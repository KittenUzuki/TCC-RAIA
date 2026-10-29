import 'package:raia_app/models/comando_voz.dart';
import 'package:raia_app/services/comando_voz_parser.dart';
import 'package:raia_app/services/estoque_voz_service.dart';

/// Um pedaço de texto reconhecido na foto, com a posição dele na imagem.
class TrechoTexto {
  final String texto;
  final double esquerda;
  final double topo;
  final double direita;
  final double base;

  const TrechoTexto(this.texto, this.esquerda, this.topo, this.direita, this.base);

  double get altura => base - topo;
}

/// Um alimento encontrado na foto. O usuário confere (e pode corrigir)
/// antes de ir para o estoque.
class ItemFoto {
  String nome;
  double quantidade;

  /// Uma das unidades do app: 'un', 'g', 'kg', 'ml', 'L'.
  String unidade;

  /// Linha da foto de onde o item saiu (mostrada na tela de conferência).
  final String linhaOriginal;

  ItemFoto({
    required this.nome,
    required this.quantidade,
    required this.unidade,
    this.linhaOriginal = '',
  });

  @override
  String toString() => 'ItemFoto("$nome", $quantidade, $unidade)';
}

/// Transforma o texto lido de uma foto em itens de estoque.
///
/// Dart puro (sem Flutter/Firebase), testável com
/// `flutter test test/texto_foto_parser_test.dart`.
///
/// Entende dois tipos de foto:
///  * Cupom / nota fiscal de mercado, linha a linha:
///      "001 7891234567890 ARROZ TIO JOAO T1 5KG 1 UN X 25,90 25,90"
///        -> Arroz tio joão, 5 kg
///      "LEITE INTEGRAL 1L 2 UN X 4,99 9,98"   -> Leite integral, 2 L
///      "BANANA PRATA 1,235 KG X 6,99 8,63"     -> Banana prata, 1,235 kg
///    Cabeçalho e rodapé (CNPJ, TOTAL, pagamento, endereço...) são ignorados.
///  * Lista escrita: "2 kg de arroz", "6 ovos", "leite" — cada linha passa
///    pelo mesmo interpretador do comando de voz.
class TextoFotoParser {
  TextoFotoParser._();

  // ---------------------------------------------------------------------------
  // 1) Montar as linhas a partir das caixas de texto do OCR
  // ---------------------------------------------------------------------------

  /// O OCR costuma separar o nome do produto e o preço em blocos diferentes
  /// (colunas). Aqui juntamos de volta tudo que está na mesma altura da foto,
  /// da esquerda para a direita, formando as linhas do cupom.
  static List<String> montarLinhas(List<TrechoTexto> trechos) {
    final ordenados = trechos.where((t) => t.texto.trim().isNotEmpty).toList()
      ..sort((a, b) => (a.topo + a.base).compareTo(b.topo + b.base));

    final linhas = <_Linha>[];
    for (final t in ordenados) {
      _Linha? melhor;
      var melhorFracao = 0.0;
      for (final l in linhas) {
        final cima = t.topo > l.topo ? t.topo : l.topo;
        final baixo = t.base < l.base ? t.base : l.base;
        final menorAltura = t.altura < l.altura ? t.altura : l.altura;
        if (menorAltura <= 0) continue;
        final fracao = (baixo - cima) / menorAltura;
        if (fracao >= 0.5 && fracao > melhorFracao) {
          melhor = l;
          melhorFracao = fracao;
        }
      }
      if (melhor == null) {
        linhas.add(_Linha(t));
      } else {
        melhor.adicionar(t);
      }
    }

    linhas.sort((a, b) => a.topo.compareTo(b.topo));
    return linhas.map((l) => l.texto).toList();
  }

  // ---------------------------------------------------------------------------
  // 2) Interpretar o texto
  // ---------------------------------------------------------------------------

  static List<ItemFoto> interpretar(String texto) {
    final itens = <ItemFoto>[];

    // Linha de cupom com nome mas sem quantidade: a quantidade pode estar na
    // linha de baixo (ex.: "1 UN X 25,90 25,90" sozinha).
    _LinhaNota? pendente;

    void fecharPendente() {
      if (pendente != null) {
        final item = _paraItem(pendente!);
        if (item != null) itens.add(item);
        pendente = null;
      }
    }

    for (final bruta in texto.split(RegExp(r'\r?\n'))) {
      final linha = bruta.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (linha.length < 2 || _ehCabecalhoOuRodape(linha)) continue;

      if (_pareceLinhaDeNota(linha)) {
        final lida = _lerLinhaDeNota(linha);
        if (lida.nome.isEmpty) {
          // Só quantidade/preço: completa o produto da linha de cima.
          if (pendente != null && lida.qtd != null) {
            pendente!.qtd = lida.qtd;
            pendente!.unidQtd = lida.unidQtd;
            fecharPendente();
          }
          continue;
        }
        fecharPendente();
        if (lida.qtd == null) {
          pendente = lida;
        } else {
          final item = _paraItem(lida);
          if (item != null) itens.add(item);
        }
      } else {
        fecharPendente();
        if (!_letras.hasMatch(linha)) continue;
        itens.addAll(_lerLinhaDeLista(linha));
      }
    }
    fecharPendente();

    return _juntarRepetidos(itens);
  }

  static final _letras = RegExp(r'[A-Za-zÀ-ÿ]{2,}');
  static final _preco = RegExp(r'\d+[.,]\d{2}(?![\d%A-Za-z])');
  static final _codigoBarras = RegExp(r'\b\d{8,14}\b');
  static const _unidadesNota = r'UN|UND|UNID|PC|PCT|CX|KG|GR|G|LT|L|ML';
  static final _qtdComX = RegExp(
      r'(\d+(?:[.,]\d+)?)\s*(' + _unidadesNota + r')?\s*[X\*]\s*\d+[.,]\d{2}');
  static final _qtdSemX = RegExp(
      r'(\d+(?:[.,]\d+)?)\s*(' + _unidadesNota + r')\s+\d+[.,]\d{2}');
  static final _embalagem =
      RegExp(r'(\d+(?:[.,]\d+)?)\s*(KG|GR|G|ML|LT|L)(?![A-Z])');

  /// Cupom: tem preço, código de barras, "2 UN X", ou está todo em
  /// maiúsculas (padrão das notas). Lista escrita à mão normalmente não.
  static bool _pareceLinhaDeNota(String linha) {
    final alta = linha.toUpperCase();
    if (_preco.hasMatch(alta) ||
        _codigoBarras.hasMatch(alta) ||
        _qtdComX.hasMatch(alta)) {
      return true;
    }
    // Lista escrita em maiúsculas começando com quantidade ("2 KG DE ARROZ")
    // continua sendo lista; item de cupom começa com código ("001 ARROZ").
    if (RegExp(r'^[1-9]\d?(?:[.,]\d+)?\s').hasMatch(linha)) return false;
    final letras = linha.replaceAll(RegExp(r'[^A-Za-zÀ-ÿ]'), '');
    if (letras.length < 4) return false;
    final maiusculas = letras.replaceAll(RegExp(r'[^A-ZÀ-Þ]'), '');
    return maiusculas.length / letras.length >= 0.8;
  }

  static bool _ehCabecalhoOuRodape(String linha) {
    if (RegExp(r'\d{1,2}/\d{1,2}/\d{2,4}').hasMatch(linha)) return true;
    if (RegExp(r'\b\d{1,2}:\d{2}\b').hasMatch(linha)) return true;
    final palavras = _semAcento(linha.toLowerCase())
        .split(RegExp(r'[^a-z0-9]+'))
        .where((p) => p.isNotEmpty);
    return palavras.any(_palavrasIgnorar.contains);
  }

  static _LinhaNota _lerLinhaDeNota(String original) {
    var s = ' ${original.toUpperCase()} ';
    s = s.replaceAll(_codigoBarras, ' ');
    // nº do item ("001 ARROZ"), mas não a quantidade ("3 UN X 4,50")
    s = s.replaceFirst(
        RegExp(r'^\s*\d{1,4}\s+(?!(?:' + _unidadesNota + r')\b|[X\*])'),
        ' ');

    final lida = _LinhaNota(original);
    String parteNome;
    final m = _qtdComX.firstMatch(s) ?? _qtdSemX.firstMatch(s);
    if (m != null) {
      lida.qtd = _numero(m.group(1)!);
      lida.unidQtd = m.group(2);
      parteNome = s.substring(0, m.start);
    } else {
      final p = _preco.firstMatch(s);
      parteNome = p == null ? s : s.substring(0, p.start);
    }

    final embs = _embalagem.allMatches(parteNome).toList();
    if (embs.isNotEmpty) {
      final e = embs.last;
      lida.emb = _numero(e.group(1)!);
      lida.unidEmb = e.group(2);
      parteNome =
          parteNome.substring(0, e.start) + ' ' + parteNome.substring(e.end);
    }

    lida.nome = _limparNome(parteNome);
    return lida;
  }

  static String _limparNome(String texto) {
    final palavras = <String>[];
    for (final tok in texto.split(RegExp(r'[\s\-\.,;:\(\)\*\+#"|]+'))) {
      if (tok.isEmpty) continue;
      if (RegExp(r'\d').hasMatch(tok)) continue; // códigos, T1, 17%, números
      final chave = _semAcento(tok.toLowerCase());
      if (chave == 'c/') {
        palavras.add('com');
        continue;
      }
      if (chave == 's/') {
        palavras.add('sem');
        continue;
      }
      final soLetras = chave.replaceAll(RegExp(r'[^a-z]'), '');
      if (soLetras.length < 2 || _ruido.contains(soLetras)) continue;
      palavras.add(_expandir[soLetras] ??
          _acentuar(tok.toLowerCase().replaceAll(RegExp(r'[^a-zà-ÿ]'), '')));
    }
    while (palavras.isNotEmpty && _sobraNasPontas.contains(palavras.last)) {
      palavras.removeLast();
    }
    while (palavras.isNotEmpty && _sobraNasPontas.contains(palavras.first)) {
      palavras.removeAt(0);
    }
    return EstoqueVozService.capitalizar(palavras.join(' '));
  }

  static ItemFoto? _paraItem(_LinhaNota l) {
    if (l.nome.length < 2) return null;
    double q;
    String u;
    final unidadeComprada = _unidadeApp(l.unidQtd);
    if (l.qtd != null && unidadeComprada != 'un') {
      // Vendido a peso/volume: "BANANA 1,235 KG X 6,99"
      q = l.qtd!;
      u = unidadeComprada;
    } else {
      final n = l.qtd ?? 1;
      if (l.emb != null && l.emb! > 0) {
        // "LEITE 1L 2 UN" -> 2 L
        q = n * l.emb!;
        u = _unidadeApp(l.unidEmb);
      } else {
        q = n;
        u = 'un';
      }
    }
    if (q <= 0) return null;
    if (u == 'g' && q >= 1000) {
      q = q / 1000;
      u = 'kg';
    } else if (u == 'ml' && q >= 1000) {
      q = q / 1000;
      u = 'L';
    }
    return ItemFoto(
      nome: l.nome,
      quantidade: _arredondar(q),
      unidade: u,
      linhaOriginal: l.original,
    );
  }

  static List<ItemFoto> _lerLinhaDeLista(String linha) {
    // Tira marcador de lista: "- arroz", "• leite", "1) ovos", "2. feijão"
    final limpa = linha
        .replaceFirst(RegExp(r'^\s*(?:[-•*·>]+|\d{1,2}[.)]\s+)\s*'), '')
        .trim();
    if (!_letras.hasMatch(limpa)) return const [];

    final r = ComandoVozParser.interpretar(limpa,
        padrao: TipoComando.adicionar);
    return r.comandos
        .where((c) =>
            c.tipo == TipoComando.adicionar && c.nome.trim().length >= 2)
        .map((c) => ItemFoto(
              nome: EstoqueVozService.capitalizar(c.nome),
              quantidade: c.quantidade ?? 1,
              unidade: c.unidade ?? 'un',
              linhaOriginal: linha,
            ))
        .toList();
  }

  /// O mesmo produto pode aparecer mais de uma vez no cupom: soma.
  static List<ItemFoto> _juntarRepetidos(List<ItemFoto> itens) {
    final resultado = <ItemFoto>[];
    for (final item in itens) {
      final igual = resultado.where((r) =>
          _semAcento(r.nome.toLowerCase()) ==
              _semAcento(item.nome.toLowerCase()) &&
          r.unidade == item.unidade);
      if (igual.isNotEmpty) {
        igual.first.quantidade =
            _arredondar(igual.first.quantidade + item.quantidade);
      } else {
        resultado.add(item);
      }
    }
    return resultado;
  }

  // ---------------------------------------------------------------------------
  // Auxiliares
  // ---------------------------------------------------------------------------

  /// Nota fiscal vem sem acento: "FEIJAO", "LIMOES", "PAES". As terminações
  /// -ao/-oes/-aes quase sempre são -ão/-ões/-ães em português.
  static String _acentuar(String p) {
    if (p.length < 3 || p != _semAcento(p)) return p; // já tem acento
    if (p.endsWith('ao')) return '${p.substring(0, p.length - 2)}ão';
    if (p.endsWith('oes')) return '${p.substring(0, p.length - 3)}ões';
    if (p.endsWith('aes')) return '${p.substring(0, p.length - 3)}ães';
    return p;
  }

  static double _numero(String s) => double.tryParse(s.replaceAll(',', '.')) ?? 0;

  static double _arredondar(double v) => (v * 1000).roundToDouble() / 1000;

  static String _unidadeApp(String? u) {
    switch (u) {
      case 'KG':
        return 'kg';
      case 'G':
      case 'GR':
        return 'g';
      case 'L':
      case 'LT':
        return 'L';
      case 'ML':
        return 'ml';
      default:
        return 'un';
    }
  }

  static String _semAcento(String s) {
    const de = 'áàâãäéèêëíìîïóòôõöúùûüç';
    const para = 'aaaaaeeeeiiiiooooouuuuc';
    final sb = StringBuffer();
    for (final ch in s.split('')) {
      final i = de.indexOf(ch);
      sb.write(i >= 0 ? para[i] : ch);
    }
    return sb.toString();
  }

  /// Se a linha tiver qualquer uma destas palavras, é cabeçalho/rodapé da
  /// nota (ou título da lista) e não um produto.
  static const _palavrasIgnorar = {
    'cnpj', 'cpf', 'ie', 'im', 'ccf', 'coo', 'total', 'subtotal', 'troco',
    'dinheiro', 'cartao', 'credito', 'debito', 'pix', 'desconto',
    'descontos', 'acrescimo', 'acrescimos', 'icms', 'pis', 'cofins',
    'tributos', 'tributo', 'imposto', 'impostos', 'aproximado', 'cupom',
    'nfce', 'nfc', 'danfe', 'sat', 'fiscal', 'consumidor', 'chave',
    'acesso', 'protocolo', 'autorizacao', 'serie', 'emissao', 'operador',
    'vendedor', 'pagamento', 'pago', 'pagar', 'valor', 'valores', 'qtd',
    'qtde', 'quant', 'descricao', 'codigo', 'cod', 'obrigado', 'obrigada',
    'volte', 'www', 'http', 'https', 'tel', 'telefone', 'fone', 'whatsapp',
    'rua', 'av', 'avenida', 'rodovia', 'cep', 'bairro', 'ltda', 'eireli',
    'epp', 'cliente', 'consulte', 'sefaz', 'data', 'hora', 'extrato', 'doc',
    'documento', 'item', 'itens', 'vl', 'unit', 'unitario',
    'recebido', 'saldo', 'parcela', 'parcelas', 'nsu', 'aut', 'lista',
    'compras', 'supermercado', 'supermercados', 'mercado', 'atacadista',
    'atacadao', 'hipermercado', 'loja', 'filial', 'endereco', 'municipio',
    'padaria', 'emporio', 'comercio', 'comercial', 'distribuidora',
  };

  /// Palavras que não fazem parte do nome do produto.
  static const _ruido = {
    'un', 'und', 'unid', 'pc', 'pct', 'pcte', 'cx', 'emb', 'bdj', 'bandeja',
    'kg', 'gr', 'lt', 'ml', 'tipo', 'unidade', 'pacote',
  };

  static const _sobraNasPontas = {'de', 'do', 'da', 'com', 'sem', 'e'};

  /// Abreviações comuns em cupom e palavras que a nota escreve sem acento.
  static const Map<String, String> _expandir = {
    // abreviações
    'qjo': 'queijo', 'qj': 'queijo', 'muss': 'muçarela',
    'mussarela': 'muçarela', 'mucarela': 'muçarela', 'req': 'requeijão',
    'requeij': 'requeijão', 'bisc': 'biscoito', 'refri': 'refrigerante',
    'refrig': 'refrigerante', 'choc': 'chocolate', 'achoc': 'achocolatado',
    'marg': 'margarina', 'mant': 'manteiga', 'integ': 'integral',
    'desn': 'desnatado', 'semid': 'semidesnatado', 'trad': 'tradicional',
    'cr': 'creme', 'fgo': 'frango', 'frgo': 'frango', 'cong': 'congelado',
    'resf': 'resfriado', 'temp': 'temperado', 'deterg': 'detergente',
    'lte': 'leite', 'macarr': 'macarrão', 'parb': 'parboilizado',
    'extr': 'extrato', 'molh': 'molho', 'farin': 'farinha',
    'iog': 'iogurte', 'beb': 'bebida', 'hig': 'higiênico',
    'ref': 'refinado', 'frances': 'francês', 'parbo': 'parboilizado',
    // acentos
    'acucar': 'açúcar', 'feijao': 'feijão', 'macarrao': 'macarrão',
    'cafe': 'café', 'pao': 'pão', 'paes': 'pães', 'limao': 'limão',
    'mamao': 'mamão', 'melao': 'melão', 'maca': 'maçã', 'macas': 'maçãs',
    'file': 'filé', 'cha': 'chá', 'oleo': 'óleo', 'agua': 'água',
    'requeijao': 'requeijão', 'linguica': 'linguiça', 'acem': 'acém',
    'musculo': 'músculo', 'coxao': 'coxão', 'fuba': 'fubá',
    'oregano': 'orégano', 'pimentao': 'pimentão', 'abobora': 'abóbora',
    'brocolis': 'brócolis', 'pessego': 'pêssego', 'salmao': 'salmão',
    'camarao': 'camarão', 'tilapia': 'tilápia', 'po': 'pó', 'grao': 'grão',
    'graos': 'grãos', 'higienico': 'higiênico', 'sabao': 'sabão',
    'alcool': 'álcool', 'lacteo': 'lácteo', 'organico': 'orgânico',
    'acai': 'açaí', 'maracuja': 'maracujá', 'jilo': 'jiló', 'pure': 'purê',
    'paprica': 'páprica', 'acafrao': 'açafrão', 'manjericao': 'manjericão',
  };
}

class _Linha {
  final List<TrechoTexto> trechos;
  double topo;
  double base;

  _Linha(TrechoTexto t)
      : trechos = [t],
        topo = t.topo,
        base = t.base;

  double get altura => base - topo;

  void adicionar(TrechoTexto t) {
    trechos.add(t);
    final n = trechos.length;
    topo = topo + (t.topo - topo) / n;
    base = base + (t.base - base) / n;
  }

  String get texto {
    final ordem = [...trechos]..sort((a, b) => a.esquerda.compareTo(b.esquerda));
    return ordem.map((t) => t.texto.trim()).join(' ');
  }
}

class _LinhaNota {
  final String original;
  String nome = '';
  double? qtd;
  String? unidQtd;
  double? emb;
  String? unidEmb;

  _LinhaNota(this.original);
}
