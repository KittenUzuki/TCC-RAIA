import 'package:flutter/material.dart';

class DetalheReceitaScreen extends StatelessWidget {
  final String nome;
  final String descricao;
  final List<String> ingredientes;
  final List<String> preparo;

  const DetalheReceitaScreen({
    required this.nome,
    required this.descricao,
    required this.ingredientes,
    required this.preparo,
  });

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Color(0xFFF5F2EE),

      appBar: AppBar(
        title: Text(nome),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(Icons.favorite_border),
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
              Text(
                nome,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              SizedBox(height: 10),

              Text(descricao),

              SizedBox(height: 25),

              // 🧾 INGREDIENTES
              Text(
                "Ingredientes",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              SizedBox(height: 10),

              ...ingredientes.map(
                (item) => ListTile(
                  leading: Icon(Icons.check),
                  title: Text(item),
                ),
              ),

              SizedBox(height: 20),

              // 👨‍🍳 PREPARO
              Text(
                "Modo de preparo",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              SizedBox(height: 10),

              ...preparo.asMap().entries.map(
                (entry) {
                  int index = entry.key + 1;
                  String passo = entry.value;

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