// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Imports para PDF
import 'package:pdf/widgets.dart' as pw; 
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

// Imports Locales (Absolutos para evitar errores)
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
  final TextEditingController obsCtrl;

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
    required this.obsCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final formP = context.watch<FormLibroProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // BOTÓN PRINCIPAL: GUARDAR
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton.icon(
            onPressed: formP.isLoading ? null : () => _guardar(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: formP.isLoading 
                ? Container(width: 24, height: 24, padding: const EdgeInsets.all(2), child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) 
                : const Icon(Icons.save),
            label: Text(
              formP.isLoading ? "GUARDANDO..." : (esEdicion ? "ACTUALIZAR LIBRO" : "REGISTRAR LIBRO"),
              style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
          ),
        ),

        // BOTÓN SECUNDARIO: PDF
        if (esEdicion) ...[
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _generarEtiquetas(context),
              icon: const Icon(Icons.print),
              label: const Text("Imprimir Etiquetas (PDF)"),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: colorScheme.secondary),
                foregroundColor: colorScheme.secondary,
              ),
            ),
          ),
        ]
      ],
    );
  }

  Future<void> _guardar(BuildContext context) async {
    final formP = context.read<FormLibroProvider>();
    final librosP = context.read<LibrosProvider>();

    if (!formP.formKey.currentState!.validate()) return;

    formP.setLoading(true);

    final copias = int.tryParse(copCtrl.text) ?? 1;
    final disponibles = esEdicion 
        ? (libroOriginal!.copiasDisponibles + (copias - libroOriginal!.copias))
        : copias;

    final nuevoLibro = Libro(
      id: esEdicion ? libroOriginal!.id : null,
      codigoBarras: codCtrl.text.trim(),
      titulo: titCtrl.text.trim(),
      autor: autCtrl.text.trim(),
      isbn: "N/A", 
      anio: int.tryParse(anioCtrl.text) ?? DateTime.now().year,
      editorial: editCtrl.text.trim(),
      categoria: formP.categoria,
      copias: copias,
      copiasDisponibles: disponibles < 0 ? 0 : disponibles,
      estado: formP.estado,
      observacion: obsCtrl.text.trim(),
      fotoBytes: formP.fotoBytes,
    );

    bool exito;
    if (esEdicion) {
      // CORRECCIÓN AQUÍ: Usamos 'editarLibro' que es el método que SÍ existe
      exito = await librosP.editarLibro(nuevoLibro);
    } else {
      exito = await librosP.agregarLibro(nuevoLibro);
    }

    formP.setLoading(false);

    if (exito) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(esEdicion ? "Libro actualizado" : "Libro registrado"),
          backgroundColor: Colors.green,
        )
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${librosP.error}"), backgroundColor: Colors.red)
      );
    }
  }

  Future<void> _generarEtiquetas(BuildContext context) async {
    if (libroOriginal == null) return;
    final l = libroOriginal!;

    await Printing.layoutPdf(
      onLayout: (format) async {
        final doc = pw.Document();
        
        doc.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Wrap(
                spacing: 10,
                runSpacing: 10,
                children: List.generate(l.copias, (index) {
                  return pw.Container(
                    width: 180,
                    height: 90,
                    padding: const pw.EdgeInsets.all(5),
                    decoration: pw.BoxDecoration(border: pw.Border.all()),
                    child: pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Text(
                          l.titulo.length > 25 ? "${l.titulo.substring(0, 25)}..." : l.titulo,
                          style: const pw.TextStyle(fontSize: 10),
                          textAlign: pw.TextAlign.center
                        ),
                        pw.SizedBox(height: 5),
                        pw.BarcodeWidget(
                          barcode: pw.Barcode.code128(),
                          data: l.codigoBarras,
                          width: 140,
                          height: 40,
                          drawText: true,
                          textStyle: const pw.TextStyle(fontSize: 8)
                        ),
                        pw.Text("Copia ${index + 1} de ${l.copias}", style: const pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                  );
                }),
              );
            },
          ),
        );
        return doc.save();
      },
    );
  }
}