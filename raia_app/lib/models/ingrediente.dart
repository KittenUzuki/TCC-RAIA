import 'package:cloud_firestore/cloud_firestore.dart';

/// Representa um ingrediente do estoque do usuário.
///
/// `quantidade` é sempre `double` (nunca `int`), pra permitir valores como
/// "1.5 kg" sem quebrar. Ao ler do formulário, faça
/// `double.tryParse(texto.replaceAll(',', '.'))`.
class Ingrediente {
  final String id;
  final String userId;
  final String nome;
  final double quantidade;
  final String unidade;
  final DateTime? validade;
  final DateTime? criadoEm;

  Ingrediente({
    required this.id,
    required this.userId,
    required this.nome,
    required this.quantidade,
    required this.unidade,
    this.validade,
    this.criadoEm,
  });

  factory Ingrediente.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Ingrediente(
      id: doc.id,
      userId: data['userId'] ?? '',
      nome: data['nome'] ?? '',
      quantidade: (data['quantidade'] ?? 0).toDouble(),
      unidade: data['unidade'] ?? '',
      validade: (data['validade'] as Timestamp?)?.toDate(),
      criadoEm: (data['criadoEm'] as Timestamp?)?.toDate(),
    );
  }

  /// Campos gravados na CRIAÇÃO de um ingrediente (inclui `criadoEm`, usado
  /// depois pra ordenar os "itens recentes" da Home).
  Map<String, dynamic> toFirestoreCreate() {
    return {
      'userId': userId,
      'nome': nome,
      'quantidade': quantidade,
      'unidade': unidade,
      'validade': validade != null ? Timestamp.fromDate(validade!) : null,
      'criadoEm': Timestamp.now(),
    };
  }

  /// Campos gravados numa ATUALIZAÇÃO (não mexe em quem criou/quando).
  Map<String, dynamic> toFirestoreUpdate() {
    return {
      'nome': nome,
      'quantidade': quantidade,
      'unidade': unidade,
      'validade': validade != null ? Timestamp.fromDate(validade!) : null,
    };
  }

  Ingrediente copyWith({
    String? nome,
    double? quantidade,
    String? unidade,
    DateTime? validade,
  }) {
    return Ingrediente(
      id: id,
      userId: userId,
      nome: nome ?? this.nome,
      quantidade: quantidade ?? this.quantidade,
      unidade: unidade ?? this.unidade,
      validade: validade ?? this.validade,
    );
  }
}