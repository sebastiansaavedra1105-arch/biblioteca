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

    // LÓGICA DE IMAGEN: 1. Bytes (Nueva) -> 2. URL (Existente) -> 3. Null
    ImageProvider? imagenMostrar;
    
    if (provider.fotoBytes != null) {
      imagenMostrar = MemoryImage(provider.fotoBytes!);
    } else if (provider.fotoUrl != null && provider.fotoUrl!.isNotEmpty) {
      imagenMostrar = NetworkImage(provider.fotoUrl!);
    }

    final bool tieneImagen = imagenMostrar != null;

    return GestureDetector(
      onTap: () => context.read<FormLibroProvider>().seleccionarFoto(),
      child: Column(
        children: [
          Container(
            width: 110,
            height: 150,
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              border: Border.all(
                color: tieneImagen ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.2), 
                width: 2
              ),
              borderRadius: BorderRadius.circular(12),
              // Aquí asignamos la imagen calculada arriba
              image: tieneImagen
                  ? DecorationImage(image: imagenMostrar, fit: BoxFit.cover)
                  : null,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))
              ],
            ),
            child: !tieneImagen
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo, color: colorScheme.primary, size: 30),
                      const SizedBox(height: 8),
                      Text(
                        "Subir\nPortada", 
                        textAlign: TextAlign.center, 
                        style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withOpacity(0.6))
                      )
                    ],
                  )
                : null,
          ),
          
          // BOTÓN DE BORRAR (Aparece si hay bytes O url)
          if (tieneImagen)
            TextButton.icon(
              onPressed: () => context.read<FormLibroProvider>().eliminarFoto(),
              icon: Icon(Icons.delete, size: 16, color: colorScheme.error),
              label: Text("Quitar", style: TextStyle(color: colorScheme.error, fontSize: 12)),
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 30)),
            )
        ],
      ),
    );
  }
}