import 'package:flutter/material.dart';
import 'detalhe_receita_screen.dart';

class ReceitasFavoritasScreen extends StatelessWidget {
  final List<Map<String, String>> favoritas = [
    {
      "nome": "Macarrão ao molho",
      "descricao": "Simples e rápido",
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
        title: Text("Favoritas"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),

      body: Padding(
        padding: EdgeInsets.all(largura * 0.05),
        child: favoritas.isEmpty
            ? Center(
                child: Text("Nenhuma receita favorita ainda"),
              )
            : ListView.builder(
                itemCount: favoritas.length,
                itemBuilder: (context, index) {
                  final receita = favoritas[index];

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
                            ],
                            preparo: [
                              "Passo 1",
                              "Passo 2",
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
                         Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.restaurant, color: Colors.grey[700]),
                        ),

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
    );
  }
}