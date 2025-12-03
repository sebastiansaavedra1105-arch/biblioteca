import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Imports absolutos
import 'package:biblio/features/catalogo_publico/providers/catalogo_provider.dart';
import 'package:biblio/features/catalogo_publico/widgets/catalogo_header.dart';
import 'package:biblio/features/catalogo_publico/widgets/libro_publico_card.dart';
import 'package:biblio/features/auth/screens/login_screen.dart';

// 🔥 CAMBIO 1: Ahora es StatefulWidget para tener "Ciclo de Vida"
class CatalogoScreen extends StatefulWidget {
  const CatalogoScreen({super.key});

  @override
  State<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen> {
  
  // 🔥 CAMBIO 2: Esto se ejecuta CADA VEZ que esta pantalla se construye (al abrir la app o volver del login)
  @override
  void initState() {
    super.initState();
    // Usamos addPostFrameCallback para asegurar que el widget esté listo antes de pedir datos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatalogoProvider>().cargarCatalogo();
    });
  }

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
            onPressed: () {
              // Navegamos al login. El .then se ejecuta cuando regresas.
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => const LoginScreen())
              ).then((_) {
                // 🔥 CAMBIO 3: Doble seguridad. Si vuelven con "Atrás", recargamos.
                if (mounted) {
                  context.read<CatalogoProvider>().cargarCatalogo();
                }
              });
            },
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

                // Estado: Vacío (con opción de recargar deslizando)
                if (provider.libros.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () async => await provider.cargarCatalogo(),
                    color: colorDorado,
                    backgroundColor: Colors.grey[900],
                    child: ListView(
                      children: const [
                        SizedBox(height: 100),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 60, color: Colors.grey),
                              SizedBox(height: 10),
                              Text("No se encontraron libros", style: TextStyle(color: Colors.grey)),
                              SizedBox(height: 5),
                              Text("Desliza para recargar", style: TextStyle(color: Colors.grey, fontSize: 10)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Estado: Lista de Libros (Grid)
                return RefreshIndicator(
                  onRefresh: () async => await provider.cargarCatalogo(),
                  color: colorDorado,
                  backgroundColor: Colors.grey[900],
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    physics: const AlwaysScrollableScrollPhysics(), // Permite scroll/refresh aunque haya pocos items
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 180, 
                      childAspectRatio: 0.55, 
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                    ),
                    itemCount: provider.libros.length,
                    itemBuilder: (context, index) {
                      return LibroPublicoCard(libro: provider.libros[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}