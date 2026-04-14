import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../modelos/area.dart';
import '../modelos/pregunta.dart';
import '../modelos/hoja_patron.dart';
import '../modelos/examen.dart';
import '../modelos/resultado.dart';

class ServicioBaseDatos {
  static Database? _baseDatos;

  Future<Database> get baseDatos async {
    if (_baseDatos != null) return _baseDatos!;
    _baseDatos = await _inicializarDB();
    return _baseDatos!;
  }

  Future<Database> _inicializarDB() async {
    String ruta = join(await getDatabasesPath(), 'examin.db');
    return await openDatabase(
      ruta,
      version: 1,
      onCreate: _crearTablas,
    );
  }

  Future<void> _crearTablas(Database db, int version) async {
    // Tabla Areas
    await db.execute('''
      CREATE TABLE areas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL
      )
    ''');

    // Tabla Hojas Patrón
    await db.execute('''
      CREATE TABLE hojas_patron (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        cantidad_preguntas INTEGER NOT NULL,
        es_puntaje_fijo INTEGER NOT NULL,
        puntaje_maximo REAL NOT NULL
      )
    ''');

    // Tabla Preguntas
    await db.execute('''
      CREATE TABLE preguntas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_hoja_patron INTEGER NOT NULL,
        numero INTEGER NOT NULL,
        respuesta_correcta TEXT NOT NULL,
        valor REAL NOT NULL,
        FOREIGN KEY (id_hoja_patron) REFERENCES hojas_patron (id) ON DELETE CASCADE
      )
    ''');

    // Tabla Exámenes
    await db.execute('''
      CREATE TABLE examenes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_area INTEGER NOT NULL,
        id_hoja_patron INTEGER NOT NULL,
        nombre TEXT NOT NULL,
        fecha_creacion TEXT NOT NULL,
        FOREIGN KEY (id_area) REFERENCES areas (id) ON DELETE CASCADE,
        FOREIGN KEY (id_hoja_patron) REFERENCES hojas_patron (id) ON DELETE CASCADE
      )
    ''');

    // Tabla Resultados
    await db.execute('''
      CREATE TABLE resultados (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_examen INTEGER NOT NULL,
        nombre_estudiante TEXT,
        respuestas_dadas TEXT NOT NULL,
        aciertos INTEGER NOT NULL,
        errores INTEGER NOT NULL,
        nota_final REAL NOT NULL,
        ruta_imagen TEXT NOT NULL,
        FOREIGN KEY (id_examen) REFERENCES examenes (id) ON DELETE CASCADE
      )
    ''');
  }

  // --- Operaciones Area ---
  Future<int> insertarArea(Area area) async {
    final db = await baseDatos;
    return await db.insert('areas', area.aMapa());
  }

  Future<List<Area>> obtenerAreas() async {
    final db = await baseDatos;
    final List<Map<String, dynamic>> mapas = await db.query('areas');
    return mapas.map((m) => Area.desdeMapa(m)).toList();
  }

  Future<int> eliminarArea(int id) async {
    final db = await baseDatos;
    return await db.delete('areas', where: 'id = ?', whereArgs: [id]);
  }

  // --- Operaciones HojaPatron y Preguntas (Transaccional) ---
  Future<int> guardarHojaPatronCompleta(HojaPatron hoja, List<Pregunta> preguntas) async {
    final db = await baseDatos;
    return await db.transaction((txn) async {
      int idHoja = await txn.insert('hojas_patron', hoja.aMapa());
      for (var p in preguntas) {
        final preguntaConId = p.copiarCon(idHojaPatron: idHoja);
        await txn.insert('preguntas', preguntaConId.aMapa());
      }
      return idHoja;
    });
  }

  Future<List<Pregunta>> obtenerPreguntasDeHoja(int idHojaPatron) async {
    final db = await baseDatos;
    final List<Map<String, dynamic>> mapas = await db.query(
      'preguntas',
      where: 'id_hoja_patron = ?',
      whereArgs: [idHojaPatron],
      orderBy: 'numero ASC',
    );
    return mapas.map((m) => Pregunta.desdeMapa(m)).toList();
  }

  // --- Operaciones Examen ---
  Future<int> insertarExamen(Examen examen) async {
    final db = await baseDatos;
    return await db.insert('examenes', examen.aMapa());
  }

  Future<List<Examen>> obtenerExamenesRecientes() async {
    final db = await baseDatos;
    final List<Map<String, dynamic>> mapas = await db.query(
      'examenes',
      orderBy: 'fecha_creacion DESC',
      limit: 10,
    );
    return mapas.map((m) => Examen.desdeMapa(m)).toList();
  }

  // --- Operaciones Resultado ---
  Future<int> guardarResultado(Resultado resultado) async {
    final db = await baseDatos;
    return await db.insert('resultados', resultado.aMapa());
  }

  Future<List<Resultado>> obtenerResultadosDeExamen(int idExamen) async {
    final db = await baseDatos;
    final List<Map<String, dynamic>> mapas = await db.query(
      'resultados',
      where: 'id_examen = ?',
      whereArgs: [idExamen],
    );
    return mapas.map((m) => Resultado.desdeMapa(m)).toList();
  }
}
