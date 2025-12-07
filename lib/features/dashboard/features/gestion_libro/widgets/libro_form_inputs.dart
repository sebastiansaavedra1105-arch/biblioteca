import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
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
  Widget build(BuildContext context) {
    final formProvider = context.watch<FormLibroProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // --- CÓDIGO DE BARRAS (Con botón generador) ---
        Row(
          children: [
            Expanded(
              child: _InputTexto(
                label: "Código de Barras",
                ctrl: widget.codCtrl,
                icon: Icons.qr_code,
                req: true,
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filled(
              onPressed: widget.onCodigoGenerado,
              icon: const Icon(Icons.auto_fix_high),
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.secondary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              tooltip: "Generar Automático",
            ),
          ],
        ),
        const SizedBox(height: 15),

        // --- TÍTULO Y AUTOR ---
        _InputTexto(label: "Título del Libro", ctrl: widget.titCtrl, icon: Icons.title, req: true),
        const SizedBox(height: 15),
        _InputTexto(label: "Autor", ctrl: widget.autCtrl, icon: Icons.person, req: true),
        const SizedBox(height: 15),

        // --- FILA 3: EDITORIAL Y AÑO ---
        Row(
          children: [
            Expanded(child: _InputTexto(label: "Editorial", ctrl: widget.editCtrl, icon: Icons.business)),
            const SizedBox(width: 15),
            Expanded(child: _InputTexto(label: "Año", ctrl: widget.anioCtrl, icon: Icons.calendar_today, isNum: true)),
          ],
        ),
        const SizedBox(height: 15),

        // --- FILA 4: CATEGORÍA Y COPIAS ---
        Row(
          children: [
            Expanded(
              flex: 2,
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
              flex: 1,
              child: _InputTexto(label: "Copias", ctrl: widget.copCtrl, isNum: true, icon: Icons.copy),
            ),
          ],
        ),
        const SizedBox(height: 15),

        // --- FILA 5: ESTADO (DROPDOWN) ---
        DropdownButtonFormField<String>(
          value: formProvider.estado,
          items: formProvider.estadosList.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (val) => formProvider.setEstado(val),
          decoration: const InputDecoration(labelText: "Estado Físico", prefixIcon: Icon(Icons.health_and_safety)),
        ),
        const SizedBox(height: 15),

        // --- OBSERVACIONES ---
        _InputTexto(
          label: "Observaciones (Opcional)",
          ctrl: widget.obsCtrl,
          icon: Icons.note,
          maxLines: 3,
        ),
      ],
    );
  }
}

// Widget Interno Simplificado (Usa el tema global automáticamente)
class _InputTexto extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final IconData? icon;
  final bool isNum;
  final bool req;
  final int maxLines;

  const _InputTexto({
    required this.label, 
    required this.ctrl, 
    this.icon, 
    this.isNum = false, 
    this.req = false, 
    this.maxLines = 1,
  });
  
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      inputFormatters: isNum ? [FilteringTextInputFormatter.digitsOnly] : [],
      maxLines: maxLines,
      validator: req ? (v) => v!.isEmpty ? 'Requerido' : null : null,
      // La decoración viene del AppTheme, solo agregamos lo específico
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, size: 20) : null,
      ),
    );
  }
}