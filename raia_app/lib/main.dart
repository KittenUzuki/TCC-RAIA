import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:raia_app/db.dart';
import 'firebase_options.dart';
import 'screens/main_screen.dart';

// auth
import 'screens/auth/login_screen.dart';
import 'screens/auth/cadastro_screen.dart';
import 'screens/auth/esqueci_senha_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // No Flutter Web, a conexao padrao do Firestore (WebChannel) as vezes e
  // bloqueada por proxy/extensao/rede, causando o erro
  // "unavailable: client is offline". Forcar long-polling contorna isso.
  if (kIsWeb) {
    db.settings = const Settings(
      persistenceEnabled: false,
      webExperimentalForceLongPolling: true,
    );
  }

  // DIAGNOSTICO: testa a conexao com o Firestore automaticamente no startup.
  // Nao precisa de login nem navegacao. Distingue conexao-quebrada de regra.
  _diagFirestore();

  runApp(RaiaApp());
}

Future<void> _diagFirestore() async {
  print('DIAG: kIsWeb=$kIsWeb, testando conexao com o Firestore...');
  try {
    final snap = await db
        .collection('users')
        .doc('__diag_probe__')
        .get(const GetOptions(source: Source.server))
        .timeout(const Duration(seconds: 15));
    print('DIAG: >>> CONEXAO OK. (existe=${snap.exists})');
  } on FirebaseException catch (e) {
    print('DIAG: FirebaseException code=${e.code} plugin=${e.plugin} msg=${e.message}');
    if (e.code == 'permission-denied') {
      print('DIAG: >>> CONEXAO FUNCIONA - foi so a regra que negou. O problema NAO e conexao.');
    } else if (e.code == 'unavailable') {
      print('DIAG: >>> CLIENTE OFFLINE - a conexao com o Firestore realmente falhou.');
    }
  } catch (e) {
    print('DIAG: erro inesperado: ${e.runtimeType} -> $e');
  }
}

class RaiaApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Raia',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Color(0xFFF5F2EE),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/cadastro': (context) => CadastroScreen(),
        '/main': (context) => MainScreen(),
        '/esqueciSenha': (context) => EsqueciSenhaScreen(),
        
      },
    );
  }
}

