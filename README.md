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
