import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/libros_provider.dart';
import '../../../core/models/libro.dart';
import 'agregar_libro_screen.dart';

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

    // Lógica de Filtrado Local
    final librosFiltrados = provider.libros.where((l) {
      final query = _filtro.toLowerCase();
      return l.titulo.toLowerCase().contains(query) ||
             l.autor.toLowerCase().contains(query) ||
             l.codigoBarras.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.black, // Fondo negro para consistencia
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- BUSCADOR ---
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

          // --- TABLA DE DATOS (FILAS) ---
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
                        scrollDirection: Axis.horizontal, // Scroll lateral si la pantalla es pequeña
                        child: DataTable(
                          columnSpacing: 20,
                          horizontalMargin: 20,
                          dataRowMinHeight: 60,
                          dataRowMaxHeight: 70,
                          columns: const [
                            DataColumn(label: Text("Portada")),
                            DataColumn(label: Text("Título")),
                            DataColumn(label: Text("Autor")),
                            DataColumn(label: Text("Año")),
                            DataColumn(label: Text("Categ.")),
                            DataColumn(label: Text("Stock")),
                            DataColumn(label: Text("Acciones")),
                          ],
                          rows: librosFiltrados.map((libro) {
                            return DataRow(
                              cells: [
                                // 1. Portada (Miniatura)
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
                                // 2. Título (Con ancho máximo para no romper la tabla)
                                DataCell(
                                  SizedBox(
                                    width: 200,
                                    child: Text(libro.titulo, overflow: TextOverflow.ellipsis, maxLines: 2)
                                  ),
                                ),
                                // 3. Autor
                                DataCell(Text(libro.autor)),
                                // 4. Año
                                DataCell(Text(libro.anio.toString())),
                                // 5. Categoría
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: Colors.blueGrey[900], borderRadius: BorderRadius.circular(10)),
                                    child: Text(libro.categoria, style: const TextStyle(fontSize: 12)),
                                  )
                                ),
                                // 6. Stock
                                DataCell(
                                  Text(
                                    "${libro.copiasDisponibles} / ${libro.copias}",
                                    style: TextStyle(
                                      color: libro.copiasDisponibles > 0 ? Colors.greenAccent : Colors.redAccent,
                                      fontWeight: FontWeight.bold
                                    ),
                                  )
                                ),
                                // 7. Acciones
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

  // Helper para imagen pequeña en la tabla
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