import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/models/libro.dart';
import '../../../core/models/alumno.dart';
import '../../dashboard/providers/libros_provider.dart';
import '../../alumnos/providers/alumnos_provider.dart';
// Eliminado import de alumno_dialog porque quitamos el botón de crear aquí

class NuevoPrestamoScreen extends StatefulWidget {
  const NuevoPrestamoScreen({super.key});

  @override
  State<NuevoPrestamoScreen> createState() => _NuevoPrestamoScreenState();
}

class _NuevoPrestamoScreenState extends State<NuevoPrestamoScreen> {
  final _libroSearchCtrl = TextEditingController();
  final _alumnoSearchCtrl = TextEditingController();

  Libro? _libroSeleccionado;
  Alumno? _alumnoSeleccionado;
  DateTime _fechaEntrega = DateTime.now().add(const Duration(days: 3));

  List<Alumno> _sugerenciasAlumnos = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AlumnosProvider>().cargarAlumnos();
    });
  }

  void _buscarLibro() async {
    final codigo = _libroSearchCtrl.text.trim();
    if (codigo.isEmpty) return;

    final provider = context.read<LibrosProvider>();
    try {
      final libro = provider.libros.firstWhere(
        (l) => l.codigoBarras == codigo,
        orElse: () => Libro(id: 'temp', codigoBarras: '', titulo: '', autor: '', isbn: '', anio: 0, editorial: '', categoria: '', copias: 0, copiasDisponibles: 0, estado: '', observacion: '')
      );

      if (libro.id != 'temp') {
        setState(() => _libroSeleccionado = libro);
        _libroSearchCtrl.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Libro no encontrado")));
      }
    } catch (e) {
      // Ignorar
    }
  }

  void _filtrarAlumnos(String query) {
    if (query.isEmpty) {
      setState(() => _sugerenciasAlumnos = []);
      return;
    }
    final todos = context.read<AlumnosProvider>().alumnos;
    setState(() {
      _sugerenciasAlumnos = todos.where((a) => 
        a.nombreCompleto.toLowerCase().contains(query.toLowerCase()) || 
        a.codigo.toLowerCase().contains(query.toLowerCase())
      ).take(5).toList(); 
    });
  }

  void _seleccionarAlumno(Alumno alumno) {
    setState(() {
      _alumnoSeleccionado = alumno;
      _sugerenciasAlumnos = [];
      _alumnoSearchCtrl.clear();
    });
  }

  void _registrarPrestamo() async {
    if (_libroSeleccionado == null || _alumnoSeleccionado == null) return;

    if (_alumnoSeleccionado!.estaVetado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⛔ EL ALUMNO ESTÁ VETADO. No se puede prestar."), backgroundColor: Colors.red)
      );
      return;
    }

    if (_libroSeleccionado!.copiasDisponibles <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ No hay copias disponibles de este libro."), backgroundColor: Colors.orange)
      );
      return;
    }

    final exito = await context.read<LibrosProvider>().registrarPrestamo(
      libro: _libroSeleccionado!,
      alumno: _alumnoSeleccionado!,
      fechaEntrega: _fechaEntrega,
    );

    if (exito && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Préstamo Registrado"), backgroundColor: Colors.green));
      setState(() {
        _libroSeleccionado = null;
        _alumnoSeleccionado = null;
        _libroSearchCtrl.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dorado = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- 1. SECCIÓN LIBRO ---
            const _HeaderSeccion("1. Libro a Prestar", Icons.book),
            if (_libroSeleccionado == null)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _libroSearchCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDeco("Escanear Código de Barras", Icons.qr_code_scanner),
                      onSubmitted: (_) => _buscarLibro(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: Icon(Icons.search, color: dorado),
                    onPressed: _buscarLibro,
                    style: IconButton.styleFrom(backgroundColor: Colors.grey[900]),
                  )
                ],
              )
            else
              _TarjetaSeleccion(
                titulo: _libroSeleccionado!.titulo,
                subtitulo: "Stock: ${_libroSeleccionado!.copiasDisponibles}",
                icon: Icons.book,
                color: _libroSeleccionado!.copiasDisponibles > 0 ? Colors.green : Colors.red,
                onDelete: () => setState(() => _libroSeleccionado = null),
              ),

            const SizedBox(height: 30),

            // --- 2. SECCIÓN ALUMNO ---
            // Eliminamos el botón de "Nuevo Alumno" de aquí
            const _HeaderSeccion("2. Alumno Solicitante", Icons.person),
            
            if (_alumnoSeleccionado == null) ...[
              TextField(
                controller: _alumnoSearchCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDeco("Buscar por Nombre o Código...", Icons.search),
                onChanged: _filtrarAlumnos,
              ),
              if (_sugerenciasAlumnos.isNotEmpty)
                Container(
                  color: Colors.grey[900],
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _sugerenciasAlumnos.length,
                    itemBuilder: (ctx, i) {
                      final a = _sugerenciasAlumnos[i];
                      return ListTile(
                        leading: Icon(a.estaVetado ? Icons.block : Icons.person, color: a.estaVetado ? Colors.red : Colors.white),
                        title: Text(a.nombreCompleto, style: const TextStyle(color: Colors.white)),
                        subtitle: Text(a.codigo, style: const TextStyle(color: Colors.grey)),
                        onTap: () => _seleccionarAlumno(a),
                      );
                    },
                  ),
                ),
            ] else
              _TarjetaSeleccion(
                titulo: _alumnoSeleccionado!.nombreCompleto,
                subtitulo: _alumnoSeleccionado!.estaVetado 
                    ? "VETADO HASTA: ${DateFormat('dd/MM/yyyy').format(_alumnoSeleccionado!.vetadoHasta!)}"
                    : "Código: ${_alumnoSeleccionado!.codigo} | Strikes: ${_alumnoSeleccionado!.strikes}",
                icon: Icons.person,
                color: _alumnoSeleccionado!.estaVetado ? Colors.red : dorado,
                onDelete: () => setState(() => _alumnoSeleccionado = null),
              ),

            const SizedBox(height: 30),

            // --- 3. FECHA ---
            const _HeaderSeccion("3. Fecha de Entrega", Icons.calendar_today),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context, 
                  initialDate: _fechaEntrega, 
                  firstDate: DateTime.now(), 
                  lastDate: DateTime.now().add(const Duration(days: 30))
                );
                if (picked != null) setState(() => _fechaEntrega = picked);
              },
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(DateFormat('dd/MM/yyyy').format(_fechaEntrega), style: const TextStyle(color: Colors.white, fontSize: 16)),
                    const Icon(Icons.edit, color: Colors.grey),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            SizedBox(
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: dorado),
                onPressed: _libroSeleccionado != null && _alumnoSeleccionado != null 
                    ? _registrarPrestamo 
                    : null, 
                child: const Text("REGISTRAR PRÉSTAMO", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey),
      prefixIcon: Icon(icon, color: Colors.grey),
      filled: true, fillColor: const Color(0xFF1E1E1E),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
    );
  }
}

class _HeaderSeccion extends StatelessWidget {
  final String titulo; final IconData icon;
  const _HeaderSeccion(this.titulo, this.icon);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [Icon(icon, color: Colors.white70, size: 20), const SizedBox(width: 10), Text(titulo, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))]),
    );
  }
}

class _TarjetaSeleccion extends StatelessWidget {
  final String titulo; final String subtitulo; final IconData icon; final Color color; final VoidCallback onDelete;
  const _TarjetaSeleccion({required this.titulo, required this.subtitulo, required this.icon, required this.color, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: color)),
      child: ListTile(
        leading: Icon(icon, color: color, size: 30),
        title: Text(titulo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitulo, style: const TextStyle(color: Colors.white70)),
        trailing: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: onDelete),
      ),
    );
  }
}