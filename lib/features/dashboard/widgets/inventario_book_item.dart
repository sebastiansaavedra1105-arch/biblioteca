import 'package:flutter/material.dart';
import 'package:biblio/core/models/libro.dart';

class InventarioBookItem extends StatelessWidget {
  final Libro libro;
  final bool puedeEditar; // <--- VARIABLE CLAVE: Si es true, muestra botones
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const InventarioBookItem({
    super.key,
    required this.libro,
    required this.puedeEditar,
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
      color: theme.cardTheme.color,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // 1. FOTO
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
                  
                  // Chips de info
                  Row(
                    children: [
                      _InfoChip(
                        icon: Icons.inventory_2, 
                        label: "${libro.copiasDisponibles}",
                        color: libro.copiasDisponibles > 0 ? Colors.blue : Colors.red,
                      ),
                      const SizedBox(width: 10),
                      _InfoChip(
                        icon: Icons.qr_code, 
                        label: libro.codigoBarras,
                        color: Colors.orange,
                      ),
                    ],
                  )
                ],
              ),
            ),

            // 3. ACCIONES (Solo si puedeEditar es true)
            if (puedeEditar)
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 22),
                    color: colorScheme.primary,
                    tooltip: "Editar Libro",
                    onPressed: onEdit,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 22),
                    color: colorScheme.error,
                    tooltip: "Eliminar Libro",
                    onPressed: onDelete,
                  ),
                ],
              ),
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5)
      ),
      child: Row(
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label, 
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)
          ),
        ],
      ),
    );
  }
}