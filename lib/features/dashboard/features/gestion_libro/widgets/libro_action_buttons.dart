// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Imports para PDF
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// Imports Locales
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
  });

  @override
  Widget build(BuildContext context) {
    final formProvider = context.watch<FormLibroProvider>();
    final globalProvider = context.read<LibrosProvider>();
    final dorado = Theme.of(context).colorScheme.primary;

    return Column(
      children: [
        // 1. BOTÓN IMPRIMIR ETIQUETA (Solo si hay código escrito)
        if (codCtrl.text.isNotEmpty) ...[
          SizedBox(
            width: double.infinity, 
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[800], 
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
              ),
              icon: const Icon(Icons.print),
              label: const Text("IMPRIMIR CÓDIGO DE BARRAS (PDF)"),
              onPressed: () => _imprimirEtiqueta(context),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // 2. BOTÓN GUARDAR
        SizedBox(
          width: double.infinity, height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: dorado, foregroundColor: Colors.black),
            onPressed: formProvider.isLoading 
              ? null 
              : () => _guardar(context, formProvider, globalProvider),
            child: Text(formProvider.isLoading ? "Procesando..." : "GUARDAR LIBRO"),
          ),
        ),

        // 3. BOTÓN IMPORTAR CSV (Solo si es nuevo)
        if (!esEdicion) ...[
          const SizedBox(height: 30),
          const Row(children: [Expanded(child: Divider(color: Colors.grey)), Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text("O", style: TextStyle(color: Colors.grey))), Expanded(child: Divider(color: Colors.grey))]),
          const SizedBox(height: 20),
          
          SizedBox(
            width: double.infinity, height: 50,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.green),
              ),
              icon: const Icon(Icons.file_upload, color: Colors.green),
              label: const Text("CARGAR DESDE EXCEL (CSV)"),
              onPressed: formProvider.isLoading 
                ? null 
                : () => _importar(context, globalProvider),
            ),
          ),
          const SizedBox(height: 10),
          const Text("Formato: CSV UTF-8 separado por comas", style: TextStyle(color: Colors.grey, fontSize: 10)),
        ]
      ],
    );
  }

  // --- LÓGICA DE GENERACIÓN DE PDF ---
  Future<void> _imprimirEtiqueta(BuildContext context) async {
    final doc = pw.Document();
    
    // Datos actuales de los campos
    final codigo = codCtrl.text;
    final titulo = titCtrl.text.isEmpty ? "Sin Título" : titCtrl.text;
    final autor = autCtrl.text.isEmpty ? "Autor Desconocido" : autCtrl.text;

    // Diseñamos la etiqueta en el PDF
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4, // Formato A4 estándar
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text("PROPIEDAD DE LA BIBLIOTECA", style: const pw.TextStyle(fontSize: 10)),
                pw.SizedBox(height: 10),
                
                // El Código de Barras
                pw.BarcodeWidget(
                  barcode: pw.Barcode.code128(),
                  data: codigo,
                  width: 200,
                  height: 80,
                ),
                pw.SizedBox(height: 5),
                pw.Text(codigo, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                
                pw.SizedBox(height: 10),
                pw.Text(titulo, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.Text(autor, style: const pw.TextStyle(fontSize: 12)),
                
                pw.SizedBox(height: 20),
                pw.Text("Recortar y pegar en el libro", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
                
                // Dibuja una línea de corte
                pw.SizedBox(height: 5),
                pw.Container(
                  width: 250, 
                  height: 150, 
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black, style: pw.BorderStyle.dashed)
                  )
                )
              ],
            ),
          );
        },
      ),
    );

    // Abre la vista previa de impresión nativa
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
    );
  }

  Future<void> _guardar(BuildContext context, FormLibroProvider formP, LibrosProvider globalP) async {
    if (!formP.validarFormulario()) return;

    formP.setLoading(true);

    final nuevoLibro = Libro(
      id: libroOriginal?.id,
      codigoBarras: codCtrl.text.trim(),
      titulo: titCtrl.text.trim(),
      autor: autCtrl.text.isEmpty ? 'Anónimo' : autCtrl.text.trim(),
      isbn: '',
      anio: int.tryParse(anioCtrl.text) ?? DateTime.now().year,
      editorial: editCtrl.text.trim(),
      categoria: formP.categoria,
      copias: int.parse(copCtrl.text),
      copiasDisponibles: esEdicion 
          ? libroOriginal!.copiasDisponibles 
          : int.parse(copCtrl.text),
      estado: formP.estado,
      observacion: '',
      fotoBytes: formP.fotoBytes,
      fotoUrl: libroOriginal?.fotoUrl,
    );

    bool exito;
    if (esEdicion) {
      exito = await globalP.editarLibro(nuevoLibro);
    } else {
      exito = await globalP.agregarLibro(nuevoLibro);
    }

    formP.setLoading(false);

    if (context.mounted && exito) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Operación exitosa"), backgroundColor: Colors.green));
      if (esEdicion) {
        Navigator.pop(context);
      } else {
        codCtrl.clear();
        titCtrl.clear();
        autCtrl.clear();
        editCtrl.clear();
        anioCtrl.clear();
        copCtrl.text = '1';
        formP.initData(null); 
      }
    }
  }

  Future<void> _importar(BuildContext context, LibrosProvider globalP) async {
    final msg = await globalP.importarLibrosDesdeCSV();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: msg.contains("Error") || msg.contains("Cancelado") ? Colors.grey : Colors.green,
        )
      );
    }
  }
}