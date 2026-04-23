import 'package:flutter/material.dart';
import 'receitas_favoritas_screen.dart'; // 🔥 IMPORTANTE
import 'detalhe_receita_screen.dart';

class ReceitasScreen extends StatelessWidget {
  final List<Map<String, String>> receitas = [
    {
      "nome": "Macarrão ao molho",
      "descricao": "Simples e rápido",
    },
    {
      "nome": "Arroz com legumes",
      "descricao": "Saudável e leve",
    },
    {
      "nome": "Panqueca",
      "descricao": "Ótima para café",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Color(0xFFF5F2EE),

      appBar: AppBar(
        title: Text("Receitas"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,

        // 🔥 BOTÃO DE FAVORITOS
        actions: [
          IconButton(
            icon: Icon(Icons.favorite),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReceitasFavoritasScreen(),
                ),
              );
            },
          ),
        ],
      ),

      body: Padding(
        padding: EdgeInsets.all(largura * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Sugestões para você",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 15),

            TextField(
              decoration: InputDecoration(
                hintText: "Buscar receita...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                itemCount: receitas.length,
                itemBuilder: (context, index) {
                  final receita = receitas[index];

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetalheReceitaScreen(
                            nome: receita["nome"]!,
                            descricao: receita["descricao"]!,
                            ingredientes: [
                              "Ingrediente 1",
                              "Ingrediente 2",
                              "Ingrediente 3",
                            ],
                            preparo: [
                              "Misture tudo",
                              "Cozinhe por 10 minutos",
                              "Sirva quente",
                            ],
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: EdgeInsets.only(bottom: 12),
                      padding: EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.restaurant,
                              size: 40, color: Colors.green),

                          SizedBox(width: 15),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                receita["nome"]!,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(receita["descricao"]!),
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}