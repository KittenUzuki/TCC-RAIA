import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:raia_app/models/ingrediente.dart';
import 'package:raia_app/models/receita.dart';
import 'package:raia_app/services/comando_voz_parser.dart' show removerAcentos;
import 'package:raia_app/services/estoque_voz_service.dart';

/// Ingrediente de uma receita do arquivo local.
class IngredienteReceitaLocal {
  final String nome; // "Peito de frango"
  final String nomeOriginal; // "Chicken Breast"
  final String medida; // "2 xícaras"
  final List<String> chave; // palavras normalizadas do nome em pt
  final List<String> chaveOriginal; // idem, do nome em inglês

  IngredienteReceitaLocal(this.nome, this.nomeOriginal, this.medida)
      : chave = EstoqueVozService.chaveNome(nome),
        chaveOriginal = EstoqueVozService.chaveNome(nomeOriginal);

  /// "Farinha de trigo (2 xícaras)"
  String get linha => medida.isEmpty ? nome : '$nome ($medida)';
}

/// Uma receita do arquivo `assets/receitas_pt.json`.
class ReceitaLocal {
  final String id;
  final String nome;
  final String nomeOriginal;
  final String categoria;
  final String origem;
  final String imagem;
  final String modoPreparo;
  final List<IngredienteReceitaLocal> ingredientes;

  /// Texto sem acento usado na busca (nome, categoria, origem e ingredientes)
  final String _textoBuscaNome;
  final String _textoBuscaResto;

  ReceitaLocal({
    required this.id,
    required this.nome,
    required this.nomeOriginal,
    required this.categoria,
    required this.origem,
    required this.imagem,
    required this.modoPreparo,
    required this.ingredientes,
  })  : _textoBuscaNome = _normalizar('$nome $nomeOriginal'),
        _textoBuscaResto = _normalizar(
            '$categoria $origem ${ingredientes.map((i) => '${i.nome} ${i.nomeOriginal}').join(' ')}');

  factory ReceitaLocal.fromJson(Map<String, dynamic> j) {
    final ings = (j['ingredientes'] as List? ?? const [])
        .map((i) => IngredienteReceitaLocal(
              (i['nome'] ?? '').toString(),
              (i['nomeOriginal'] ?? '').toString(),
              (i['medida'] ?? '').toString(),
            ))
        .where((i) => i.nome.isNotEmpty)
        .toList();
    return ReceitaLocal(
      id: (j['id'] ?? '').toString(),
      nome: (j['nome'] ?? '').toString(),
      nomeOriginal: (j['nomeOriginal'] ?? '').toString(),
      categoria: (j['categoria'] ?? '').toString(),
      origem: (j['origem'] ?? '').toString(),
      imagem: (j['imagem'] ?? '').toString(),
      modoPreparo: (j['modoPreparo'] ?? '').toString(),
      ingredientes: ings,
    );
  }
}

String _normalizar(String s) => removerAcentos(s.toLowerCase());

/// Lê as receitas do arquivo local (gerado por `IA/gerar_receitas_pt.py`)
/// e sugere receitas com base no estoque — tudo no aparelho, sem internet
/// e sem o servidor Flask.
class ReceitaLocalService {
  static const caminhoArquivo = 'assets/receitas_pt.json';

  /// Itens que quase todo mundo tem e que ninguém cadastra no estoque:
  /// não aparecem como "faltando".
  static const _basicos = [
    ['agua'],
    ['gelo'],
    ['sal'],
    ['sal', 'marinho'],
    ['pimenta', 'reino'],
  ];

  static Future<List<ReceitaLocal>>? _carregando;

  /// Carrega o arquivo uma única vez (fica em memória depois).
  Future<List<ReceitaLocal>> carregar() => _carregando ??= _ler();

  Future<List<ReceitaLocal>> _ler() async {
    try {
      final texto = await rootBundle.loadString(caminhoArquivo);
      final lista = jsonDecode(texto) as List;
      return lista
          .map((j) => ReceitaLocal.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _carregando = null; // permite tentar de novo
      rethrow;
    }
  }

  /// Receitas que usam pelo menos 1 item do estoque, das que faltam menos
  /// ingredientes para as que faltam mais.
  List<Receita> sugerir(
    List<ReceitaLocal> base,
    List<Ingrediente> estoque, {
    int limite = 60,
  }) {
    final chavesEstoque = _chavesEstoque(estoque);
    final urgentes = _chavesUrgentes(estoque);
    final avaliadas = <_Avaliacao>[];

    for (final r in base) {
      final a = _avaliar(r, chavesEstoque, urgentes);
      if (a.tem > 0) avaliadas.add(a);
    }
    avaliadas.sort((a, b) {
      final c1 = a.faltando.length.compareTo(b.faltando.length);
      if (c1 != 0) return c1;
      final c2 = b.usaUrgente.compareTo(a.usaUrgente); // vence logo primeiro
      if (c2 != 0) return c2;
      final c3 = b.tem.compareTo(a.tem);
      if (c3 != 0) return c3;
      return a.receita.nome.compareTo(b.receita.nome);
    });
    return avaliadas.take(limite).map((a) => a.paraReceita()).toList();
  }

  /// Busca em TODAS as receitas por nome, categoria, origem ou ingrediente
  /// ("frango", "sobremesa", "italiana", "chocolate"...).
  List<Receita> buscar(
    List<ReceitaLocal> base,
    String termo,
    List<Ingrediente> estoque, {
    int limite = 100,
  }) {
    final palavras = _normalizar(termo)
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (palavras.isEmpty) return [];

    final chavesEstoque = _chavesEstoque(estoque);
    final urgentes = _chavesUrgentes(estoque);
    final noNome = <_Avaliacao>[];
    final noResto = <_Avaliacao>[];

    for (final r in base) {
      final todasNoNome = palavras.every(r._textoBuscaNome.contains);
      final todas = todasNoNome ||
          palavras.every(
              (p) => r._textoBuscaNome.contains(p) || r._textoBuscaResto.contains(p));
      if (!todas) continue;
      final a = _avaliar(r, chavesEstoque, urgentes);
      (todasNoNome ? noNome : noResto).add(a);
    }
    int ordem(_Avaliacao a, _Avaliacao b) {
      final c = a.faltando.length.compareTo(b.faltando.length);
      return c != 0 ? c : a.receita.nome.compareTo(b.receita.nome);
    }

    noNome.sort(ordem);
    noResto.sort(ordem);
    return [...noNome, ...noResto]
        .take(limite)
        .map((a) => a.paraReceita())
        .toList();
  }

  // ---------------------------------------------------------------------------

  List<List<String>> _chavesEstoque(List<Ingrediente> estoque) => estoque
      .where((i) => i.quantidade > 0)
      .map((i) => EstoqueVozService.chaveNome(i.nome))
      .where((c) => c.isNotEmpty)
      .toList();

  /// Itens que vencem em até 3 dias (ou já venceram).
  List<List<String>> _chavesUrgentes(List<Ingrediente> estoque) {
    final limite = DateTime.now().add(const Duration(days: 3));
    return estoque
        .where((i) => i.validade != null && i.validade!.isBefore(limite))
        .map((i) => EstoqueVozService.chaveNome(i.nome))
        .where((c) => c.isNotEmpty)
        .toList();
  }

  _Avaliacao _avaliar(ReceitaLocal r, List<List<String>> estoque,
      List<List<String>> urgentes) {
    var tem = 0;
    var usaUrgente = 0;
    final faltando = <String>[];
    for (final ing in r.ingredientes) {
      final noEstoque = _combina(ing, estoque);
      if (noEstoque) {
        tem++;
        if (_combina(ing, urgentes)) usaUrgente++;
      } else if (!_ehBasico(ing.chave) && !faltando.contains(ing.nome)) {
        faltando.add(ing.nome);
      }
    }
    return _Avaliacao(r, tem, usaUrgente, faltando);
  }

  static bool _ehBasico(List<String> chave) =>
      _basicos.any((b) => _iguais(b, chave));

  /// Ingrediente da receita e item do estoque "são a mesma coisa" quando as
  /// palavras de um estão todas no outro:
  ///   estoque "Frango"  x receita "Peito de frango"  -> sim
  ///   estoque "Leite integral" x receita "Leite"     -> sim
  /// Compara também com o nome original em inglês.
  static bool _combina(IngredienteReceitaLocal ing, List<List<String>> estoque) {
    for (final e in estoque) {
      if (_contido(e, ing.chave) || _contido(ing.chave, e)) return true;
      if (_contido(e, ing.chaveOriginal)) return true;
    }
    return false;
  }

  static bool _contido(List<String> menor, List<String> maior) =>
      menor.isNotEmpty && menor.every(maior.contains);

  static bool _iguais(List<String> a, List<String> b) =>
      a.length == b.length && _contido(a, b);
}

class _Avaliacao {
  final ReceitaLocal receita;
  final int tem;
  final int usaUrgente;
  final List<String> faltando;

  _Avaliacao(this.receita, this.tem, this.usaUrgente, this.faltando);

  Receita paraReceita() => Receita(
        id: receita.id,
        nome: receita.nome,
        imagem: receita.imagem,
        ingredientesFaltando: faltando,
        modoPreparo: receita.modoPreparo,
        ingredientes: receita.ingredientes.map((i) => i.linha).toList(),
        categoria: receita.categoria,
        origem: receita.origem,
      );
}
