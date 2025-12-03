import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
// 👇 CORRECCIÓN: Import absoluto
import 'package:biblio/core/models/libro.dart';

class FormLibroProvider extends ChangeNotifier {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  Uint8List? _fotoBytes;
  String _estado = 'Bueno';
  String _categoria = 'General';
  bool _isLoading = false;

  final List<String> categoriasList = [
    'General', 'Ficción', 'No Ficción', 'Ciencia', 'Historia', 
    'Tecnología', 'Arte', 'Matemáticas', 'Literatura', 
    'Comunicación', 'Ciencias Sociales', 'Minedu', 
    'Idiomas', 'Religión', 'Otro'
  ];

  Uint8List? get fotoBytes => _fotoBytes;
  String get estado => _estado;
  String get categoria => _categoria;
  bool get isLoading => _isLoading;

  void initData(Libro? libro) {
    if (libro != null) {
      _fotoBytes = libro.fotoBytes;
      _estado = libro.estado;
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

  void setCategoria(String? val) {
    if (val != null) {
      _categoria = val;
      notifyListeners();
    }
  }

  void setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  Future<void> seleccionarFoto() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 30,
      maxWidth: 600,
    );
    if (file != null) {
      _fotoBytes = await file.readAsBytes();
      notifyListeners();
    }
  }

  bool validarFormulario() {
    return formKey.currentState?.validate() ?? false;
  }
}