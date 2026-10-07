import 'package:flutter/material.dart';

import '../../models/receita.dart';
import '../../services/auth_service.dart';
import '../../services/favorito_service.dart';

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

  bool _processando = false;

  List<String> get _passosPreparo {
    final texto = widget.receita.modoPreparo.trim();
    if (texto.isEmpty) return [];

    final linhas = texto
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    return linhas.isNotEmpty ? linhas : [texto];
  }

  Future<void> _alternarFavorito(bool jaEhFavorito) async {
    final uid = _authService.usuarioAtual?.uid;
    if (uid == null || _processando) return;

    setState(() => _processando = true);
    try {
      if (jaEhFavorito) {
        await _favoritoService.desfavoritar(uid, widget.receita.id);
      } else {
        await _favoritoService.favoritar(uid, widget.receita);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível atualizar os favoritos.')),
        );
      }
    } finally {
      if (mounted) setState(() => _processando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.of(context).size.width;
    final uid = _authService.usuarioAtual?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F2EE),
      appBar: AppBar(
        title: Text(widget.receita.nome),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          if (uid == null)
            const SizedBox.shrink()
          else
            StreamBuilder<bool>(
              stream: _favoritoService.streamEhFavorito(uid, widget.receita.id),
              builder: (context, snapshot) {
                final ehFavorito = snapshot.data ?? false;
                return IconButton(
                  icon: Icon(
                    ehFavorito ? Icons.favorite : Icons.favorite_border,
                    color: ehFavorito ? Colors.red : null,
                  ),
                  onPressed: _processando
                      ? null
                      : () => _alternarFavorito(ehFavorito),
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
              if (widget.receita.imagem.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    widget.receita.imagem,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                ),

              if (widget.receita.imagem.isNotEmpty) const SizedBox(height: 16),

              Text(
                widget.receita.nome,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 25),

              Text(
                widget.receita.ingredientesFaltando.isEmpty
                    ? "Você já tem todos os ingredientes"
                    : "Ingredientes que faltam",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              if (widget.receita.ingredientesFaltando.isEmpty)
                const ListTile(
                  leading: Icon(Icons.check_circle, color: Colors.green),
                  title: Text("Tudo certo para cozinhar!"),
                )
              else
                ...widget.receita.ingredientesFaltando.map(
                  (item) => ListTile(
                    leading: const Icon(Icons.shopping_cart_outlined),
                    title: Text(item),
                  ),
                ),

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
