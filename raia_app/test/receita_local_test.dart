// Testes das sugestões de receitas a partir do arquivo local. Rode com:
//   flutter test test/receita_local_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:raia_app/models/ingrediente.dart';
import 'package:raia_app/services/receita_local_service.dart';

ReceitaLocal receita(String id, String nome, List<List<String>> ings,
        {String categoria = '', String origem = ''}) =>
    ReceitaLocal.fromJson({
      'id': id,
      'nome': nome,
      'nomeOriginal': nome,
      'categoria': categoria,
      'origem': origem,
      'imagem': '',
      'modoPreparo': 'Misture tudo.',
      'ingredientes': [
        for (final i in ings) {'nome': i[0], 'nomeOriginal': i[1], 'medida': i[2]}
      ],
    });

Ingrediente item(String nome, {DateTime? validade}) => Ingrediente(
    id: nome, userId: 'u1', nome: nome, quantidade: 1, unidade: 'un',
    validade: validade);

void main() {
  final base = [
    receita('1', 'Frango ao alho', [
      ['Peito de frango', 'Chicken Breast', '500g'],
      ['Alho', 'Garlic', '3 dentes'],
      ['Sal', 'Salt', 'a gosto'],
    ], categoria: 'Frango'),
    receita('2', 'Bolo de chocolate', [
      ['Farinha de trigo', 'Plain Flour', '2 xícaras'],
      ['Ovos', 'Eggs', '3'],
      ['Chocolate amargo', 'Dark Chocolate', '200g'],
      ['Açúcar', 'Sugar', '1 xícara'],
    ], categoria: 'Sobremesa'),
    receita('3', 'Espaguete', [
      ['Espaguete', 'Spaghetti', '500g'],
      ['Tomate pelado picado', 'Chopped Tomatoes', '1 lata'],
    ], origem: 'Italiana'),
  ];
  final servico = ReceitaLocalService();

  test('sugere só receitas que usam o estoque, faltando menos primeiro', () {
    final r = servico.sugerir(base, [item('Frango'), item('Alho'), item('Ovo')]);
    expect(r.map((x) => x.id), ['1', '2']);
    expect(r.first.ingredientesFaltando, isEmpty); // sal não conta
    expect(r[1].ingredientesFaltando,
        ['Farinha de trigo', 'Chocolate amargo', 'Açúcar']);
  });

  test('item do estoque com nome mais longo também combina', () {
    final r = servico.sugerir(base, [item('Tomate pelado')]);
    expect(r.single.id, '3');
  });

  test('busca por nome, ingrediente, categoria e país (sem acento)', () {
    expect(servico.buscar(base, 'chocolate', []).single.id, '2');
    expect(servico.buscar(base, 'sobremesa', []).single.id, '2');
    expect(servico.buscar(base, 'italiana', []).single.id, '3');
    expect(servico.buscar(base, 'acucar', []).single.id, '2');
    expect(servico.buscar(base, 'garlic', []).single.id, '1');
  });

  test('receita vira Receita com lista de ingredientes formatada', () {
    final r = servico.buscar(base, 'frango', [item('Frango')]).first;
    expect(r.ingredientes.first, 'Peito de frango (500g)');
    expect(r.ingredientesFaltando, ['Alho']);
  });
}
