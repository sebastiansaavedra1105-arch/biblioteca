import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <--- NECESARIO PARA SALIR DE LA APP
import 'package:provider/provider.dart';

import 'package:biblio/features/catalogo_publico/providers/catalogo_provider.dart';
import 'package:biblio/features/catalogo_publico/widgets/catalogo_header.dart';
import 'package:biblio/features/catalogo_publico/widgets/libro_publico_card.dart';
import 'package:biblio/features/auth/screens/login_screen.dart';
import 'package:biblio/core/widgets/acerca_de_dialog.dart';
import 'package:biblio/core/theme/theme_provider.dart';

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

  // Función para cerrar la app con confirmación (Opcional pero recomendado)
  void _salirDeLaApp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("¿Salir de la aplicación?"),
        content: const Text("Se cerrará el sistema de biblioteca."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              SystemNavigator.pop(); // <--- ESTO CIERRA LA APP
            },
            child: const Text("Salir", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      // APP BAR INSTITUCIONAL
      appBar: AppBar(
        elevation: 0, 
        backgroundColor: colorScheme.surface, 
        toolbarHeight: 70, 
        
        // TÍTULO A LA IZQUIERDA
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white, 
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.primary, width: 1.5),
              ),
              child: Image.asset(
                'assets/images/logo_colegio.png',
                height: 40,
                width: 40,
                errorBuilder: (_,__,___) => Icon(Icons.school, color: colorScheme.primary),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BIBLIOTECA',
                  style: TextStyle(
                    color: colorScheme.primary, 
                    fontSize: 12,
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'JIMÉNEZ PIMENTEL',
                  style: TextStyle(
                    color: colorScheme.secondary, 
                    fontSize: 16,
                    fontWeight: FontWeight.w900, 
                    fontFamily: 'Playfair Display', 
                  ),
                ),
              ],
            ),
          ],
        ),
        
        // ACCIONES A LA DERECHA
        actions: [
          // 1. SWITCH DE TEMA
          IconButton(
            onPressed: () => themeProvider.toggleTheme(!isDark),
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              color: isDark ? Colors.amber : colorScheme.secondary,
            ),
            tooltip: isDark ? 'Modo Claro' : 'Modo Oscuro',
          ),

          // 2. CRÉDITOS
          IconButton(
            icon: Icon(Icons.info_outline, color: colorScheme.secondary),
            tooltip: 'Acerca de',
            onPressed: () => showDialog(context: context, builder: (_) => const AcercaDeDialog()),
          ),

          // 3. LOGIN ADMIN
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colorScheme.primary),
            ),
            child: IconButton(
              icon: Icon(Icons.login, color: colorScheme.primary),
              tooltip: 'Acceso Admin',
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()))
                    .then((_) {
                  if (mounted) context.read<CatalogoProvider>().cargarCatalogo();
                });
              },
            ),
          ),

          // 4. 🔥 BOTÓN SALIR DE LA APP (NUEVO)
          Container(
            margin: const EdgeInsets.only(right: 10, left: 5),
            decoration: BoxDecoration(
              color: colorScheme.error, // Rojo Vino
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.power_settings_new, color: Colors.white),
              tooltip: 'Salir de la App', // <--- LO QUE PEDISTE
              onPressed: _salirDeLaApp,
            ),
          ),
        ],
        
        // LÍNEA DIVISORIA DORADA
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(color: colorScheme.primary, height: 2),
        ),
      ),

      // CUERPO
      body: Column(
        children: [
          const CatalogoHeader(),
          Expanded(
            child: Consumer<CatalogoProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return Center(child: CircularProgressIndicator(color: colorScheme.primary));
                }
                if (provider.libros.isEmpty) {
                  return _buildEmptyState(context, provider);
                }
                return RefreshIndicator(
                  onRefresh: () async => await provider.cargarCatalogo(),
                  color: colorScheme.primary,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 220, 
                      childAspectRatio: 0.60,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                    ),
                    itemCount: provider.libros.length,
                    itemBuilder: (context, index) => LibroPublicoCard(libro: provider.libros[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, CatalogoProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 10),
          Text(
            "No se encontraron libros",
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.grey),
          ),
          TextButton(
            onPressed: () => provider.cargarCatalogo(),
            child: const Text("Recargar catálogo"),
          )
        ],
      ),
    );
  }
}