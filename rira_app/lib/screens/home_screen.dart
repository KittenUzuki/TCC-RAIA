import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            SizedBox(height: 20),

            // TÍTULO
            Text(
              "Rira",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            Text("Sua cozinha inteligente"),

            SizedBox(height: 20),

            // CARD RESUMO
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text("Você tem 12 itens no estoque"),
            ),

            SizedBox(height: 20),

            // BOTÕES
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text("Adicionar alimento"),
            ),

            SizedBox(height: 10),

            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text("Ver estoque"),
            ),

            SizedBox(height: 10),

            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text("Ver receitas"),
            ),

            SizedBox(height: 20),

            // LISTA
            Text(
              "Itens recentes",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            ListTile(title: Text("Tomate (2)")),
            ListTile(title: Text("Leite (1L)")),
            ListTile(title: Text("Arroz (1 pacote)")),
          ],
        ),
      ),
    );
  }
}