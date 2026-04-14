class Resultado {
  final int? id;
  final int idExamen;
  final String? nombreEstudiante;
  final String respuestasDadas; // Almacenado como JSON String
  final int aciertos;
  final int errores;
  final double notaFinal;
  final String rutaImagen;

  Resultado({
    this.id,
    required this.idExamen,
    this.nombreEstudiante,
    required this.respuestasDadas,
    required this.aciertos,
    required this.errores,
    required this.notaFinal,
    required this.rutaImagen,
  });

  Map<String, dynamic> aMapa() {
    return {
      'id': id,
      'id_examen': idExamen,
      'nombre_estudiante': nombreEstudiante,
      'respuestas_dadas': respuestasDadas,
      'aciertos': aciertos,
      'errores': errores,
      'nota_final': notaFinal,
      'ruta_imagen': rutaImagen,
    };
  }

  factory Resultado.desdeMapa(Map<String, dynamic> mapa) {
    return Resultado(
      id: mapa['id'] as int?,
      idExamen: mapa['id_examen'] as int,
      nombreEstudiante: mapa['nombre_estudiante'] as String?,
      respuestasDadas: mapa['respuestas_dadas'] as String,
      aciertos: mapa['aciertos'] as int,
      errores: mapa['errores'] as int,
      notaFinal: (mapa['nota_final'] as num).toDouble(),
      rutaImagen: mapa['ruta_imagen'] as String,
    );
  }

  Resultado copiarCon({
    int? id,
    int? idExamen,
    String? nombreEstudiante,
    String? respuestasDadas,
    int? aciertos,
    int? errores,
    double? notaFinal,
    String? rutaImagen,
  }) {
    return Resultado(
      id: id ?? this.id,
      idExamen: idExamen ?? this.idExamen,
      nombreEstudiante: nombreEstudiante ?? this.nombreEstudiante,
      respuestasDadas: respuestasDadas ?? this.respuestasDadas,
      aciertos: aciertos ?? this.aciertos,
      errores: errores ?? this.errores,
      notaFinal: notaFinal ?? this.notaFinal,
      rutaImagen: rutaImagen ?? this.rutaImagen,
    );
  }
}
