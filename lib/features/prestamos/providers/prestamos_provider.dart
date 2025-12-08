import 'dart:convert'; // Necesario para jsonEncode
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart'; // Asegúrate de importar esto
import '../../../core/database/database_service.dart';
import '../../../core/models/libro.dart';
import '../../../core/models/alumno.dart';

class PrestamosProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final _uuid = const Uuid(); // Generador de IDs

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  // --- REGISTRAR PRÉSTAMO (CORREGIDO) ---
  Future<bool> registrarPrestamo({
    required Libro libro,
    required Alumno alumno,
    required DateTime fechaEntrega,
    required String usuarioId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final db = await _dbService.database;

      await db.transaction((txn) async {
        // 1. Verificar stock real dentro de la transacción (Bloqueo pesimista)
        final libroData = await txn.query(
          'libros',
          columns: ['copias_disponibles'],
          where: 'id = ?',
          whereArgs: [libro.id],
        );

        if (libroData.isEmpty) throw Exception("El libro no existe en BD");

        final disponibles = libroData.first['copias_disponibles'] as int;

        if (disponibles <= 0) {
          throw Exception("No quedan copias disponibles de este libro");
        }

        // 2. Generar ID Único (CRUCIAL: Esto faltaba y causaba el crash)
        final String prestamoId = _uuid.v4();

        // 3. Preparar datos del préstamo
        final nuevoPrestamo = {
          'id': prestamoId, // <--- AHORA SÍ TIENE ID
          'libro_id': libro.id,
          'libro_titulo': libro.titulo,
          'alumno_id': alumno.id,
          'alumno_nombre': alumno.nombreCompleto,
          'usuario_id': usuarioId,
          'fecha_prestamo': DateTime.now().toIso8601String(),
          'fecha_entrega': fechaEntrega.toIso8601String(),
          'activo': 1,
          'renovaciones': 0
        };

        // 4. Insertar Préstamo
        await txn.insert('prestamos', nuevoPrestamo);

        // 5. Restar stock
        await txn.rawUpdate(
          'UPDATE libros SET copias_disponibles = copias_disponibles - 1 WHERE id = ?',
          [libro.id]
        );

        // 6. INSERTAR EN LA COLA DE SINCRONIZACIÓN (OFFLINE FIRST)
        // Esto garantiza que SyncService lo suba a Supabase luego.
        await txn.insert('sync_cola', {
          'accion': 'INSERT',
          'tabla': 'prestamos',
          'registro_id': prestamoId,
          'datos': jsonEncode(nuevoPrestamo),
          'fecha_creacion': DateTime.now().toIso8601String(),
        });
        
        // OPCIONAL: También encolar el UPDATE del libro para que el stock baje en la nube
         await txn.insert('sync_cola', {
          'accion': 'UPDATE',
          'tabla': 'libros',
          'registro_id': libro.id,
          'datos': jsonEncode({'copias_disponibles': disponibles - 1}), // Solo mandamos el campo que cambia
          'fecha_creacion': DateTime.now().toIso8601String(),
        });
      });

      _isLoading = false;
      notifyListeners();
      return true;

    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint("❌ Error en transacción préstamo: $e");
      return false;
    }
  }
}