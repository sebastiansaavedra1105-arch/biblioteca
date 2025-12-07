import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Imports de Widgets y Pantallas Locales
import 'package:biblio/features/dashboard/widgets/admin_navbar.dart';
import 'package:biblio/features/dashboard/screens/resumen_stats_screen.dart';
import 'package:biblio/features/dashboard/screens/inventario_screen.dart';
import 'package:biblio/features/dashboard/features/gestion_libro/screens/agregar_libro_screen.dart';
import 'package:biblio/features/alumnos/screens/gestion_alumnos_screen.dart';
import 'package:biblio/features/catalogo_publico/screens/catalogo_screen.dart';

// Imports de otros módulos
import 'package:biblio/features/dashboard/providers/libros_provider.dart';
import 'package:biblio/features/prestamos/screens/nuevo_prestamo_screen.dart';
import 'package:biblio/features/prestamos/screens/registrar_devolucion_screen.dart';
import 'package:biblio/features/auth/providers/auth_provider.dart';

// IMPORT IMPORTANTE: El cerebro del formulario
import 'package:biblio/features/dashboard/features/gestion_libro/providers/form_libro_provider.dart';

// IMPORT PARA EL TEMA
import 'package:biblio/core/theme/theme_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<String> _titulos = [
    'PANEL ADMINISTRATIVO',
    'REGISTRAR PRÉSTAMO', 
    'DEVOLUCIONES PENDIENTES',
    'GESTIÓN DE ALUMNOS',
    'AGREGAR NUEVO LIBRO',
    'INVENTARIO GENERAL'
  ];

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

void _cerrarSesion() {
    context.read<AuthProvider>().logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const CatalogoScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos info del tema para el botón de switch
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final colorScheme = Theme.of(context).colorScheme;

    // Lista de Pantallas
    final List<Widget> vistas = [
      const ResumenStatsScreen(),        // 0
      const NuevoPrestamoScreen(),       // 1
      const RegistrarDevolucionScreen(), // 2
      const GestionAlumnosScreen(),      // 3
      
      // 4. Agregar Libro (Con su provider inyectado aquí)
      ChangeNotifierProvider(
        create: (_) => FormLibroProvider(),
        child: const AgregarLibroScreen(),
      ), 
      
      const InventarioScreen(),          // 5
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titulos[_selectedIndex],
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          // 1. SWITCH DE TEMA (NUEVO)
          IconButton(
            onPressed: () => themeProvider.toggleTheme(!isDark),
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              color: isDark ? Colors.amber : Colors.white, // Blanco sobre dorado en Light, Amber en Dark
            ),
            tooltip: 'Cambiar Tema',
          ),

          // 2. BOTÓN REFRESCAR
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Actualizar datos",
            onPressed: () {
               context.read<LibrosProvider>().cargarTodo();
               ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(
                   content: const Text('Actualizando datos...'),
                   backgroundColor: colorScheme.secondary,
                   duration: const Duration(seconds: 1),
                 )
               );
            },
          ),

          // 3. MENÚ LOGOUT
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle),
            onSelected: (v) => v == 'logout' ? _cerrarSesion() : null,
            color: colorScheme.surface, // Fondo del menú dinámico
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'logout', 
                child: Row(
                  children: [
                    Icon(Icons.exit_to_app, color: colorScheme.error), 
                    const SizedBox(width: 10), 
                    Text(
                      'Cerrar Sesión', 
                      style: TextStyle(color: colorScheme.error)
                    )
                  ]
                )
              ),
            ],
          ),
          const SizedBox(width: 10),
        ],
      ),
      
      // Cuerpo con IndexedStack para mantener el estado de las pantallas
      body: IndexedStack(
        index: _selectedIndex,
        children: vistas,
      ),
      
      bottomNavigationBar: AdminNavbar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
      ),
    );
  }
}