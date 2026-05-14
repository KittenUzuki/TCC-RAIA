
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'add_ingredientes_screen.dart'; 

class EstoqueScreen extends StatefulWidget {
  @override
  State<EstoqueScreen> createState() => _EstoqueScreenState();
}

class _EstoqueScreenState extends State<EstoqueScreen> {
  final User? user = FirebaseAuth.instance.currentUser;

  Future<void> _deletarIngrediente(String docId) async {
    if (user == null) return;
    try {
      // REATORAÇÃO: Apontar para a coleção correta para deletar
      await FirebaseFirestore.instance.collection('ingredientes').doc(docId).delete();
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

  void _mostrarModalEdicao(BuildContext context, QueryDocumentSnapshot ingrediente) {
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
          // A tela de edição já foi refatorada, então ela funcionará corretamente
          child: AddIngredientesScreen(ingrediente: ingrediente),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Meu Estoque"),
      ),
      body: user == null
          ? Center(child: Text("Faça login para ver seu estoque."))
          : StreamBuilder<QuerySnapshot>(
              // REATORAÇÃO: Alterar a consulta do StreamBuilder
              stream: FirebaseFirestore.instance
                  .collection('ingredientes') // 1. Acessar a coleção principal
                  .where('userId', isEqualTo: user!.uid) // 2. Filtrar pelo ID do usuário
                  .orderBy('validade') // 3. Ordenar os resultados
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Erro ao carregar o estoque: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text("Seu estoque está vazio. Toque no botão \"+\" para adicionar seu primeiro ingrediente!", textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final nome = data['nome'] ?? 'Nome não disponível';
                    final quantidade = data['quantidade'] ?? 0;
                    final unidade = data['unidade'] ?? '';
                    final Timestamp? validadeTimestamp = data['validade'];
                    final validade = validadeTimestamp?.toDate();

                    String subtitle = 'Qtd: $quantidade $unidade';
                    if (validade != null) {
                      subtitle += ' | Val: ${DateFormat('dd/MM/yyyy').format(validade)}';
                    }

                    return Dismissible(
                      key: Key(doc.id),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) => _deletarIngrediente(doc.id),
                      background: Container(
                        color: Colors.red.shade700,
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        alignment: Alignment.centerRight,
                        child: Icon(Icons.delete, color: Colors.white),
                      ),
                      child: ListTile(
                        title: Text(nome, style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(subtitle),
                        trailing: IconButton(
                          icon: Icon(Icons.edit, color: Theme.of(context).primaryColor),
                          onPressed: () => _mostrarModalEdicao(context, doc),
                          tooltip: 'Editar Ingrediente',
                        ),
                        onTap: () => _mostrarModalEdicao(context, doc),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
