import 'package:flutter/material.dart';

class AcercaDeDialog extends StatelessWidget {
  const AcercaDeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E), // Fondo oscuro secundario
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFD4AF37), width: 1), // Borde dorado
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- LOGO ---
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.black38,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD4AF37), width: 2),
              ),
              child: Image.asset(
                'assets/images/logo_colegio.png', // Tu logo
                height: 60,
                width: 60,
                fit: BoxFit.contain,
                errorBuilder: (_,__,___) => const Icon(Icons.school, size: 50, color: Color(0xFFD4AF37)),
              ),
            ),
            const SizedBox(height: 15),

            // --- TÍTULO ---
            const Text(
              "Sistema Bibliotecario",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const Text(
              "Versión 1.0.0",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 20),
            const Divider(color: Colors.white24),
            const SizedBox(height: 10),

            // --- EQUIPO DE DESARROLLO ---
            const Text(
              "DESARROLLADO POR:",
              style: TextStyle(
                color: Color(0xFFD4AF37), // Dorado
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            
            // Aquí pones a tus 3 compañeros
            _buildDeveloperRow("Jin patrick Manya Fasanando", "Líder de Proyecto / Backend"),
            _buildDeveloperRow("Deiviss Jean Pool Palacios Dávila", "Frontend / Diseño"),
            _buildDeveloperRow("Pedro Sebastian Saavedra Rodrigues", "Base de Datos / QA"),

            const SizedBox(height: 15),

            // --- PROFESOR ---
            const Text(
              "SUPERVISADO POR:",
              style: TextStyle(
                color: Color(0xFFD4AF37),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 5),
            _buildDeveloperRow("Ing. Manuel Antonio Vela Vasquez", "Docente Encargado", isProfessor: true),

            const SizedBox(height: 20),
            
            // --- PIE DE PÁGINA ---
            const Text(
              "© 2025 - Todos los derechos reservados",
              style: TextStyle(color: Colors.white30, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cerrar", style: TextStyle(color: Color(0xFFD4AF37))),
        ),
      ],
    );
  }

  Widget _buildDeveloperRow(String nombre, String rol, {bool isProfessor = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            isProfessor ? Icons.school : Icons.code,
            size: 16,
            color: isProfessor ? const Color(0xFFD4AF37) : Colors.white54,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  rol,
                  style: const TextStyle(
                    color: Colors.grey,
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