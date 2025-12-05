import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/alumnos_provider.dart';
import '../widgets/alumno_dialog.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/models/alumno.dart';

class GestionAlumnosScreen extends StatefulWidget {
  const GestionAlumnosScreen({super.key});

  @override
  State<GestionAlumnosScreen> createState() => _GestionAlumnosScreenState();
}

class _GestionAlumnosScreenState extends State<GestionAlumnosScreen> {
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
    final esDirector = context.read<AuthProvider>().esDirector;
    final primaryColor = Theme.of(context).colorScheme.primary;

    // Filtro rápido en memoria
    final alumnosFiltrados = provider.alumnos.where((a) {
      final query = _filtro.toLowerCase();
      return a.nombreCompleto.toLowerCase().contains(query) ||
             a.codigo.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Column(
        children: [
          // --- 1. HEADER ENTERPRISE ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E1E),
              border: Border(bottom: BorderSide(color: Color(0xFF333333))),
            ),
            child: Row(
              children: [
                Icon(Icons.people_alt_outlined, color: primaryColor, size: 32),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Directorio de Alumnos",
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "${alumnosFiltrados.length} estudiantes registrados",
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                ),
                
                const Spacer(),

                // Barra de Búsqueda
                SizedBox(
                  width: 300,
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (val) => setState(() => _filtro = val),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre o matrícula...',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      prefixIcon: Icon(Icons.search, color: primaryColor),
                      filled: true,
                      fillColor: const Color(0xFF2C2C2C),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Botón Nuevo Alumno
                if (!esDirector)
                  ElevatedButton.icon(
                    onPressed: () => showDialog(
                      context: context, 
                      builder: (_) => const AlumnoDialog()
                    ),
                    icon: const Icon(Icons.person_add, color: Colors.black),
                    label: const Text("Nuevo Alumno"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
              ],
            ),
          ),

          // --- 2. TABLA DE DATOS ---
          Expanded(
            child: provider.isLoading
                ? Center(child: CircularProgressIndicator(color: primaryColor))
                : Theme(
                    data: Theme.of(context).copyWith(
                      cardColor: const Color(0xFF1E1E1E),
                      dividerColor: const Color(0xFF333333),
                      textTheme: const TextTheme(bodySmall: TextStyle(color: Colors.white)),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: SizedBox(
                        width: double.infinity,
                        child: PaginatedDataTable(
                          header: null,
                          rowsPerPage: 10,
                          columnSpacing: 20,
                          showCheckboxColumn: false,
                          arrowHeadColor: primaryColor,
                          columns: [
                            const DataColumn(label: Text("Estado", style: TextStyle(color: Colors.grey))),
                            const DataColumn(label: Text("Código", style: TextStyle(color: Colors.grey))),
                            const DataColumn(label: Text("Nombre Completo", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                            const DataColumn(label: Text("Grado", style: TextStyle(color: Colors.grey))),
                            const DataColumn(label: Text("Historial", style: TextStyle(color: Colors.grey))),
                            if (!esDirector)
                              const DataColumn(label: Text("Acciones", style: TextStyle(color: Colors.grey))),
                          ],
                          source: _AlumnosDataSource(
                            alumnos: alumnosFiltrados,
                            context: context,
                            esDirector: esDirector,
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// --- DATA SOURCE PARA LA TABLA ---
class _AlumnosDataSource extends DataTableSource {
  final List<Alumno> alumnos;
  final BuildContext context;
  final bool esDirector;

  _AlumnosDataSource({required this.alumnos, required this.context, required this.esDirector});

  @override
  DataRow? getRow(int index) {
    if (index >= alumnos.length) return null;
    final alumno = alumnos[index];
    
    // Lógica visual para Veto y Sanciones
    bool estaVetado = false;
    if (alumno.vetadoHasta != null) {
      estaVetado = alumno.vetadoHasta!.isAfter(DateTime.now());
    }
    final tieneStrikes = alumno.strikes > 0;

    return DataRow(
      cells: [
        // 1. Estado
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: estaVetado ? Colors.red.withOpacity(0.2) : (tieneStrikes ? Colors.orange.withOpacity(0.2) : Colors.green.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: estaVetado ? Colors.red : (tieneStrikes ? Colors.orange : Colors.green), width: 0.5),
            ),
            child: Text(
              estaVetado ? "VETADO" : (tieneStrikes ? "Strike ${alumno.strikes}" : "Activo"),
              style: TextStyle(
                color: estaVetado ? Colors.red : (tieneStrikes ? Colors.orange : Colors.green),
                fontSize: 11, fontWeight: FontWeight.bold
              ),
            ),
          ),
        ),
        // 2. Código
        DataCell(Text(alumno.codigo, style: const TextStyle(color: Colors.white70, fontFamily: 'Monospace'))),
        // 3. Nombre
        DataCell(Text(alumno.nombreCompleto, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500))),
        // 4. Grado
        DataCell(Text("${alumno.grado} - ${alumno.seccion}", style: const TextStyle(color: Colors.white70))),
        // 5. Historial
        DataCell(
          Row(children: List.generate(3, (i) => Icon(
            Icons.warning_amber_rounded, 
            size: 16, 
            color: i < alumno.strikes ? Colors.orange : Colors.grey[800]
          ))),
        ),
        // 6. Acciones
        if (!esDirector)
          DataCell(
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 20),
                  tooltip: "Editar datos",
                  onPressed: () => showDialog(
                    context: context, 
                    builder: (_) => AlumnoDialog(alumno: alumno)
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                  tooltip: "Eliminar alumno",
                  onPressed: () => _confirmarBorrado(alumno),
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => alumnos.length;
  @override
  int get selectedRowCount => 0;

  // --- DIÁLOGO DE CONFIRMACIÓN CON ADVERTENCIA ---
  void _confirmarBorrado(Alumno alumno) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Confirmar Eliminación", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Estás intentando eliminar a:", style: TextStyle(color: Colors.grey[400])),
            const SizedBox(height: 8),
            Text(alumno.nombreCompleto, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            
            // Aviso de seguridad
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                border: Border.all(color: Colors.amber),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield, color: Colors.amber, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Si el alumno tiene libros pendientes, la eliminación será bloqueada por seguridad.",
                      style: TextStyle(color: Colors.amber, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[900]),
            onPressed: () async {
              Navigator.pop(context); // Cerrar diálogo

              // Capturamos el messenger antes del await (Buenas prácticas)
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              
              // Ejecutamos el borrado con validación
              final resultado = await context.read<AlumnosProvider>().borrarAlumno(alumno.id!);
              
              // Verificamos mounted por seguridad
              if (context.mounted) {
                if (resultado['success']) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(resultado['message']),
                      backgroundColor: Colors.green[800],
                    )
                  );
                } else {
                  // Mostrar alerta visual si fue bloqueado
                  _mostrarAlertaBloqueo(context, resultado['message']);
                }
              }
            },
            child: const Text("Eliminar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- DIÁLOGO DE ERROR / BLOQUEO ---
  void _mostrarAlertaBloqueo(BuildContext context, String mensaje) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Row(children: [
          Icon(Icons.block, color: Colors.red),
          SizedBox(width: 10),
          Text("Acción Denegada", style: TextStyle(color: Colors.white))
        ]),
        content: Text(mensaje, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Entendido", style: TextStyle(color: Colors.blueAccent)),
          )
        ],
      )
    );
  }
}