import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:biblio/features/director/providers/director_provider.dart';

class DirectorResumenScreen extends StatelessWidget {
  final Function(int) onNavigate;

  const DirectorResumenScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final provider = context.watch<DirectorProvider>();

    if (provider.isLoading) {
      return Center(child: CircularProgressIndicator(color: colorScheme.primary));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Bienvenido al Panel de Control",
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary),
          ),
          const SizedBox(height: 5),
          Text(
            "Visualización estratégica de la biblioteca.",
            style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
          ),
          const SizedBox(height: 30),

          // KPIs
          Row(
            children: [
              Expanded(child: _KpiCard(label: "Préstamos Semanales", value: "${provider.prestamosSemana}", icon: Icons.trending_up, color: Colors.blue)),
              const SizedBox(width: 16),
              Expanded(child: _KpiCard(label: "Préstamos Mensuales", value: "${provider.prestamosMes}", icon: Icons.calendar_month, color: Colors.orange)),
              const SizedBox(width: 16),
              Expanded(child: _KpiCard(label: "Devoluciones (Mes)", value: "${provider.devolucionesMes}", icon: Icons.check_circle_outline, color: Colors.green)),
            ],
          ),

          const SizedBox(height: 40),
          Text("Accesos Directos", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
          const SizedBox(height: 15),
          
          Wrap(
            spacing: 16, runSpacing: 16,
            children: [
              _ActionBtn(label: "Ver Alumnos", icon: Icons.school, onTap: () => onNavigate(2), color: colorScheme.secondary),
              _ActionBtn(label: "Auditar Inventario", icon: Icons.inventory_2, onTap: () => onNavigate(4), color: colorScheme.secondary),
              _ActionBtn(label: "Descargar Reporte", icon: Icons.download, onTap: () => onNavigate(1), color: const Color(0xFF2E7D32)),
            ],
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label, value; final IconData icon; final Color color;
  const _KpiCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.onSurface.withOpacity(0.05)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 15),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: scheme.onSurface)),
          Text(label, style: TextStyle(fontSize: 12, color: scheme.onSurface.withOpacity(0.6))),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label; final IconData icon; final VoidCallback onTap; final Color color;
  const _ActionBtn({required this.label, required this.icon, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap, icon: Icon(icon, size: 18), label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1), foregroundColor: color, elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}