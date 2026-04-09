import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  final nomeController = TextEditingController();
  final senhaController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F2EE), // fundo claro igual figma
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Bem-Vindo!",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 30),

            TextField(
              controller: nomeController,
              decoration: InputDecoration(
                labelText: "Nome",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            SizedBox(height: 15),

            TextField(
              controller: senhaController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Senha",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            SizedBox(height: 8),

            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "Esqueceu a senha?",
                style: TextStyle(fontSize: 12),
              ),
            ),

            SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: Size(double.infinity, 45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text("Confirmar"),
            ),

            SizedBox(height: 10),

            Text("Não tem uma conta? Clique aqui"),
          ],
        ),
      ),
    );
  }
}