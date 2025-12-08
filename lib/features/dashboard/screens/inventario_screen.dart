import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:biblio/features/dashboard/providers/libros_provider.dart';
import 'package:biblio/features/auth/providers/auth_provider.dart';
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

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<LibrosProvider>().buscarLibros(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LibrosProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    
    // DETECTAR SI ES DIRECTOR
    final esDirector = context.read<AuthProvider>().esDirector;
    
    // SI ES DIRECTOR, ES MODO LECTURA. SI ES ADMIN, PUEDE EDITAR.
    // (Según tu lógica: Admin es quien edita, Director solo mira)
    final esModoLectura = esDirector; 

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: InventarioSearchBar(controller: _searchCtrl, onChanged: _onSearchChanged),
          ),
          Expanded(
            child: provider.isLoading
                ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: provider.libros.length,
                    itemBuilder: (context, index) {
                      final libro = provider.libros[index];
                      return InventarioBookItem(
                        libro: libro,
                        // TRUCO: Pasamos 'false' a esDirector en el widget BookItem
                        // para que oculte los botones de borrar/editar si estamos en modo lectura.
                        // OJO: El nombre del parámetro en BookItem es 'esDirector', 
                        // pero funciona como "puedeEditar". 
                        // Así que si esModoLectura es true, pasamos false.
                        esDirector: !esModoLectura, 
                        
                        onEdit: () { /* Lógica editar */ },
                        onDelete: () { /* Lógica borrar */ },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}