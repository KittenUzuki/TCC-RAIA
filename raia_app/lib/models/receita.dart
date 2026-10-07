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

  /// Monta a receita a partir da resposta da API de sugestões (backend
  /// Python / TheMealDB).
  factory Receita.fromJson(Map<String, dynamic> json) {
    return Receita(
      id: json['id'],
      nome: json['nome'],
      imagem: json['imagem'],
      ingredientesFaltando: List<String>.from(json['ingredientesFaltando']),
      modoPreparo: json['modoPreparo'],
    );
  }

  /// Monta a receita a partir de um documento salvo em
  /// `users/{uid}/favoritos/{id}` (ver [FavoritoService]).
  factory Receita.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Receita(
      id: doc.id,
      nome: data['nome'] ?? '',
      imagem: data['imagem'] ?? '',
      ingredientesFaltando:
          List<String>.from(data['ingredientesFaltando'] ?? const []),
      modoPreparo: data['modoPreparo'] ?? '',
    );
  }

  /// Snapshot salvo ao favoritar — guarda os dados da receita como estavam
  /// no momento, já que ela vem de uma API externa.
  Map<String, dynamic> toFirestoreFavorito() {
    return {
      'nome': nome,
      'imagem': imagem,
      'ingredientesFaltando': ingredientesFaltando,
      'modoPreparo': modoPreparo,
      'favoritadoEm': FieldValue.serverTimestamp(),
    };
  }
}
