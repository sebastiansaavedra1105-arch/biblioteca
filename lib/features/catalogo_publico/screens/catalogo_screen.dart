// ignore: unused_import
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Imports de arquitectura
import '../../../core/models/libro.dart';
import '../../dashboard/providers/libros_provider.dart';
import '../../auth/screens/login_screen.dart';

class CatalogoScreen extends StatefulWidget {
  const CatalogoScreen({super.key});

  @override
  State<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final colorDorado = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.black,
      // APP BAR TRANSPARENTE
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
          // --- BARRA DE BÚSQUEDA ---
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
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar título, autor...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                prefixIcon: Icon(Icons.search, color: colorDorado),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: colorDorado),
                ),
              ),
            ),
          ),

          // --- LISTA DE LIBROS (CONSUMER) ---
          Expanded(
            child: Consumer<LibrosProvider>(
              builder: (context, provider, child) {
                
                // 1. ESTADO DE CARGA INICIAL
                if (provider.isLoading && provider.libros.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: colorDorado),
                        const SizedBox(height: 20),
                        const Text("Cargando Biblioteca...", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                // 2. ERROR
                if (provider.error != null) {
                  return Center(child: Text("Error: ${provider.error}", style: const TextStyle(color: Colors.red)));
                }

                // 3. FILTRADO LOCAL
                final librosFiltrados = provider.libros.where((libro) {
                  final titulo = libro.titulo.toLowerCase();
                  final autor = libro.autor.toLowerCase();
                  final input = _searchQuery.toLowerCase();
                  return titulo.contains(input) || autor.contains(input);
                }).toList();

                // 4. LISTA VACÍA
                if (librosFiltrados.isEmpty) {
                  if (_searchQuery.isNotEmpty) {
                    return const Center(child: Text("No se encontraron coincidencias", style: TextStyle(color: Colors.grey)));
                  }
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.menu_book, size: 60, color: Colors.grey),
                        SizedBox(height: 15),
                        Text("No hay libros en el catálogo", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                // 5. GRILLA DE LIBROS
                return RefreshIndicator(
                  onRefresh: provider.cargarTodo, // Pull to refresh
                  color: colorDorado,
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // 2 columnas para que se vea bien en móviles
                      childAspectRatio: 0.65,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: librosFiltrados.length,
                    itemBuilder: (context, index) {
                      return _buildBookCard(librosFiltrados[index], colorDorado);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookCard(Libro libro, Color colorAccent) {
    final bool isDisponible = libro.copiasDisponibles > 0;
    
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[900]!),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 5, offset: const Offset(0, 3))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // FOTO
          Expanded(
            flex: 4,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                image: libro.fotoBytes != null
                  ? DecorationImage(
                      image: MemoryImage(libro.fotoBytes!), 
                      fit: BoxFit.cover
                    )
                  : null
              ),
              child: (libro.fotoBytes == null)
                 ? Center(child: Icon(Icons.book, size: 40, color: Colors.grey[800]))
                 : null,
            ),
          ),
          
          // INFO
          Expanded(
            flex: 3,
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
                        libro.titulo,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: colorAccent, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        libro.autor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                  
                  // ESTADO Y DISPONIBILIDAD
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDisponible ? Colors.green[900]!.withOpacity(0.3) : Colors.red[900]!.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isDisponible ? '${libro.copiasDisponibles} DISP.' : 'AGOTADO',
                          style: TextStyle(
                            color: isDisponible ? Colors.green[400] : Colors.red[400],
                            fontSize: 10,
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      ),
                    ],
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