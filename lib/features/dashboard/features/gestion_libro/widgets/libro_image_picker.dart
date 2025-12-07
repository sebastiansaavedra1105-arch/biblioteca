import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/form_libro_provider.dart';

class LibroImagePicker extends StatelessWidget {
  const LibroImagePicker({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FormLibroProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        GestureDetector(
          onTap: () => context.read<FormLibroProvider>().seleccionarFoto(),
          child: Container(
            width: 120,
            height: 160,
            decoration: BoxDecoration(
              // Fondo dinámico: Gris suave en Light, Gris oscuro en Dark
              color: theme.brightness == Brightness.dark 
                  ? Colors.grey[800] 
                  : Colors.grey[200],
              border: Border.all(
                color: colorScheme.primary.withOpacity(0.5), 
                width: 2
              ),
              borderRadius: BorderRadius.circular(12),
              image: provider.fotoBytes != null
                  ? DecorationImage(
                      image: MemoryImage(provider.fotoBytes!), 
                      fit: BoxFit.cover
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5)
                )
              ],
            ),
            child: provider.fotoBytes == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo, color: colorScheme.primary, size: 30),
                      const SizedBox(height: 8),
                      Text(
                        "Tocar para\nagregar portada",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11, 
                          color: colorScheme.onSurface.withOpacity(0.6)
                        ),
                      )
                    ],
                  )
                : null,
          ),
        ),
        
        // Botón para quitar la foto (solo si hay foto)
        if (provider.fotoBytes != null)
          TextButton.icon(
            onPressed: () => context.read<FormLibroProvider>().eliminarFoto(),
            icon: Icon(Icons.delete, size: 16, color: colorScheme.error),
            label: Text("Quitar", style: TextStyle(color: colorScheme.error, fontSize: 12)),
          )
      ],
    );
  }
}