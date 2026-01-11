import 'package:flutter/material.dart';
import '../../../core/models/libro.dart';

class LibroDetalleDialog extends StatelessWidget {
  final Libro libro;

  const LibroDetalleDialog({super.key, required this.libro});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Dialog(
      backgroundColor: colorScheme.surface, 
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.primary.withOpacity(0.3), width: 1), 
      ),
      child: Container(
        width: 600, 
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- ENCABEZADO (FOTO + TÍTULO) ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // FOTO CON SOMBRA
                Container(
                  width: 120, height: 180,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(3, 5),
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _construirImagen(libro),
                  ),
                ),
                const SizedBox(width: 24),
                
                // DATOS PRINCIPALES
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título
                      Text(
                        libro.titulo,
                        style: textTheme.displaySmall?.copyWith(
                          fontSize: 24, 
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Autor
                      Text(
                        libro.autor,
                        style: textTheme.headlineMedium?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          color: colorScheme.primary, 
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Categoría (Chip)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: colorScheme.primary.withOpacity(0.5)),
                        ),
                        child: Text(
                          libro.categoria,
                          style: textTheme.labelLarge?.copyWith(
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // --- DETALLES TÉCNICOS (GRID) ---
            Wrap(
              spacing: 30,
              runSpacing: 15,
              children: [
                _datoCampo(context, "ISBN", libro.isbn),
                _datoCampo(context, "Año", libro.anio.toString()),
                _datoCampo(context, "Editorial", libro.editorial),
                _datoCampo(context, "Ubicación", libro.codigoBarras), 
              ],
            ),

            const SizedBox(height: 24),

            // --- ESTADO Y DISPONIBILIDAD ---
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                // CORRECCIÓN: 'background' deprecated -> Usamos scaffoldBackgroundColor para contraste
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _EstadoBadge(
                    label: "Copias: ${libro.copiasDisponibles} / ${libro.copias}",
                    icon: Icons.copy,
                    color: colorScheme.onSurface,
                  ),
                  _EstadoBadge(
                    label: libro.copiasDisponibles > 0 ? "DISPONIBLE" : "AGOTADO",
                    icon: libro.copiasDisponibles > 0 ? Icons.check_circle : Icons.cancel,
                    color: libro.copiasDisponibles > 0 ? Colors.green : colorScheme.error,
                    isBold: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            
            // --- BOTÓN CERRAR ---
            Align(
              alignment: Alignment.centerRight, 
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context), 
                icon: const Icon(Icons.close),
                label: const Text("Cerrar"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.surface,
                  foregroundColor: colorScheme.onSurface,
                  elevation: 0,
                  side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _datoCampo(BuildContext context, String label, String valor) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.grey,
            letterSpacing: 1.0,
          ),
        ),
        Text(
          valor,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _construirImagen(Libro l) {
    if (l.fotoBytes != null && l.fotoBytes!.isNotEmpty) {
      return Image.memory(l.fotoBytes!, fit: BoxFit.cover);
    } else if (l.fotoUrl != null && l.fotoUrl!.isNotEmpty) {
      return Image.network(
        l.fotoUrl!, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
        loadingBuilder: (_, child, loading) => loading == null ? child : _placeholder(),
      );
    } else {
      return _placeholder();
    }
  }

  Widget _placeholder() {
    return Container(
      color: Colors.grey[300],
      child: const Center(child: Icon(Icons.book, size: 40, color: Colors.grey)),
    );
  }
}

class _EstadoBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isBold;

  const _EstadoBadge({
    required this.label,
    required this.icon,
    required this.color,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}