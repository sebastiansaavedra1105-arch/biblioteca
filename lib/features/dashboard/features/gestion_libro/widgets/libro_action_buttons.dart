// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Packages para PDF
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw; 
import 'package:printing/printing.dart';

import 'package:biblio/features/dashboard/features/gestion_libro/providers/form_libro_provider.dart';
import 'package:biblio/features/dashboard/providers/libros_provider.dart'; 
import 'package:biblio/core/models/libro.dart';

class LibroActionButtons extends StatelessWidget {
  final bool esEdicion;
  final Libro? libroOriginal;
  
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
          height: 50,
          child: ElevatedButton.icon(
            onPressed: formP.isLoading ? null : () => _guardar(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 4,
            ),
            icon: formP.isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                : const Icon(Icons.save),
            label: Text(
              formP.isLoading ? "PROCESANDO..." : (esEdicion ? "ACTUALIZAR DATOS" : "REGISTRAR LIBRO"),
              style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ),
        ),
        
        const SizedBox(height: 20),

        // ACCIONES SECUNDARIAS
        Row(
          children: [
            // IMPORTAR (Solo si es nuevo)
            if (!esEdicion)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _importarCSV(context),
                  icon: const Icon(Icons.upload_file),
                  label: const Text("Importar CSV"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: colorScheme.primary),
                  ),
                ),
              ),
            
            if (!esEdicion) const SizedBox(width: 10),

            // IMPRIMIR ETIQUETAS (Siempre visible)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _imprimirEtiquetas(context),
                icon: const Icon(Icons.print),
                label: const Text("Imprimir Códigos"),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: colorScheme.secondary),
                  foregroundColor: colorScheme.secondary,
                ),
              ),
            ),
          ],
        )
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
      editorial: editCtrl.text.trim().isEmpty ? 'Sin Editorial' : editCtrl.text.trim(),
      categoria: formP.categoria,
      copias: copias,
      copiasDisponibles: disponibles < 0 ? 0 : disponibles,
      estado: formP.estado,
      observacion: obsCtrl.text.trim(),
      fotoBytes: formP.fotoBytes,
    );

    bool exito;
    if (esEdicion) {
      exito = await librosP.editarLibro(nuevoLibro);
    } else {
      exito = await librosP.agregarLibro(nuevoLibro);
    }

    formP.setLoading(false);

    if (exito && context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(esEdicion ? "Libro actualizado" : "Libro registrado"), backgroundColor: Colors.green)
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${librosP.error}"), backgroundColor: Colors.red)
      );
    }
  }

  // --- CORRECCIÓN AQUÍ: Usamos el nombre y tipo de retorno correcto ---
  Future<void> _importarCSV(BuildContext context) async {
    final provider = context.read<LibrosProvider>();
    
    // Llamada al método real de tu Provider
    final mensaje = await provider.importarLibrosDesdeCSV();
    
    if (context.mounted) {
      if (mensaje == "Cancelado") return;

      final esExito = mensaje.startsWith("Éxito");
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje), 
          backgroundColor: esExito ? Colors.green : Colors.red
        )
      );

      if (esExito) {
        Navigator.pop(context); // Cerrar pantalla si salió bien
      }
    }
  }

  Future<void> _imprimirEtiquetas(BuildContext context) async {
    String titulo = esEdicion ? libroOriginal!.titulo : titCtrl.text;
    String codigo = esEdicion ? libroOriginal!.codigoBarras : codCtrl.text;
    int cantidad = int.tryParse(copCtrl.text) ?? 1;

    if (titulo.isEmpty || codigo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Falta Título o Código")));
      return;
    }

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
                children: List.generate(cantidad, (index) {
                  return pw.Container(
                    width: 150,
                    height: 70,
                    padding: const pw.EdgeInsets.all(5),
                    decoration: pw.BoxDecoration(border: pw.Border.all()),
                    child: pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Text(
                          titulo.length > 25 ? "${titulo.substring(0, 25)}..." : titulo,
                          style: const pw.TextStyle(fontSize: 8),
                          textAlign: pw.TextAlign.center
                        ),
                        pw.SizedBox(height: 4),
                        pw.BarcodeWidget(
                          barcode: pw.Barcode.code128(),
                          data: codigo,
                          width: 130,
                          height: 35,
                          drawText: true,
                          textStyle: const pw.TextStyle(fontSize: 7)
                        ),
                        pw.Text("Copia ${index + 1}", style: const pw.TextStyle(fontSize: 6)),
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