# RAIA - Gerenciador Inteligente de Alimentos

Aplicativo mobile para gerenciar alimentos em casa, permitindo cadastrar produtos, controlar o estoque e receber sugestões de receitas com base nos itens disponíveis.

## Objetivo

Reduzir o desperdício de alimentos e facilitar o planejamento de refeições através de uma gestão de estoque doméstica e inteligente.

## Status do Projeto: Em Desenvolvimento (TCC 2026)

| Funcionalidade | Status |
| :--- | :--- |
| **Módulo de Autenticação** | ✅ Completo |
| Login com E-mail e Senha | ✅ Completo |
| Cadastro de Novos Usuários | ✅ Completo |
| Recuperação de Senha | ✅ Completo |
| Exclusão de Conta | ✅ Completo |
| **Módulo de Estoque** | 🔶 Parcial |
| Adicionar Ingrediente Manualmente | ✅ Completo |
| Visualizar Lista de Ingredientes | ✅ Completo |
| Editar Ingrediente Existente | ✅ Completo |
| Deletar Ingrediente | ✅ Completo |
| Cadastro por Foto/QR Code | ❌ Não Iniciado |
| **Módulo de Receitas** | ❌ Não Iniciado |
| Sugestão de Receitas (IA) | ❌ Não Iniciado |
| Salvar Receitas Favoritas | ❌ Não Iniciado |

*Para um relatório técnico detalhado sobre a arquitetura e pontos de melhoria, consulte o arquivo `ANALISE_PROJETO.md`.* 

## Tecnologias Utilizadas

*   **Mobile:** Flutter (Dart)
*   **Backend & Banco de Dados:** Firebase (Firestore, Firebase Authentication)
*   **Inteligência Artificial (Planejado):** Python (para o sistema de recomendação de receitas)

## Arquitetura do Sistema

-   **Aplicativo Mobile (Flutter):** Comunica-se diretamente com os serviços do Firebase.
-   **Firebase (BaaS):**
    -   **Firestore:** Banco de dados NoSQL para usuários, inventários e receitas.
    -   **Firebase Authentication:** Gerencia a autenticação e segurança dos usuários.
-   **Serviço de IA (Python):** (Planejado) Consumirá os dados do inventário para gerar sugestões de receitas.


## Equipe

- Irineu Henrique Santos Silva
- Matheus Ferreira Fagundes
- Yasmin Victoria Lopes da Silva

---
*Projeto desenvolvido como Trabalho de Conclusão de Curso – COTUCA 2026.*

1. Destravar o Flask

O erro acontece porque o Flask nunca foi instalado. Faltou criar o ambiente virtual e instalar as dependências nele. No PowerShell:

powershell
cd D:\Github\TCC-RAIA\IA
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install flask requests deep-translator
python server.py
Depois do Activate.ps1, o terminal passa a mostrar (.venv) no começo da linha. Se não aparecer, o ambiente não está ativo.
Se o PowerShell bloquear o Activate.ps1, rode antes: Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass.
Usei pip install flask requests deep-translator direto, em vez de -r requirements.txt, porque o seu requirements.txt ainda pode ter aquele comando do gcloud colado, que quebra o pip.
Deve aparecer Running on http://127.0.0.1:5000. Deixe esse terminal aberto.
Nas próximas vezes, só ative o ambiente e rode o servidor:
powershell
  cd D:\Github\TCC-RAIA\IA
  .venv\Scripts\Activate.ps1
  python server.py
