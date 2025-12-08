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
      // backgroundColor lo maneja el tema global, pero podemos forzar un tono sutil si es necesario
      body: Consumer<DirectorProvider>(
        builder: (context, provider, _) {
          // Filtramos la lista
          final listaVisible = provider.usuarios.where((u) => u['username'] != 'director').toList();
          final totalUsuarios = listaVisible.length;

          if (provider.isLoading) {
            return Center(child: CircularProgressIndicator(color: colorScheme.primary));
          }

          return Column(
            children: [
              // --- 1. HEADER MEJORADO ---
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: colorScheme.onSurface.withOpacity(0.05)))
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Contador de usuarios (Izquierda)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Equipo de Trabajo",
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold, 
                            color: colorScheme.onSurface
                          )
                        ),
                        Text(
                          "$totalUsuarios miembros activos",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.6)
                          )
                        ),
                      ],
                    ),

                    // Botón de Agregar (Derecha)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white, // Texto blanco para contraste
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                        shadowColor: colorScheme.primary.withOpacity(0.4),
                      ),
                      icon: const Icon(Icons.person_add_rounded, size: 20),
                      label: const Text("Nuevo Usuario", style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () => _mostrarDialogo(context, null),
                    ),
                  ],
                ),
              ),

              // --- 2. LISTA DE USUARIOS (ESTILO TARJETAS) ---
              Expanded(
                child: listaVisible.isEmpty
                    ? _buildEmptyState(colorScheme)
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: listaVisible.length,
                        itemBuilder: (context, index) {
                          final usuario = listaVisible[index];
                          return _UsuarioCard(
                            usuario: usuario,
                            onEdit: () => _mostrarDialogo(context, usuario),
                            onDelete: () => _confirmarBorrar(context, usuario['id'], usuario['username']),
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

  // Estado vacío bonito
  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.people_outline, size: 50, color: colorScheme.primary),
          ),
          const SizedBox(height: 15),
          Text(
            "No hay personal registrado",
            style: TextStyle(fontSize: 16, color: colorScheme.onSurface.withOpacity(0.6)),
          ),
          const SizedBox(height: 5),
          Text(
            "Agrega un nuevo usuario para comenzar.",
            style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withOpacity(0.4)),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogo(BuildContext context, Map<String, dynamic>? usuario) {
    showDialog(
      context: context,
      builder: (_) => UsuarioDialog(
        usuarioParaEditar: usuario,
        onConfirm: (user, pass, nombre, rol) {
          final provider = context.read<DirectorProvider>();
          if (usuario == null) {
            provider.crearUsuario(user, pass, nombre, rol);
          } else {
            provider.editarUsuario(usuario['id'], nombre, rol, pass);
          }
        },
      ),
    );
  }

  void _confirmarBorrar(BuildContext context, String id, String nombre) {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text("¿Eliminar Usuario?", style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
        content: Text("Se eliminará a @$nombre permanentemente del sistema.", style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("Cancelar")
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
            ),
            icon: const Icon(Icons.delete_forever, size: 18),
            onPressed: () {
              context.read<DirectorProvider>().eliminarUsuario(id);
              Navigator.pop(context);
            }, 
            label: const Text("Eliminar")
          ),
        ],
      )
    );
  }
}

// --- WIDGET INTERNO: TARJETA DE USUARIO ---
class _UsuarioCard extends StatelessWidget {
  final Map<String, dynamic> usuario;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UsuarioCard({
    required this.usuario,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final bool esDirectorRol = usuario['rol'] == 'DIRECTOR';
    final Color rolColor = esDirectorRol ? colorScheme.primary : Colors.blue;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.onSurface.withOpacity(0.05)),
      ),
      color: theme.cardTheme.color,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // 1. AVATAR
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: rolColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                esDirectorRol ? Icons.security : Icons.manage_accounts,
                color: rolColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),

            // 2. INFORMACIÓN
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          usuario['nombre'] ?? 'Sin Nombre',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // CHIP DE ROL
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: rolColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: rolColor.withOpacity(0.3), width: 0.5)
                        ),
                        child: Text(
                          esDirectorRol ? "DIRECTOR" : "BIBLIOTECARIO",
                          style: TextStyle(
                            fontSize: 10, 
                            fontWeight: FontWeight.bold, 
                            color: rolColor
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.alternate_email, size: 14, color: colorScheme.onSurface.withOpacity(0.5)),
                      const SizedBox(width: 2),
                      Text(
                        usuario['username'] ?? 'anonimo',
                        style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 3. ACCIONES
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  color: colorScheme.primary,
                  tooltip: "Editar datos",
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: colorScheme.error,
                  tooltip: "Eliminar usuario",
                  onPressed: onDelete,
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}