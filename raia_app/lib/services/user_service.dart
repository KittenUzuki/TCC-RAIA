import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:raia_app/db.dart';
import 'package:raia_app/models/usuario.dart';

/// Encapsula o acesso à coleção `users` no Firestore e à foto de perfil no
/// Firebase Storage (perfil do usuário, separado da autenticação em si,
/// que fica no [AuthService]).
class UserService {
  final CollectionReference _collection = db.collection('users');
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Sempre o mesmo caminho por usuário: cada foto nova sobrescreve a
  /// anterior, então o Storage não acumula arquivos velhos.
  Reference _refFoto(String uid) => _storage.ref('perfil/$uid/foto.jpg');

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

  /// Envia a foto pro Storage, grava a URL em `users/{uid}.fotoUrl` e
  /// devolve a URL. Usa `putData` (bytes) em vez de `putFile`, então
  /// funciona no Android, iOS e Web.
  Future<String> enviarFotoPerfil(
    String uid,
    Uint8List bytes, {
    String contentType = 'image/jpeg',
  }) async {
    final ref = _refFoto(uid);

    await ref
        .putData(bytes, SettableMetadata(contentType: contentType))
        .timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw Exception('O envio da foto demorou demais. Tente de novo.');
      },
    );

    final url = await ref.getDownloadURL();

    // Como o arquivo é sobrescrito no mesmo caminho, a URL base não muda.
    // O "&v=..." força o app a baixar a foto nova em vez de mostrar a
    // antiga que ficou em cache. O Storage ignora esse parâmetro extra.
    final urlComVersao = '$url&v=${DateTime.now().millisecondsSinceEpoch}';

    await _collection.doc(uid).update({'fotoUrl': urlComVersao});
    return urlComVersao;
  }

  /// Apaga o arquivo da foto no Storage (se existir). Usado ao remover a
  /// foto e ao excluir a conta.
  Future<void> excluirArquivoFoto(String uid) async {
    try {
      await _refFoto(uid).delete();
    } on FirebaseException catch (e) {
      // Se o usuário nunca enviou foto, não existe arquivo: não é erro.
      if (e.code != 'object-not-found') rethrow;
    }
  }

  /// Remove a foto: apaga o arquivo e limpa o campo no perfil.
  Future<void> removerFotoPerfil(String uid) async {
    await excluirArquivoFoto(uid);
    await _collection.doc(uid).update({'fotoUrl': FieldValue.delete()});
  }
}