import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:biblio/core/models/libro.dart';
import 'package:biblio/features/dashboard/providers/libros_provider.dart';
import 'package:biblio/features/dashboard/features/gestion_libro/screens/agregar_libro_screen.dart';
// Importamos AuthProvider para permisos
import 'package:biblio/features/auth/providers/auth_provider.dart';

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _filtro = '';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LibrosProvider>();
    final dorado = Theme.of(context).colorScheme.primary;
    // Verificamos si es director
    final esDirector = context.read<AuthProvider>().esDirector;

    final librosFiltrados = provider.libros.where((l) {
      final query = _filtro.toLowerCase();
      return l.titulo.toLowerCase().contains(query) ||
             l.autor.toLowerCase().contains(query) ||
             l.codigoBarras.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.black, 
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar por título, autor o código...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                prefixIcon: Icon(Icons.search, color: dorado),
                suffixIcon: _filtro.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _filtro = '');
                      },
                    ) 
                  : null,
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
              onChanged: (val) => setState(() => _filtro = val),
            ),
          ),

          Expanded(
            child: provider.isLoading
              ? Center(child: CircularProgressIndicator(color: dorado))
              : librosFiltrados.isEmpty
                ? const Center(child: Text("No se encontraron libros", style: TextStyle(color: Colors.grey)))
                : Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.grey[800],
                      dataTableTheme: DataTableThemeData(
                        headingRowColor: WidgetStateProperty.all(const Color(0xFF252525)),
                        dataRowColor: WidgetStateProperty.all(Colors.black),
                        headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        dataTextStyle: const TextStyle(color: Colors.white70),
                      )
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal, 
                        child: DataTable(
                          columnSpacing: 20,
                          horizontalMargin: 20,
                          dataRowMinHeight: 60,
                          dataRowMaxHeight: 70,
                          columns: [
                            const DataColumn(label: Text("Portada")),
                            const DataColumn(label: Text("Título")),
                            const DataColumn(label: Text("Autor")),
                            const DataColumn(label: Text("Año")),
                            const DataColumn(label: Text("Categ.")),
                            const DataColumn(label: Text("Stock")),
                            // Ocultamos la columna Acciones si es director
                            if (!esDirector) const DataColumn(label: Text("Acciones")),
                          ],
                          rows: librosFiltrados.map((libro) {
                            return DataRow(
                              cells: [
                                DataCell(
                                  Container(
                                    width: 40, height: 50,
                                    margin: const EdgeInsets.symmetric(vertical: 5),
                                    decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(4)),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: _construirImagenMini(libro),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 200,
                                    child: Text(libro.titulo, overflow: TextOverflow.ellipsis, maxLines: 2)
                                  ),
                                ),
                                DataCell(Text(libro.autor)),
                                DataCell(Text(libro.anio.toString())),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: Colors.blueGrey[900], borderRadius: BorderRadius.circular(10)),
                                    child: Text(libro.categoria, style: const TextStyle(fontSize: 12)),
                                  )
                                ),
                                DataCell(
                                  Text(
                                    "${libro.copiasDisponibles} / ${libro.copias}",
                                    style: TextStyle(
                                      color: libro.copiasDisponibles > 0 ? Colors.greenAccent : Colors.redAccent,
                                      fontWeight: FontWeight.bold
                                    ),
                                  )
                                ),
                                // Solo mostramos los botones si NO es director
                                if (!esDirector)
                                  DataCell(
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.blueGrey, size: 20),
                                          tooltip: "Editar",
                                          onPressed: () {
                                            Navigator.push(context, MaterialPageRoute(builder: (_) => AgregarLibroScreen(libroParaEditar: libro)));
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                          tooltip: "Borrar",
                                          onPressed: () => _confirmarBorrado(context, provider, libro),
                                        ),
                                      ],
                                    )
                                  ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _construirImagenMini(Libro l) {
    if (l.fotoBytes != null && l.fotoBytes!.isNotEmpty) {
      return Image.memory(l.fotoBytes!, fit: BoxFit.cover);
    } else if (l.fotoUrl != null && l.fotoUrl!.isNotEmpty) {
      return Image.network(l.fotoUrl!, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.book, size: 20, color: Colors.grey));
    }
    return const Icon(Icons.book, size: 20, color: Colors.grey);
  }

  void _confirmarBorrado(BuildContext context, LibrosProvider provider, Libro libro) {
    showDialog(
      context: context, 
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("Confirmar Borrado", style: TextStyle(color: Colors.white)),
        content: Text("¿Eliminar '${libro.titulo}'?", style: const TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          TextButton(
            onPressed: () {
              provider.borrarLibro(libro.id!);
              Navigator.pop(context);
            }, 
            child: const Text("Borrar", style: TextStyle(color: Colors.red))
          ),
        ],
      )
    );
  }
}