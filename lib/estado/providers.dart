import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../servicios/servicio_base_datos.dart';
import '../servicios/servicio_omr.dart';
import '../servicios/servicio_camara.dart';
import '../servicios/servicio_calificacion.dart';
import '../modelos/area.dart';
import '../modelos/examen.dart';
import '../modelos/hoja_patron.dart';
import '../modelos/pregunta.dart';
import '../modelos/resultado.dart';

// --- Providers de Servicios ---

final servicioBaseDatosProvider = Provider<ServicioBaseDatos>((ref) {
  return ServicioBaseDatos();
});

final servicioOMRProvider = Provider<ServicioOMR>((ref) {
  return ServicioOMR();
});

final servicioCamaraProvider = Provider<ServicioCamara>((ref) {
  final servicio = ServicioCamara();
  ref.onDispose(() => servicio.dispose());
  return servicio;
});

final servicioCalificacionProvider = Provider<ServicioCalificacion>((ref) {
  return ServicioCalificacion();
});

// --- Providers de Estado de Datos ---

/// Lista de todas las áreas disponibles en la base de datos.
final areasProvider = FutureProvider<List<Area>>((ref) async {
  final db = ref.watch(servicioBaseDatosProvider);
  return await db.obtenerAreas();
});

/// Área actualmente seleccionada para el nuevo examen.
final areaSeleccionadaProvider = StateProvider<Area?>((ref) => null);

/// Hoja patrón que se está configurando o escaneando.
final hojaPatronActualProvider = StateProvider<HojaPatron?>((ref) => null);

/// Lista de preguntas asociadas a la hoja patrón actual.
final preguntasActualesProvider = StateProvider<List<Pregunta>>((ref) => []);

/// Examen que se está realizando actualmente.
final examenActualProvider = StateProvider<Examen?>((ref) => null);

/// Lista de resultados (exámenes de alumnos) procesados en la sesión actual.
final resultadosActualesProvider = StateProvider<List<Resultado>>((ref) => []);

// --- Providers de Consultas Específicas ---

/// Obtiene los exámenes recientes desde la base de datos.
final examenesRecientesProvider = FutureProvider<List<Examen>>((ref) async {
  final db = ref.watch(servicioBaseDatosProvider);
  return await db.obtenerExamenesRecientes();
});

/// Obtiene los resultados de un examen específico.
final resultadosPorExamenProvider = FutureProvider.family<List<Resultado>, int>((ref, idExamen) async {
  final db = ref.watch(servicioBaseDatosProvider);
  return await db.obtenerResultadosDeExamen(idExamen);
});
