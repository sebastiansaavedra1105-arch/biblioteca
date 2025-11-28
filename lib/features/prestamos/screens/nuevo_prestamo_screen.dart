import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/libro.dart';
import '../../dashboard/providers/libros_provider.dart';

class NuevoPrestamoScreen extends StatefulWidget {
  const NuevoPrestamoScreen({super.key});

  @override
  State<NuevoPrestamoScreen> createState() => _NuevoPrestamoScreenState();
}

class _NuevoPrestamoScreenState extends State<NuevoPrestamoScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores
  final _codLibroCtrl = TextEditingController();
  final _codAlumnoCtrl = TextEditingController();
  final _nomAlumnoCtrl = TextEditingController();
  DateTime _fecha = DateTime.now().add(const Duration(days: 7));

  // Estado Local
  Libro? _libro;
  String? _errorLibro;
  bool _buscando = false;

  Future<void> _buscarLibro() async {
    if (_codLibroCtrl.text.isEmpty) return;
    setState(() { _buscando = true; _errorLibro = null; _libro = null; });

    final encontrado = await context.read<LibrosProvider>().buscarLibroPorCodigo(_codLibroCtrl.text);

    setState(() {
      _buscando = false;
      if (encontrado == null) {
        _errorLibro = 'Libro no encontrado';
      } else if (encontrado.copiasDisponibles < 1) {
        _errorLibro = 'Sin stock disponible';
      } else {
        _libro = encontrado;
      }
    });
  }

  Future<void> _procesarPrestamo() async {
    if (!_formKey.currentState!.validate() || _libro == null) return;

    final exito = await context.read<LibrosProvider>().registrarPrestamo(
      libro: _libro!,
      codigoAlumno: _codAlumnoCtrl.text,
      nombreAlumno: _nomAlumnoCtrl.text,
      fechaEntrega: _fecha,
    );

    if (mounted && exito) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ Préstamo registrado: ${_libro!.titulo}'), backgroundColor: Colors.green));
      _limpiar();
    }
  }

  void _limpiar() {
    _codLibroCtrl.clear(); _codAlumnoCtrl.clear(); _nomAlumnoCtrl.clear();
    setState(() { _libro = null; _fecha = DateTime.now().add(const Duration(days: 7)); });
  }

  @override
  Widget build(BuildContext context) {
    final dorado = Theme.of(context).colorScheme.primary;
    final loading = context.select<LibrosProvider, bool>((p) => p.isLoading);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // SECCION BUSCAR LIBRO
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _codLibroCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: _deco('Escanear Código Libro', Icons.qr_code_scanner, dorado),
                    onFieldSubmitted: (_) => _buscarLibro(),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  style: IconButton.styleFrom(backgroundColor: dorado, foregroundColor: Colors.black),
                  icon: _buscando 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                    : const Icon(Icons.search),
                  onPressed: _buscarLibro,
                )
              ],
            ),
            
            if (_errorLibro != null) 
              Padding(padding: const EdgeInsets.all(8.0), child: Text(_errorLibro!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),

            if (_libro != null)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 20),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1), 
                  border: Border.all(color: Colors.green.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(10)
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_libro!.titulo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text("Autor: ${_libro!.autor}  •  Stock: ${_libro!.copiasDisponibles}", style: TextStyle(color: Colors.grey[400])),
                ]),
              ),

            const SizedBox(height: 20),
            const Text("DATOS DEL ALUMNO", style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1.5)),
            const SizedBox(height: 10),

            _Input(label: 'Código / DNI', ctrl: _codAlumnoCtrl, icon: Icons.badge),
            const SizedBox(height: 15),
            _Input(label: 'Nombre Completo', ctrl: _nomAlumnoCtrl, icon: Icons.person),
            
            const SizedBox(height: 20),
            
            // SELECTOR DE FECHA
            InkWell(
              onTap: () async {
                final d = await showDatePicker(
                  context: context, initialDate: _fecha, firstDate: DateTime.now(), lastDate: DateTime(2030),
                  builder: (c, child) => Theme(data: Theme.of(c).copyWith(colorScheme: ColorScheme.dark(primary: dorado, onPrimary: Colors.black)), child: child!)
                );
                if (d != null) setState(() => _fecha = d);
              },
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white24)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Fecha de Entrega", style: TextStyle(color: Colors.grey[400])),
                    Row(children: [
                      Icon(Icons.calendar_today, color: dorado, size: 18),
                      const SizedBox(width: 10),
                      Text("${_fecha.day}/${_fecha.month}/${_fecha.year}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                    ])
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: dorado, foregroundColor: Colors.black, minimumSize: const Size.fromHeight(50)
              ),
              onPressed: (_libro != null && !loading) ? _procesarPrestamo : null,
              icon: loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check_circle),
              label: Text(loading ? "PROCESANDO..." : "CONFIRMAR PRÉSTAMO", style: const TextStyle(fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }
}

// Widgets y decoraciones auxiliares para mantener el código corto
class _Input extends StatelessWidget {
  final String label; final TextEditingController ctrl; final IconData icon;
  const _Input({required this.label, required this.ctrl, required this.icon});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl, style: const TextStyle(color: Colors.white),
      validator: (v) => v!.isEmpty ? 'Requerido' : null,
      decoration: _deco(label, icon, Theme.of(context).colorScheme.primary),
    );
  }
}

InputDecoration _deco(String label, IconData icon, Color color) {
  return InputDecoration(
    labelText: label, prefixIcon: Icon(icon, color: Colors.grey),
    filled: true, fillColor: Colors.white10,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: color)),
  );
}