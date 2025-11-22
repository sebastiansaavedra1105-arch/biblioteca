import 'dart:math';
import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../../../core/database/database_service.dart';

class AgregarLibroScreen extends StatefulWidget {
  const AgregarLibroScreen({super.key});

  @override
  State<AgregarLibroScreen> createState() => _AgregarLibroScreenState();
}

class _AgregarLibroScreenState extends State<AgregarLibroScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores
  final _codigoController = TextEditingController();
  final _tituloController = TextEditingController();
  final _autorController = TextEditingController();
  final _isbnController = TextEditingController();
  final _editorialController = TextEditingController();
  final _anioController = TextEditingController();
  final _copiasController = TextEditingController(text: '1');
  final _observacionController = TextEditingController();

  // Variables de estado
  bool _isLoading = false;
  String _estadoSeleccionado = 'Bueno';
  String _categoriaSeleccionada = 'General';
  
  final List<String> _estados = ['Nuevo', 'Bueno', 'Regular', 'Malo', 'Deteriorado'];
  final List<String> _categorias = ['General', 'Ciencia', 'Historia', 'Tecnología', 'Infantil'];

  @override
  void dispose() {
    _codigoController.dispose();
    _tituloController.dispose();
    _autorController.dispose();
    _isbnController.dispose();
    _editorialController.dispose();
    _anioController.dispose();
    _copiasController.dispose();
    _observacionController.dispose();
    super.dispose();
  }

  /// Genera un código automático tipo LIB12345678
  void _generarCodigoAutomatico() {
    final random = Random();
    final numero = 10000000 + random.nextInt(90000000); 
    setState(() {
      _codigoController.text = "LIB$numero";
    });
  }

  /// Guarda el libro en la base de datos
  Future<void> _guardarLibro() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final int copias = int.parse(_copiasController.text);
      
      await DatabaseService().insertarLibro({
        'codigo_barras': _codigoController.text.trim(),
        'titulo': _tituloController.text.trim(),
        'autor': _autorController.text.trim().isEmpty ? 'Anónimo' : _autorController.text.trim(),
        'isbn': _isbnController.text.trim().isEmpty ? 'S/N' : _isbnController.text.trim(),
        'anio': int.tryParse(_anioController.text) ?? DateTime.now().year,
        'editorial': _editorialController.text.trim().isEmpty ? 'Sin Editorial' : _editorialController.text.trim(),
        'categoria': _categoriaSeleccionada, 
        'copias': copias,
        'copias_disponibles': copias,
        'estado': _estadoSeleccionado,
        'observacion': _observacionController.text.trim(),
      });

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Libro agregado correctamente'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      Navigator.pop(context, true); // Retorna true para indicar que se agregó un libro
      
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: ${e.toString().contains('UNIQUE') ? 'El código de barras ya existe' : 'No se pudo guardar el libro'}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorDorado = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AGREGAR NUEVO LIBRO'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- SECCIÓN CÓDIGO DE BARRAS ---
              _buildSeccionCodigoBarras(colorDorado),

              const SizedBox(height: 25),
              _buildSeccionHeader('Datos Principales'),
              const SizedBox(height: 10),

              // Título (Requerido)
              _buildInput(
                'Título del Libro *',
                _tituloController,
                icon: Icons.book,
                required: true,
              ),
              const SizedBox(height: 15),

              // Autor (Opcional)
              _buildInput(
                'Autor (Opcional)',
                _autorController,
                icon: Icons.person,
                hint: 'Ej: Gabriel García Márquez',
              ),
              const SizedBox(height: 15),

              // Fila: ISBN y Año
              Row(
                children: [
                  Expanded(
                    child: _buildInput(
                      'ISBN',
                      _isbnController,
                      icon: Icons.numbers,
                      hint: 'Ej: 978-0307474728',
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildInput(
                      'Año Pub.',
                      _anioController,
                      icon: Icons.calendar_today,
                      isNumber: true,
                      hint: 'Ej: 2008',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // Fila: Editorial y Categoría
              Row(
                children: [
                  Expanded(
                    child: _buildInput(
                      'Editorial (Opcional)',
                      _editorialController,
                      icon: Icons.business,
                      hint: 'Ej: Prentice Hall',
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildDropdown(
                      label: 'Categoría',
                      icon: Icons.category,
                      value: _categoriaSeleccionada,
                      items: _categorias,
                      onChanged: (val) => setState(() => _categoriaSeleccionada = val!),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 25),
              _buildSeccionHeader('Inventario y Estado'),
              const SizedBox(height: 10),

              // Fila: Copias y Estado
              Row(
                children: [
                  Expanded(
                    child: _buildInput(
                      'Nº Copias *',
                      _copiasController,
                      icon: Icons.content_copy,
                      isNumber: true,
                      required: true,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildDropdown(
                      label: 'Estado Físico',
                      icon: Icons.check_circle_outline,
                      value: _estadoSeleccionado,
                      items: _estados,
                      onChanged: (val) => setState(() => _estadoSeleccionado = val!),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),
              
              // Observación
              TextFormField(
                controller: _observacionController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Observaciones (Opcional)',
                  hintText: 'Ej: Tapa rayada, edición especial, incluye CD...',
                  hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
                  prefixIcon: const Icon(Icons.note_alt_outlined, color: Colors.grey),
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[800]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: colorDorado, width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 40),
              
              // Botón Guardar
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorDorado, 
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  onPressed: _isLoading ? null : _guardarLibro,
                  icon: _isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2,
                        ),
                      ) 
                    : const Icon(Icons.save, size: 24),
                  label: Text(
                    _isLoading ? 'GUARDANDO...' : 'GUARDAR EN BIBLIOTECA',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget: Sección del código de barras con visualización
  Widget _buildSeccionCodigoBarras(Color colorDorado) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _codigoController,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Código de Barras *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.qr_code_scanner),
                    filled: true,
                    fillColor: Colors.black12,
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Campo requerido' : null,
                  onChanged: (val) => setState(() {}),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: _generarCodigoAutomatico,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorDorado,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                ),
                icon: const Icon(Icons.auto_awesome),
                label: const Text("Generar"),
              )
            ],
          ),
          
          // Visualización del código de barras
          if (_codigoController.text.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 15.0),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: BarcodeWidget(
                  barcode: Barcode.code128(),
                  data: _codigoController.text.trim(),
                  width: 200,
                  height: 60,
                  drawText: true,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Widget: Header de sección
  Widget _buildSeccionHeader(String titulo) {
    return Text(
      titulo,
      style: const TextStyle(
        color: Colors.grey,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  /// Widget: Campo de texto reutilizable
  Widget _buildInput(
    String label,
    TextEditingController controller, {
    IconData? icon,
    bool isNumber = false,
    bool required = false,
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      validator: required 
        ? (v) => v == null || v.trim().isEmpty ? 'Campo requerido' : null 
        : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
        prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
        border: const OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey[800]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
      ),
    );
  }

  /// Widget: Dropdown reutilizable
  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: Colors.grey[900],
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon, color: Colors.grey),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey[800]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(
            item,
            style: const TextStyle(color: Colors.white),
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}