import 'package:flutter/material.dart';
import '../../../core/models/libro.dart';
import 'libro_detalle_dialog.dart';

class LibroPublicoCard extends StatelessWidget {
  final Libro libro;
  const LibroPublicoCard({super.key, required this.libro});

  @override
  Widget build(BuildContext context) {
    final bool isDisponible = libro.copiasDisponibles > 0;

    return GestureDetector(
      onTap: () {
        // Al tocar, abrimos el widget del diálogo que creamos antes
        showDialog(
          context: context,
          builder: (ctx) => LibroDetalleDialog(libro: libro),
        );
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 5, offset: const Offset(0, 3))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // FOTO
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                  child: _construirImagen(libro),
                ),
              ),
              // DATOS RESUMIDOS
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      libro.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.circle, size: 8, color: isDisponible ? Colors.green : Colors.red),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            isDisponible ? 'Disponible' : 'Agotado',
                            style: TextStyle(color: Colors.grey[400], fontSize: 10),
                            overflow: TextOverflow.ellipsis,
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
        l.fotoUrl!, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
        loadingBuilder: (_, child, loading) => loading == null ? child : const Center(child: CircularProgressIndicator()),
      );
    } else {
      return Container(color: Colors.grey[900], child: const Icon(Icons.book, color: Colors.grey));
    }
  }
}