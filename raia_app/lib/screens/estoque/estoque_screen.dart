
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'package:raia_app/models/ingrediente.dart';

class EstoqueScreen extends StatefulWidget {
  @override
  _EstoqueScreenState createState() => _EstoqueScreenState();
}

class _EstoqueScreenState extends State<EstoqueScreen> {
  late Future<List<Ingrediente>> _ingredientesFuture;

  @override
  void initState() {
    super.initState();
    _ingredientesFuture = _fetchIngredientes();
  }

  Future<List<Ingrediente>> _fetchIngredientes() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Se não houver usuário logado, retorna uma lista vazia.
      return [];
    }

    final querySnapshot = await FirebaseFirestore.instance
        .collection('ingredientes')
        .doc(user.uid)
        .collection('userIngredientes')
        .get();

    return querySnapshot.docs
        .map((doc) => Ingrediente.fromFirestore(doc))
        .toList();
  }

  Color getCorValidade(DateTime? data) {
    if (data == null) return Colors.grey;

    final hoje = DateTime.now();
    // Zera a hora, minuto, segundo para comparar apenas as datas
    final dataSemHora = DateTime(data.year, data.month, data.day);
    final hojeSemHora = DateTime(hoje.year, hoje.month, hoje.day);

    if (dataSemHora.isBefore(hojeSemHora)) {
      return Colors.red; // vencido
    } else if (dataSemHora.difference(hojeSemHora).inDays <= 3) {
      return Colors.orange; // perto de vencer
    } else {
      return Colors.green; // ok
    }
  }

  String formatarData(DateTime? data) {
    if (data == null) return "Sem validade";
    return DateFormat('dd/MM/yyyy').format(data);
  }

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Color(0xFFF5F2EE),
      appBar: AppBar(
        title: Text("Estoque"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: EdgeInsets.all(largura * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Seus ingredientes",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<List<Ingrediente>>(
                future: _ingredientesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                        child: Text("Erro ao carregar os ingredientes."));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                        child: Text("Você ainda não tem ingredientes."));
                  }

                  final itens = snapshot.data!;

                  return ListView.builder(
                    itemCount: itens.length,
                    itemBuilder: (context, index) {
                      final item = itens[index];
                      final cor = getCorValidade(item.validade);

                      return Container(
                        margin: EdgeInsets.only(bottom: 12),
                        padding: EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border(
                            left: BorderSide(color: cor, width: 5),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.nome,
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 5),
                                Text("Qtd: ${item.quantidade}"),
                                Text(
                                    "Validade: ${formatarData(item.validade)}"),
                              ],
                            ),
                            Icon(Icons.kitchen),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
