import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

// Lógica
import 'package:biblio/core/models/libro.dart';
import 'package:biblio/features/dashboard/providers/libros_provider.dart';
import 'package:biblio/features/auth/providers/auth_provider.dart';
// Provider del formulario (necesario para editar)
import 'package:biblio/features/dashboard/features/gestion_libro/providers/form_libro_provider.dart';

// Vistas
import 'package:biblio/features/dashboard/features/gestion_libro/screens/agregar_libro_screen.dart';
import '../widgets/inventario_search_bar.dart';
import '../widgets/inventario_book_item.dart';

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LibrosProvider>().cargarTodo();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<LibrosProvider>().buscarLibros(query);
    });
  }

  // --- LÓGICA DE NAVEGACIÓN A EDITAR ---
  void _irAEditar(Libro libro) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          // ¡IMPORTANTE! Creamos el provider del formulario aquí
          create: (_) => FormLibroProvider(),
          child: AgregarLibroScreen(libroParaEditar: libro),
        ),
      ),
    ).then((_) {
      // Al volver, recargamos la lista por si hubo cambios
      if (mounted) context.read<LibrosProvider>().cargarTodo();
    });
  }

  // --- LÓGICA DE BORRADO ---
  void _confirmarBorrado(BuildContext context, Libro libro) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmar Borrado"),
        content: Text("¿Deseas eliminar '${libro.titulo}' del sistema?\nEsta acción no se puede deshacer."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = context.read<LibrosProvider>();
              await provider.borrarLibro(libro.id!);
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Libro '${libro.titulo}' eliminado"),
                    backgroundColor: Colors.green,
                  )
                );
              }
            },
            child: const Text("Borrar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LibrosProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    
    // VERIFICAR PERMISOS
    final esDirector = context.read<AuthProvider>().esDirector;
    // Si es Director -> No edita. Si es Admin -> Sí edita.
    final bool puedeEditar = !esDirector; 

    return Scaffold(
      body: Column(
        children: [
          // 1. BARRA DE BÚSQUEDA
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: InventarioSearchBar(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
            ),
          ),

          // 2. LISTA DE LIBROS
          Expanded(
            child: provider.isLoading
                ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
                : provider.libros.isEmpty
                    ? Center(child: Text("No se encontraron libros", style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5))))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: provider.libros.length,
                        itemBuilder: (context, index) {
                          final libro = provider.libros[index];
                          return InventarioBookItem(
                            libro: libro,
                            puedeEditar: puedeEditar, // Pasamos el permiso
                            onEdit: () => _irAEditar(libro),
                            onDelete: () => _confirmarBorrado(context, libro),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}