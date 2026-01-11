import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:biblio/features/director/providers/director_provider.dart';

class MantenimientoScreen extends StatelessWidget {
  const MantenimientoScreen({super.key});

  static const String masterPassword = "admin"; // Contraseña de seguridad

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      // SIN APPBAR (El título ya está en el Dashboard principal)
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Alerta visual (Header interno de la sección)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.error.withOpacity(0.3))
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: colorScheme.error, size: 40),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "ZONA DE PELIGRO",
                          style: TextStyle(
                            color: colorScheme.error, 
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1.2
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "Las acciones aquí son irreversibles y requieren contraseña maestra.",
                          style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Opción 1: Préstamos
            _PeligroItem(
              titulo: "1. Borrar Historial de Préstamos",
              desc: "Elimina todos los registros de préstamos (activos e historial). No afecta inventario ni usuarios.",
              icon: Icons.history,
              color: Colors.orange,
              onTap: () => _confirmarAccion(context, "Borrar Préstamos", () => context.read<DirectorProvider>().limpiarPrestamos()),
            ),
            
            // Opción 2: Libros
            _PeligroItem(
              titulo: "2. Vaciar Inventario de Libros",
              desc: "Elimina todos los libros del sistema. Mantiene usuarios y alumnos.",
              icon: Icons.library_books,
              color: Colors.deepOrange,
              onTap: () => _confirmarAccion(context, "Vaciar Libros", () => context.read<DirectorProvider>().limpiarLibros()),
            ),

            // Opción 3: Todo (Nuclear)
            _PeligroItem(
              titulo: "3. RESTABLECIMIENTO TOTAL",
              desc: "Elimina TODO (Libros, Préstamos, Alumnos). Solo quedan los usuarios administradores.",
              icon: Icons.delete_forever,
              color: colorScheme.error,
              isCritical: true,
              onTap: () => _confirmarAccion(context, "Restablecimiento Total", () => context.read<DirectorProvider>().limpiarTodo()),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarAccion(BuildContext context, String accion, Future<bool> Function() tarea) {
    final passCtrl = TextEditingController();
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text("Confirmar: $accion", style: TextStyle(color: colorScheme.error)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Ingrese contraseña maestra:", style: TextStyle(color: colorScheme.onSurface)),
            const SizedBox(height: 10),
            TextField(
              controller: passCtrl, 
              obscureText: true, 
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: colorScheme.onSurface.withOpacity(0.3))),
              )
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text("Cancelar")
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: colorScheme.error),
            onPressed: () async {
              if (passCtrl.text == masterPassword) {
                Navigator.pop(ctx); // Cerrar diálogo
                final exito = await tarea(); // Ejecutar
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(exito ? "Acción realizada correctamente" : "Error al ejecutar acción"),
                      backgroundColor: exito ? Colors.green : Colors.red,
                    )
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Contraseña incorrecta"), backgroundColor: Colors.red)
                );
              }
            },
            child: const Text("CONFIRMAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// Widget Interno para los botones de peligro
class _PeligroItem extends StatelessWidget {
  final String titulo, desc;
  final IconData icon;
  final Color color;
  final bool isCritical;
  final VoidCallback onTap;

  const _PeligroItem({
    required this.titulo, 
    required this.desc, 
    required this.icon, 
    required this.color, 
    required this.onTap, 
    this.isCritical = false
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 15),
      color: theme.cardTheme.color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: color.withOpacity(0.5), width: isCritical ? 2 : 1)
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(titulo, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Text(desc, style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7))),
        ),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
          onPressed: onTap,
          child: const Text("EJECUTAR"),
        ),
      ),
    );
  }
}