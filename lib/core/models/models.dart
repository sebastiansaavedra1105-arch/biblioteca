// lib/core/models/models.dart

// SI USAS ESTA CLASE 'LIBRO', ACTUALÍZALA ASÍ (Si no, bórrala y usa libro.dart):
class Libro {
  final String? id; // Cambiado a String
  final String codigoBarras;
  final String titulo;
  final String autor;
  final String isbn;
  final int anio;
  final String editorial;
  final String categoria;
  int copias;
  int copiasDisponibles;

  Libro({
    this.id,
    required this.codigoBarras,
    required this.titulo,
    required this.autor,
    required this.isbn,
    required this.anio,
    required this.editorial,
    required this.categoria,
    this.copias = 1,
    this.copiasDisponibles = 1,
  });
}

class Prestamo {
  final String? id;       // CAMBIO: String (UUID)
  final String libroId;   // CAMBIO: String (UUID)
  final String libroTitulo; 
  final String libroCodigoBarras;
  final String codigoAlumno;
  final String nombreAlumno;
  final String emailAlumno;
  final DateTime fechaPrestamo;
  final DateTime fechaEntrega;
  bool activo;

  Prestamo({
    this.id,
    required this.libroId,
    required this.libroTitulo,
    required this.libroCodigoBarras,
    required this.codigoAlumno,
    required this.nombreAlumno,
    required this.emailAlumno,
    required this.fechaPrestamo,
    required this.fechaEntrega,
    this.activo = true,
  });
}