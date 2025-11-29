import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/libros_provider.dart';
import 'resumen_stats_screen.dart'; 
import 'inventario_screen.dart';    

class DirectorDashboardScreen extends StatefulWidget {
  const DirectorDashboardScreen({super.key});

  @override
  State<DirectorDashboardScreen> createState() => _DirectorDashboardScreenState();
}

class _DirectorDashboardScreenState extends State<DirectorDashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Al entrar, el Director DEBE descargar datos de la nube (Sync Down)
    // Esto lo implementaremos en el siguiente paso, por ahora cargamos local
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LibrosProvider>().cargarEstadisticas();
    });
  }

  void _cerrarSesion() {
    context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    // Definimos las vistas del Director (Solo lectura)
    final List<Widget> vistas = [
      const ResumenStatsScreen(),         // 0: Resumen General
      const InventarioScreen(),           // 1: Ver Inventario Completo
      const Center(child: Text("Reportes Avanzados (Próximamente)")), // 2: Futuro
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('PANEL DIRECTOR'),
        backgroundColor: Colors.red.shade900, // Color distintivo de autoridad
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_download),
            tooltip: 'Descargar datos de la Encargada',
            onPressed: () async {
               // Feedback visual inmediato
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(
                   content: Text("⏳ Descargando datos de la nube..."),
                   duration: Duration(seconds: 2),
                 )
               );
               
               // Llamada real a la sincronización
               await context.read<LibrosProvider>().sincronizarDesdeNube();

               // Confirmación (si el widget sigue vivo)
               if (context.mounted) {
                 ScaffoldMessenger.of(context).hideCurrentSnackBar();
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(
                     content: Text("✅ Datos actualizados correctamente"),
                     backgroundColor: Colors.green,
                   )
                 );
               }
            },
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: 'Cerrar Sesión',
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: vistas,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        backgroundColor: Colors.black,
        selectedItemColor: Colors.redAccent, // Rojo para el director
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Resumen'),
          BottomNavigationBarItem(icon: Icon(Icons.library_books), label: 'Inventario'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Reportes'),
        ],
      ),
    );
  }
}