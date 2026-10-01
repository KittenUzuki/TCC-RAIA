import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:raia_app/db.dart';
import 'package:raia_app/models/ingrediente.dart';

/// Encapsula todo o acesso à coleção `ingredientes` no Firestore.
///
/// As telas (estoque, formulário, home) não devem chamar
/// `db.collection('ingredientes')` diretamente — tudo passa por aqui.
/// Isso deixa o CRUD num lugar só: se o Firestore mudar, só este arquivo
/// muda, e dá pra testar a lógica sem precisar montar widgets.
class IngredienteService {
  final CollectionReference _collection = db.collection('ingredientes');

  /// Stream com todos os ingredientes do usuário, em tempo real.
  Stream<List<Ingrediente>> streamIngredientes(String userId) {
    return _collection.where('userId', isEqualTo: userId).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => Ingrediente.fromFirestore(doc))
              .toList(),
        );
  }

  /// Busca os ingredientes do usuário uma única vez (não fica ouvindo
  /// mudanças). Útil pra montar a lista de nomes que vai pra API de IA.
  Future<List<Ingrediente>> listarUmaVez(String userId) async {
    final snapshot =
        await _collection.where('userId', isEqualTo: userId).get();
    return snapshot.docs.map((doc) => Ingrediente.fromFirestore(doc)).toList();
  }

  Future<void> adicionar(Ingrediente ingrediente) {
    return _collection.add(ingrediente.toFirestoreCreate()).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw Exception(
          'TIMEOUT: o Firestore nao respondeu em 10s. '
          'Provavel causa: banco em modo Datastore (nao Nativo) ou conexao bloqueada.',
        );
      },
    );
  }

  Future<void> atualizar(Ingrediente ingrediente) {
    return _collection
        .doc(ingrediente.id)
        .update(ingrediente.toFirestoreUpdate())
        .timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw Exception(
          'TIMEOUT: o Firestore nao respondeu em 10s. '
          'Provavel causa: banco em modo Datastore (nao Nativo) ou conexao bloqueada.',
        );
      },
    );
  }

  Future<void> remover(String docId) {
    return _collection.doc(docId).delete();
  }

  /// Remove todos os ingredientes de um usuário. Usado ao excluir a conta.
  Future<void> removerTodosDoUsuario(String userId) async {
    final snapshot =
        await _collection.where('userId', isEqualTo: userId).get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }
}