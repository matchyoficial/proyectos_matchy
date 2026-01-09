// 📂 lib/models/lugar_data.dart
// ✅ Modelo único para Restaurantes / Bares / Cafés / Actividades
// ✅ Construye dirección COMPLETA para Google Maps de forma segura

class LugarData {
  // ===========================================================
  // 🔹 DATOS BASE
  // ===========================================================
  final String id;               // 🔴 CHINCHE LUGAR ID — ej: "faro"
  final String nombre;           // 🔴 CHINCHE LUGAR NOMBRE
  final String direccion;        // 🔴 CHINCHE LUGAR DIR (puede ser corta)
  final String bio;              // 🔴 CHINCHE LUGAR BIO

  // 🔴 CHINCHE LUGAR FOTOS — assets o urls (UI limita a 8)
  final List<String> fotos;

  // 🔴 CHINCHE LUGAR PDF — nombre ("faro_pdf.pdf") o url completa
  final String menuPdf;

  // 🔴 CHINCHE LUGAR MAPS OVERRIDE
  // Si viene lleno, IGNORA dirección + ciudad + país
  final String mapsQuery;

  // ===========================================================
  // 🔹 GEO DEFAULTS (EDITABLES A FUTURO)
  // ===========================================================
  static const String defaultCity = 'Cali';               // 🔴 CHINCHE LUGAR GEO 1
  static const String defaultRegion = 'Valle del Cauca';  // 🔴 CHINCHE LUGAR GEO 2
  static const String defaultCountry = 'Colombia';        // 🔴 CHINCHE LUGAR GEO 3

  const LugarData({
    required this.id,
    required this.nombre,
    required this.direccion,
    required this.bio,
    required this.fotos,
    required this.menuPdf,
    this.mapsQuery = '',
  });

  // ===========================================================
  // ✅ MAPS FINAL — fuente ÚNICA de verdad para Google Maps
  // Prioridad:
  // 1) mapsQuery (si viene)
  // 2) dirección completa (si ya tiene comas)
  // 3) dirección + ciudad + región + país
  // ===========================================================
  String get mapsQueryFinal {
    final mq = mapsQuery.trim();
    if (mq.isNotEmpty) return mq;

    final dir = direccion.trim();
    if (dir.isEmpty) return '';

    // Si ya parece completa, no la tocamos
    if (dir.contains(',')) return dir;

    // Completamos automáticamente
    return '$dir, $defaultCity, $defaultRegion, $defaultCountry';
  }

  // ===========================================================
  // 🔹 UTILS (opcional, pero útil)
  // ===========================================================
  bool get hasFotos => fotos.isNotEmpty;

  bool get hasMenuPdf => menuPdf.trim().isNotEmpty;
}
