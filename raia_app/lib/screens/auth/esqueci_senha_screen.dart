
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
class EsqueciSenhaScreen extends StatefulWidget {
  @override
  _EsqueciSenhaScreenState createState() => _EsqueciSenhaScreenState();
}
class _EsqueciSenhaScreenState extends State<EsqueciSenhaScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  Future<void> _sendPasswordResetEmail() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(
          email: _emailController.text.trim(),
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Link para redefinição de senha enviado para o seu email.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(); // Volta para a tela de login
        }
      } on FirebaseAuthException catch (e) {
        if (context.mounted) {
          String errorMessage = "Ocorreu um erro. Tente novamente.";
          if (e.code == 'user-not-found') {
            errorMessage = "Nenhum usuário encontrado com este email.";
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (context.mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Esqueci a Senha"),
        backgroundColor: Color(0xFFF5F2EE),
      ),
      backgroundColor: Color(0xFFF5F2EE),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Redefinir Senha",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  "Digite seu email e enviaremos um link para você voltar a acessar sua conta.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
                SizedBox(height: 30),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty || !value.contains('@')) {
                      return 'Por favor, insira um email válido.';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                _isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _sendPasswordResetEmail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          minimumSize: Size(double.infinity, 45),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text("Enviar Link de Redefinição"),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
