import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/sync_service.dart';

class SplashProvider extends ChangeNotifier {
  String _mensaje = "Iniciando sistema...";
  String get mensaje => _mensaje;

  /// Retorna TRUE si es la primera vez (para bloquear la UI), FALSE si es carga rápida.
  /// También inicia la sincronización.
  Future<bool> inicializarLogica() async {
    final syncService = SyncService();
    final prefs = await SharedPreferences.getInstance();
    
    // Verificamos si es la primera vez
    bool esPrimeraVez = prefs.getBool('app_inicializada') == null;

    // Simular pequeña espera estética para ver el logo
    await Future.delayed(const Duration(seconds: 2));

    if (esPrimeraVez) {
      _actualizarMensaje("Configurando biblioteca por primera vez...");
      try {
        // Bloqueante: obligamos a esperar la descarga completa
        await syncService.sincronizacionInicial();
        await prefs.setBool('app_inicializada', true);
      } catch (e) {
        debugPrint("Error en carga inicial: $e");
      }
      return true; // Fue primera vez
    } else {
      _actualizarMensaje("Cargando datos locales...");
      // No bloqueante: Sincroniza en segundo plano y dejamos que la UI avance
      syncService.sincronizacionInicial().then((_) {
        debugPrint("⚡ Sincronización silenciosa completada");
      });
      return false; // No fue primera vez
    }
  }

  void _actualizarMensaje(String nuevoMensaje) {
    _mensaje = nuevoMensaje;
    notifyListeners();
  }
}