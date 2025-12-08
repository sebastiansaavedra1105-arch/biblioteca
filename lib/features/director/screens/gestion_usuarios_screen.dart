import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/director_provider.dart';
import '../widgets/usuario_dialog.dart';

class GestionUsuariosScreen extends StatelessWidget {
  const GestionUsuariosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Consumer<DirectorProvider>(
        builder: (context, provider, _) {
          // AHORA MOSTRAMOS TODOS (Incluido el director para que pueda editarse)
          final listaVisible = provider.usuarios; 
          final totalUsuarios = listaVisible.length;

          if (provider.isLoading) {
            return Center(child: CircularProgressIndicator(color: colorScheme.primary));
          }

          return Column(
            children: [
              // --- 1. HEADER ---
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: colorScheme.onSurface.withOpacity(0.05)))
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Usuarios del Sistema",
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "$totalUsuarios registrados",
                          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.5)),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _mostrarDialogoUsuario(context, null), // Crear Nuevo
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.person_add, size: 18),
                      label: const Text("Nuevo Usuario"),
                    )
                  ],
                ),
              ),

              // --- 2. LISTA ---
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: listaVisible.length,
                  itemBuilder: (context, index) {
                    final usuario = listaVisible[index];
                    return _UsuarioCard(
                      usuario: usuario,
                      onEdit: () => _mostrarDialogoUsuario(context, usuario),
                      onDelete: () => _confirmarBorrado(context, usuario),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Lógica para abrir el diálogo (Crear o Editar)
  void _mostrarDialogoUsuario(BuildContext context, Map<String, dynamic>? usuario) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => UsuarioDialog(
        usuarioParaEditar: usuario,
        onConfirm: (user, pass, nombre, rol) async {
          final provider = context.read<DirectorProvider>();
          bool exito;

          if (usuario == null) {
            // CREAR
            exito = await provider.crearUsuario(
              username: user, 
              password: pass, // Aquí la contraseña es obligatoria
              nombre: nombre, 
              rol: rol
            );
          } else {
            // EDITAR
            exito = await provider.editarUsuario(
              id: usuario['id'],
              username: user,
              password: pass, // Si viene vacía, el provider la ignora
              nombre: nombre,
              rol: rol
            );
          }

          if (context.mounted) {
            if (exito) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(usuario == null ? "Usuario creado" : "Datos actualizados"), backgroundColor: Colors.green)
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Error en la operación"), backgroundColor: Colors.red)
              );
            }
          }
        },
      ),
    );
  }

  void _confirmarBorrado(BuildContext context, Map<String, dynamic> usuario) {
    // Evitar que el director se borre a sí mismo por error
    if (usuario['rol'] == 'DIRECTOR') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No puedes eliminar al Director principal"), backgroundColor: Colors.orange)
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("¿Eliminar Usuario?"),
        content: Text("Se eliminará el acceso de '${usuario['nombre']}'."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<DirectorProvider>().eliminarUsuario(usuario['id']);
            }, 
            child: const Text("Eliminar", style: TextStyle(color: Colors.white))
          )
        ],
      )
    );
  }
}

class _UsuarioCard extends StatelessWidget {
  final Map<String, dynamic> usuario;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UsuarioCard({required this.usuario, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final esDirector = usuario['rol'] == 'DIRECTOR';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.1))
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: esDirector 
                  ? colorScheme.primary.withOpacity(0.1) 
                  : Colors.grey.withOpacity(0.1),
              child: Icon(
                esDirector ? Icons.security : Icons.person,
                color: esDirector ? colorScheme.primary : Colors.grey[700]
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    usuario['nombre'] ?? 'Sin Nombre',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "${usuario['rol']} • ${usuario['username']}",
                    style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withOpacity(0.6)),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              color: colorScheme.primary,
              onPressed: onEdit,
            ),
            if (!esDirector) // No mostrar botón borrar para el director
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: colorScheme.error,
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}