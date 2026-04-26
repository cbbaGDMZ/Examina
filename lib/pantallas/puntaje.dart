import 'package:flutter/material.dart';

class PantallaPuntaje extends StatefulWidget {
  const PantallaPuntaje({super.key});

  @override
  State<PantallaPuntaje> createState() => _PantallaPuntajeState();
}

class _PantallaPuntajeState extends State<PantallaPuntaje> {
  String? _tipoSeleccionado;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Configuración de Puntaje'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selecciona el tipo de puntaje',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Define cómo se evaluarán las respuestas',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            _buildOptionCard(
              id: 'fijo',
              titulo: 'Puntaje fijo',
              descripcion: 'Cada respuesta correcta vale lo mismo.',
              ejemplo: '20 preguntas | 1 punto c/u',
              icono: Icons.equalizer,
            ),
            const SizedBox(height: 16),
            _buildOptionCard(
              id: 'variado',
              titulo: 'Puntaje variado',
              descripcion: 'Las respuestas suman según una configuración definida.',
              ejemplo: 'Correcta: +1 | Incorrecta: -0.25',
              icono: Icons.add_chart,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _tipoSeleccionado == null
                    ? null
                    : () {
                        if (_tipoSeleccionado == 'fijo') {
                          Navigator.pushNamed(context, '/puntaje_fijo');
                        } else if (_tipoSeleccionado == 'variado') {
                          Navigator.pushNamed(context, '/puntaje_variado');
                        }
                      },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: _tipoSeleccionado != null 
                      ? Colors.deepPurpleAccent 
                      : Colors.grey.shade800,
                ),
                child: const Text(
                  'Continuar',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required String id,
    required String titulo,
    required String descripcion,
    required String ejemplo,
    required IconData icono,
  }) {
    final estaSeleccionado = _tipoSeleccionado == id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _tipoSeleccionado = id;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: estaSeleccionado ? Colors.deepPurple.withOpacity(0.2) : Colors.grey.shade900,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: estaSeleccionado ? Colors.deepPurpleAccent : Colors.grey.shade800,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: estaSeleccionado ? Colors.deepPurpleAccent : Colors.grey.shade800,
                shape: BoxShape.circle,
              ),
              child: Icon(icono, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        titulo,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (estaSeleccionado)
                        const Icon(Icons.check_circle, color: Colors.deepPurpleAccent),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    descripcion,
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ej: $ejemplo',
                    style: const TextStyle(
                      color: Colors.deepPurpleAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
