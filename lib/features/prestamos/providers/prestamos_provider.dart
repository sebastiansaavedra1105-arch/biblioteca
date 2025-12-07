import 'package:flutter/material.dart';
import '../../../core/database/database_service.dart';
import '../../../core/models/libro.dart';
import '../../../core/models/alumno.dart';

class PrestamosProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  // --- REGISTRAR PRÉSTAMO ---
  Future<bool> registrarPrestamo({
    required Libro libro,
    required Alumno alumno,
    required DateTime fechaEntrega,
    required String usuarioId, // El ID del bibliotecario que presta
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final db = await _dbService.database;

      await db.transaction((txn) async {
        // 1. Verificar stock real en transacción
        final libroData = await txn.query(
          'libros', 
          columns: ['copias_disponibles'], 
          where: 'id = ?', 
          whereArgs: [libro.id]
        );
        
        final disponibles = libroData.first['copias_disponibles'] as int;

        if (disponibles <= 0) {
          throw Exception("No quedan copias disponibles de este libro");
        }

        // 2. Crear registro de préstamo
        final nuevoPrestamo = {
          'libro_id': libro.id,
          'libro_titulo': libro.titulo,
          'alumno_id': alumno.id,
          'alumno_nombre': alumno.nombreCompleto,
          'usuario_id': usuarioId, // Quién prestó
          'fecha_prestamo': DateTime.now().toIso8601String(),
          'fecha_entrega': fechaEntrega.toIso8601String(),
          'activo': 1, // 1 = Activo, 0 = Devuelto
          'renovaciones': 0
        };

        // Insertar en local (SyncService se encargará de subirlo luego)
        // Nota: Idealmente deberías usar SyncService aquí, pero por simplicidad usamos DB directa
        // y asumimos que SyncService está observando o que insertas en cola.
        // Para consistencia con tu arquitectura, insertamos directo y tú tienes la cola en DatabaseService
        
        // *IMPORTANTE*: Aquí deberías llamar a tu método de insertar cola si no usas SyncService directo.
        // Asumo que tu DatabaseService.insertarCola maneja esto, o insertamos directo.
        
        await txn.insert('prestamos', nuevoPrestamo);

        // 3. Restar stock
        await txn.rawUpdate(
          'UPDATE libros SET copias_disponibles = copias_disponibles - 1 WHERE id = ?',
          [libro.id]
        );
      });

      _isLoading = false;
      notifyListeners();
      return true;

    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}