import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/alumno.dart';
import '../providers/alumnos_provider.dart';

class AlumnoDialog extends StatefulWidget {
  final Alumno? alumno; // Si es null, es nuevo. Si no, es edición.

  const AlumnoDialog({super.key, this.alumno});

  @override
  State<AlumnoDialog> createState() => _AlumnoDialogState();
}

class _AlumnoDialogState extends State<AlumnoDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _codigoCtrl;
  late TextEditingController _nombreCtrl;
  late TextEditingController _gradoCtrl;
  late TextEditingController _seccionCtrl;

  @override
  void initState() {
    super.initState();
    _codigoCtrl = TextEditingController(text: widget.alumno?.codigo ?? '');
    _nombreCtrl = TextEditingController(text: widget.alumno?.nombreCompleto ?? '');
    _gradoCtrl = TextEditingController(text: widget.alumno?.grado ?? '');
    _seccionCtrl = TextEditingController(text: widget.alumno?.seccion ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.alumno != null;
    final dorado = Theme.of(context).colorScheme.primary;

    return AlertDialog(
      backgroundColor: const Color(0xFF252525),
      title: Text(esEdicion ? "Editar Alumno" : "Registrar Alumno", style: const TextStyle(color: Colors.white)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _input("Código / DNI *", _codigoCtrl, req: true),
              const SizedBox(height: 10),
              _input("Nombre Completo *", _nombreCtrl, req: true),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _input("Grado", _gradoCtrl)),
                  const SizedBox(width: 10),
                  Expanded(child: _input("Sección", _seccionCtrl)),
                ],
              ),
              
              if (esEdicion && (widget.alumno!.strikes > 0)) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.red),
                      const SizedBox(width: 10),
                      Text("Faltas Acumuladas: ${widget.alumno!.strikes}", style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                )
              ]
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar", style: TextStyle(color: Colors.grey))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: dorado),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final nuevoAlumno = Alumno(
                id: widget.alumno?.id,
                codigo: _codigoCtrl.text.trim(),
                nombreCompleto: _nombreCtrl.text.trim(),
                grado: _gradoCtrl.text.trim(),
                seccion: _seccionCtrl.text.trim(),
                strikes: widget.alumno?.strikes ?? 0,
                vetadoHasta: widget.alumno?.vetadoHasta,
              );

              context.read<AlumnosProvider>().guardarAlumno(nuevoAlumno, esEdicion: esEdicion);
              Navigator.pop(context);
            }
          },
          child: const Text("Guardar", style: TextStyle(color: Colors.black)),
        )
      ],
    );
  }

  Widget _input(String label, TextEditingController ctrl, {bool req = false}) {
    return TextFormField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      validator: req ? (v) => v!.isEmpty ? 'Requerido' : null : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true, fillColor: Colors.black26,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}