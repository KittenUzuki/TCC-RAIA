import 'package:flutter/material.dart';

class PerfilScreen extends StatelessWidget {
  final nomeController = TextEditingController(text: "Nome");
  final emailController = TextEditingController(text: "email@email.com");

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Color(0xFFF5F2EE),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: largura * 0.08),
          child: Column(
            children: [
              SizedBox(height: 40),

              Text(
                "Minha Conta",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              SizedBox(height: 20),

              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey[300],
                child: Icon(Icons.person, size: 40, color: Colors.grey[700]),
              ),

              SizedBox(height: 20),

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
                controller: emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              SizedBox(height: 30),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text("SAIR"),
                  SizedBox(width: 5),
                  Icon(Icons.logout),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}