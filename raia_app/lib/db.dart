import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// IMPORTANTE: o app usa um banco Firestore NOMEADO 'default' (o que existe no
// projeto raia-app-81e71), e NAO o banco reservado '(default)'. Por isso todo
// acesso ao Firestore deve passar por esta instancia, e nao por
// FirebaseFirestore.instance (que apontaria para o '(default)' inexistente).
final FirebaseFirestore db = FirebaseFirestore.instanceFor(
  app: Firebase.app(),
  databaseId: 'default',
);
