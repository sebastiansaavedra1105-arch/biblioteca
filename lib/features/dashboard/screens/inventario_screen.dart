import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

// Imports de Lógica
import 'package:biblio/core/models/libro.dart';
import 'package:biblio/features/dashboard/providers/libros_provider.dart';
import 'package:biblio/features/auth/providers/auth_provider.dart';
import 'package:biblio/features/dashboard/features/gestion_libro/providers/form_libro_provider.dart';

// Imports de Pantallas y Widgets
import 'package:biblio/features/dashboard/features/gestion_libro/screens/agregar_libro_screen.dart';
import '../widgets/inventario_search_bar.dart'; // <--- El que creamos
import '../widgets/inventario_book_item.dart';  // <--- El que creamos

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
    // Carga inicial para asegurar datos frescos
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

  // Lógica de búsqueda con retraso para no saturar la BD
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<LibrosProvider>().buscarLibros(query);
    });
  }

  // Navegar a Editar (Inyectando el Provider necesario)
  void _irAEditar(Libro libro) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => FormLibroProvider(), // Creamos una instancia limpia del formulario
          child: AgregarLibroScreen(libroParaEditar: libro),
        ),
      ),
    ).then((_) {
      // Al volver, recargamos la lista por si hubo cambios
      if (mounted) context.read<LibrosProvider>().cargarTodo();
    });
  }

  // Lógica de Borrado
  void _confirmarBorrado(BuildContext context, Libro libro) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: const Text("Confirmar Borrado"),
        content: Text("¿Realmente deseas eliminar '${libro.titulo}' del sistema?\nEsta acción no se puede deshacer."),
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
                    backgroundColor: theme.colorScheme.error,
                  )
                );
              }
            },
            child: const Text("Borrar Definitivamente"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LibrosProvider>();
    final esDirector = context.read<AuthProvider>().esDirector;
    final theme = Theme.of(context);

    return Scaffold(
      // Ya no necesitamos AppBar aquí porque el Dashboard tiene el título "INVENTARIO GENERAL"
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
                ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
                : provider.libros.isEmpty
                    ? _buildEmptyState(theme)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: provider.libros.length,
                        itemBuilder: (context, index) {
                          final libro = provider.libros[index];
                          return InventarioBookItem(
                            libro: libro,
                            esDirector: esDirector,
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

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: theme.colorScheme.onSurface.withOpacity(0.2)),
          const SizedBox(height: 20),
          Text(
            "No se encontraron libros",
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5)
            ),
          ),
        ],
      ),
    );
  }
}