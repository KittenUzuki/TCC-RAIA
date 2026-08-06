"""
RAIA - Motor de recomendacao de receitas
==========================================

Este script demonstra o pipeline completo discutido:

    Estoque do usuario
        -> Indice invertido de ingredientes (pre-filtro)
        -> Receitas candidatas (via API do TheMealDB)
        -> Scoring de viabilidade (cobertura + urgencia de validade)
        -> Matching semantico via embeddings (sentence-transformers,
           modelo multilingue - compara "tomate" no estoque com
           "tomatoes" vindo da API em ingles, por exemplo)
        -> Ranking final

Dependencias: "requests" (API real) + "sentence-transformers" (matching).
    pip install requests sentence-transformers --break-system-packages

Observacao: o script inteiro depende de internet agora - as funcoes de
rede (fetch_*) chamam a API publica do TheMealDB, e o bloco
`if __name__ == "__main__"` roda o pipeline de ponta a ponta com dados
reais (sem mocks). O download do modelo de embeddings (na primeira
execucao) tambem requer internet - ele fica em cache local depois disso.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from datetime import date
from functools import lru_cache
from typing import Optional

try:
    import requests
except ImportError:  # ambiente sem a lib instalada
    requests = None

try:
    from sentence_transformers import SentenceTransformer
except ImportError:  # ambiente sem a lib instalada
    SentenceTransformer = None


# ---------------------------------------------------------------------------
# 1. Modelos de dados
# ---------------------------------------------------------------------------

@dataclass
class ItemEstoque:
    nome: str
    quantidade: float
    unidade: str
    validade: Optional[date] = None


@dataclass
class IngredienteReceita:
    nome: str
    quantidade: Optional[float]
    unidade: Optional[str]


@dataclass
class Receita:
    id: str
    nome: str
    ingredientes: list[IngredienteReceita] = field(default_factory=list)


# ---------------------------------------------------------------------------
# 2. Integracao com a API do TheMealDB
# ---------------------------------------------------------------------------

BASE_URL = "https://www.themealdb.com/api/json/v1/1"


def fetch_receitas_por_ingrediente(ingrediente: str) -> list[dict]:
    """Busca receitas que contenham um ingrediente especifico.

    Endpoint: filter.php?i=<ingrediente>
    Retorna apenas id + nome (sem lista completa de ingredientes -
    e preciso um segundo request para os detalhes, ver abaixo).
    """
    if requests is None:
        raise RuntimeError("instale 'requests' para usar chamadas de rede")

    resp = requests.get(f"{BASE_URL}/filter.php", params={"i": ingrediente}, timeout=10)
    resp.raise_for_status()
    data = resp.json()
    return data.get("meals") or []


def fetch_detalhes_receita(meal_id: str) -> Receita:
    """Busca os detalhes completos de uma receita (ingredientes + medidas).

    Endpoint: lookup.php?i=<id>
    A API devolve os ingredientes em campos soltos (strIngredient1..20 /
    strMeasure1..20), entao normalize_receita_raw faz o parsing disso.
    """
    if requests is None:
        raise RuntimeError("instale 'requests' para usar chamadas de rede")

    resp = requests.get(f"{BASE_URL}/lookup.php", params={"i": meal_id}, timeout=10)
    resp.raise_for_status()
    data = resp.json()
    meal = data["meals"][0]
    return normalize_receita_raw(meal)


# O TheMealDB so aceita nomes de ingrediente em ingles (e com "_" no lugar
# de espaco) no endpoint filter.php. Como o estoque do usuario esta em
# portugues, precisamos de uma traducao minima antes de consultar a API.
# Em producao troque isto por um servico de traducao/dicionario maior -
# aqui cobrimos so os itens usados na demonstracao.
_TRADUCAO_PT_EN = {
    "tomate": "tomato",
    "cebola": "onion",
    "azeite": "olive_oil",
    "alho": "garlic",
    "manjericao": "basil",
    "frango": "chicken",
}


def obter_receitas_candidatas(estoque: list[ItemEstoque]) -> list[Receita]:
    """Indice invertido de ingredientes (pre-filtro), com chamadas reais
    a API: para cada item do estoque, busca as receitas que o usam
    (filter.php), agrega os IDs unicos encontrados e busca os detalhes
    completos de cada uma (lookup.php). Requer internet.
    """
    ids_ja_buscados: set[str] = set()
    receitas: list[Receita] = []

    for item in estoque:
        nome_em_ingles = _TRADUCAO_PT_EN.get(item.nome.lower(), item.nome)
        candidatos = fetch_receitas_por_ingrediente(nome_em_ingles)

        for candidato in candidatos:
            meal_id = candidato["idMeal"]
            if meal_id in ids_ja_buscados:
                continue
            ids_ja_buscados.add(meal_id)
            receitas.append(fetch_detalhes_receita(meal_id))

    return receitas


# ---------------------------------------------------------------------------
# 3. Normalizacao (o formato bruto da API -> o formato do motor de scoring)
# ---------------------------------------------------------------------------

_UNIDADES_CONHECIDAS = {
    "g": "g", "gram": "g", "grams": "g", "kg": "kg",
    "ml": "ml", "l": "l", "liter": "l",
    "tsp": "tsp", "tbs": "tbsp", "tbsp": "tbsp",
    "cup": "cup", "cups": "cup", "oz": "oz", "lb": "lb",
}


def _parse_medida(medida: str) -> tuple[Optional[float], Optional[str]]:
    """Tenta extrair quantidade + unidade de uma medida em texto livre,
    ex.: "1 kg", "2 tbs", "a pinch" -> (None, None) quando nao da pra parsear.
    """
    medida = medida.strip().lower()
    if not medida:
        return None, None

    match = re.match(r"([\d/.,]+)\s*([a-zA-Z]*)", medida)
    if not match:
        return None, None

    qtd_str, unidade_bruta = match.groups()
    try:
        if "/" in qtd_str:
            num, den = qtd_str.split("/")
            quantidade = float(num) / float(den)
        else:
            quantidade = float(qtd_str.replace(",", "."))
    except ValueError:
        return None, None

    unidade = _UNIDADES_CONHECIDAS.get(unidade_bruta, unidade_bruta or None)
    return quantidade, unidade


def normalize_receita_raw(meal: dict) -> Receita:
    """Converte o formato bruto do TheMealDB (campos strIngredient1..20 /
    strMeasure1..20) para o formato estruturado usado no scoring."""
    ingredientes: list[IngredienteReceita] = []

    for i in range(1, 21):
        nome = meal.get(f"strIngredient{i}")
        medida = meal.get(f"strMeasure{i}") or ""
        if nome and nome.strip():
            quantidade, unidade = _parse_medida(medida)
            ingredientes.append(IngredienteReceita(nome.strip(), quantidade, unidade))

    return Receita(id=meal["idMeal"], nome=meal["strMeal"], ingredientes=ingredientes)


# ---------------------------------------------------------------------------
# 4. Matching semantico (embeddings via sentence-transformers)
# ---------------------------------------------------------------------------
#
# Modelo multilingue: o estoque do usuario esta em portugues ("tomate",
# "cebola") mas a API do TheMealDB devolve os ingredientes em ingles
# ("tomatoes", "onion"), entao precisamos de um modelo que coloque as
# duas linguas no mesmo espaco vetorial. O modelo e carregado uma unica
# vez (lazy load) e cada string so e codificada uma vez, gracas ao cache.

NOME_MODELO_EMBEDDINGS = "paraphrase-multilingual-MiniLM-L12-v2"

# Similaridade de cosseno vai de -1 a 1; para nomes curtos de ingredientes
# 0.6-0.65 costuma ser um bom ponto de corte (ajuste conforme os falsos
# positivos/negativos observados nos seus dados reais).
LIMIAR_SIMILARIDADE = 0.62

_modelo_embeddings: "SentenceTransformer | None" = None


def _carregar_modelo() -> "SentenceTransformer":
    """Lazy load do modelo de embeddings (evita custo de import/download
    quando o script e usado so para scoring, ex. em testes)."""
    global _modelo_embeddings

    if SentenceTransformer is None:
        raise RuntimeError(
            "instale 'sentence-transformers' para usar o matching semantico "
            "(pip install sentence-transformers --break-system-packages)"
        )

    if _modelo_embeddings is None:
        _modelo_embeddings = SentenceTransformer(NOME_MODELO_EMBEDDINGS)

    return _modelo_embeddings


@lru_cache(maxsize=4096)
def _embedding(texto: str) -> tuple[float, ...]:
    """Calcula (e cacheia) o embedding normalizado de uma string.

    Retorna uma tupla de floats (hashable, funciona com lru_cache);
    a normalizacao faz com que o produto escalar entre dois vetores
    seja igual a similaridade de cosseno.
    """
    modelo = _carregar_modelo()
    vetor = modelo.encode(texto.strip().lower(), normalize_embeddings=True)
    return tuple(float(x) for x in vetor)


def similaridade_ingredientes(nome_estoque: str, nome_receita: str) -> float:
    """Similaridade de cosseno (0 a 1 na pratica) entre dois nomes de
    ingrediente, usando os embeddings cacheados.

    Como os embeddings ja saem normalizados de _embedding(), o produto
    escalar simples (sem numpy) e igual a similaridade de cosseno.
    """
    v1 = _embedding(nome_estoque)
    v2 = _embedding(nome_receita)
    return sum(a * b for a, b in zip(v1, v2))


def sao_o_mesmo_ingrediente(nome_estoque: str, nome_receita: str) -> bool:
    return similaridade_ingredientes(nome_estoque, nome_receita) >= LIMIAR_SIMILARIDADE


# ---------------------------------------------------------------------------
# 5. Scoring de viabilidade
# ---------------------------------------------------------------------------

PESO_COBERTURA = 10.0
PESO_URGENCIA = 5.0
PENALIDADE_FALTANTE = 1.0
DIAS_URGENCIA = 3  # itens que vencem em ate N dias contam como "urgentes"


def _dias_para_vencer(validade: Optional[date]) -> Optional[int]:
    if validade is None:
        return None
    return (validade - date.today()).days


def calcular_score(receita: Receita, estoque: list[ItemEstoque]) -> dict:
    """Retorna o score de viabilidade de uma receita dado o estoque atual.

    score = cobertura * peso_cobertura + urgencia * peso_urgencia
            - faltantes * penalidade
    """
    total_ingredientes = len(receita.ingredientes) or 1
    encontrados = 0
    faltantes = []
    bonus_urgencia = 0.0

    for ing_receita in receita.ingredientes:
        item_correspondente = next(
            (item for item in estoque if sao_o_mesmo_ingrediente(item.nome, ing_receita.nome)),
            None,
        )

        if item_correspondente is None:
            faltantes.append(ing_receita.nome)
            continue

        # checagem de quantidade so quando ambos os lados tem valores numericos
        se_precisa_quantidade = ing_receita.quantidade is not None
        se_falta_quantidade = (
            se_precisa_quantidade
            and item_correspondente.quantidade < ing_receita.quantidade
        )
        if se_falta_quantidade:
            faltantes.append(f"{ing_receita.nome} (quantidade insuficiente)")
            continue

        encontrados += 1
        dias = _dias_para_vencer(item_correspondente.validade)
        if dias is not None and dias <= DIAS_URGENCIA:
            bonus_urgencia += 1.0

    cobertura = encontrados / total_ingredientes
    score = (
        cobertura * PESO_COBERTURA
        + bonus_urgencia * PESO_URGENCIA
        - len(faltantes) * PENALIDADE_FALTANTE
    )

    return {
        "receita": receita.nome,
        "score": round(score, 2),
        "cobertura_pct": round(cobertura * 100, 1),
        "ingredientes_faltantes": faltantes,
        "usa_item_urgente": bonus_urgencia > 0,
    }


def ranquear_receitas(receitas: list[Receita], estoque: list[ItemEstoque]) -> list[dict]:
    resultados = [calcular_score(r, estoque) for r in receitas]
    return sorted(resultados, key=lambda r: r["score"], reverse=True)


# ---------------------------------------------------------------------------
# 6. Demonstracao de ponta a ponta (requer internet)
# ---------------------------------------------------------------------------
#
# Este bloco usa as chamadas reais a API do TheMealDB (secao 2) e o
# modelo real de embeddings (secao 4) - nao ha mais dados mockados.
# Isso significa que, na primeira execucao, o sentence-transformers vai
# baixar o modelo "paraphrase-multilingual-MiniLM-L12-v2" (alguns
# centenas de MB) e cada chamada fetch_* vai bater na API publica do
# TheMealDB. Sem internet, este bloco falha.

if __name__ == "__main__":
    estoque_do_usuario = [
        ItemEstoque("tomate", 4, "unidade", validade=date(2026, 8, 7)),  # vence logo
        ItemEstoque("cebola", 2, "unidade", validade=date(2026, 8, 20)),
        ItemEstoque("azeite", 500, "ml"),
        ItemEstoque("alho", 3, "unidade"),
        ItemEstoque("manjericao", 1, "unidade"),
    ]

    print("Buscando receitas candidatas na API do TheMealDB...\n")
    receitas_candidatas = obter_receitas_candidatas(estoque_do_usuario)

    if not receitas_candidatas:
        print(
            "Nenhuma receita candidata encontrada. Verifique a conexao com "
            "a internet e se os nomes em _TRADUCAO_PT_EN cobrem seu estoque."
        )
    else:
        print(f"{len(receitas_candidatas)} receita(s) candidata(s) encontrada(s) "
              f"(baixando modelo de embeddings, se ainda nao estiver em cache)...\n")

        print("Ranking de receitas sugeridas:\n")
        for resultado in ranquear_receitas(receitas_candidatas, estoque_do_usuario):
            print(f"- {resultado['receita']}")
            print(f"  score: {resultado['score']} | cobertura: {resultado['cobertura_pct']}%")
            print(f"  usa item perto de vencer: {resultado['usa_item_urgente']}")
            if resultado["ingredientes_faltantes"]:
                print(f"  faltam: {', '.join(resultado['ingredientes_faltantes'])}")
            print()