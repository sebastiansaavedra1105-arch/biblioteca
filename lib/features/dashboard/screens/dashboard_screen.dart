import 'package:flutter/material.dart';
// Importar el servicio de BD
import 'package:biblio/core/database/database_service.dart'; 

import 'package:biblio/features/prestamos/screens/nuevo_prestamo_screen.dart';
import 'package:biblio/features/prestamos/screens/registrar_devolucion_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Estado para manejar la carga
  bool _isLoading = true;
  int _totalLibros = 0;
  int _totalLectores = 0;
  int _totalPrestamosActivos = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  // Cargar datos asíncronamente
  Future<void> _loadDashboardData() async {
    setState(() { _isLoading = true; });

    // Instancia de la BD
    final db = DatabaseService.instance;

    // Obtener los conteos (ahora en paralelo)
    final data = await Future.wait([
      db.getTotalLibros(),
      db.getTotalLectores(),
      db.getTotalPrestamosActivos(),
    ]);

    // Actualizar el estado con los datos
    setState(() {
      _totalLibros = data[0];
      _totalLectores = data[1];
      _totalPrestamosActivos = data[2];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Biblioteca Dashboard'),
        actions: [
          // Botón para refrescar los datos
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'Refrescar datos',
          ),
        ],
      ),
      // Mostrar indicador de carga o el contenido
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildDashboardBody(context),
    );
  }

  // Widget principal del contenido del Dashboard
  Widget _buildDashboardBody(BuildContext context) {
    // Usar ListView para permitir scroll en pantallas pequeñas
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // --- Sección de Atajos Rápidos ---
        _buildSectionTitle(context, 'Atajos Rápidos'),
        const SizedBox(height: 16.0),
        Row(
          children: [
            Expanded(
              child: _buildShortcutButton(
                context: context,
                icon: Icons.add_task_outlined,
                label: 'Nuevo Préstamo',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NuevoPrestamoScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: _buildShortcutButton(
                context: context,
                icon: Icons.undo_outlined,
                label: 'Registrar Devolución',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegistrarDevolucionScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 24.0),

        // --- Sección de Estadísticas ---
        _buildSectionTitle(context, 'Estadísticas'),
        const SizedBox(height: 16.0),
        // Grid para las tarjetas de KPI
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16.0,
          crossAxisSpacing: 16.0,
          childAspectRatio: 1.2,
          children: [
            _buildKpiCard(
              title: 'Libros Totales',
              value: _totalLibros.toString(),
              icon: Icons.book_outlined,
              color: Colors.blue.shade700,
            ),
            _buildKpiCard(
              title: 'Lectores',
              value: _totalLectores.toString(),
              icon: Icons.person_outline,
              color: Colors.green.shade700,
            ),
            _buildKpiCard(
              title: 'Préstamos Activos',
              value: _totalPrestamosActivos.toString(),
              icon: Icons.swap_horiz_outlined,
              color: Colors.orange.shade700,
            ),
          ],
        ),
      ],
    );
  }

  // --- Widgets Reutilizables ---

  // Título de sección
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  // Tarjeta de KPI (Indicador Clave de Rendimiento)
  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 32.0, color: color),
            const SizedBox(height: 8.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black54,
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Botón de Atajo
  Widget _buildShortcutButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    final colorPrimario = Theme.of(context).colorScheme.primary;
    return ElevatedButton.icon(
      icon: Icon(icon, size: 20.0),
      label: Text(label),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: colorPrimario,
        backgroundColor: colorPrimario.withOpacity(0.1),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}