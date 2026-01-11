import 'package:flutter/material.dart';

class SeleccionCard extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final IconData icon;
  final Color colorBase; // Azul para Alumno, Dorado para Libro
  final VoidCallback onDelete;

  const SeleccionCard({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.icon,
    required this.colorBase,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorBase.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: colorBase.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorBase.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: colorBase),
        ),
        title: Text(
          titulo,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitulo,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        trailing: IconButton(
          icon: Icon(Icons.close, color: theme.colorScheme.error),
          onPressed: onDelete,
          tooltip: "Quitar selección",
        ),
      ),
    );
  }
}