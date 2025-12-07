import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- PALETA DE COLORES "ROYAL ACADEMIC" ---
  
  // PRIMARIO: El Dorado (Identidad)
  static const Color _goldPrimary = Color(0xFFD4AF37); 
  
  // SECUNDARIO: Azul Noche (Identidad - Reemplaza al negro en modo claro)
  static const Color _navyBlue = Color(0xFF1C2331); 
  
  // TERCIARIO: Rojo Vino (Identidad - Para errores o botones de peligro)
  static const Color _burgundyRed = Color(0xFF8B0000); 

  // FONDOS MODO CLARO (Anti-Quema-Retinas)
  static const Color _lightBackground = Color(0xFFF4F1EA); // Color "Pergamino/Hueso"
  static const Color _lightSurface = Color(0xFFFFFFFF);    // Tarjetas blancas
  
  // FONDOS MODO OSCURO
  static const Color _darkBackground = Color(0xFF121212);
  static const Color _darkSurface = Color(0xFF1E1E1E);

  // --- TEMA CLARO ---
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // CONFIGURACIÓN DE COLORES
      colorScheme: const ColorScheme.light(
        primary: _goldPrimary,
        onPrimary: Colors.white, 
        secondary: _navyBlue,     
        onSecondary: Colors.white,
        surface: _lightSurface,
        // Eliminado background (deprecated)
        error: _burgundyRed,      
        onSurface: _navyBlue,     
      ),

      scaffoldBackgroundColor: _lightBackground, // Definimos el fondo aquí

      // CONFIGURACIÓN DE TEXTOS (Google Fonts)
      textTheme: TextTheme(
        // Títulos Grandes 
        displayLarge: GoogleFonts.playfairDisplay(fontSize: 32, fontWeight: FontWeight.bold, color: _navyBlue),
        displayMedium: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.bold, color: _navyBlue),
        displaySmall: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.bold, color: _navyBlue),
        headlineMedium: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.bold, color: _navyBlue),
        
        // Texto Normal 
        bodyLarge: GoogleFonts.lato(fontSize: 16, color: _navyBlue),
        bodyMedium: GoogleFonts.lato(fontSize: 14, color: _navyBlue.withOpacity(0.8)),
        labelLarge: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white), 
      ),

      // TARJETAS
      cardTheme: CardTheme(
        color: _lightSurface,
        elevation: 2,
        shadowColor: _navyBlue.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // APP BAR (Sin const porque usa GoogleFonts)
      appBarTheme: AppBarTheme(
        backgroundColor: _goldPrimary,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 22, 
          fontWeight: FontWeight.bold, 
          color: Colors.white
        ),
      ),

      // INPUTS (Sin const en los bordes para evitar conflictos)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _goldPrimary, width: 2)),
      ),
    );
  }

  // --- TEMA OSCURO ---
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      colorScheme: const ColorScheme.dark(
        primary: _goldPrimary,
        onPrimary: Colors.black, 
        secondary: _goldPrimary,
        surface: _darkSurface,
        // Eliminado background (deprecated)
        error: Color(0xFFCF6679), 
      ),
      
      scaffoldBackgroundColor: _darkBackground,

      textTheme: TextTheme(
        displayLarge: GoogleFonts.playfairDisplay(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
        displayMedium: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
        headlineMedium: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        
        bodyLarge: GoogleFonts.lato(fontSize: 16, color: Colors.white),
        bodyMedium: GoogleFonts.lato(fontSize: 14, color: Colors.white70),
      ),

      cardTheme: CardTheme(
        color: _darkSurface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF333333)),
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: _goldPrimary,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 22, 
          fontWeight: FontWeight.bold, 
          color: _goldPrimary
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF444444))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _goldPrimary, width: 2)),
      ),
    );
  }
}