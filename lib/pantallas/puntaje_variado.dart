import 'package:flutter/material.dart';

class GrupoPuntaje {
  final TextEditingController startController;
  final TextEditingController endController;
  final TextEditingController valueController;

  GrupoPuntaje({String start = '', String end = '', String value = ''}) 
      : startController = TextEditingController(text: start),
        endController = TextEditingController(text: end),
        valueController = TextEditingController(text: value);

  void dispose() {
    startController.dispose();
    endController.dispose();
    valueController.dispose();
  }
}

class PantallaPuntajeVariado extends StatefulWidget {
  const PantallaPuntajeVariado({super.key});

  @override
  State<PantallaPuntajeVariado> createState() => _PantallaPuntajeVariadoState();
}

class _PantallaPuntajeVariadoState extends State<PantallaPuntajeVariado> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _cantidadPreguntasController = TextEditingController(text: '20');
  
  final List<GrupoPuntaje> _grupos = [
    GrupoPuntaje(start: '1', end: '10', value: '5.0'),
    GrupoPuntaje(start: '11', end: '20', value: '5.0'),
  ];

  double _notaCalculada = 100.0;
  String? _errorGlobal;

  @override
  void initState() {
    super.initState();
    _recalcularYValidar();
  }

  @override
  void dispose() {
    _cantidadPreguntasController.dispose();
    for (var grupo in _grupos) {
      grupo.dispose();
    }
    super.dispose();
  }

  void _agregarGrupo() {
    setState(() {
      _grupos.add(GrupoPuntaje());
      _recalcularYValidar();
    });
  }

  void _eliminarGrupo(int index) {
    if (_grupos.length > 2) {
      setState(() {
        _grupos[index].dispose();
        _grupos.removeAt(index);
        _recalcularYValidar();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe haber al menos 2 grupos')),
      );
    }
  }

  void _recalcularYValidar() {
    double suma = 0.0;
    String? error;

    final totalPreguntas = int.tryParse(_cantidadPreguntasController.text) ?? 0;
    if (totalPreguntas < 20 || totalPreguntas > 100) {
      error = 'La cantidad total de preguntas debe ser entre 20 y 100.';
    }

    List<Map<String, dynamic>> intervalos = [];

    for (var grupo in _grupos) {
      final start = int.tryParse(grupo.startController.text);
      final end = int.tryParse(grupo.endController.text);
      final value = double.tryParse(grupo.valueController.text);

      if (start != null && end != null && value != null && start > 0 && end >= start) {
        intervalos.add({'start': start, 'end': end, 'value': value});
        suma += (end - start + 1) * value;
      } else {
        error ??= 'Complete todos los campos de los grupos correctamente.';
      }
    }

    if (error == null) {
      intervalos.sort((a, b) => (a['start'] as int).compareTo(b['start'] as int));

      if (intervalos.isEmpty) {
        error = 'Defina los grupos de preguntas.';
      } else if (intervalos.first['start'] != 1) {
        error = 'Los grupos deben empezar desde la pregunta 1.';
      } else if (intervalos.last['end'] != totalPreguntas) {
        error = 'Los grupos deben cubrir hasta la pregunta $totalPreguntas.';
      } else {
        for (int i = 0; i < intervalos.length - 1; i++) {
          final actualEnd = intervalos[i]['end'] as int;
          final siguienteStart = intervalos[i + 1]['start'] as int;

          if (siguienteStart <= actualEnd) {
            error = 'Hay preguntas superpuestas entre los grupos.';
            break;
          } else if (siguienteStart > actualEnd + 1) {
            error = 'Faltan preguntas por asignar entre los grupos.';
            break;
          }
        }
      }
    }

    setState(() {
      _notaCalculada = suma;
      _errorGlobal = error;
    });
  }

  bool _isFormValid() {
    if (_errorGlobal != null) return false;
    if (_notaCalculada != 100.0) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Configurar puntaje variado'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24.0),
                children: [
                  const Text(
                    'Define grupos de preguntas con distintos pesos',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  
                  _buildGlobalInputs(),
                  
                  const SizedBox(height: 32),
                  const Text(
                    'Grupos de preguntas',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  ...List.generate(_grupos.length, (index) => _buildGrupoItem(index)),
                  
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _agregarGrupo,
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar grupo'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: Colors.deepPurpleAccent),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  _buildInfoResumen(),
                ],
              ),
            ),
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalInputs() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Cantidad preguntas', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _cantidadPreguntasController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade900,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onChanged: (_) => _recalcularYValidar(),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Número grupos', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 8),
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.centerLeft,
                child: Text('${_grupos.length}', style: const TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGrupoItem(int index) {
    final grupo = _grupos[index];
    final startVal = int.tryParse(grupo.startController.text) ?? 0;
    final endVal = int.tryParse(grupo.endController.text) ?? 0;
    final val = double.tryParse(grupo.valueController.text) ?? 0;
    final subtotal = (endVal >= startVal && startVal > 0) ? (endVal - startVal + 1) * val : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Grupo ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurpleAccent)),
              if (_grupos.length > 2)
                InkWell(
                  onTap: () => _eliminarGrupo(index),
                  child: const Icon(Icons.close, color: Colors.redAccent, size: 20),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Del', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: grupo.startController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: _inputDecoration(),
                      onChanged: (_) => _recalcularYValidar(),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('-', style: TextStyle(color: Colors.grey)),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Al', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: grupo.endController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: _inputDecoration(),
                      onChanged: (_) => _recalcularYValidar(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Valor', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: grupo.valueController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      decoration: _inputDecoration(),
                      onChanged: (_) => _recalcularYValidar(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Subtotal: ${subtotal.toStringAsFixed(1)} pts',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      filled: true,
      fillColor: Colors.black26,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.deepPurpleAccent)),
    );
  }

  Widget _buildInfoResumen() {
    return Column(
      children: [
        Row(
          children: [
            const Icon(Icons.info_outline, size: 20, color: Colors.deepPurpleAccent),
            const SizedBox(width: 12),
            Expanded(child: Text('Las preguntas pueden tener pesos distintos.', style: TextStyle(color: Colors.grey.shade400, fontSize: 14))),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.check_circle_outline, size: 20, color: Colors.deepPurpleAccent),
            const SizedBox(width: 12),
            Expanded(child: Text('La suma total debe ser exactamente 100.', style: TextStyle(color: Colors.grey.shade400, fontSize: 14))),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomSection() {
    String? mensajeError = _errorGlobal;
    if (mensajeError == null) {
      if (_notaCalculada > 100) {
        mensajeError = '¡Excede 100 puntos!';
      } else if (_notaCalculada < 100) {
        mensajeError = 'Debe sumar exactamente 100 puntos.';
      }
    }

    final bool esValido = _isFormValid();

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: esValido 
                    ? Colors.deepPurpleAccent.withOpacity(0.3) 
                    : Colors.redAccent.withOpacity(0.5),
              ),
            ),
            child: Column(
              children: [
                const Text('Nota calculada', style: TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 8),
                Text(
                  '${_notaCalculada.toStringAsFixed(1)} puntos',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.deepPurpleAccent),
                ),
                if (mensajeError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    mensajeError,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: esValido ? () {
                if (_formKey.currentState!.validate()) {
                  // Navigator.pushNamed(context, '/siguiente');
                }
              } : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.deepPurpleAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Continuar', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
