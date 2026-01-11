import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Providers
import 'features/dashboard/providers/libros_provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/director/providers/director_provider.dart';
import 'features/catalogo_publico/providers/catalogo_provider.dart';
import 'features/alumnos/providers/alumnos_provider.dart';
import 'features/auth/providers/splash_provider.dart';
import 'core/theme/theme_provider.dart'; // <--- IMPORTANTE: Provider del tema

// Configuración de Estilos
import 'core/theme/app_theme.dart'; // <--- IMPORTANTE: Tus estilos

// Pantalla
import 'features/auth/screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Config Supabase (Simplificado para el ejemplo)
  String supabaseUrl = 'https://wapntjydoxzhyixhnwbk.supabase.co';
  String supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndhcG50anlkb3h6aHlpeGhud2JrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNDQyMTMsImV4cCI6MjA3OTkyMDIxM30.vJsRHsSJZVHiphR9oHg6JdnOoHwMqcW5de53KtdLX7U';
  
  try {
    await dotenv.load(fileName: ".env");
    supabaseUrl = dotenv.env['SUPABASE_URL'] ?? supabaseUrl;
    supabaseKey = dotenv.env['SUPABASE_KEY'] ?? supabaseKey;
  } catch (_) {}

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
        ChangeNotifierProvider(create: (_) => SplashProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()), 
      ],
      child: const MainApp(),
    );
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Escuchamos el estado del tema
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Biblioteca Jiménez Pimentel',
      
      // --- CONFIGURACIÓN DE TEMAS ---
      theme: AppTheme.lightTheme,       // Tu tema claro (Crema/Dorado)
      darkTheme: AppTheme.darkTheme,    // Tu tema oscuro (Negro/Dorado)
      themeMode: themeProvider.themeMode, // Controlado por el switch
      
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es', '')],
      home: const SplashScreen(),
    );
  }
}