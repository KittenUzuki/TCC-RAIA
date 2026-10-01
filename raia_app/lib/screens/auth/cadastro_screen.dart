import 'package:flutter/material.dart';
import 'package:raia_app/screens/auth/login_screen.dart';
import 'package:raia_app/services/auth_service.dart';

class CadastroScreen extends StatelessWidget {
  final nomeController = TextEditingController();
  final emailController = TextEditingController();
  final senhaController = TextEditingController();
  final confirmarController = TextEditingController();
  final _authService = AuthService();

  void _cadastrarUsuario(BuildContext context) async {
    // Validações Manuais
    if (nomeController.text.isEmpty || emailController.text.isEmpty || senhaController.text.isEmpty || confirmarController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Por favor, preencha todos os campos.')),
        );
        return;
    }

    if (senhaController.text != confirmarController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('As senhas não coincidem!')),
      );
      return;
    }

    try {
      await _authService.cadastrar(
        nome: nomeController.text,
        email: emailController.text,
        senha: senhaController.text,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cadastro realizado com sucesso! Faça o login.'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
        );
      }
    } on AuthException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro inesperado ao criar a conta. Tente novamente.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 8),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(elevation: 0, backgroundColor: Colors.transparent, leading: BackButton(color: Colors.black)),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: largura * 0.08),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                 Text(
                  "Criar Conta",
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
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "Email",
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
                SizedBox(height: 15),
                TextField(
                  controller: confirmarController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Confirmar Senha",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => _cadastrarUsuario(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: Size(double.infinity, 45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text("Confirmar", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}