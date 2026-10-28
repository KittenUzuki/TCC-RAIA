// Testes do comando de voz. Rode com:
//   flutter test test/comando_voz_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:raia_app/models/comando_voz.dart';
import 'package:raia_app/models/ingrediente.dart';
import 'package:raia_app/services/comando_voz_parser.dart';
import 'package:raia_app/services/estoque_voz_service.dart';

const add = TipoComando.adicionar;
const rem = TipoComando.remover;

/// Confere os comandos gerados por uma frase.
/// Cada esperado: [tipo, nome, quantidade, unidade]
void confere(String frase, List<List<Object?>> esperado,
    {TipoComando padrao = add}) {
  final r = ComandoVozParser.interpretar(frase, padrao: padrao);
  expect(r.comandos.length, esperado.length,
      reason: 'frase "$frase" gerou ${r.comandos}');
  for (var i = 0; i < esperado.length; i++) {
    final c = r.comandos[i];
    final e = esperado[i];
    expect(c.tipo, e[0], reason: '"$frase" item $i: $c');
    expect(c.nome, e[1], reason: '"$frase" item $i: $c');
    expect(c.quantidade, e[2], reason: '"$frase" item $i: $c');
    expect(c.unidade, e[3], reason: '"$frase" item $i: $c');
  }
}

Ingrediente ing(String id, String nome, double q, String u) =>
    Ingrediente(id: id, userId: 'u1', nome: nome, quantidade: q, unidade: u);

void main() {
  group('Interpretação da frase', () {
    test('adicionar com número e unidade', () {
      confere('adicionar 2 kg de arroz', [[add, 'arroz', 2.0, 'kg']]);
      confere('Adicionar 2kg de carne moída', [[add, 'carne moída', 2.0, 'kg']]);
      confere('adicionar 1,5 l de suco de laranja',
          [[add, 'suco de laranja', 1.5, 'L']]);
    });

    test('números por extenso', () {
      confere('adiciona três ovos e um litro de leite', [
        [add, 'ovos', 3.0, null],
        [add, 'leite', 1.0, 'L'],
      ]);
      confere('vinte e dois ovos', [[add, 'ovos', 22.0, null]]);
      confere('duzentos e cinquenta gramas de manteiga',
          [[add, 'manteiga', 250.0, 'g']]);
      confere('adicionar dois ovos e três tomates', [
        [add, 'ovos', 2.0, null],
        [add, 'tomates', 3.0, null],
      ]);
    });

    test('meio, meia dúzia, e meio', () {
      confere('comprei meia dúzia de ovos', [[add, 'ovos', 6.0, 'un']]);
      confere('uma dúzia de ovos', [[add, 'ovos', 12.0, 'un']]);
      confere('coloca dois quilos e meio de batata',
          [[add, 'batata', 2.5, 'kg']]);
      confere('meio quilo de feijão', [[add, 'feijão', 0.5, 'kg']]);
    });

    test('embalagens e lugares', () {
      confere('adicionar dois pacotes de café', [[add, 'café', 2.0, 'un']]);
      confere('adiciona 500ml de leite no estoque por favor',
          [[add, 'leite', 500.0, 'ml']]);
    });

    test('remover', () {
      confere('remover o leite', [[rem, 'leite', null, null]]);
      confere('usei 2 ovos', [[rem, 'ovos', 2.0, null]]);
      confere('remover um ovo', [[rem, 'ovo', 1.0, null]]);
      confere('acabou o café', [[rem, 'café', null, null]]);
      confere('jogar fora o iogurte', [[rem, 'iogurte', null, null]]);
      confere('tira 300 gramas de queijo da geladeira',
          [[rem, 'queijo', 300.0, 'g']]);
    });

    test('verbo no fim da frase', () {
      confere('o leite acabou', [[rem, 'leite', null, null]]);
      confere('o leite e o café acabaram', [
        [rem, 'leite', null, null],
        [rem, 'café', null, null],
      ]);
    });

    test('vários comandos', () {
      confere('adicionar 2 ovos e remover o queijo', [
        [add, 'ovos', 2.0, null],
        [rem, 'queijo', null, null],
      ]);
      confere('adicionar 2 ovos 3 tomates', [
        [add, 'ovos', 2.0, null],
        [add, 'tomates', 3.0, null],
      ]);
      confere('adicionar 2 ovos remover o leite', [
        [add, 'ovos', 2.0, null],
        [rem, 'leite', null, null],
      ]);
    });

    test('sem verbo usa o padrão', () {
      confere('leite 2 litros', [[add, 'leite', 2.0, 'L']]);
      confere('2 ovos', [[rem, 'ovos', 2.0, null]], padrao: rem);
      confere('adicionar pão', [[add, 'pão', null, null]]);
    });

    test('frase sem alimento', () {
      expect(ComandoVozParser.interpretar('adicionar').vazio, isTrue);
      expect(ComandoVozParser.interpretar('').vazio, isTrue);
    });
  });

  group('Plano sobre o estoque', () {
    final estoque = [
      ing('1', 'Ovos', 10, 'un'),
      ing('2', 'Leite', 2, 'L'),
      ing('3', 'Arroz', 1, 'kg'),
      ing('4', 'Queijo', 500, 'g'),
      ing('5', 'Leite condensado', 1, 'un'),
    ];

    PlanoVoz plano(String frase) => EstoqueVozService.planejar(
        ComandoVozParser.interpretar(frase).comandos, estoque, 'u1');

    test('soma em item existente (ignora plural/maiúscula)', () {
      final p = plano('adicionar 6 ovos');
      expect(p.acoes.single.tipo, TipoAcao.atualizar);
      expect(p.acoes.single.ingrediente.id, '1');
      expect(p.acoes.single.ingrediente.quantidade, 16);
    });

    test('subtrai e apaga quando zera', () {
      expect(plano('usei 2 ovos').acoes.single.ingrediente.quantidade, 8);
      final p = plano('usei 10 ovos');
      expect(p.acoes.single.tipo, TipoAcao.excluir);
    });

    test('converte g <-> kg', () {
      expect(plano('tirar 300 g de arroz').acoes.single.ingrediente.quantidade,
          0.7);
      expect(
          plano('adicionar 500 gramas de arroz')
              .acoes
              .single
              .ingrediente
              .quantidade,
          1.5);
      expect(plano('adicionar 1 kg de queijo').acoes.single.ingrediente.quantidade,
          1500);
    });

    test('nome exato vence o parcial', () {
      final p = plano('remover o leite');
      expect(p.acoes.single.tipo, TipoAcao.excluir);
      expect(p.acoes.single.ingrediente.id, '2');
    });

    test('nome parcial único', () {
      final p = plano('remover o condensado');
      expect(p.acoes.single.ingrediente.id, '5');
    });

    test('cria item novo', () {
      final p = plano('adicionar 2 tomates');
      expect(p.acoes.single.tipo, TipoAcao.criar);
      expect(p.acoes.single.ingrediente.nome, 'Tomates');
      expect(p.acoes.single.ingrediente.unidade, 'un');
    });

    test('erros não geram ações', () {
      final p1 = plano('remover banana');
      expect(p1.acoes, isEmpty);
      expect(p1.linhas.single.ok, isFalse);
      final p2 = plano('tirar 1 kg de ovos');
      expect(p2.acoes, isEmpty);
      expect(p2.linhas.single.ok, isFalse);
    });

    test('vários comandos no mesmo item viram uma ação só', () {
      final p = plano('adicionar 2 ovos e usar 1 ovo');
      expect(p.linhas.length, 2);
      expect(p.acoes.single.ingrediente.quantidade, 11);
    });
  });
}
