import 'package:flutter/material.dart';
import 'package:biblio/core/models/libro.dart';

class InventarioBookItem extends StatelessWidget {
  final Libro libro;
  final bool puedeEditar;
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
      margin: const EdgeInsets.only(bottom: 8), 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: theme.cardTheme.color,
      child: ListTile(
        visualDensity: VisualDensity.compact,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        
        // 1. FOTO
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            width: 40,
            height: 60,
            child: _construirImagen(libro, colorScheme),
          ),
        ),
        
        // 2. TÍTULO
        title: Text(
          libro.titulo,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        
        // 3. SUBTÍTULO
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              libro.autor,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
                fontSize: 13
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            
            // CHIPS COMPACTOS
            Row(
              mainAxisSize: MainAxisSize.min, // Importante: Que la fila ocupe lo mínimo
              children: [
                _InfoChip(
                  icon: Icons.inventory_2, 
                  label: "${libro.copiasDisponibles}",
                  color: libro.copiasDisponibles > 0 ? Colors.blue : Colors.red,
                ),
                const SizedBox(width: 8),
                
                // --- CORRECCIÓN AQUÍ ---
                // Antes: Expanded(...) -> Estiraba todo
                // Ahora: Flexible(...) -> Solo ocupa lo necesario
                Flexible( 
                  fit: FlexFit.loose, 
                  child: _InfoChip(
                    icon: Icons.qr_code, 
                    label: libro.codigoBarras,
                    color: Colors.orange,
                  ),
                ),
              ],
            )
          ],
        ),
        
        // 4. ACCIONES
        trailing: puedeEditar
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    color: colorScheme.primary,
                    tooltip: "Editar",
                    onPressed: onEdit,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    iconSize: 20,
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: colorScheme.error,
                    tooltip: "Eliminar",
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    iconSize: 20,
                  ),
                ],
              )
            : null,
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
      child: Center(
        child: Icon(Icons.book, size: 20, color: colors.onSurface.withOpacity(0.3))
      ),
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
        mainAxisSize: MainAxisSize.min, // Esto asegura que el chip se encoja al contenido
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Flexible( // Protege si el texto es muy largo, pero no estira si es corto
            child: Text(
              label, 
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}