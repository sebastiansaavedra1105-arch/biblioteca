import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:biblio/core/models/libro.dart';
import 'package:biblio/features/dashboard/providers/libros_provider.dart';
import 'package:biblio/features/dashboard/features/gestion_libro/screens/agregar_libro_screen.dart';
import 'package:biblio/features/auth/providers/auth_provider.dart';
import 'package:biblio/features/dashboard/features/gestion_libro/providers/form_libro_provider.dart';

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LibrosProvider>();
    final esDirector = context.read<AuthProvider>().esDirector;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Column(
        children: [
          // --- 1. ENCABEZADO FIJO (Barra de herramientas) ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E1E),
              border: Border(bottom: BorderSide(color: Color(0xFF333333))),
            ),
            child: Row(
              children: [
                // Título e Icono
                Icon(
                  esDirector ? Icons.analytics_outlined : Icons.inventory_2_outlined,
                  color: primaryColor,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      esDirector ? "Visor de Inventario" : "Gestión de Inventario",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "${provider.libros.length} libros encontrados",
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                ),
                const Spacer(),

                // Barra de Búsqueda
                SizedBox(
                  width: 300,
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: _onSearchChanged,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Buscar por título, autor o código...',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      prefixIcon: Icon(Icons.search, color: primaryColor),
                      filled: true,
                      fillColor: const Color(0xFF2C2C2C),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Botón "Nuevo Libro" (SOLO ADMIN)
               if (!esDirector)
                  ElevatedButton.icon(
                    onPressed: () {
                       Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => 
                          ChangeNotifierProvider(
                            create: (_) => FormLibroProvider(),
                            child: const AgregarLibroScreen(),
                          )
                        ),
                      );
                    },
                    icon: const Icon(Icons.add, color: Colors.black),
                    label: const Text("Nuevo Libro"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // --- 2. TABLA DE DATOS (EXPANDIDA) ---
          Expanded(
            child: provider.libros.isEmpty
                ? _buildEmptyState()
                : Theme(
                    data: Theme.of(context).copyWith(
                      cardColor: const Color(0xFF1E1E1E),
                      dividerColor: const Color(0xFF333333),
                      textTheme: const TextTheme(
                        bodySmall: TextStyle(color: Colors.white),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: SizedBox(
                        width: double.infinity,
                        child: PaginatedDataTable(
                          header: null,
                          rowsPerPage: 10,
                          columnSpacing: 20,
                          showCheckboxColumn: false,
                          arrowHeadColor: primaryColor,
                          columns: [
                            const DataColumn(
                              label: Text(
                                "Portada",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                            const DataColumn(
                              label: Text(
                                "Código",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                            const DataColumn(
                              label: Text(
                                "Título",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const DataColumn(
                              label: Text(
                                "Autor",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                            const DataColumn(
                              label: Text(
                                "Categoría",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                            const DataColumn(
                              label: Text(
                                "Stock",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                            const DataColumn(
                              label: Text(
                                "Estado",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                            if (!esDirector)
                              const DataColumn(
                                label: Text(
                                  "Acciones",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                          ],
                          source: _LibrosDataSource(
                            libros: provider.libros,
                            context: context,
                            provider: provider,
                            esDirector: esDirector,
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_books_outlined, size: 80, color: Colors.grey[800]),
          const SizedBox(height: 16),
          Text(
            "No se encontraron libros",
            style: TextStyle(color: Colors.grey[500], fontSize: 18),
          ),
        ],
      ),
    );
  }
}

// --- CLASE DATA SOURCE PARA LA TABLA ---
class _LibrosDataSource extends DataTableSource {
  final List<Libro> libros;
  final BuildContext context;
  final LibrosProvider provider;
  final bool esDirector;

  _LibrosDataSource({
    required this.libros,
    required this.context,
    required this.provider,
    required this.esDirector,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= libros.length) return null;
    final libro = libros[index];
    final colorEstado =
        libro.copiasDisponibles > 0 ? Colors.greenAccent : Colors.redAccent;

    return DataRow(
      cells: [
        // 1. Portada
        DataCell(
          Container(
            width: 30,
            height: 45,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Colors.grey[800],
            ),
            clipBehavior: Clip.antiAlias,
            child: _construirImagenMini(libro),
          ),
        ),
        // 2. Código
        DataCell(
          Text(
            libro.codigoBarras,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
        // 3. Título
        DataCell(
          SizedBox(
            width: 250,
            child: Text(
              libro.titulo,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        // 4. Autor
        DataCell(
          Text(
            libro.autor,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
        // 5. Categoria
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              libro.categoria,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white60,
              ),
            ),
          ),
        ),
        // 6. Stock
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${libro.copiasDisponibles}",
                style: TextStyle(
                  color: colorEstado,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "/${libro.copias}",
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        // 7. Estado
        DataCell(
          Text(
            libro.estado,
            style: const TextStyle(color: Colors.white70),
          ),
        ),

        // 8. Acciones (SOLO ADMIN)
        if (!esDirector)
          DataCell(
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 20),
                  tooltip: "Editar",
                  onPressed: () {
                     Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => 
                          ChangeNotifierProvider(
                            create: (_) => FormLibroProvider(),
                            child: AgregarLibroScreen(libroParaEditar: libro),
                          )
                        ),
                      );
                  },
                ),
                IconButton(
                  icon:
                      const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                  tooltip: "Eliminar",
                  onPressed: () =>
                      _confirmarBorrado(context, provider, libro),
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => libros.length;
  @override
  int get selectedRowCount => 0;

  Widget _construirImagenMini(Libro l) {
    if (l.fotoBytes != null && l.fotoBytes!.isNotEmpty) {
      return Image.memory(l.fotoBytes!, fit: BoxFit.cover);
    } else if (l.fotoUrl != null && l.fotoUrl!.isNotEmpty) {
      return Image.network(
        l.fotoUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.book, size: 16, color: Colors.white24),
      );
    }
    return const Icon(Icons.book, size: 16, color: Colors.white24);
  }

  void _confirmarBorrado(
    BuildContext context,
    LibrosProvider provider,
    Libro libro,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          "Confirmar Borrado",
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          "¿Realmente deseas eliminar '${libro.titulo}' del sistema?",
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancelar",
              style: TextStyle(color: Colors.white60),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[900],
            ),
            onPressed: () {
              provider.borrarLibro(libro.id!);
              Navigator.pop(context);
            },
            child: const Text(
              "Borrar",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}