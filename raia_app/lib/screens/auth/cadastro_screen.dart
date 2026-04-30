
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:raia_app/screens/main_screen.dart';

class CadastroScreen extends StatefulWidget {
  @override
  _CadastroScreenState createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _formKey = GlobalKey<FormState>();
  final nomeController = TextEditingController();
  final emailController = TextEditingController();
  final senhaController = TextEditingController();
  final confirmarController = TextEditingController();
  bool _isLoading = false;

  Future<void> _cadastrarUsuario() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: senhaController.text.trim(),
      );

      if (userCredential.user != null) {
        await FirebaseFirestore.instance.collection('usuarios').doc(userCredential.user!.uid).set({
          'nome': nomeController.text.trim(),
          'email': emailController.text.trim(),
          'dataCriacao': FieldValue.serverTimestamp(),
        });
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cadastro realizado com sucesso!')),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => MainScreen()),
          (route) => false,
        );
      }

    } on FirebaseAuthException catch (e) {
      String mensagemErro = 'Ocorreu um erro desconhecido.';
      if (e.code == 'weak-password') {
        mensagemErro = 'A senha deve ter no mínimo 6 caracteres.';
      } else if (e.code == 'email-already-in-use') {
        mensagemErro = 'Este e-mail já está em uso por outra conta.';
      } else if (e.code == 'invalid-email') {
        mensagemErro = 'O formato do e-mail é inválido.';
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensagemErro)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(elevation: 0, backgroundColor: Colors.transparent),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text("Criar Conta", style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                SizedBox(height: 30),
                TextFormField(
                  controller: nomeController,
                  decoration: InputDecoration(labelText: "Nome"),
                  validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                ),
                SizedBox(height: 15),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: "Email"),
                  validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                ),
                SizedBox(height: 15),
                TextFormField(
                  controller: senhaController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: "Senha"),
                   validator: (value) => value!.length < 6 ? 'Mínimo 6 caracteres' : null,
                ),
                SizedBox(height: 15),
                TextFormField(
                  controller: confirmarController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: "Confirmar Senha"),
                   validator: (value) {
                    if (value != senhaController.text) {
                      return 'As senhas não coincidem';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 25),
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _cadastrarUsuario,
                        child: Text("Confirmar"),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
