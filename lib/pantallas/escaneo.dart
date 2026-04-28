import 'dart:io';
import 'package:flutter/material.dart';
import '../../servicios/servicio_camara.dart';
import '../../servicios/servicio_procesamiento_imagen.dart';

class PantallaEscaneo extends StatefulWidget {
  final String tipoEscaneo;

  const PantallaEscaneo({
    super.key,
    this.tipoEscaneo = 'examen',
  });

  @override
  State<PantallaEscaneo> createState() => _PantallaEscaneoState();
}

class _PantallaEscaneoState extends State<PantallaEscaneo> {
  final ServicioCamara _servicioCamara = ServicioCamara();
  final ServicioProcesamientoImagen _servicioProcesamiento = ServicioProcesamientoImagen();
  
  bool _escaneando = false;
  bool _procesando = false;
  String? _rutaImagenCapturada;
  String? _rutaImagenCorregida;
  ResultadoProcesamiento? _ultimoResultado;
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
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Procesando...', style: TextStyle(fontSize: 16)),
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
          ElevatedButton.icon(
            onPressed: _iniciarEscaneo,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Escanear'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultadoExito() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle,
            size: 80,
            color: Colors.green,
          ),
          const SizedBox(height: 20),
          const Text(
            'Escaneo exitoso',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            'Marcadores detectados: ${_ultimoResultado!.marcadoresDetectados.length}',
            style: const TextStyle(color: Colors.grey),
          ),
          if (_ultimoResultado!.anguloRotacion != null) ...[
            const SizedBox(height: 5),
            Text(
              'Rotación corregida: ${_ultimoResultado!.anguloRotacion!.toStringAsFixed(1)}°',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
          if (_rutaImagenCorregida != null) ...[
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.deepPurple),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(_rutaImagenCorregida!),
                  height: 200,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context, {
                'exito': true,
                'rutaImagen': _rutaImagenCorregida,
                'marcadores': _ultimoResultado!.marcadoresDetectados,
              });
            },
            icon: const Icon(Icons.check),
            label: const Text('Continuar'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
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
    setState(() {
      _escaneando = true;
      _ultimoResultado = null;
    });

    try {
      final rutaImagen = await _servicioCamara.escanearHoja();

      if (rutaImagen == null) {
        setState(() {
          _escaneando = false;
        });
        return;
      }

      setState(() {
        _rutaImagenCapturada = rutaImagen;
        _escaneando = false;
        _procesando = true;
      });

      await Future.delayed(const Duration(milliseconds: 500));

      final resultado = await _servicioProcesamiento.procesarHoja(rutaImagen);

      setState(() {
        _procesando = false;
        _ultimoResultado = resultado;
        if (resultado.exito) {
          _rutaImagenCorregida = resultado.rutaImagenCorregida;
        } else {
          _intentos++;
        }
      });
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

  @override
  void dispose() {
    _servicioCamara.dispose();
    super.dispose();
  }
}
