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
    if (Platform.isLinux || Platform.isWindows) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
    
    // CAMBIO IMPORTANTE: Subimos a v9 para empezar limpio y compatible
    String path = join(appDocumentsDir.path, 'biblioteca_premium_v9_final.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // TABLAS ACTUALIZADAS (Con created_at y updated_at para Supabase)

    // 1. Usuarios
    await db.execute('''
      CREATE TABLE usuarios(
        id TEXT PRIMARY KEY, 
        username TEXT UNIQUE,
        password TEXT,
        nombre TEXT,
        rol TEXT,
        created_at TEXT,
        updated_at TEXT
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
        foto_url TEXT,
        created_at TEXT,
        updated_at TEXT
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
        activo INTEGER,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // 4. Cola de Sincronización
    await db.execute('''
      CREATE TABLE cola_sincronizacion(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        accion TEXT,
        tabla TEXT,
        datos TEXT,
        registro_id TEXT,
        fecha TEXT
      )
    ''');

    // Insertar usuarios por defecto
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

  // --- MÉTODOS GENÉRICOS ---

  Future<void> insertarDirecto(String tabla, Map<String, dynamic> datos) async {
    final db = await database;
    await db.insert(tabla, datos, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> actualizarDirecto(String tabla, Map<String, dynamic> datos, String id) async {
    final db = await database;
    await db.update(tabla, datos, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> eliminarDirecto(String tabla, String id) async {
    final db = await database;
    await db.delete(tabla, where: 'id = ?', whereArgs: [id]);
  }

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

  // --- MÉTODOS DE CONSULTA ---

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