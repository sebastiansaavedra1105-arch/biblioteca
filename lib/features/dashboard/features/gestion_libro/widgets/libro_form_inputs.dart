import 'package:flutter/material.dart';
// ignore: unnecessary_import
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:barcode_widget/barcode_widget.dart'; 
import '../providers/form_libro_provider.dart';

class LibroFormInputs extends StatefulWidget {
  final TextEditingController codCtrl;
  final TextEditingController titCtrl;
  final TextEditingController autCtrl;
  final TextEditingController editCtrl;
  final TextEditingController anioCtrl;
  final TextEditingController copCtrl;
  final TextEditingController obsCtrl;
  final VoidCallback onCodigoGenerado;

  const LibroFormInputs({
    super.key,
    required this.codCtrl,
    required this.titCtrl,
    required this.autCtrl,
    required this.editCtrl,
    required this.anioCtrl,
    required this.copCtrl,
    required this.obsCtrl,
    required this.onCodigoGenerado,
  });

  @override
  State<LibroFormInputs> createState() => _LibroFormInputsState();
}

class _LibroFormInputsState extends State<LibroFormInputs> {
  @override
  void initState() {
    super.initState();
    // Escuchar cambios para actualizar (y ocultar/mostrar) el código en tiempo real
    widget.codCtrl.addListener(() {
      if (mounted) setState(() {});
    });
  }

  void _seleccionarAnio() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Seleccionar Año"),
          content: SizedBox(
            width: 300,
            height: 300,
            child: YearPicker(
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
              selectedDate: DateTime.now(),
              onChanged: (DateTime dateTime) {
                widget.anioCtrl.text = dateTime.year.toString();
                Navigator.pop(context);
              },
            ),
          ),
        );
      },
    );
  }

  void _cambiarCopias(int delta) {
    int valorActual = int.tryParse(widget.copCtrl.text) ?? 1;
    int nuevoValor = valorActual + delta;
    if (nuevoValor < 1) nuevoValor = 1;
    widget.copCtrl.text = nuevoValor.toString();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final formProvider = context.watch<FormLibroProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Lógica para saber si mostrar el código (si hay texto y no son solo espacios)
    final bool mostrarCodigo = widget.codCtrl.text.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. CÓDIGO DE BARRAS INPUT
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _InputTexto(
                label: "Código de Barras / ISBN",
                ctrl: widget.codCtrl,
                icon: Icons.qr_code,
                req: true,
              ),
            ),
            const SizedBox(width: 10),
            // Botón Generar
            SizedBox(
              height: 55,
              width: 55,
              child: IconButton.filled(
                onPressed: widget.onCodigoGenerado,
                icon: const Icon(Icons.auto_fix_high),
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.secondary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                tooltip: "Generar Automático",
              ),
            ),
          ],
        ),
        
        // --- VISTA PREVIA DEL CÓDIGO (MÁS GRANDE) ---
        if (mostrarCodigo)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20), // Más espacio vertical
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white, // Fondo blanco para que el lector pueda leerlo
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))
                  ]
                ),
                width: 280, // MÁS ANCHO (Antes era 220)
                height: 90, // MÁS ALTO (Antes era 60)
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: BarcodeWidget(
                        barcode: Barcode.code128(),
                        data: widget.codCtrl.text,
                        drawText: true,
                        style: const TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),
                        textPadding: 5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        
        const SizedBox(height: 10),

        // 2. DATOS PRINCIPALES
        _InputTexto(label: "Título de la Obra", ctrl: widget.titCtrl, icon: Icons.title, req: true),
        const SizedBox(height: 15),
        _InputTexto(label: "Autor(es)", ctrl: widget.autCtrl, icon: Icons.person, req: true),
        const SizedBox(height: 15),

        // 3. EDITORIAL Y AÑO
        Row(
          children: [
            Expanded(
              child: _InputTexto(label: "Editorial (Opcional)", ctrl: widget.editCtrl, icon: Icons.business, req: false),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: GestureDetector(
                onTap: _seleccionarAnio,
                child: AbsorbPointer(
                  child: _InputTexto(
                    label: "Año", 
                    ctrl: widget.anioCtrl, 
                    icon: Icons.calendar_today, 
                    req: true,
                    suffix: const Icon(Icons.arrow_drop_down),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),

        // 4. CATEGORÍA Y COPIAS
        Row(
          children: [
            Expanded(
              flex: 3,
              child: DropdownButtonFormField<String>(
                value: formProvider.categoria,
                items: formProvider.categoriasList.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => formProvider.setCategoria(val),
                decoration: const InputDecoration(labelText: "Categoría", prefixIcon: Icon(Icons.category)),
                isExpanded: true,
              ),
            ),
            const SizedBox(width: 15),
            
            Expanded(
              flex: 2,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: "Copias",
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () => _cambiarCopias(-1),
                      child: Icon(Icons.remove_circle_outline, color: colorScheme.error, size: 26),
                    ),
                    Text(
                      widget.copCtrl.text.isEmpty ? "1" : widget.copCtrl.text,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    InkWell(
                      onTap: () => _cambiarCopias(1),
                      child: Icon(Icons.add_circle_outline, color: colorScheme.primary, size: 26),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),

        // 5. ESTADO Y OBSERVACIONES
        DropdownButtonFormField<String>(
          value: formProvider.estado,
          items: formProvider.estadosList.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (val) => formProvider.setEstado(val),
          decoration: const InputDecoration(labelText: "Estado Físico", prefixIcon: Icon(Icons.health_and_safety)),
        ),
        const SizedBox(height: 15),

        _InputTexto(
          label: "Observaciones (Opcional)",
          ctrl: widget.obsCtrl,
          icon: Icons.note,
          maxLines: 3,
          req: false,
        ),
      ],
    );
  }
}

class _InputTexto extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final IconData? icon;
  final bool req;
  final int maxLines;
  final Widget? suffix;

  const _InputTexto({required this.label, required this.ctrl, this.icon, this.req = false, this.maxLines = 1, this.suffix});
  
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      validator: req ? (v) => v!.isEmpty ? 'Requerido' : null : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, size: 20) : null,
        suffixIcon: suffix,
      ),
    );
  }
}