import 'package:flutter/material.dart';
// Importa tus modelos

class RegistrarDevolucionScreen extends StatelessWidget {
  const RegistrarDevolucionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Lista falsa para ver cómo queda el diseño
    final prestamosFalsos = [
      {
        "titulo": "Cien Años de Soledad",
        "alumno": "Juan Pérez",
        "fecha": "2023-10-25",
        "diasRestantes": 5
      },
      {
        "titulo": "El Principito",
        "alumno": "Maria Garcia",
        "fecha": "2023-10-20",
        "diasRestantes": -2 // Vencido
      }
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: prestamosFalsos.length,
      itemBuilder: (context, index) {
        final p = prestamosFalsos[index];
        final int dias = p['diasRestantes'] as int;
        final bool vencido = dias < 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        p['titulo'].toString(),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF667eea)),
                      ),
                    ),
                    Chip(
                      label: Text(vencido ? "Vencido" : "$dias días"),
                      backgroundColor: vencido ? Colors.red[100] : Colors.green[100],
                      labelStyle: TextStyle(color: vencido ? Colors.red[900] : Colors.green[900]),
                    )
                  ],
                ),
                const SizedBox(height: 10),
                Text("👤 Alumno: ${p['alumno']}"),
                Text("📅 Entrega: ${p['fecha']}"),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text("Devolver Libro"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () {
                      // Aquí lógica de devolución en DB
                    },
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}