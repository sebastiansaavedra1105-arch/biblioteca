import 'dart:math';
import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:provider/provider.dart';
// Import absoluto
import 'package:biblio/features/dashboard/features/gestion_libro/providers/form_libro_provider.dart';

class LibroFormInputs extends StatelessWidget {
  final TextEditingController codCtrl;
  final TextEditingController titCtrl;
  final TextEditingController autCtrl;
  final TextEditingController editCtrl;
  final TextEditingController anioCtrl;
  final TextEditingController copCtrl;
  final VoidCallback onCodigoGenerado;

  const LibroFormInputs({
    super.key,
    required this.codCtrl,
    required this.titCtrl,
    required this.autCtrl,
    required this.editCtrl,
    required this.anioCtrl,
    required this.copCtrl,
    required this.onCodigoGenerado,
  });

  void _generarCodigo() {
    codCtrl.text = "LIB${10000000 + Random().nextInt(90000000)}";
    onCodigoGenerado();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FormLibroProvider>();

    // Definimos una constante para el espacio vertical, así es uniforme
    const double espacioVertical = 24.0;

    return Column(
      children: [
        // 1. INPUT CÓDIGO DE BARRAS
        Row(
          children: [
            Expanded(
              child: _Input(
                label: 'Código de Barras *',
                ctrl: codCtrl,
                icon: Icons.qr_code,
                onChanged: (v) => onCodigoGenerado(), 
                suffix: IconButton(
                  icon: const Icon(Icons.bolt, color: Colors.orange),
                  tooltip: "Generar Código Aleatorio",
                  onPressed: _generarCodigo,
                ),
              ),
            ),
          ],
        ),

        // --- 2. VISUALIZADOR 3D (REDUCIDO Y CENTRADO) ---
        if (codCtrl.text.isNotEmpty) ...[
          const SizedBox(height: 20), // Un poco más de aire arriba del código
          Center(
            child: Container(
              width: 220, 
              height: 90, 
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
                ]
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: BarcodeWidget(
                      barcode: Barcode.code128(),
                      data: codCtrl.text,
                      drawText: false, 
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    codCtrl.text, 
                    style: const TextStyle(
                      color: Colors.black, 
                      fontWeight: FontWeight.bold, 
                      fontSize: 12,
                      letterSpacing: 1.5
                    )
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 10), // Espacio después del código
        ],
        
        const SizedBox(height: espacioVertical), // Separación grande

        // 3. RESTO DE CAMPOS CON MÁS ESPACIO
        _Input(label: 'Título del Libro *', ctrl: titCtrl, req: true),
        
        const SizedBox(height: espacioVertical), // Separación
        
        _Input(label: 'Autor', ctrl: autCtrl),
        
        const SizedBox(height: espacioVertical), // Separación

        Row(children: [
          Expanded(child: _Input(label: 'Editorial', ctrl: editCtrl)),
          const SizedBox(width: 15), // Separación horizontal un poco mayor también
          Expanded(child: _Input(label: 'Año', ctrl: anioCtrl, isNum: true)),
        ]),
        
        const SizedBox(height: espacioVertical), // Separación

        Row(children: [
          Expanded(child: _Input(label: 'Copias Físicas', ctrl: copCtrl, isNum: true)),
          const SizedBox(width: 15),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: provider.categoria,
              dropdownColor: Colors.grey[900],
              items: provider.categoriasList.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 12)))).toList(),
              onChanged: (v) => provider.setCategoria(v),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Categoría',
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true, fillColor: Colors.white10,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16), // Padding interno más cómodo
              ),
            ),
          ),
        ]),
      ],
    );
  }
}

class _Input extends StatelessWidget {
  final String label; final TextEditingController ctrl; final IconData? icon; final bool isNum; final bool req; final Widget? suffix; final Function(String)? onChanged;
  const _Input({required this.label, required this.ctrl, this.icon, this.isNum = false, this.req = false, this.suffix, this.onChanged});
  
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      onChanged: onChanged,
      validator: req ? (v) => v!.isEmpty ? 'Requerido' : null : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: icon != null ? Icon(icon, color: Colors.grey, size: 20) : null,
        suffixIcon: suffix,
        filled: true, fillColor: Colors.white10,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16), // Inputs más altos y cómodos
      ),
    );
  }
}