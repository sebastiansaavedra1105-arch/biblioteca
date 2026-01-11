import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:biblio/features/alumnos/providers/alumnos_provider.dart';
import 'package:biblio/core/models/alumno.dart';

class DirectorAlumnosScreen extends StatefulWidget {
  const DirectorAlumnosScreen({super.key});

  @override
  State<DirectorAlumnosScreen> createState() => _DirectorAlumnosScreenState();
}

class _DirectorAlumnosScreenState extends State<DirectorAlumnosScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _filtro = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AlumnosProvider>().cargarAlumnos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AlumnosProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Filtro
    final alumnosFiltrados = provider.alumnos.where((a) {
      final query = _filtro.toLowerCase();
      return a.nombreCompleto.toLowerCase().contains(query) || 
             a.codigo.toLowerCase().contains(query);
    }).toList();

    return Column(
      children: [
        // --- 1. HEADER INFORMATIVO ---
        Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: colorScheme.onSurface.withOpacity(0.05))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Población Estudiantil",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface
                    )
                  ),
                  Text(
                    "${alumnosFiltrados.length} alumnos encontrados",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.6)
                    )
                  ),
                ],
              ),
              // Icono decorativo
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)
                ),
                child: Icon(Icons.school, color: colorScheme.secondary),
              )
            ],
          ),
        ),

        // --- 2. BUSCADOR ---
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (val) => setState(() => _filtro = val),
            style: TextStyle(color: colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: "Buscar por nombre, DNI o código...",
              hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
              prefixIcon: Icon(Icons.search, color: colorScheme.primary),
              suffixIcon: _filtro.isNotEmpty 
                  ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _searchCtrl.clear(); setState(() => _filtro = ''); }) 
                  : null,
              filled: true,
              fillColor: theme.cardTheme.color,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
          ),
        ),

        // --- 3. LISTA DE TARJETAS ---
        Expanded(
          child: alumnosFiltrados.isEmpty
              ? _buildEmptyState(colorScheme)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: alumnosFiltrados.length,
                  itemBuilder: (context, index) {
                    final alumno = alumnosFiltrados[index];
                    return _DirectorStudentCard(alumno: alumno);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 60, color: colorScheme.onSurface.withOpacity(0.2)),
          const SizedBox(height: 10),
          Text("No se encontraron alumnos", style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5))),
        ],
      ),
    );
  }
}

// --- TARJETA DE ALUMNO MEJORADA ---
class _DirectorStudentCard extends StatelessWidget {
  final Alumno alumno;
  const _DirectorStudentCard({required this.alumno});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Verificar estado
    final bool estaVetado = alumno.vetadoHasta != null && alumno.vetadoHasta!.isAfter(DateTime.now());

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        // Si está vetado, borde rojo sutil
        side: estaVetado ? BorderSide(color: colorScheme.error.withOpacity(0.5)) : BorderSide.none
      ),
      color: theme.cardTheme.color,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // AVATAR CON INICIALES
            CircleAvatar(
              radius: 24,
              backgroundColor: estaVetado 
                  ? colorScheme.error.withOpacity(0.1) 
                  : colorScheme.secondary.withOpacity(0.1),
              child: Text(
                alumno.nombreCompleto.isNotEmpty ? alumno.nombreCompleto[0].toUpperCase() : '?',
                style: TextStyle(
                  color: estaVetado ? colorScheme.error : colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // INFORMACIÓN CENTRAL
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alumno.nombreCompleto,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.badge_outlined, size: 14, color: colorScheme.onSurface.withOpacity(0.5)),
                      const SizedBox(width: 4),
                      Text(
                        alumno.codigo,
                        style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withOpacity(0.7)),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.class_outlined, size: 14, color: colorScheme.onSurface.withOpacity(0.5)),
                      const SizedBox(width: 4),
                      Text(
                        "${alumno.grado} - ${alumno.seccion}",
                        style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withOpacity(0.7)),
                      ),
                    ],
                  )
                ],
              ),
            ),

            // CHIP DE ESTADO (VETADO)
            if (estaVetado)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: colorScheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colorScheme.error.withOpacity(0.3))
                ),
                child: Row(
                  children: [
                    Icon(Icons.block, size: 14, color: colorScheme.error),
                    const SizedBox(width: 4),
                    Text(
                      "VETADO",
                      style: TextStyle(
                        fontSize: 10, 
                        fontWeight: FontWeight.bold, 
                        color: colorScheme.error
                      ),
                    ),
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }
}