// 📂 lib/models/lugar_data.dart
// ✅ Modelo definitivo Lugares (Matchy) - FIX ORTOGRÁFICO GPS
// 🔥 ARREGLO: Se ajustaron los mapeos para leer 'latitud'/'longitud' de Firebase.

class SedeData {
  final String id;
  final String nombre;
  final String direccion;

  final double? latitude;
  final double? longitude;

  const SedeData({
    required this.id,
    required this.nombre,
    required this.direccion,
    this.latitude,
    this.longitude,
  });

  factory SedeData.fromMap(String id, Map<String, dynamic> map) {
    return SedeData(
      id: id,
      nombre: (map['nombre'] ?? '').toString(),
      direccion: (map['direccion'] ?? '').toString(),
      // 🔥 Buscamos latitud/latitud y longitud/longitude para evitar errores
      latitude: (map['latitud'] ?? map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitud'] ?? map['longitude'] ?? 0.0).toDouble(),
    );
  }
}

class LugarData {
  final String id;
  final String nombre;
  final String direccion;
  final String bio;
  final List<String> fotos;
  final String fotoPortada;
  final String sitioWeb;
  final int orden;

  final double? latitude;
  final double? longitude;

  final List<String> tipos;
  final List<SedeData> sedes;

  const LugarData({
    required this.id,
    required this.nombre,
    required this.direccion,
    required this.bio,
    required this.fotos,
    required this.fotoPortada,
    required this.sitioWeb,
    required this.orden,
    this.latitude,
    this.longitude,
    this.tipos = const [],
    this.sedes = const [],
  });

  bool get hasSitioWeb => sitioWeb.trim().isNotEmpty;

  factory LugarData.embedded({
    required String id,
    required String nombre,
    required String direccion,
    required List<String> fotos,
    required String fotoPortada,
    double? latitude,
    double? longitude,
  }) {
    return LugarData(
      id: id,
      nombre: nombre,
      direccion: direccion,
      bio: '',
      fotos: fotos,
      fotoPortada: fotoPortada,
      sitioWeb: '',
      orden: 9999,
      latitude: latitude,
      longitude: longitude,
      tipos: const [],
      sedes: const [],
    );
  }

  static String _normTipo(dynamic v) => v.toString().trim().toLowerCase();

  factory LugarData.fromMap({
    required String id,
    required Map<String, dynamic> data,
  }) {
    final fotosRaw = data['fotos'];
    final fotos = (fotosRaw is List)
        ? fotosRaw.map((e) => e.toString()).toList()
        : <String>[];

    final tiposRaw = data['tipos'];
    List<String> tipos = (tiposRaw is List)
        ? tiposRaw.map(_normTipo).where((s) => s.isNotEmpty).toList()
        : <String>[];

    final tipoLegacy = _normTipo(data['tipo'] ?? '');
    if (tipos.isEmpty && tipoLegacy.isNotEmpty) {
      tipos = [tipoLegacy];
    }

    final sedesRaw = data['sedes'];
    final List<SedeData> sedes = [];
    if (sedesRaw is Map) {
      for (final entry in sedesRaw.entries) {
        final key = entry.key.toString();
        final value = entry.value;
        if (value is Map) {
          sedes.add(
            SedeData.fromMap(key, Map<String, dynamic>.from(value)),
          );
        }
      }
    }

    final ordenRaw = data['orden'];
    final orden = (ordenRaw is num) ? ordenRaw.toInt() : 9999;

    return LugarData(
      id: id,
      nombre: (data['nombre'] ?? '').toString(),
      direccion: (data['direccion'] ?? '').toString(),
      bio: (data['bio'] ?? '').toString(),
      fotos: fotos,
      fotoPortada: (data['fotoPortada'] ?? '').toString(),
      sitioWeb: (data['webUrl'] ?? '').toString(),
      orden: orden,
      tipos: tipos,
      sedes: sedes,
      // 🔥 Buscamos latitud/latitud y longitud/longitude
      latitude: (data['latitud'] ?? data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitud'] ?? data['longitude'] ?? 0.0).toDouble(),
    );
  }
}