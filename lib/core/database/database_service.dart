import 'dart:io'; // Para File y Directory
import 'package:path/path.dart'; // Para unir rutas (join)
import 'package:path_provider/path_provider.dart'; // Ubicación de carpetas del S.O.
import 'package:sqflite/sqflite.dart'; // El paquete principal

class DatabaseService {
  // --- Singleton Pattern ---
  // Constructor privado
  DatabaseService._privateConstructor();
  // Instancia única (static final)
  static final DatabaseService instance = DatabaseService._privateConstructor();

  // Única referencia a la base de datos en toda la app
  static Database? _database;

  // Getter para la base de datos.
  // Si ya existe, la devuelve. Si no, la inicializa.
  Future<Database> get database async {
    if (_database != null) return _database!;
    
    // Si es nula, la creamos
    _database = await _initDatabase();
    return _database!;
  }

  // --- Inicialización ---
  Future<Database> _initDatabase() async {
    // Obtener la ruta de documentos de la app (segura)
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    // Nombre del archivo de la BD
    String path = join(documentsDirectory.path, 'biblioteca.db'); 

    // Abrir la BD
    return await openDatabase(
      path,
      version: 1,       // Versión de la BD (para futuras migraciones)
      onCreate: _onCreate, // Método a ejecutar la primera vez
    );
  }

  // --- Creación de Tablas (SQL) ---
  // Se ejecuta solo 1 vez cuando el archivo .db no existe
  Future _onCreate(Database db, int version) async {
    
    // Tabla de Libros
    await db.execute('''
    CREATE TABLE libros (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      titulo TEXT NOT NULL,
      autor TEXT,
      isbn TEXT UNIQUE,
      portada_path TEXT,
      estado TEXT NOT NULL DEFAULT 'Disponible'
    )
    ''');

    // Tabla de Lectores
    await db.execute('''
    CREATE TABLE lectores (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nombre TEXT NOT NULL,
      identificacion TEXT UNIQUE NOT NULL
    )
    ''');

    // Tabla de Préstamos (la tabla "junction")
    await db.execute('''
    CREATE TABLE prestamos (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      libro_id INTEGER NOT NULL,
      lector_id INTEGER NOT NULL,
      fecha_prestamo TEXT NOT NULL,
      fecha_devolucion_prevista TEXT NOT NULL,
      fecha_devolucion_real TEXT,
      FOREIGN KEY (libro_id) REFERENCES libros (id),
      FOREIGN KEY (lector_id) REFERENCES lectores (id)
    )
    ''');
  }

  // ==== CRUD Libros ====

  // C: Create (Insertar libro)
  // Devuelve el ID del libro insertado
  Future<int> insertarLibro(Map<String, dynamic> libroData) async {
    final db = await instance.database;
    // conflictAlgorithm: 'replace' -> maneja conflictos con 'isbn' (UNIQUE)
    return await db.insert(
      'libros', 
      libroData, 
      conflictAlgorithm: ConflictAlgorithm.replace
    );
  }

  // R: Read (Obtener todos los libros)
  Future<List<Map<String, dynamic>>> getLibros() async {
    final db = await instance.database;
    return await db.query('libros', orderBy: 'titulo ASC');
  }

  // R: Read (Obtener un libro por su ID)
  Future<Map<String, dynamic>?> getLibro(int id) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'libros',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1, // Solo uno
    );

    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  // U: Update (Actualizar libro)
  Future<int> actualizarLibro(Map<String, dynamic> libroData) async {
    final db = await instance.database;
    final int id = libroData['id'];
    return await db.update(
      'libros',
      libroData,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // D: Delete (Eliminar libro)
  Future<int> eliminarLibro(int id) async {
    final db = await instance.database;
    return await db.delete(
      'libros',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==== CRUD Lectores ====

  // C: Create (Insertar lector)
  Future<int> insertarLector(Map<String, dynamic> lectorData) async {
    final db = await instance.database;
    // conflictAlgorithm: 'replace' -> maneja 'identificacion' (UNIQUE)
    return await db.insert(
      'lectores', 
      lectorData, 
      conflictAlgorithm: ConflictAlgorithm.replace
    );
  }

  // R: Read (Obtener todos los lectores)
  Future<List<Map<String, dynamic>>> getLectores() async {
    final db = await instance.database;
    return await db.query('lectores', orderBy: 'nombre ASC');
  }

  // R: Read (Obtener un lector por su ID)
  Future<Map<String, dynamic>?> getLector(int id) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'lectores',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1, // Solo uno
    );

    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  // U: Update (Actualizar lector)
  Future<int> actualizarLector(Map<String, dynamic> lectorData) async {
    final db = await instance.database;
    final int id = lectorData['id'];
    return await db.update(
      'lectores',
      lectorData,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // D: Delete (Eliminar lector)
  Future<int> eliminarLector(int id) async {
    final db = await instance.database;
    return await db.delete(
      'lectores',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==== Funciones de Agregación (Conteos) ====

  // Contar total de libros
  Future<int> getTotalLibros() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM libros');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Contar total de lectores
  Future<int> getTotalLectores() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM lectores');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ==== Funciones de Préstamos (Lógica de Negocio) ====

  // C: Registrar un nuevo préstamo
  // Usa una transacción para asegurar consistencia
  Future<void> registrarPrestamo({
    required int libroId,
    required int lectorId,
    required DateTime fechaDevolucionPrevista,
  }) async {
    final db = await instance.database;
    
    await db.transaction((txn) async {
      // 1. Insertar el registro de préstamo
      await txn.insert('prestamos', {
        'libro_id': libroId,
        'lector_id': lectorId,
        'fecha_prestamo': DateTime.now().toIso8601String(), // Fecha actual
        'fecha_devolucion_prevista': fechaDevolucionPrevista.toIso8601String(),
        'fecha_devolucion_real': null, // Nulo significa "no devuelto"
      });

      // 2. Actualizar el estado del libro a 'Prestado'
      await txn.update(
        'libros',
        {'estado': 'Prestado'}, // Nuevo estado
        where: 'id = ?',
        whereArgs: [libroId],
      );
    });
  }

  // U: Registrar una devolución (basado en el ID del libro)
  Future<void> registrarDevolucion(int libroId) async {
    final db = await instance.database;
    
    await db.transaction((txn) async {
      // 1. Marcar el préstamo como devuelto (el más reciente de ese libro)
      await txn.update(
        'prestamos',
        {'fecha_devolucion_real': DateTime.now().toIso8601String()},
        // Buscar el préstamo activo (no devuelto) de este libro
        where: 'libro_id = ? AND fecha_devolucion_real IS NULL', 
        whereArgs: [libroId],
      );

      // 2. Actualizar el estado del libro a 'Disponible'
      await txn.update(
        'libros',
        {'estado': 'Disponible'}, // Nuevo estado
        where: 'id = ?',
        whereArgs: [libroId],
      );
    });
  }

  // R: Obtener todos los préstamos activos (no devueltos)
  // Usamos rawQuery para hacer un JOIN y obtener nombres
  Future<List<Map<String, dynamic>>> getPrestamosActivos() async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT 
        p.id, 
        p.fecha_prestamo,
        p.fecha_devolucion_prevista,
        l.titulo AS libro_titulo, 
        lec.nombre AS lector_nombre
      FROM prestamos p
      JOIN libros l ON p.libro_id = l.id
      JOIN lectores lec ON p.lector_id = lec.id
      WHERE p.fecha_devolucion_real IS NULL
      ORDER BY p.fecha_devolucion_prevista ASC
    ''');
  }

  // Contar préstamos activos (para el Dashboard)
  Future<int> getTotalPrestamosActivos() async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM prestamos WHERE fecha_devolucion_real IS NULL'
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

}