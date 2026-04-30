
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:raia_app/screens/auth/login_screen.dart';

class PerfilScreen extends StatefulWidget {
  @override
  _PerfilScreenState createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final docSnapshot = await _firestore.collection('usuarios').doc(user.uid).get();

      if (docSnapshot.exists && mounted) {
        setState(() {
          _nome = docSnapshot.data()?['nome'];
          _email = user.email;
          nomeController.text = _nome ?? '';
          emailController.text = _email ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao buscar dados: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    try {
      await _auth.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao fazer logout: $e")),
        );
      }
    }
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Text("Confirmar Exclusão"),
          content: Text("Você tem certeza que deseja excluir sua conta? Todos os seus dados, incluindo seu estoque, serão permanentemente perdidos. Esta ação não pode ser desfeita."),
          actions: [
            TextButton(
              child: Text("Cancelar"),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            TextButton(
              child: Text("Excluir", style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(ctx).pop();
                _deleteAccount();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (mounted) setState(() => _isLoading = true);

    try {
      final ingredientesQuery = await _firestore.collection('users').doc(user.uid).collection('ingredientes').get();
      for (var doc in ingredientesQuery.docs) {
        await doc.reference.delete();
      }
      await _firestore.collection('usuarios').doc(user.uid).delete();

      await user.delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Conta excluída com sucesso."), backgroundColor: Colors.green),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
        );
      }

    } on FirebaseAuthException catch (e) {
       if (mounted) setState(() => _isLoading = false);
       String message = "Ocorreu um erro ao excluir a conta.";
       if (e.code == 'requires-recent-login') {
         message = "Esta é uma operação sensível. Por favor, faça login novamente antes de excluir sua conta.";
         _logout();
       }
       if(mounted){
         ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.red),
          );
       }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Um erro inesperado ocorreu: $e"), backgroundColor: Colors.red),
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
          : SafeArea(
            child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: largura * 0.08, vertical: 20),
                  child: Column(
                    children: [
                      Text("Minha Conta", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      SizedBox(height: 20),
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey[300],
                        child: Icon(Icons.person, size: 40, color: Colors.grey[700]),
                      ),
                      SizedBox(height: 20),
                      TextField(controller: nomeController, readOnly: true, decoration: InputDecoration(labelText: "Nome", border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
                      SizedBox(height: 15),
                      TextField(controller: emailController, readOnly: true, decoration: InputDecoration(labelText: "Email", border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
                      SizedBox(height: 30),
                      InkWell(
                        onTap: _logout,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text("SAIR"),
                              SizedBox(width: 5),
                              Icon(Icons.logout),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      InkWell(
                        onTap: _showDeleteConfirmationDialog,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text("EXCLUIR CONTA", style: TextStyle(color: Colors.red)),
                              SizedBox(width: 5),
                              Icon(Icons.delete_forever, color: Colors.red),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ),
    );
  }
}
