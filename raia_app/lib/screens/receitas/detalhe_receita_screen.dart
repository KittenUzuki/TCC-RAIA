import 'package:flutter/material.dart';

import '../../models/receita.dart';

class DetalheReceitaScreen extends StatelessWidget {
  final Receita receita;

  const DetalheReceitaScreen({
    super.key,
    required this.receita,
  });

  List<String> get _passosPreparo {
    final texto = receita.modoPreparo.trim();
    if (texto.isEmpty) return [];

    final linhas = texto
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    return linhas.isNotEmpty ? linhas : [texto];
  }

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F2EE),
      appBar: AppBar(
        title: Text(receita.nome),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () {
              // futuro: salvar favorito
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(largura * 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (receita.imagem.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    receita.imagem,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                ),

              if (receita.imagem.isNotEmpty) const SizedBox(height: 16),

              Text(
                receita.nome,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 25),

              Text(
                receita.ingredientesFaltando.isEmpty
                    ? "Você já tem todos os ingredientes"
                    : "Ingredientes que faltam",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              if (receita.ingredientesFaltando.isEmpty)
                const ListTile(
                  leading: Icon(Icons.check_circle, color: Colors.green),
                  title: Text("Tudo certo para cozinhar!"),
                )
              else
                ...receita.ingredientesFaltando.map(
                  (item) => ListTile(
                    leading: const Icon(Icons.shopping_cart_outlined),
                    title: Text(item),
                  ),
                ),

              const SizedBox(height: 20),

              const Text(
                "Modo de preparo",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              ..._passosPreparo.asMap().entries.map(
                (entry) {
                  final index = entry.key + 1;
                  final passo = entry.value;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text("$index. $passo"),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}