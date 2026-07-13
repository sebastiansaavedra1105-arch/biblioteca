import 'dart:convert';
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

  factory Libro.fromMap(Map<String, dynamic> map) {
    Uint8List? foto;
    final raw = map['foto_bytes'];
    if (raw is Uint8List) {
      foto = raw;
    } else if (raw is String && raw.isNotEmpty) {
      try {
        foto = base64Decode(raw);
      } catch (_) {
        foto = null;
      }
    } else if (raw is List) {
      foto = Uint8List.fromList(raw.cast<int>());
    }

    return Libro(
      id: map['id'] is int ? map['id'] : int.tryParse('${map['id']}'),
      codigoBarras: map['codigo_barras'] ?? '',
      titulo: map['titulo'] ?? '',
      autor: map['autor'] ?? '',
      isbn: map['isbn'] ?? '',
      anio: map['anio'] is int ? map['anio'] : int.tryParse('${map['anio']}') ?? 0,
      editorial: map['editorial'] ?? '',
      categoria: map['categoria'] ?? 'General',
      copias: map['copias'] is int ? map['copias'] : int.tryParse('${map['copias']}') ?? 1,
      copiasDisponibles: map['copias_disponibles'] is int ? map['copias_disponibles'] : int.tryParse('${map['copias_disponibles']}') ?? 1,
      estado: map['estado'] ?? 'Bueno',
      observacion: map['observacion'] ?? '',
      fotoBytes: foto,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
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