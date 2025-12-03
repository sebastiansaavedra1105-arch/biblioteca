import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:biblio/features/dashboard/features/gestion_libro/providers/form_libro_provider.dart';

class LibroImagePicker extends StatelessWidget {
  const LibroImagePicker({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FormLibroProvider>();
    final dorado = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: () => context.read<FormLibroProvider>().seleccionarFoto(),
      child: Container(
        width: 100,
        height: 140,
        decoration: BoxDecoration(
          color: Colors.grey[900],
          border: Border.all(color: dorado.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(8),
          image: provider.fotoBytes != null
              ? DecorationImage(
                  image: MemoryImage(provider.fotoBytes!), fit: BoxFit.cover)
              : null,
        ),
        child: provider.fotoBytes == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo, color: dorado),
                  const SizedBox(height: 5),
                  const Text("Portada", style: TextStyle(fontSize: 10, color: Colors.grey))
                ],
              )
            : null,
      ),
    );
  }
}