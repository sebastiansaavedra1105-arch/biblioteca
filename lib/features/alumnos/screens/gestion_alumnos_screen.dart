import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/alumnos_provider.dart';
import '../widgets/alumno_dialog.dart';
// Importamos AuthProvider para verificar permisos
import '../../auth/providers/auth_provider.dart';

class GestionAlumnosScreen extends StatefulWidget {
  const GestionAlumnosScreen({super.key});

  @override
  State<GestionAlumnosScreen> createState() => _GestionAlumnosScreenState();
}

class _GestionAlumnosScreenState extends State<GestionAlumnosScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AlumnosProvider>().cargarAlumnos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dorado = Theme.of(context).colorScheme.primary;
    // Verificamos si el usuario logueado es Director
    final esDirector = context.read<AuthProvider>().esDirector;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Gestión de Alumnos"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      // Solo mostramos el botón de agregar si NO es director
      floatingActionButton: esDirector 
        ? null 
        : FloatingActionButton.extended(
            backgroundColor: dorado,
            icon: const Icon(Icons.person_add, color: Colors.black),
            label: const Text("Nuevo Alumno", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            onPressed: () => showDialog(context: context, builder: (_) => const AlumnoDialog()),
          ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Buscar por nombre o código...",
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: Icon(Icons.search, color: dorado),
                filled: true, fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
              onChanged: (val) {
                context.read<AlumnosProvider>().cargarAlumnos(query: val);
              },
            ),
          ),

          Expanded(
            child: Consumer<AlumnosProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) return Center(child: CircularProgressIndicator(color: dorado));
                if (provider.alumnos.isEmpty) return const Center(child: Text("No hay alumnos registrados", style: TextStyle(color: Colors.grey)));

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: provider.alumnos.length,
                  itemBuilder: (ctx, i) {
                    final alumno = provider.alumnos[i];
                    
                    Color estadoColor = Colors.green;
                    IconData estadoIcon = Icons.check_circle;
                    String estadoTexto = "Habilitado";

                    if (alumno.estaVetado) {
                      estadoColor = Colors.red;
                      estadoIcon = Icons.block;
                      estadoTexto = "VETADO";
                    } else if (alumno.strikes > 0) {
                      estadoColor = Colors.orange;
                      estadoIcon = Icons.warning;
                      estadoTexto = "${alumno.strikes} Faltas";
                    }

                    return Card(
                      color: const Color(0xFF1E1E1E),
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: estadoColor.withOpacity(0.2),
                          child: Icon(estadoIcon, color: estadoColor),
                        ),
                        title: Text(alumno.nombreCompleto, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text("${alumno.codigo} • ${alumno.grado} ${alumno.seccion} • $estadoTexto", style: TextStyle(color: Colors.grey[400])),
                        // Solo permitimos editar si NO es director
                        trailing: esDirector 
                          ? null 
                          : IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blueGrey),
                              onPressed: () => showDialog(
                                context: context, 
                                builder: (_) => AlumnoDialog(alumno: alumno)
                              ),
                            ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}