import 'package:flutter/material.dart';

import 'api_client.dart';
import 'config.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Recupera la sesión guardada antes de arrancar la app.
  await ApiClient.instance.init();
  runApp(const CineFlixAdminApp());
}

/// Aplicación de administración de CineFlix.
class CineFlixAdminApp extends StatelessWidget {
  const CineFlixAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CineFlix Admin',
      debugShowCheckedModeBanner: false,
      theme: buildNetflixTheme(),
      // Si ya hay token guardado vamos directos al panel.
      home: ApiClient.instance.isLoggedIn
          ? const HomeScreen()
          : const LoginScreen(),
    );
  }
}

/// Tema oscuro con la estética de Netflix.
ThemeData buildNetflixTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: kDarkBackground,
    primaryColor: kNetflixRed,
    colorScheme: base.colorScheme.copyWith(
      primary: kNetflixRed,
      secondary: kNetflixRed,
      surface: kCardColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: kDarkBackground,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardColor: kCardColor,
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: kCardColor,
      selectedItemColor: kNetflixRed,
      unselectedItemColor: Colors.white60,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kCardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kNetflixRed,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: kNetflixRed,
      foregroundColor: Colors.white,
    ),
  );
}
