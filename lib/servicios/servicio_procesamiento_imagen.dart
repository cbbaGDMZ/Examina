import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart' as img;

class ResultadoProcesamiento {
  final bool exito;
  final String? rutaImagenCorregida;
  final String? mensajeError;
  final List<String> advertencias;
  final List<Marcador> marcadoresDetectados;
  final double? anguloRotacion;
  final MetadatosProcesamiento? metadatos;

  ResultadoProcesamiento({
    required this.exito,
    this.rutaImagenCorregida,
    this.mensajeError,
    this.advertencias = const [],
    this.marcadoresDetectados = const [],
    this.anguloRotacion,
    this.metadatos,
  });
}

class Marcador {
  final String posicion;
  final double x;
  final double y;

  Marcador({
    required this.posicion,
    required this.x,
    required this.y,
  });

  @override
  String toString() => 'Marcador($posicion: $x, $y)';
}

class MetadatosProcesamiento {
  final double escalaX;
  final double escalaY;
  final double anchoOriginal;
  final double altoOriginal;
  final double anchoCorregido;
  final double altoCorregido;

  MetadatosProcesamiento({
    required this.escalaX,
    required this.escalaY,
    required this.anchoOriginal,
    required this.altoOriginal,
    required this.anchoCorregido,
    required this.altoCorregido,
  });
}

class ServicioProcesamientoImagen {
  Future<ResultadoProcesamiento> procesarHoja(String rutaImagen, {String? rutaCarpetaTemporal}) async {
    try {
      final archivo = File(rutaImagen);
      if (!await archivo.exists()) {
        return ResultadoProcesamiento(
          exito: false,
          mensajeError: 'La imagen no existe en la ruta: $rutaImagen',
        );
      }

      final bytes = await archivo.readAsBytes();
      final imagenOriginal = img.decodeImage(bytes);
      if (imagenOriginal == null) {
        return ResultadoProcesamiento(
          exito: false,
          mensajeError: 'No se pudo decodificar la imagen',
        );
      }

      // 1. NORMALIZACIÓN PARA DETECCIÓN
      // No modificamos la original aún, trabajamos sobre una copia para detectar
      final imagenDeteccion = img.contrast(img.grayscale(imagenOriginal.clone()), contrast: 1.5);
      
      final advertencias = <String>[];

      // 2. DETECCIÓN DE MARCADORES
      final marcadores = _detectarMarcadores(imagenDeteccion);

      if (marcadores.length != 4) {
        return ResultadoProcesamiento(
          exito: false,
          mensajeError: 'Se detectaron ${marcadores.length} marcadores, se requieren 4 para procesar.',
          marcadoresDetectados: marcadores,
        );
      }

      // 3. VALIDACIÓN DE CALIDAD (Solo informativa, nunca bloquea)
      final calidadResult = _validarCalidad(imagenDeteccion);
      if (!calidadResult['aprobado']!) {
        advertencias.add('Calidad: ${calidadResult['mensaje']}');
      }

      // 4. CORRECCIÓN DE ROTACIÓN
      final angulo = _calcularAnguloRotacion(marcadores);
      img.Image imagenProcesada = imagenOriginal.clone();

      if (angulo.abs() > 0.1) {
        imagenProcesada = img.copyRotate(imagenOriginal, angle: angulo);
      }

      // 5. NORMALIZACIÓN FORZADA (Para la demo)
      // Redimensionar primero
      imagenProcesada = img.copyResize(
        imagenProcesada,
        width: 800,
        height: 1200,
        interpolation: img.Interpolation.linear,
      );

      // Aplicar filtros post-procesamiento mínimos para diagnóstico
      imagenProcesada = img.grayscale(imagenProcesada);
      // Comentamos la binarización para ver qué está pasando
      // imagenProcesada = img.luminanceThreshold(imagenProcesada, threshold: 0.5);

      // 6. GUARDADO FINAL
      final nombreArchivo = 'hoja_procesada_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final rutaSalida = rutaCarpetaTemporal != null 
          ? '$rutaCarpetaTemporal/$nombreArchivo'
          : '${Directory.systemTemp.path}/$nombreArchivo';
          
      final bytesFinal = img.encodeJpg(imagenProcesada, quality: 85);
      await File(rutaSalida).writeAsBytes(bytesFinal);

      final metadatos = MetadatosProcesamiento(
        escalaX: 800 / imagenOriginal.width,
        escalaY: 1200 / imagenOriginal.height,
        anchoOriginal: imagenOriginal.width.toDouble(),
        altoOriginal: imagenOriginal.height.toDouble(),
        anchoCorregido: 800,
        altoCorregido: 1200,
      );

      return ResultadoProcesamiento(
        exito: true,
        rutaImagenCorregida: rutaSalida,
        advertencias: advertencias,
        marcadoresDetectados: marcadores,
        anguloRotacion: angulo,
        metadatos: metadatos,
      );
    } catch (e) {
      return ResultadoProcesamiento(
        exito: false,
        mensajeError: 'Error crítico al procesar: $e',
      );
    }
  }


  List<Marcador> _detectarMarcadores(img.Image imagen) {
    final grayscale = img.grayscale(imagen.clone());
    final blurred = img.gaussianBlur(grayscale, radius: 2);

    final width = blurred.width;
    final height = blurred.height;
    final quarterWidth = width / 4;
    final quarterHeight = height / 4;

    final posiblesMarcadores = <String, _RegionMarcador>{};

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = blurred.getPixel(x, y);
        final luminance = img.getLuminance(pixel);

        if (luminance < 50) {
          if (x < quarterWidth && y < quarterHeight) {
            _actualizarRegion(posiblesMarcadores, 'sup_izq', x, y);
          } else if (x >= 3 * quarterWidth && y < quarterHeight) {
            _actualizarRegion(posiblesMarcadores, 'sup_der', x, y);
          } else if (x < quarterWidth && y >= 3 * quarterHeight) {
            _actualizarRegion(posiblesMarcadores, 'inf_izq', x, y);
          } else if (x >= 3 * quarterWidth && y >= 3 * quarterHeight) {
            _actualizarRegion(posiblesMarcadores, 'inf_der', x, y);
          }
        }
      }
    }

    final marcadores = <Marcador>[];
    for (final entry in posiblesMarcadores.entries) {
      if (entry.value.puntos.isNotEmpty) {
        final centro = _calcularCentro(entry.value.puntos);
        marcadores.add(Marcador(
          posicion: _mapearPosicion(entry.key),
          x: centro.$1,
          y: centro.$2,
        ));
      }
    }

    return marcadores;
  }

  void _actualizarRegion(Map<String, _RegionMarcador> mapa, String clave, int x, int y) {
    mapa.putIfAbsent(clave, () => _RegionMarcador());
    mapa[clave]!.agregarPunto(x, y);
  }

  (double, double) _calcularCentro(List<(int, int)> puntos) {
    if (puntos.isEmpty) return (0.0, 0.0);
    double sumaX = 0, sumaY = 0;
    for (final p in puntos) {
      sumaX += p.$1;
      sumaY += p.$2;
    }
    return (sumaX / puntos.length, sumaY / puntos.length);
  }

  String _mapearPosicion(String clave) {
    switch (clave) {
      case 'sup_izq':
        return 'superior_izquierdo';
      case 'sup_der':
        return 'superior_derecho';
      case 'inf_izq':
        return 'inferior_izquierdo';
      case 'inf_der':
        return 'inferior_derecho';
      default:
        return clave;
    }
  }

  bool _esEsquina(Marcador m, int ancho, int alto, double minX, double maxX, double minY, double maxY) {
    final esIzquierda = m.x < ancho / 2;
    final esDerecha = m.x >= ancho / 2;
    final esSuperior = m.y < alto / 2;
    final esInferior = m.y >= alto / 2;

    if (esSuperior && esIzquierda) return true;
    if (esSuperior && esDerecha) return true;
    if (esInferior && esIzquierda) return true;
    if (esInferior && esDerecha) return true;

    return false;
  }

  List<double> _calcularDistancias(List<Marcador> marcadores) {
    final distancias = <double>[];
    for (int i = 0; i < marcadores.length; i++) {
      for (int j = i + 1; j < marcadores.length; j++) {
        final d = math.sqrt(
          math.pow(marcadores[j].x - marcadores[i].x, 2) +
              math.pow(marcadores[j].y - marcadores[i].y, 2),
        );
        distancias.add(d);
      }
    }
    return distancias;
  }

  Map<String, dynamic> _validarCalidad(img.Image imagen) {
    final grayscale = img.grayscale(imagen.clone());

    int pixelesOscuros = 0;
    int pixelesBrillantes = 0;
    int totalPixeles = grayscale.width * grayscale.height;

    double sumaContraste = 0;

    for (int y = 0; y < grayscale.height; y++) {
      for (int x = 0; x < grayscale.width; x++) {
        final pixel = grayscale.getPixel(x, y);
        final luminance = img.getLuminance(pixel);

        if (luminance < 30) pixelesOscuros++;
        if (luminance > 225) pixelesBrillantes++;

        if (x > 0) {
          final pixelAnterior = grayscale.getPixel(x - 1, y);
          final lumAnterior = img.getLuminance(pixelAnterior);
          sumaContraste += (luminance - lumAnterior).abs();
        }
        if (y > 0) {
          final pixelArriba = grayscale.getPixel(x, y - 1);
          final lumArriba = img.getLuminance(pixelArriba);
          sumaContraste += (luminance - lumArriba).abs();
        }
      }
    }

    final contrastePromedio = sumaContraste / (totalPixeles * 2);
    final proporcionOscura = pixelesOscuros / totalPixeles;
    final proporcionBrillante = pixelesBrillantes / totalPixeles;

    if (proporcionOscura > 0.40) {
      return {'aprobado': false, 'mensaje': 'Imagen muy oscura'};
    }
    if (proporcionBrillante > 0.15) {
      return {'aprobado': false, 'mensaje': 'Imagen muy brillante (sobreexpuesta)'};
    }
    if (contrastePromedio < 15) {
      return {'aprobado': false, 'mensaje': 'Bajo contraste'};
    }

    return {'aprobado': true, 'mensaje': 'OK'};
  }

  double _calcularAnguloRotacion(List<Marcador> marcadores) {
    Marcador? supIzq;
    Marcador? supDer;

    for (final m in marcadores) {
      if (m.posicion == 'superior_izquierdo') supIzq = m;
      if (m.posicion == 'superior_derecho') supDer = m;
    }

    if (supIzq != null && supDer != null) {
      final dx = supDer.x - supIzq.x;
      final dy = supDer.y - supIzq.y;
      return math.atan2(dy, dx) * 180 / math.pi;
    }

    return 0.0;
  }

  Future<ResultadoProcesamiento> detectarMarcadoresSimple(String rutaImagen) async {
    try {
      final archivo = File(rutaImagen);
      if (!await archivo.exists()) {
        return ResultadoProcesamiento(
          exito: false,
          mensajeError: 'La imagen no existe',
        );
      }

      final bytes = await archivo.readAsBytes();
      final imagen = img.decodeImage(bytes);
      if (imagen == null) {
        return ResultadoProcesamiento(
          exito: false,
          mensajeError: 'No se pudo decodificar la imagen',
        );
      }

      final imagenDeteccion = img.contrast(img.grayscale(imagen.clone()), contrast: 1.5);
      final marcadores = _detectarMarcadores(imagenDeteccion);

      return ResultadoProcesamiento(
        exito: marcadores.length == 4,
        mensajeError: marcadores.length == 4
            ? null
            : 'Se detectaron ${marcadores.length} marcadores, se requieren 4',
        marcadoresDetectados: marcadores,
      );
    } catch (e) {
      return ResultadoProcesamiento(
        exito: false,
        mensajeError: 'Error: $e',
      );
    }
  }
}

class _RegionMarcador {
  final List<(int, int)> puntos = [];

  void agregarPunto(int x, int y) {
    if (puntos.length < 100) {
      puntos.add((x, y));
    }
  }
}