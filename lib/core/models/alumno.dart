class Alumno {
  final String? id;
  final String codigo; // DNI o Matrícula
  final String nombreCompleto;
  final String grado;
  final String seccion;
  final int strikes;
  final DateTime? vetadoHasta;

  Alumno({
    this.id,
    required this.codigo,
    required this.nombreCompleto,
    required this.grado,
    required this.seccion,
    this.strikes = 0,
    this.vetadoHasta,
  });

  // De Map (Base de datos) a Objeto
  factory Alumno.fromMap(Map<String, dynamic> map) {
    return Alumno(
      id: map['id'],
      codigo: map['codigo'] ?? '',
      nombreCompleto: map['nombre_completo'] ?? '',
      grado: map['grado'] ?? '',
      seccion: map['seccion'] ?? '',
      strikes: map['strikes'] ?? 0,
      vetadoHasta: map['vetado_hasta'] != null 
          ? DateTime.tryParse(map['vetado_hasta']) 
          : null,
    );
  }

  // De Objeto a Map (Para guardar en BD)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'codigo': codigo,
      'nombre_completo': nombreCompleto,
      'grado': grado,
      'seccion': seccion,
      'strikes': strikes,
      'vetado_hasta': vetadoHasta?.toIso8601String(),
    };
  }

  // Helper para saber si está vetado HOY
  bool get estaVetado {
    if (vetadoHasta == null) return false;
    return vetadoHasta!.isAfter(DateTime.now());
  }
}