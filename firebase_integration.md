
# Guia de Integração com Firebase para o App RIRA

Este documento detalha a estrutura do banco de dados no Firestore, as regras de segurança e exemplos de código para integrar o seu aplicativo Flutter com o Firebase.

## 1. Estrutura do Firestore

A estrutura a seguir usa subcoleções para organizar os dados de forma que cada usuário tenha acesso apenas aos seus próprios documentos.

```
/users/{userId}
  - nome: "Nome do Usuário"
  - email: "usuario@email.com"

/ingredientes/{userId}/userIngredientes/{ingredienteId}
  - nome: "Tomate"
  - quantidade: 5
  - dataValidade: Timestamp (opcional)
  - criadoEm: Timestamp

/receitas/{receitaId}
  - nome: "Macarronada"
  - descricao: "Uma deliciosa macarronada para a família."
  - ingredientes: ["massa", "molho de tomate", "carne moída"]
  - preparo: ["Passo 1...", "Passo 2..."]
  - imagem: "url_da_imagem"

/favoritos/{userId}/userFavoritos/{receitaId}
  - nome: "Macarronada"
  - descricao: "Uma deliciosa macarronada para a família."
  - imagem: "url_da_imagem"
  - adicionadoEm: Timestamp
```

**Observações:**
*   A coleção `ingredientes` e `favoritos` são aninhadas sob o `userId`. Isso simplifica as regras de segurança.
*   A coleção `receitas` é mantida no nível raiz para que todas as receitas sejam públicas para todos os usuários.

---

## 2. Regras de Segurança do Firebase (firestore.rules)

Estas regras garantem que os usuários só possam ler e escrever seus próprios dados. Copie e cole isso na aba "Regras" do seu console do Firestore.

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Usuários podem ler e atualizar seu próprio perfil
    match /users/{userId} {
      allow read, update: if request.auth != null && request.auth.uid == userId;
    }

    // Permite que usuários autenticados criem seu perfil
    match /users/{userId} {
        allow create: if request.auth != null;
    }

    // Usuários podem ler e escrever apenas em sua própria lista de ingredientes
    match /ingredientes/{userId}/{documents=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // Usuários podem ler e escrever apenas em sua própria lista de favoritos
    match /favoritos/{userId}/{documents=**} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // Todas as receitas são públicas para leitura por qualquer usuário autenticado
    match /receitas/{receitaId} {
        allow read: if request.auth != null;
        // Restrinja a escrita apenas para administradores (se necessário)
        allow write: if false; 
    }
  }
}
```

---

## 3. Exemplos de Código (Dart + Flutter)

Primeiro, adicione os pacotes ao seu `pubspec.yaml`:
```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^3.1.1
  firebase_auth: ^5.1.1
  cloud_firestore: ^5.0.2
```

### Autenticação (AuthService)

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obter usuário atual
  User? get currentUser => _auth.currentUser;

  // Cadastro com Email e Senha
  Future<UserCredential?> signUp(String nome, String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Salvar informações do usuário no Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'nome': nome,
        'email': email,
      });

      return userCredential;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Login com Email e Senha
  Future<UserCredential?> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Sair
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
```

### Gerenciamento de Dados (FirestoreService)

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  // Adicionar um novo ingrediente
  Future<void> addIngrediente(String nome, int quantidade, DateTime? dataValidade) async {
    if (userId == null) return;

    await _firestore
        .collection('ingredientes')
        .doc(userId)
        .collection('userIngredientes')
        .add({
          'nome': nome,
          'quantidade': quantidade,
          'dataValidade': dataValidade != null ? Timestamp.fromDate(dataValidade) : null,
          'criadoEm': Timestamp.now(),
        });
  }

  // Obter stream de ingredientes do usuário
  Stream<QuerySnapshot> getIngredientesStream() {
    if (userId == null) return Stream.empty();

    return _firestore
        .collection('ingredientes')
        .doc(userId)
        .collection('userIngredientes')
        .orderBy('criadoEm', descending: true)
        .snapshots();
  }

  // Adicionar uma receita aos favoritos
  Future<void> addFavorito(String receitaId, Map<String, dynamic> receitaData) async {
    if (userId == null) return;

    await _firestore
        .collection('favoritos')
        .doc(userId)
        .collection('userFavoritos')
        .doc(receitaId)
        .set({
          ...receitaData,
          'adicionadoEm': Timestamp.now(),
        });
  }

  // Remover um favorito
  Future<void> removeFavorito(String receitaId) async {
    if (userId == null) return;

    await _firestore
        .collection('favoritos')
        .doc(userId)
        .collection('userFavoritos')
        .doc(receitaId)
        .delete();
  }

  // Obter stream de favoritos do usuário
  Stream<QuerySnapshot> getFavoritosStream() {
    if (userId == null) return Stream.empty();

    return _firestore
        .collection('favoritos')
        .doc(userId)
        .collection('userFavoritos')
        .orderBy('adicionadoEm', descending: true)
        .snapshots();
  }
}
```

## 4. Sugestão de Organização no Flutter

Para manter seu código limpo, crie uma pasta `services` ou `api` dentro de `lib`:

```
lib/
  ├── models/
  │   ├── ingrediente.dart
  │   └── receita.dart
  ├── screens/
  │   ├── auth/
  │   └── ...
  ├── services/
  │   ├── auth_service.dart
  │   └── firestore_service.dart
  └── main.dart
```

Use um provedor de estado como o `Provider` ou `Riverpod` para acessar as instâncias de `AuthService` e `FirestoreService` em toda a sua árvore de widgets.

Isso deve lhe dar um excelente ponto de partida para a integração!
