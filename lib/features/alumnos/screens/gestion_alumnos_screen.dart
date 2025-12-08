import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/alumnos_provider.dart';
// Importamos el archivo correcto
import '../widgets/alumno_dialog.dart'; 
import '../../auth/providers/auth_provider.dart';
import '../../../core/models/alumno.dart';

class GestionAlumnosScreen extends StatefulWidget {
  const GestionAlumnosScreen({super.key});

  @override
  State<GestionAlumnosScreen> createState() => _GestionAlumnosScreenState();
}

class _GestionAlumnosScreenState extends State<GestionAlumnosScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _filtro = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AlumnosProvider>().cargarAlumnos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AlumnosProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authProvider = context.read<AuthProvider>();
    final bool esSoloLectura = authProvider.esDirector; 

    // Filtro rápido
    final alumnosFiltrados = provider.alumnos.where((a) {
      final query = _filtro.toLowerCase();
      return a.nombreCompleto.toLowerCase().contains(query) || 
             a.codigo.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      body: Column(
        children: [
          // 1. BARRA DE BÚSQUEDA Y BOTÓN AGREGAR
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (val) => setState(() => _filtro = val),
                    decoration: InputDecoration(
                      hintText: "Buscar alumno (Nombre o DNI)...",
                      prefixIcon: Icon(Icons.search, color: colorScheme.primary),
                      suffixIcon: _filtro.isNotEmpty 
                        ? IconButton(
                            icon: const Icon(Icons.clear), 
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _filtro = '');
                            }
                          )
                        : null,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Solo mostramos el botón de agregar si NO es director
                if (!esSoloLectura)
                  ElevatedButton.icon(
                    onPressed: () => _navegarFormularioAlumno(), // CORREGIDO AQUÍ
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    ),
                    icon: const Icon(Icons.person_add),
                    label: const Text("Nuevo"),
                  ),
              ],
            ),
          ),

          // 2. LISTA DE ALUMNOS
          Expanded(
            child: provider.isLoading
              ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
              : alumnosFiltrados.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_off_outlined, size: 60, color: colorScheme.onSurface.withOpacity(0.3)),
                        const SizedBox(height: 10),
                        Text("No se encontraron alumnos", style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5))),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: alumnosFiltrados.length,
                    itemBuilder: (context, index) {
                      final alumno = alumnosFiltrados[index];
                      final tieneSancion = alumno.strikes > 0;
                      final vetado = alumno.vetadoHasta != null && DateTime.now().isBefore(alumno.vetadoHasta!);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: vetado 
                              ? colorScheme.error 
                              : colorScheme.outline.withOpacity(0.1)
                          )
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: vetado 
                              ? colorScheme.error.withOpacity(0.2) 
                              : colorScheme.primary.withOpacity(0.1),
                            child: Icon(
                              vetado ? Icons.block : Icons.person, 
                              color: vetado ? colorScheme.error : colorScheme.primary
                            ),
                          ),
                          title: Text(
                            alumno.nombreCompleto,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("${alumno.grado} - ${alumno.seccion} • ${alumno.codigo}"),
                              if (tieneSancion)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    children: [
                                      Icon(Icons.warning_amber_rounded, size: 14, color: colorScheme.error),
                                      const SizedBox(width: 4),
                                      Text(
                                        "Strikes: ${alumno.strikes} ${vetado ? '(VETADO)' : ''}",
                                        style: TextStyle(
                                          color: colorScheme.error, 
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                            ],
                          ),
                          trailing: esSoloLectura
                            ? null 
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined),
                                    color: colorScheme.primary,
                                    tooltip: "Editar",
                                    onPressed: () => _editarAlumno(alumno),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    color: colorScheme.error,
                                    tooltip: "Eliminar",
                                    onPressed: () => _confirmarBorrado(context, alumno),
                                  ),
                                ],
                              ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // --- MÉTODOS DE NAVEGACIÓN Y ACCIÓN ---

  void _navegarFormularioAlumno([Alumno? alumno]) {
    // CORREGIDO: Usamos Navigator.push y el nombre correcto de la clase
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AgregarAlumnoScreen(alumno: alumno),
      ),
    ).then((_) {
      // Recargamos al volver por si hubo cambios
      context.read<AlumnosProvider>().cargarAlumnos();
    });
  }

  void _editarAlumno(Alumno alumno) {
    _navegarFormularioAlumno(alumno);
  }

  void _confirmarBorrado(BuildContext context, Alumno alumno) {
    final messenger = ScaffoldMessenger.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: const Text("¿Eliminar Alumno?"),
        content: Text("Se eliminará a '${alumno.nombreCompleto}' del sistema.\nEsta acción no se puede deshacer."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: colorScheme.error),
            onPressed: () async {
              Navigator.pop(ctx);
              
              final resultado = await context.read<AlumnosProvider>().borrarAlumno(alumno.id!);
              
              if (context.mounted) {
                if (resultado['success']) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(resultado['message']),
                      backgroundColor: Colors.green,
                    )
                  );
                } else {
                  _mostrarAlertaBloqueo(context, resultado['message']);
                }
              }
            },
            child: const Text("Eliminar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _mostrarAlertaBloqueo(BuildContext context, String mensaje) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Row(children: [
          Icon(Icons.block, color: colorScheme.error),
          const SizedBox(width: 10),
          const Text("Acción Denegada")
        ]),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Entendido"),
          )
        ],
      )
    );
  }
}