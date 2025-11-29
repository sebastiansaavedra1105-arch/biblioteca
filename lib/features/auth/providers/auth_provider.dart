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

  // 🔥 NUEVO: Saber si es el Director
  bool get estaAutenticado => _usuarioActual != null;
  bool get esDirector => _usuarioActual?['rol'] == 'DIRECTOR';

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 500)); 
      final usuario = await _dbService.login(username, password);

      if (usuario != null) {
        _usuarioActual = usuario;
        _isLoading = false;
        notifyListeners(); 
        return true;
      } else {
        _errorMessage = 'Credenciales incorrectas';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _usuarioActual = null;
    notifyListeners();
  }
}