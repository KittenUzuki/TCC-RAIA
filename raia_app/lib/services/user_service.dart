import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:raia_app/db.dart';
import 'package:raia_app/models/usuario.dart';

/// Encapsula o acesso à coleção `users` no Firestore (perfil do usuário,
/// separado da autenticação em si, que fica no [AuthService]).
class UserService {
  final CollectionReference _collection = db.collection('users');

  Future<Usuario?> buscarPerfil(String uid) async {
    final doc = await _collection
        .doc(uid)
        .get(const GetOptions(source: Source.server));
    if (!doc.exists) return null;
    return Usuario.fromFirestore(doc);
  }

  Future<void> atualizarPerfil(String uid, Map<String, dynamic> dados) {
    return _collection.doc(uid).update(dados);
  }

  Future<void> excluirPerfil(String uid) {
    return _collection.doc(uid).delete();
  }
}
