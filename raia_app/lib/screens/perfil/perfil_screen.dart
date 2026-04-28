
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 1. Convertido para StatefulWidget para poder carregar e gerenciar dados.
class PerfilScreen extends StatefulWidget {
  @override
  _PerfilScreenState createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  // Variáveis para guardar os dados do usuário e o estado de carregamento
  bool _isLoading = true;
  String? _nome;
  String? _email;

  final nomeController = TextEditingController();
  final emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 2. Chama a função para buscar os dados assim que a tela é iniciada.
    _fetchUserData();
  }

  // 3. Função assíncrona para buscar os dados no Firebase.
  Future<void> _fetchUserData() async {
    // Pega o usuário atualmente logado no Authentication.
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        // Usa o ID do usuário para encontrar o documento correspondente no Firestore.
        final docSnapshot = await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get();

        if (docSnapshot.exists) {
          // Se o documento existe, atualiza as variáveis e os controladores.
          setState(() {
            _nome = docSnapshot.data()?['nome'];
            _email = docSnapshot.data()?['email'];
            nomeController.text = _nome ?? '';
            emailController.text = _email ?? '';
          });
        }
      } catch (e) {
        // Em caso de erro, exibe uma mensagem.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao buscar dados do usuário: $e")),
        );
      }
    }
    // Define que o carregamento terminou.
    setState(() {
      _isLoading = false;
    });
  }
  
  // 4. Função para fazer o logout.
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    // Leva o usuário de volta para a tela de login e remove todas as outras telas da pilha.
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Color(0xFFF5F2EE),
      // 5. Se estiver carregando, mostra um indicador de progresso, senão, mostra os dados.
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
                      readOnly: true, // Por enquanto, apenas leitura.
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
                      readOnly: true, // Apenas leitura.
                      decoration: InputDecoration(
                        labelText: "Email",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    SizedBox(height: 30),
                    // 6. Botão de SAIR agora é clicável e chama a função _logout.
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
