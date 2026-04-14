class Area {
  final int? id;
  final String nombre;

  Area({
    this.id,
    required this.nombre,
  });

  Map<String, dynamic> aMapa() {
    return {
      'id': id,
      'nombre': nombre,
    };
  }

  factory Area.desdeMapa(Map<String, dynamic> mapa) {
    return Area(
      id: mapa['id'] as int?,
      nombre: mapa['nombre'] as String,
    );
  }

  Area copiarCon({
    int? id,
    String? nombre,
  }) {
    return Area(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
    );
  }
}
