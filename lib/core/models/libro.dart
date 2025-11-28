import 'dart:typed_data';

class Libro {
  final int? id;
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
  });

  // Convertir de Map (BD) a Objeto (App)
  factory Libro.fromMap(Map<String, dynamic> map) {
    return Libro(
      id: map['id'],
      codigoBarras: map['codigo_barras'],
      titulo: map['titulo'],
      autor: map['autor'],
      isbn: map['isbn'],
      anio: map['anio'],
      editorial: map['editorial'],
      categoria: map['categoria'],
      copias: map['copias'],
      copiasDisponibles: map['copias_disponibles'],
      estado: map['estado'],
      observacion: map['observacion'] ?? '',
      fotoBytes: map['foto_bytes'], // BLOB viene como Uint8List en sqflite
    );
  }

  // Convertir de Objeto (App) a Map (BD)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
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
    };
  }
}