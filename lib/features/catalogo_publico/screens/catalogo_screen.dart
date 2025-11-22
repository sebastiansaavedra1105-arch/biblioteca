import 'package:flutter/material.dart';
import '../../auth/screens/login_screen.dart';

class CatalogoScreen extends StatefulWidget {
  const CatalogoScreen({super.key});

  @override
  State<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen> {
  // Simulación de datos (luego vendrán de la BD)
  final List<Map<String, dynamic>> libros = [
    {'titulo': 'Clean Code', 'autor': 'Robert C. Martin', 'disponible': true},
    {'titulo': 'El Principito', 'autor': 'Antoine de Saint-Exupéry', 'disponible': false},
    {'titulo': '1984', 'autor': 'George Orwell', 'disponible': true},
    {'titulo': 'Flutter Apprentice', 'autor': 'Ray Wenderlich', 'disponible': true},
    {'titulo': 'Cien Años de Soledad', 'autor': 'Gabriel García Márquez', 'disponible': true},
  ];

  @override
  Widget build(BuildContext context) {
    // Obtenemos los colores del tema definido en main.dart
    final colorDorado = Theme.of(context).colorScheme.primary;
    final colorFondoTarjeta = Theme.of(context).cardTheme.color;

    return Scaffold(
      // Appbar transparente para dar sensación de amplitud
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_library, color: colorDorado, size: 30),
            const SizedBox(width: 10),
            const Text('BIBLIOTECA DIGITAL'), // Fuente definida en theme
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.login),
            tooltip: 'Acceso Administrativo',
            onPressed: () {
              Navigator.push
              (context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
             );
            },
          )
        ],
      ),
      body: Column(
        children: [
          // SECCIÓN 1: BUSCADOR HERO
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black, 
                  Colors.black.withOpacity(0.8)
                ],
              ),
            ),
            child: Column(
              children: [
                const Text(
                  "Encuentra tu próxima lectura",
                  style: TextStyle(
                    color: Colors.grey, 
                    fontSize: 16, 
                    letterSpacing: 2
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Buscar por título, autor o ISBN...',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    filled: true,
                    fillColor: const Color(0xFF1A1A1A), // Gris oscuro premium
                    prefixIcon: Icon(Icons.search, color: colorDorado),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: colorDorado),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: Colors.grey[800]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: colorDorado, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // SECCIÓN 2: RESULTADOS (GRID)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, // 3 Columnas (ajustable según pantalla)
                  childAspectRatio: 0.7, // Proporción de libro vertical
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: libros.length,
                itemBuilder: (context, index) {
                  final libro = libros[index];
                  return _buildBookCard(libro, colorDorado, colorFondoTarjeta!);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookCard(Map<String, dynamic> libro, Color colorAccent, Color cardColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[900]!), // Borde sutil
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Simulación de Portada
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Center(
                child: Icon(Icons.book, size: 50, color: Colors.grey[800]),
              ),
            ),
          ),
          // Información
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
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
                          color: colorAccent, // Título Dorado
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        libro['autor'],
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                  // Indicador de Disponibilidad
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: libro['disponible'] ? Colors.green[900]!.withOpacity(0.3) : Colors.red[900]!.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: libro['disponible'] ? Colors.green : Colors.red,
                        width: 0.5
                      )
                    ),
                    child: Text(
                      libro['disponible'] ? 'DISPONIBLE' : 'PRESTADO',
                      style: TextStyle(
                        color: libro['disponible'] ? Colors.green[400] : Colors.red[400],
                        fontSize: 10,
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