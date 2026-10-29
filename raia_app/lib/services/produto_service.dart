import 'dart:convert';

import 'package:http/http.dart' as http;

/// Consulta o nome de um produto pelo código de barras no Open Food Facts
/// (base pública e gratuita, sem chave de API).
class ProdutoService {
  static const String _base =
      'https://world.openfoodfacts.org/api/v2/product';

  /// Devolve o nome do produto, ou `null` se o código não for um código de
  /// produto válido ou não existir na base. Lança exceção se a consulta
  /// falhar (sem internet, timeout, erro do servidor).
  Future<String?> buscarNomePorCodigo(String codigo) async {
    final limpo = codigo.trim();

    // Códigos de produto (EAN/UPC) têm de 8 a 14 dígitos. Se o QR tiver
    // outra coisa (um link, por exemplo), nem consulta.
    if (!RegExp(r'^\d{8,14}$').hasMatch(limpo)) return null;

    final uri = Uri.parse(
      '$_base/$limpo.json?fields=product_name,product_name_pt,generic_name_pt',
    );

    final resposta = await http
        .get(uri, headers: {'User-Agent': 'Raia-TCC/1.0'})
        .timeout(const Duration(seconds: 10));

    if (resposta.statusCode == 404) return null;
    if (resposta.statusCode != 200) {
      throw Exception(
        'Falha ao consultar o produto (status ${resposta.statusCode}).',
      );
    }

    final json = jsonDecode(resposta.body) as Map<String, dynamic>;
    if (json['status'] != 1) return null;

    final produto = json['product'] as Map<String, dynamic>? ?? {};

    // Prefere o nome em português; se não tiver, usa o que existir.
    for (final campo in ['product_name_pt', 'product_name', 'generic_name_pt']) {
      final valor = (produto[campo] as String?)?.trim();
      if (valor != null && valor.isNotEmpty) return valor;
    }
    return null;
  }
}