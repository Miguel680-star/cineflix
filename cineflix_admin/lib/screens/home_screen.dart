import 'package:flutter/material.dart';

import 'account_screen.dart';
import 'dashboard_screen.dart';
import 'movies_screen.dart';
import 'payments_screen.dart';
import 'plans_screen.dart';

/// Contenedor principal con la barra de navegación inferior.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  static const List<String> _titles = [
    'Inicio',
    'Películas',
    'Planes',
    'Pagos',
    'Cuenta',
  ];

  static const List<Widget> _screens = [
    DashboardScreen(),
    MoviesScreen(),
    PlansScreen(),
    PaymentsScreen(),
    AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index])),
      // IndexedStack conserva el estado de cada pestaña.
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.movie_outlined),
            activeIcon: Icon(Icons.movie),
            label: 'Películas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_membership_outlined),
            activeIcon: Icon(Icons.card_membership),
            label: 'Planes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payments_outlined),
            activeIcon: Icon(Icons.payments),
            label: 'Pagos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Cuenta',
          ),
        ],
      ),
    );
  }
}
