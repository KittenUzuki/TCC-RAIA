"""
Baixa TODAS as receitas do TheMealDB e salva num arquivo JSON que o app
RAIA lê localmente (raia_app/assets/receitas_pt.json).

Assim o app não precisa chamar a API (nem o servidor Flask) toda vez que a
tela de Receitas abre: procura tudo no arquivo, na hora.

As receitas ficam como vêm da API (em inglês), sem tradução.

Como rodar (dentro da pasta IA, com o venv ativado):
    pip install requests
    python gerar_receitas_pt.py

Depois de gerar, pare o app e rode de novo (flutter run).
"""

from __future__ import annotations

import json
import string
import sys
import time
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

import requests

BASE_URL = "https://www.themealdb.com/api/json/v1/1"
PASTA_IA = Path(__file__).resolve().parent
SAIDA = PASTA_IA.parent / "raia_app" / "assets" / "receitas_pt.json"


def baixar_todas_receitas() -> list[dict]:
    """O TheMealDB permite buscar por letra inicial e já devolve a receita
    completa. Uma chamada por letra/dígito = banco inteiro."""
    sessao = requests.Session()

    def por_letra(letra: str) -> list[dict]:
        for tentativa in range(4):
            try:
                r = sessao.get(f"{BASE_URL}/search.php", params={"f": letra}, timeout=20)
                r.raise_for_status()
                return r.json().get("meals") or []
            except Exception as e:
                print(f"   ! letra '{letra}': {e} (tentativa {tentativa + 1}/4)")
                time.sleep(2 * (tentativa + 1))
        return []

    with ThreadPoolExecutor(max_workers=6) as ex:
        listas = list(ex.map(por_letra, string.ascii_lowercase + string.digits))

    receitas: dict[str, dict] = {}
    for lista in listas:
        for meal in lista:
            receitas[meal["idMeal"]] = meal
    return sorted(receitas.values(), key=lambda m: int(m["idMeal"]))


def ingredientes_da_receita(meal: dict) -> list[dict]:
    itens = []
    for i in range(1, 21):
        nome = (meal.get(f"strIngredient{i}") or "").strip()
        medida = (meal.get(f"strMeasure{i}") or "").strip()
        if nome:
            itens.append({"nome": nome, "nomeOriginal": nome, "medida": medida})
    return itens


def modo_de_preparo(texto: str | None) -> str:
    """Tira linhas vazias e quebras de linha do Windows."""
    texto = (texto or "").replace("\r\n", "\n").replace("\r", "\n")
    return "\n".join(l.strip() for l in texto.split("\n") if l.strip())


def converter(meal: dict) -> dict:
    """Formato que o app lê (ver lib/services/receita_local_service.dart)."""
    return {
        "id": meal["idMeal"],
        "nome": meal.get("strMeal") or "",
        "nomeOriginal": meal.get("strMeal") or "",
        "categoria": meal.get("strCategory") or "",
        "origem": meal.get("strArea") or "",
        "imagem": meal.get("strMealThumb") or "",
        "video": meal.get("strYoutube") or "",
        "tags": [t.strip() for t in (meal.get("strTags") or "").split(",") if t.strip()],
        "ingredientes": ingredientes_da_receita(meal),
        "modoPreparo": modo_de_preparo(meal.get("strInstructions")),
    }


def main():
    inicio = time.time()
    print("Baixando todas as receitas do TheMealDB...")
    meals = baixar_todas_receitas()
    if not meals:
        print("Nenhuma receita baixada. Confira sua internet e rode de novo.")
        sys.exit(1)

    receitas = [converter(m) for m in meals]
    SAIDA.parent.mkdir(parents=True, exist_ok=True)
    SAIDA.write_text(json.dumps(receitas, ensure_ascii=False, indent=1), encoding="utf-8")
    print(f"Pronto! {len(receitas)} receitas salvas em {SAIDA} ({time.time() - inicio:.0f}s).")
    print("Agora pare o app e rode de novo: flutter run")


if __name__ == "__main__":
    main()
