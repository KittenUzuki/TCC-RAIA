import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  final _picker = ImagePicker();

  bool _isLoading = true;
  bool _enviandoFoto = false;
  String? _nome;
  String? _email;
  String? _fotoUrl;

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
          _fotoUrl = perfil?.fotoUrl;
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

  Future<void> _escolherFoto() async {
    final acao = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.photo_camera),
              title: Text('Tirar foto'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Escolher da galeria'),
              onTap: () => Navigator.pop(ctx, 'galeria'),
            ),
            if (_fotoUrl != null)
              ListTile(
                leading: Icon(Icons.delete_outline, color: Colors.red),
                title: Text('Remover foto', style: TextStyle(color: Colors.red)),
                onTap: () => Navigator.pop(ctx, 'remover'),
              ),
          ],
        ),
      ),
    );

    if (acao == null) return;

    final user = _authService.usuarioAtual;
    if (user == null) return;

    setState(() => _enviandoFoto = true);

    try {
      if (acao == 'remover') {
        await _userService.removerFotoPerfil(user.uid);
        if (mounted) setState(() => _fotoUrl = null);
      } else {
        // Reduz a imagem já na hora de escolher: upload mais rápido e
        // menos gasto no Storage.
        final arquivo = await _picker.pickImage(
          source: acao == 'camera' ? ImageSource.camera : ImageSource.gallery,
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 80,
        );

        // Usuário cancelou a seleção: não faz nada.
        if (arquivo == null) return;

        final bytes = await arquivo.readAsBytes();
        final url = await _userService.enviarFotoPerfil(
          user.uid,
          bytes,
          contentType: arquivo.mimeType ?? 'image/jpeg',
        );
        if (mounted) setState(() => _fotoUrl = url);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Não foi possível atualizar a foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _enviandoFoto = false);
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
      // Ordem importa: apaga os dados (Firestore e Storage) ANTES de
      // excluir a conta, porque depois de excluída as regras não
      // autorizam mais esse uid.
      await _ingredienteService.removerTodosDoUsuario(user.uid);
      await _userService.excluirArquivoFoto(user.uid);
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

  Widget _buildAvatar() {
    final temFoto = _fotoUrl != null && _fotoUrl!.isNotEmpty;

    return Stack(
      children: [
        CircleAvatar(
          radius: 48,
          backgroundColor: Colors.grey[300],
          backgroundImage: temFoto ? NetworkImage(_fotoUrl!) : null,
          // Se a imagem não carregar (sem internet, por exemplo), cai
          // no ícone padrão em vez de ficar um círculo vazio.
          onBackgroundImageError: temFoto ? (_, __) {} : null,
          child: temFoto
              ? null
              : Icon(Icons.person, size: 48, color: Colors.grey[700]),
        ),
        if (_enviandoFoto)
          Positioned.fill(
            child: CircleAvatar(
              backgroundColor: Colors.black38,
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
        Positioned(
          bottom: 0,
          right: 0,
          child: InkWell(
            onTap: _enviandoFoto ? null : _escolherFoto,
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.green,
              child: Icon(Icons.camera_alt, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
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
                      _buildAvatar(),
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