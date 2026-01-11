import 'package:flutter/material.dart';

class AcercaDeDialog extends StatelessWidget {
  const AcercaDeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    // Accedemos a los colores del tema actual
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return AlertDialog(
      // Usamos 'surface' para que sea Crema en Claro y Gris en Oscuro
      backgroundColor: colorScheme.surface, 
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.primary, width: 2), // Borde dorado más notable
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- LOGO ---
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                // Fondo dinámico sutil
                color: colorScheme.onSurface.withOpacity(0.05),
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.primary, width: 2),
              ),
              child: Image.asset(
                'assets/images/logo_colegio.png', 
                height: 80, // Un poco más grande
                width: 80,
                fit: BoxFit.contain,
                errorBuilder: (_,__,___) => Icon(Icons.school, size: 60, color: colorScheme.primary),
              ),
            ),
            const SizedBox(height: 15),

            // --- TÍTULO ---
            Text(
              "Sistema Bibliotecario",
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface, // Se adapta (Azul Noche o Blanco)
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              "Versión 1.0.0",
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 20),
            Divider(color: colorScheme.onSurface.withOpacity(0.2)),
            const SizedBox(height: 10),

            // --- EQUIPO DE DESARROLLO ---
            Text(
              "DESARROLLADO POR:",
              style: TextStyle(
                color: colorScheme.primary, // Dorado
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            
            // Tus compañeros (con colores dinámicos)
            _buildDeveloperRow(context, "Jin Patrick Manya Fasanando", "Líder de Proyecto / Backend"),
            _buildDeveloperRow(context, "Deiviss Jean Pool Palacios Dávila", "Frontend / Diseño"),
            _buildDeveloperRow(context, "Pedro Sebastian Saavedra Rodrigues", "Base de Datos / QA"),

            const SizedBox(height: 15),

            // --- PROFESOR ---
            Text(
              "SUPERVISADO POR:",
              style: TextStyle(
                color: colorScheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 5),
            _buildDeveloperRow(context, "Ing. Manuel Antonio Vela Vasquez", "Docente Encargado", isProfessor: true),

            const SizedBox(height: 20),
            
            // --- PIE DE PÁGINA ---
            Text(
              "© 2025 - Todos los derechos reservados",
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.4), 
                fontSize: 10
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cerrar", style: TextStyle(color: colorScheme.primary)),
        ),
      ],
    );
  }

  Widget _buildDeveloperRow(BuildContext context, String nombre, String rol, {bool isProfessor = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            isProfessor ? Icons.school : Icons.code,
            size: 18,
            // Si es profesor Dorado, si es alumno usamos el color del texto normal con opacidad
            color: isProfessor ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.7),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: TextStyle(
                    color: colorScheme.onSurface, // Se ve bien en Claro y Oscuro
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  rol,
                  style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}