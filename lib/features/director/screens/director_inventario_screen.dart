import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:biblio/features/dashboard/providers/libros_provider.dart';
import 'package:biblio/core/models/libro.dart'; // Ahora sí se detectará como usado

class DirectorInventarioScreen extends StatefulWidget {
  const DirectorInventarioScreen({super.key});

  @override
  State<DirectorInventarioScreen> createState() => _DirectorInventarioScreenState();
}

class _DirectorInventarioScreenState extends State<DirectorInventarioScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LibrosProvider>().cargarTodo();
    });
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<LibrosProvider>().buscarLibros(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LibrosProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // BUSCADOR EN EL CUERPO
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchCtrl,
            onChanged: _onSearchChanged,
            style: TextStyle(color: colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: "Consultar inventario...",
              hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
              prefixIcon: Icon(Icons.search, color: colorScheme.primary),
              filled: true,
              fillColor: theme.cardTheme.color,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10), 
                borderSide: BorderSide.none
              ),
            ),
          ),
        ),

        Expanded(
          child: provider.isLoading
              ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: provider.libros.length,
                  itemBuilder: (context, index) {
                    // CORRECCIÓN AQUÍ: Usamos 'Libro' explícitamente en vez de 'final'
                    // Esto hace que el import de arriba sea necesario y elimina la advertencia.
                    Libro libro = provider.libros[index];
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 1,
                      color: theme.cardTheme.color,
                      child: ListTile(
                        leading: Container(
                          width: 40, height: 60,
                          decoration: BoxDecoration(
                            color: colorScheme.surface, 
                            borderRadius: BorderRadius.circular(4)
                          ),
                          child: (libro.fotoUrl != null || libro.fotoBytes != null)
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image(
                                    image: (libro.fotoBytes != null)
                                        ? MemoryImage(libro.fotoBytes!) as ImageProvider
                                        : NetworkImage(libro.fotoUrl!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_,__,___) => Icon(Icons.book, color: colorScheme.onSurface.withOpacity(0.3)),
                                  ),
                                )
                              : Icon(Icons.book, color: colorScheme.onSurface.withOpacity(0.3)),
                        ),
                        title: Text(
                          libro.titulo, 
                          maxLines: 1, 
                          overflow: TextOverflow.ellipsis, 
                          style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface)
                        ),
                        subtitle: Text(
                          "Stock: ${libro.copiasDisponibles}/${libro.copias} • ${libro.codigoBarras}", 
                          style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6))
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}