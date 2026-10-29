import 'package:flutter_test/flutter_test.dart';
import 'package:raia_app/services/texto_foto_parser.dart';

/// Compara só o que importa: nome, quantidade e unidade.
List<List<Object>> _resumo(List<ItemFoto> itens) =>
    itens.map((i) => <Object>[i.nome, i.quantidade, i.unidade]).toList();

void main() {
  test('cupom NFC-e: ignora cabeçalho/rodapé e lê os produtos', () {
    const texto = '''SUPERMERCADO BOM PRECO LTDA
CNPJ: 12.345.678/0001-90  IE: 123456789
RUA DAS FLORES, 123 - CENTRO - CAMPINAS/SP
DOCUMENTO AUXILIAR DA NOTA FISCAL DE CONSUMIDOR ELETRONICA
CODIGO DESCRICAO QTD UN VL UNIT VL TOTAL
001 7891234567890 ARROZ TIO JOAO T1 5KG 1 UN X 25,90 25,90
002 7896543210987 FEIJAO CARIOCA CAMIL 1KG 2 UN X 8,49 16,98
003 7894900011517 LEITE INTEG ITALAC 1L 6 UN X 4,79 28,74
004 2000123000000 BANANA PRATA KG 1,235 KG X 6,99 8,63
005 7891000100103 CAFE PILAO TRAD 500G 1 UN X 18,90 18,90
006 7893000394117 OVOS BRANCOS C/12 1 UN X 13,90 13,90
007 7891149101009 QJO MUSS FATIADO 150G 2 UN X 7,50 15,00
008 7894900011517 LEITE INTEG ITALAC 1L 2 UN X 4,79 9,58
QTD. TOTAL DE ITENS 16
VALOR TOTAL R\$ 137,63
CARTAO DE DEBITO 137,63
TROCO 0,00
Consulte pela Chave de Acesso em www.fazenda.sp.gov.br
29/10/2026 09:45:12''';

    expect(_resumo(TextoFotoParser.interpretar(texto)), [
      ['Arroz tio joão', 5.0, 'kg'],
      ['Feijão carioca camil', 2.0, 'kg'],
      ['Leite integral italac', 8.0, 'L'], // 6 L + 2 L (linha repetida)
      ['Banana prata', 1.235, 'kg'],
      ['Café pilão tradicional', 500.0, 'g'],
      ['Ovos brancos', 1.0, 'un'],
      ['Queijo muçarela fatiado', 300.0, 'g'],
    ]);
  });

  test('cupom com a quantidade na linha de baixo', () {
    const texto = '''001 7891234567890 ARROZ AGULHINHA 5KG
1 UN X 22,90 22,90
002 MACARRAO ESPAGUETE 500G
3 UN X 4,50 13,50
003 ACUCAR REFINADO 1KG
TOTAL 36,40''';

    expect(_resumo(TextoFotoParser.interpretar(texto)), [
      ['Arroz agulhinha', 5.0, 'kg'],
      ['Macarrão espaguete', 1.5, 'kg'],
      ['Açúcar refinado', 1.0, 'kg'],
    ]);
  });

  test('lista escrita usa o mesmo interpretador do comando de voz', () {
    const texto = '''Lista de compras
- 2 kg de arroz
- 6 ovos
- leite
1) meia dúzia de bananas
2 KG DE BATATA
pão de forma''';

    expect(_resumo(TextoFotoParser.interpretar(texto)), [
      ['Arroz', 2.0, 'kg'],
      ['Ovos', 6.0, 'un'],
      ['Leite', 1.0, 'un'],
      ['Bananas', 6.0, 'un'],
      ['Batata', 2.0, 'kg'],
      ['Pão de forma', 1.0, 'un'],
    ]);
  });

  test('montarLinhas junta nome e preço que o OCR separou em colunas', () {
    final linhas = TextoFotoParser.montarLinhas(const [
      TrechoTexto('001 ARROZ TIO JOAO 5KG', 10, 100, 300, 120),
      TrechoTexto('1 UN X 25,90 25,90', 320, 103, 500, 123),
      TrechoTexto('002 FEIJAO 1KG', 10, 130, 200, 150),
      TrechoTexto('2 UN X 8,49 16,98', 320, 134, 500, 154),
      TrechoTexto('MERCADO X', 100, 40, 300, 70),
    ]);

    expect(linhas, [
      'MERCADO X',
      '001 ARROZ TIO JOAO 5KG 1 UN X 25,90 25,90',
      '002 FEIJAO 1KG 2 UN X 8,49 16,98',
    ]);
  });
}
