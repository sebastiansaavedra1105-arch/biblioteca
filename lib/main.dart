import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Providers
import 'features/dashboard/providers/libros_provider.dart';
import 'features/auth/providers/auth_provider.dart';

// Pantallas
import 'features/catalogo_publico/screens/catalogo_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LibrosProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'Biblioteca Premium',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF000000),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFD4AF37),
            surface: Color(0xFF121212),
            onPrimary: Colors.black,
          ),
          cardTheme: CardTheme(
            color: const Color(0xFF1A1A1A),
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFF333333), width: 1),
            ),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.black,
            centerTitle: true,
            elevation: 0,
            titleTextStyle: TextStyle(color: Color(0xFFD4AF37), fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        // Controlador de Flujo
        home: const AuthWrapper(),
      ),
    );
  }
}

// --- CONTROLADOR DE FLUJO (Responde a tu diagrama) ---
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Escuchamos al AuthProvider
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // ¿Está logueado?
        if (authProvider.estaAutenticado) {
          return const DashboardScreen(); // Flecha "SI" del diagrama
        } else {
          return const CatalogoScreen();  // Flecha "NO" del diagrama
        }
      },
    );
  }
}