
import 'package:cloud_firestore/cloud_firestore.dart';

class Ingrediente {
  final String id;
  final String nome;
  final double quantidade;
  final String unidade;
  final DateTime? validade;

  Ingrediente({
    required this.id,
    required this.nome,
    required this.quantidade,
    required this.unidade,
    this.validade,
  });

  factory Ingrediente.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Ingrediente(
      id: doc.id,
      nome: data['nome'] ?? '',
      quantidade: (data['quantidade'] ?? 0).toDouble(),
      unidade: data['unidade'] ?? '',
      validade: (data['validade'] as Timestamp?)?.toDate(),
    );
  }
}
