import 'package:flutter/material.dart';
import 'package:raia_app/models/receita.dart';
import 'package:raia_app/services/auth_service.dart';
import 'package:raia_app/services/favorito_service.dart';
import 'detalhe_receita_screen.dart';

class ReceitasFavoritasScreen extends StatefulWidget {
  @override
  State<ReceitasFavoritasScreen> createState() =>
      _ReceitasFavoritasScreenState();
}

class _ReceitasFavoritasScreenState extends State<ReceitasFavoritasScreen> {
  final _authService = AuthService();
  final _favoritoService = FavoritoService();

  Stream<List<Receita>>? _favoritasStream;

  @override
  void initState() {
    super.initState();
    final user = _authService.usuarioAtual;
    if (user != null) {
      _favoritasStream = _favoritoService.streamFavoritos(user.uid);
    }
  }

  Future<void> _desfavoritar(Receita receita) async {
    final user = _authService.usuarioAtual;
    if (user == null) return;

    try {
      await _favoritoService.remover(user.uid, receita.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Não foi possível remover dos favoritos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildImagem(String imagem) {
    const double tamanho = 60;
    final placeholder = Container(
      width: tamanho,
      height: tamanho,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(Icons.restaurant, color: Colors.grey[700]),
    );

    if (imagem.isEmpty) return placeholder;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        imagem,
        width: tamanho,
        height: tamanho,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => placeholder,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Color(0xFFF5F2EE),
      appBar: AppBar(
        title: Text("Favoritas"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: EdgeInsets.all(largura * 0.05),
        child: _favoritasStream == null
            ? Center(child: Text("Faça login para ver suas favoritas."))
            : StreamBuilder<List<Receita>>(
                stream: _favoritasStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                          "Erro ao carregar as favoritas: ${snapshot.error}"),
                    );
                  }

                  final favoritas = snapshot.data ?? [];
                  if (favoritas.isEmpty) {
                    return Center(
                      child: Text(
                        "Nenhuma receita favorita ainda.\nToque no coração de uma receita pra salvá-la aqui.",
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: favoritas.length,
                    itemBuilder: (context, index) {
                      final receita = favoritas[index];

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DetalheReceitaScreen(receita: receita),
                            ),
                          );
                        },
                        child: Container(
                          margin: EdgeInsets.only(bottom: 12),
                          padding: EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              _buildImagem(receita.imagem),
                              SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      receita.nome,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      receita.ingredientesFaltando.isEmpty
                                          ? "Sem ingredientes faltando"
                                          : "Faltavam: ${receita.ingredientesFaltando.join(', ')}",
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Remover dos favoritos',
                                icon: Icon(Icons.favorite, color: Colors.red),
                                onPressed: () => _desfavoritar(receita),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}
