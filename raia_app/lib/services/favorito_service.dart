import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:raia_app/db.dart';
import 'package:raia_app/models/receita.dart';

/// Encapsula o acesso às receitas favoritas, guardadas na subcoleção
/// `users/{uid}/favoritos`. As telas não falam direto com o Firestore.
class FavoritoService {
  CollectionReference _favoritos(String userId) =>
      db.collection('users').doc(userId).collection('favoritos');

  /// Todas as receitas favoritas do usuário, da mais recente pra mais antiga.
  Stream<List<Receita>> streamFavoritos(String userId) {
    return _favoritos(userId)
        .orderBy('favoritadaEm', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Receita.fromFirestore(doc)).toList());
  }

  /// Emite true/false conforme a receita seja (ou não) favorita.
  /// Usado pra pintar o coração na tela de detalhe.
  Stream<bool> streamEhFavorita(String userId, String receitaId) {
    return _favoritos(userId)
        .doc(receitaId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  Future<void> adicionar(String userId, Receita receita) {
    return _favoritos(userId).doc(receita.id).set(receita.toFirestoreFavorito());
  }

  Future<void> remover(String userId, String receitaId) {
    return _favoritos(userId).doc(receitaId).delete();
  }

  /// Apaga todos os favoritos do usuário. Usado ao excluir a conta
  /// (o Firestore não apaga subcoleções sozinho quando o documento pai some).
  Future<void> removerTodosDoUsuario(String userId) async {
    final snapshot = await _favoritos(userId).get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }
}