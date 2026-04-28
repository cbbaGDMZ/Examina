import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class ResultadoProcesamiento {
  final bool exito;
  final String? rutaImagenCorregida;
  final String? mensajeError;
  final List<Marcador> marcadoresDetectados;
  final double? anguloRotacion;
  final MetadatosProcesamiento? metadatos;

  ResultadoProcesamiento({
    required this.exito,
    this.rutaImagenCorregida,
    this.mensajeError,
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
  Future<ResultadoProcesamiento> procesarHoja(String rutaImagen) async {
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

      final marcadores = _detectarMarcadores(imagenOriginal);

      if (marcadores.length != 4) {
        return ResultadoProcesamiento(
          exito: false,
          mensajeError: 'Se detectaron ${marcadores.length} marcadores, se requieren 4',
          marcadoresDetectados: marcadores,
        );
      }

      if (!_validarGeometriaMarcadores(marcadores, imagenOriginal.width, imagenOriginal.height)) {
        return ResultadoProcesamiento(
          exito: false,
          mensajeError: 'La geometría de los marcadores no es válida',
          marcadoresDetectados: marcadores,
        );
      }

      final calidadResult = _validarCalidad(imagenOriginal);
      if (!calidadResult['aprobado']!) {
        return ResultadoProcesamiento(
          exito: false,
          mensajeError: 'Error de calidad: ${calidadResult['mensaje']}',
          marcadoresDetectados: marcadores,
        );
      }

      final enfoqueResult = _validarEnfoque(imagenOriginal);
      if (!enfoqueResult['aprobado']!) {
        return ResultadoProcesamiento(
          exito: false,
          mensajeError: 'Error de enfoque: ${enfoqueResult['mensaje']}',
          marcadoresDetectados: marcadores,
        );
      }

      final angulo = _calcularAnguloRotacion(marcadores);

      final resultadoWarp = _corregirPerspectiva(
        imagenOriginal,
        angulo,
      );

      img.Image? imagenCorregida;
      if (resultadoWarp != null) {
        imagenCorregida = img.decodeImage(resultadoWarp);
      }

      img.Image? imagenNormalizada;
      List<int>? bytesNormalizado;

      if (imagenCorregida != null) {
        imagenNormalizada = img.copyResize(
          imagenCorregida,
          width: 800,
          height: 1200,
          interpolation: img.Interpolation.linear,
        );
        bytesNormalizado = img.encodeJpg(imagenNormalizada, quality: 90);
      }

      final imageBytes = img.encodeJpg(imagenOriginal, quality: 90);
      final tempDir = Directory.systemTemp;
      final rutaSalida = '${tempDir.path}/hoja_corregida_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final bytesGuardar = bytesNormalizado ?? imageBytes;
      final archivoSalida = File(rutaSalida);
      await archivoSalida.writeAsBytes(bytesGuardar);

      final anchoCorregido = imagenCorregida?.width.toDouble() ?? imagenOriginal.width.toDouble();
      final altoCorregido = imagenCorregida?.height.toDouble() ?? imagenOriginal.height.toDouble();
      final anchoFinal = imagenNormalizada?.width.toDouble() ?? anchoCorregido;
      final altoFinal = imagenNormalizada?.height.toDouble() ?? altoCorregido;

      final metadatos = MetadatosProcesamiento(
        escalaX: bytesNormalizado != null ? 800 / imagenOriginal.width : 1.0,
        escalaY: bytesNormalizado != null ? 1200 / imagenOriginal.height : 1.0,
        anchoOriginal: imagenOriginal.width.toDouble(),
        altoOriginal: imagenOriginal.height.toDouble(),
        anchoCorregido: anchoFinal,
        altoCorregido: altoFinal,
      );

      return ResultadoProcesamiento(
        exito: true,
        rutaImagenCorregida: rutaSalida,
        marcadoresDetectados: marcadores,
        anguloRotacion: angulo,
        metadatos: metadatos,
      );
    } catch (e) {
      return ResultadoProcesamiento(
        exito: false,
        mensajeError: 'Error al procesar imagen: $e',
      );
    }
  }

  List<Marcador> _detectarMarcadores(img.Image imagen) {
    final grayscale = img.grayscale(imagen);
    final blurred = img.gaussianBlur(grayscale, radius: 2);
    final edges = img.sobel(blurred);

    final width = edges.width;
    final height = edges.height;
    final quarterWidth = width / 4;
    final quarterHeight = height / 4;

    final posiblesMarcadores = <String, _RegionMarcador>{};

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = edges.getPixel(x, y);
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

  bool _validarGeometriaMarcadores(List<Marcador> marcadores, int ancho, int alto) {
    if (marcadores.length != 4) return false;

    final esperadoMinX = ancho * 0.02;
    final esperadoMaxX = ancho * 0.25;
    final esperadoMinY = alto * 0.02;
    final esperadoMaxY = alto * 0.25;

    for (final m in marcadores) {
      final esEsquina = _esEsquina(m, ancho, alto, esperadoMinX, esperadoMaxX, esperadoMinY, esperadoMaxY);
      if (!esEsquina) return false;
    }

    final distancias = _calcularDistancias(marcadores);
    final distanciaPromedio = distancias.reduce((a, b) => a + b) / distancias.length;

    for (final d in distancias) {
      if (d < distanciaPromedio * 0.5 || d > distanciaPromedio * 1.5) {
        return false;
      }
    }

    return true;
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
    final grayscale = img.grayscale(imagen);

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

    if (proporcionOscura > 0.15) {
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

  Map<String, dynamic> _validarEnfoque(img.Image imagen) {
    final grayscale = img.grayscale(imagen);

    double sumaVariacion = 0;
    int muestras = 0;

    for (int y = 0; y < grayscale.height; y += 10) {
      for (int x = 0; x < grayscale.width; x += 10) {
        if (x > 0 && y > 0) {
          final pixelActual = grayscale.getPixel(x, y);
          final pixelIzq = grayscale.getPixel(x - 1, y);
          final pixelArriba = grayscale.getPixel(x, y - 1);

          final lumActual = img.getLuminance(pixelActual);
          final lumIzq = img.getLuminance(pixelIzq);
          final lumArriba = img.getLuminance(pixelArriba);

          sumaVariacion += (lumActual - lumIzq).abs() + (lumActual - lumArriba).abs();
          muestras += 2;
        }
      }
    }

    final variacionPromedio = muestras > 0 ? sumaVariacion / muestras : 0;

    if (variacionPromedio < 5) {
      return {'aprobado': false, 'mensaje': 'Imagen desenfocada (borrosa)'};
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

  Uint8List? _corregirPerspectiva(img.Image imagen, double angulo) {
    try {
      img.Image rotada = imagen;

      if (angulo.abs() > 0.5) {
        rotada = img.copyRotate(imagen, angle: angulo);
      }

      final bordes = _detectarBordesHorizontales(rotada);
      if (bordes != null) {
        final recortada = img.copyCrop(
          rotada,
          x: bordes.$1,
          y: bordes.$2,
          width: bordes.$3 - bordes.$1,
          height: bordes.$4 - bordes.$2,
        );
        return Uint8List.fromList(img.encodeJpg(recortada, quality: 90));
      }

      return Uint8List.fromList(img.encodeJpg(rotada, quality: 90));
    } catch (e) {
      return null;
    }
  }

  (int, int, int, int)? _detectarBordesHorizontales(img.Image imagen) {
    final grayscale = img.grayscale(imagen);
    final width = grayscale.width;
    final height = grayscale.height;

    int bordeSuperior = 0;
    int bordeInferior = height;
    int bordeIzquierdo = 0;
    int bordeDerecho = width;

    bool encontradoSuperior = false;
    for (int y = 0; y < height ~/ 3; y++) {
      int pixelesOscuros = 0;
      for (int x = 0; x < width; x++) {
        final lum = img.getLuminance(grayscale.getPixel(x, y));
        if (lum < 80) pixelesOscuros++;
      }
      if (pixelesOscuros > width * 0.1) {
        bordeSuperior = math.max(0, y - 20);
        encontradoSuperior = true;
        break;
      }
    }

    if (!encontradoSuperior) return null;

    for (int y = height - 1; y > height * 2 ~/ 3; y--) {
      int pixelesOscuros = 0;
      for (int x = 0; x < width; x++) {
        final lum = img.getLuminance(grayscale.getPixel(x, y));
        if (lum < 80) pixelesOscuros++;
      }
      if (pixelesOscuros > width * 0.1) {
        bordeInferior = math.min(height, y + 20);
        break;
      }
    }

    for (int x = 0; x < width ~/ 3; x++) {
      int pixelesOscuros = 0;
      for (int y = bordeSuperior; y < bordeInferior; y++) {
        final lum = img.getLuminance(grayscale.getPixel(x, y));
        if (lum < 80) pixelesOscuros++;
      }
      if (pixelesOscuros > (bordeInferior - bordeSuperior) * 0.1) {
        bordeIzquierdo = math.max(0, x - 20);
        break;
      }
    }

    for (int x = width - 1; x > width * 2 ~/ 3; x--) {
      int pixelesOscuros = 0;
      for (int y = bordeSuperior; y < bordeInferior; y++) {
        final lum = img.getLuminance(grayscale.getPixel(x, y));
        if (lum < 80) pixelesOscuros++;
      }
      if (pixelesOscuros > (bordeInferior - bordeSuperior) * 0.1) {
        bordeDerecho = math.min(width, x + 20);
        break;
      }
    }

    if (bordeInferior - bordeSuperior < height * 0.5 ||
        bordeDerecho - bordeIzquierdo < width * 0.5) {
      return null;
    }

    return (bordeIzquierdo, bordeSuperior, bordeDerecho, bordeInferior);
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

      final marcadores = _detectarMarcadores(imagen);

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