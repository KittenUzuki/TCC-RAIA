
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PerfilScreen extends StatefulWidget {
  @override
  _PerfilScreenState createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  bool _isLoading = true;
  String? _nome;
  String? _email;

  final nomeController = TextEditingController();
  final emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        final docSnapshot = await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get();

        if (docSnapshot.exists) {
          if (context.mounted) {
             setState(() {
              _nome = docSnapshot.data()?['nome'];
              _email = docSnapshot.data()?['email'];
              nomeController.text = _nome ?? '';
              emailController.text = _email ?? '';
            });
          }
        }
      } catch (e) {
         if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Erro ao buscar dados do usuário: $e")),
            );
         }
      }
    }
    if (context.mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      // A CORREÇÃO ESTÁ AQUI:
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao fazer logout: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Color(0xFFF5F2EE),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                      readOnly: true,
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
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: "Email",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    SizedBox(height: 30),
                    InkWell(
                      onTap: _logout,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text("SAIR"),
                          SizedBox(width: 5),
                          Icon(Icons.logout),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
