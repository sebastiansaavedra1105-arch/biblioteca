import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color; // Color del icono y fondo sutil

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Eliminada la variable isDark que causaba la advertencia

    return Card(
      elevation: 2,
      // Color de fondo de la tarjeta automático según el tema (Blanco o Gris)
      color: theme.cardTheme.color, 
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            // ICONO EN CAJA DE COLOR
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15), // Fondo sutil del color del icono
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 20),
            
            // DATOS DE TEXTO
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // Para que no ocupe altura extra innecesaria
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface, // Se adapta (Negro o Blanco)
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}