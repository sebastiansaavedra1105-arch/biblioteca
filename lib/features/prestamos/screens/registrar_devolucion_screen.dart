import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../dashboard/providers/libros_provider.dart';
import '../widgets/prestamo_item_card.dart';

class RegistrarDevolucionScreen extends StatefulWidget {
  const RegistrarDevolucionScreen({super.key});

  @override
  State<RegistrarDevolucionScreen> createState() => _RegistrarDevolucionScreenState();
}

class _RegistrarDevolucionScreenState extends State<RegistrarDevolucionScreen> {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LibrosProvider>().cargarPrestamos();
    });
  }

  void _confirmarDevolucion(Map<String, dynamic> prestamo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text("Confirmar Devolución"),
        content: Text("¿Confirmas que se devolvió el libro '${prestamo['libro_titulo']}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text("Cancelar")
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = context.read<LibrosProvider>();
              
              // LLAMADA CORRECTA CON PARÁMETROS NOMBRADOS
              final exito = await provider.registrarDevolucion(
                prestamoId: prestamo['id'].toString(), 
                libroId: prestamo['libro_id'].toString()
              );

              if (exito && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar( // Agregado const
                    content: Text("✅ Devolución registrada correctamente"),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  )
                );
              }
            }, 
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
            child: const Text("Confirmar", style: TextStyle(color: Colors.white))
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<LibrosProvider>(
      builder: (context, provider, child) {
        final prestamos = provider.prestamosActivos;

        if (provider.isLoading) {
          return Center(child: CircularProgressIndicator(color: colorScheme.primary));
        }

        if (prestamos.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 80, color: Colors.green.withOpacity(0.5)),
                const SizedBox(height: 20),
                Text("No hay préstamos activos", style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: prestamos.length,
          itemBuilder: (context, index) {
            return PrestamoItemCard(
              prestamo: prestamos[index],
              onDevolver: () => _confirmarDevolucion(prestamos[index]),
            );
          },
        );
      },
    );
  }
}