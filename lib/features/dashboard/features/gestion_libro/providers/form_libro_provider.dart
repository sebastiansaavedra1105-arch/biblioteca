import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
// CORRECCIÓN: Import absoluto para evitar errores de ruta
import 'package:biblio/core/models/libro.dart';

class FormLibroProvider extends ChangeNotifier {
  // Llave global para validar el formulario desde los botones
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // --- ESTADO DEL FORMULARIO ---
  Uint8List? _fotoBytes;
  String _estado = 'Bueno';
  String _categoria = 'General';
  bool _isLoading = false;

  // Listas para los Dropdowns
  final List<String> categoriasList = [
    'General', 'Ficción', 'No Ficción', 'Ciencia', 'Historia', 
    'Tecnología', 'Arte', 'Matemáticas', 'Literatura', 
    'Comunicación', 'Ciencias Sociales', 'Minedu', 
    'Idiomas', 'Religión', 'Otro'
  ];

  final List<String> estadosList = ['Bueno', 'Regular', 'Malo'];

  // --- GETTERS ---
  Uint8List? get fotoBytes => _fotoBytes;
  String get estado => _estado;
  String get categoria => _categoria;
  bool get isLoading => _isLoading;

  // --- INICIALIZACIÓN ---
  void initData(Libro? libro) {
    if (libro != null) {
      _fotoBytes = libro.fotoBytes;
      
      if (estadosList.contains(libro.estado)) {
        _estado = libro.estado;
      } else {
        _estado = 'Bueno';
      }

      if (categoriasList.contains(libro.categoria)) {
        _categoria = libro.categoria;
      } else {
        _categoria = 'General';
      }
    } else {
      _limpiar();
    }
  }

  void _limpiar() {
    _fotoBytes = null;
    _estado = 'Bueno';
    _categoria = 'General';
    _isLoading = false;
  }

  // --- SETTERS ---
  void setCategoria(String? val) {
    if (val != null) {
      _categoria = val;
      notifyListeners();
    }
  }

  void setEstado(String? val) {
    if (val != null) {
      _estado = val;
      notifyListeners();
    }
  }

  void setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  // --- MANEJO DE IMÁGENES ---
  Future<void> seleccionarFoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600, 
        imageQuality: 80,
      );

      if (image != null) {
        _fotoBytes = await image.readAsBytes();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error seleccionando foto: $e");
    }
  }

  void eliminarFoto() {
    _fotoBytes = null;
    notifyListeners();
  }
}