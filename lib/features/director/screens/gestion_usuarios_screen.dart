import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/director_provider.dart';
import '../widgets/usuario_dialog.dart';

class GestionUsuariosScreen extends StatelessWidget {
  const GestionUsuariosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dorado = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Gestión de Usuarios", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: dorado,
                foregroundColor: Colors.black,
              ),
              icon: const Icon(Icons.person_add),
              label: const Text("Nuevo Usuario"),
              onPressed: () {
                _mostrarDialogo(context, null); // null = Crear
              },
            ),
          )
        ],
      ),
      body: Consumer<DirectorProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) return Center(child: CircularProgressIndicator(color: dorado));
          
          // 🔥 FILTRO: Ocultamos la cuenta maestra 'director' para que no salga en la lista
          final listaVisible = provider.usuarios.where((u) => u['username'] != 'director').toList();

          if (listaVisible.isEmpty) {
            return const Center(child: Text("No hay otros usuarios registrados.", style: TextStyle(color: Colors.grey)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: listaVisible.length,
            itemBuilder: (ctx, i) {
              final u = listaVisible[i];
              
              // Protegemos la cuenta 'admin' por defecto para que no se borre accidentalmente (opcional)
              final esAdminBase = u['username'] == 'admin';

              return Card(
                color: const Color(0xFF1E1E1E),
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: u['rol'] == 'DIRECTOR' ? Colors.amber[700] : Colors.blueGrey,
                    child: Icon(u['rol'] == 'DIRECTOR' ? Icons.security : Icons.person, color: Colors.white),
                  ),
                  title: Text(u['nombre'] ?? 'Sin Nombre', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text("${u['rol']} • @${u['username']}", style: TextStyle(color: Colors.grey[400])),
                  
                  // 🔥 AQUÍ ESTÁ LA SOLUCIÓN: BOTONES EDITAR Y ELIMINAR
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Botón EDITAR
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blueAccent),
                        tooltip: "Editar datos",
                        onPressed: () => _mostrarDialogo(context, u), // Pasamos el usuario para editar
                      ),
                      
                      // Botón ELIMINAR (Solo si no es admin base, o quita la condición si quieres borrar todo)
                      if (!esAdminBase)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          tooltip: "Eliminar",
                          onPressed: () => _confirmarBorrar(context, u['id'], u['username']),
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(Icons.lock, color: Colors.grey, size: 20),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _mostrarDialogo(BuildContext context, Map<String, dynamic>? usuario) {
    showDialog(
      context: context,
      builder: (_) => UsuarioDialog(
        usuarioParaEditar: usuario, // Si pasamos datos, el diálogo se pone en modo EDICIÓN
        onConfirm: (user, pass, nombre, rol) {
          final provider = context.read<DirectorProvider>();
          
          if (usuario == null) {
            // CREAR
            provider.crearUsuario(user, pass, nombre, rol);
          } else {
            // EDITAR (Usamos el ID del usuario original)
            provider.editarUsuario(usuario['id'], nombre, rol, pass);
          }
        },
      ),
    );
  }

  void _confirmarBorrar(BuildContext context, String id, String nombre) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF252525),
        title: const Text("¿Eliminar Usuario?", style: TextStyle(color: Colors.white)),
        content: Text("Se eliminará a @$nombre permanentemente.", style: const TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          TextButton(
            onPressed: () {
              context.read<DirectorProvider>().eliminarUsuario(id);
              Navigator.pop(context);
            }, 
            child: const Text("Eliminar", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
          ),
        ],
      )
    );
  }
}