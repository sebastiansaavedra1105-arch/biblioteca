import 'package:flutter/material.dart';

class NuevoPrestamoScreen extends StatefulWidget {
  const NuevoPrestamoScreen({super.key});

  @override
  State<NuevoPrestamoScreen> createState() => _NuevoPrestamoScreenState();
}

class _NuevoPrestamoScreenState extends State<NuevoPrestamoScreen> {
  // Controladores para el formulario
  final TextEditingController _lectorController = TextEditingController();
  final TextEditingController _libroController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Nuevo Préstamo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Campos de búsqueda (luego serán más complejos)
            TextField(
              controller: _lectorController,
              decoration: const InputDecoration(
                labelText: 'Buscar Lector (por ID o Identificación)',
                suffixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _libroController,
              decoration: const InputDecoration(
                labelText: 'Buscar Libro (por ID o ISBN)',
                suffixIcon: Icon(Icons.search),
              ),
            ),
            
            const Spacer(), // Empuja el botón al fondo

            ElevatedButton(
              onPressed: () {
                // Lógica para registrar el préstamo
                // 1. Validar lector y libro
                // 2. Llamar a db.registrarPrestamo(...)
                // 3. Mostrar éxito y volver atrás
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50), // Ancho completo
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: const Text('Confirmar Préstamo'),
            ),
          ],
        ),
      ),
    );
  }
}