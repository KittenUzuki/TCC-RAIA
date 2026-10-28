import 'package:raia_app/models/comando_voz.dart';
import 'package:raia_app/models/ingrediente.dart';
import 'package:raia_app/services/comando_voz_parser.dart';
import 'package:raia_app/services/ingrediente_service.dart';

/// O que vai acontecer no Firestore depois que o usuário confirmar.
enum TipoAcao { criar, atualizar, excluir }

class AcaoEstoque {
  final TipoAcao tipo;
  final Ingrediente ingrediente;
  const AcaoEstoque(this.tipo, this.ingrediente);
}

/// Uma linha da prévia mostrada ao usuário ("Somar 2 un em Ovos (fica 8 un)").
class LinhaPlano {
  final ComandoVoz comando;
  final String descricao;
  final bool ok; // false = não deu pra executar (item não encontrado etc.)
  const LinhaPlano(this.comando, this.descricao, {this.ok = true});
}

class PlanoVoz {
  final List<LinhaPlano> linhas;
  final List<AcaoEstoque> acoes;
  const PlanoVoz(this.linhas, this.acoes);

  bool get temAlteracoes => acoes.isNotEmpty;
}

/// Cruza os comandos de voz com o estoque atual e decide o que fazer.
///
/// Regras:
///  * ADICIONAR: se já existe um item com o mesmo nome (ignorando acento,
///    maiúscula e plural) e unidade compatível, SOMA na quantidade. Senão,
///    cria um item novo. Sem quantidade falada = 1.
///  * REMOVER sem quantidade ("remover o leite"): apaga o item.
///  * REMOVER com quantidade ("usei 2 ovos"): subtrai; se zerar, apaga.
///  * Converte g<->kg e ml<->L automaticamente.
///
/// A parte de planejar é pura (não acessa o Firebase) pra poder ser testada;
/// só [aplicar] grava de fato.
class EstoqueVozService {
  final IngredienteService _ingredienteService;

  EstoqueVozService({IngredienteService? ingredienteService})
      : _ingredienteService = ingredienteService ?? IngredienteService();

  /// Grava as ações no Firestore. Retorna quantas foram aplicadas.
  Future<int> aplicar(PlanoVoz plano) async {
    var feitas = 0;
    for (final acao in plano.acoes) {
      switch (acao.tipo) {
        case TipoAcao.criar:
          await _ingredienteService.adicionar(acao.ingrediente);
          break;
        case TipoAcao.atualizar:
          await _ingredienteService.atualizar(acao.ingrediente);
          break;
        case TipoAcao.excluir:
          await _ingredienteService.remover(acao.ingrediente.id);
          break;
      }
      feitas++;
    }
    return feitas;
  }

  static PlanoVoz planejar(
    List<ComandoVoz> comandos,
    List<Ingrediente> estoque,
    String userId,
  ) {
    final itens = estoque.map(_ItemTrabalho.doEstoque).toList();
    final linhas = <LinhaPlano>[];

    for (final c in comandos) {
      final ativos = itens.where((i) => !i.excluido).toList();
      final busca =
          _encontrar(c.nome, ativos, aceitarNomeMaior: c.tipo == TipoComando.remover);

      if (c.tipo == TipoComando.adicionar) {
        final qtdFalada = c.quantidade ?? 1;
        final item = busca.item;
        if (item != null) {
          final convertida =
              converterUnidade(qtdFalada, c.unidade ?? item.unidade, item.unidade);
          if (convertida != null) {
            item.quantidade = _arredondar(item.quantidade + convertida);
            linhas.add(LinhaPlano(
              c,
              'Somar ${formatarQuantidade(qtdFalada, c.unidade ?? item.unidade)} '
              'em ${item.nome} (fica ${formatarQuantidade(item.quantidade, item.unidade)})',
            ));
            continue;
          }
        }
        final unidade = c.unidade ?? 'un';
        final novo = _ItemTrabalho(
          original: null,
          nome: capitalizar(c.nome),
          quantidade: _arredondar(qtdFalada),
          unidade: unidade,
        );
        itens.add(novo);
        linhas.add(LinhaPlano(
          c,
          'Adicionar ${formatarQuantidade(qtdFalada, unidade)} de ${novo.nome} (novo)',
        ));
      } else {
        if (busca.item == null && busca.ambiguos.length > 1) {
          linhas.add(LinhaPlano(
            c,
            '"${c.nome}" combina com ${busca.ambiguos.map((i) => i.nome).join(', ')}. '
            'Fale o nome completo.',
            ok: false,
          ));
          continue;
        }
        final item = busca.item;
        if (item == null) {
          linhas.add(LinhaPlano(
            c,
            'Não encontrei "${c.nome}" no estoque',
            ok: false,
          ));
          continue;
        }
        if (c.quantidade == null) {
          item.excluido = true;
          linhas.add(LinhaPlano(c, 'Remover ${item.nome} do estoque'));
          continue;
        }
        final convertida =
            converterUnidade(c.quantidade!, c.unidade ?? item.unidade, item.unidade);
        if (convertida == null) {
          linhas.add(LinhaPlano(
            c,
            'Não dá pra tirar ${formatarQuantidade(c.quantidade!, c.unidade ?? item.unidade)} '
            'de ${item.nome}: no estoque está em "${item.unidade}"',
            ok: false,
          ));
          continue;
        }
        final restante = _arredondar(item.quantidade - convertida);
        final falado = formatarQuantidade(c.quantidade!, c.unidade ?? item.unidade);
        if (restante <= 0) {
          item.excluido = true;
          linhas.add(LinhaPlano(
            c,
            'Tirar $falado de ${item.nome} — acabou, será removido',
          ));
        } else {
          item.quantidade = restante;
          linhas.add(LinhaPlano(
            c,
            'Tirar $falado de ${item.nome} '
            '(fica ${formatarQuantidade(restante, item.unidade)})',
          ));
        }
      }
    }

    // Transforma o estado final em ações no banco
    final acoes = <AcaoEstoque>[];
    for (final i in itens) {
      final o = i.original;
      if (o == null) {
        if (!i.excluido) {
          acoes.add(AcaoEstoque(
            TipoAcao.criar,
            Ingrediente(
              id: '',
              userId: userId,
              nome: i.nome,
              quantidade: i.quantidade,
              unidade: i.unidade,
            ),
          ));
        }
      } else if (i.excluido) {
        acoes.add(AcaoEstoque(TipoAcao.excluir, o));
      } else if (i.quantidade != o.quantidade) {
        acoes.add(AcaoEstoque(
          TipoAcao.atualizar,
          o.copyWith(quantidade: i.quantidade),
        ));
      }
    }

    return PlanoVoz(linhas, acoes);
  }

  // ---------------------------------------------------------------------------
  // Busca por nome
  // ---------------------------------------------------------------------------

  /// Procura o item do estoque que o usuário quis dizer.
  ///
  /// 1. Nome igual (sem acento/maiúscula/plural): "ovos" == "Ovo"
  /// 2. Falou menos palavras: "leite" -> "Leite integral" (se for o único)
  /// 3. (só na remoção) Falou mais palavras: "leite integral" -> "Leite"
  static _Busca _encontrar(String nomeFalado, List<_ItemTrabalho> itens,
      {required bool aceitarNomeMaior}) {
    final falado = chaveNome(nomeFalado);
    if (falado.isEmpty) return const _Busca(null, []);

    final exatos = itens.where((i) => _mesmasPalavras(falado, i.chave)).toList();
    if (exatos.isNotEmpty) return _Busca(exatos.first, exatos);

    final contem = itens.where((i) => _contido(falado, i.chave)).toList();
    if (contem.length == 1) return _Busca(contem.first, contem);
    if (contem.length > 1) return _Busca(null, contem);

    if (aceitarNomeMaior) {
      final contidos = itens
          .where((i) => i.chave.isNotEmpty && _contido(i.chave, falado))
          .toList();
      if (contidos.length == 1) return _Busca(contidos.first, contidos);
      if (contidos.length > 1) return _Busca(null, contidos);
    }
    return const _Busca(null, []);
  }

  /// Palavras "importantes" do nome, sem acento e no singular.
  static List<String> chaveNome(String nome) {
    const ignorar = {'de', 'do', 'da', 'dos', 'das', 'o', 'a', 'os', 'as', 'e', 'com'};
    return removerAcentos(nome.toLowerCase())
        .split(RegExp(r'[^a-z0-9]+'))
        .where((p) => p.isNotEmpty && !ignorar.contains(p))
        .map(singular)
        .toList();
  }

  /// Plural -> singular (aproximado, mas aplicado nos dois lados da
  /// comparação, então os erros se cancelam).
  static String singular(String w) {
    if (w.length <= 3) return w;
    String corta(int n) => w.substring(0, w.length - n);
    if (w.endsWith('oes') || w.endsWith('aes')) return '${corta(3)}ao';
    if (w.endsWith('aos')) return corta(1);
    if (w.endsWith('ns')) return '${corta(2)}m';
    if (w.endsWith('eis')) return '${corta(3)}el';
    if (w.endsWith('ais')) return '${corta(3)}al';
    if (w.endsWith('res') || w.endsWith('zes') || w.endsWith('ses')) {
      return corta(2);
    }
    if (w.endsWith('s')) return corta(1);
    return w;
  }

  static bool _palavraIgual(String a, String b) {
    if (a == b) return true;
    // tolera 1 letra de diferença em palavras grandes ("macarão"/"macarrão")
    if (a.length >= 5 && b.length >= 5) return _distancia(a, b) <= 1;
    return false;
  }

  static bool _mesmasPalavras(List<String> a, List<String> b) =>
      a.length == b.length && _contido(a, b);

  /// Todas as palavras de [menor] aparecem em [maior]?
  static bool _contido(List<String> menor, List<String> maior) =>
      menor.isNotEmpty &&
      menor.every((p) => maior.any((q) => _palavraIgual(p, q)));

  static int _distancia(String a, String b) {
    if ((a.length - b.length).abs() > 1) return 2;
    var anterior = List<int>.generate(b.length + 1, (i) => i);
    for (var i = 1; i <= a.length; i++) {
      final atual = List<int>.filled(b.length + 1, 0);
      atual[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final custo = a[i - 1] == b[j - 1] ? 0 : 1;
        atual[j] = [
          anterior[j] + 1,
          atual[j - 1] + 1,
          anterior[j - 1] + custo,
        ].reduce((x, y) => x < y ? x : y);
      }
      anterior = atual;
    }
    return anterior[b.length];
  }

  // ---------------------------------------------------------------------------
  // Unidades e formatação
  // ---------------------------------------------------------------------------

  static const Map<String, List<Object>> _baseUnidade = {
    'g': ['massa', 1.0],
    'kg': ['massa', 1000.0],
    'ml': ['volume', 1.0],
    'l': ['volume', 1000.0],
    'un': ['un', 1.0],
  };

  /// Converte [quantidade] de [de] para [para]. Retorna null se não dá
  /// (ex.: kg -> un).
  static double? converterUnidade(double quantidade, String de, String para) {
    final a = _baseUnidade[de.toLowerCase()];
    final b = _baseUnidade[para.toLowerCase()];
    if (a == null || b == null) {
      return de.toLowerCase() == para.toLowerCase() ? quantidade : null;
    }
    if (a[0] != b[0]) return null;
    return _arredondar(quantidade * (a[1] as double) / (b[1] as double));
  }

  static double _arredondar(double v) => (v * 1000).roundToDouble() / 1000;

  static String formatarQuantidade(double q, String unidade) {
    String n;
    if (q == q.roundToDouble()) {
      n = q.toInt().toString();
    } else {
      n = q
          .toStringAsFixed(3)
          .replaceAll(RegExp(r'0+$'), '')
          .replaceAll('.', ',');
    }
    return '$n $unidade';
  }

  static String capitalizar(String s) {
    final t = s.trim();
    if (t.isEmpty) return t;
    return t[0].toUpperCase() + t.substring(1);
  }
}

class _ItemTrabalho {
  final Ingrediente? original; // null = item novo criado por voz
  final String nome;
  double quantidade;
  final String unidade;
  bool excluido = false;
  final List<String> chave;

  _ItemTrabalho({
    required this.original,
    required this.nome,
    required this.quantidade,
    required this.unidade,
  }) : chave = EstoqueVozService.chaveNome(nome);

  factory _ItemTrabalho.doEstoque(Ingrediente i) => _ItemTrabalho(
        original: i,
        nome: i.nome,
        quantidade: i.quantidade,
        unidade: i.unidade,
      );
}

class _Busca {
  final _ItemTrabalho? item;
  final List<_ItemTrabalho> ambiguos;
  const _Busca(this.item, this.ambiguos);
}
