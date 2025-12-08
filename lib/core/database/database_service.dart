import 'dart:io';
import 'package:bcrypt/bcrypt.dart';
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
    
    String path = join(appDocumentsDir.path, 'biblioteca_sistema_v4200_final.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
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

    // 2. Alumnos
    await db.execute('''
      CREATE TABLE alumnos(
        id TEXT PRIMARY KEY,
        codigo TEXT UNIQUE,
        nombre_completo TEXT,
        grado TEXT,
        seccion TEXT,
        strikes INTEGER DEFAULT 0,
        vetado_hasta TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // 3. Libros
    await db.execute('''
      CREATE TABLE libros(
        id TEXT PRIMARY KEY,
        codigo_barras TEXT,
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
        foto_url TEXT,
        foto_bytes BLOB, 
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // 4. Préstamos
    await db.execute('''
      CREATE TABLE prestamos(
        id TEXT PRIMARY KEY,
        libro_id TEXT,
        alumno_id TEXT, 
        libro_titulo TEXT,
        alumno_nombre TEXT,     
        usuario_id TEXT,  
        fecha_prestamo TEXT,
        fecha_entrega TEXT,
        fecha_devolucion_real TEXT,
        activo INTEGER,
        renovaciones INTEGER, 
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // 5. Cola Sync
    await db.execute('''
      CREATE TABLE sync_cola(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        accion TEXT,
        tabla TEXT,
        datos TEXT,
        registro_id TEXT,
        fecha_creacion TEXT
      )
    ''');

    // --- DATOS SEMILLA (SEGURIDAD MEJORADA) ---
    // Esta es la contraseña maestra inicial. 
    // Puedes cambiarla aquí antes de compilar para producción.
    const passwordMaestra = 'C0ntr4S3gur4_2025!'; 
    
    final hashSeguro = BCrypt.hashpw(passwordMaestra, BCrypt.gensalt());

    // 1. ADMIN (Bibliotecaria)
    // Usuario: admin_biblio | Pass: C0ntr4S3gur4_2025!
    await db.rawInsert(
      'INSERT INTO usuarios (id, username, password, nombre, rol, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [
        '00000000-0000-0000-0000-000000000001', 
        'admin_biblio', 
        hashSeguro, 
        'Encargada Principal', 
        'BIBLIOTECARIA', 
        DateTime.now().toIso8601String(),
        DateTime.now().toIso8601String()
      ]
    );

    // 2. DIRECTOR (Superusuario)
    // Usuario: director_general | Pass: C0ntr4S3gur4_2025!
    await db.rawInsert(
      'INSERT INTO usuarios (id, username, password, nombre, rol, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [
        '00000000-0000-0000-0000-000000000002', 
        'director_general', 
        hashSeguro, 
        'Dirección General', 
        'DIRECTOR', 
        DateTime.now().toIso8601String(),
        DateTime.now().toIso8601String()
      ]
    );
  }

  // --- MÉTODOS DE AUTENTICACIÓN ---

  Future<Map<String, dynamic>?> login(String username, String password) async {
    final db = await database;
    final List<Map<String, dynamic>> res = await db.query(
      'usuarios',
      where: 'username = ?',
      whereArgs: [username],
    );

    if (res.isNotEmpty) {
      final usuario = res.first;
      final hashGuardado = usuario['password'] as String;
      // Verificación de Hash
      if (BCrypt.checkpw(password, hashGuardado)) {
        return usuario;
      }
    }
    return null;
  }

  Future<bool> cambiarPassword(String id, String nuevaPassword) async {
    final db = await database;
    try {
      final nuevoHash = BCrypt.hashpw(nuevaPassword, BCrypt.gensalt());
      await db.update(
        'usuarios',
        {'password': nuevoHash, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  // --- CRUD GENÉRICO ---
  Future<int> insertarDirecto(String tabla, Map<String, dynamic> datos) async {
    final db = await database;
    return await db.insert(tabla, datos, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> actualizarDirecto(String tabla, Map<String, dynamic> datos, String id) async {
    final db = await database;
    return await db.update(tabla, datos, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> eliminarDirecto(String tabla, String id) async {
    final db = await database;
    return await db.delete(tabla, where: 'id = ?', whereArgs: [id]);
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
    final totalLibros = Sqflite.firstIntValue(await db.rawQuery('SELECT SUM(copias) FROM libros')) ?? 0;
    final prestamosActivos = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM prestamos WHERE activo = 1')) ?? 0;
    final librosDisponibles = Sqflite.firstIntValue(await db.rawQuery('SELECT SUM(copias_disponibles) FROM libros')) ?? 0;

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

  Future<List<Map<String, dynamic>>> obtenerHistorialPrestamos() async {
    final db = await database;
    return await db.query('prestamos', orderBy: 'fecha_prestamo DESC');
  }

  // --- COLA ---
  Future<int> insertarCola(Map<String, dynamic> tarea) async {
    final db = await database;
    return await db.insert('sync_cola', tarea);
  }

  Future<List<Map<String, dynamic>>> obtenerColaPendiente() async {
    final db = await database;
    return await db.query('sync_cola', orderBy: 'fecha_creacion ASC');
  }

  Future<int> borrarDeCola(int id) async {
    final db = await database;
    return await db.delete('sync_cola', where: 'id = ?', whereArgs: [id]);
  }
}