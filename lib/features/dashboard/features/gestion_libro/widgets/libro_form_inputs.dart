import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:biblio/features/dashboard/features/gestion_libro/providers/form_libro_provider.dart';

class LibroFormInputs extends StatefulWidget {
  final TextEditingController codCtrl;
  final TextEditingController titCtrl;
  final TextEditingController autCtrl;
  final TextEditingController editCtrl;
  final TextEditingController anioCtrl;
  final TextEditingController copCtrl;
  final TextEditingController obsCtrl; // NUEVO
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
  // Estado local para el contador visual
  late int _copiasCounter;

  @override
  void initState() {
    super.initState();
    // Sincronizamos el contador con lo que venga en el controlador (por si es edición)
    _copiasCounter = int.tryParse(widget.copCtrl.text) ?? 1;
  }

  void _actualizarCopias(int nuevoValor) {
    if (nuevoValor < 1) return;
    setState(() => _copiasCounter = nuevoValor);
    // TRUCO: Actualizamos el controlador de texto oculto para que el botón Guardar funcione igual
    widget.copCtrl.text = _copiasCounter.toString();
  }

  void _generarCodigo() {
    widget.codCtrl.text = "LIB${10000000 + Random().nextInt(90000000)}";
    widget.onCodigoGenerado();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FormLibroProvider>();
    final dorado = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- 1. CÓDIGO Y ISBN ---
        Row(
          children: [
            Expanded(
              child: _InputTexto(
                label: 'Código de Barras *',
                ctrl: widget.codCtrl,
                icon: Icons.qr_code,
                req: true,
                suffix: IconButton(
                  icon: Icon(Icons.refresh, color: dorado),
                  tooltip: "Generar Automático",
                  onPressed: _generarCodigo,
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _InputTexto(
                label: 'ISBN (Opcional)',
                ctrl: TextEditingController(), // Si tienes controlador pásalo, si no, uno dummy
                icon: Icons.tag,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // --- 2. DATOS PRINCIPALES ---
        _InputTexto(
          label: 'Título del Libro *',
          ctrl: widget.titCtrl,
          icon: Icons.auto_stories,
          req: true,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _InputTexto(label: 'Autor *', ctrl: widget.autCtrl, icon: Icons.person_outline, req: true),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _InputTexto(label: 'Editorial', ctrl: widget.editCtrl, icon: Icons.business),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // --- 3. AÑO Y CATEGORÍA (Validado + Dropdown) ---
        Row(
          children: [
            Expanded(
              flex: 1,
              child: _InputTexto(
                label: 'Año *',
                ctrl: widget.anioCtrl,
                icon: Icons.calendar_today,
                isNum: true,
                req: true,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requerido';
                  final n = int.tryParse(v);
                  final currentYear = DateTime.now().year;
                  if (n == null) return 'Inválido';
                  if (n < 1500 || n > currentYear + 1) return 'Año 1500-${currentYear + 1}';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              flex: 2, // Más espacio para categoría
              child: DropdownButtonFormField<String>(
                value: provider.categoriasList.contains(provider.categoria) ? provider.categoria : provider.categoriasList.first,
                items: provider.categoriasList.map((c) => DropdownMenuItem(
                  value: c, 
                  child: Text(c, style: const TextStyle(color: Colors.white))
                )).toList(),
                onChanged: (val) => provider.setCategoria(val),
                dropdownColor: const Color(0xFF2C2C2C),
                decoration: _inputDecoration('Categoría', Icons.category),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // --- 4. COPIAS (Stepper) Y ESTADO (Dropdown) ---
        Row(
          children: [
            // STEPPER CUSTOMIZADO
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Copias", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () => _actualizarCopias(_copiasCounter - 1),
                          child: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                        ),
                        Text(
                          '$_copiasCounter', 
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)
                        ),
                        InkWell(
                          onTap: () => _actualizarCopias(_copiasCounter + 1),
                          child: const Icon(Icons.add_circle_outline, color: Colors.greenAccent),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 15),
            
            // ESTADO DROPDOWN
            Expanded(
              child: DropdownButtonFormField<String>(
                value: provider.estado,
                items: ['Bueno', 'Regular', 'Malo', 'Reparación'].map((e) => DropdownMenuItem(
                  value: e, 
                  child: Text(e, style: const TextStyle(color: Colors.white))
                )).toList(),
                onChanged: (val) {
                  // Necesitas agregar setEstado en tu provider o usar una variable local si el provider no lo tiene expuesto
                  // Como el provider tiene _estado privado y getters, asumiré que agregaste un setter o método
                  // Si no existe, tendrás que agregarlo en el provider (ver abajo).
                },
                dropdownColor: const Color(0xFF2C2C2C),
                decoration: _inputDecoration('Estado', Icons.health_and_safety),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // --- 5. OBSERVACIONES (Nuevo Campo) ---
        _InputTexto(
          label: 'Observaciones (Opcional)',
          ctrl: widget.obsCtrl,
          icon: Icons.note_alt_outlined,
          maxLines: 3,
        ),
      ],
    );
  }

  // Helper para decoración consistente
  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      prefixIcon: Icon(icon, color: Colors.grey, size: 20),
      filled: true, fillColor: Colors.white10,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
    );
  }
}

// Widget Interno Reutilizable
class _InputTexto extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final IconData? icon;
  final bool isNum;
  final bool req;
  final Widget? suffix;
  final int maxLines;
  final String? Function(String?)? validator;

  const _InputTexto({
    required this.label, 
    required this.ctrl, 
    this.icon, 
    this.isNum = false, 
    this.req = false, 
    this.suffix, 
    this.maxLines = 1,
    this.validator,
  });
  
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      inputFormatters: isNum ? [FilteringTextInputFormatter.digitsOnly] : [],
      style: const TextStyle(color: Colors.white),
      maxLines: maxLines,
      validator: validator ?? (req ? (v) => v!.isEmpty ? 'Requerido' : null : null),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: icon != null ? Icon(icon, color: Colors.grey, size: 20) : null,
        suffixIcon: suffix,
        filled: true, fillColor: Colors.white10,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
    );
  }
}