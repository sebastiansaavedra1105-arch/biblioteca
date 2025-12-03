import 'package:flutter/material.dart';
import '../../../core/database/database_service.dart';

class AuthProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _usuarioActual;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get usuarioActual => _usuarioActual;

  bool get estaAutenticado => _usuarioActual != null;
  bool get esDirector => _usuarioActual?['rol'] == 'DIRECTOR';

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Login real contra base de datos local (encriptada)
      final usuario = await _dbService.login(username, password);

      if (usuario != null) {
        _usuarioActual = usuario;
        _isLoading = false;
        notifyListeners(); 
        return true;
      } else {
        _errorMessage = 'Usuario o contraseña incorrectos';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error interno: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _usuarioActual = null;
    notifyListeners();
  }

  Future<bool> cambiarContrasena(String nuevaPassword) async {
    if (_usuarioActual == null) return false;
    
    final exito = await _dbService.cambiarPassword(_usuarioActual!['id'], nuevaPassword);
    if (exito) {
      // Actualizamos el usuario en memoria si es necesario, o pedimos relogin
      notifyListeners();
    }
    return exito;
  }
}