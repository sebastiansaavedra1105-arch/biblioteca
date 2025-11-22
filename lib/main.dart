import 'package:flutter/material.dart';
import 'features/catalogo_publico/screens/catalogo_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Biblioteca Premium',
      debugShowCheckedModeBanner: false,
      
      // TEMA PREMIUM (NEGRO + DORADO)
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark, // Base oscura automática
        
        // 1. Fondo Negro Puro
        scaffoldBackgroundColor: const Color(0xFF000000), 
        
        // 2. Definición de colores
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFD4AF37),    // Dorado Metálico (Metallic Gold)
          secondary: Color(0xFFC0C0C0),  // Plateado (Silver) para elementos secundarios
          surface: Color(0xFF121212),    // Un gris muy oscuro para tarjetas (no negro total para dar profundidad)
          onPrimary: Colors.black,       // Texto negro sobre botones dorados
        ),

        // 3. Estilo de Tarjetas (Cards)
        cardTheme: CardTheme(
          color: const Color(0xFF1A1A1A), // Gris oscuro elegante
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF333333), width: 1), // Borde sutil
          ),
        ),

        // 4. Estilo de Textos (Appbar y Títulos)
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          centerTitle: true,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Color(0xFFD4AF37), // Título dorado
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2, // Espaciado premium
          ),
        ),
      ),
      
      // Tu pantalla inicial (por ahora dejamos el Dashboard, luego pondremos la vista pública)
      home: const CatalogoScreen(),
    );
  }
}