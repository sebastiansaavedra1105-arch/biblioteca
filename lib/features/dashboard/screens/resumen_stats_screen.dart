import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/libros_provider.dart';
import '../widgets/stat_card.dart';

class ResumenStatsScreen extends StatelessWidget {
  const ResumenStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Consumer<LibrosProvider>(
      builder: (context, provider, child) {
        final stats = provider.estadisticas;
        final totalLibros = stats['totalLibros'] ?? 0;
        final prestamosActivos = stats['prestamosActivos'] ?? 0;
        final librosDisponibles = stats['librosDisponibles'] ?? 0;
        
        // --- 1. CÁLCULO DE VENCIDOS ---
        final now = DateTime.now();
        int conteoVencidos = 0;
        
        for (var p in provider.prestamosActivos) {
          final entregaStr = p['fecha_entrega'] as String?;
          if (entregaStr != null) {
            final entrega = DateTime.parse(entregaStr);
            if (now.isAfter(entrega)) {
              conteoVencidos++;
            }
          }
        }

        // --- 2. ACTIVIDAD RECIENTE ---
        final actividad = provider.actividadReciente;

        // ESTADO VACÍO
        if (totalLibros == 0 && !provider.isLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.library_books_outlined,
                  size: 80, 
                  color: colorScheme.secondary.withOpacity(0.3)
                ),
                const SizedBox(height: 20),
                Text(
                  "Base de datos vacía", 
                  style: textTheme.headlineSmall?.copyWith( // Usamos headlineSmall (Sencillo)
                    color: colorScheme.secondary.withOpacity(0.5)
                  )
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- ENCABEZADO SENCILLO ---
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Hola, Admin", 
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.secondary.withOpacity(0.7),
                      fontWeight: FontWeight.bold
                    )
                  ),
                  const SizedBox(height: 4),
                  // CAMBIO 1: Fecha con estilo sencillo (headlineSmall en vez de displaySmall)
                  Text(
                    DateFormat('d ' 'MMMM, yyyy', 'es').format(now), 
                    style: textTheme.headlineSmall?.copyWith( 
                      fontWeight: FontWeight.bold,
                      color: colorScheme.secondary 
                    )
                  ),
                ],
              ),
              
              const SizedBox(height: 30),
              
              // --- TARJETAS SIMPLES ---
              Wrap(
                spacing: 16, 
                runSpacing: 16, 
                children: [
                  SizedBox(
                    width: 260,
                    child: StatCard(
                      title: 'Total Libros',
                      value: totalLibros.toString(),
                      icon: Icons.library_books,
                      color: colorScheme.secondary, 
                    ),
                  ),
                  SizedBox(
                    width: 260,
                    child: StatCard(
                      title: 'Disponibles',
                      value: librosDisponibles.toString(),
                      icon: Icons.check_circle_outline,
                      color: colorScheme.secondary.withOpacity(0.7), 
                    ),
                  ),
                  SizedBox(
                    width: 260,
                    child: StatCard(
                      title: 'Prestados',
                      value: prestamosActivos.toString(),
                      icon: Icons.upload_rounded, 
                      color: colorScheme.primary, 
                    ),
                  ),
                  SizedBox(
                    width: 260,
                    child: StatCard(
                      title: 'Vencidos',
                      value: conteoVencidos.toString(), 
                      icon: Icons.warning_amber_rounded,
                      color: colorScheme.error, 
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),
              
              // --- TÍTULO SECCIÓN ---
              // CAMBIO 2: Título sencillo (titleLarge en vez de headlineMedium)
              Text(
                "Actividad Reciente",
                style: textTheme.titleLarge?.copyWith( 
                  fontWeight: FontWeight.bold,
                  color: colorScheme.secondary,
                  fontSize: 20 // Tamaño ajustado para que no sea gigante
                ),
              ),
              const SizedBox(height: 15),
              
              // --- LISTA DE ACTIVIDAD ---
              if (actividad.isEmpty)
                Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.secondary.withOpacity(0.1)),
                  ),
                  child: Center(
                    child: Text(
                      "Sin movimientos hoy",
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.secondary.withOpacity(0.5)
                      ),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: actividad.length,
                  itemBuilder: (context, index) {
                    final item = actividad[index];
                    
                    final tituloLibro = item['libro_titulo'] ?? 'Desconocido';
                    final nombreAlumno = item['alumno_nombre'] ?? 'Alumno';
                    final fechaPrestamo = DateTime.parse(item['fecha_prestamo']);
                    final esActivo = item['activo'] == 1;
                    
                    bool devolucionTardia = false;
                    if (!esActivo && item['fecha_devolucion_real'] != null && item['fecha_entrega'] != null) {
                       final entrega = DateTime.parse(item['fecha_entrega']);
                       final devolucion = DateTime.parse(item['fecha_devolucion_real']);
                       if (devolucion.isAfter(entrega)) {
                         devolucionTardia = true;
                       }
                    }

                    Color colorIcono;
                    IconData icono;
                    String textoEstado;

                    if (esActivo) {
                      colorIcono = colorScheme.primary; 
                      icono = Icons.arrow_outward_rounded;
                      textoEstado = "Prestado";
                    } else if (devolucionTardia) {
                      colorIcono = colorScheme.error; 
                      icono = Icons.priority_high_rounded;
                      textoEstado = "Tarde";
                    } else {
                      colorIcono = colorScheme.secondary; 
                      icono = Icons.check;
                      textoEstado = "Devuelto";
                    }

                    final fechaMostrar = esActivo 
                        ? fechaPrestamo 
                        : DateTime.parse(item['updated_at'] ?? item['fecha_prestamo']);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.withOpacity(0.2))
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: colorIcono.withOpacity(0.1),
                          radius: 18,
                          child: Icon(icono, color: colorIcono, size: 18),
                        ),
                        title: Text(
                          tituloLibro,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1, 
                          overflow: TextOverflow.ellipsis
                        ),
                        subtitle: Text("$nombreAlumno • ${DateFormat('HH:mm').format(fechaMostrar)}"),
                        trailing: Text(
                          textoEstado,
                          style: TextStyle(
                            color: colorIcono, 
                            fontWeight: FontWeight.bold,
                            fontSize: 12
                          )
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}