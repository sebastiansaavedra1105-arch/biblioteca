// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Imports para PDF y Códigos de Barras
// Nota: Eliminamos 'package:pdf/pdf.dart' porque no se usaba directamente y causaba advertencia.
import 'package:pdf/widgets.dart' as pw; 
import 'package:printing/printing.dart';

// Imports Locales
import 'package:biblio/features/dashboard/features/gestion_libro/providers/form_libro_provider.dart';
import 'package:biblio/features/dashboard/providers/libros_provider.dart'; 
import 'package:biblio/core/models/libro.dart';

class LibroActionButtons extends StatelessWidget {
  final bool esEdicion;
  final Libro? libroOriginal;
  
  // Controladores
  final TextEditingController codCtrl;
  final TextEditingController titCtrl;
  final TextEditingController autCtrl;
  final TextEditingController editCtrl;
  final TextEditingController anioCtrl;
  final TextEditingController copCtrl;
  final TextEditingController obsCtrl; // Controlador de Observaciones

  const LibroActionButtons({
    super.key,
    required this.esEdicion,
    this.libroOriginal,
    required this.codCtrl,
    required this.titCtrl,
    required this.autCtrl,
    required this.editCtrl,
    required this.anioCtrl,
    required this.copCtrl,
    required this.obsCtrl, // Recibido correctamente
  });

  @override
  Widget build(BuildContext context) {
    final formP = context.watch<FormLibroProvider>();
    final globalP = context.read<LibrosProvider>();
    final dorado = Theme.of(context).colorScheme.primary;

    return Column(
      children: [
        // 1. BOTÓN GUARDAR PRINCIPAL
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: dorado,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
            ),
            icon: formP.isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : const Icon(Icons.save_outlined, size: 28),
            label: Text(
              formP.isLoading ? "Procesando..." : (esEdicion ? "Actualizar Libro" : "Guardar Libro"),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            onPressed: formP.isLoading ? null : () => _guardar(context, formP, globalP),
          ),
        ),
        
        const SizedBox(height: 20),

        // 2. BOTONES SECUNDARIOS (Solo en modo registro nuevo para evitar desorden en edición)
        if (!esEdicion) ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _importar(context, globalP),
                  icon: const Icon(Icons.upload_file, color: Colors.white70),
                  label: const Text("Importar CSV", style: TextStyle(color: Colors.white70)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.white24),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _imprimirCodigos(context, globalP),
                  icon: const Icon(Icons.print, color: Colors.white70),
                  label: const Text("Imprimir Códigos", style: TextStyle(color: Colors.white70)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.white24),
                  ),
                ),
              ),
            ],
          ),
        ]
      ],
    );
  }

  // --- LÓGICA DE GUARDADO ---
  Future<void> _guardar(BuildContext context, FormLibroProvider formP, LibrosProvider globalP) async {
    // 1. Validar formulario visualmente
    if (!formP.formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Revisa los campos marcados en rojo"), backgroundColor: Colors.orange)
      );
      return;
    }

    // 2. Bloquear botón
    formP.setLoading(true);

    try {
      // 3. Construir el objeto Libro limpio y validado
      final nuevoLibro = Libro(
        id: esEdicion ? libroOriginal!.id : null,
        codigoBarras: codCtrl.text.trim(),
        titulo: titCtrl.text.trim(),
        autor: autCtrl.text.trim(),
        isbn: '', 
        anio: int.tryParse(anioCtrl.text) ?? DateTime.now().year,
        editorial: editCtrl.text.trim(),
        categoria: formP.categoria,
        copias: int.parse(copCtrl.text),
        copiasDisponibles: esEdicion 
            ? libroOriginal!.copiasDisponibles 
            : int.parse(copCtrl.text), 
        estado: formP.estado, 
        observacion: obsCtrl.text.trim(), // Guardamos la observación
        fotoBytes: formP.fotoBytes,
        fotoUrl: libroOriginal?.fotoUrl,
      );

      // 4. Enviar a la base de datos
      bool exito;
      if (esEdicion) {
        exito = await globalP.editarLibro(nuevoLibro);
      } else {
        exito = await globalP.agregarLibro(nuevoLibro);
      }

      formP.setLoading(false);

      if (context.mounted && exito) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(esEdicion ? "✅ Libro actualizado correctamente" : "✅ Libro guardado exitosamente"),
            backgroundColor: Colors.green[800],
            behavior: SnackBarBehavior.floating,
          )
        );

        if (esEdicion) {
          Navigator.pop(context);
        } else {
          // Limpiar campos
          codCtrl.clear();
          titCtrl.clear();
          autCtrl.clear();
          editCtrl.clear();
          anioCtrl.clear();
          copCtrl.text = '1';
          obsCtrl.clear();
          formP.initData(null); 
        }
      }
    } catch (e) {
      formP.setLoading(false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Error: $e"), backgroundColor: Colors.red)
        );
      }
    }
  }

  // --- LÓGICA DE IMPORTACIÓN ---
  Future<void> _importar(BuildContext context, LibrosProvider globalP) async {
    final msg = await globalP.importarLibrosDesdeCSV();
    
    // CORRECCIÓN LINTER: Quitamos '&& msg != null' porque msg siempre es String
    if (context.mounted && msg.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  // --- LÓGICA DE IMPRESIÓN (MEJORADA PARA ETIQUETAS REALES) ---
  Future<void> _imprimirCodigos(BuildContext context, LibrosProvider globalP) async {
    final libros = globalP.libros;
    if (libros.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No hay libros para imprimir")));
      return;
    }

    await Printing.layoutPdf(
      onLayout: (format) async {
        final doc = pw.Document();
        
        // Creamos una lista de etiquetas
        doc.addPage(
          pw.MultiPage(
            pageFormat: format,
            build: (pw.Context context) {
              return [
                pw.Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  children: libros.map((l) {
                    // CADA ETIQUETA
                    return pw.Container(
                      width: 180,
                      height: 80,
                      padding: const pw.EdgeInsets.all(5),
                      decoration: pw.BoxDecoration(border: pw.Border.all()),
                      child: pw.Column(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          // Título truncado
                          pw.Text(
                            l.titulo.length > 25 ? "${l.titulo.substring(0, 25)}..." : l.titulo,
                            style: const pw.TextStyle(fontSize: 8),
                            textAlign: pw.TextAlign.center
                          ),
                          pw.SizedBox(height: 5),
                          // CÓDIGO DE BARRAS REAL (Escaneable)
                          pw.BarcodeWidget(
                            barcode: pw.Barcode.code128(), // Tipo de código estándar
                            data: l.codigoBarras,
                            width: 150,
                            height: 40,
                            drawText: true,
                            textStyle: const pw.TextStyle(fontSize: 8)
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                )
              ];
            },
          ),
        );
        return doc.save();
      },
    );
  }
}