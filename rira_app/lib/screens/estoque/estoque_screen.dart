import 'package:flutter/material.dart';

class EstoqueScreen extends StatelessWidget {
  final List<Map<String, dynamic>> itens = [
    {
      "nome": "Tomate",
      "quantidade": "2",
      "validade": DateTime.now().add(Duration(days: 2))
    },
    {
      "nome": "Leite",
      "quantidade": "1L",
      "validade": DateTime.now().subtract(Duration(days: 1))
    },
    {
      "nome": "Arroz",
      "quantidade": "1 pacote",
      "validade": null
    },
  ];

  Color getCorValidade(DateTime? data) {
    if (data == null) return Colors.grey;

    final hoje = DateTime.now();

    if (data.isBefore(hoje)) {
      return Colors.red; // vencido
    } else if (data.difference(hoje).inDays <= 3) {
      return Colors.orange; // perto de vencer
    } else {
      return Colors.green; // ok
    }
  }

  String formatarData(DateTime? data) {
    if (data == null) return "Sem validade";
    return "${data.day}/${data.month}/${data.year}";
  }

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Color(0xFFF5F2EE),

      appBar: AppBar(
        title: Text("Estoque"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),

      body: Padding(
        padding: EdgeInsets.all(largura * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Seus ingredientes",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                itemCount: itens.length,
                itemBuilder: (context, index) {
                  final item = itens[index];
                  final cor = getCorValidade(item["validade"]);

                  return Container(
                    margin: EdgeInsets.only(bottom: 12),
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border(
                        left: BorderSide(color: cor, width: 5),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item["nome"],
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 5),
                            Text("Qtd: ${item["quantidade"]}"),
                            Text("Validade: ${formatarData(item["validade"])}"),
                          ],
                        ),
                        Icon(Icons.kitchen),
                      ],
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