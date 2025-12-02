// ignore_for_file: use_build_context_synchronously
// ignore: unused_import
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:barcode_widget/barcode_widget.dart';

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
  
  // Controladores de Texto
  late TextEditingController _codCtrl;
  late TextEditingController _titCtrl;
  late TextEditingController _autCtrl;
  late TextEditingController _isbnCtrl;
  late TextEditingController _editCtrl;
  late TextEditingController _anioCtrl;
  late TextEditingController _copCtrl;
  late TextEditingController _obsCtrl;

  String _estado = 'Bueno';
  String _categoria = 'General';
  
  final List<String> _categorias = [
    'General', 'Ficción', 'No Ficción', 'Ciencia', 'Historia', 
    'Tecnología', 'Arte', 'Matemáticas', 'Literatura', 
    'Comunicación', 'Ciencias Sociales', 'Minedu', 
    'Idiomas', 'Religión', 'Otro'
  ];

  Uint8List? _imgBytes;
  bool _esEdicion = false;

  @override
  void initState() {
    super.initState();
    _esEdicion = widget.libroParaEditar != null;
    final l = widget.libroParaEditar;
    
    // Inicializamos controladores
    _codCtrl = TextEditingController(text: l?.codigoBarras ?? '');
    _titCtrl = TextEditingController(text: l?.titulo ?? '');
    _autCtrl = TextEditingController(text: l?.autor ?? '');
    _isbnCtrl = TextEditingController(text: l?.isbn ?? '');
    _editCtrl = TextEditingController(text: l?.editorial ?? '');
    _anioCtrl = TextEditingController(text: l?.anio.toString() ?? '');
    _copCtrl = TextEditingController(text: l?.copias.toString() ?? '1');
    _obsCtrl = TextEditingController(text: l?.observacion ?? '');

    if (_esEdicion) {
      _estado = l!.estado;
      _imgBytes = l.fotoBytes;
      
      // Validamos que la categoría exista en la lista, si no, 'General'
      if (_categorias.contains(l.categoria)) {
        _categoria = l.categoria;
      } else {
        _categoria = 'General';
      }
    }
  }

  @override
  void dispose() {
    _codCtrl.dispose();
    _titCtrl.dispose();
    _autCtrl.dispose();
    _isbnCtrl.dispose();
    _editCtrl.dispose();
    _anioCtrl.dispose();
    _copCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  void _generarCodigo() {
    final codigo = "LIB${10000000 + Random().nextInt(90000000)}";
    _codCtrl.text = codigo;
    setState(() {}); // Para redibujar el código de barras
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery, 
      imageQuality: 30, // Comprimimos
      maxWidth: 600
    );
    
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() {
        _imgBytes = bytes;
      });
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    
    final provider = context.read<LibrosProvider>();
    
    final libroForm = Libro(
      id: widget.libroParaEditar?.id,
      codigoBarras: _codCtrl.text.trim(),
      titulo: _titCtrl.text.trim(),
      autor: _autCtrl.text.isEmpty ? 'Anónimo' : _autCtrl.text.trim(),
      isbn: _isbnCtrl.text.trim(),
      anio: int.tryParse(_anioCtrl.text) ?? DateTime.now().year,
      editorial: _editCtrl.text.trim(),
      categoria: _categoria,
      copias: int.parse(_copCtrl.text),
      // Si es nuevo, disponibles = copias. Si es editado, mantenemos el cálculo actual si es posible
      copiasDisponibles: _esEdicion 
          ? widget.libroParaEditar!.copiasDisponibles // (Podrías ajustar lógica aquí si aumentan copias)
          : int.parse(_copCtrl.text),
      estado: _estado,
      observacion: _obsCtrl.text.trim(),
      fotoBytes: _imgBytes,
      fotoUrl: widget.libroParaEditar?.fotoUrl,
    );

    bool exito;
    if (_esEdicion) {
      exito = await provider.editarLibro(libroForm);
    } else {
      exito = await provider.agregarLibro(libroForm);
    }

    if (mounted && exito) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_esEdicion ? '✅ Libro Actualizado' : '✅ Libro Agregado'), 
          backgroundColor: Colors.green
        )
      );
      
      if (_esEdicion) {
        Navigator.pop(context);
      } else {
        _limpiarFormulario();
      }
    }
  }

  void _limpiarFormulario() {
    _codCtrl.clear();
    _titCtrl.clear();
    _autCtrl.clear();
    _isbnCtrl.clear();
    _editCtrl.clear();
    _anioCtrl.clear();
    _obsCtrl.clear();
    _copCtrl.text = '1';
    
    setState(() {
      _imgBytes = null;
      _estado = 'Bueno';
      _categoria = 'General';
    });
  }

  @override
  Widget build(BuildContext context) {
    // Usamos select para escuchar solo el loading y evitar reconstrucciones masivas
    final loading = context.select<LibrosProvider, bool>((p) => p.isLoading);
    final dorado = Theme.of(context).colorScheme.primary;

    return Scaffold(
        appBar: AppBar(title: Text(_esEdicion ? "Editar Libro" : "Nuevo Libro")),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // --- SECCIÓN 1: FOTO Y CÓDIGO ---
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
                        child: _imgBytes == null 
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [Icon(Icons.add_a_photo, color: dorado), const Text("Portada", style: TextStyle(fontSize: 10))]
                            )
                          : null,
                      ),
                    ),
                    const SizedBox(width: 15),
                    
                    // CÓDIGO DE BARRAS
                    Expanded(
                      child: Column(
                        children: [
                           _Input(
                             label: 'Código *', 
                             ctrl: _codCtrl, 
                             icon: Icons.qr_code, 
                             onChanged: (val) => setState((){}), 
                             suffix: IconButton(
                               icon: const Icon(Icons.bolt, color: Colors.orange), 
                               tooltip: "Generar aleatorio",
                               onPressed: _generarCodigo
                             )
                           ),
                           
                           if (_codCtrl.text.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 10),
                              padding: const EdgeInsets.all(5),
                              color: Colors.white,
                              child: BarcodeWidget(barcode: Barcode.code128(), data: _codCtrl.text, height: 50, drawText: false),
                            )
                        ],
                      ),
                    )
                  ],
                ),
                
                const SizedBox(height: 20),

                // --- SECCIÓN 2: DATOS PRINCIPALES ---
                _Input(label: 'Título *', ctrl: _titCtrl, req: true),
                const SizedBox(height: 10),
                _Input(label: 'Autor', ctrl: _autCtrl),
                const SizedBox(height: 10),
                
                Row(children: [
                  Expanded(child: _Input(label: 'Editorial', ctrl: _editCtrl)),
                  const SizedBox(width: 10),
                  Expanded(child: _Input(label: 'Año', ctrl: _anioCtrl, isNum: true)),
                ]),
                const SizedBox(height: 10),
                
                 Row(children: [
                  Expanded(child: _Input(label: 'Copias', ctrl: _copCtrl, isNum: true)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _categoria,
                      dropdownColor: Colors.grey[900],
                      items: _categorias.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 12)))).toList(),
                      onChanged: (v) => setState(() => _categoria = v!),
                      decoration: _inputDeco('Categoría', null, dorado),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ]),
                
                const SizedBox(height: 20),
                
                // --- BOTONES ---
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: dorado, foregroundColor: Colors.black),
                    onPressed: loading ? null : _guardar,
                    child: Text(loading ? "Guardando..." : "GUARDAR LIBRO"),
                  ),
                ),

                // --- BOTÓN DE CARGA MASIVA (SOLO SI NO ES EDICIÓN) ---
                if (!_esEdicion) ...[
                  const SizedBox(height: 30),
                  const Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey)),
                      Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text("O", style: TextStyle(color: Colors.grey))),
                      Expanded(child: Divider(color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.green),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                      ),
                      icon: const Icon(Icons.file_upload, color: Colors.green),
                      label: const Text("CARGAR DESDE EXCEL (CSV)"),
                      onPressed: loading ? null : () async {
                        final mensaje = await context.read<LibrosProvider>().importarLibrosDesdeCSV();
                        
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(mensaje),
                              backgroundColor: mensaje.contains("Error") ? Colors.red : Colors.green,
                              behavior: SnackBarBehavior.floating,
                            )
                          );
                          
                          if (!mensaje.contains("Error") && !mensaje.contains("Cancelado")) {
                            // Opcional: Si quieres que cierre la pantalla al terminar
                            // Navigator.pop(context); 
                            // O limpiamos el form
                            _limpiarFormulario();
                          }
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Asegúrate de guardar tu Excel como 'CSV UTF-8'.\nOrden: Cantidad, Título, Estado, Autor, Código, Año, Editorial, Categoría",
                    style: TextStyle(color: Colors.grey, fontSize: 10),
                    textAlign: TextAlign.center,
                  )
                ]
              ],
            ),
          ),
        ),
    );
  }
}

// Widget auxiliar _Input
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
      decoration: _inputDeco(label, icon, Theme.of(context).colorScheme.primary).copyWith(suffixIcon: suffix),
    );
  }
}

InputDecoration _inputDeco(String label, IconData? icon, Color color) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.grey),
    prefixIcon: icon != null ? Icon(icon, color: Colors.grey, size: 20) : null,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    filled: true, fillColor: Colors.white10,
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white24)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: color)),
  );
}