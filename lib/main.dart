import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; 

// Providers
import 'package:biblio/features/dashboard/providers/libros_provider.dart';
import 'package:biblio/features/auth/providers/auth_provider.dart';
import 'package:biblio/features/director/providers/director_provider.dart';
import 'package:biblio/features/catalogo_publico/providers/catalogo_provider.dart';
import 'package:biblio/features/alumnos/providers/alumnos_provider.dart'; 

// Pantallas
import 'package:biblio/features/catalogo_publico/screens/catalogo_screen.dart';
import 'package:biblio/features/dashboard/screens/dashboard_screen.dart';
import 'package:biblio/features/director/screens/director_dashboard_screen.dart'; 

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- 1. CREDENCIALES REALES POR DEFECTO (RESPALDO) ---
  String supabaseUrl = 'https://wapntjydoxzhyixhnwbk.supabase.co';
  String supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndhcG50anlkb3h6aHlpeGhud2JrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNDQyMTMsImV4cCI6MjA3OTkyMDIxM30.vJsRHsSJZVHiphR9oHg6JdnOoHwMqcW5de53KtdLX7U';

  // --- 2. INTENTAR CARGAR DESDE .ENV ---
  try {
    await dotenv.load(fileName: ".env");
    if (dotenv.env['SUPABASE_URL'] != null && 
        dotenv.env['SUPABASE_URL']!.contains('supabase.co') && 
        !dotenv.env['SUPABASE_URL']!.contains('tu-url')) {    
      
      supabaseUrl = dotenv.env['SUPABASE_URL']!;
      supabaseKey = dotenv.env['SUPABASE_ANON_KEY']!;
    }
  } catch (e) {
    debugPrint("⚠️ No se cargó .env o tiene formato incorrecto. Usando credenciales internas.");
  }

  // --- 3. INICIALIZAR ---
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LibrosProvider()),
        ChangeNotifierProvider(create: (_) => CatalogoProvider()),
        ChangeNotifierProvider(create: (_) => DirectorProvider()),
        // 👇 AQUÍ REGISTRAMOS EL NUEVO PROVIDER DE ALUMNOS
        ChangeNotifierProvider(create: (_) => AlumnosProvider()),
      ],
      child: MaterialApp(
        title: 'Biblioteca Premium',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: Colors.black,
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
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('es', ''), 
        ],
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.estaAutenticado) {
          if (authProvider.esDirector) {
             return const DirectorDashboardScreen();
          } else {
             return const DashboardScreen();
          }
        } else {
          return const CatalogoScreen();
        }
      },
    );
  }
}