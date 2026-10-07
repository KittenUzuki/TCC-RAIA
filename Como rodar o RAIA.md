# Como rodar o RAIA — guia rápido

O projeto tem **duas partes que precisam rodar ao mesmo tempo**, em duas janelas de terminal separadas:

1. **A API de receitas** (Python/Flask, pasta `IA/`) — sem ela, a tela de Receitas (e por tabela, Favoritos) fica carregando pra sempre ou dá erro.
2. **O app Flutter** (pasta `raia_app/`) — o app em si, Android/Chrome/etc.

Se só o app Flutter estiver rodando e a API não, o app **não vai travar nem avisar com clareza** — a tela de Receitas vai ficar "carregando" ou mostrar erro de conexão. Isso normalmente é o motivo nº1 de achar que "quebrou alguma coisa" quando na verdade só esqueceram de ligar o servidor.

---

## Toda vez que for testar (resumo rápido)

Faça nessa ordem:

**Terminal 1 — liga a API** (dentro de `raia_app/IA`):

```
venv\Scripts\activate
python server.py
```

Espera aparecer `Running on http://0.0.0.0:5000`. **Deixa essa janela aberta** — se fechar, a API para.

**Terminal 2 — liga o app** (dentro de `raia_app`):

```
flutter run
```

(ou pelo botão de play do Android Studio / VS Code, escolhendo o emulador Pixel 4 como dispositivo)

Pronto. As duas janelas ficam abertas o tempo todo que você estiver testando.

---

## Primeira vez configurando numa máquina nova (só precisa fazer uma vez)

Se é a primeira vez que você roda o projeto nesse computador, antes do passo acima:

**1. Criar o ambiente virtual do Python** (só na primeira vez; dentro de `raia_app/IA`):

```
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
```

Isso cria a pasta `venv/` com as bibliotecas Python do projeto, isolada do resto do seu computador. Você não precisa repetir o `pip install` toda vez — só se o `requirements.txt` mudar.

**2. Buscar os pacotes do Flutter** (só quando clonar o projeto ou depois de atualizar o `pubspec.yaml`; dentro de `raia_app`):

```
flutter pub get
```

**3. Conferir se o Firestore está com as regras publicadas:**

```
firebase deploy --only firestore:rules
```

(Se você mudou o `firestore.rules` recentemente e esqueceu de publicar, as operações no Firestore falham silenciosamente — o app parece travado, sem erro claro.)

---

## Rodando em lugares diferentes

A URL que o app usa pra falar com a API Flask é **detectada automaticamente** (arquivo `lib/config/api_config.dart`), então na maioria dos casos você não precisa mexer em nada:

| Onde você testa | Funciona sozinho? |
| --- | --- |
| Chrome (`flutter run -d chrome`) | ✅ Sim |
| Emulador Android (Pixel 4) | ✅ Sim |
| Celular físico (USB ou Wi-Fi) | ⚠️ Precisa configurar o IP manualmente uma vez — ver abaixo |

**Só para celular físico:** abra `lib/config/api_config.dart`, descubra o IP da sua máquina na rede Wi-Fi (`ipconfig` no cmd do Windows → procure "Endereço IPv4", algo como `192.168.0.15`) e preencha:

```dart
static const String? _ipDaMinhaMaquina = '192.168.0.15';
```

O celular e o computador precisam estar na **mesma rede Wi-Fi** pra isso funcionar. Lembre de voltar esse valor para `null` se depois for testar de novo no Chrome ou no emulador.

---

## Problemas comuns ao tentar rodar

| Sintoma | Causa provável | O que fazer |
| --- | --- | --- |
| Tela de Receitas fica carregando pra sempre / erro de conexão | Esqueceu de rodar `python server.py` | Confere se o Terminal 1 está aberto e mostrando `Running on...` |
| `ModuleNotFoundError` ao rodar `server.py` | Ambiente virtual não foi ativado, ou não foi criado | Roda `venv\Scripts\activate` antes do `python server.py`. Se o erro continuar, roda `pip install -r requirements.txt` de novo |
| Usuário cadastra mas não aparece no Firestore / ingrediente não salva | Regras do Firestore desatualizadas no console | `firebase deploy --only firestore:rules` |
| Erro de Gradle mencionando `build.gradle` (sem `.kts`) | Sobraram arquivos antigos (`android/build.gradle`, `android/settings.gradle`, `android/app/build.gradle`) junto dos `.kts` novos | Apaga os três arquivos **sem** `.kts` — eles não deveriam coexistir com os `.kts` |
| `No matching client found for package name` | `applicationId` no `android/app/build.gradle.kts` não bate com o `package_name` do `google-services.json` | Confere os dois valores e deixa iguais, ou rode `flutterfire configure` de novo |
| App não conecta no emulador mas conecta no Chrome | Esqueceu que `localhost` não funciona no emulador | Já resolvido pelo `api_config.dart` — se ainda acontecer, confere se esse arquivo foi mesmo colado no projeto |

---

## Lembrete de bolso (cole isso num post-it se precisar)

```
Terminal 1 (IA):       venv\Scripts\activate  →  python server.py
Terminal 2 (raia_app): flutter run
```