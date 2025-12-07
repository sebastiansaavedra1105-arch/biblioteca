import 'package:flutter/material.dart';
import 'package:biblio/core/models/libro.dart';

class InventarioBookItem extends StatelessWidget {
  final Libro libro;
  final bool esDirector;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const InventarioBookItem({
    super.key,
    required this.libro,
    required this.esDirector,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // 1. FOTO (Pequeña y optimizada)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 60,
                height: 90,
                child: _construirImagen(libro, colorScheme),
              ),
            ),
            const SizedBox(width: 16),

            // 2. DATOS DEL LIBRO
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    libro.titulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Playfair Display', // Fuente elegante
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    libro.autor,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7)
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Chips de info (Stock y Código)
                  Row(
                    children: [
                      _InfoChip(
                        icon: Icons.inventory_2, 
                        label: "${libro.copiasDisponibles}/${libro.copias}",
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      _InfoChip(
                        icon: Icons.qr_code, 
                        label: libro.codigoBarras,
                        color: colorScheme.secondary,
                      ),
                    ],
                  )
                ],
              ),
            ),

            // 3. BOTONES DE ACCIÓN (Editar / Eliminar)
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  color: colorScheme.primary,
                  tooltip: "Editar",
                  onPressed: onEdit,
                ),
                if (esDirector) // Solo el director puede borrar
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    color: colorScheme.error, // Rojo Vino
                    tooltip: "Eliminar",
                    onPressed: onDelete,
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _construirImagen(Libro l, ColorScheme colors) {
    if (l.fotoBytes != null && l.fotoBytes!.isNotEmpty) {
      return Image.memory(l.fotoBytes!, fit: BoxFit.cover);
    } else if (l.fotoUrl != null && l.fotoUrl!.isNotEmpty) {
      return Image.network(
        l.fotoUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(colors),
      );
    }
    return _placeholder(colors);
  }

  Widget _placeholder(ColorScheme colors) {
    return Container(
      color: colors.onSurface.withOpacity(0.1),
      child: Icon(Icons.book, color: colors.onSurface.withOpacity(0.3)),
    );
  }
}

// Widget auxiliar pequeño para los datos
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label, 
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)
          ),
        ],
      ),
    );
  }
}