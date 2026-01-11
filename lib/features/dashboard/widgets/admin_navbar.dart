import 'package:flutter/material.dart';

class AdminNavbar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AdminNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Obtenemos los colores del tema actual
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface, // Fondo dinámico (Crema o Negro)
        border: Border(
          top: BorderSide(
            color: colorScheme.onSurface.withOpacity(0.1), // Línea sutil separadora
            width: 0.5
          )
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Necesario para 6 botones
        backgroundColor: colorScheme.surface, // Se adapta al tema
        
        // COLORES
        selectedItemColor: colorScheme.primary, // Dorado institucional
        unselectedItemColor: colorScheme.onSurface.withOpacity(0.6), // Gris/Azul según tema
        
        selectedFontSize: 11,
        unselectedFontSize: 10,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        
        currentIndex: currentIndex,
        onTap: onTap,
        
        items: const <BottomNavigationBarItem>[
          // Índice 0
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Resumen',
          ),
          // Índice 1
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.add_circle),
            label: 'Prestar',
          ),
          // Índice 2
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_return_outlined),
            activeIcon: Icon(Icons.assignment_return),
            label: 'Devolver',
          ),
          // Índice 3
          BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined),
            activeIcon: Icon(Icons.school),
            label: 'Alumnos',
          ),
          // Índice 4
          BottomNavigationBarItem(
            icon: Icon(Icons.library_add_outlined),
            activeIcon: Icon(Icons.library_add),
            label: 'Libro +',
          ),
          // Índice 5
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Inventario',
          ),
        ],
      ),
    );
  }
}