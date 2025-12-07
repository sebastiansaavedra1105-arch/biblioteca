import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Providers
import '../providers/splash_provider.dart';
import '../providers/auth_provider.dart';
import '../../dashboard/providers/libros_provider.dart';
import '../../alumnos/providers/alumnos_provider.dart';

// Pantallas
import '../../dashboard/screens/dashboard_screen.dart';
import '../../director/screens/director_dashboard_screen.dart';
import '../../catalogo_publico/screens/catalogo_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // Configurar Animación del Logo
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    // Iniciar la carga al terminar el primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ejecutarCargaCompleta();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _ejecutarCargaCompleta() async {
    final splashProvider = context.read<SplashProvider>();
    
    // 1. Ejecutar lógica de sincronización (Esperamos a que el provider termine)
    await splashProvider.inicializarLogica();

    // --- PROTECCIÓN CONTRA ASYNC GAP ---
    // Si el usuario cerró la app mientras cargaba, nos detenemos aquí.
    if (!mounted) return; 

    // 2. Cargar datos en memoria (Providers de Libros y Alumnos)
    // Ahora es seguro usar 'context' porque validamos 'mounted'
    await context.read<LibrosProvider>().cargarTodo();
    
    if (!mounted) return; // Validación de seguridad nuevamente

    await context.read<AlumnosProvider>().cargarAlumnos();

    if (!mounted) return; // Última validación

    // 3. Navegación
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const AuthWrapper(),
        transitionDuration: const Duration(milliseconds: 800),
        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Escuchamos el mensaje del provider para mostrarlo en pantalla
    final mensaje = context.select<SplashProvider, String>((p) => p.mensaje);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- AQUÍ ESTÁ TU LOGO ---
            ScaleTransition(
              scale: Tween<double>(begin: 0.9, end: 1.1).animate(_animation),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD4AF37).withOpacity(0.2),
                      blurRadius: 40,
                      spreadRadius: 10,
                    )
                  ]
                ),
                // CAMBIO: Usamos Image.asset en lugar de Icon
                // Asegúrate de tener la imagen en: assets/images/logo_colegio.png
                child: Image.asset(
                  'assets/images/logo_colegio.png',
                  width: 180, 
                  height: 180,
                  fit: BoxFit.contain,
                  // Si la imagen falla o no existe aún, mostramos el icono como respaldo
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.auto_stories, size: 100, color: Color(0xFFD4AF37));
                  },
                ), 
              ),
            ),
            
            const SizedBox(height: 50),
            
            // Indicador de carga
            const SizedBox(
              width: 40, height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Mensaje de estado
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white54, 
                fontSize: 14,
                letterSpacing: 1.0
              ),
            ),
          ],
        ),
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
          return authProvider.esDirector 
              ? const DirectorDashboardScreen() 
              : const DashboardScreen();
        } else {
          return const CatalogoScreen();
        }
      },
    );
  }
}