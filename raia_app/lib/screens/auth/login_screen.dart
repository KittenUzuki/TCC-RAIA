import 'package:flutter/material.dart';
import 'package:raia_app/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final senhaController = TextEditingController();
  final _authService = AuthService();

  void signIn() async {
    // show loading circle
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      await _authService.login(
        email: emailController.text,
        senha: senhaController.text,
      );
      // pop the loading circle
      if (mounted) {
        Navigator.pop(context);
        Navigator.pushReplacementNamed(context, '/main');
      }
    } on AuthException catch (e) {
      // pop the loading circle
      if (mounted) {
        Navigator.pop(context);
        // show error message já traduzida (em vez de e.code cru)
        showErrorMessage(e.message);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        showErrorMessage('Ocorreu um erro inesperado. Tente novamente.');
      }
    }
  }

  void showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: largura * 0.08),
            child: Column(
              children: [
                Text(
                  "Bem-Vindo!",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 30),
                TextField(
                  controller: emailController,
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
                SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/esqueciSenha');
                  },
                  child: Text("Esqueceu a senha?"),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: signIn,
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
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/cadastro');
                  },
                  child: Text("Não tem uma conta? Clique aqui"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}