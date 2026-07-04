// 📂 lib/screens/cita_detalle_screen.dart
// ✅ DETALLE DE CITA CONFIRMADA (status: matched) — TARJETA DE CÓDIGO Y GPS
// 🔥 Recibe todos sus datos de visualización por constructor (lugar, Matchy, fecha/hora,
//    intención/preferencia, ambos códigos, isOwner) — no necesita StreamBuilder para pintar
//    la pantalla, solo escribe a Firestore cuando se confirma el código.
// 🆕 GPS DINÁMICO: radio efectivo = 35m base + el margen de error (accuracy) que el GPS reporta
//    en el momento, con techo absoluto de 100m. Se toman hasta 3 lecturas en ~2 segundos y se
//    usa la más precisa. El lat/lng del lugar se obtiene con una consulta puntual a
//    citas/{citaId} al momento de confirmar (no venía en el constructor).
// 🐛 FIX: la fecha ahora se muestra en palabras ("Viernes 3 de Jul") usando citaDateTime +
//    _fechaAmigable — mismo patrón exacto que ya usa citas_screen.dart en sus tarjetas — en vez
//    del string crudo widget.fecha ("3/7/2026") que se me había colado por error. Envuelta en
//    FittedBox para que se vea de tamaño mediano y nunca se corte, sin importar el día/mes.
//    Todo lo demás del archivo queda exactamente igual a la versión anterior.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geolocator/geolocator.dart';

import 'package:proyectos_matchy/screens/perfil_usuariox_screen.dart';

class CitaDetalleScreen extends StatefulWidget {
  final String citaId;
  final String lugarId;
  final String lugarNombre;
  final String lugarDireccion;
  final String lugarFotoPortada;
  final String matchyNombre;
  final String matchyFoto;
  final String matchyUid;
  final int matchyEdad;
  final String fecha;
  final String hora;
  final String intencion;
  final String preferencia;
  final String miCodigoCita;
  final String codigoDelOtro;
  final bool isOwner;
  final DateTime citaDateTime;

  const CitaDetalleScreen({
    super.key,
    required this.citaId,
    required this.lugarId,
    required this.lugarNombre,
    required this.lugarDireccion,
    required this.lugarFotoPortada,
    required this.matchyNombre,
    required this.matchyFoto,
    required this.matchyUid,
    required this.matchyEdad,
    required this.fecha,
    required this.hora,
    required this.intencion,
    required this.preferencia,
    required this.miCodigoCita,
    required this.codigoDelOtro,
    required this.isOwner,
    required this.citaDateTime,
  });

  @override
  State<CitaDetalleScreen> createState() => _CitaDetalleScreenState();
}

class _CitaDetalleScreenState extends State<CitaDetalleScreen> {
  // 🆕 GPS DINÁMICO
  static const double kRadioGPSBase = 35.0;    // se queda igual, sin tocar
  static const double kRadioGPSTecho = 100.0;  // techo absoluto, nunca se supera

  final TextEditingController _codigoCtrl = TextEditingController();
  bool _confirmando = false;

  @override
  void dispose() {
    _codigoCtrl.dispose();
    super.dispose();
  }

  // 🐛 FIX: mismo formateador exacto que usa _CitaCard en citas_screen.dart, para que la fecha
  // se vea en palabras y consistente en toda la app.
  String _fechaAmigable(DateTime d) {
    const List<String> dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    const List<String> meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return "${dias[d.weekday - 1]} ${d.day} de ${meses[d.month - 1]}";
  }

  // ===========================================================================
  // 🔔 BURBUJA FLOTANTE (mismo patrón usado en todo el proyecto)
  // ===========================================================================
  void _mostrarBurbuja(String mensaje, Color color, IconData icono) {
    if (!mounted) return;
    final overlayState = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 20, left: 25, right: 25),
            child: Material(
              color: Colors.transparent,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 500),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E2C).withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.7), width: 2),
                    boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 5))],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
                        child: Icon(icono, color: color, size: 28),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                          child: Text(
                            mensaje,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Poppins'),
                          )
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlayState.insert(entry);
    Future.delayed(const Duration(seconds: 4), () {
      if (entry.mounted) entry.remove();
    });
  }

  // ===========================================================================
  // 🆕 GPS DINÁMICO: mejor lectura de hasta 3 intentos + radio efectivo con techo
  // ===========================================================================
  Future<Position?> _obtenerMejorUbicacion({int intentos = 3}) async {
    Position? mejor;
    for (int i = 0; i < intentos; i++) {
      try {
        final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        if (mejor == null || pos.accuracy < mejor.accuracy) {
          mejor = pos;
        }
      } catch (_) {
        // seguimos intentando con la siguiente lectura
      }
      if (i < intentos - 1) await Future.delayed(const Duration(milliseconds: 700));
    }
    return mejor;
  }

  double _radioEfectivo(double accuracy) {
    return (kRadioGPSBase + accuracy).clamp(kRadioGPSBase, kRadioGPSTecho);
  }

  // ===========================================================================
  // ✍️ CONFIRMAR CITA (código + GPS dinámico)
  // ===========================================================================
  Future<void> _confirmarCita() async {
    if (_confirmando) return;
    final ingresado = _codigoCtrl.text.trim().toUpperCase();

    if (ingresado.isEmpty) {
      _mostrarBurbuja("Escribe el código que te dio tu Matchy.", Colors.orangeAccent, Icons.info_outline_rounded);
      return;
    }

    setState(() => _confirmando = true);

    try {
      if (ingresado != widget.codigoDelOtro.toUpperCase()) {
        _mostrarBurbuja("Código incorrecto. Revísalo con tu Matchy.", const Color(0xFFFF5252), Icons.error_outline_rounded);
        return;
      }

      // Obtenemos lat/lng directo de la cita (no venía en el constructor)
      double lat = 0.0, lng = 0.0;
      try {
        final citaSnap = await FirebaseFirestore.instance.collection('citas').doc(widget.citaId).get();
        final cdata = citaSnap.data() ?? {};
        lat = (cdata['latitude'] as num?)?.toDouble() ?? 0.0;
        lng = (cdata['longitude'] as num?)?.toDouble() ?? 0.0;
      } catch (_) {}

      final pos = await _obtenerMejorUbicacion();
      if (pos == null) {
        _mostrarBurbuja("No pudimos obtener tu ubicación. Activa el GPS e inténtalo de nuevo.", const Color(0xFFFF5252), Icons.location_off_rounded);
        return;
      }

      final distancia = Geolocator.distanceBetween(pos.latitude, pos.longitude, lat, lng);
      final radioEfectivo = _radioEfectivo(pos.accuracy);
      if (distancia > radioEfectivo) {
        _mostrarBurbuja(
          "Estás a ${distancia.round()}m del lugar. Tu GPS tiene un margen de ±${pos.accuracy.round()}m ahora mismo — si estás en el lugar, intenta de nuevo en unos segundos o acércate a una ventana.",
          const Color(0xFFFF5252),
          Icons.social_distance_rounded,
        );
        return;
      }

      final campo = widget.isOwner ? 'gpsCheckOwner' : 'gpsCheckMatchy';
      await FirebaseFirestore.instance.collection('citas').doc(widget.citaId).update({campo: true});

      if (!mounted) return;
      _mostrarBurbuja("¡Cita confirmada! Disfruta tu encuentro.", const Color(0xFF00E676), Icons.check_circle_rounded);
      _codigoCtrl.clear();
    } catch (e) {
      _mostrarBurbuja("Error al confirmar: $e", const Color(0xFFFF5252), Icons.error_outline_rounded);
    } finally {
      if (mounted) setState(() => _confirmando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover)),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 70, 20, 60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 🖼️ FOTO DEL LUGAR
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 5))],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        widget.lugarFotoPortada.trim().startsWith('http')
                            ? CachedNetworkImage(
                          imageUrl: widget.lugarFotoPortada,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: Colors.black26),
                          errorWidget: (_, __, ___) => Container(color: Colors.grey[900], child: const Icon(Icons.broken_image, color: Colors.white24)),
                        )
                            : Container(color: Colors.grey[900], child: const Icon(Icons.image_not_supported, color: Colors.white24)),
                        Container(
                          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.9)])),
                        ),
                        Positioned(
                          left: 18, right: 18, bottom: 14,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.lugarNombre.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, fontFamily: 'Poppins')),
                              Text(widget.lugarDireccion, style: const TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'Poppins')),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 👤 TARJETA DEL MATCHY
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PerfilUsuarioXScreen(uid: widget.matchyUid))),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: const Color(0x20FFFFFF), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white12)),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: SizedBox(
                              width: 60, height: 60,
                              child: widget.matchyFoto.trim().startsWith('http')
                                  ? CachedNetworkImage(imageUrl: widget.matchyFoto, fit: BoxFit.cover, errorWidget: (_, __, ___) => Container(color: Colors.grey[900]))
                                  : Container(color: Colors.grey[900], child: const Icon(Icons.person, color: Colors.white24)),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text("${widget.matchyNombre}, ${widget.matchyEdad}", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'Poppins')),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: Colors.white38),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 📅 FECHA / HORA / INTENCIÓN / PREFERENCIA
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white12)),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // 🐛 FIX: fecha en palabras (no el string crudo "3/7/2026"), tamaño
                            // mediano vía FittedBox para que nunca se corte ni se vea gigante.
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  _fechaAmigable(widget.citaDateTime),
                                  style: const TextStyle(color: Color(0xFFFFC107), fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'Poppins'),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(widget.hora, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17, fontFamily: 'Poppins')),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(height: 1, color: Colors.white12),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Intención: ${widget.intencion}", style: const TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'Poppins')),
                            Text("Preferencia: ${widget.preferencia}", style: const TextStyle(color: Color(0xFFE0D4FF), fontSize: 13, fontFamily: 'Poppins')),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 🎯 BLOQUE DE CÓDIGO / CONFIRMAR CITA / SEGURIDAD (diseño intacto)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0x20FFFFFF),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text("TU CÓDIGO", style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Poppins', letterSpacing: 1.0)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFBEB3FF))),
                          alignment: Alignment.center,
                          child: Text(
                            widget.miCodigoCita.isEmpty ? '········' : widget.miCodigoCita,
                            style: const TextStyle(color: Color(0xFFBEB3FF), fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 6, fontFamily: 'Poppins'),
                          ),
                        ),

                        const SizedBox(height: 20),

                        const Text("CONFIRMAR CITA", style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Poppins', letterSpacing: 1.0)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _codigoCtrl,
                          textCapitalization: TextCapitalization.characters,
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 3, fontFamily: 'Poppins'),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            hintText: "CÓDIGO DE ${widget.matchyNombre}",
                            hintStyle: const TextStyle(color: Colors.white38, fontSize: 13, letterSpacing: 1, fontFamily: 'Poppins'),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.08),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                        const SizedBox(height: 14),
                        GestureDetector(
                          onTap: _confirmando ? null : _confirmarCita,
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF00E676), Color(0xFF00B84D)]),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.center,
                            child: _confirmando
                                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                                : const Text("CONFIRMAR CITA", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 15, fontFamily: 'Poppins')),
                          ),
                        ),

                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(12)),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.shield_outlined, color: Colors.white54, size: 18),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Por tu seguridad, nunca compartas tu código por chat. Entrégalo solo en persona.",
                                  style: TextStyle(color: Colors.white54, fontSize: 12, fontFamily: 'Poppins', height: 1.3),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            top: 50, left: 16,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 42, height: 42,
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), shape: BoxShape.circle, border: Border.all(color: Colors.white24, width: 1)),
                child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}