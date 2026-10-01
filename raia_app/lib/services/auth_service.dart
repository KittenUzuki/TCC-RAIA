import 'package:firebase_auth/firebase_auth.dart';
import 'package:raia_app/db.dart';
import 'package:raia_app/models/usuario.dart';

/// Centraliza toda a lógica de autenticação (login, cadastro, logout,
/// exclusão de conta e redefinição de senha).
///
/// Antes, `login_screen.dart`, `cadastro_screen.dart` e `perfil_screen.dart`
/// cada um instanciava `FirebaseAuth.instance` e repetia o mesmo padrão de
/// try/catch. Agora as telas só chamam os métodos daqui e tratam a
/// [AuthException], que já vem com mensagem em português.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get usuarioAtual => _auth.currentUser;

  /// Emite um evento sempre que o usuário loga ou desloga.
  Stream<User?> get mudancasDeEstado => _auth.authStateChanges();

  Future<void> login({required String email, required String senha}) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: senha.trim(),
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.code, _mensagemAmigavel(e.code));
    }
  }

  /// Cria a conta no FirebaseAuth e o documento de perfil em `users/{uid}`.
  Future<void> cadastrar({
    required String nome,
    required String email,
    required String senha,
  }) async {
    final UserCredential credencial;
    try {
      credencial = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: senha.trim(),
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.code, _mensagemAmigavel(e.code));
    }

    final uid = credencial.user?.uid;
    if (uid == null) {
      throw AuthException(
        'user-null',
        'Não foi possível criar a conta. Tente novamente.',
      );
    }

    final usuario = Usuario(uid: uid, nome: nome.trim(), email: email.trim());

    try {
      await db
          .collection('users')
          .doc(uid)
          .set(usuario.toFirestoreCreate())
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('timeout ao salvar perfil');
        },
      );
    } catch (e) {
      // A conta de autenticação já foi criada; só o perfil no Firestore
      // falhou. Melhor avisar o usuário do que deixar isso silencioso.
      throw AuthException(
        'perfil-nao-salvo',
        'Conta criada, mas houve um problema ao salvar seu perfil. '
            'Tente fazer login normalmente.',
      );
    }
  }

  Future<void> logout() => _auth.signOut();

  /// Exclui a conta do FirebaseAuth. Se o Firestore tiver dados do usuário
  /// (ingredientes, perfil), apague-os ANTES de chamar isso — depois de
  /// excluída a conta, as regras do Firestore não vão mais autorizar o uid.
  Future<void> excluirConta() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.code, _mensagemAmigavel(e.code));
    }
  }

  Future<void> enviarEmailRedefinicaoSenha(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.code, _mensagemAmigavel(e.code));
    }
  }

  String _mensagemAmigavel(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-mail ou senha incorretos.';
      case 'invalid-email':
        return 'O formato do e-mail é inválido.';
      case 'weak-password':
        return 'A senha fornecida é muito fraca (mínimo 6 caracteres).';
      case 'email-already-in-use':
        return 'O e-mail fornecido já está em uso.';
      case 'user-disabled':
        return 'Esta conta foi desativada.';
      case 'too-many-requests':
        return 'Muitas tentativas. Aguarde um pouco antes de tentar novamente.';
      case 'requires-recent-login':
        return 'Esta é uma operação sensível. Faça login novamente antes de continuar.';
      case 'network-request-failed':
        return 'Falha de conexão. Verifique sua internet e tente novamente.';
      default:
        return 'Ocorreu um erro inesperado. Tente novamente.';
    }
  }
}

/// Exceção lançada pelo [AuthService] com uma mensagem já traduzida pra
/// português. `code` mantém o código original do FirebaseAuth, caso a tela
/// precise reagir a um código específico (ex.: `requires-recent-login`).
class AuthException implements Exception {
  final String code;
  final String message;

  AuthException(this.code, this.message);

  @override
  String toString() => message;
}
