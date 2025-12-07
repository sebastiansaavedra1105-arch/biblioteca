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
    
    // Accedemos al tema
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      // backgroundColor: colorScheme.surface, // Ya lo maneja el tema por defecto
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(
            esEdicion ? Icons.edit : Icons.person_add,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Text(
            esEdicion ? "Editar Alumno" : "Registrar Alumno",
            style: TextStyle(color: colorScheme.onSurface),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _input("DNI / Código", _codigoCtrl, req: true, icon: Icons.badge),
              const SizedBox(height: 15),
              _input("Nombre Completo", _nombreCtrl, req: true, icon: Icons.person),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(child: _input("Grado", _gradoCtrl, req: true, icon: Icons.grade)),
                  const SizedBox(width: 10),
                  Expanded(child: _input("Sección", _seccionCtrl, req: true, icon: Icons.class_)),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), 
          child: Text(
            "Cancelar", 
            style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6))
          )
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: Colors.white,
          ),
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
          child: const Text("Guardar"),
        )
      ],
    );
  }

  // Widget de input optimizado que usa el tema global
  Widget _input(String label, TextEditingController ctrl, {bool req = false, required IconData icon}) {
    // Nota: Como definimos inputDecorationTheme en AppTheme, 
    // no necesitamos redefinir bordes ni colores aquí. ¡Esa es la magia!
    return TextFormField(
      controller: ctrl,
      validator: req ? (v) => v!.isEmpty ? 'Requerido' : null : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
      ),
    );
  }
}