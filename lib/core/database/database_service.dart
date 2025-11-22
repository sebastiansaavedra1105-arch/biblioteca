import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseService {
  // Singleton: Para asegurar que solo haya una conexión abierta
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
    // Configuración específica para Windows/Linux
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
    String path = join(appDocumentsDir.path, 'biblioteca_premium.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Tabla Usuarios
    await db.execute('''
      CREATE TABLE usuarios(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE,
        password TEXT,
        nombre TEXT,
        rol TEXT
      )
    ''');

    // 2. Tabla Libros
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
        copias_disponibles INTEGER
      )
    ''');

    // 3. Crear Usuario Admin por defecto (Usuario: admin, Pass: 1234)
    await db.insert('usuarios', {
      'username': 'admin',
      'password': '1234', // En producción esto debería estar encriptado (SHA256)
      'nombre': 'Administrador Principal',
      'rol': 'admin'
    });
    
    // ignore: avoid_print
    print("Base de datos creada y Admin insertado.");
  }

  // --- MÉTODOS DE AUTENTICACIÓN ---

  Future<Map<String, dynamic>?> login(String user, String password) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'usuarios',
      where: 'username = ? AND password = ?',
      whereArgs: [user, password],
    );

    if (result.isNotEmpty) {
      return result.first;
    } else {
      return null;
    }
  }

  // --- MÉTODOS PARA EL DASHBOARD ---

  // 1. Obtener conteos para las tarjetas
  Future<Map<String, int>> obtenerEstadisticas() async {
    final db = await database;
    
    // Contar libros totales
    final resultLibros = await db.rawQuery('SELECT COUNT(*) as count FROM libros');
    final int totalLibros = (resultLibros.first['count'] as int?) ?? 0;
    
    return {
      'totalLibros': totalLibros,
      'prestamosActivos': 0, // Lo actualizaremos cuando hagamos la tabla prestamos
      'librosDisponibles': totalLibros, // Por ahora igual al total
    };
  }

  // 2. Insertar datos de prueba (Semilla)
  Future<void> insertarDatosPrueba() async {
    final db = await database;
    
    // Verificar si ya hay libros para no duplicar
    final countResult = await db.rawQuery('SELECT COUNT(*) as count FROM libros');
    final count = (countResult.first['count'] as int?) ?? 0;
    if (count > 0) return;

    // Insertar libros de ejemplo (Los de tu HTML)
    final batch = db.batch();
    
    batch.insert('libros', {
      'codigo_barras': 'LIB001',
      'titulo': 'Cien Años de Soledad',
      'autor': 'Gabriel G. Marquez',
      'isbn': '978-0307474728',
      'anio': 1967,
      'editorial': 'Sudamericana',
      'categoria': 'Novela',
      'copias': 3,
      'copias_disponibles': 3
    });
    
    batch.insert('libros', {
      'codigo_barras': 'LIB002',
      'titulo': 'Clean Code',
      'autor': 'Robert C. Martin',
      'isbn': '978-0132350884',
      'anio': 2008,
      'editorial': 'Prentice Hall',
      'categoria': 'Tecnología',
      'copias': 5,
      'copias_disponibles': 5
    });

    batch.insert('libros', {
      'codigo_barras': 'LIB003',
      'titulo': 'El Principito',
      'autor': 'Saint-Exupéry',
      'isbn': '978-0156012195',
      'anio': 1943,
      'editorial': 'Reynal & Hitchcock',
      'categoria': 'Infantil',
      'copias': 2,
      'copias_disponibles': 2
    });

    await batch.commit();
    // ignore: avoid_print
    print("Datos de prueba insertados exitosamente.");
  }

}