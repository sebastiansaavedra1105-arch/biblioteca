import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Imports de Widgets y Pantallas Locales
import 'package:biblio/features/dashboard/widgets/admin_navbar.dart';
import 'package:biblio/features/dashboard/screens/resumen_stats_screen.dart';
import 'package:biblio/features/dashboard/screens/inventario_screen.dart';
import 'package:biblio/features/dashboard/features/gestion_libro/screens/agregar_libro_screen.dart';
import 'package:biblio/features/alumnos/screens/gestion_alumnos_screen.dart';

// Imports de otros módulos
import 'package:biblio/features/dashboard/providers/libros_provider.dart';
import 'package:biblio/features/prestamos/screens/nuevo_prestamo_screen.dart';
import 'package:biblio/features/prestamos/screens/registrar_devolucion_screen.dart';
import 'package:biblio/features/auth/providers/auth_provider.dart';

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
    'INVENTARIO COMPLETO'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LibrosProvider>().cargarEstadisticas();
    });
  }

  void _onNavTap(int index) {
    setState(() => _selectedIndex = index);
    
    if (index == 0 || index == 4) {
      context.read<LibrosProvider>().cargarEstadisticas();
      context.read<LibrosProvider>().cargarLibros();
    }
  }

  void _cerrarSesion() {
    context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> vistas = [
      const ResumenStatsScreen(),        // 0
      const NuevoPrestamoScreen(),       // 1
      const RegistrarDevolucionScreen(), // 2
      const GestionAlumnosScreen(),      // 3
      const AgregarLibroScreen(),        // 4
      const InventarioScreen(),          // 5
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titulos[_selectedIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Actualizar datos",
            onPressed: () {
               context.read<LibrosProvider>().cargarTodo();
            },
          ),
          PopupMenuButton<String>(
            onSelected: (v) => v == 'logout' ? _cerrarSesion() : null,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout', 
                child: Row(
                  children: [
                    Icon(Icons.exit_to_app, color: Colors.red), 
                    SizedBox(width: 10), 
                    Text('Cerrar Sesión')
                  ]
                )
              ),
            ],
          ),
        ],
      ),
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