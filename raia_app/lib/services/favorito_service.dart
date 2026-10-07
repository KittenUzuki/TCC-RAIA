import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:raia_app/db.dart';
import 'package:raia_app/models/receita.dart';

/// Encapsula o acesso aos favoritos do usuário.
///
/// Guardados como subcoleção `users/{uid}/favoritos/{receitaId}`, usando o
/// próprio `id` da receita (o `idMeal` do TheMealDB) como ID do documento.
/// Isso tem duas vantagens sobre uma coleção `favoritos` separada com um
/// campo `userId`:
///  - Saber se uma receita já está favoritada vira um `get()` direto por
///    ID (rápido), em vez de uma query.
///  - As regras de segurança ficam automáticas: quem já pode ler/escrever
///    `users/{uid}` ganha acesso à subcoleção dele com uma única regra
///    recursiva (ver firestore.rules).
///
/// Guardamos uma cópia (snapshot) dos dados da receita no momento em que
/// foi favoritada — nome, imagem, modo de preparo — porque a receita vem
/// de uma API externa (TheMealDB) e não existe em nenhuma coleção nossa
/// pra "buscar de novo" depois.
class FavoritoService {
  CollectionReference _colecao(String uid) =>
      db.collection('users').doc(uid).collection('favoritos');

  Stream<List<Receita>> streamFavoritos(String uid) {
    return _colecao(uid).orderBy('favoritadoEm', descending: true).snapshots().map(
          (snap) => snap.docs.map((doc) => Receita.fromFirestore(doc)).toList(),
        );
  }

  /// `true`/`false` em tempo real — usado pra pintar o coração da tela de
  /// detalhe da receita sem precisar carregar a lista inteira de favoritos.
  Stream<bool> streamEhFavorito(String uid, String receitaId) {
    return _colecao(uid).doc(receitaId).snapshots().map((doc) => doc.exists);
  }

  Future<void> favoritar(String uid, Receita receita) {
    return _colecao(uid).doc(receita.id).set(receita.toFirestoreFavorito());
  }

  Future<void> desfavoritar(String uid, String receitaId) {
    return _colecao(uid).doc(receitaId).delete();
  }
}
