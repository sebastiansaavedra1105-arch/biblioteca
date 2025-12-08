import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) { context.read<DirectorProvider>().cargarReportes(); });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final provider = context.watch<DirectorProvider>();

    if (provider.isLoading) return Center(child: CircularProgressIndicator(color: colorScheme.primary));

    return Column(
      children: [
        // BOTÓN EXPORTAR EN EL CUERPO (Header interno)
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton.icon(
                onPressed: () async {
                  final path = await provider.descargarReporteCsv();
                  if (context.mounted && path != null) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Guardado en: $path"), backgroundColor: Colors.green));
                  }
                },
                icon: const Icon(Icons.download, size: 18),
                label: const Text("Exportar CSV"),
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: _StatCard(titulo: "Semana", dato: "${provider.prestamosSemana}", icono: Icons.calendar_view_week, color: Colors.blue)),
                    const SizedBox(width: 16),
                    Expanded(child: _StatCard(titulo: "Mes", dato: "${provider.prestamosMes}", icono: Icons.calendar_month, color: Colors.orange)),
                    const SizedBox(width: 16),
                    Expanded(child: _StatCard(titulo: "Devueltos", dato: "${provider.devolucionesMes}", icono: Icons.assignment_return, color: Colors.green)),
                  ],
                ),
                const SizedBox(height: 30),
                Text("Historial Reciente", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.onSurface.withOpacity(0.05)),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: provider.historialPrestamos.take(15).length,
                    separatorBuilder: (_,__) => Divider(height: 1, color: colorScheme.onSurface.withOpacity(0.1)),
                    itemBuilder: (ctx, i) {
                      final item = provider.historialPrestamos[i];
                      final fecha = DateTime.parse(item['fecha_prestamo']);
                      return ListTile(
                        title: Text(item['libro_titulo'] ?? '?', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text("Alumno: ${item['alumno_nombre'] ?? '?'}"),
                        trailing: Text(DateFormat('dd/MM/yyyy').format(fecha), style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withOpacity(0.6))),
                      );
                    }
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String titulo, dato; final IconData icono; final Color color;
  const _StatCard({required this.titulo, required this.dato, required this.icono, required this.color});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))]
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icono, color: color), const SizedBox(height: 10),
        Text(dato, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: scheme.onSurface)),
        Text(titulo, style: TextStyle(color: scheme.onSurface.withOpacity(0.6), fontSize: 12)),
      ]),
    );
  }
}