import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/alumnos_provider.dart';
import '../widgets/alumno_dialog.dart'; // Importamos la nueva pantalla (aunque el archivo se llame igual)
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
      // NO HAY APPBAR NI HEADER GIGANTE AQUÍ (El título lo pone el dashboard padre)
      
      body: Column(
        children: [
          // Espacio superior para separar del header del dashboard
          const SizedBox(height: 20),

          // --- BUSCADOR ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (val) => setState(() => _filtro = val),
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: "Buscar alumno por nombre o DNI...",
                hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
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
                fillColor: theme.cardTheme.color,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // --- LISTA DE ALUMNOS ---
          Expanded(
            child: provider.isLoading
                ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
                : alumnosFiltrados.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.group_off, size: 60, color: colorScheme.onSurface.withOpacity(0.2)),
                            const SizedBox(height: 10),
                            Text(
                              "No se encontraron alumnos",
                              style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
                            )
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: alumnosFiltrados.length,
                        itemBuilder: (context, index) {
                          final alumno = alumnosFiltrados[index];
                          return _AlumnoCard(
                            alumno: alumno,
                            esSoloLectura: esSoloLectura,
                          );
                        },
                      ),
          ),
        ],
      ),

      // --- BOTÓN FLOTANTE (Solo si NO es director) ---
      floatingActionButton: esSoloLectura 
          ? null 
          : FloatingActionButton.extended(
              // NAVEGAMOS A LA PANTALLA COMPLETA
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AgregarAlumnoScreen())
              ),
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.person_add),
              label: const Text("Nuevo Alumno"),
            ),
    );
  }
}

// --------------------------------------------------------------------------
// TARJETA DE ALUMNO
// --------------------------------------------------------------------------
class _AlumnoCard extends StatelessWidget {
  final Alumno alumno;
  final bool esSoloLectura;

  const _AlumnoCard({
    required this.alumno,
    required this.esSoloLectura,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: theme.cardTheme.color,
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
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.badge, size: 14, color: colorScheme.onSurface.withOpacity(0.5)),
                const SizedBox(width: 4),
                Text(
                  alumno.codigo, 
                  style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7))
                ),
                const SizedBox(width: 15),
                Icon(Icons.class_, size: 14, color: colorScheme.onSurface.withOpacity(0.5)),
                const SizedBox(width: 4),
                Text(
                  "${alumno.grado} - ${alumno.seccion}", 
                  style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7))
                ),
              ],
            ),
            if (alumno.vetadoHasta != null && alumno.vetadoHasta!.isAfter(DateTime.now()))
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  "⛔ VETADO",
                  style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              )
          ],
        ),

        // MENÚ DE ACCIONES
        trailing: esSoloLectura 
            ? null 
            : PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: colorScheme.onSurface.withOpacity(0.6)),
                color: colorScheme.surface,
                onSelected: (value) {
                  if (value == 'editar') {
                    // NAVEGAMOS A LA PANTALLA DE EDICIÓN
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AgregarAlumnoScreen(alumno: alumno)
                      )
                    );
                  } else if (value == 'eliminar') {
                    _confirmarEliminacion(context);
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

  void _confirmarEliminacion(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text("Confirmar Eliminación", style: TextStyle(color: colorScheme.onSurface)),
        content: Text(
          "¿Estás seguro de eliminar a ${alumno.nombreCompleto}?",
          style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
        ),
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