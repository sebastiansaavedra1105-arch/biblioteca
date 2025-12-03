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
    final colorDorado = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white12, width: 0.5)),
      ),
      child: BottomNavigationBar(
        // 'fixed' es importante porque ahora tenemos 6 botones y si no se vería raro
        type: BottomNavigationBarType.fixed, 
        backgroundColor: Colors.black,
        selectedItemColor: colorDorado,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 10, // Reducimos un poco la fuente para que quepan todos
        unselectedFontSize: 10,
        currentIndex: currentIndex,
        onTap: onTap,
        items: const <BottomNavigationBarItem>[
          // Índice 0
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Resumen',
          ),
          // Índice 1
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Prestar',
          ),
          // Índice 2
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_return),
            label: 'Devolver',
          ),
          // Índice 3:
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'Alumnos',
          ),
          // Índice 4
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Libro +',
          ),
          // Índice 5
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Inventario',
          ),
        ],
      ),
    );
  }
}