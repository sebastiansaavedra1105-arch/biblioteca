import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Imports de Widgets y Pantallas del Dashboard
import '../widgets/admin_navbar.dart';
import 'resumen_stats_screen.dart';
import 'agregar_libro_screen.dart';
import 'inventario_screen.dart'; 

// Imports de otros módulos
import '../providers/libros_provider.dart';
import '../../prestamos/screens/nuevo_prestamo_screen.dart';
import '../../prestamos/screens/registrar_devolucion_screen.dart';
import '../../auth/providers/auth_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  // Títulos dinámicos según la pestaña seleccionada
  final List<String> _titulos = [
    'PANEL ADMINISTRATIVO',
    'REGISTRAR PRÉSTAMO', 
    'DEVOLUCIONES PENDIENTES',
    'AGREGAR NUEVO LIBRO',
    'INVENTARIO COMPLETO'
  ];

  @override
  void initState() {
    super.initState();
    // Carga inicial al abrir la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LibrosProvider>().cargarEstadisticas();
    });
  }

  // 🔥 LÓGICA DE NAVEGACIÓN MEJORADA
  void _onNavTap(int index) {
    setState(() => _selectedIndex = index);
    
    // TRUCO: Si vas a "Resumen" (0) o "Inventario" (4), forzamos la recarga
    // para que los datos importados o cambiados se reflejen al instante.
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
    // Lista de pantallas (Orden debe coincidir con el Navbar)
    final List<Widget> vistas = [
      const ResumenStatsScreen(),        // Índice 0
      const NuevoPrestamoScreen(),       // Índice 1
      const RegistrarDevolucionScreen(), // Índice 2
      const AgregarLibroScreen(),        // Índice 3
      const InventarioScreen(),          // Índice 4
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titulos[_selectedIndex]),
        actions: [
          // Botón de refresco manual (Carga Todo)
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Actualizar datos",
            onPressed: () {
               context.read<LibrosProvider>().cargarTodo();
            },
          ),
          // Menú de usuario / Cerrar sesión
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
      
      // IndexedStack mantiene vivo el estado de los formularios (no borra lo que escribes al cambiar pestaña)
      body: IndexedStack(
        index: _selectedIndex,
        children: vistas,
      ),
      
      bottomNavigationBar: AdminNavbar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap, // Usamos nuestra función mejorada
      ),
    );
  }
}