import 'package:flutter/material.dart';
import '../../../core/database/database_service.dart';
import '../../auth/screens/login_screen.dart';

class CatalogoScreen extends StatefulWidget {
  const CatalogoScreen({super.key});

  @override
  State<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen> {
  // Lista vacía al inicio, se llenará con la DB
  List<Map<String, dynamic>> _libros = [];
  List<Map<String, dynamic>> _librosFiltrados = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarLibros();
  }

  Future<void> _cargarLibros() async {
    final datos = await DatabaseService().obtenerTodosLosLibros();
    if (mounted) {
      setState(() {
        _libros = datos;
        _librosFiltrados = datos; // Al inicio mostramos todos
        _isLoading = false;
      });
    }
  }

  void _filtrarLibros(String query) {
    final results = _libros.where((libro) {
      final titulo = libro['titulo'].toString().toLowerCase();
      final autor = libro['autor'].toString().toLowerCase();
      final input = query.toLowerCase();
      return titulo.contains(input) || autor.contains(input);
    }).toList();

    setState(() => _librosFiltrados = results);
  }

  @override
  Widget build(BuildContext context) {
    final colorDorado = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.black, // Aseguramos fondo negro
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_library, color: colorDorado, size: 28),
            const SizedBox(width: 10),
            const Text('BIBLIOTECA DIGITAL'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.login),
            tooltip: 'Acceso Admin',
            onPressed: () {
               Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          )
        ],
      ),
      body: Column(
        children: [
          // SECCIÓN BUSCADOR
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black, Colors.black.withOpacity(0.8)],
                begin: Alignment.topCenter, end: Alignment.bottomCenter
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _filtrarLibros,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar título, autor...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                prefixIcon: Icon(Icons.search, color: colorDorado),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: colorDorado),
                ),
              ),
            ),
          ),

          // SECCIÓN GRID DE LIBROS REALES
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _cargarLibros,
                  color: colorDorado,
                  child: _librosFiltrados.isEmpty 
                    ? const Center(child: Text("No se encontraron libros", style: TextStyle(color: Colors.grey)))
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3, 
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: _librosFiltrados.length,
                        itemBuilder: (context, index) {
                          return _buildBookCard(_librosFiltrados[index], colorDorado);
                        },
                      ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookCard(Map<String, dynamic> libro, Color colorAccent) {
    // Calculamos disponibilidad real desde la DB
    final int disponibles = libro['copias_disponibles'];
    final bool isDisponible = disponibles > 0;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[900]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Center(
                // Si tienes URL de imagen úsala, si no, ícono genérico
                child: Icon(Icons.book, size: 40, color: Colors.grey[800]),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        libro['titulo'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colorAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        libro['autor'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDisponible ? Colors.green[900]!.withOpacity(0.3) : Colors.red[900]!.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isDisponible ? '$disponibles DISPONIBLES' : 'AGOTADO',
                      style: TextStyle(
                        color: isDisponible ? Colors.green[400] : Colors.red[400],
                        fontSize: 9,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}