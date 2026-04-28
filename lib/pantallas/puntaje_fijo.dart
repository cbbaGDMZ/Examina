import 'package:flutter/material.dart';

class PantallaPuntajeFijo extends StatefulWidget {
  const PantallaPuntajeFijo({super.key});

  @override
  State<PantallaPuntajeFijo> createState() => _PantallaPuntajeFijoState();
}

class _PantallaPuntajeFijoState extends State<PantallaPuntajeFijo> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _cantidadPreguntasController = TextEditingController(text: '20');
  final TextEditingController _valorPreguntaController = TextEditingController(text: '5.0');

  double _notaMaxima = 20.0;

  @override
  void initState() {
    super.initState();
    _recalcularNota();
  }

  @override
  void dispose() {
    _cantidadPreguntasController.dispose();
    _valorPreguntaController.dispose();
    super.dispose();
  }

  void _recalcularNota() {
    final preguntas = double.tryParse(_cantidadPreguntasController.text) ?? 0;
    final valor = double.tryParse(_valorPreguntaController.text) ?? 0;
    setState(() {
      _notaMaxima = preguntas * valor;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Configurar puntaje fijo'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Define la estructura del examen',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Define cómo se evaluará cada respuesta',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              
              _buildInputField(
                label: 'Número de preguntas',
                controller: _cantidadPreguntasController,
                icon: Icons.format_list_numbered,
                hint: 'Ej: 20',
                isInteger: true,
              ),
              const SizedBox(height: 24),
              _buildInputField(
                label: 'Valor de cada pregunta',
                controller: _valorPreguntaController,
                icon: Icons.star_outline,
                hint: 'Ej: 5.0',
              ),
              
              const SizedBox(height: 32),
              _buildNotaMaximaCard(),
              const SizedBox(height: 24),
              
              _buildInfoResumen(),
              
              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isFormValid() ? () {
                    if (_formKey.currentState!.validate()) {
                      Navigator.pushNamed(context, '/escaneo');
                    }
                  } : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.deepPurpleAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
      ),
    );
  }

  bool _isFormValid() {
    final preguntas = int.tryParse(_cantidadPreguntasController.text) ?? 0;
    final valor = double.tryParse(_valorPreguntaController.text) ?? 0;
    final notaTotal = preguntas * valor;
    // La nota debe ser exactamente 100
    return preguntas >= 20 && preguntas <= 100 && valor > 0 && notaTotal == 100;
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool isInteger = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: !isInteger),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.deepPurpleAccent),
            hintText: hint,
            filled: true,
            fillColor: Colors.grey.shade900,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade800),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.deepPurpleAccent, width: 2),
            ),
          ),
          onChanged: (value) => _recalcularNota(),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Campo requerido';
            final numValue = double.tryParse(value);
            if (numValue == null) return 'Ingrese un número válido';
            
            if (isInteger) {
              final intValue = int.tryParse(value);
              if (intValue == null) return 'Ingrese un número entero';
              if (intValue < 20 || intValue > 100) return 'Rango: 20 - 100';
            } else if (numValue <= 0) {
              return 'Debe ser mayor a 0';
            }

            // Validación de nota total estricta a 100
            final preguntas = int.tryParse(_cantidadPreguntasController.text) ?? 0;
            final valor = double.tryParse(_valorPreguntaController.text) ?? 0;
            final total = preguntas * valor;
            if (total != 100) {
              return 'La nota total debe ser exactamente 100';
            }
            
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildNotaMaximaCard() {
    String? mensajeError;
    if (_notaMaxima > 100) {
      mensajeError = '¡Excede los 100 puntos!';
    } else if (_notaMaxima < 100) {
      mensajeError = 'Debe sumar exactamente 100 puntos';
    }

    return Container(
      width: double.infinity,
      height: 150, // Altura fija para evitar que el card cambie de tamaño
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (_notaMaxima != 100) 
              ? Colors.redAccent.withOpacity(0.5) 
              : Colors.deepPurpleAccent.withOpacity(0.3),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Nota calculada',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            '${_notaMaxima.toStringAsFixed(1)} puntos',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurpleAccent,
            ),
          ),
          const SizedBox(height: 8),
          // Contenedor de altura fija para el mensaje
          SizedBox(
            height: 20,
            child: mensajeError != null
                ? Text(
                    mensajeError,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoResumen() {
    return Column(
      children: [
        _buildResumenItem(Icons.check, 'Todas las preguntas tienen el mismo peso.'),
        const SizedBox(height: 12),
        _buildResumenItem(Icons.close, 'Incorrectas y omisiones valen 0.'),
      ],
    );
  }

  Widget _buildResumenItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.deepPurpleAccent),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          ),
        ),
      ],
    );
  }
}
