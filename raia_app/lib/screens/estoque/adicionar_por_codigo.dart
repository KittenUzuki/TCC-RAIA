import 'package:flutter/material.dart';
import 'package:raia_app/screens/estoque/add_ingredientes_screen.dart';
import 'package:raia_app/screens/estoque/scanner_screen.dart';
import 'package:raia_app/services/produto_service.dart';

/// Fluxo completo de "adicionar por QR code / código de barras":
/// escaneia -> consulta o nome do produto -> abre o formulário preenchido.
Future<void> adicionarPorCodigo(BuildContext context) async {
  final codigo = await Navigator.push<String>(
    context,
    MaterialPageRoute(builder: (_) => const ScannerScreen()),
  );

  // Usuário voltou sem escanear nada.
  if (codigo == null || !context.mounted) return;

  // Loading enquanto consulta a base de produtos.
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  String? nome;
  String? aviso;

  try {
    nome = await ProdutoService().buscarNomePorCodigo(codigo);
    if (nome == null) {
      aviso = 'Produto não encontrado na base. Preencha o nome manualmente.';
    }
  } catch (_) {
    aviso = 'Não foi possível consultar o produto (sem internet?). '
        'Preencha o nome manualmente.';
  }

  if (!context.mounted) return;
  Navigator.pop(context); // fecha o loading

  if (aviso != null) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(aviso)));
  }

  // Abre o mesmo formulário do "Manual", já com o nome preenchido.
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: AddIngredientesScreen(nomeInicial: nome),
      );
    },
  );
}