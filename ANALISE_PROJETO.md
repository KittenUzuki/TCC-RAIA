# Análise e Diário de Bordo do Projeto RAIA

**Última Atualização:** 30/04/2026

Este documento serve como um relatório técnico sobre o estado atual do projeto RAIA, detalhando a arquitetura, funcionalidades implementadas, pontos de melhoria e um plano de ação para os próximos passos.

## 1. Visão Geral da Arquitetura

O projeto segue uma arquitetura cliente-servidor utilizando Flutter para o frontend e Firebase como Backend-as-a-Service (BaaS).

-   **Frontend:** Flutter (Estrutura: `screens`, `widgets`, `models`)
-   **Backend:**
    -   **Autenticação:** Firebase Authentication
    -   **Banco de Dados:** Cloud Firestore
    -   **Armazenamento de Arquivos:** Firebase Storage

## 2. Status das Funcionalidades (Check-up)

| Funcionalidade | Status | Detalhes |
| :--- | :--- | :--- |
| **Autenticação de Usuário** | 🔶 **Parcial/Instável** | Login, Cadastro, Logout e Exclusão foram implementados, mas bugs no fluxo de Logout e feedback de Cadastro foram reportados. **Estabilização em andamento.** |
| **CRUD de Ingredientes** | 🔶 **Em Correção** | A funcionalidade de Criar, Ler, Atualizar e Deletar foi refatorada para uma estrutura de dados correta. **Aguardando testes após correção.** |
| **Visualização do Estoque** | 🔶 **Em Correção** | A tela foi refatorada. Aguardando criação de índice no Firebase e testes. |
| **Cadastro por Imagem/QR**| ❌ **Não Iniciado** | O pacote `image_picker` está instalado, mas a funcionalidade não foi implementada. |
| **Sugestão de Receitas** | ❌ **Não Iniciado** | Nenhuma implementação relacionada a receitas foi iniciada. |

## 3. Ações Críticas Realizadas

### 3.1. (CONCLUÍDO) Refatoração da Estrutura do Banco de Dados

-   **Problema Original:** A implementação no Firestore (`ingredientes/{userId}/userIngredientes`) não refletia o plano de dados original (schema SQL) e criava um gargalo técnico que impedia a escalabilidade (ex: consultas por IA).
-   **Ação Corretiva:** O código foi refatorado. Agora, os ingredientes são salvos em uma coleção de nível superior `ingredientes`. Cada documento nesta coleção contém um campo `userId`, espelhando a lógica da tabela de junção `rira.Alimento` do plano original.
-   **Arquivos Impactados:** `add_ingredientes_screen.dart` e `estoque_screen.dart`.
-   **Status:** A refatoração do código está completa. O app agora está alinhado com a modelagem de dados correta e escalável.

## 4. Plano de Ação Imediato (Estabilização)

O foco atual é **estabilizar a base do aplicativo** antes de prosseguir com novas funcionalidades.

1.  **Criar Índice no Firestore (Tarefa do Usuário):**
    -   **Ação:** Executar o app, navegar para a tela de Estoque e usar o link gerado no log de erro para criar o índice composto no painel do Firebase.
    -   **Objetivo:** Permitir que a consulta de ingredientes (`where('userId', isEqualTo: ...).orderBy('validade')`) funcione.

2.  **Corrigir Bug de Logout (Em Andamento):**
    -   **Ação:** Diagnosticar e corrigir o erro que impede o usuário de sair da conta na `perfil_screen.dart`.
    -   **Objetivo:** Garantir que a função `signOut()` funcione corretamente e o usuário seja redirecionado para a tela de login.

3.  **Corrigir Feedback de Cadastro:**
    -   **Ação:** Adicionar feedback visual (ex: SnackBar) e navegação para a tela de login após um cadastro bem-sucedido na `cadastro_screen.dart`.
    -   **Objetivo:** Melhorar a experiência do usuário, fornecendo uma confirmação clara de que a conta foi criada.

## 5. Próximos Passos (Pós-Estabilização)

-   **Refatorar Lógica de Acesso a Dados:** Mover as chamadas ao Firestore para uma classe de serviço (`FirestoreService.dart`) para limpar o código das telas.
-   **Implementar Sugestão de Receitas:** Iniciar o desenvolvimento da funcionalidade de receitas.
