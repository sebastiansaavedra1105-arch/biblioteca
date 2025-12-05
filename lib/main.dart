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

// Servicios
import 'package:biblio/core/services/sync_service.dart';

// Pantallas
import 'package:biblio/features/catalogo_publico/screens/catalogo_screen.dart';
import 'package:biblio/features/dashboard/screens/dashboard_screen.dart';
import 'package:biblio/features/director/screens/director_dashboard_screen.dart'; 

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- CONFIGURACIÓN SUPABASE ---
String supabaseUrl = 'https://wapntjydoxzhyixhnwbk.supabase.co';
  String supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndhcG50anlkb3h6aHlpeGhud2JrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNDQyMTMsImV4cCI6MjA3OTkyMDIxM30.vJsRHsSJZVHiphR9oHg6JdnOoHwMqcW5de53KtdLX7U';

  try {
    await dotenv.load(fileName: ".env");
    if (dotenv.env['SUPABASE_URL'] != null && dotenv.env['SUPABASE_KEY'] != null) {
      supabaseUrl = dotenv.env['SUPABASE_URL']!;
      supabaseKey = dotenv.env['SUPABASE_KEY']!;
    }
  } catch (e) {
    debugPrint("⚠️ No se encontró .env, usando credenciales por defecto.");
  }

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);

  runApp(const AppState());
}

class AppState extends StatelessWidget {
  const AppState({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LibrosProvider()), 
        ChangeNotifierProvider(create: (_) => DirectorProvider()),
        ChangeNotifierProvider(create: (_) => CatalogoProvider()),
        ChangeNotifierProvider(create: (_) => AlumnosProvider()),
      ],
      child: const MainApp(),
    );
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Biblioteca System',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFD4AF37), // Dorado
          secondary: Color(0xFF1E1E1E),
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
      // AQUÍ EL CAMBIO CLAVE: Vamos primero al cargador
      home: const InicializadorSistema(),
    );
  }
}

// --- PANTALLA DE CARGA / SPLASH SCREEN ---
class InicializadorSistema extends StatefulWidget {
  const InicializadorSistema({super.key});

  @override
  State<InicializadorSistema> createState() => _InicializadorSistemaState();
}

class _InicializadorSistemaState extends State<InicializadorSistema> {
  String _mensaje = "Iniciando sistema...";

  @override
  void initState() {
    super.initState();
    _ejecutarCargaInicial();
  }

  Future<void> _ejecutarCargaInicial() async {
    // Mensaje inicial
    if (mounted) setState(() => _mensaje = "Verificando sincronización...");
    
    final syncService = SyncService(); 
    // espera larga (el async gap)
    await syncService.sincronizacionInicial();

    if (!mounted) return; 

    setState(() => _mensaje = "Preparando biblioteca...");
    
    // Ejecutamos la primera carga
    await context.read<LibrosProvider>().cargarTodo();

    if (!mounted) return; 

    await context.read<AlumnosProvider>().cargarAlumnos();

    if (!mounted) return;

    // 3. Navegar
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const AuthWrapper(),
        transitionDuration: const Duration(milliseconds: 1000),
        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Dorado
            const Icon(Icons.auto_stories, size: 80, color: Color(0xFFD4AF37)), 
            const SizedBox(height: 40),
            
            // Barra de Progreso
            const SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                backgroundColor: Color(0xFF333333),
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 20),
            
            // Texto de estado
            Text(
              _mensaje,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 14,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- TU AUTH WRAPPER ORIGINAL ---
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