import 'dart:convert';
import '../modelos/pregunta.dart';
import '../modelos/examen.dart';
import '../modelos/resultado.dart';

class ServicioCalificacion {
  /// Compara las respuestas del alumno contra la clave de respuestas de la plantilla.
  /// Retorna un mapa con 'aciertos', 'errores' y 'puntaje_obtenido'.
  Map<String, dynamic> calificarExamen(
      List<Pregunta> preguntasPatron, Map<int, String> respuestasAlumno) {
    int aciertos = 0;
    int errores = 0;
    double puntajeObtenido = 0.0;

    for (var pregunta in preguntasPatron) {
      final respuestaAlumno = respuestasAlumno[pregunta.numero];

      // Normalización para comparación (trim y uppercase)
      if (respuestaAlumno != null &&
          respuestaAlumno.trim().toUpperCase() ==
              pregunta.respuestaCorrecta.trim().toUpperCase()) {
        aciertos++;
        puntajeObtenido += pregunta.valor;
      } else {
        errores++;
      }
    }

    return {
      'aciertos': aciertos,
      'errores': errores,
      'puntaje_obtenido': puntajeObtenido,
    };
  }

  /// Orquestador para crear un objeto [Resultado] a partir de la calificación procesada.
  Resultado generarResultado({
    required Examen examen,
    String? nombreEstudiante,
    required Map<int, String> respuestasAlumno,
    required List<Pregunta> preguntasPatron,
    required String rutaImagen,
  }) {
    final calificacion = calificarExamen(preguntasPatron, respuestasAlumno);

    // Serializamos el mapa de respuestas a un String JSON para el modelo
    final respuestasJson = jsonEncode(
        respuestasAlumno.map((key, value) => MapEntry(key.toString(), value)));

    return Resultado(
      idExamen: examen.id!,
      nombreEstudiante: nombreEstudiante,
      respuestasDadas: respuestasJson,
      aciertos: calificacion['aciertos'] as int,
      errores: calificacion['errores'] as int,
      notaFinal: calificacion['puntaje_obtenido'] as double,
      rutaImagen: rutaImagen,
    );
  }

  /// Valida si el número de respuestas detectadas coincide con el esperado.
  bool validarCompletitud(int cantidadEsperada, Map<int, String> respuestas) {
    return respuestas.length == cantidadEsperada;
  }
}
