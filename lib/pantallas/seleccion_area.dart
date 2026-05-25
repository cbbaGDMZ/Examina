import 'package:flutter/material.dart';

class SeleccionArea extends StatefulWidget {
  const SeleccionArea({super.key});

  @override
  State<SeleccionArea> createState() => _SeleccionAreaState();
}

class _SeleccionAreaState extends State<SeleccionArea> {
  final List<Map<String, dynamic>> _opciones = [
    {'nombre': 'TECNOLOGÍA', 'icono': Icons.settings},
    {'nombre': 'MEDICINA', 'icono': Icons.medical_services},
  ];

  int? _opcionSeleccionada;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       appBar: AppBar(
        title: const Text('pantalla inicio'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: SizedBox(
                height: 200, // Altura fija para el catálogo
                child: PageView.builder(
                  controller: PageController(viewportFraction: 0.7),
                  itemCount: _opciones.length,
                  itemBuilder: (context, index) {
                    final opcion = _opciones[index];
                    final estaSeleccionado = _opcionSeleccionada == index;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _opcionSeleccionada = index;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: estaSeleccionado
                              ? Colors.deepPurple.shade700
                              : Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: estaSeleccionado
                                ? Colors.deepPurpleAccent
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              opcion['icono'] as IconData,
                              size: 60,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              opcion['nombre'] as String,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0, left: 24.0, right: 24.0, top: 16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _opcionSeleccionada == null
                    ? null
                    : () {
                        Navigator.pushNamed(context, '/puntaje');
                      },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: _opcionSeleccionada != null 
                      ? Colors.deepPurpleAccent 
                      : Colors.grey.shade800,
                ),
                child: const Text(
                  'Continuar',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
