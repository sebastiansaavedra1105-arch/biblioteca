import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/libros_provider.dart';
// Importamos el widget reutilizable
import '../widgets/stat_card.dart';

class ResumenStatsScreen extends StatelessWidget {
  const ResumenStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Escuchamos los datos
    return Consumer<LibrosProvider>(
      builder: (context, provider, child) {
        final stats = provider.estadisticas;
        final totalLibros = stats['totalLibros'] ?? 0;
        final prestamosActivos = stats['prestamosActivos'] ?? 0;
        final librosDisponibles = stats['librosDisponibles'] ?? 0;

        // ESTADO: VACÍO (Con estilos dinámicos)
        if (totalLibros == 0 && !provider.isLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.library_books_outlined, 
                  size: 80, 
                  color: colorScheme.onSurface.withOpacity(0.2) // Gris dinámico
                ),
                const SizedBox(height: 20),
                Text(
                  "La base de datos está vacía", 
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.5)
                  )
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SALUDO
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: colorScheme.primary,
                    radius: 20,
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Bienvenido, Admin", 
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface
                        )
                      ),
                      Text(
                        "Resumen de hoy", 
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6)
                        )
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 30),
              
              // TARJETAS DE ESTADÍSTICAS
              // Usamos Wrap para que sea responsive en todas las pantallas
              Wrap(
                spacing: 16, // Espacio horizontal
                runSpacing: 16, // Espacio vertical
                children: [
                  SizedBox(
                    width: 260, // Ancho fijo por tarjeta
                    child: StatCard(
                      title: 'Total Libros',
                      value: totalLibros.toString(),
                      icon: Icons.menu_book,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(
                    width: 260,
                    child: StatCard(
                      title: 'Disponibles',
                      value: librosDisponibles.toString(),
                      icon: Icons.check_circle_outline,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(
                    width: 260,
                    child: StatCard(
                      title: 'Prestados',
                      value: prestamosActivos.toString(),
                      icon: Icons.people_alt,
                      color: Colors.orange,
                    ),
                  ),
                  SizedBox(
                    width: 260,
                    child: StatCard(
                      title: 'Vencidos',
                      value: '0', // Aquí conectarás la lógica real de vencidos
                      icon: Icons.warning_amber,
                      color: colorScheme.error, // Rojo Vino
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),
              
              // SECCIÓN DE GRÁFICOS O LISTAS FUTURAS
              Text(
                "Actividad Reciente",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface
                ),
              ),
              const SizedBox(height: 10),
              
              // Placeholder para futura tabla de actividad
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.onSurface.withOpacity(0.1)),
                ),
                child: Center(
                  child: Text(
                    "No hay actividad reciente registrada",
                    style: TextStyle(color: colorScheme.onSurface.withOpacity(0.4)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}