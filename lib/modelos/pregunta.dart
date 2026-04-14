class Pregunta {
  final int? id;
  final int idHojaPatron;
  final int numero;
  final String respuestaCorrecta;
  final double valor;

  Pregunta({
    this.id,
    required this.idHojaPatron,
    required this.numero,
    required this.respuestaCorrecta,
    required this.valor,
  });

  Map<String, dynamic> aMapa() {
    return {
      'id': id,
      'id_hoja_patron': idHojaPatron,
      'numero': numero,
      'respuesta_correcta': respuestaCorrecta,
      'valor': valor,
    };
  }

  factory Pregunta.desdeMapa(Map<String, dynamic> mapa) {
    return Pregunta(
      id: mapa['id'] as int?,
      idHojaPatron: mapa['id_hoja_patron'] as int,
      numero: mapa['numero'] as int,
      respuestaCorrecta: mapa['respuesta_correcta'] as String,
      valor: (mapa['valor'] as num).toDouble(),
    );
  }

  Pregunta copiarCon({
    int? id,
    int? idHojaPatron,
    int? numero,
    String? respuestaCorrecta,
    double? valor,
  }) {
    return Pregunta(
      id: id ?? this.id,
      idHojaPatron: idHojaPatron ?? this.idHojaPatron,
      numero: numero ?? this.numero,
      respuestaCorrecta: respuestaCorrecta ?? this.respuestaCorrecta,
      valor: valor ?? this.valor,
    );
  }
}
