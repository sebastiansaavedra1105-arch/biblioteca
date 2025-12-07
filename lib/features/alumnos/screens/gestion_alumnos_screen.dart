import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/alumnos_provider.dart';
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
    final esDirector = context.read<AuthProvider>().esDirector;
    
    // Accedemos al tema global
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Filtro rápido en memoria
    final alumnosFiltrados = provider.alumnos.where((a) {
      final query = _filtro.toLowerCase();
      return a.nombreCompleto.toLowerCase().contains(query) ||
             a.codigo.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      // El fondo ya lo maneja el tema global
      body: Column(
        children: [
          // --- 1. HEADER Y BUSCADOR ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.school, color: colorScheme.primary, size: 28),
                    const SizedBox(width: 10),
                    Text(
                      "Directorio de Alumnos",
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                
                // Buscador
                TextField(
                  controller: _searchCtrl,
                  onChanged: (val) => setState(() => _filtro = val),
                  decoration: InputDecoration(
                    hintText: "Buscar por Nombre o DNI...",
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
                    filled: true,
                    // Color de fondo del input según tema
                    fillColor: theme.brightness == Brightness.dark 
                        ? Colors.grey[900] 
                        : Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- 2. LISTA DE ALUMNOS ---
          Expanded(
            child: provider.isLoading
                ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
                : alumnosFiltrados.isEmpty
                    ? _buildEmptyState(theme)
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: alumnosFiltrados.length,
                        itemBuilder: (context, index) {
                          final alumno = alumnosFiltrados[index];
                          return _AlumnoCard(
                            alumno: alumno, 
                            esDirector: esDirector,
                            colorScheme: colorScheme,
                            textTheme: textTheme,
                          );
                        },
                      ),
          ),
        ],
      ),

      // BOTÓN FLOTANTE
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => const AlumnoDialog(),
          );
        },
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text("Nuevo Alumno"),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_off, size: 60, color: theme.colorScheme.onSurface.withOpacity(0.3)),
          const SizedBox(height: 10),
          Text(
            "No se encontraron alumnos", 
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5)
            )
          ),
        ],
      ),
    );
  }
}

// Widget Interno para la tarjeta (Limpio y reutilizable)
class _AlumnoCard extends StatelessWidget {
  final Alumno alumno;
  final bool esDirector;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _AlumnoCard({
    required this.alumno,
    required this.esDirector,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        // AVATAR
        leading: CircleAvatar(
          backgroundColor: colorScheme.primary.withOpacity(0.1),
          child: Text(
            alumno.nombreCompleto.isNotEmpty ? alumno.nombreCompleto[0].toUpperCase() : '?',
            style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
          ),
        ),
        
        // DATOS
        title: Text(
          alumno.nombreCompleto,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.badge, size: 14, color: colorScheme.secondary.withOpacity(0.6)),
                const SizedBox(width: 4),
                Text(alumno.codigo, style: textTheme.bodySmall),
                const SizedBox(width: 15),
                Icon(Icons.class_, size: 14, color: colorScheme.secondary.withOpacity(0.6)),
                const SizedBox(width: 4),
                Text("${alumno.grado} - ${alumno.seccion}", style: textTheme.bodySmall),
              ],
            ),
          ],
        ),

        // ACCIONES
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: colorScheme.onSurface.withOpacity(0.6)),
          onSelected: (value) async {
            if (value == 'editar') {
              showDialog(
                context: context,
                builder: (_) => AlumnoDialog(alumno: alumno),
              );
            } else if (value == 'eliminar') {
              _confirmarEliminacion(context, scaffoldMessenger);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'editar',
              child: Row(
                children: [
                  Icon(Icons.edit, color: colorScheme.primary, size: 20),
                  const SizedBox(width: 10),
                  const Text("Editar"),
                ],
              ),
            ),
            if (esDirector) 
              PopupMenuItem(
                value: 'eliminar',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: colorScheme.error, size: 20),
                    const SizedBox(width: 10),
                    Text("Eliminar", style: TextStyle(color: colorScheme.error)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

 void _confirmarEliminacion(BuildContext context, ScaffoldMessengerState messenger) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmar Eliminación"),
        content: Text("¿Estás seguro de eliminar a ${alumno.nombreCompleto}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          TextButton(
            onPressed: () async {
              // 1. Cerramos el diálogo de confirmación inmediatamente
              Navigator.pop(ctx); 
              
              // 2. Ejecutamos el borrado usando el context PADRE
              final res = await context.read<AlumnosProvider>().borrarAlumno(alumno.id!);
              
              // --- CORRECCIÓN DEL ASYNC GAP ---
              // Verificamos si la pantalla padre (GestionAlumnosScreen) sigue viva
              if (!context.mounted) return;

              if (res['success']) {
                messenger.showSnackBar(SnackBar(
                  content: Text(res['message']),
                  backgroundColor: Colors.green,
                ));
              } else {
                _mostrarAlertaBloqueo(context, res['message']);
              }
            },
            child: Text("Eliminar", style: TextStyle(color: colorScheme.error)),
          ),
        ],
      ),
    );
  }

  void _mostrarAlertaBloqueo(BuildContext context, String mensaje) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
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