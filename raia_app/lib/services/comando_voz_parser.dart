import 'package:raia_app/models/comando_voz.dart';

/// Transforma o texto reconhecido pela voz em comandos de estoque.
///
/// Este arquivo é Dart puro (não depende de Flutter nem do Firebase), então
/// dá pra testar com `flutter test test/comando_voz_parser_test.dart`.
///
/// Frases que ele entende (exemplos):
///   "adicionar 2 kg de arroz"
///   "adiciona três ovos e um litro de leite"
///   "comprei meia dúzia de ovos"
///   "coloca dois quilos e meio de batata"
///   "remover o leite"                 -> apaga o leite do estoque
///   "tira 2 ovos" / "usei 2 ovos"     -> subtrai 2 ovos
///   "acabou o café"                   -> apaga o café
///   "o leite acabou"                  -> apaga o leite
///   "adicionar 2 ovos e remover o queijo"  (vários comandos na mesma frase)
class ComandoVozParser {
  ComandoVozParser._();

  /// Interpreta [texto]. Quando a frase não tem verbo (ex.: só "2 kg de
  /// arroz"), usa [padrao] como ação.
  static ResultadoInterpretacao interpretar(
    String texto, {
    TipoComando padrao = TipoComando.adicionar,
  }) {
    final palavras = _quebrarEmPalavras(texto);
    var toks = _agruparNumeros(palavras);
    toks = _juntarEMeio(toks);
    toks = _removerLocaisEExpressoes(toks);

    // 1) Separa por vírgula / "e" / "depois"
    final segmentos = <List<_Tok>>[];
    var atual = <_Tok>[];
    for (final t in toks) {
      if (_separadores.contains(t.chave)) {
        if (atual.isNotEmpty) segmentos.add(atual);
        atual = <_Tok>[];
      } else {
        atual.add(t);
      }
    }
    if (atual.isNotEmpty) segmentos.add(atual);

    // 2) Dentro de cada segmento, separa itens falados sem "e"
    //    ("adicionar 2 ovos 3 tomates", "adicionar 2 ovos remover o leite")
    final itens = <_ItemBruto>[];
    for (final seg in segmentos) {
      itens.addAll(_quebrarSegmento(seg));
    }

    // 3) Decide adicionar/remover de cada item (herda o verbo anterior)
    final comandos = <ComandoVoz>[];
    final ignorados = <String>[];
    TipoComando? herdado;
    for (var i = 0; i < itens.length; i++) {
      final item = itens[i];
      TipoComando tipo;
      if (item.verbo != null) {
        tipo = item.verbo!;
        herdado = tipo;
      } else if (herdado != null) {
        tipo = herdado;
      } else {
        // Nenhum verbo ainda: procura um verbo "no fim" mais à frente,
        // como em "o leite e o café acabaram".
        final posterior = itens
            .skip(i + 1)
            .where((it) => it.verbo != null)
            .cast<_ItemBruto?>()
            .firstWhere((_) => true, orElse: () => null);
        tipo = (posterior != null && posterior.verboNoFim)
            ? posterior.verbo!
            : padrao;
      }

      if (item.nome.isEmpty) {
        // Só verbo ("adicionar"), ou só número: não vira comando.
        if (item.verbo == null && item.trecho.isNotEmpty) {
          ignorados.add(item.trecho);
        }
        continue;
      }

      comandos.add(ComandoVoz(
        tipo: tipo,
        nome: item.nome,
        quantidade: item.quantidade,
        unidade: item.unidade,
        trecho: item.trecho,
      ));
    }

    return ResultadoInterpretacao(comandos, ignorados);
  }

  // ---------------------------------------------------------------------------
  // Vocabulário (tudo em minúsculo e SEM acento)
  // ---------------------------------------------------------------------------

  static const _verbosAdicionar = {
    'adicionar', 'adiciona', 'adicione', 'adicionei', 'adicionem',
    'acrescentar', 'acrescenta', 'acrescente', 'acrescentei',
    'colocar', 'coloca', 'coloque', 'coloquei',
    'por', 'poe', 'ponha', 'pus', 'botar', 'bota', 'bote', 'botei',
    'incluir', 'inclui', 'inclua', 'inclusao',
    'cadastrar', 'cadastra', 'cadastre', 'registrar', 'registra', 'registre',
    'guardar', 'guarda', 'guarde', 'guardei',
    'comprei', 'compramos', 'comprar', 'compra',
    'ganhei', 'add', 'adicao',
  };

  static const _verbosRemover = {
    'remover', 'remove', 'remova', 'removi', 'removam',
    'tirar', 'tira', 'tire', 'tirei', 'retirar', 'retira', 'retire', 'retirei',
    'apagar', 'apaga', 'apague', 'apaguei',
    'excluir', 'exclui', 'exclua', 'excluiu',
    'deletar', 'deleta', 'delete', 'deletei',
    'descartar', 'descarta', 'descarte', 'descartei',
    'jogar', 'joga', 'jogue', 'joguei',
    'usar', 'usei', 'usamos', 'gastar', 'gastei', 'gastamos',
    'consumi', 'consumimos', 'comi', 'comemos', 'bebi', 'bebemos',
    'acabou', 'acabaram', 'terminou', 'terminaram', 'venceu', 'venceram',
    'estragou', 'estragaram', 'zerar', 'zera', 'zere',
    'menos', 'subtrair', 'subtrai', 'diminuir', 'diminui', 'diminua',
  };

  static const _separadores = {',', 'e', 'depois', 'entao'};

  /// Palavras que não fazem parte do nome do alimento.
  static const _enchimento = {
    'eu', 'nos', 'voce', 'me', 'ai', 'agora', 'hoje', 'ja', 'que', 'tambem',
    'todo', 'toda', 'todos', 'todas', 'tudo', 'mais', 'fora', 'so',
    'apenas', 'ainda', 'aqui', 'la', 'pra', 'para', 'ok', 'tipo', 'favor',
    'raia', 'novo', 'nova', 'novos', 'novas', 'vou', 'vamos', 'quero',
    'queria', 'gostaria', 'preciso', 'pode', 'poderia', 'consegue', 'gente',
    'acabei', 'tenho', 'tem', 'temos', 'nao', 'sim', 'oi', 'ola',
  };

  /// Locais que a pessoa pode citar: "no estoque", "da geladeira"...
  static const _locais = {
    'estoque', 'despensa', 'geladeira', 'lista', 'armario', 'freezer',
    'carrinho', 'sistema', 'app', 'aplicativo', 'inventario',
  };

  static const _preposicoesDeLocal = {
    'no', 'na', 'nos', 'nas', 'ao', 'aos', 'do', 'da', 'dos', 'das', 'pro',
    'pra', 'para', 'a', 'o', 'meu', 'minha', 'de', 'em', 'nesse', 'nessa',
  };

  static const _conectores = {'de', 'do', 'da', 'dos', 'das'};
  static const _artigos = {'o', 'a', 'os', 'as'};
  static const _lixoNoFim = {'de', 'do', 'da', 'dos', 'das', 'o', 'a', 'os', 'as', 'com'};

  /// palavra -> (unidade do app, multiplicador, éEmbalagem)
  static const Map<String, _Unidade> _unidades = {
    'kg': _Unidade('kg'), 'quilo': _Unidade('kg'), 'quilos': _Unidade('kg'),
    'kilo': _Unidade('kg'), 'kilos': _Unidade('kg'), 'kgs': _Unidade('kg'),
    'quilograma': _Unidade('kg'), 'quilogramas': _Unidade('kg'),
    'kilograma': _Unidade('kg'), 'kilogramas': _Unidade('kg'),
    'g': _Unidade('g'), 'gr': _Unidade('g'), 'grs': _Unidade('g'),
    'grama': _Unidade('g'), 'gramas': _Unidade('g'),
    'l': _Unidade('L'), 'lt': _Unidade('L'), 'lts': _Unidade('L'),
    'litro': _Unidade('L'), 'litros': _Unidade('L'),
    'ml': _Unidade('ml'), 'mililitro': _Unidade('ml'),
    'mililitros': _Unidade('ml'),
    'un': _Unidade('un'), 'und': _Unidade('un'), 'unid': _Unidade('un'),
    'unidade': _Unidade('un'), 'unidades': _Unidade('un'),
    'duzia': _Unidade('un', fator: 12), 'duzias': _Unidade('un', fator: 12),
    // Embalagens viram "un" e saem do nome ("2 latas de milho" -> milho, 2 un)
    'pacote': _Unidade('un', embalagem: true),
    'pacotes': _Unidade('un', embalagem: true),
    'pacotinho': _Unidade('un', embalagem: true),
    'pacotinhos': _Unidade('un', embalagem: true),
    'caixa': _Unidade('un', embalagem: true),
    'caixas': _Unidade('un', embalagem: true),
    'caixinha': _Unidade('un', embalagem: true),
    'caixinhas': _Unidade('un', embalagem: true),
    'lata': _Unidade('un', embalagem: true),
    'latas': _Unidade('un', embalagem: true),
    'latinha': _Unidade('un', embalagem: true),
    'latinhas': _Unidade('un', embalagem: true),
    'garrafa': _Unidade('un', embalagem: true),
    'garrafas': _Unidade('un', embalagem: true),
    'saco': _Unidade('un', embalagem: true),
    'sacos': _Unidade('un', embalagem: true),
    'saquinho': _Unidade('un', embalagem: true),
    'saquinhos': _Unidade('un', embalagem: true),
    'pote': _Unidade('un', embalagem: true),
    'potes': _Unidade('un', embalagem: true),
    'potinho': _Unidade('un', embalagem: true),
    'potinhos': _Unidade('un', embalagem: true),
    'vidro': _Unidade('un', embalagem: true),
    'vidros': _Unidade('un', embalagem: true),
    'bandeja': _Unidade('un', embalagem: true),
    'bandejas': _Unidade('un', embalagem: true),
    'fardo': _Unidade('un', embalagem: true),
    'fardos': _Unidade('un', embalagem: true),
    'embalagem': _Unidade('un', embalagem: true),
    'embalagens': _Unidade('un', embalagem: true),
  };

  static const Map<String, double> _numerosPorExtenso = {
    'zero': 0, 'um': 1, 'uma': 1, 'dois': 2, 'duas': 2, 'tres': 3,
    'quatro': 4, 'cinco': 5, 'seis': 6, 'sete': 7, 'oito': 8, 'nove': 9,
    'dez': 10, 'onze': 11, 'doze': 12, 'treze': 13, 'quatorze': 14,
    'catorze': 14, 'quinze': 15, 'dezesseis': 16, 'dezasseis': 16,
    'dezessete': 17, 'dezoito': 18, 'dezenove': 19, 'vinte': 20,
    'trinta': 30, 'quarenta': 40, 'cinquenta': 50, 'sessenta': 60,
    'setenta': 70, 'oitenta': 80, 'noventa': 90, 'cem': 100, 'cento': 100,
    'duzentos': 200, 'duzentas': 200, 'trezentos': 300, 'trezentas': 300,
    'quatrocentos': 400, 'quatrocentas': 400, 'quinhentos': 500,
    'quinhentas': 500, 'seiscentos': 600, 'seiscentas': 600,
    'setecentos': 700, 'setecentas': 700, 'oitocentos': 800,
    'oitocentas': 800, 'novecentos': 900, 'novecentas': 900,
  };

  // ---------------------------------------------------------------------------
  // Etapas
  // ---------------------------------------------------------------------------

  /// Minúsculas, separa pontuação e "2kg" -> "2 kg". Mantém acentos.
  static List<String> _quebrarEmPalavras(String texto) {
    var t = texto.toLowerCase().trim();
    // Protege o separador decimal: "1,5" / "1.5"
    t = t.replaceAllMapped(
        RegExp(r'(\d)[.,](\d)'), (m) => '${m[1]}\u0001${m[2]}');
    t = t.replaceAll(RegExp(r'[,;.!?:]'), ' , ');
    t = t.replaceAll('\u0001', '.');
    // "2kg" -> "2 kg", "500ml" -> "500 ml"
    t = t.replaceAllMapped(
        RegExp(r'(\d)([a-zà-ú])'), (m) => '${m[1]} ${m[2]}');
    t = t.replaceAll(RegExp(r'[-–—"“”()]'), ' ');
    return t.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  }

  static double? _valorPorExtenso(String chave) => _numerosPorExtenso[chave];

  static double? _valor(String palavra) {
    final d = double.tryParse(palavra);
    if (d != null) return d;
    return _valorPorExtenso(removerAcentos(palavra));
  }

  /// Junta "duzentos e cinquenta", "vinte e dois", "dois e meio",
  /// "mil e quinhentos" num único token numérico.
  static List<_Tok> _agruparNumeros(List<String> palavras) {
    final saida = <_Tok>[];
    var i = 0;
    while (i < palavras.length) {
      final w = palavras[i];
      final k = removerAcentos(w);
      final v = _valor(w);

      if (v == null) {
        if (k == 'meio' || k == 'meia') {
          saida.add(_Tok(w, numero: 0.5));
        } else if (k == 'mil') {
          saida.add(_Tok(w, numero: 1000)); // "mil gramas"
        } else {
          saida.add(_Tok(w));
        }
        i++;
        continue;
      }

      var total = 0.0;
      var atual = v;
      final partes = [w];
      var j = i + 1;
      while (j < palavras.length) {
        final kj = removerAcentos(palavras[j]);
        if (kj == 'mil') {
          total += (atual == 0 ? 1.0 : atual) * 1000;
          atual = 0;
          partes.add(palavras[j]);
          j++;
          continue;
        }
        if (kj == 'e' && j + 1 < palavras.length) {
          final prox = palavras[j + 1];
          final kp = removerAcentos(prox);
          if (kp == 'meio' || kp == 'meia') {
            // "dois e meio" — mas não "dois e meia dúzia de..."
            final depois =
                j + 2 < palavras.length ? removerAcentos(palavras[j + 2]) : '';
            if (depois != 'duzia' && depois != 'duzias') {
              atual += 0.5;
              partes..add(palavras[j])..add(prox);
              j += 2;
            }
            break;
          }
          final pv = _valorPorExtenso(kp);
          if (pv != null && _podeSomar(total, atual, pv)) {
            atual += pv;
            partes..add(palavras[j])..add(prox);
            j += 2;
            continue;
          }
        }
        break;
      }
      saida.add(_Tok(partes.join(' '), numero: total + atual));
      i = j;
    }
    return saida;
  }

  /// "vinte e dois" sim; "dois e três" não (são dois itens diferentes).
  static bool _podeSomar(double total, double atual, double proximo) {
    if (atual == 0 && total > 0) return proximo < 1000;
    if (atual >= 100 && atual % 100 == 0) return proximo < 100;
    if (atual >= 20 && atual % 10 == 0) return proximo < 10;
    return false;
  }

  /// "2 quilos e meio" -> 2.5 quilos (antes de separar pelo "e").
  static List<_Tok> _juntarEMeio(List<_Tok> toks) {
    final saida = <_Tok>[];
    var i = 0;
    while (i < toks.length) {
      if (i + 3 < toks.length &&
          toks[i].ehNumero &&
          _unidades.containsKey(toks[i + 1].chave) &&
          toks[i + 2].chave == 'e' &&
          toks[i + 3].numero == 0.5 &&
          (toks[i + 3].chave == 'meio' || toks[i + 3].chave == 'meia')) {
        saida.add(_Tok(toks[i].texto, numero: toks[i].numero! + 0.5));
        saida.add(toks[i + 1]);
        i += 4;
        continue;
      }
      saida.add(toks[i]);
      i++;
    }
    return saida;
  }

  /// Tira "no estoque", "da geladeira", "por favor"...
  static List<_Tok> _removerLocaisEExpressoes(List<_Tok> toks) {
    final saida = <_Tok>[];
    for (var i = 0; i < toks.length; i++) {
      final t = toks[i];
      if (t.chave == 'por' &&
          i + 1 < toks.length &&
          toks[i + 1].chave == 'favor') {
        i++; // pula "por favor"
        continue;
      }
      if (_locais.contains(t.chave)) {
        // remove até 3 preposições/artigos logo antes ("para o meu estoque")
        var removidas = 0;
        while (saida.isNotEmpty &&
            removidas < 3 &&
            !saida.last.ehNumero &&
            _preposicoesDeLocal.contains(saida.last.chave)) {
          saida.removeLast();
          removidas++;
        }
        continue;
      }
      saida.add(t);
    }
    return saida;
  }

  static TipoComando? _verbo(_Tok t) {
    if (t.ehNumero) return null;
    if (_verbosAdicionar.contains(t.chave)) return TipoComando.adicionar;
    if (_verbosRemover.contains(t.chave)) return TipoComando.remover;
    return null;
  }

  static bool _ehPalavraDeNome(_Tok t) =>
      !t.ehNumero &&
      _verbo(t) == null &&
      !_enchimento.contains(t.chave) &&
      !_unidades.containsKey(t.chave) &&
      !_conectores.contains(t.chave) &&
      !_artigos.contains(t.chave);

  /// Um segmento pode conter mais de um item quando a pessoa não fala "e":
  /// "adicionar 2 ovos 3 tomates" ou "adicionar 2 ovos remover o leite".
  static List<_ItemBruto> _quebrarSegmento(List<_Tok> seg) {
    final partes = <List<_Tok>>[];
    var atual = <_Tok>[];
    var temNome = false;
    var temNumero = false;

    bool temConteudoDepois(int idx) {
      for (var k = idx + 1; k < seg.length; k++) {
        if (seg[k].ehNumero || _ehPalavraDeNome(seg[k])) return true;
      }
      return false;
    }

    for (var i = 0; i < seg.length; i++) {
      final t = seg[i];
      final novoItemPorNumero = t.ehNumero && temNome && temNumero;
      final novoItemPorVerbo =
          _verbo(t) != null && temNome && temConteudoDepois(i);
      if (novoItemPorNumero || novoItemPorVerbo) {
        partes.add(atual);
        atual = <_Tok>[];
        temNome = false;
        temNumero = false;
      }
      atual.add(t);
      if (t.ehNumero) temNumero = true;
      if (_ehPalavraDeNome(t)) temNome = true;
    }
    if (atual.isNotEmpty) partes.add(atual);
    return partes.map(_montarItem).toList();
  }

  static _ItemBruto _montarItem(List<_Tok> toks) {
    TipoComando? verbo;
    var verboNoFim = false;
    double? quantidade;
    String? unidade;
    final nome = <_Tok>[];

    // posição do último token "de conteúdo" (pra saber se o verbo veio no fim)
    var ultimoConteudo = -1;
    for (var i = 0; i < toks.length; i++) {
      if (toks[i].ehNumero || _ehPalavraDeNome(toks[i])) ultimoConteudo = i;
    }

    var i = 0;
    while (i < toks.length) {
      final t = toks[i];
      final v = _verbo(t);

      if (v != null) {
        verbo ??= v;
        if (i > ultimoConteudo) verboNoFim = true;
        // "jogar fora", "pôr no" etc. — o resto é tratado como enchimento
        i++;
        continue;
      }

      if (t.ehNumero) {
        if (quantidade == null) {
          quantidade = t.numero;
          // unidade logo depois do número?
          if (i + 1 < toks.length && _unidades.containsKey(toks[i + 1].chave)) {
            final u = _unidades[toks[i + 1].chave]!;
            unidade = u.unidade;
            quantidade = quantidade! * u.fator;
            i++;
          }
          // pula "de/do/da" depois do número/unidade
          while (i + 1 < toks.length && _conectores.contains(toks[i + 1].chave)) {
            i++;
          }
        }
        i++;
        continue;
      }

      // Unidade sem número antes, no começo do item: "quilo de arroz",
      // "dúzia de ovos", "pacote de café"
      if (_unidades.containsKey(t.chave) && nome.isEmpty) {
        final temProximaPalavra = i + 1 < toks.length;
        // letras soltas ("l", "g") só valem como unidade depois de número
        if (t.chave.length > 1 && temProximaPalavra) {
          final u = _unidades[t.chave]!;
          unidade = u.unidade;
          // "quilo de arroz" = 1 kg; "dúzia de ovos" = 12 un.
          // Embalagem sem número ("o pacote de café") fica sem quantidade.
          if (!u.embalagem && quantidade == null) quantidade = u.fator;
          while (i + 1 < toks.length && _conectores.contains(toks[i + 1].chave)) {
            i++;
          }
          i++;
          continue;
        }
      }

      if (_enchimento.contains(t.chave)) {
        i++;
        continue;
      }

      nome.add(t);
      i++;
    }

    // Limpa artigos/conectores das pontas: "o leite" -> "leite"
    while (nome.isNotEmpty &&
        (_artigos.contains(nome.first.chave) ||
            _conectores.contains(nome.first.chave))) {
      nome.removeAt(0);
    }
    while (nome.isNotEmpty && _lixoNoFim.contains(nome.last.chave)) {
      nome.removeLast();
    }

    return _ItemBruto(
      verbo: verbo,
      verboNoFim: verboNoFim,
      nome: nome.map((t) => t.texto).join(' '),
      quantidade: quantidade,
      unidade: unidade,
      trecho: toks.map((t) => t.texto).join(' '),
    );
  }
}

/// Remove acentos (á -> a, ç -> c...). Usado pra comparar palavras.
String removerAcentos(String s) {
  const de = 'áàâãäéèêëíìîïóòôõöúùûüçñÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇÑ';
  const para = 'aaaaaeeeeiiiiooooouuuucnAAAAAEEEEIIIIOOOOOUUUUCN';
  final sb = StringBuffer();
  for (final ch in s.split('')) {
    final idx = de.indexOf(ch);
    sb.write(idx >= 0 ? para[idx] : ch);
  }
  return sb.toString();
}

class _Tok {
  final String texto; // como foi falado (minúsculo, com acento)
  final String chave; // sem acento, pra comparar
  final double? numero;

  _Tok(this.texto, {this.numero}) : chave = removerAcentos(texto);

  bool get ehNumero => numero != null;

  @override
  String toString() => ehNumero ? '#$numero' : texto;
}

class _Unidade {
  final String unidade;
  final double fator;
  final bool embalagem;
  const _Unidade(this.unidade, {this.fator = 1, this.embalagem = false});
}

class _ItemBruto {
  final TipoComando? verbo;
  final bool verboNoFim;
  final String nome;
  final double? quantidade;
  final String? unidade;
  final String trecho;

  _ItemBruto({
    required this.verbo,
    required this.verboNoFim,
    required this.nome,
    required this.quantidade,
    required this.unidade,
    required this.trecho,
  });
}
