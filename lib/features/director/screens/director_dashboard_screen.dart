import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Imports absolutos
import 'package:biblio/features/auth/providers/auth_provider.dart';
import 'package:biblio/features/dashboard/providers/libros_provider.dart';
import 'package:biblio/features/dashboard/screens/inventario_screen.dart';
import 'package:biblio/features/dashboard/screens/resumen_stats_screen.dart';

// Pantallas del módulo Director
import 'package:biblio/features/director/screens/gestion_usuarios_screen.dart';
import 'package:biblio/features/director/screens/reportes_director_screen.dart';
import 'package:biblio/features/director/screens/mantenimiento_screen.dart';
import 'package:biblio/features/alumnos/screens/gestion_alumnos_screen.dart';

class DirectorDashboardScreen extends StatefulWidget {
  const DirectorDashboardScreen({super.key});

  @override
  State<DirectorDashboardScreen> createState() => _DirectorDashboardScreenState();
}

class _DirectorDashboardScreenState extends State<DirectorDashboardScreen> {
  int _selectedIndex = 0;
  bool _isSyncing = false; 

  final List<Widget> _vistas = [
    const ResumenStatsScreen(),     // 0: Resumen General
    const ReportesDirectorScreen(), // 1: Reportes CSV
    const GestionAlumnosScreen(),   // 2: ALUMNOS (NUEVO)
    const GestionUsuariosScreen(),  // 3: Usuarios (Staff)
    const InventarioScreen(),       // 4: Inventario
    const MantenimientoScreen(),    // 5: Mantenimiento
  ];

  Future<void> _descargarDeNube() async {
    setState(() => _isSyncing = true);
    await context.read<LibrosProvider>().sincronizarDesdeNube();
    
    if (mounted) {
      setState(() => _isSyncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Datos descargados de la nube correctamente"),
          backgroundColor: Colors.green,
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dorado = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text("PANEL DE DIRECCIÓN"),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.red),
            tooltip: "Cerrar Sesión",
            onPressed: () => context.read<AuthProvider>().logout(),
          )
        ],
      ),
      body: Row(
        children: [
          // --- SIDEBAR ---
          Container(
            width: 250,
            color: const Color(0xFF121212),
            child: Column(
              children: [
                const SizedBox(height: 30),
                Icon(Icons.admin_panel_settings, size: 60, color: dorado),
                const SizedBox(height: 10),
                Text("DIRECTOR", style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                const SizedBox(height: 40),
                
                _MenuButton(
                  icon: Icons.dashboard, 
                  label: "Resumen", 
                  isActive: _selectedIndex == 0,
                  onTap: () => setState(() => _selectedIndex = 0),
                ),
                _MenuButton(
                  icon: Icons.analytics, 
                  label: "Reportes", 
                  isActive: _selectedIndex == 1,
                  onTap: () => setState(() => _selectedIndex = 1),
                ),
                
                // BOTÓN DE ALUMNOS
                _MenuButton(
                  icon: Icons.school, 
                  label: "Alumnos", 
                  isActive: _selectedIndex == 2,
                  onTap: () => setState(() => _selectedIndex = 2),
                ),

                _MenuButton(
                  icon: Icons.group, 
                  label: "Usuarios (Staff)", 
                  isActive: _selectedIndex == 3,
                  onTap: () => setState(() => _selectedIndex = 3),
                ),
                _MenuButton(
                  icon: Icons.list_alt, 
                  label: "Inventario", 
                  isActive: _selectedIndex == 4,
                  onTap: () => setState(() => _selectedIndex = 4),
                ),
                _MenuButton(
                  icon: Icons.build_circle, 
                  label: "Mantenimiento", 
                  isActive: _selectedIndex == 5,
                  onTap: () => setState(() => _selectedIndex = 5),
                ),

                const Spacer(), 

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blueGrey[900],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blueGrey)
                    ),
                    child: ListTile(
                      title: const Text("Sincronizar", style: TextStyle(color: Colors.white, fontSize: 12)),
                      subtitle: const Text("Descargar Nube", style: TextStyle(color: Colors.grey, fontSize: 10)),
                      trailing: _isSyncing 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.cloud_download, color: Colors.blueAccent),
                      onTap: _isSyncing ? null : _descargarDeNube,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          
          // --- CONTENIDO ---
          Expanded(
            child: Container(
              color: Colors.black,
              child: _vistas[_selectedIndex],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _MenuButton({required this.icon, required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dorado = Theme.of(context).colorScheme.primary;
    return Material(
      color: isActive ? dorado.withOpacity(0.1) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: isActive ? dorado : Colors.transparent, width: 4))
          ),
          child: Row(
            children: [
              Icon(icon, color: isActive ? dorado : Colors.grey, size: 22),
              const SizedBox(width: 15),
              Text(label, style: TextStyle(color: isActive ? Colors.white : Colors.grey, fontWeight: isActive ? FontWeight.bold : FontWeight.normal, fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }
}