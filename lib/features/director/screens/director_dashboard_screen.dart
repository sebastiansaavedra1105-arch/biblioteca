import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Imports absolutos
import 'package:biblio/features/auth/providers/auth_provider.dart';
import 'package:biblio/features/director/providers/director_provider.dart';
import 'package:biblio/core/theme/theme_provider.dart'; 
import 'package:biblio/features/catalogo_publico/screens/catalogo_screen.dart'; 

// PANTALLAS HIJAS
import 'package:biblio/features/director/screens/director_resumen_screen.dart';
import 'package:biblio/features/director/screens/reportes_director_screen.dart';
import 'package:biblio/features/director/screens/gestion_usuarios_screen.dart';
import 'package:biblio/features/director/screens/mantenimiento_screen.dart';
import 'package:biblio/features/director/screens/director_alumnos_screen.dart';
import 'package:biblio/features/director/screens/director_inventario_screen.dart';

class DirectorDashboardScreen extends StatefulWidget {
  const DirectorDashboardScreen({super.key});

  @override
  State<DirectorDashboardScreen> createState() => _DirectorDashboardScreenState();
}

class _DirectorDashboardScreenState extends State<DirectorDashboardScreen> {
  int _selectedIndex = 0;
  bool _isSidebarOpen = true; 

  final List<String> _titulos = [
    "PANEL DIRECTIVO",
    "MÉTRICAS Y REPORTES",
    "DIRECTORIO DE ALUMNOS",
    "GESTIÓN DE PERSONAL",
    "AUDITORÍA DE INVENTARIO",
    "MANTENIMIENTO DEL SISTEMA"
  ];

  late List<Widget> _vistas;

  @override
  void initState() {
    super.initState();
    _vistas = [
      DirectorResumenScreen(onNavigate: (i) => setState(() => _selectedIndex = i)), // 0
      const ReportesDirectorScreen(),     // 1
      const DirectorAlumnosScreen(),      // 2
      const GestionUsuariosScreen(),      // 3
      const DirectorInventarioScreen(),   // 4
      const MantenimientoScreen(),        // 5
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DirectorProvider>().cargarReportes(); 
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    final double sidebarWidth = _isSidebarOpen ? 260 : 70;

    return Scaffold(
      body: Row(
        children: [
          // --- SIDEBAR ---
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: sidebarWidth,
            decoration: BoxDecoration(
              color: colorScheme.surface, 
              border: Border(right: BorderSide(color: colorScheme.onSurface.withOpacity(0.1))),
            ),
            child: Column(
              children: [
                // LOGO DEL COLEGIO EN EL SIDEBAR
                Container(
                  height: 70, 
                  alignment: Alignment.center,
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: colorScheme.onSurface.withOpacity(0.1)))),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    child: _isSidebarOpen 
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Logo pequeño
                            const _LogoColegio(size: 35),
                            const SizedBox(width: 12),
                            Text("DIRECCIÓN", style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.primary, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                          ],
                        )
                      : const _LogoColegio(size: 35), // Solo logo si está cerrado
                  ),
                ),
                
                // Menú
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    children: [
                      _SidebarItem(icon: Icons.dashboard, label: "Resumen", index: 0, selectedIndex: _selectedIndex, isOpen: _isSidebarOpen, onTap: (i) => setState(() => _selectedIndex = i)),
                      _SidebarItem(icon: Icons.analytics, label: "Reportes", index: 1, selectedIndex: _selectedIndex, isOpen: _isSidebarOpen, onTap: (i) => setState(() => _selectedIndex = i)),
                      _SidebarItem(icon: Icons.school, label: "Alumnos", index: 2, selectedIndex: _selectedIndex, isOpen: _isSidebarOpen, onTap: (i) => setState(() => _selectedIndex = i)),
                      _SidebarItem(icon: Icons.manage_accounts, label: "Personal", index: 3, selectedIndex: _selectedIndex, isOpen: _isSidebarOpen, onTap: (i) => setState(() => _selectedIndex = i)),
                      _SidebarItem(icon: Icons.inventory_2, label: "Inventario", index: 4, selectedIndex: _selectedIndex, isOpen: _isSidebarOpen, onTap: (i) => setState(() => _selectedIndex = i)),
                      if (_isSidebarOpen) Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), child: Divider(color: colorScheme.onSurface.withOpacity(0.1))),
                      _SidebarItem(icon: Icons.build, label: "Mantenimiento", index: 5, selectedIndex: _selectedIndex, isOpen: _isSidebarOpen, onTap: (i) => setState(() => _selectedIndex = i)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- CONTENIDO ---
          Expanded(
            child: Column(
              children: [
                // HEADER PRINCIPAL
                Container(
                  height: 70, 
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    border: Border(bottom: BorderSide(color: colorScheme.onSurface.withOpacity(0.1))),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => setState(() => _isSidebarOpen = !_isSidebarOpen),
                        icon: Icon(_isSidebarOpen ? Icons.menu_open : Icons.menu),
                        color: colorScheme.onSurface,
                      ),
                      const SizedBox(width: 20),
                      
                      Text(
                        _titulos[_selectedIndex],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                          letterSpacing: 1.0,
                        ),
                      ),

                      const Spacer(),

                      IconButton(
                        onPressed: () => themeProvider.toggleTheme(!themeProvider.isDarkMode),
                        icon: Icon(themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode),
                        color: themeProvider.isDarkMode ? Colors.amber : colorScheme.onSurface.withOpacity(0.6),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        onPressed: _cerrarSesion,
                        icon: Icon(Icons.logout, color: colorScheme.error),
                        tooltip: "Cerrar Sesión",
                      ),
                    ],
                  ),
                ),

                // CUERPO
                Expanded(
                  child: Container(
                    color: theme.scaffoldBackgroundColor, 
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

// --- WIDGET LOGO COLEGIO ---
class _LogoColegio extends StatelessWidget {
  final double size;
  const _LogoColegio({required this.size});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(2), // Borde interno
      decoration: BoxDecoration(
        color: Colors.white, // Fondo blanco para que el logo resalte si es PNG transparente
        shape: BoxShape.circle,
        border: Border.all(color: colorScheme.primary, width: 2), // Aro dorado
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/logo_colegio.png', // Ruta del logo
          height: size,
          width: size,
          fit: BoxFit.contain,
          errorBuilder: (_,__,___) => Icon(Icons.security, size: size * 0.7, color: colorScheme.primary), // Fallback
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon; final String label; final int index; final int selectedIndex; final bool isOpen; final Function(int) onTap;
  const _SidebarItem({required this.icon, required this.label, required this.index, required this.selectedIndex, required this.isOpen, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = index == selectedIndex;
    return InkWell(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        clipBehavior: Clip.hardEdge,
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: isOpen ? 16 : 0),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected ? Border.all(color: colorScheme.primary.withOpacity(0.5)) : null,
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: Row(
            mainAxisAlignment: isOpen ? MainAxisAlignment.start : MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 30, child: Icon(icon, color: isSelected ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.6), size: 22)),
              if (isOpen) ...[const SizedBox(width: 15), Text(label, style: TextStyle(color: isSelected ? colorScheme.onSurface : colorScheme.onSurface.withOpacity(0.7), fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 14))],
            ],
          ),
        ),
      ),
    );
  }
}