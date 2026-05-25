import 'dart:io';
import 'package:image/image.dart' as img;

class ZonaBurbuja {
  final int x;
  final int y;
  final int ancho;
  final int alto;
  final String opcion;

  ZonaBurbuja({required this.x, required this.y, required this.ancho, required this.alto, required this.opcion});
}

class ServicioOMR {
  // Layout hardcodeado para la demo (Basado en una imagen de 800x1200)
  // Estos valores son estimados para una hoja estándar de 20 preguntas en una columna
  List<List<ZonaBurbuja>> _generarLayout(int cantidadPreguntas) {
    List<List<ZonaBurbuja>> layout = [];
    
    // Coordenadas base (Ajustar según la hoja real de la demo)
    int inicioX = 150; 
    int inicioY = 200;
    int espaciadoY = 45;
    int espaciadoX = 60;
    int radioBurbuja = 25;

    for (int i = 0; i < cantidadPreguntas; i++) {
      List<ZonaBurbuja> opcionesPregunta = [];
      final nombresOpciones = ['A', 'B', 'C', 'D', 'E'];
      
      for (int j = 0; j < 5; j++) {
        opcionesPregunta.add(ZonaBurbuja(
          x: inicioX + (j * espaciadoX),
          y: inicioY + (i * espaciadoY),
          ancho: radioBurbuja,
          alto: radioBurbuja,
          opcion: nombresOpciones[j],
        ));
      }
      layout.add(opcionesPregunta);
    }
    return layout;
  }

  /// Detecta las respuestas analizando la intensidad de píxeles en las zonas definidas.
  Future<Map<int, String>> detectarRespuestas(String rutaImagen, int cantidadPreguntas) async {
    final archivo = File(rutaImagen);
    if (!await archivo.exists()) {
      throw Exception('La imagen no existe');
    }

    final bytes = await archivo.readAsBytes();
    final imagen = img.decodeImage(bytes);
    if (imagen == null) throw Exception('No se pudo decodificar la imagen para OMR');

    final layout = _generarLayout(cantidadPreguntas);
    final Map<int, String> resultados = {};

    for (int i = 0; i < layout.length; i++) {
      String mejorOpcion = 'N/A'; // No marcado
      double maxIntensidad = -1.0;
      
      // Lista para guardar la intensidad de cada opción y detectar ambigüedad
      List<double> intensidades = [];

      for (var zona in layout[i]) {
        double intensidad = _calcularIntensidadZona(imagen, zona);
        intensidades.add(intensidad);

        if (intensidad > maxIntensidad) {
          maxIntensidad = intensidad;
          mejorOpcion = zona.opcion;
        }
      }

      // Validación simple de ambigüedad o no marcado
      // Si la burbuja más oscura no supera un umbral mínimo, consideramos que no marcó
      if (maxIntensidad < 0.1) {
        resultados[i + 1] = '?'; // No detectado
      } else {
        resultados[i + 1] = mejorOpcion;
      }
    }

    return resultados;
  }

  double _calcularIntensidadZona(img.Image imagen, ZonaBurbuja zona) {
    int pixelesNegros = 0;
    int totalPixeles = 0;

    for (int y = zona.y; y < zona.y + zona.alto; y++) {
      for (int x = zona.x; x < zona.x + zona.ancho; x++) {
        // Asegurar que no nos salimos de la imagen
        if (x >= 0 && x < imagen.width && y >= 0 && y < imagen.height) {
          final pixel = imagen.getPixel(x, y);
          // Como la imagen ya está binarizada por el scanner, 
          // el pixel es o blanco o negro.
          if (img.getLuminance(pixel) < 128) {
            pixelesNegros++;
          }
          totalPixeles++;
        }
      }
    }

    return totalPixeles > 0 ? pixelesNegros / totalPixeles : 0.0;
  }

  bool validarImagen(String rutaImagen) {
    return File(rutaImagen).existsSync();
  }
}
