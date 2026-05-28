import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/main_screen.dart';

// widget
import 'widgets/bottom_nav_bar.dart';

// screens
import 'screens/home/home_screen.dart';

// auth
import 'screens/auth/login_screen.dart';
import 'screens/auth/cadastro_screen.dart';
import 'screens/auth/esqueci_senha_screen.dart';

// perfil
import 'screens/perfil/perfil_screen.dart';

//estoque
import 'screens/estoque/add_ingredientes_screen.dart';
import 'screens/estoque/estoque_screen.dart';

//receitas
import 'screens/receitas/receitas_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );




  runApp(RaiaApp());
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



class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  //telas da barra de navegação
  final List<Widget> _screens = [
    HomeScreen(),
    EstoqueScreen(),
    ReceitasScreen(),
    PerfilScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // MENU DE OPÇÕES
  void _mostrarOpcoes(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Adicionar Ingrediente",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              SizedBox(height: 20),

              _buildOpcao(Icons.mic, "Por voz", () {}),
              _buildOpcao(Icons.receipt, "Foto da nota", () {}),
              _buildOpcao(Icons.qr_code, "QR Code da nota", () {}),
              _buildOpcao(Icons.edit, "Manual", () {
                Navigator.pop(context); // fecha o menu
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddIngredientesScreen(),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  //BOTÃO REUTILIZÁVEL
  Widget _buildOpcao(IconData icon, String texto, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.green),
      title: Text(texto),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _screens[_selectedIndex]),

      // BOTÃO FLUTUANTE
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarOpcoes(context),
        backgroundColor: Colors.green,
        child: Icon(Icons.add),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}