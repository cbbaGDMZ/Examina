class HojaPatron {
  final int? id;
  final String nombre;
  final int cantidadPreguntas;
  final bool esPuntajeFijo;
  final double puntajeMaximo;

  HojaPatron({
    this.id,
    required this.nombre,
    required this.cantidadPreguntas,
    required this.esPuntajeFijo,
    required this.puntajeMaximo,
  });

  Map<String, dynamic> aMapa() {
    return {
      'id': id,
      'nombre': nombre,
      'cantidad_preguntas': cantidadPreguntas,
      'es_puntaje_fijo': esPuntajeFijo ? 1 : 0,
      'puntaje_maximo': puntajeMaximo,
    };
  }

  factory HojaPatron.desdeMapa(Map<String, dynamic> mapa) {
    return HojaPatron(
      id: mapa['id'] as int?,
      nombre: mapa['nombre'] as String,
      cantidadPreguntas: mapa['cantidad_preguntas'] as int,
      esPuntajeFijo: mapa['es_puntaje_fijo'] == 1,
      puntajeMaximo: (mapa['puntaje_maximo'] as num).toDouble(),
    );
  }

  HojaPatron copiarCon({
    int? id,
    String? nombre,
    int? cantidadPreguntas,
    bool? esPuntajeFijo,
    double? puntajeMaximo,
  }) {
    return HojaPatron(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      cantidadPreguntas: cantidadPreguntas ?? this.cantidadPreguntas,
      esPuntajeFijo: esPuntajeFijo ?? this.esPuntajeFijo,
      puntajeMaximo: puntajeMaximo ?? this.puntajeMaximo,
    );
  }
}
