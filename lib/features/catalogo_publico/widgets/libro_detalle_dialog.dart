import 'package:flutter/material.dart';
import '../../../core/models/libro.dart';

class LibroDetalleDialog extends StatelessWidget {
  final Libro libro;

  const LibroDetalleDialog({super.key, required this.libro});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF252525),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 500, // Ancho máximo para escritorio
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- ENCABEZADO (FOTO + DATOS) ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // FOTO
                Container(
                  width: 100, height: 150,
                  decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _construirImagen(libro),
                  ),
                ),
                const SizedBox(width: 20),
                // DATOS
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(libro.titulo, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text("Por: ${libro.autor}", style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 16)),
                      const SizedBox(height: 10),
                      _datoFila("Categoría:", libro.categoria),
                      _datoFila("Editorial:", libro.editorial),
                      _datoFila("Año:", libro.anio.toString()),
                      _datoFila("ISBN:", libro.isbn),
                      const SizedBox(height: 10),
                      // Badge Disponibilidad
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: libro.copiasDisponibles > 0 ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: libro.copiasDisponibles > 0 ? Colors.green : Colors.red)
                        ),
                        child: Text(
                          libro.copiasDisponibles > 0 ? "DISPONIBLE (${libro.copiasDisponibles})" : "AGOTADO",
                          style: TextStyle(
                            color: libro.copiasDisponibles > 0 ? Colors.greenAccent : Colors.redAccent, 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(color: Colors.grey),
            
            // --- OBSERVACIONES ---
            const Align(alignment: Alignment.centerLeft, child: Text("Observaciones / Detalles:", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
            const SizedBox(height: 5),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
              child: Text(
                libro.observacion.isEmpty ? "Sin observaciones." : libro.observacion, 
                style: const TextStyle(color: Colors.white70)
              ),
            ),
            const SizedBox(height: 20),
            
            // --- BOTÓN CERRAR ---
            Align(
              alignment: Alignment.centerRight, 
              child: TextButton(
                onPressed: () => Navigator.pop(context), 
                child: const Text("Cerrar")
              )
            ),
          ],
        ),
      ),
    );
  }

  Widget _datoFila(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text("$label ", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          Expanded(child: Text(valor, style: const TextStyle(color: Colors.white70), overflow: TextOverflow.ellipsis)),
        ],
      ),
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
      color: Colors.grey[900],
      child: const Center(child: Icon(Icons.book, size: 30, color: Colors.grey)),
    );
  }
}