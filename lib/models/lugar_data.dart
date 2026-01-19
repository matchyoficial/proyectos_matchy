// 📂 lib/models/lugar_data.dart
// ✅ Modelo definitivo Lugares (Matchy)
// ✅ Soporta ORDEN + SEDES (map sede_1, sede_2...)
// ✅ Soporta TIPOS (array) + compatibilidad si existe "tipo" legacy
// ✅ Restaura LugarData.embedded para pantallas de citas

class SedeData {
  final String id; // sede_1, sede_2...
  final String nombre;
  final String direccion;

  const SedeData({
    required this.id,
    required this.nombre,
    required this.direccion,
  });

  factory SedeData.fromMap(String id, Map<String, dynamic> map) {
    return SedeData(
      id: id,
      nombre: (map['nombre'] ?? '').toString(),
      direccion: (map['direccion'] ?? '').toString(),
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

  /// ✅ Clasificación principal: SIEMPRE usar esto en las pantallas
  final List<String> tipos;

  /// ✅ Multi-sedes (desde Firestore como MAP)
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
    this.tipos = const [],
    this.sedes = const [],
  });

  bool get hasSitioWeb => sitioWeb.trim().isNotEmpty;

  /// ✅ Constructor seguro para citas (NO exige bio, web, orden, tipos, sedes)
  factory LugarData.embedded({
    required String id,
    required String nombre,
    required String direccion,
    required List<String> fotos,
    required String fotoPortada,
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
      tipos: const [],
      sedes: const [],
    );
  }

  // 🔴 CHINCHE LUGAR 1 — normalización única de strings para "tipos"
  static String _normTipo(dynamic v) => v.toString().trim().toLowerCase();

  factory LugarData.fromMap({
    required String id,
    required Map<String, dynamic> data,
  }) {
    // ✅ fotos
    final fotosRaw = data['fotos'];
    final fotos = (fotosRaw is List)
        ? fotosRaw.map((e) => e.toString()).toList()
        : <String>[];

    // ✅ tipos (array) + fallback legacy "tipo"
    final tiposRaw = data['tipos'];
    List<String> tipos = (tiposRaw is List)
        ? tiposRaw.map(_normTipo).where((s) => s.isNotEmpty).toList()
        : <String>[];

    final tipoLegacy = _normTipo(data['tipo'] ?? '');
    if (tipos.isEmpty && tipoLegacy.isNotEmpty) {
      tipos = [tipoLegacy];
    }

    // ✅ sedes: Firestore puede venir como MAP { sede_1: {..}, sede_2: {..} }
    // y en algunos docs viejos puede estar como [] (array vacío). Toleramos ambos.
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

    // ✅ orden: tolerar num por seguridad
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
    );
  }
}
