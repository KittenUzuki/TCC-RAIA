import 'package:flutter/material.dart';
import 'package:raia_app/screens/auth/login_screen.dart';
import 'package:raia_app/services/auth_service.dart';
import 'package:raia_app/services/ingrediente_service.dart';
import 'package:raia_app/services/user_service.dart';

class PerfilScreen extends StatefulWidget {
  @override
  _PerfilScreenState createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _authService = AuthService();
  final _userService = UserService();
  final _ingredienteService = IngredienteService();

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
    final user = _authService.usuarioAtual;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final perfil = await _userService.buscarPerfil(user.uid);

      if (mounted) {
        setState(() {
          _nome = perfil?.nome;
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
      await _authService.logout();
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
    final user = _authService.usuarioAtual;
    if (user == null) return;

    if (mounted) setState(() => _isLoading = true);

    try {
      // Ordem importa: apaga os dados no Firestore ANTES de excluir a conta,
      // porque depois de excluída as regras não autorizam mais esse uid.
      await _ingredienteService.removerTodosDoUsuario(user.uid);
      await _userService.excluirPerfil(user.uid);
      await _authService.excluirConta();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Conta excluída com sucesso."), backgroundColor: Colors.green),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
        );
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
      if (e.code == 'requires-recent-login') {
        _logout();
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