import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/database/database_service.dart';

class AgregarLibroScreen extends StatefulWidget {
  const AgregarLibroScreen({super.key});

  @override
  State<AgregarLibroScreen> createState() => _AgregarLibroScreenState();
}

class _AgregarLibroScreenState extends State<AgregarLibroScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _codigoController = TextEditingController();
  final _tituloController = TextEditingController();
  final _autorController = TextEditingController();
  final _isbnController = TextEditingController();
  final _editorialController = TextEditingController();
  final _anioController = TextEditingController();
  final _copiasController = TextEditingController(text: '1');
  final _observacionController = TextEditingController();

  bool _isLoading = false;
  String _estadoSeleccionado = 'Bueno';
  final List<String> _estados = ['Nuevo', 'Bueno', 'Regular', 'Malo', 'Deteriorado'];
  
  File? _imageFile;
  Uint8List? _imageBytes;

  void _generarCodigoAutomatico() {
    final numero = 10000000 + Random().nextInt(90000000); 
    setState(() {
      _codigoController.text = "LIB$numero";
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    // Comprimimos la imagen para que la BD no pese demasiado
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600, 
      imageQuality: 50 
    );

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageFile = File(pickedFile.path);
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _guardarLibro() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final int copias = int.parse(_copiasController.text);
      
      await DatabaseService().insertarLibro({
        'codigo_barras': _codigoController.text,
        'titulo': _tituloController.text,
        'autor': _autorController.text.isEmpty ? 'Anónimo' : _autorController.text,
        'isbn': _isbnController.text.isEmpty ? 'S/N' : _isbnController.text,
        'anio': int.tryParse(_anioController.text) ?? DateTime.now().year,
        'editorial': _editorialController.text.isEmpty ? 'Sin Editorial' : _editorialController.text,
        'categoria': 'General', 
        'copias': copias,
        'copias_disponibles': copias,
        'estado': _estadoSeleccionado,
        'observacion': _observacionController.text,
        'foto_bytes': _imageBytes,
      });

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Libro agregado correctamente'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true); 
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: El código de barras ya existe.'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorDorado = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('AGREGAR NUEVO LIBRO')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 120,
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorDorado.withOpacity(0.5)),
                      image: _imageFile != null 
                        ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                        : null
                    ),
                    child: _imageFile == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate, color: colorDorado, size: 40),
                              const SizedBox(height: 10),
                              Text("Agregar Portada", textAlign: TextAlign.center, style: TextStyle(color: colorDorado, fontSize: 12))
                            ],
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 25),

              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[800]!)
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _codigoController,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            decoration: const InputDecoration(
                              labelText: 'Código de Barras *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.qr_code_scanner), // CORREGIDO AQUÍ
                              filled: true,
                              fillColor: Colors.black12,
                            ),
                            validator: (v) => v!.isEmpty ? 'Requerido' : null,
                            onChanged: (val) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _generarCodigoAutomatico,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorDorado,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15)
                          ),
                          child: const Text("Generar"),
                        )
                      ],
                    ),
                    
                    if (_codigoController.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 15.0),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          color: Colors.white,
                          child: BarcodeWidget(
                            barcode: Barcode.code128(),
                            data: _codigoController.text,
                            width: 200,
                            height: 60,
                            drawText: true,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 25),
              const Text("Datos Principales", style: TextStyle(color: Colors.grey, fontSize: 16)),
              const SizedBox(height: 10),

              _buildInput('Título del Libro *', _tituloController, icon: Icons.book, required: true),
              const SizedBox(height: 15),

              _buildInput('Autor (Opcional)', _autorController, icon: Icons.person),
              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(child: _buildInput('ISBN', _isbnController, icon: Icons.numbers)),
                  const SizedBox(width: 15),
                  Expanded(child: _buildInput('Año Pub.', _anioController, icon: Icons.calendar_today, isNumber: true)),
                ],
              ),
              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(child: _buildInput('Editorial (Opcional)', _editorialController, icon: Icons.business)),
                  const SizedBox(width: 15),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: 'General',
                      decoration: const InputDecoration(
                        labelText: 'Categoría',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category)
                      ),
                      dropdownColor: Colors.grey[900],
                      items: ['General', 'Novela', 'Ciencia', 'Historia', 'Tecnología', 'Infantil']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: Colors.white))))
                          .toList(),
                      onChanged: (val) {},
                    )
                  ),
                ],
              ),
              
              const SizedBox(height: 25),
              const Text("Inventario y Estado", style: TextStyle(color: Colors.grey, fontSize: 16)),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _buildInput('Nº Copias *', _copiasController, icon: Icons.copy, isNumber: true, required: true)
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _estadoSeleccionado,
                      dropdownColor: Colors.grey[900],
                      decoration: const InputDecoration(
                        labelText: 'Estado Físico',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.check_circle_outline)
                      ),
                      items: _estados.map((estado) {
                        return DropdownMenuItem(
                          value: estado,
                          child: Text(estado, style: const TextStyle(color: Colors.white)),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _estadoSeleccionado = val!),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),
              
              TextFormField(
                controller: _observacionController,
                maxLines: 2,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Observaciones (Opcional)',
                  hintText: 'Ej: Tapa un poco rayada, edición especial...',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  prefixIcon: const Icon(Icons.note, color: Colors.grey),
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[800]!)),
                ),
              ),

              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorDorado, 
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  onPressed: _isLoading ? null : _guardarLibro,
                  icon: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) 
                    : const Icon(Icons.save),
                  label: Text(_isLoading ? ' GUARDANDO...' : 'GUARDAR EN BIBLIOTECA', 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller, {IconData? icon, bool isNumber = false, bool required = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      validator: required ? (v) => v!.isEmpty ? 'Campo requerido' : null : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
        border: const OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[800]!)),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)),
      ),
    );
  }
}