import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
    String path = join(appDocumentsDir.path, 'biblioteca_premium_v6.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE usuarios(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE,
        password TEXT,
        nombre TEXT,
        rol TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE libros(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        codigo_barras TEXT UNIQUE,
        titulo TEXT,
        autor TEXT,
        isbn TEXT,
        anio INTEGER,
        editorial TEXT,
        categoria TEXT,
        copias INTEGER,
        copias_disponibles INTEGER,
        estado TEXT,
        observacion TEXT,
        foto_bytes BLOB
      )
    ''');

    await db.execute('''
      CREATE TABLE prestamos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        libro_id INTEGER,
        libro_titulo TEXT,
        codigo_alumno TEXT,
        nombre_alumno TEXT,
        fecha_prestamo TEXT,
        fecha_entrega TEXT,
        activo INTEGER,
        FOREIGN KEY(libro_id) REFERENCES libros(id)
      )
    ''');

    await db.insert('usuarios', {
      'username': 'admin',
      'password': '1234',
      'nombre': 'Administrador Principal',
      'rol': 'admin'
    });
  }

  Future<int> insertarLibro(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('libros', row);
  }

  Future<List<Map<String, dynamic>>> obtenerTodosLosLibros() async {
    final db = await database;
    return await db.query('libros', orderBy: 'titulo ASC');
  }

  Future<Map<String, dynamic>?> buscarLibroPorCodigo(String codigo) async {
    final db = await database;
    final res = await db.query('libros', where: 'codigo_barras = ?', whereArgs: [codigo]);
    return res.isNotEmpty ? res.first : null;
  }

  Future<Map<String, int>> obtenerEstadisticas() async {
    final db = await database;
    final totalLibros = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM libros')) ?? 0;
    final prestamosActivos = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM prestamos WHERE activo = 1')) ?? 0;
    final librosDisponibles = Sqflite.firstIntValue(await db.rawQuery('SELECT SUM(copias_disponibles) FROM libros')) ?? 0;

    return {
      'totalLibros': totalLibros,
      'prestamosActivos': prestamosActivos,
      'librosDisponibles': librosDisponibles,
    };
  }
  
  Future<bool> registrarPrestamo({
    required int libroId,
    required String titulo,
    required String alumno,
    required String nombreAlumno,
    required DateTime entrega,
  }) async {
    final db = await database;
    try {
      await db.transaction((txn) async {
        await txn.insert('prestamos', {
          'libro_id': libroId,
          'libro_titulo': titulo,
          'codigo_alumno': alumno,
          'nombre_alumno': nombreAlumno,
          'fecha_prestamo': DateTime.now().toIso8601String(),
          'fecha_entrega': entrega.toIso8601String(),
          'activo': 1
        });
        await txn.rawUpdate(
          'UPDATE libros SET copias_disponibles = copias_disponibles - 1 WHERE id = ?',
          [libroId]
        );
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> login(String user, String password) async {
    final db = await database;
    final res = await db.query('usuarios', where: 'username = ? AND password = ?', whereArgs: [user, password]);
    return res.isNotEmpty ? res.first : null;
  }

  Future<String> obtenerRutaBaseDatos() async {
    final dbDir = await getApplicationDocumentsDirectory();
    return join(dbDir.path, 'biblioteca_premium_v6.db');
  }

  Future<void> insertarDatosPrueba() async {}

  Future<List<Map<String, dynamic>>> obtenerPrestamosActivos() async {
    final db = await database;
    // Traemos los préstamos que tienen activo = 1, ordenados por fecha de entrega
    return await db.query('prestamos', where: 'activo = 1', orderBy: 'fecha_entrega ASC');
  }

  Future<void> registrarDevolucion(int prestamoId, int libroId) async {
    final db = await database;
    await db.transaction((txn) async {
      // 1. Marcar préstamo como inactivo (devuelto)
      await txn.update('prestamos', {'activo': 0}, where: 'id = ?', whereArgs: [prestamoId]);
      
      // 2. Aumentar el stock del libro
      await txn.rawUpdate(
        'UPDATE libros SET copias_disponibles = copias_disponibles + 1 WHERE id = ?',
        [libroId]
      );
    });
  }

  Future<int> actualizarLibro(Map<String, dynamic> row) async {
    final db = await database;
    return await db.update(
      'libros', 
      row, 
      where: 'id = ?', 
      whereArgs: [row['id']]
    );
  }

  Future<int> eliminarLibro(int id) async {
    final db = await database;
    return await db.delete(
      'libros', 
      where: 'id = ?', 
      whereArgs: [id]
    );
  }

}