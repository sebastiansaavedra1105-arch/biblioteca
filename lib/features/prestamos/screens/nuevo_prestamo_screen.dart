import 'package:flutter/material.dart';
import '../../../core/database/database_service.dart';

class NuevoPrestamoScreen extends StatefulWidget {
  const NuevoPrestamoScreen({super.key});

  @override
  State<NuevoPrestamoScreen> createState() => _NuevoPrestamoScreenState();
}

class _NuevoPrestamoScreenState extends State<NuevoPrestamoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codigoLibroController = TextEditingController();
  final _codigoAlumnoController = TextEditingController();
  final _nombreAlumnoController = TextEditingController();
  DateTime _fechaEntrega = DateTime.now().add(const Duration(days: 14));

  // Variables para controlar el estado del libro buscado
  Map<String, dynamic>? _libroEncontrado;
  bool _buscando = false;
  String _mensajeErrorLibro = '';

  // 1. Lógica para buscar libro
  Future<void> _buscarLibro() async {
    if (_codigoLibroController.text.isEmpty) return;

    setState(() {
      _buscando = true;
      _mensajeErrorLibro = '';
      _libroEncontrado = null;
    });

    final libro = await DatabaseService().buscarLibroPorCodigo(_codigoLibroController.text);

    setState(() {
      _buscando = false;
      if (libro != null) {
        if (libro['copias_disponibles'] > 0) {
          _libroEncontrado = libro;
        } else {
          _mensajeErrorLibro = 'El libro "${libro['titulo']}" no tiene copias disponibles.';
        }
      } else {
        _mensajeErrorLibro = 'Libro no encontrado con ese código.';
      }
    });
  }

  // 2. Lógica para guardar préstamo
  Future<void> _guardarPrestamo() async {
    if (!_formKey.currentState!.validate()) return;
    if (_libroEncontrado == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debes buscar y seleccionar un libro válido primero.')));
      return;
    }

    final exito = await DatabaseService().registrarPrestamo(
      libroId: _libroEncontrado!['id'],
      titulo: _libroEncontrado!['titulo'],
      alumno: _codigoAlumnoController.text,
      nombreAlumno: _nombreAlumnoController.text,
      entrega: _fechaEntrega,
    );

    if (exito) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Préstamo registrado: ${_libroEncontrado!['titulo']}'),
          backgroundColor: Colors.green,
        )
      );
      Navigator.pop(context, true); // Retorna true para actualizar el dashboard
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al guardar en base de datos')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorDorado = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('REGISTRAR PRÉSTAMO')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- SECCIÓN BUSCADOR DE LIBRO ---
              Text('📖 Datos del Libro', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorDorado)),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _codigoLibroController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Código de Barras (Ej: LIB001)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.qr_code),
                      ),
                      onFieldSubmitted: (_) => _buscarLibro(), // Buscar al dar Enter
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorDorado,
                      fixedSize: const Size(60, 60),
                      padding: EdgeInsets.zero
                    ),
                    onPressed: _buscando ? null : _buscarLibro,
                    child: _buscando 
                      ? const CircularProgressIndicator(color: Colors.black) 
                      : const Icon(Icons.search, color: Colors.black, size: 30),
                  )
                ],
              ),
              
              // Mostrar resultado de búsqueda
              if (_mensajeErrorLibro.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(_mensajeErrorLibro, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ),
                
              if (_libroEncontrado != null)
                Container(
                  margin: const EdgeInsets.only(top: 15),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    border: Border.all(color: Colors.green),
                    borderRadius: BorderRadius.circular(10)
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("✅ ${_libroEncontrado!['titulo']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                      Text("Autor: ${_libroEncontrado!['autor']}"),
                      Text("Disponibles: ${_libroEncontrado!['copias_disponibles']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),

              const SizedBox(height: 30),
              
              // --- SECCIÓN ALUMNO ---
              Text('👤 Datos del Alumno', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorDorado)),
              const SizedBox(height: 15),
              TextFormField(
                controller: _codigoAlumnoController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Código Alumno / DNI', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _nombreAlumnoController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Nombre Completo', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Requerido' : null,
              ),
              
              const SizedBox(height: 20),
              // Selector de fecha
              ListTile(
                title: const Text('Fecha de Entrega', style: TextStyle(color: Colors.grey)),
                subtitle: Text(
                  "${_fechaEntrega.day}/${_fechaEntrega.month}/${_fechaEntrega.year}", 
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                ),
                trailing: Icon(Icons.calendar_today, color: colorDorado),
                tileColor: Colors.grey[900],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _fechaEntrega,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2030),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.dark(primary: colorDorado, onPrimary: Colors.black),
                        ),
                        child: child!,
                      );
                    }
                  );
                  if (picked != null) setState(() => _fechaEntrega = picked);
                },
              ),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorDorado,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: _libroEncontrado != null ? _guardarPrestamo : null, // Solo habilitado si hay libro
                  icon: const Icon(Icons.save),
                  label: const Text('CONFIRMAR PRÉSTAMO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}