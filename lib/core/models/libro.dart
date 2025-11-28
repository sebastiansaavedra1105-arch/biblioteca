import 'dart:typed_data';

class Libro {
  final String? id; // CAMBIO: Ahora es String (UUID)
  final String codigoBarras;
  final String titulo;
  final String autor;
  final String isbn;
  final int anio;
  final String editorial;
  final String categoria;
  final int copias;
  final int copiasDisponibles;
  final String estado;
  final String observacion;
  final Uint8List? fotoBytes;
  final String? fotoUrl; // NUEVO: Para soporte de imágenes en la nube

  Libro({
    this.id,
    required this.codigoBarras,
    required this.titulo,
    required this.autor,
    required this.isbn,
    required this.anio,
    required this.editorial,
    required this.categoria,
    required this.copias,
    required this.copiasDisponibles,
    required this.estado,
    required this.observacion,
    this.fotoBytes,
    this.fotoUrl,
  });

  // Convertir de Map (BD) a Objeto (App)
  factory Libro.fromMap(Map<String, dynamic> map) {
    return Libro(
      id: map['id']?.toString(), // Aseguramos conversión a String
      codigoBarras: map['codigo_barras'] ?? '',
      titulo: map['titulo'] ?? '',
      autor: map['autor'] ?? '',
      isbn: map['isbn'] ?? '',
      anio: map['anio'] ?? 0,
      editorial: map['editorial'] ?? '',
      categoria: map['categoria'] ?? '',
      copias: map['copias'] ?? 0,
      copiasDisponibles: map['copias_disponibles'] ?? 0,
      estado: map['estado'] ?? 'Bueno',
      observacion: map['observacion'] ?? '',
      fotoBytes: map['foto_bytes'], 
      fotoUrl: map['foto_url'],
    );
  }

  // Convertir de Objeto (App) a Map (BD)
  Map<String, dynamic> toMap() {
    return {
      'id': id, // UUID se guarda tal cual
      'codigo_barras': codigoBarras,
      'titulo': titulo,
      'autor': autor,
      'isbn': isbn,
      'anio': anio,
      'editorial': editorial,
      'categoria': categoria,
      'copias': copias,
      'copias_disponibles': copiasDisponibles,
      'estado': estado,
      'observacion': observacion,
      'foto_bytes': fotoBytes,
      'foto_url': fotoUrl,
    };
  }
}