import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Imports absolutos
import 'package:biblio/features/catalogo_publico/providers/catalogo_provider.dart';
import 'package:biblio/features/catalogo_publico/widgets/catalogo_header.dart';
import 'package:biblio/features/catalogo_publico/widgets/libro_publico_card.dart';
import 'package:biblio/features/auth/screens/login_screen.dart';

// 🔥 IMPORTANTE: Importamos el Dialog de Acerca De
import 'package:biblio/core/widgets/acerca_de_dialog.dart';

class CatalogoScreen extends StatefulWidget {
  const CatalogoScreen({super.key});

  @override
  State<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen> {
  
  @override
  void initState() {
    super.initState();
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
        centerTitle: true, // Centramos el título para que se vea elegante
        title: Row(
          mainAxisSize: MainAxisSize.min, // Para que se centre bien
          children: [
            Icon(Icons.local_library, color: colorDorado, size: 28),
            const SizedBox(width: 10),
            Text('BIBLIOTECA DIGITAL', style: TextStyle(color: colorDorado, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          // 🔥 NUEVO BOTÓN: ACERCA DE (CRÉDITOS)
          // Lo ponemos antes del Login para que sea visible pero secundario
          IconButton(
            icon: Icon(Icons.info_outline, color: colorDorado), // Icono dorado
            tooltip: 'Acerca del Equipo',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const AcercaDeDialog(),
              );
            },
          ),

          // BOTÓN LOGIN EXISTENTE
          IconButton(
            icon: const Icon(Icons.login, color: Colors.white), // Blanco para diferenciar
            tooltip: 'Acceso Administrativo',
            onPressed: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => const LoginScreen())
              ).then((_) {
                if (mounted) {
                  context.read<CatalogoProvider>().cargarCatalogo();
                }
              });
            },
          ),
          
          const SizedBox(width: 10), // Un pequeño margen a la derecha
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
                    physics: const AlwaysScrollableScrollPhysics(),
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