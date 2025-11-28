import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/libros_provider.dart';
import 'agregar_libro_screen.dart';

class InventarioScreen extends StatelessWidget {
  const InventarioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LibrosProvider>(
      builder: (context, provider, _) {
        final libros = provider.libros;

        if (libros.isEmpty) {
          return const Center(child: Text("Sin inventario", style: TextStyle(color: Colors.grey)));
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80), // Espacio para que no lo tape nada
          itemCount: libros.length,
          itemBuilder: (context, index) {
            final l = libros[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              color: const Color(0xFF1A1A1A),
              child: ListTile(
                leading: l.fotoBytes != null 
                   ? Image.memory(l.fotoBytes!, width: 40, height: 60, fit: BoxFit.cover)
                   : const Icon(Icons.book, color: Colors.grey),
                title: Text(l.titulo, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text("Stock: ${l.copiasDisponibles} / ${l.copias}", style: TextStyle(color: Colors.grey[400])),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // EDITAR
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        // Navegamos a la pantalla de agregar PERO en modo edición
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => AgregarLibroScreen(libroParaEditar: l)),
                        );
                      },
                    ),
                    // BORRAR
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text("¿Eliminar Libro?"),
                            content: Text("Se borrará '${l.titulo}' permanentemente."),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  provider.borrarLibro(l.id!);
                                }, 
                                child: const Text("Eliminar", style: TextStyle(color: Colors.red))
                              ),
                            ],
                          )
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}