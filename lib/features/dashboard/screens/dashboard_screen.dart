import 'package:biblio/features/dashboard/screens/inventario_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/admin_navbar.dart';
import 'resumen_stats_screen.dart';
import 'agregar_libro_screen.dart';

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

  // Títulos según la pestaña
  final List<String> _titulos = [
    'PANEL ADMINISTRATIVO',
    'REGISTRAR PRÉSTAMO', // Ahora tiene su propio título aquí
    'DEVOLUCIONES PENDIENTES',
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
    // Ya no hay Navigator.push, todo es fluido dentro del mismo dashboard
    setState(() => _selectedIndex = index);
  }

  void _cerrarSesion() {
    context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    // Lista de pantallas integradas
    final List<Widget> vistas = [
      const ResumenStatsScreen(),        // 0
      const NuevoPrestamoScreen(),       // 1
      const RegistrarDevolucionScreen(), // 2
      const AgregarLibroScreen(),        // 3
      const InventarioScreen(),          // 4
      const Center(child: Text('Inventario (En construcción)', style: TextStyle(color: Colors.white))), // 4
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titulos[_selectedIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<LibrosProvider>().cargarEstadisticas(),
          ),
          PopupMenuButton<String>(
            onSelected: (v) => v == 'logout' ? _cerrarSesion() : null,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'logout', child: Row(children: [Icon(Icons.exit_to_app, color: Colors.red), SizedBox(width: 10), Text('Cerrar Sesión')])),
            ],
          ),
        ],
      ),
      // Mantiene el estado de los formularios al cambiar de pestaña
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