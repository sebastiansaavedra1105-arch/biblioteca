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
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        selectedItemColor: colorDorado,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        currentIndex: currentIndex,
        onTap: onTap,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Resumen',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline, size: 28),
            label: 'Prestar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_return),
            label: 'Devolver',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book, size: 28),
            label: 'Add Libro',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Inventario',
          ),
        ],
      ),
    );
  }
}