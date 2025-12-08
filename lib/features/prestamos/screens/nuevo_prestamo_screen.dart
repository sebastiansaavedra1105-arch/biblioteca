import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

// Modelos y Providers
import '../../../core/models/libro.dart';
import '../../../core/models/alumno.dart';
import '../../dashboard/providers/libros_provider.dart';
import '../../alumnos/providers/alumnos_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/prestamos_provider.dart';

// Widgets
import '../widgets/prestamo_search_field.dart';
import '../widgets/seleccion_card.dart';

class NuevoPrestamoScreen extends StatefulWidget {
  const NuevoPrestamoScreen({super.key});

  @override
  State<NuevoPrestamoScreen> createState() => _NuevoPrestamoScreenState();
}

class _NuevoPrestamoScreenState extends State<NuevoPrestamoScreen> {
  final _libroCtrl = TextEditingController();
  final _alumnoCtrl = TextEditingController();
  
  Libro? _libroSeleccionado;
  Alumno? _alumnoSeleccionado;
  DateTime _fechaEntrega = DateTime.now().add(const Duration(days: 3));

  @override
  void initState() {
    super.initState();
    // Carga inicial de datos globales (Libros y Alumnos)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AlumnosProvider>().cargarAlumnos();
      context.read<LibrosProvider>().cargarTodo();
    });
  }

  // --- LÓGICA DE BÚSQUEDA ---
  void _buscarLibro() {
    final query = _libroCtrl.text.trim().toLowerCase();
    if (query.isEmpty) return;

    final provider = context.read<LibrosProvider>();
    try {
      final libro = provider.libros.firstWhere(
        (l) => l.codigoBarras.toLowerCase() == query || 
               l.titulo.toLowerCase().contains(query),
      );
      
      if (libro.copiasDisponibles > 0) {
        setState(() {
          _libroSeleccionado = libro;
          _libroCtrl.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Libro seleccionado: ${libro.titulo}"), backgroundColor: Colors.green)
        );
      } else {
        _mostrarError("El libro '${libro.titulo}' no tiene stock disponible.");
      }
    } catch (e) {
      _mostrarError("Libro no encontrado. Verifique el código o título.");
    }
  }

  void _buscarAlumno() {
    final query = _alumnoCtrl.text.trim().toLowerCase();
    if (query.isEmpty) return;

    final provider = context.read<AlumnosProvider>();
    try {
      final alumno = provider.alumnos.firstWhere(
        (a) => a.codigo.toLowerCase() == query || 
               a.nombreCompleto.toLowerCase().contains(query),
      );

      if (alumno.vetadoHasta != null && alumno.vetadoHasta!.isAfter(DateTime.now())) {
        _mostrarError("ALUMNO VETADO hasta ${DateFormat('dd/MM/yyyy').format(alumno.vetadoHasta!)}");
        return;
      }

      setState(() {
        _alumnoSeleccionado = alumno;
        _alumnoCtrl.clear();
      });
    } catch (e) {
      _mostrarError("Alumno no encontrado.");
    }
  }

  void _mostrarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red)
    );
  }

  // --- PROCESAR PRÉSTAMO ---
  // Recibimos 'ctx' porque es el contexto que tiene acceso al PrestamosProvider local
  Future<void> _procesarPrestamo(BuildContext ctx) async {
    if (_libroSeleccionado == null || _alumnoSeleccionado == null) return;

    // CORRECCIÓN: Acceso a mapa ['id'] en lugar de propiedad .id
    final usuarioId = ctx.read<AuthProvider>().usuarioActual?['id'] ?? 'admin';
    final prestamosP = ctx.read<PrestamosProvider>();

    final exito = await prestamosP.registrarPrestamo(
      libro: _libroSeleccionado!,
      alumno: _alumnoSeleccionado!,
      fechaEntrega: _fechaEntrega,
      usuarioId: usuarioId.toString(),
    );

    if (exito && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Préstamo registrado exitosamente"), backgroundColor: Colors.green)
      );
      setState(() {
        _libroSeleccionado = null;
        _alumnoSeleccionado = null;
        _fechaEntrega = DateTime.now().add(const Duration(days: 3));
      });
      
      if (ctx.mounted) {
        ctx.read<LibrosProvider>().cargarTodo();
      }
      
    } else if (mounted) {
      _mostrarError(prestamosP.error ?? "Error desconocido");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // SOLUCIÓN AL ERROR DE PROVIDER:
    // Inyectamos el PrestamosProvider AQUÍ mismo para esta pantalla.
    return ChangeNotifierProvider(
      create: (_) => PrestamosProvider(),
      child: Builder(
        builder: (innerContext) {
          // 'innerContext' es el que puede ver el PrestamosProvider creado arriba
          return Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  
                  // --- PASO 1: LIBRO ---
                  _StepCard(
                    index: 1,
                    title: "Material Bibliográfico",
                    child: _libroSeleccionado == null
                        ? PrestamoSearchField(
                            label: "Escanear Código o Título",
                            icon: Icons.menu_book,
                            controller: _libroCtrl,
                            onSearch: _buscarLibro,
                          )
                        : SeleccionCard(
                            titulo: _libroSeleccionado!.titulo,
                            subtitulo: "Stock: ${_libroSeleccionado!.copiasDisponibles} | ${_libroSeleccionado!.codigoBarras}",
                            icon: Icons.book,
                            colorBase: Colors.amber,
                            onDelete: () => setState(() => _libroSeleccionado = null),
                          ),
                  ),

                  const SizedBox(height: 20),

                  // --- PASO 2: ALUMNO ---
                  _StepCard(
                    index: 2,
                    title: "Estudiante Solicitante",
                    child: _alumnoSeleccionado == null
                        ? PrestamoSearchField(
                            label: "Buscar por DNI o Nombre",
                            icon: Icons.person_search,
                            controller: _alumnoCtrl,
                            onSearch: _buscarAlumno,
                          )
                        : SeleccionCard(
                            titulo: _alumnoSeleccionado!.nombreCompleto,
                            subtitulo: "${_alumnoSeleccionado!.grado} - ${_alumnoSeleccionado!.seccion}",
                            icon: Icons.person,
                            colorBase: Colors.blue,
                            onDelete: () => setState(() => _alumnoSeleccionado = null),
                          ),
                  ),

                  const SizedBox(height: 20),

                  // --- PASO 3: FECHA Y BOTÓN ---
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    color: theme.cardTheme.color,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_today, color: colorScheme.primary),
                              const SizedBox(width: 10),
                              Text("Fecha de Devolución", style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                            ],
                          ),
                          const SizedBox(height: 15),
                          
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _fechaEntrega,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) setState(() => _fechaEntrega = picked);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                border: Border.all(color: colorScheme.onSurface.withOpacity(0.2)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat('dd/MM/yyyy').format(_fechaEntrega),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                  ),
                                  const Icon(Icons.arrow_drop_down),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 30),

                          // BOTÓN DE ACCIÓN
                          // Usamos Consumer para escuchar isLoading del PrestamosProvider local
                          Consumer<PrestamosProvider>(
                            builder: (context, prestamosP, child) {
                              return SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: ElevatedButton.icon(
                                  onPressed: (_libroSeleccionado != null && _alumnoSeleccionado != null && !prestamosP.isLoading) 
                                      ? () => _procesarPrestamo(innerContext) // Usamos innerContext
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colorScheme.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 4,
                                  ),
                                  icon: prestamosP.isLoading 
                                      ? Container(width: 24, height: 24, padding: const EdgeInsets.all(2), child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                                      : const Icon(Icons.save_alt),
                                  label: Text(
                                    prestamosP.isLoading ? "PROCESANDO..." : "REGISTRAR PRÉSTAMO",
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                                  ),
                                ),
                              );
                            }
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        }
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final int index;
  final String title;
  final Widget child;

  const _StepCard({required this.index, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Theme.of(context).cardTheme.color,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.2), shape: BoxShape.circle),
                  child: Center(child: Text("$index", style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold))),
                ),
                const SizedBox(width: 10),
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.onSurface)),
              ],
            ),
            const SizedBox(height: 15),
            child,
          ],
        ),
      ),
    );
  }
}