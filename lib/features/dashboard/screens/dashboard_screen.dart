import 'package:flutter/material.dart';
import '../../../core/database/database_service.dart';
import '../../prestamos/screens/nuevo_prestamo_screen.dart';
import '../../prestamos/screens/registrar_devolucion_screen.dart';
import '../../catalogo_publico/screens/catalogo_screen.dart';
import 'agregar_libro_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  bool _isLoading = true;

  // Variables de estado
  int totalLibros = 0;
  int prestamosActivos = 0;
  int librosDisponibles = 0;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final db = DatabaseService();
    final stats = await db.obtenerEstadisticas();
    
    if (mounted) {
      setState(() {
        totalLibros = stats['totalLibros'] ?? 0;
        prestamosActivos = stats['prestamosActivos'] ?? 0;
        librosDisponibles = stats['librosDisponibles'] ?? 0;
        _isLoading = false;
      });
    }
  }

  void _cerrarSesion() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const CatalogoScreen()),
      (route) => false,
    );
  }

  // Lógica principal de navegación
  void _onItemTapped(int index) async {
    // CASO 1: Si toca "Prestar" (Índice 1)
    if (index == 1) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const NuevoPrestamoScreen()),
      );
      _cargarDatos(); // Recargar al volver
      return; // No cambiamos de pestaña, nos quedamos donde estábamos
    }

    // CASO 2: Si toca "Nuevo Libro" (Índice 3)
    if (index == 3) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AgregarLibroScreen()),
      );
      _cargarDatos(); // Recargar al volver
      return; // No cambiamos de pestaña
    }

    // CASO 3: Navegación normal (Resumen, Devoluciones, Catálogo)
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorDorado = Theme.of(context).colorScheme.primary;

    // Definimos las vistas. 
    // NOTA: Dejamos SizedBox en los índices 1 y 3 porque esos botones abren pantallas encima, 
    // no cambian el cuerpo del Dashboard.
    final List<Widget> widgetOptions = <Widget>[
      _buildEstadisticasTab(colorDorado),  // Índice 0
      const SizedBox(),                    // Índice 1 (Botón Acción: Prestar)
      const RegistrarDevolucionScreen(),   // Índice 2
      const SizedBox(),                    // Índice 3 (Botón Acción: Nuevo Libro)
      const Center(child: Text('Catálogo Admin (Próximamente)')), // Índice 4
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('PANEL ADMINISTRATIVO'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarDatos,
            tooltip: 'Actualizar datos',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') _cerrarSesion();
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(children: [Icon(Icons.exit_to_app, color: Colors.red), SizedBox(width: 10), Text('Cerrar Sesión')]),
              ),
            ],
          ),
        ],
      ),
      
      // Cuerpo de la app
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : widgetOptions.elementAt(_selectedIndex),

      // --- BARRA DE NAVEGACIÓN CON 5 ITEMS ---
      bottomNavigationBar: BottomNavigationBar(
        // 'fixed' es obligatorio cuando hay más de 3 items para que se vean los textos y colores bien
        type: BottomNavigationBarType.fixed, 
        backgroundColor: Colors.black,
        selectedItemColor: colorDorado,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          // 0. Resumen
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard), 
            label: 'Resumen'
          ),
          // 1. Prestar (Acción)
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline, size: 30), 
            label: 'Prestar'
          ),
          // 2. Devoluciones
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_return), 
            label: 'Devolver'
          ),
          // 3. Nuevo Libro (Acción)
          BottomNavigationBarItem(
            icon: Icon(Icons.book, size: 30), 
            label: 'Agregar Libro'
          ),
          // 4. Inventario
          BottomNavigationBarItem(
            icon: Icon(Icons.list), 
            label: 'Inventario'
          ),
        ],
      ),
    );
  }

  Widget _buildEstadisticasTab(Color colorDorado) {
    if (totalLibros == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.library_books_outlined, size: 80, color: Colors.grey[800]),
            const SizedBox(height: 20),
            const Text("La base de datos está vacía", style: TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 30),
            const Text("Usa el botón 'Agregar Libro' abajo 👇", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Bienvenido, Admin", style: TextStyle(color: Colors.grey[400], fontSize: 16)),
          const SizedBox(height: 20),
          
          Expanded(
            child: GridView.count(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.1,
              children: [
                _buildStatCard('Total Libros', totalLibros.toString(), Colors.blue, Icons.menu_book),
                _buildStatCard('Disponibles', librosDisponibles.toString(), Colors.green, Icons.check_circle_outline),
                _buildStatCard('Prestados', prestamosActivos.toString(), Colors.orange, Icons.people_alt),
                _buildStatCard('Vencidos', '0', Colors.red, Icons.warning_amber),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String count, Color color, IconData icon) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.2), Colors.transparent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 30),
              const Spacer(),
              Text(count, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[400])),
            ],
          ),
        ),
      ),
    );
  }
}