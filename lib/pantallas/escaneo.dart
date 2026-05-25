import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import '../../servicios/servicio_camara.dart';
import '../../servicios/servicio_procesamiento_imagen.dart';
import '../../servicios/servicio_omr.dart';

class PantallaEscaneo extends StatefulWidget {
  final String tipoEscaneo;
  final int cantidadPreguntas;

  const PantallaEscaneo({
    super.key,
    this.tipoEscaneo = 'examen',
    this.cantidadPreguntas = 20,
  });

  @override
  State<PantallaEscaneo> createState() => _PantallaEscaneoState();
}

class _PantallaEscaneoState extends State<PantallaEscaneo> {
  final ServicioCamara _servicioCamara = ServicioCamara();
  final ServicioProcesamientoImagen _servicioProcesamiento = ServicioProcesamientoImagen();
  final ServicioOMR _servicioOMR = ServicioOMR();
  
  bool _escaneando = false;
  bool _procesando = false;
  String? _rutaImagenCapturada;
  String? _rutaImagenCorregida;
  ResultadoProcesamiento? _ultimoResultado;
  Map<int, String>? _respuestasDetectadas;
  int _intentos = 0;
  int _maxIntentos = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tipoEscaneo == 'patron' ? 'Escanear Hoja Patrón' : 'Escanear Examen'),
        centerTitle: true,
      ),
      body: _buildCuerpo(),
    );
  }

  Widget _buildCuerpo() {
    if (_escaneando || _procesando) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(_escaneando ? 'Esperando cámara...' : 'Analizando imagen...', 
                style: const TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    if (_ultimoResultado != null && _ultimoResultado!.exito) {
      return _buildResultadoExito();
    }

    if (_ultimoResultado != null && !_ultimoResultado!.exito) {
      return _buildResultadoError();
    }

    return _buildBotonEscanear();
  }

  Widget _buildBotonEscanear() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.document_scanner,
            size: 80,
            color: Colors.deepPurpleAccent,
          ),
          const SizedBox(height: 20),
          Text(
            widget.tipoEscaneo == 'patron' 
                ? 'Escanear Hoja Patrón' 
                : 'Escanear Examen',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Asegúrate de que los 4 marcadores\nde esquina sean visibles',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _iniciarEscaneo,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Escanear'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
              ),
              const SizedBox(width: 15),
              ElevatedButton.icon(
                onPressed: _cargarImagenDeArchivo,
                icon: const Icon(Icons.image),
                label: const Text('Cargar Imagen'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultadoExito() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle,
            size: 60,
            color: Colors.green,
          ),
          const SizedBox(height: 15),
          const Text(
            'Escaneo exitoso',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          if (_ultimoResultado!.advertencias.isNotEmpty) ...[
            ..._ultimoResultado!.advertencias.map((adv) => Text(
              '⚠️ $adv',
              style: const TextStyle(color: Colors.orange, fontSize: 13),
            )),
            const SizedBox(height: 10),
          ],
          if (_rutaImagenCorregida != null) ...[
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.deepPurple, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  File(_rutaImagenCorregida!),
                  key: ValueKey(_rutaImagenCorregida), // Forzar refresco
                  height: 300,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          if (_respuestasDetectadas != null)
            Text(
              'Respuestas detectadas: ${widget.cantidadPreguntas}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context, {
                'exito': true,
                'rutaImagen': _rutaImagenCorregida,
                'respuestas': _respuestasDetectadas,
                'marcadores': _ultimoResultado!.marcadoresDetectados,
              });
            },
            icon: const Icon(Icons.check),
            label: const Text('Continuar'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _ultimoResultado = null),
            child: const Text('Repetir escaneo'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultadoError() {
    final puedeReintentar = _intentos < _maxIntentos;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red,
          ),
          const SizedBox(height: 20),
          const Text(
            'Escaneo fallido',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            _ultimoResultado!.mensajeError ?? 'Error desconocido',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent),
          ),
          const SizedBox(height: 10),
          Text(
            'Intento $_intentos de $_maxIntentos',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 30),
          if (puedeReintentar) ...[
            ElevatedButton.icon(
              onPressed: _iniciarEscaneo,
              icon: const Icon(Icons.refresh),
              label: const Text('Reescanear'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
            ),
          ] else ...[
            const Text(
              'Máximo de intentos alcanzado',
              style: TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () {
                Navigator.pop(context, {'exito': false});
              },
              child: const Text('Cancelar'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _iniciarEscaneo() async {
    if (Platform.isLinux || Platform.isWindows) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El escáner de cámara nativo no está disponible en Desktop. Use "Cargar Imagen".')),
      );
      return;
    }
    setState(() {
      _escaneando = true;
      _ultimoResultado = null;
      _respuestasDetectadas = null;
    });

    try {
      final rutaImagen = await _servicioCamara.escanearHoja();

      if (rutaImagen == null) {
        setState(() {
          _escaneando = false;
        });
        return;
      }

      await _procesarImagen(rutaImagen);
    } catch (e) {
      setState(() {
        _escaneando = false;
        _procesando = false;
        _ultimoResultado = ResultadoProcesamiento(
          exito: false,
          mensajeError: 'Error al escanear: $e',
        );
        _intentos++;
      });
    }
  }

  Future<void> _cargarImagenDeArchivo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        String rutaArchivo = result.files.single.path!;
        String extension = result.files.single.extension?.toLowerCase() ?? '';

        if (extension == 'pdf') {
          setState(() {
            _escaneando = true;
            _procesando = false;
          });
          
          final rutaImagen = await _convertirPdfAImagen(rutaArchivo);
          if (rutaImagen != null) {
            await _procesarImagen(rutaImagen);
          } else {
            setState(() {
              _escaneando = false;
              _ultimoResultado = ResultadoProcesamiento(
                exito: false,
                mensajeError: 'No se pudo extraer la imagen del PDF',
              );
            });
          }
        } else {
          await _procesarImagen(rutaArchivo);
        }
      }
    } catch (e) {
      setState(() {
        _ultimoResultado = ResultadoProcesamiento(
          exito: false,
          mensajeError: 'Error al cargar archivo: $e',
        );
      });
    }
  }

  Future<String?> _convertirPdfAImagen(String rutaPdf) async {
    try {
      final document = await PdfDocument.openFile(rutaPdf);
      final page = document.pages[0];
      
      final pageImage = await page.render(
        fullWidth: page.width * 3,
        fullHeight: page.height * 3,
      );
      
      await document.dispose();

      if (pageImage != null) {
        final tempDir = await getTemporaryDirectory();
        final rutaSalida = '${tempDir.path}/pdf_page_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final file = File(rutaSalida);
        
        final image = img.Image.fromBytes(
          width: pageImage.width,
          height: pageImage.height,
          bytes: pageImage.pixels.buffer,
          numChannels: 4,
          order: pageImage.format == ui.PixelFormat.bgra8888 
              ? img.ChannelOrder.bgra 
              : img.ChannelOrder.rgba,
        );
        
        final jpegBytes = img.encodeJpg(image);
        await file.writeAsBytes(jpegBytes);
        return rutaSalida;
      }
    } catch (e) {
      print('Error convirtiendo PDF: $e');
    }
    return null;
  }

  Future<void> _procesarImagen(String rutaImagen) async {
    setState(() {
      _rutaImagenCapturada = rutaImagen;
      _escaneando = false;
      _procesando = true;
    });

    try {
      final tempDir = await getTemporaryDirectory();
      
      // Ejecutar procesamiento en Isolate
      final resultado = await compute(_procesarEnIsolate, {
        'servicio': _servicioProcesamiento,
        'ruta': rutaImagen,
        'dir': tempDir.path,
      });

      if (resultado.exito && resultado.rutaImagenCorregida != null) {
        // DETECCIÓN OMR (Aquí conectamos con el siguiente servicio)
        final respuestas = await _servicioOMR.detectarRespuestas(
          resultado.rutaImagenCorregida!, 
          widget.cantidadPreguntas
        );

        setState(() {
          _procesando = false;
          _ultimoResultado = resultado;
          _rutaImagenCorregida = resultado.rutaImagenCorregida;
          _respuestasDetectadas = respuestas;
        });
      } else {
        setState(() {
          _procesando = false;
          _ultimoResultado = resultado;
          _intentos++;
        });
      }
    } catch (e) {
      setState(() {
        _procesando = false;
        _ultimoResultado = ResultadoProcesamiento(
          exito: false,
          mensajeError: 'Error al procesar: $e',
        );
        _intentos++;
      });
    }
  }

  static Future<ResultadoProcesamiento> _procesarEnIsolate(Map<String, dynamic> params) async {
    final ServicioProcesamientoImagen servicio = params['servicio'];
    final String ruta = params['ruta'];
    final String? dir = params['dir'];
    return await servicio.procesarHoja(ruta, rutaCarpetaTemporal: dir);
  }

  @override
  void dispose() {
    _servicioCamara.dispose();
    super.dispose();
  }
}

