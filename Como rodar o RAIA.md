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

---

## Comando de voz (adicionar/remover alimentos falando)

Depois de atualizar o projeto, rode **uma vez** dentro de `raia_app`:

```
flutter pub get
```

(no Mac/iOS, se der erro de pods: `cd ios && pod install`)

**Onde fica:** botão **+** → **Por voz**, ícone de microfone no topo da tela **Meu Estoque**, ou o botão **Adicionar/remover por voz** na Home.

**Exemplos do que dá pra falar:**

| Frase | O que acontece |
| --- | --- |
| "adicionar 2 kg de arroz" | cria Arroz 2 kg (ou soma se já existir) |
| "comprei meia dúzia de ovos e um litro de leite" | soma 6 ovos e 1 L de leite |
| "coloca dois quilos e meio de batata" | 2,5 kg de batata |
| "usei 3 ovos" / "tira 300 gramas de queijo" | subtrai do estoque (se zerar, apaga) |
| "remover o leite" / "acabou o café" / "o leite acabou" | apaga o item |
| "adicionar 2 ovos e remover o queijo" | vários comandos de uma vez |

O app sempre mostra uma prévia ("O que vai mudar") e só grava quando você toca em **Confirmar**. O texto reconhecido fica num campo editável: dá pra corrigir uma palavra errada ou digitar o comando. Converte g↔kg e ml↔L sozinho e ignora acento/plural/maiúscula ao procurar o item.

**Onde funciona:**

| Onde | Observação |
| --- | --- |
| Celular Android | ✅ Usa o reconhecimento do Google (precisa do app Google instalado) |
| Emulador Android | ⚠️ No emulador, abra os "..." (Extended controls) → Microphone → ligue **"Virtual microphone uses host audio input"**. Use uma imagem com Google Play |
| Chrome (`flutter run -d chrome`) | ✅ O Chrome pede permissão do microfone na primeira vez |
| iPhone / Mac | ✅ Pede permissão de microfone e de reconhecimento de fala |

Se o microfone não estiver disponível, a tela avisa e você pode **digitar** o comando no campo — a interpretação é a mesma.

**Testes da interpretação das frases:** `flutter test test/comando_voz_test.dart`

---

## Receitas em português (arquivo local, sem esperar a API)

A tela de Receitas **não usa mais o servidor Flask**. As receitas ficam no arquivo `raia_app/assets/receitas_pt.json`, que já vem traduzido, e o app procura nele na hora, sem internet.

**Gerar o arquivo (só uma vez, ou quando quiser atualizar):** dentro de `IA`, com o venv ativado:

```
pip install -r requirements.txt
python gerar_receitas_pt.py
```

O script baixa **todas** as receitas do TheMealDB, traduz nome, ingredientes, medidas (libras e onças viram gramas) e modo de preparo para português e grava o arquivo. Leva alguns minutos na primeira vez. Se a internet cair, rode de novo: ele continua de onde parou (cache em `IA/cache_traducoes.json`).

Depois disso, **pare e rode o app de novo** (`flutter run`). Hot reload não recarrega arquivos de assets.

**Na tela de Receitas:**
- As sugestões são as receitas que usam itens do seu estoque, das que faltam menos ingredientes para as que faltam mais (as que usam itens perto de vencer sobem).
- A busca procura em **todas** as receitas: nome, ingrediente ("frango", "chocolate"), categoria ("sobremesa", "massas") ou país ("italiana").
- Água, gelo, sal e pimenta-do-reino não contam como "faltando".
- O detalhe da receita mostra a lista completa de ingredientes, com ✅ para o que você tem e 🛒 para o que falta.

Se a tela mostrar "O arquivo de receitas ainda não foi gerado", é porque o script ainda não foi rodado.

## QR code / código de barras

No botão "+" escolha **QR Code / código de barras**. A câmera abre, lê o código do produto e o app consulta o nome no Open Food Facts (base gratuita, não precisa de chave). O formulário "Manual" abre já com o nome preenchido; é só conferir quantidade, unidade e validade.

- Precisa de internet para buscar o nome. Sem internet, ou se o produto não estiver na base, o formulário abre vazio para você digitar.
- Rode `flutter pub get` depois de baixar estas mudanças (foi adicionado o pacote `mobile_scanner`).
- A câmera não funciona no emulador sem câmera configurada; teste num celular de verdade.
- Permissões já configuradas: `CAMERA` no Android e `NSCameraUsageDescription` no iOS/macOS.

## Adicionar por foto (cupom fiscal ou lista)

No botão "+" escolha **Foto da nota ou lista**. Tire uma foto (ou escolha da galeria) do cupom do mercado ou de uma lista escrita. O app lê as palavras da foto no próprio celular (ML Kit do Google, sem internet) e mostra os alimentos encontrados com nome, quantidade e unidade. Você pode corrigir, desmarcar ou adicionar itens; ao salvar, ele mostra o que vai mudar e soma com o que já existe no estoque, igual ao comando de voz.

- Cupom: entende linhas como `ARROZ T1 5KG 1 UN X 25,90` (vira 5 kg de arroz), `LEITE 1L 6 UN X 4,79` (6 L) e itens a peso (`BANANA 1,235 KG`). Cabeçalho, total, pagamento e endereço são ignorados.
- Lista: cada linha é lida como no comando de voz (`2 kg de arroz`, `6 ovos`, `leite`).
- Dicas para a foto: cupom esticado e reto, boa luz, sem sombra, ocupando a tela toda.
- Funciona no Android e no iPhone. No navegador/macOS use "Digitar texto" (serve também para testar no emulador).
- Depois de baixar: `flutter pub get`. No iPhone o mínimo passou a ser iOS 15.5 (exigência do ML Kit); o `ios/Podfile` já está configurado — se der erro de pods, rode `cd ios && pod install --repo-update`.
- Testes do leitor: `flutter test test/texto_foto_parser_test.dart`.
