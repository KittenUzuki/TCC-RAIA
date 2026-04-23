# Nome APP
Aplicativo mobile para gerenciar alimentos em casa, permitindo cadastrar produtos, controlar o estoque e receber sugestões de receitas com base nos itens disponíveis.

# Objetivo

Muitas pessoas não possuem controle sobre os alimentos armazenados em casa, o que gera desperdício, compras repetidas e dificuldade para decidir o que cozinhar.
O objetivo do projeto é facilitar o gerenciamento doméstico e reduzir o desperdício de alimentos por meio de tecnologia.

# Funcionalidades

Cadastro manual de alimentos

Cadastro a partir de QR Code ou foto da nota fiscal

Controle de quantidade e validade

Visualização do estoque disponível

Sugestão automática de receitas com base nos itens cadastrados

# Tecnologias Utilizadas

*   **Mobile:** Flutter (Dart)
*   **Backend & Banco de Dados:** Firebase (Firestore, Firebase Authentication)
*   **Inteligência Artificial:** Python (recomendação de receitas)

# Arquitetura do Sistema

A nova arquitetura simplificada do sistema é a seguinte:

*   **Aplicativo Mobile (Flutter):** O aplicativo se comunica diretamente com os serviços do Firebase para autenticação e armazenamento de dados.
*   **Firebase (Backend-as-a-Service):**
    *   **Firestore:** Atua como o banco de dados NoSQL principal, armazenando informações de usuários, inventários e receitas.
    *   **Firebase Authentication:** Gerencia o login e a segurança dos usuários.
*   **Serviço de IA (Python):** Um serviço separado que consome os dados do inventário (possivelmente via uma Cloud Function) para gerar e sugerir receitas.

    Flutter (App Mobile) <-> Firebase (Backend & DB)
           |
           V
    Serviço Python (IA) -> Sugestões de Receitas

# Equipe

### Irineu Henrique Santos Silva

### Matheus Ferreira Fagundes

### Yasmin Victoria Lopes da Silva

Projeto desenvolvido como Trabalho de Conclusão de Curso – COTUCA 2026.

# Como Executar o Projeto

# Status do Projeto

Em desenvolvimento — TCC 2026

# Licença

Este projeto está sob a licença MIT. Consulte o arquivo LICENSE para mais informações.
