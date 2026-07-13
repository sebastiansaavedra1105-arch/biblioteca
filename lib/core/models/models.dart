class Prestamo {
  final int? id;
  final int libroId;
  final String libroTitulo;
  final String codigoAlumno;
  final String nombreAlumno;
  final DateTime fechaPrestamo;
  final DateTime fechaEntrega;
  bool activo;

  Prestamo({
    this.id,
    required this.libroId,
    required this.libroTitulo,
    required this.codigoAlumno,
    required this.nombreAlumno,
    required this.fechaPrestamo,
    required this.fechaEntrega,
    this.activo = true,
  });
}