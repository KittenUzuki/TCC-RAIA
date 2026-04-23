import 'package:flutter/material.dart';
import 'package:raia_app/screens/receitas/receitas_screen.dart';

// estoque
import '../estoque/add_ingredientes_screen.dart';
import '../estoque/estoque_screen.dart';

class HomeScreen extends StatelessWidget {
  final List<String> itens = [
    "Tomate (2)",
    "Leite (1L)",
    "Arroz (1 pacote)"
  ];

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(largura * 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10),

              Text("Raia",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),

              Text("Sua cozinha inteligente"),

              SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text("Você tem ${itens.length} itens no estoque"),
              ),

              SizedBox(height: 20),

              buildButton("Adicionar alimento", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddIngredientesScreen(),
                  ),
                );
              }),

            //estoque
             buildButton("Ver estoque", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EstoqueScreen(),
                  ),
                );
              }),

              //receitas
              buildButton("Ver Receitas", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReceitasScreen(),
                  ),
                );
              }),

              SizedBox(height: 20),

              Text("Itens recentes",
                  style: TextStyle(fontWeight: FontWeight.bold)),

              ...itens.map(buildItem).toList(),
            ],
          ),
        ),
      ),
    );
  }

   
  Widget buildButton(String text, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          minimumSize: Size(double.infinity, 45),
        ),
        child: Text(text),
      ),
    );
  }

  Widget buildItem(String item) {
    return ListTile(
      leading: Icon(Icons.check_circle_outline),
      title: Text(item),
    );
  }
}