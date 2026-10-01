import 'package:cloud_firestore/cloud_firestore.dart';

/// Representa o perfil do usuário salvo em `users/{uid}` no Firestore.
/// (A autenticação em si — senha, e-mail de login — continua no FirebaseAuth;
/// aqui é só o perfil complementar: nome, foto, etc.)
class Usuario {
  final String uid;
  final String nome;
  final String email;
  final String? fotoUrl;
  final DateTime? criadoEm;

  Usuario({
    required this.uid,
    required this.nome,
    required this.email,
    this.fotoUrl,
    this.criadoEm,
  });

  factory Usuario.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Usuario(
      uid: doc.id,
      nome: data['nome'] ?? '',
      email: data['email'] ?? '',
      fotoUrl: data['fotoUrl'],
      criadoEm: (data['dataCriacao'] as Timestamp?)?.toDate(),
    );
  }

  /// Campos gravados na criação do perfil (junto com o cadastro).
  Map<String, dynamic> toFirestoreCreate() {
    return {
      'nome': nome,
      'email': email,
      if (fotoUrl != null) 'fotoUrl': fotoUrl,
      'dataCriacao': FieldValue.serverTimestamp(),
    };
  }

  Usuario copyWith({String? nome, String? fotoUrl}) {
    return Usuario(
      uid: uid,
      nome: nome ?? this.nome,
      email: email,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      criadoEm: criadoEm,
    );
  }
}