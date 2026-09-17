import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:raia_app/db.dart';

import '../../models/ingrediente.dart';
import '../../models/receita.dart';
import 'receitas_favoritas_screen.dart'; // 🔥 IMPORTANTE
import 'detalhe_receita_screen.dart';

class ReceitasScreen extends StatefulWidget {
  const ReceitasScreen({super.key});

  @override
  State<ReceitasScreen> createState() => _ReceitasScreenState();
}

class _ReceitasScreenState extends State<ReceitasScreen> {
  static const String _endpointReceitasSugeridas =
      'http://localhost:5000/sugerir';

  final TextEditingController _buscaController = TextEditingController();

  Future<List<Receita>>? _futureReceitas;
  List<Receita> _todasReceitas = [];
  List<Receita> _receitasFiltradas = [];

  @override
  void initState() {
    super.initState();
    _carregarReceitas();
    _buscaController.addListener(_filtrar);
  }

  @override
  void dispose() {
    _buscaController.removeListener(_filtrar);
    _buscaController.dispose();
    super.dispose();
  }

  void _carregarReceitas() {
    setState(() {
      _futureReceitas = buscarReceitasSugeridas();
    });
  }

  void _filtrar() {
    final termo = _buscaController.text.trim().toLowerCase();
    setState(() {
      _receitasFiltradas = termo.isEmpty
          ? _todasReceitas
          : _todasReceitas
              .where((r) => r.nome.toLowerCase().contains(termo))
              .toList();
    });
  }

  Future<List<Receita>> buscarReceitasSugeridas() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado.');
    }

    final snapshot = await db
      .collection('ingredientes')
      .where('userId', isEqualTo: user.uid)
      .get();

    final nomes = snapshot.docs
        .map((doc) => Ingrediente.fromFirestore(doc).nome)
        .toList();

    if (nomes.isEmpty) {
      return [];
    }
    if (_endpointReceitasSugeridas.isEmpty) {
      throw Exception('Endpoint do backend não configurado.');
    }
    final resposta = await http
        .post(
          Uri.parse(_endpointReceitasSugeridas),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'ingredientes': nomes}),
        )
        .timeout(const Duration(seconds: 20));

    if (resposta.statusCode != 200) {
      throw Exception(
        'Falha ao buscar receitas sugeridas (status ${resposta.statusCode}).',
      );
    }

    final json = jsonDecode(resposta.body);
    final lista = (json['receitas'] as List)
        .map((r) => Receita.fromJson(r as Map<String, dynamic>))
        .toList();

    return lista;
  }

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F2EE),
      appBar: AppBar(
        title: const Text("Receitas"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,

        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReceitasFavoritasScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(largura * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Sugestões para você",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _buscaController,
              decoration: InputDecoration(
                hintText: "Buscar receita...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<List<Receita>>(
                future: _futureReceitas,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return _buildEstadoErro(snapshot.error.toString());
                  }

                  final receitas = snapshot.data ?? [];
                  if (receitas.isEmpty) {
                    return _buildEstadoVazio();
                  }

                  if (_todasReceitas != receitas) {
                    _todasReceitas = receitas;
                    _receitasFiltradas =
                        _buscaController.text.trim().isEmpty
                            ? receitas
                            : _receitasFiltradas;
                    if (_buscaController.text.trim().isNotEmpty) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _filtrar();
                      });
                    }
                  }

                  final lista = _buscaController.text.trim().isEmpty
                      ? _todasReceitas
                      : _receitasFiltradas;

                  if (lista.isEmpty) {
                    return const Center(
                      child: Text("Nenhuma receita encontrada."),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      _carregarReceitas();
                      await _futureReceitas;
                    },
                    child: ListView.builder(
                      itemCount: lista.length,
                      itemBuilder: (context, index) {
                        final receita = lista[index];

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
                                _buildImagem(receita.imagem),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                      if (receita
                                          .ingredientesFaltando.isNotEmpty)
                                        Text(
                                          "Faltam: ${receita.ingredientesFaltando.join(', ')}",
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontSize: 13,
                                          ),
                                        )
                                      else
                                        const Text(
                                          "Você tem tudo para fazer!",
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontSize: 13,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagem(String imagem) {
    const double tamanho = 48;
    if (imagem.isEmpty) {
      return const Icon(Icons.restaurant, size: tamanho, color: Colors.green);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imagem,
        width: tamanho,
        height: tamanho,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.restaurant,
          size: tamanho,
          color: Colors.green,
        ),
      ),
    );
  }

  Widget _buildEstadoVazio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.kitchen, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              "Nenhuma sugestão ainda.\nAdicione ingredientes ao seu estoque para receber sugestões.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _carregarReceitas,
              child: const Text("Atualizar"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadoErro(String mensagem) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              "Não foi possível carregar as receitas.\n$mensagem",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _carregarReceitas,
              child: const Text("Tentar novamente"),
            ),
          ],
        ),
      ),
    );
  }
}