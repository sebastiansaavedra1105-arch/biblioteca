import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:biblio/features/director/providers/director_provider.dart';

class MantenimientoScreen extends StatelessWidget {
  const MantenimientoScreen({super.key});

  // 🔐 CONTRASEÑA MAESTRA
  static const String masterPassword = "admin"; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView( // Scroll por si la pantalla es chica
        padding: const EdgeInsets.all(30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red, size: 40),
                SizedBox(width: 15),
                Text(
                  "ZONA DE MANTENIMIENTO",
                  style: TextStyle(color: Colors.red, fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              "Gestión de datos sensibles. Se requiere la Contraseña Maestra para ejecutar estas acciones.",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 40),

            // --- NIVEL 1: SOLO PRÉSTAMOS ---
            _PeligroButton(
              titulo: "1. Borrar Historial de Préstamos",
              descripcion: "Elimina el registro de quién llevó qué libro. Los libros se mantienen en el inventario.",
              icon: Icons.history,
              color: Colors.orange,
              onPressed: () => _confirmarAccion(context, "Borrar PRÉSTAMOS", () {
                context.read<DirectorProvider>().limpiarPrestamos();
              }),
            ),

            const SizedBox(height: 20),

            // --- NIVEL 2: SOLO LIBROS ---
            _PeligroButton(
              titulo: "2. Borrar Catálogo de Libros",
              descripcion: "Elimina todos los libros. (Nota: Esto también borra los préstamos asociados por seguridad).",
              icon: Icons.library_books,
              color: Colors.deepOrange,
              onPressed: () => _confirmarAccion(context, "Borrar LIBROS", () {
                context.read<DirectorProvider>().limpiarLibros();
              }),
            ),

            const SizedBox(height: 20),

            // --- NIVEL 3: BORRAR Todo ---
            _PeligroButton(
              titulo: "3. RESTABLECIMIENTO TOTAL (FÁBRICA)",
              descripcion: "Elimina absolutamente TODO: Libros, Préstamos y Datos temporales. Deja el sistema como nuevo.",
              icon: Icons.delete_forever,
              color: Colors.red,
              isCritical: true, // Estilo más agresivo
              onPressed: () => _confirmarAccion(context, "BORRAR TODO EL SISTEMA", () {
                context.read<DirectorProvider>().limpiarTodo();
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarAccion(BuildContext context, String accion, VoidCallback onSuccess) {
    final passCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF252525),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Colors.red, width: 2)),
        title: Row(
          children: [
            const Icon(Icons.security, color: Colors.red),
            const SizedBox(width: 10),
            Text("Confirmar: $accion", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Esta acción es IRREVERSIBLE. Los datos se borrarán del equipo y de la nube.\n\nIngrese la contraseña maestra:",
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: passCtrl,
              obscureText: true,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                hintText: "Contraseña",
                hintStyle: TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.black,
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.red)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCELAR", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              if (passCtrl.text == masterPassword) {
                Navigator.pop(ctx);
                onSuccess(); // Ejecuta la limpieza
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("✅ Limpieza ejecutada correctamente"), backgroundColor: Colors.green)
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("⛔ Contraseña incorrecta"), backgroundColor: Colors.red)
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

class _PeligroButton extends StatelessWidget {
  final String titulo;
  final String descripcion;
  final IconData icon;
  final Color color;
  final bool isCritical;
  final VoidCallback onPressed;

  const _PeligroButton({
    required this.titulo, 
    required this.descripcion, 
    required this.icon, 
    required this.color, 
    required this.onPressed,
    this.isCritical = false
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.5), width: isCritical ? 2 : 1),
        borderRadius: BorderRadius.circular(10),
        color: color.withOpacity(0.1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 30),
        ),
        title: Text(titulo, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(descripcion, style: const TextStyle(color: Colors.white70)),
        ),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15)
          ),
          onPressed: onPressed,
          child: const Text("EJECUTAR", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}