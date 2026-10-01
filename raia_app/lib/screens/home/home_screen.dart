import 'package:flutter/material.dart';
import 'package:raia_app/models/ingrediente.dart';
import 'package:raia_app/services/auth_service.dart';
import 'package:raia_app/services/ingrediente_service.dart';
import 'package:raia_app/screens/receitas/receitas_screen.dart';

// estoque
import '../estoque/add_ingredientes_screen.dart';
import '../estoque/estoque_screen.dart';

/// Quantos itens mostrar na seção "Itens recentes".
const int _limiteItensRecentes = 3;

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _ingredienteService = IngredienteService();

  /// Pega os N ingredientes criados mais recentemente, a partir da lista
  /// completa que já veio do stream (evita precisar de um índice composto
  /// no Firestore só pra isso).
  List<Ingrediente> _maisRecentes(List<Ingrediente> todos) {
    final copia = [...todos];
    copia.sort((a, b) {
      final dataA = a.criadoEm;
      final dataB = b.criadoEm;
      if (dataA == null && dataB == null) return 0;
      if (dataA == null) return 1; // sem data vai pro fim
      if (dataB == null) return -1;
      return dataB.compareTo(dataA); // mais recente primeiro
    });
    return copia.take(_limiteItensRecentes).toList();
  }

  String _formatarQuantidade(double quantidade) {
    if (quantidade == quantidade.roundToDouble()) {
      return quantidade.toInt().toString();
    }
    return quantidade.toString();
  }

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.of(context).size.width;
    final user = _authService.usuarioAtual;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(largura * 0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 10),

                Text("Raia",
                    style:
                        TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),

                Text("Sua cozinha inteligente"),

                SizedBox(height: 20),

                if (user == null)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text("Faça login para ver seu estoque."),
                  )
                else
                  StreamBuilder<List<Ingrediente>>(
                    stream: _ingredienteService.streamIngredientes(user.uid),
                    builder: (context, snapshot) {
                      final ingredientes = snapshot.data ?? [];

                      final cardEstoque = Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: snapshot.connectionState ==
                                    ConnectionState.waiting &&
                                !snapshot.hasData
                            ? Text("Carregando seu estoque...")
                            : snapshot.hasError
                                ? Text("Erro ao carregar o estoque.")
                                : Text(
                                    "Você tem ${ingredientes.length} ${ingredientes.length == 1 ? 'item' : 'itens'} no estoque",
                                  ),
                      );

                      final recentes = _maisRecentes(ingredientes);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          cardEstoque,
                          SizedBox(height: 20),
                          buildButton("Adicionar alimento", () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddIngredientesScreen(),
                              ),
                            );
                          }),
                          buildButton("Ver estoque", () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EstoqueScreen(),
                              ),
                            );
                          }),
                          buildButton("Ver Receitas", () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ReceitasScreen(),
                              ),
                            );
                          }),
                          SizedBox(height: 20),
                          Text("Itens recentes",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          if (snapshot.connectionState ==
                                  ConnectionState.waiting &&
                              !snapshot.hasData)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else if (recentes.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                "Nenhum item ainda. Toque em \"Adicionar alimento\" pra começar!",
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            )
                          else
                            ...recentes.map(
                              (ingrediente) => buildItem(
                                "${ingrediente.nome} (${_formatarQuantidade(ingrediente.quantidade)} ${ingrediente.unidade})",
                              ),
                            ),
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildButton(String text, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          minimumSize: Size(double.infinity, 45),
        ),
        child: Text(text),
      ),
    );
  }

  Widget buildItem(String item) {
    return ListTile(
      leading: Icon(Icons.check_circle_outline),
      title: Text(item),
    );
  }
}