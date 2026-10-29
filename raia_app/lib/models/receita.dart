import 'package:cloud_firestore/cloud_firestore.dart';

class Receita {
  final String id;
  final String nome;
  final String imagem;
  final List<String> ingredientesFaltando;
  final String modoPreparo;

  Receita({
    required this.id,
    required this.nome,
    required this.imagem,
    required this.ingredientesFaltando,
    required this.modoPreparo,
  });

  /// Lê a receita que vem da API de sugestões.
  factory Receita.fromJson(Map<String, dynamic> json) {
    return Receita(
      id: json['id'],
      nome: json['nome'],
      imagem: json['imagem'],
      ingredientesFaltando: List<String>.from(json['ingredientesFaltando']),
      modoPreparo: json['modoPreparo'],
    );
  }

  /// Lê uma receita favoritada, salva em `users/{uid}/favoritos/{id}`.
  factory Receita.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Receita(
      id: doc.id,
      nome: data['nome'] ?? '',
      imagem: data['imagem'] ?? '',
      ingredientesFaltando:
          List<String>.from(data['ingredientesFaltando'] ?? []),
      modoPreparo: data['modoPreparo'] ?? '',
    );
  }

  /// Cópia da receita gravada ao favoritar (o id vira o ID do documento,
  /// por isso não entra aqui). `favoritadaEm` ordena a lista de favoritas.
  Map<String, dynamic> toFirestoreFavorito() {
    return {
      'nome': nome,
      'imagem': imagem,
      'ingredientesFaltando': ingredientesFaltando,
      'modoPreparo': modoPreparo,
      'favoritadaEm': Timestamp.now(),
    };
  }
}