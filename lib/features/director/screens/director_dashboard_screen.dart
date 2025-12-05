import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Imports absolutos
import 'package:biblio/features/auth/providers/auth_provider.dart';
import 'package:biblio/features/director/providers/director_provider.dart';

// Pantallas del módulo Director
import 'package:biblio/features/dashboard/screens/resumen_stats_screen.dart';
import 'package:biblio/features/director/screens/reportes_director_screen.dart';
import 'package:biblio/features/alumnos/screens/gestion_alumnos_screen.dart';
import 'package:biblio/features/director/screens/gestion_usuarios_screen.dart';
import 'package:biblio/features/dashboard/screens/inventario_screen.dart';
import 'package:biblio/features/director/screens/mantenimiento_screen.dart';

class DirectorDashboardScreen extends StatefulWidget {
  const DirectorDashboardScreen({super.key});

  @override
  State<DirectorDashboardScreen> createState() => _DirectorDashboardScreenState();
}

class _DirectorDashboardScreenState extends State<DirectorDashboardScreen> {
  int _selectedIndex = 0;
  bool _isSyncing = false; // Estado local para la animación del botón

  final List<Widget> _vistas = [
    const ResumenStatsScreen(),     // 0: Resumen General
    const ReportesDirectorScreen(), // 1: Reportes CSV
    const GestionAlumnosScreen(),   // 2: Alumnos
    const GestionUsuariosScreen(),  // 3: Usuarios (Staff)
    const InventarioScreen(),       // 4: Inventario (Solo lectura)
    const MantenimientoScreen(),    // 5: Zona de Peligro
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final dorado = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: Row(
        children: [
          // --- BARRA LATERAL (SIDEBAR) ---
          Container(
            width: 250,
            color: const Color(0xFF1E1E1E),
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Logo / Título
                const Icon(Icons.security, size: 50, color: Colors.white),
                const SizedBox(height: 10),
                const Text("PANEL DIRECTOR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 40),

                // Menú
                _MenuButton(icon: Icons.dashboard, label: "Resumen", isActive: _selectedIndex == 0, onTap: () => setState(() => _selectedIndex = 0)),
                _MenuButton(icon: Icons.bar_chart, label: "Reportes", isActive: _selectedIndex == 1, onTap: () => setState(() => _selectedIndex = 1)),
                _MenuButton(icon: Icons.school, label: "Alumnos", isActive: _selectedIndex == 2, onTap: () => setState(() => _selectedIndex = 2)),
                _MenuButton(icon: Icons.people, label: "Usuarios Staff", isActive: _selectedIndex == 3, onTap: () => setState(() => _selectedIndex = 3)),
                _MenuButton(icon: Icons.inventory_2, label: "Ver Inventario", isActive: _selectedIndex == 4, onTap: () => setState(() => _selectedIndex = 4)),
                
                const Spacer(),
                
                // Zona de Peligro
                _MenuButton(icon: Icons.warning_amber_rounded, label: "Mantenimiento", isActive: _selectedIndex == 5, onTap: () => setState(() => _selectedIndex = 5)),
                
                const SizedBox(height: 20),
                
                // Cerrar Sesión
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    onPressed: () => authProvider.logout(), 
                    icon: const Icon(Icons.logout, color: Colors.black),
                    label: const Text("Cerrar Sesión"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: dorado,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 50)
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          
          // --- CONTENIDO PRINCIPAL ---
          Expanded(
            child: Column(
              children: [
                // HEADER SUPERIOR
                Container(
                  height: 60,
                  color: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // --- BOTÓN DE ACTUALIZAR NUBE ---
                      IconButton(
                        tooltip: "Forzar actualización desde la nube",
                        icon: _isSyncing 
                          ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: dorado, strokeWidth: 2))
                          : const Icon(Icons.cloud_download_outlined, color: Colors.white),
                        onPressed: _isSyncing ? null : () async {
                          final directorProvider = context.read<DirectorProvider>();
                          final messenger = ScaffoldMessenger.of(context);
                          setState(() => _isSyncing = true);
                          await directorProvider.forzarSincronizacionManual();
                          if (!mounted) return;
                          setState(() => _isSyncing = false);
                          messenger.showSnackBar(
                            SnackBar(
                              content: const Text("Datos actualizados desde la nube correctamente"),
                              backgroundColor: Colors.green[800],
                              )
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                      const Chip(
                        label: Text("Modo Director", style: TextStyle(color: Colors.white)),
                        backgroundColor: Color(0xFF333333),
                        avatar: Icon(Icons.admin_panel_settings, color: Colors.greenAccent, size: 18),
                      ),
                    ],
                  ),
                ),

                // VISTA SELECCIONADA
                Expanded(
                  child: Container(
                    color: const Color(0xFF121212), // Fondo oscuro cuerpo
                    child: _vistas[_selectedIndex],
                  ),
                ),
              ],
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