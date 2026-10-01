import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:raia_app/models/ingrediente.dart';
import 'package:raia_app/services/auth_service.dart';
import 'package:raia_app/services/ingrediente_service.dart';

import 'add_ingredientes_screen.dart';

class EstoqueScreen extends StatefulWidget {
  @override
  State<EstoqueScreen> createState() => _EstoqueScreenState();
}

class _EstoqueScreenState extends State<EstoqueScreen> {
  final _authService = AuthService();
  final _ingredienteService = IngredienteService();
  User? get user => _authService.usuarioAtual;

  Future<void> _deletarIngrediente(String docId) async {
    if (user == null) return;
    try {
      await _ingredienteService.remover(docId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ingrediente removido com sucesso!'), duration: Duration(seconds: 2)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao remover ingrediente: $e')),
        );
      }
    }
  }

  void _mostrarModalEdicao(BuildContext context, Ingrediente ingrediente) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: AddIngredientesScreen(ingrediente: ingrediente),
        );
      },
    );
  }

  String _formatarQuantidade(double quantidade) {
    // Evita mostrar "2.0" quando a quantidade é um número inteiro.
    if (quantidade == quantidade.roundToDouble()) {
      return quantidade.toInt().toString();
    }
    return quantidade.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Meu Estoque"),
      ),
      body: user == null
          ? Center(child: Text("Faça login para ver seu estoque."))
          : StreamBuilder<List<Ingrediente>>(
              stream: _ingredienteService.streamIngredientes(user!.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Erro ao carregar o estoque: ${snapshot.error}"));
                }

                final ingredientes = snapshot.data ?? [];
                if (ingredientes.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text("Seu estoque está vazio. Toque no botão \"+\" para adicionar seu primeiro ingrediente!", textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: ingredientes.length,
                  itemBuilder: (context, index) {
                    final ingrediente = ingredientes[index];

                    String subtitle = 'Qtd: ${_formatarQuantidade(ingrediente.quantidade)} ${ingrediente.unidade}';
                    if (ingrediente.validade != null) {
                      subtitle += ' | Val: ${DateFormat('dd/MM/yyyy').format(ingrediente.validade!)}';
                    }

                    return Dismissible(
                      key: Key(ingrediente.id),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) => _deletarIngrediente(ingrediente.id),
                      background: Container(
                        color: Colors.red.shade700,
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        alignment: Alignment.centerRight,
                        child: Icon(Icons.delete, color: Colors.white),
                      ),
                      child: ListTile(
                        title: Text(ingrediente.nome, style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(subtitle),
                        trailing: IconButton(
                          icon: Icon(Icons.edit, color: Theme.of(context).primaryColor),
                          onPressed: () => _mostrarModalEdicao(context, ingrediente),
                          tooltip: 'Editar Ingrediente',
                        ),
                        onTap: () => _mostrarModalEdicao(context, ingrediente),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}