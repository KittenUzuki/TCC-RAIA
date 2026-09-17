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

def traduzir_lista_pt_en(lista_pt):
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

def sugerir_receitas(request):
    headers = {'Access-Control-Allow-Origin': '*'}
    if request.method == 'OPTIONS':
        headers.update({
            'Access-Control-Allow-Methods': 'POST',
            'Access-Control-Allow-Headers': 'Content-Type',
        })
        return ('', 204, headers)

    dados = request.get_json(silent=True) or {}
    ingredientes_pt = [i.strip().lower() for i in dados.get("ingredientes", []) if i.strip()]

    print(f"\n--- NOVA REQUISIÇÃO ---")
    print(f"1. Ingredientes recebidos do Flutter: {ingredientes_pt}")

    if not ingredientes_pt:
        return (jsonify({"receitas": []}), 200, headers)

    ingredientes_en = traduzir_lista_pt_en(ingredientes_pt)
    print(f"2. Ingredientes traduzidos para EN: {ingredientes_en}")
    set_ingredientes_en = set(ingredientes_en)

    candidatas_ids = set()
    for ing in set_ingredientes_en:
        try:
            resp = requests.get(
                "https://www.themealdb.com/api/json/v1/1/filter.php",
                params={"i": ing},
                timeout=4
            )
            meals = resp.json().get("meals") or []
            print(f"3. Busca por '{ing}': {len(meals)} receitas encontradas.")
            for meal in meals:
                candidatas_ids.add(meal["idMeal"])
        except Exception as e:
            continue

    resultados = []
    tradutor_pt = GoogleTranslator(source='en', target='pt')

    for id_receita in list(candidatas_ids)[:6]:
        try:
            resp = requests.get(
                "https://www.themealdb.com/api/json/v1/1/lookup.php",
                params={"i": id_receita},
                timeout=4
            )
            dados_meal = resp.json().get("meals")
            if not dados_meal:
                continue

            detalhe = dados_meal[0]

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

            resultados.append({
                "id": id_receita,
                "nome": nome_pt,
                "imagem": detalhe.get("strMealThumb", ""),
                "ingredientesFaltando": faltando_pt,
                "modoPreparo": instrucoes_pt,
            })
        except Exception:
            continue

    resultados.sort(key=lambda r: len(r["ingredientesFaltando"]))
    print(f"4. Retornando {len(resultados)} receitas para o aplicativo.\n")
    return (jsonify({"receitas": resultados}), 200, headers)