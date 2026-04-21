import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'pantallas/inicio/pantalla_inicio.dart';
import 'pantallas/seleccion_area.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES', null);
  runApp(
    const ProviderScope(
      child: ExaminApp(),
    ),
  );
}

class ExaminApp extends StatelessWidget {
  const ExaminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Examin',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // Configuración de idioma (simplificada para este paso)
      locale: const Locale('es', 'ES'),
      initialRoute: '/area',
      routes: {
        '/inicio': (context) => const PantallaInicio(),
        '/area': (context) => const SeleccionArea(),
      },
    );
  }
}
