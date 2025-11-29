// ignore: unused_import
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:barcode_widget/barcode_widget.dart'; // <--- IMPORTANTE

import '../../../core/models/libro.dart';
import '../../dashboard/providers/libros_provider.dart';

class AgregarLibroScreen extends StatefulWidget {
  final Libro? libroParaEditar;

  const AgregarLibroScreen({super.key, this.libroParaEditar});

  @override
  State<AgregarLibroScreen> createState() => _AgregarLibroScreenState();
}

class _AgregarLibroScreenState extends State<AgregarLibroScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  late Map<String, TextEditingController> _ctrls;
  String _estado = 'Bueno';
  
  String _categoria = 'General';
  final List<String> _categorias = [
    'General', 'Ficción', 'No Ficción', 'Ciencia', 'Historia', 
    'Tecnología', 'Arte', 'Matemáticas', 'Literatura', 
    'Comunicación', 'Ciencias Sociales', 'Libros del Estado (Minedu)', 
    'Idiomas', 'Religión', 'Otro'
  ];

  Uint8List? _imgBytes;
  bool _esEdicion = false;

  @override
  void initState() {
    super.initState();
    _esEdicion = widget.libroParaEditar != null;
    
    final l = widget.libroParaEditar;
    
    _ctrls = {
      'cod': TextEditingController(text: l?.codigoBarras ?? ''),
      'tit': TextEditingController(text: l?.titulo ?? ''),
      'aut': TextEditingController(text: l?.autor ?? ''),
      'isbn': TextEditingController(text: l?.isbn ?? ''),
      'edit': TextEditingController(text: l?.editorial ?? ''),
      'anio': TextEditingController(text: l?.anio.toString() ?? ''),
      'cop': TextEditingController(text: l?.copias.toString() ?? '1'),
      'obs': TextEditingController(text: l?.observacion ?? ''),
    };

    if (_esEdicion) {
      _estado = l!.estado;
      _imgBytes = l.fotoBytes;
      if (_categorias.contains(l.categoria)) {
        _categoria = l.categoria;
      } else {
        _categoria = 'General'; 
      }
    }
  }

  void _generarCodigo() {
    // Generamos un número aleatorio de 8 dígitos
    final codigo = "LIB${10000000 + Random().nextInt(90000000)}";
    _ctrls['cod']!.text = codigo;
    setState(() {}); // Actualiza la UI para mostrar el código de barras
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() => _imgBytes = bytes);
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    
    final p = context.read<LibrosProvider>();
    
    final libroForm = Libro(
      id: widget.libroParaEditar?.id,
      codigoBarras: _ctrls['cod']!.text,
      titulo: _ctrls['tit']!.text,
      autor: _ctrls['aut']!.text.isEmpty ? 'Anónimo' : _ctrls['aut']!.text,
      isbn: _ctrls['isbn']!.text,
      anio: int.tryParse(_ctrls['anio']!.text) ?? DateTime.now().year,
      editorial: _ctrls['edit']!.text,
      categoria: _categoria,
      copias: int.parse(_ctrls['cop']!.text),
      copiasDisponibles: int.parse(_ctrls['cop']!.text),
      estado: _estado,
      observacion: _ctrls['obs']!.text,
      fotoBytes: _imgBytes,
    );

    bool exito;
    if (_esEdicion) {
      exito = await p.editarLibro(libroForm);
    } else {
      exito = await p.agregarLibro(libroForm);
    }

    if (mounted && exito) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_esEdicion ? '✅ Libro Actualizado' : '✅ Libro Agregado'), backgroundColor: Colors.green)
      );
      
      if (_esEdicion) {
        Navigator.pop(context);
      } else {
        _limpiarFormulario();
      }
    }
  }

  void _limpiarFormulario() {
    _ctrls.forEach((_, c) => c.clear());
    setState(() {
      _imgBytes = null;
      _ctrls['cop']!.text = '1';
      _estado = 'Bueno';
      _categoria = 'General';
    });
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.select<LibrosProvider, bool>((p) => p.isLoading);
    final dorado = Theme.of(context).colorScheme.primary;

    Widget contenido = SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            if (_esEdicion) ...[
              Text("EDITANDO LIBRO", style: TextStyle(color: dorado, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 20),
            ],
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // FOTO
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 100, height: 140,
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      border: Border.all(color: dorado.withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(8),
                      image: _imgBytes != null 
                        ? DecorationImage(image: MemoryImage(_imgBytes!), fit: BoxFit.cover) 
                        : null
                    ),
                    child: _imgBytes == null ? Icon(Icons.add_a_photo, color: dorado) : null,
                  ),
                ),
                const SizedBox(width: 15),
                // CÓDIGO + BARRAS
                Expanded(
                  child: Column(
                    children: [
                      _Input(label: 'Código *', ctrl: _ctrls['cod']!, icon: Icons.qr_code, 
                        // Al escribir manualmente también actualizamos el gráfico
                        onChanged: (val) => setState((){}), 
                        suffix: IconButton(icon: const Icon(Icons.bolt, color: Colors.orange), onPressed: _generarCodigo)),
                      
                      const SizedBox(height: 10),
                      
                      // --- AQUÍ ESTÁ EL GRÁFICO DE BARRAS ---
                      if (_ctrls['cod']!.text.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white, // Fondo BLANCO obligatorio para lectores
                            borderRadius: BorderRadius.circular(8)
                          ),
                          child: Column(
                            children: [
                              BarcodeWidget(
                                barcode: Barcode.code128(), // Estándar bibliotecas
                                data: _ctrls['cod']!.text,
                                width: double.infinity,
                                height: 60,
                                drawText: true,
                              ),
                              const SizedBox(height: 5),
                              const Text("Listo para escanear/imprimir", style: TextStyle(color: Colors.black54, fontSize: 10))
                            ],
                          ),
                        ),
                      
                      const SizedBox(height: 10),
                      _Input(label: 'ISBN (Opcional)', ctrl: _ctrls['isbn']!, icon: Icons.numbers),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 20),

            // RESTO DEL FORMULARIO
            _Input(label: 'Título del Libro *', ctrl: _ctrls['tit']!, icon: Icons.book, req: true),
            const SizedBox(height: 15),
            Row(children: [
              Expanded(child: _Input(label: 'Autor', ctrl: _ctrls['aut']!, icon: Icons.person)),
              const SizedBox(width: 10),
              Expanded(child: _Input(label: 'Año', ctrl: _ctrls['anio']!, isNum: true)),
            ]),
            const SizedBox(height: 15),

            Row(children: [
              Expanded(
                flex: 1, 
                child: _Input(label: 'Editorial', ctrl: _ctrls['edit']!, icon: Icons.business)
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  value: _categoria,
                  dropdownColor: Colors.grey[900],
                  isExpanded: true,
                  decoration: _inputDeco('Categoría', Icons.category, dorado),
                  items: _categorias.map((e) => DropdownMenuItem(
                    value: e, 
                    child: Text(e, style: const TextStyle(color: Colors.white, fontSize: 13), overflow: TextOverflow.ellipsis)
                  )).toList(),
                  onChanged: (v) => setState(() => _categoria = v!),
                ),
              ),
            ]),
            
            const SizedBox(height: 15),

            Row(children: [
              Expanded(child: _Input(label: 'Copias *', ctrl: _ctrls['cop']!, isNum: true, req: true)),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _estado,
                  dropdownColor: Colors.grey[900],
                  decoration: _inputDeco('Estado', null, dorado),
                  items: ['Nuevo', 'Bueno', 'Regular', 'Malo'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: Colors.white)))).toList(),
                  onChanged: (v) => setState(() => _estado = v!),
                ),
              ),
            ]),
            const SizedBox(height: 15),
            _Input(label: 'Observaciones', ctrl: _ctrls['obs']!, icon: Icons.note),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: dorado, foregroundColor: Colors.black),
                onPressed: loading ? null : _guardar,
                icon: loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(_esEdicion ? Icons.update : Icons.save),
                label: Text(loading ? 'PROCESANDO...' : (_esEdicion ? 'ACTUALIZAR DATOS' : 'REGISTRAR LIBRO'), style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );

    if (_esEdicion) {
      return Scaffold(
        appBar: AppBar(title: const Text("Editar Libro")),
        body: contenido,
      );
    }

    return contenido;
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
      onChanged: onChanged, // Para actualizar el gráfico al escribir
      validator: req ? (v) => v!.isEmpty ? 'Requerido' : null : null,
      decoration: _inputDeco(label, icon, Theme.of(context).colorScheme.primary).copyWith(suffixIcon: suffix),
    );
  }
}

InputDecoration _inputDeco(String label, IconData? icon, Color color) {
  return InputDecoration(
    labelText: label,
    prefixIcon: icon != null ? Icon(icon, color: Colors.grey, size: 20) : null,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    filled: true, fillColor: Colors.black12,
  );
}