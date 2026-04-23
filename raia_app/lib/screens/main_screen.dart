
import 'package:flutter/material.dart';

// widget
import '../widgets/bottom_nav_bar.dart';

// screens
import 'home/home_screen.dart';
import 'perfil/perfil_screen.dart';
import 'estoque/add_ingredientes_screen.dart';
import 'estoque/estoque_screen.dart';
import 'receitas/receitas_screen.dart';


class MainScreen extends StatefulWidget {
  @override
  State<MainScreen> createState() => _MainScreenState();
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
