import 'package:flutter/material.dart';

class RegistrarDevolucionScreen extends StatefulWidget {
  const RegistrarDevolucionScreen({super.key});

  @override
  State<RegistrarDevolucionScreen> createState() => _RegistrarDevolucionScreenState();
}

class _RegistrarDevolucionScreenState extends State<RegistrarDevolucionScreen> {
  final TextEditingController _libroController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Devolución'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Campo de búsqueda
            TextField(
              controller: _libroController,
              decoration: const InputDecoration(
                labelText: 'Buscar Libro (por ID, ISBN o Título)',
                suffixIcon: Icon(Icons.search),
              ),
              // Implementar búsqueda en tiempo real
            ),
            
            const SizedBox(height: 24),
            
            // Mostrar aquí una lista de resultados de búsqueda
            // Por ahora, un espacio vacío
            const Expanded(
              child: Center(
                child: Text('Busque un libro para registrar su devolución.'),
              ),
            ),
            
            // El botón estaría deshabilitado hasta seleccionar un libro
            ElevatedButton(
              onPressed: null, // Deshabilitado por ahora
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Confirmar Devolución'),
            ),
          ],
        ),
      ),
    );
  }
}