class Examen {
  final int? id;
  final int idArea;
  final int idHojaPatron;
  final String nombre;
  final DateTime fechaCreacion;

  Examen({
    this.id,
    required this.idArea,
    required this.idHojaPatron,
    required this.nombre,
    required this.fechaCreacion,
  });

  Map<String, dynamic> aMapa() {
    return {
      'id': id,
      'id_area': idArea,
      'id_hoja_patron': idHojaPatron,
      'nombre': nombre,
      'fecha_creacion': fechaCreacion.toIso8601String(),
    };
  }

  factory Examen.desdeMapa(Map<String, dynamic> mapa) {
    return Examen(
      id: mapa['id'] as int?,
      idArea: mapa['id_area'] as int,
      idHojaPatron: mapa['id_hoja_patron'] as int,
      nombre: mapa['nombre'] as String,
      fechaCreacion: DateTime.parse(mapa['fecha_creacion'] as String),
    );
  }

  Examen copiarCon({
    int? id,
    int? idArea,
    int? idHojaPatron,
    String? nombre,
    DateTime? fechaCreacion,
  }) {
    return Examen(
      id: id ?? this.id,
      idArea: idArea ?? this.idArea,
      idHojaPatron: idHojaPatron ?? this.idHojaPatron,
      nombre: nombre ?? this.nombre,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }
}
