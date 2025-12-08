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

    return GestureDetector(
      onTap: () => context.read<FormLibroProvider>().seleccionarFoto(),
      child: Column(
        children: [
          Container(
            width: 110,
            height: 150,
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              border: Border.all(color: colorScheme.primary.withOpacity(0.5), width: 2),
              borderRadius: BorderRadius.circular(12),
              image: provider.fotoBytes != null
                  ? DecorationImage(image: MemoryImage(provider.fotoBytes!), fit: BoxFit.cover)
                  : null,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))
              ],
            ),
            child: provider.fotoBytes == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo, color: colorScheme.primary, size: 30),
                      const SizedBox(height: 8),
                      Text("Subir\nPortada", textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withOpacity(0.6)))
                    ],
                  )
                : null,
          ),
          
          if (provider.fotoBytes != null)
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