import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../dashboard/providers/libros_provider.dart';

class RegistrarDevolucionScreen extends StatefulWidget {
  const RegistrarDevolucionScreen({super.key});

  @override
  State<RegistrarDevolucionScreen> createState() => _RegistrarDevolucionScreenState();
}

class _RegistrarDevolucionScreenState extends State<RegistrarDevolucionScreen> {
  
  @override
  void initState() {
    super.initState();
    // Cargar préstamos al entrar a la pestaña
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LibrosProvider>().cargarPrestamos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LibrosProvider>(
      builder: (context, provider, child) {
        final prestamos = provider.prestamosActivos;

        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (prestamos.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
                const SizedBox(height: 20),
                Text("No hay préstamos activos", style: TextStyle(color: Colors.grey[400], fontSize: 18)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: prestamos.length,
          itemBuilder: (context, index) {
            final p = prestamos[index];
            
            // Calculamos días restantes / vencimiento
            final fechaEntrega = DateTime.parse(p['fecha_entrega']);
            final hoy = DateTime.now();
            final diferencia = fechaEntrega.difference(hoy).inDays;
            final esVencido = diferencia < 0;

            return Card(
              margin: const EdgeInsets.only(bottom: 15),
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
                            p['libro_titulo'] ?? 'Libro Desconocido',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: esVencido ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8)
                          ),
                          child: Text(
                            esVencido ? "Vencido hace ${diferencia.abs()} días" : "$diferencia días restantes",
                            style: TextStyle(
                              color: esVencido ? Colors.red[300] : Colors.green[300], 
                              fontSize: 12, fontWeight: FontWeight.bold
                            ),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.person, size: 16, color: Colors.grey),
                        const SizedBox(width: 5),
                        Text("${p['nombre_alumno']} (${p['codigo_alumno']})", style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                        const SizedBox(width: 5),
                        Text("Entrega: ${fechaEntrega.day}/${fechaEntrega.month}/${fechaEntrega.year}", style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 15),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.assignment_return),
                        label: const Text("REGISTRAR DEVOLUCIÓN"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          // Llamar al provider para devolver
                          showDialog(
                            context: context, 
                            builder: (ctx) => AlertDialog(
                              title: const Text("Confirmar Devolución"),
                              content: Text("¿Confirmas que se devolvió el libro '${p['libro_titulo']}'?"),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    // Acción real
                                    provider.registrarDevolucion(p['id'], p['libro_id']);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Libro devuelto correctamente"))
                                    );
                                  }, 
                                  child: const Text("Confirmar", style: TextStyle(color: Colors.green))
                                ),
                              ],
                            )
                          );
                        },
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}