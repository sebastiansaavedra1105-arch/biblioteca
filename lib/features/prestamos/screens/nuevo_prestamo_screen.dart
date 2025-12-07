import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/models/libro.dart';
import '../../../core/models/alumno.dart';
import '../../dashboard/providers/libros_provider.dart';
import '../../alumnos/providers/alumnos_provider.dart';
import '../../auth/providers/auth_provider.dart';

import '../widgets/prestamo_search_field.dart';
import '../widgets/seleccion_card.dart';

class NuevoPrestamoScreen extends StatefulWidget {
  const NuevoPrestamoScreen({super.key});

  @override
  State<NuevoPrestamoScreen> createState() => _NuevoPrestamoScreenState();
}

class _NuevoPrestamoScreenState extends State<NuevoPrestamoScreen> {
  final _libroCtrl = TextEditingController();
  final _alumnoCtrl = TextEditingController();
  
  Libro? _libroSeleccionado;
  Alumno? _alumnoSeleccionado;
  DateTime _fechaEntrega = DateTime.now().add(const Duration(days: 3));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AlumnosProvider>().cargarAlumnos();
    });
  }

  void _buscarLibro() {
    final query = _libroCtrl.text.trim().toLowerCase();
    if (query.isEmpty) return;

    final provider = context.read<LibrosProvider>();
    try {
      final libro = provider.libros.firstWhere(
        (l) => l.codigoBarras.toLowerCase() == query || 
               l.titulo.toLowerCase().contains(query),
      );
      
      if (libro.copiasDisponibles <= 0) {
        _mostrarError("El libro '${libro.titulo}' no tiene copias disponibles.");
        return;
      }

      setState(() {
        _libroSeleccionado = libro;
        _libroCtrl.clear();
      });
    } catch (e) {
      _mostrarError("No se encontró ningún libro con ese código/título.");
    }
  }

  void _buscarAlumno() {
    final query = _alumnoCtrl.text.trim().toLowerCase();
    if (query.isEmpty) return;

    final provider = context.read<AlumnosProvider>();
    try {
      final alumno = provider.alumnos.firstWhere(
        (a) => a.codigo.toLowerCase() == query || 
               a.nombreCompleto.toLowerCase().contains(query),
      );

      if (alumno.vetadoHasta != null && alumno.vetadoHasta!.isAfter(DateTime.now())) {
        _mostrarError("El alumno está vetado.");
        return;
      }

      setState(() {
        _alumnoSeleccionado = alumno;
        _alumnoCtrl.clear();
      });
    } catch (e) {
      _mostrarError("Alumno no encontrado.");
    }
  }

  Future<void> _procesarPrestamo() async {
    if (_libroSeleccionado == null || _alumnoSeleccionado == null) {
      _mostrarError("Debe seleccionar un libro y un alumno.");
      return;
    }

    final librosProvider = context.read<LibrosProvider>();
    final authProvider = context.read<AuthProvider>();
    
    // AQUÍ YA NO DARÁ ERROR PORQUE ACTUALIZAMOS EL PROVIDER
    final exito = await librosProvider.registrarPrestamo(
      libro: _libroSeleccionado!,
      alumno: _alumnoSeleccionado!,
      fechaEntrega: _fechaEntrega,
      usuarioId: authProvider.usuarioActual?['id'] ?? 'admin',
    );

    if (exito) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar( // Agregado const
          content: Text("✅ Préstamo registrado con éxito"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        )
      );
      setState(() {
        _libroSeleccionado = null;
        _alumnoSeleccionado = null;
        _fechaEntrega = DateTime.now().add(const Duration(days: 3));
      });
    } else {
      _mostrarError(librosProvider.error ?? "Error al registrar préstamo");
    }
  }

  void _mostrarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Theme.of(context).colorScheme.error)
    );
  }

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaEntrega,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _fechaEntrega = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Nuevo Préstamo",
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // 1. SELECCIONAR LIBRO
          const _SectionHeader(title: "1. Seleccionar Libro", icon: Icons.book), // Agregado const
          if (_libroSeleccionado == null)
            PrestamoSearchField(
              label: "Buscar por Código o Título",
              icon: Icons.qr_code,
              controller: _libroCtrl,
              onSearch: _buscarLibro,
            )
          else
            SeleccionCard(
              titulo: _libroSeleccionado!.titulo,
              subtitulo: "Copias: ${_libroSeleccionado!.copiasDisponibles}",
              icon: Icons.menu_book,
              colorBase: colorScheme.primary,
              onDelete: () => setState(() => _libroSeleccionado = null),
            ),
          
          const SizedBox(height: 30),

          // 2. SELECCIONAR ALUMNO
          const _SectionHeader(title: "2. Seleccionar Alumno", icon: Icons.person), // Agregado const
          if (_alumnoSeleccionado == null)
            PrestamoSearchField(
              label: "Buscar por DNI o Nombre",
              icon: Icons.badge,
              controller: _alumnoCtrl,
              onSearch: _buscarAlumno,
            )
          else
            SeleccionCard(
              titulo: _alumnoSeleccionado!.nombreCompleto,
              subtitulo: _alumnoSeleccionado!.codigo,
              icon: Icons.person,
              colorBase: Colors.blue,
              onDelete: () => setState(() => _alumnoSeleccionado = null),
            ),

          const SizedBox(height: 30),

          // 3. FECHA
          const _SectionHeader(title: "3. Fecha de Entrega", icon: Icons.calendar_today), // Agregado const
          InkWell(
            onTap: _seleccionarFecha,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.onSurface.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(12),
                color: theme.cardTheme.color,
              ),
              child: Row(
                children: [
                  Icon(Icons.event, color: colorScheme.secondary),
                  const SizedBox(width: 15),
                  Text(
                    DateFormat('EEEE d, MMMM yyyy', 'es').format(_fechaEntrega),
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 40),

          // BOTÓN
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              onPressed: (_libroSeleccionado != null && _alumnoSeleccionado != null) 
                  ? _procesarPrestamo 
                  : null,
              icon: const Icon(Icons.save),
              label: const Text("REGISTRAR PRÉSTAMO", style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurface.withOpacity(0.6)),
          const SizedBox(width: 8),
          Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}