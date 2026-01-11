import 'package:flutter/material.dart';
import '../../../core/models/libro.dart';
import 'libro_detalle_dialog.dart';

class LibroPublicoCard extends StatelessWidget {
  final Libro libro;
  const LibroPublicoCard({super.key, required this.libro});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    
    final bool isDisponible = libro.copiasDisponibles > 0;

    // Colores dinámicos
    final Color estadoColor = isDisponible 
        ? const Color(0xFF2E7D32) // Verde Oscuro (Disponible)
        : colorScheme.error;      // Rojo Vino (Agotado - Aquí se ve tu color)

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => LibroDetalleDialog(libro: libro),
        );
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Card(
          // Quitamos margen para que el Grid controle el espacio
          margin: EdgeInsets.zero, 
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            // Borde sutil dorado si es oscuro
            side: theme.brightness == Brightness.dark 
                ? BorderSide(color: colorScheme.primary.withOpacity(0.3)) 
                : BorderSide.none,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. FOTO DEL LIBRO
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: _construirImagen(libro),
                    ),
                    // Etiqueta de Categoría flotante
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          libro.categoria,
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // 2. INFORMACIÓN
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título
                    Text(
                      libro.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Playfair Display', // Tu fuente elegante
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    
                    // Autor
                    Text(
                      libro.autor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    
                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 10),

                    // 3. ESTADO (Aquí está lo que pedías)
                    Row(
                      children: [
                        Icon(
                          isDisponible ? Icons.check_circle : Icons.cancel, 
                          size: 14, 
                          color: estadoColor
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            isDisponible 
                                ? 'DISPONIBLE (${libro.copiasDisponibles})' 
                                : 'AGOTADO',
                            style: TextStyle(
                              color: estadoColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirImagen(Libro l) {
    if (l.fotoBytes != null && l.fotoBytes!.isNotEmpty) {
      return Image.memory(l.fotoBytes!, fit: BoxFit.cover);
    } else if (l.fotoUrl != null && l.fotoUrl!.isNotEmpty) {
      return Image.network(
        l.fotoUrl!, 
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
        loadingBuilder: (_, child, loading) => loading == null ? child : _placeholder(),
      );
    } else {
      return _placeholder();
    }
  }

  Widget _placeholder() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.menu_book, size: 40, color: Colors.grey),
      ),
    );
  }
}