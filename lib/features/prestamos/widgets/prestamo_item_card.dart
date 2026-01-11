import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PrestamoItemCard extends StatelessWidget {
  final Map<String, dynamic> prestamo;
  final VoidCallback onDevolver;

  const PrestamoItemCard({
    super.key,
    required this.prestamo,
    required this.onDevolver,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Parsear fecha
    final fechaEntrega = DateTime.parse(prestamo['fecha_entrega']);
    final hoy = DateTime.now();
    
    // Lógica de vencimiento
    final esVencido = hoy.isAfter(fechaEntrega);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: esVencido 
            ? BorderSide(color: colorScheme.error, width: 1.5) 
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ICONO LIBRO
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.book, color: colorScheme.primary),
                ),
                const SizedBox(width: 16),
                
                // DATOS
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prestamo['libro_titulo'] ?? 'Libro Desconocido',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Playfair Display',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Alumno: ${prestamo['alumno_nombre']}",
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      
                      // FECHAS
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 14, color: colorScheme.onSurface.withOpacity(0.5)),
                          const SizedBox(width: 5),
                          Text(
                            "Entrega: ${DateFormat('dd/MM/yyyy').format(fechaEntrega)}",
                            style: TextStyle(
                              color: esVencido ? colorScheme.error : colorScheme.onSurface,
                              fontWeight: esVencido ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          if (esVencido)
                            Text(" (VENCIDO)", style: TextStyle(color: colorScheme.error, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            
            // BOTÓN DE ACCIÓN
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onDevolver,
                icon: const Icon(Icons.assignment_return),
                label: const Text("REGISTRAR DEVOLUCIÓN"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: esVencido ? colorScheme.error : colorScheme.secondary, 
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}