import 'package:flutter/material.dart';
import 'package:raia_app/services/auth_service.dart';
import 'package:raia_app/services/favorito_service.dart';

import '../../models/receita.dart';

class DetalheReceitaScreen extends StatefulWidget {
  final Receita receita;

  const DetalheReceitaScreen({
    super.key,
    required this.receita,
  });

  @override
  State<DetalheReceitaScreen> createState() => _DetalheReceitaScreenState();
}

class _DetalheReceitaScreenState extends State<DetalheReceitaScreen> {
  final _authService = AuthService();
  final _favoritoService = FavoritoService();

  // Criado uma vez só (e não dentro do build) pra o StreamBuilder não
  // reassinar o stream a cada rebuild da tela.
  Stream<bool>? _favoritaStream;

  Receita get receita => widget.receita;

  @override
  void initState() {
    super.initState();
    final user = _authService.usuarioAtual;
    if (user != null) {
      _favoritaStream =
          _favoritoService.streamEhFavorita(user.uid, receita.id);
    }
  }

  String get _subtitulo => [receita.categoria, receita.origem]
      .where((t) => t.isNotEmpty)
      .join(' • ');

  /// A linha é "Nome (medida)"; o ingrediente falta se o nome está na lista
  /// de faltando.
  bool _falta(String linha) => receita.ingredientesFaltando
      .any((f) => linha == f || linha.startsWith('$f ('));

  Future<void> _alternarFavorito(bool jaEFavorita) async {
    final user = _authService.usuarioAtual;
    if (user == null) return;

    try {
      if (jaEFavorita) {
        await _favoritoService.remover(user.uid, receita.id);
      } else {
        await _favoritoService.adicionar(user.uid, receita);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(jaEFavorita
                ? 'Removida dos favoritos.'
                : 'Adicionada aos favoritos!'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Não foi possível atualizar os favoritos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<String> get _passosPreparo {
    final texto = receita.modoPreparo.trim();
    if (texto.isEmpty) return [];

    final linhas = texto
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    return linhas.isNotEmpty ? linhas : [texto];
  }

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F2EE),
      appBar: AppBar(
        title: Text(receita.nome),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          StreamBuilder<bool>(
            stream: _favoritaStream,
            builder: (context, snapshot) {
              final ehFavorita = snapshot.data ?? false;
              final carregando =
                  snapshot.connectionState == ConnectionState.waiting;

              return IconButton(
                tooltip: ehFavorita
                    ? 'Remover dos favoritos'
                    : 'Adicionar aos favoritos',
                icon: Icon(
                  ehFavorita ? Icons.favorite : Icons.favorite_border,
                  color: ehFavorita ? Colors.red : null,
                ),
                // Desabilitado se não há usuário logado ou enquanto ainda
                // não sabemos se a receita já é favorita.
                onPressed: (_favoritaStream == null || carregando)
                    ? null
                    : () => _alternarFavorito(ehFavorita),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(largura * 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (receita.imagem.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    receita.imagem,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                ),

              if (receita.imagem.isNotEmpty) const SizedBox(height: 16),

              Text(
                receita.nome,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              if (_subtitulo.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  _subtitulo,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],

              const SizedBox(height: 25),

              if (receita.ingredientes.isNotEmpty) ...[
                const Text(
                  "Ingredientes",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  receita.ingredientesFaltando.isEmpty
                      ? "Você já tem tudo para cozinhar!"
                      : "Faltam ${receita.ingredientesFaltando.length} "
                          "de ${receita.ingredientes.length} ingredientes",
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 6),
                ...receita.ingredientes.map((linha) {
                  final falta = _falta(linha);
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      falta
                          ? Icons.shopping_cart_outlined
                          : Icons.check_circle,
                      color: falta ? Colors.orange.shade800 : Colors.green,
                    ),
                    title: Text(linha),
                  );
                }),
              ] else ...[
                Text(
                  receita.ingredientesFaltando.isEmpty
                      ? "Você já tem todos os ingredientes"
                      : "Ingredientes que faltam",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                if (receita.ingredientesFaltando.isEmpty)
                  const ListTile(
                    leading: Icon(Icons.check_circle, color: Colors.green),
                    title: Text("Tudo certo para cozinhar!"),
                  )
                else
                  ...receita.ingredientesFaltando.map(
                    (item) => ListTile(
                      leading: const Icon(Icons.shopping_cart_outlined),
                      title: Text(item),
                    ),
                  ),
              ],

              const SizedBox(height: 20),

              const Text(
                "Modo de preparo",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              ..._passosPreparo.asMap().entries.map(
                (entry) {
                  final index = entry.key + 1;
                  final passo = entry.value;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text("$index. $passo"),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
