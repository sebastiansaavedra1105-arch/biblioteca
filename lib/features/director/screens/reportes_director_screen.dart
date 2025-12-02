import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/director_provider.dart';

class ReportesDirectorScreen extends StatefulWidget {
  const ReportesDirectorScreen({super.key});

  @override
  State<ReportesDirectorScreen> createState() => _ReportesDirectorScreenState();
}

class _ReportesDirectorScreenState extends State<ReportesDirectorScreen> {
  
  @override
  void initState() {
    super.initState();
    // Cargar datos frescos al entrar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DirectorProvider>().cargarReportes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dorado = Theme.of(context).colorScheme.primary;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<DirectorProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) return Center(child: CircularProgressIndicator(color: dorado));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text("Métricas de Rendimiento", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                // --- SECCIÓN 1: TARJETAS DE RESUMEN ---
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        titulo: "Esta Semana",
                        dato: "${provider.prestamosSemana}",
                        subtitulo: "Préstamos nuevos",
                        icono: Icons.calendar_view_week,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _StatCard(
                        titulo: "Este Mes",
                        dato: "${provider.prestamosMes}",
                        subtitulo: "Préstamos totales",
                        icono: Icons.calendar_month,
                        color: dorado,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                // Tarjeta de Devoluciones (Ancho completo)
                _StatCard(
                  titulo: "Efectividad de Devolución (Mes)",
                  dato: "${provider.devolucionesMes}",
                  subtitulo: "Libros devueltos este mes",
                  icono: Icons.assignment_return,
                  color: Colors.green,
                ),

                const SizedBox(height: 30),
                const Divider(color: Colors.grey),
                const SizedBox(height: 10),

                // --- SECCIÓN 2: BOTÓN DE DESCARGA ---
                const Text("Exportación de Datos", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                const Text(
                  "Genera un archivo CSV con todo el historial de préstamos y devoluciones para abrir en Excel.",
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  height: 60,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E1E1E),
                      foregroundColor: Colors.white,
                      side: BorderSide(color: dorado),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.download, size: 28),
                    label: const Text("DESCARGAR REPORTE COMPLETO (CSV)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      final path = await provider.descargarReporteCsv();
                      if (context.mounted) {
                        if (path != null) {
                          _mostrarExito(context, path);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al generar reporte")));
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _mostrarExito(BuildContext context, String path) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF252525),
        title: const Row(children: [Icon(Icons.check_circle, color: Colors.green), SizedBox(width: 10), Text("Reporte Guardado", style: TextStyle(color: Colors.white))]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("El archivo se guardó exitosamente en:", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              color: Colors.black,
              child: Text(path, style: const TextStyle(color: Colors.amber, fontFamily: 'monospace')),
            ),
            const SizedBox(height: 10),
            const Text("Puedes abrirlo con Excel o LibreOffice.", style: TextStyle(color: Colors.white70)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Entendido"))
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String titulo;
  final String dato;
  final String subtitulo;
  final IconData icono;
  final Color color;

  const _StatCard({required this.titulo, required this.dato, required this.subtitulo, required this.icono, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(15),
        border: Border(left: BorderSide(color: color, width: 5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icono, color: color, size: 30),
              Text(dato, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          Text(titulo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          Text(subtitulo, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        ],
      ),
    );
  }
}