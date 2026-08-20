import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/usuario_model.dart';

class UsuarioService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> criarUsuario(UsuarioModel usuario) async {
    try {
      print('====================================');
      print('TENTANDO SALVAR USUÁRIO NO FIRESTORE');
      print('====================================');

      print('UID: ${usuario.id}');
      print('Nome: ${usuario.nome}');
      print('Email: ${usuario.email}');
      print('Dados: ${usuario.toMap()}');

      print('Iniciando operação .set()...');

      await _firestore
          .collection('usuarios')
          .doc(usuario.id)
          .set(usuario.toMap())
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception(
                'TIMEOUT: Firestore não respondeu em 15 segundos.',
              );
            },
          );

      print('====================================');
      print('USUÁRIO SALVO COM SUCESSO!');
      print('====================================');
    } on FirebaseException catch (e) {
      print('====================================');
      print('ERRO DO FIREBASE FIRESTORE');
      print('Código: ${e.code}');
      print('Mensagem: ${e.message}');
      print('Detalhes: ${e.toString()}');
      print('====================================');

      rethrow;
    } catch (e) {
      print('====================================');
      print('ERRO DESCONHECIDO NO FIRESTORE');
      print('Erro: $e');
      print('====================================');

      rethrow;
    }
  }
}