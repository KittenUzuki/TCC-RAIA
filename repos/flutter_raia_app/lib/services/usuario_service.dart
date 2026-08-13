import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/usuario_model.dart';

class UsuarioService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> criarUsuario(UsuarioModel usuario) async {
    await _firestore
        .collection('usuarios')
        .doc(usuario.id)
        .set(usuario.toMap());
  }
}