import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/cadastro_screen.dart';

void main() {
  runApp(RiraApp());
}

class RiraApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Rira',
      theme: ThemeData(primarySwatch: Colors.green),

      // 🔥 AGORA COMEÇA PELO LOGIN
      initialRoute: '/',

      routes: {
        '/': (context) => LoginScreen(),
        '/cadastro': (context) => CadastroScreen(),
        '/main': (context) => MainScreen(),
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    HomeScreen(),
    Center(child: Text("Estoque")),
    Center(child: Text("Receitas")),
    Center(child: Text("Perfil")),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.green,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: "Estoque"),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: "Receitas"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil"),
        ],
      ),
    );
  }
}