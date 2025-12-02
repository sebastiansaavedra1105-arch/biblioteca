import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Imports locales (nuestros nuevos widgets)
import '../providers/catalogo_provider.dart';
import '../widgets/catalogo_header.dart';
import '../widgets/libro_publico_card.dart';
import '../../auth/screens/login_screen.dart';

class CatalogoScreen extends StatelessWidget {
  const CatalogoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorDorado = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.black,
      
      // --- APP BAR ---
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_library, color: colorDorado, size: 28),
            const SizedBox(width: 10),
            Text('BIBLIOTECA DIGITAL', style: TextStyle(color: colorDorado, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.login, color: Colors.white),
            tooltip: 'Acceso Administrativo',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
          )
        ],
      ),

      // --- CUERPO ---
      body: Column(
        children: [
          // 1. HEADER (Buscador, Filtros, Flechas)
          const CatalogoHeader(), 

          // 2. GRILLA DE LIBROS
          Expanded(
            child: Consumer<CatalogoProvider>(
              builder: (context, provider, child) {
                // Estado: Cargando
                if (provider.isLoading) {
                  return Center(child: CircularProgressIndicator(color: colorDorado));
                }

                // Estado: Vacío
                if (provider.libros.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 60, color: Colors.grey),
                        SizedBox(height: 10),
                        Text("No se encontraron libros", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                // Estado: Lista de Libros
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 180, 
                    childAspectRatio: 0.55, 
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                  ),
                  itemCount: provider.libros.length,
                  itemBuilder: (context, index) {
                    // Usamos nuestra tarjeta refactorizada
                    return LibroPublicoCard(libro: provider.libros[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}