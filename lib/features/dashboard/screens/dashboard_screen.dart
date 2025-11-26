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

  int totalLibros = 0;
  int prestamosActivos = 0;
  int librosDisponibles = 0;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    
    DatabaseService().obtenerRutaBaseDatos().then((ruta) {
      debugPrint("ARCHIVO DE BASE DE DATOS UBICADO EN: $ruta"); 
    });
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

  void _onItemTapped(int index) async {
    if (index == 1) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const NuevoPrestamoScreen()),
      );
      _cargarDatos();
      return;
    }

    if (index == 3) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AgregarLibroScreen()),
      );
      _cargarDatos();
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorDorado = Theme.of(context).colorScheme.primary;

    final List<Widget> widgetOptions = <Widget>[
      _buildEstadisticasTab(colorDorado),
      const SizedBox(),
      const RegistrarDevolucionScreen(),
      const SizedBox(),
      const Center(child: Text('Catálogo Admin (Próximamente)')),
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
      
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : widgetOptions.elementAt(_selectedIndex),

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, 
        backgroundColor: Colors.black,
        selectedItemColor: colorDorado,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard), 
            label: 'Resumen'
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline, size: 30), 
            label: 'Prestar'
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_return), 
            label: 'Devolver'
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book, size: 30), 
            label: 'Add Libro'
          ),
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
            const Text("Usa el botón 'Add Libro' abajo 👇", style: TextStyle(color: Colors.grey)),
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
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
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