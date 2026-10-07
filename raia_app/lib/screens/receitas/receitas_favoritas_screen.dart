import 'package:flutter/material.dart';
import 'package:raia_app/models/receita.dart';
import 'package:raia_app/services/auth_service.dart';
import 'package:raia_app/services/favorito_service.dart';
import 'detalhe_receita_screen.dart';

class ReceitasFavoritasScreen extends StatelessWidget {
  ReceitasFavoritasScreen({super.key});

  final _authService = AuthService();
  final _favoritoService = FavoritoService();

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.of(context).size.width;
    final uid = _authService.usuarioAtual?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F2EE),
      appBar: AppBar(
        title: const Text("Favoritas"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: uid == null
          ? const Center(child: Text("Você precisa estar logado."))
          : Padding(
              padding: EdgeInsets.all(largura * 0.05),
              child: StreamBuilder<List<Receita>>(
                stream: _favoritoService.streamFavoritos(uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        "Não foi possível carregar seus favoritos.",
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  final favoritas = snapshot.data ?? [];

                  if (favoritas.isEmpty) {
                    return const Center(
                      child: Text("Nenhuma receita favorita ainda"),
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
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: receita.imagem.isNotEmpty
                                    ? Image.network(
                                        receita.imagem,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) => _iconePadrao(),
                                      )
                                    : _iconePadrao(),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      receita.nome,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      receita.ingredientesFaltando.isEmpty
                                          ? "Você tinha tudo pra fazer!"
                                          : "Faltava: ${receita.ingredientesFaltando.join(', ')}",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.favorite, color: Colors.red, size: 20),
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

  Widget _iconePadrao() {
    return Container(
      width: 60,
      height: 60,
      color: Colors.grey[300],
      child: Icon(Icons.restaurant, color: Colors.grey[700]),
    );
  }
}
