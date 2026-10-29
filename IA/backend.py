import time
from concurrent.futures import ThreadPoolExecutor, as_completed

import requests
from flask import jsonify
from deep_translator import GoogleTranslator, MyMemoryTranslator

DICIONARIO_PT_EN = {
    "leite": "milk", "tomate": "tomato", "batata": "potato", "cenoura": "carrot", "ovo": "egg", "ovos": "eggs",
    "frango": "chicken", "carne": "beef", "arroz": "rice", "feijao": "beans", "feijão": "beans",
    "queijo": "cheese", "cebola": "onion", "alho": "garlic", "manteiga": "butter",
    "farinha": "flour", "açucar": "sugar", "açúcar": "sugar", "sal": "salt",
    "cenoura": "carrot", "macarrao": "pasta", "macarrão": "pasta", "azeite": "olive oil",
    "oleo": "oil", "óleo": "oil", "pao": "bread", "pão": "bread", "peixe": "fish",
    "cogumelo": "mushroom", "presunto": "ham", "bacon": "bacon", "maça": "apples", "maçã": "apples"
}

# Quantas receitas candidatas processar no máximo por requisição. Cada uma
# roda numa thread separada (ver ThreadPoolExecutor abaixo), então subir
# esse número não multiplica o tempo de espera do jeito que multiplicava
# antes da paralelização — só multiplica um pouco a carga na API externa.
MAX_RECEITAS = 6


def traduzir_lista_pt_en(lista_pt):
    """Traduz PT->EN. Dicionário fixo primeiro (instantâneo, sem rede);
    só o que sobrar vai pra tradução online."""
    ingredientes_en = []
    para_traduzir = []

    for item in lista_pt:
        if item in DICIONARIO_PT_EN:
            ingredientes_en.append(DICIONARIO_PT_EN[item])
        else:
            para_traduzir.append(item)

    if para_traduzir:
        try:
            tradutor = GoogleTranslator(source='pt', target='en')
            traducoes = tradutor.translate_batch(para_traduzir)
            ingredientes_en.extend([t.lower() for t in traducoes])
        except Exception:
            try:
                tradutor_alt = MyMemoryTranslator(source='pt-BR', target='en-US')
                traducoes = [tradutor_alt.translate(item) for item in para_traduzir]
                ingredientes_en.extend([t.lower() for t in traducoes if t])
            except Exception:
                ingredientes_en.extend(para_traduzir)

    return ingredientes_en


def _buscar_candidatos(ingrediente_en):
    """Busca receitas que usam um ingrediente (1 chamada à TheMealDB).
    Roda em paralelo para cada ingrediente — ver ThreadPoolExecutor em
    sugerir_receitas()."""
    try:
        resp = requests.get(
            "https://www.themealdb.com/api/json/v1/1/filter.php",
            params={"i": ingrediente_en},
            timeout=16,
        )
        meals = resp.json().get("meals") or []
        print(f"3. Busca por '{ingrediente_en}': {len(meals)} receitas encontradas.")
        return [meal["idMeal"] for meal in meals]
    except Exception:
        return []


def _processar_receita(id_receita, set_ingredientes_en):
    """Busca os detalhes de UMA receita e traduz nome/instruções/faltantes.
    Esta função roda em paralelo (uma thread por receita) — é aqui que
    estava a maior parte da lentidão, porque cada chamada faz 1 busca +
    até 3 traduções em sequência.

    IMPORTANTE: criamos um GoogleTranslator novo aqui dentro (em vez de
    compartilhar uma única instância entre as threads) porque não há
    garantia de que a biblioteca deep_translator seja segura para uso
    concorrente (thread-safe). Criar uma instância por chamada é mais
    seguro e tem custo desprezível perto do tempo de rede.
    """
    try:
        resp = requests.get(
            "https://www.themealdb.com/api/json/v1/1/lookup.php",
            params={"i": id_receita},
            timeout=10,
        )
        dados_meal = resp.json().get("meals")
        if not dados_meal:
            return None

        detalhe = dados_meal[0]
        tradutor_pt = GoogleTranslator(source='en', target='pt')

        ingredientes_receita_en = [
            detalhe[f"strIngredient{i}"].strip().lower()
            for i in range(1, 40)
            if detalhe.get(f"strIngredient{i}") and detalhe[f"strIngredient{i}"].strip()
        ]

        faltando_en = [ing for ing in ingredientes_receita_en if ing not in set_ingredientes_en]

        try:
            nome_pt = tradutor_pt.translate(detalhe["strMeal"])
        except Exception:
            nome_pt = detalhe["strMeal"]

        try:
            instrucoes_pt = tradutor_pt.translate(detalhe["strInstructions"])
        except Exception:
            instrucoes_pt = detalhe["strInstructions"]

        faltando_pt = []
        if faltando_en:
            try:
                faltando_pt = [t.capitalize() for t in tradutor_pt.translate_batch(faltando_en)]
            except Exception:
                faltando_pt = [ing.capitalize() for ing in faltando_en]

        return {
            "id": id_receita,
            "nome": nome_pt,
            "imagem": detalhe.get("strMealThumb", ""),
            "ingredientesFaltando": faltando_pt,
            "modoPreparo": instrucoes_pt,
        }
    except Exception:
        return None


def sugerir_receitas(request):
    headers = {'Access-Control-Allow-Origin': '*'}
    if request.method == 'OPTIONS':
        headers.update({
            'Access-Control-Allow-Methods': 'POST',
            'Access-Control-Allow-Headers': 'Content-Type',
        })
        return ('', 204, headers)

    inicio = time.time()
    dados = request.get_json(silent=True) or {}
    ingredientes_pt = [i.strip().lower() for i in dados.get("ingredientes", []) if i.strip()]

    print(f"\n--- NOVA REQUISIÇÃO ---")
    print(f"1. Ingredientes recebidos do Flutter: {ingredientes_pt}")

    if not ingredientes_pt:
        return (jsonify({"receitas": []}), 200, headers)

    ingredientes_en = traduzir_lista_pt_en(ingredientes_pt)
    print(f"2. Ingredientes traduzidos para EN: {ingredientes_en}")
    set_ingredientes_en = set(ingredientes_en)

    # Busca candidatos para todos os ingredientes AO MESMO TEMPO, em vez de
    # um ingrediente por vez. Com poucos ingredientes o ganho é pequeno,
    # mas não custa nada e ajuda quando o estoque tiver muitos itens.
    candidatas_ids = set()
    with ThreadPoolExecutor(max_workers=max(1, len(set_ingredientes_en))) as executor:
        futures = [executor.submit(_buscar_candidatos, ing) for ing in set_ingredientes_en]
        for future in as_completed(futures):
            candidatas_ids.update(future.result())

    ids_para_processar = list(candidatas_ids)[:MAX_RECEITAS]

    # AQUI está o ganho principal: processar as receitas (busca + tradução)
    # em paralelo em vez de uma atrás da outra. Antes: até 6 receitas x
    # (1 busca + 3 traduções) em sequência. Agora: as 6 rodam ao mesmo
    # tempo, então o tempo total fica perto do tempo da MAIS LENTA, não da
    # SOMA de todas.
    resultados = []
    with ThreadPoolExecutor(max_workers=max(1, len(ids_para_processar))) as executor:
        futures = [
            executor.submit(_processar_receita, id_receita, set_ingredientes_en)
            for id_receita in ids_para_processar
        ]
        for future in as_completed(futures):
            receita = future.result()
            if receita is not None:
                resultados.append(receita)

    resultados.sort(key=lambda r: len(r["ingredientesFaltando"]))

    duracao = time.time() - inicio
    print(f"4. Retornando {len(resultados)} receitas para o aplicativo. ({duracao:.1f}s)\n")
    return (jsonify({"receitas": resultados}), 200, headers)
