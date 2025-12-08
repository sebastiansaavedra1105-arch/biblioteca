import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/alumno.dart';
import '../providers/alumnos_provider.dart';

// Ahora es una Pantalla Completa, no un Diálogo pequeño
class AgregarAlumnoScreen extends StatefulWidget {
  final Alumno? alumno; // Si es null, es nuevo. Si no, es edición.

  const AgregarAlumnoScreen({super.key, this.alumno});

  @override
  State<AgregarAlumnoScreen> createState() => _AgregarAlumnoScreenState();
}

class _AgregarAlumnoScreenState extends State<AgregarAlumnoScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores
  late TextEditingController _codigoCtrl;
  late TextEditingController _nombreCtrl;
  late TextEditingController _gradoCtrl;
  late TextEditingController _seccionCtrl;

  @override
  void initState() {
    super.initState();
    // Inicializar datos
    _codigoCtrl = TextEditingController(text: widget.alumno?.codigo ?? '');
    _nombreCtrl = TextEditingController(text: widget.alumno?.nombreCompleto ?? '');
    _gradoCtrl = TextEditingController(text: widget.alumno?.grado ?? '');
    _seccionCtrl = TextEditingController(text: widget.alumno?.seccion ?? '');
  }

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _nombreCtrl.dispose();
    _gradoCtrl.dispose();
    _seccionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.alumno != null;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(esEdicion ? "Editar Alumno" : "Registrar Alumno"),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor, // Se funde con el fondo
        foregroundColor: colorScheme.onSurface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- ICONO DE CABECERA ---
              Center(
                child: Container(
                  height: 100,
                  width: 100,
                  margin: const EdgeInsets.only(bottom: 30),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.primary.withOpacity(0.5), width: 2),
                  ),
                  child: Icon(Icons.person, size: 50, color: colorScheme.primary),
                ),
              ),

              Text(
                "Información del Estudiante",
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary),
              ),
              const SizedBox(height: 20),

              // --- INPUTS ---
              _InputTexto(
                label: "DNI / Código de Matrícula",
                ctrl: _codigoCtrl,
                icon: Icons.badge,
                req: true,
              ),
              const SizedBox(height: 20),

              _InputTexto(
                label: "Nombre Completo",
                ctrl: _nombreCtrl,
                icon: Icons.person_outline,
                req: true,
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: _InputTexto(
                      label: "Grado",
                      ctrl: _gradoCtrl,
                      icon: Icons.grade,
                      req: true,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _InputTexto(
                      label: "Sección",
                      ctrl: _seccionCtrl,
                      icon: Icons.class_outlined,
                      req: true,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),
              
              // --- BOTÓN GUARDAR ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _guardar,
                  icon: const Icon(Icons.save),
                  label: Text(
                    esEdicion ? "ACTUALIZAR DATOS" : "REGISTRAR ALUMNO",
                    style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _guardar() {
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

      // Guardamos usando el provider
      context.read<AlumnosProvider>().guardarAlumno(
        nuevoAlumno, 
        esEdicion: widget.alumno != null
      );
      
      Navigator.pop(context); // Volvemos a la lista
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.alumno != null ? "Alumno actualizado" : "Alumno registrado"),
          backgroundColor: Colors.green,
        )
      );
    }
  }
}

// Widget de Input idéntico al de libros
class _InputTexto extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final IconData icon;
  final bool req;

  const _InputTexto({
    required this.label, 
    required this.ctrl, 
    required this.icon, 
    this.req = false
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      validator: req ? (v) => v!.isEmpty ? 'Requerido' : null : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 22),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        // El resto del estilo lo toma del Theme global
      ),
    );
  }
}