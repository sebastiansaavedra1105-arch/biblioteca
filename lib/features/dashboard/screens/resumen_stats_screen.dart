import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/libros_provider.dart';

class ResumenStatsScreen extends StatelessWidget {
  const ResumenStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Escuchamos los datos
    return Consumer<LibrosProvider>(
      builder: (context, provider, child) {
        final stats = provider.estadisticas;
        final totalLibros = stats['totalLibros'] ?? 0;
        final prestamosActivos = stats['prestamosActivos'] ?? 0;
        final librosDisponibles = stats['librosDisponibles'] ?? 0;

        // Si está vacío
        if (totalLibros == 0 && !provider.isLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.library_books_outlined, size: 80, color: Colors.grey[800]),
                const SizedBox(height: 20),
                const Text("La base de datos está vacía", style: TextStyle(fontSize: 18, color: Colors.grey)),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Bienvenido, Admin", style: TextStyle(color: Colors.grey[400], fontSize: 16)),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 4,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                  children: [
                    _buildStatCard(context, 'Total Libros', totalLibros.toString(), Colors.blue, Icons.menu_book),
                    _buildStatCard(context, 'Disponibles', librosDisponibles.toString(), Colors.green, Icons.check_circle_outline),
                    _buildStatCard(context, 'Prestados', prestamosActivos.toString(), Colors.orange, Icons.people_alt),
                    _buildStatCard(context, 'Vencidos', '0', Colors.red, Icons.warning_amber),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String count, Color color, IconData icon) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.2), Colors.transparent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 30),
              const Spacer(),
              Text(count, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[400])),
            ],
          ),
        ),
      ),
    );
  }
}