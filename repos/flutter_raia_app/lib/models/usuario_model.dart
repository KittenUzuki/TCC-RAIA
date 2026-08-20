import 'package:cloud_firestore/cloud_firestore.dart';

class UsuarioModel {
  final String id;
  final String nome;
  final String email;
  final DateTime dataCriacao;

  UsuarioModel({
    required this.id,
    required this.nome,
    required this.email,
    required this.dataCriacao,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      'dataCriacao': Timestamp.fromDate(dataCriacao),
    };
  }

  factory UsuarioModel.fromMap(Map<String, dynamic> map) {
    return UsuarioModel(
      id: map['id'] as String,
      nome: map['nome'] as String,
      email: map['email'] as String,
      dataCriacao: (map['dataCriacao'] as Timestamp).toDate(),
    );
  }
}