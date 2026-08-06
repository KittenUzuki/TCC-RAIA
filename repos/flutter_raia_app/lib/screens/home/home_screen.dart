import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Raia'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Bem-vindo ao Raia!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                authService.usuarioAtual?.email ??
                    'Usuário não encontrado',
              ),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: () async {
                  await authService.logout();

                  if (context.mounted) {
                    Navigator.pushReplacementNamed(
                      context,
                      '/',
                    );
                  }
                },
                child: const Text('Sair'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}