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
    // Inicialización para Linux/Windows (FVM)
    if (Platform.isLinux || Platform.isWindows) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
    // CAMBIO 1: Nombre nuevo para empezar de cero con la estructura UUID
    String path = join(appDocumentsDir.path, 'biblioteca_premium_v8_final.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // CAMBIO 2: Los ID ahora son TEXT (para UUIDs)
    
    // 1. Usuarios
    await db.execute('''
      CREATE TABLE usuarios(
        id TEXT PRIMARY KEY, 
        username TEXT UNIQUE,
        password TEXT,
        nombre TEXT,
        rol TEXT
      )
    ''');

    // 2. Libros
    await db.execute('''
      CREATE TABLE libros(
        id TEXT PRIMARY KEY,
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
        foto_bytes BLOB,
        foto_url TEXT -- Campo nuevo para la nube
      )
    ''');

    // 3. Préstamos
    await db.execute('''
      CREATE TABLE prestamos(
        id TEXT PRIMARY KEY,
        libro_id TEXT,
        libro_titulo TEXT,
        codigo_alumno TEXT,
        nombre_alumno TEXT,
        fecha_prestamo TEXT,
        fecha_entrega TEXT,
        activo INTEGER -- 1 = Activo, 0 = Devuelto
      )
    ''');

    // 4. NUEVA TABLA: Cola de Sincronización (Offline)
    await db.execute('''
      CREATE TABLE cola_sincronizacion(
        id INTEGER PRIMARY KEY AUTOINCREMENT, -- Este sí es autoincrement local
        accion TEXT,
        tabla TEXT,
        datos TEXT, -- JSON
        registro_id TEXT,
        fecha TEXT
      )
    ''');

    // INSERTAR USUARIOS POR DEFECTO (Con IDs fijos para probar)
    await db.insert('usuarios', {
      'id': 'user-001',
      'username': 'admin',
      'password': '123',
      'nombre': 'Encargada Biblio',
      'rol': 'BIBLIOTECARIA'
    });

    await db.insert('usuarios', {
      'id': 'user-002',
      'username': 'director',
      'password': 'dir',
      'nombre': 'Sr. Director',
      'rol': 'DIRECTOR'
    });
  }

  // Insertar sin preguntar (SyncService ya validó el ID)
  Future<void> insertarDirecto(String tabla, Map<String, dynamic> datos) async {
    final db = await database;
    await db.insert(tabla, datos, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Actualizar genérico
  Future<void> actualizarDirecto(String tabla, Map<String, dynamic> datos, String id) async {
    final db = await database;
    await db.update(tabla, datos, where: 'id = ?', whereArgs: [id]);
  }

  // Eliminar genérico
  Future<void> eliminarDirecto(String tabla, String id) async {
    final db = await database;
    await db.delete(tabla, where: 'id = ?', whereArgs: [id]);
  }

  // --- MÉTODOS DE LA COLA ---

  Future<void> insertarCola(Map<String, dynamic> tarea) async {
    final db = await database;
    await db.insert('cola_sincronizacion', tarea);
  }

  Future<List<Map<String, dynamic>>> obtenerColaPendiente() async {
    final db = await database;
    return await db.query('cola_sincronizacion', orderBy: 'fecha ASC');
  }

  Future<void> borrarDeCola(int id) async {
    final db = await database;
    await db.delete('cola_sincronizacion', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>?> login(String user, String password) async {
    final db = await database;
    final res = await db.query('usuarios', where: 'username = ? AND password = ?', whereArgs: [user, password]);
    return res.isNotEmpty ? res.first : null;
  }

  Future<List<Map<String, dynamic>>> obtenerTodosLosLibros() async {
    final db = await database;
    return await db.query('libros', orderBy: 'id DESC');
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
    
    // Suma de copias disponibles
    final resultDisponibles = await db.rawQuery('SELECT SUM(copias_disponibles) as total FROM libros');
    final librosDisponibles = (resultDisponibles.first['total'] as int?) ?? 0;

    return {
      'totalLibros': totalLibros,
      'prestamosActivos': prestamosActivos,
      'librosDisponibles': librosDisponibles,
    };
  }
  
  Future<List<Map<String, dynamic>>> obtenerPrestamosActivos() async {
    final db = await database;
    return await db.query('prestamos', where: 'activo = 1', orderBy: 'fecha_entrega ASC');
  }

  Future<void> registrarDevolucionLocal(String prestamoId, String libroId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update('prestamos', {'activo': 0}, where: 'id = ?', whereArgs: [prestamoId]);
      await txn.rawUpdate(
        'UPDATE libros SET copias_disponibles = copias_disponibles + 1 WHERE id = ?',
        [libroId]
      );
    });
  }
}