// 📂 lib/screens/perfil_usuariox_screen.dart
// -----------------------------------------------------------
// PERFIL PÚBLICO DEL USUARIO (SMART CACHE PRO + SISTEMA DE REPORTES)
// 🔥 REPORTES PRO: Botón ghost inyectado al final del perfil.
// 🔥 UI MATCHY: Burbuja flotante de reporte con fricción inteligente.
// 🔥 FIX CRÍTICO CORREO: Estructura 'message' ajustada para Trigger Email Extension.
// 🔥 LIE DETECTOR: Captura nombre y correo real vs. lo que escribe el usuario.
// 💎 NUEVO: Inyección del Check Azul y Tarjeta de Biometría (Seguridad Anti-Fakes).
// 🔧 FIX ZOOM: Se quitó el gesto "arrastrar hacia abajo para cerrar" del visor de fotos.
//    Competía con el pellizco de InteractiveViewer y con el deslizamiento de PageView
//    en la misma arena de gestos, causando que el zoom fallara al azar, se trabara y
//    se viera recortado. Ahora se cierra solo con el botón X, igual que en
//    lugar_plantilla_screen.dart (que ya funciona perfecto).
// -----------------------------------------------------------

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:proyectos_matchy/widgets/foto_perfil_usuario.dart';
import 'package:proyectos_matchy/widgets/termometro_confiabilidad.dart';

class PerfilUsuarioXScreen extends StatefulWidget {
  final String uid;

  const PerfilUsuarioXScreen({super.key, required this.uid});

  @override
  State<PerfilUsuarioXScreen> createState() => _PerfilUsuarioXScreenState();
}

class _PerfilUsuarioXScreenState extends State<PerfilUsuarioXScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  // 🛡️ ZONA DE CHINCHES MAESTROS (DISEÑO PREMIUM)
  static const String kUsersCollection = 'users';
  static const double altoFotoPrincipal = 450;

  static const List<Shadow> kTextShadow = [
    Shadow(color: Colors.black, blurRadius: 10, offset: Offset(0, 4))
  ];
  static const List<BoxShadow> kChipShadow = [
    BoxShadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 3))
  ];

  static const int maxShortLength = 14;
  static const double gapX = 10;
  static const double chipPadV = 10;
  static const double chipPadH = 10;
  static const double chipFont = 13;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection(kUsersCollection)
          .doc(widget.uid)
          .get();

      if (!snap.exists) {
        if (mounted) setState(() { _data = null; _loading = false; });
        return;
      }

      if (mounted) setState(() { _data = snap.data(); _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _data = null; _loading = false; });
    }
  }

  // 🔥 SISTEMA DE NOTIFICACIONES MATCHY STYLE
  void _mostrarBurbuja(String mensaje, Color color, IconData icono) {
    if (!mounted) return;
    final overlayState = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => SafeArea(
        child: Align(
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
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
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Poppins'),
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

  // 🔥 LANZADOR DEL REPORTE
  void _mostrarDialogoReporte(String reportadoNombre, String reportadoUid) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ReportDialog(
        reportadoNombre: reportadoNombre,
        reportadoUid: reportadoUid,
        onSuccess: () {
          _mostrarBurbuja("Reporte enviado. Nuestro equipo lo revisará pronto.", const Color(0xFF00E676), Icons.check_circle_outline_rounded);
        },
        onError: (e) {
          _mostrarBurbuja("Error al enviar reporte: $e", const Color(0xFFFF5252), Icons.error_outline_rounded);
        },
      ),
    );
  }

  // -------------------------------------------------------------
  // Helpers UI
  // -------------------------------------------------------------

  Widget _fallback() {
    return Container(
      color: const Color(0x33FFFFFF),
      child: const Center(
        child: Icon(Icons.person, color: Colors.white70, size: 70),
      ),
    );
  }

  Widget _buildImage(String? raw) {
    if (raw == null || raw.trim().isEmpty) return _fallback();
    final v = raw.trim();
    if (v.startsWith('http')) {
      return CachedNetworkImage(
        key: ValueKey(v),
        imageUrl: v,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        memCacheHeight: 1200,
        placeholder: (context, url) => Container(color: Colors.black26, child: const Center(child: CircularProgressIndicator(color: Color(0xFFBEB3FF), strokeWidth: 2))),
        errorWidget: (_, __, ___) => _fallback(),
      );
    }
    if (v.startsWith('assets/')) {
      return Image.asset(v, fit: BoxFit.cover, alignment: Alignment.topCenter, errorBuilder: (_, __, ___) => _fallback());
    }
    return Image.file(File(v), fit: BoxFit.cover, alignment: Alignment.topCenter, errorBuilder: (_, __, ___) => _fallback());
  }

  Widget _cardTexto(String titulo, String texto) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x33FFFFFF),
        borderRadius: BorderRadius.circular(20),
        boxShadow: kChipShadow,
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              titulo,
              style: const TextStyle(
                color: Color(0xFFB3D9FF),
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
                shadows: kTextShadow,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            texto,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Poppins'),
          ),
        ],
      ),
    );
  }

  List<List<String>> _buildRows(List<String> all) {
    final cleaned = all.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    final rows = <List<String>>[];
    int i = 0;
    while (i < cleaned.length) {
      final cur = cleaned[i];
      if (cur.length > maxShortLength) { rows.add([cur]); i += 1; continue; }
      if (i + 1 < cleaned.length && cleaned[i + 1].length <= maxShortLength) {
        rows.add([cur, cleaned[i + 1]]); i += 2;
      } else { rows.add([cur]); i += 1; }
    }
    return rows;
  }

  Widget _chip(String txt) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: chipPadV, horizontal: chipPadH),
      decoration: BoxDecoration(
        color: const Color(0x66FFFFFF),
        borderRadius: BorderRadius.circular(50),
        boxShadow: kChipShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              txt,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: chipFont, fontFamily: 'Poppins', fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardChips(String titulo, List<String> items) {
    if (items.isEmpty) return const SizedBox();
    final rows = _buildRows(items);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x33FFFFFF),
        borderRadius: BorderRadius.circular(20),
        boxShadow: kChipShadow,
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              titulo,
              style: const TextStyle(
                color: Color(0xFFB3D9FF),
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
                shadows: kTextShadow,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Column(
            children: rows.map((fila) {
              if (fila.length == 1) return Row(children: [Expanded(child: _chip(fila[0]))]);
              return Row(
                children: [
                  Expanded(child: _chip(fila[0])),
                  const SizedBox(width: gapX),
                  Expanded(child: _chip(fila[1])),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(color: Colors.white)));

    if (_data == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(child: Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover)),
            const Center(child: Text('No pude cargar el perfil', style: TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'Poppins'))),
            Positioned(
              top: 50, left: 20,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 45, height: 45,
                  decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle, border: Border.all(color: Colors.white24)),
                  child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                ),
              ),
            )
          ],
        ),
      );
    }

    final nombre = (_data!['nombre'] ?? '').toString().trim();
    final edad = (_data!['edad'] ?? '').toString().trim();
    final profesion = (_data!['profesion'] ?? '').toString().trim();
    final ciudad = (_data!['ciudad'] ?? '').toString().trim();
    final pais = (_data!['pais'] ?? '').toString().trim();
    final bio = (_data!['biografia'] ?? '').toString().trim();
    final detalle = (_data!['detalle'] ?? '').toString().trim();

    // 🔥 EXTRACCIÓN DEL CHECK AZUL
    final isVerified = _data!['isVerified'] == true;

    final sobreMi = (_data!['sobreMiSeleccion'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
    final busco = (_data!['buscoSeleccion'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
    final intereses = (_data!['interesesSeleccion'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
    final galeriaRaw = (_data!['photoUrls'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();

    // 🔍 NUEVO: abre el visor de fotos a pantalla completa con zoom, deslizando desde el índice tocado
    void abrirZoom(int index) {
      if (galeriaRaw.isEmpty) return;
      Navigator.of(context).push(
        PageRouteBuilder(
          opaque: false,
          barrierColor: Colors.black,
          transitionDuration: const Duration(milliseconds: 220),
          reverseTransitionDuration: const Duration(milliseconds: 180),
          pageBuilder: (_, animation, __) => FadeTransition(
            opacity: animation,
            child: _GaleriaZoomFullScreen(fotos: galeriaRaw, initialIndex: index),
          ),
        ),
      );
    }

    final puntaje = (_data!['confiabilidad'] as num?)?.toInt() ?? 100;
    final userStatus = (_data!['userStatus'] ?? 'active').toString();
    final strikes = (_data!['strikes'] as num?)?.toInt() ?? 0;
    final bloqueadoTimestamp = _data!['bloqueadoHasta'] as Timestamp?;

    bool estaBloqueado = false;
    DateTime? fechaTermometro;
    if (userStatus == 'blocked' || (bloqueadoTimestamp != null && bloqueadoTimestamp.toDate().isAfter(DateTime.now()))) estaBloqueado = true;
    if (estaBloqueado) {
      fechaTermometro = bloqueadoTimestamp?.toDate() ?? DateTime.now().add(Duration(days: strikes * 5 > 0 ? strikes * 5 : 1));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover)),
          Column(
            children: [
              const SizedBox(height: 45),
              SizedBox(height: 45, child: Image.asset('assets/images/logomatchyplano.png')),
              const SizedBox(height: 14),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        height: altoFotoPrincipal,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.45), blurRadius: 10, offset: const Offset(0, 6))],
                        ),
                        clipBehavior: Clip.antiAlias,
                        // 🔍 NUEVO: se envuelve la tarjeta completa (imagen + overlay) en un GestureDetector
                        // para abrir el zoom. Debe ser la tarjeta ENTERA y no solo la imagen, porque el
                        // degradado (Container con decoración) que está encima en el Stack "atrapa" el toque
                        // antes de que le llegue a un detector puesto solo en la imagen de más abajo.
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: galeriaRaw.isNotEmpty ? () => abrirZoom(0) : null,
                          child: Stack(
                            children: [
                              Positioned.fill(child: FotoPerfilUsuario(uid: widget.uid, fit: BoxFit.cover, alignment: Alignment.topCenter)),
                              Positioned(
                                left: 0, right: 0, bottom: 0,
                                child: Container(
                                  height: 180,
                                  decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.95)])),
                                ),
                              ),
                              Positioned(
                                left: 30, bottom: 30, right: 30,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 🔥 INYECCIÓN: Etiqueta "PERFIL VERIFICADO" blindada con FittedBox
                                    if (isVerified)
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                          margin: const EdgeInsets.only(bottom: 6),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF00B4DB).withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(color: const Color(0xFF00B4DB), width: 1),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: const [
                                              Icon(Icons.verified, color: Color(0xFF00B4DB), size: 14),
                                              SizedBox(width: 4),
                                              Flexible(
                                                child: Text(
                                                  "PERFIL VERIFICADO",
                                                  style: TextStyle(
                                                      color: Color(0xFF00B4DB),
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                      letterSpacing: 0.6,
                                                      fontFamily: 'Poppins'
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Row(
                                        children: [
                                          Text(nombre, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'Poppins', shadows: kTextShadow)),
                                          if (edad.isNotEmpty) Text(', $edad', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'Poppins', shadows: kTextShadow)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(profesion.isEmpty ? '—' : profesion, style: const TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Poppins', shadows: kTextShadow)),
                                    ),
                                    const SizedBox(height: 2),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        ciudad.isEmpty && pais.isEmpty ? 'Sin ubicación' : (ciudad.isNotEmpty && pais.isNotEmpty ? '$ciudad - $pais' : (ciudad.isNotEmpty ? ciudad : pais)),
                                        style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Poppins', shadows: kTextShadow),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      TermometroConfiabilidad(puntaje: puntaje, fechaDesbloqueo: fechaTermometro, mostrarReloj: false),
                      const SizedBox(height: 6),

                      // 🔥 INYECCIÓN: Tarjeta de Biometría Anti-Falsificación
                      if (isVerified)
                        const _CardVerificacionBiometrica(),

                      _cardTexto('Biografía', bio.isEmpty ? '—' : bio),
                      if (sobreMi.isNotEmpty) _cardChips('Sobre mí', sobreMi),
                      if (galeriaRaw.length >= 2) Container(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), height: 400, clipBehavior: Clip.antiAlias, decoration: BoxDecoration(borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))]), child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => abrirZoom(1), child: _buildImage(galeriaRaw[1]))),
                      if (busco.isNotEmpty) _cardChips('Busco...', busco),
                      if (galeriaRaw.length >= 3) Container(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), height: 400, clipBehavior: Clip.antiAlias, decoration: BoxDecoration(borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))]), child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => abrirZoom(2), child: _buildImage(galeriaRaw[2]))),
                      if (intereses.isNotEmpty) _cardChips('Intereses y Hobbies', intereses),
                      if (galeriaRaw.length >= 4) Container(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), height: 400, clipBehavior: Clip.antiAlias, decoration: BoxDecoration(borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))]), child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => abrirZoom(3), child: _buildImage(galeriaRaw[3]))),
                      _cardTexto('Un detalle que me enamora', detalle.isEmpty ? '—' : detalle),
                      if (galeriaRaw.length >= 5) Container(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), height: 400, clipBehavior: Clip.antiAlias, decoration: BoxDecoration(borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))]), child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => abrirZoom(4), child: _buildImage(galeriaRaw[4]))),

                      const SizedBox(height: 30),

                      // 🔥 BOTÓN GHOST DE REPORTE (Elegante y Sutil)
                      Center(
                        child: TextButton.icon(
                          onPressed: () => _mostrarDialogoReporte(nombre, widget.uid),
                          icon: const Icon(Icons.flag_rounded, color: Colors.white54, size: 18),
                          label: const Text(
                              "¿Algo no está bien? Reportar perfil",
                              style: TextStyle(color: Colors.white54, fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.bold)
                          ),
                          style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: const BorderSide(color: Colors.white12, width: 1)
                              ),
                              backgroundColor: Colors.white.withOpacity(0.05)
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 0, left: 0, right: 0, height: 80,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.95)])),
              ),
            ),
          ),
          Positioned(
            top: 50, left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
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

// ============================================================================
// 🔥 WIDGET EXTRA: TARJETA DE VERIFICACIÓN BIOMÉTRICA (ANTI-FAKE)
// ============================================================================
class _CardVerificacionBiometrica extends StatelessWidget {
  const _CardVerificacionBiometrica({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x33FFFFFF), // Mismo fondo gris translúcido
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 3))],
        border: Border.all(color: const Color(0xFF00B4DB).withOpacity(0.5), width: 1.5), // Borde neón sutil
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF00B4DB).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified, color: Color(0xFF00B4DB), size: 28),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Text(
              "Este perfil fue verificado con biometría facial ✔️",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                  fontFamily: 'Poppins'
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 🔍 NUEVO: visor de fotos a pantalla completa con zoom (pellizcar) y deslizamiento entre fotos
// 🔧 FIX ZOOM: sin gesto de "arrastrar para cerrar" — cierra solo con el botón X.
// Esto evita que un GestureDetector de arrastre vertical compita en la arena de gestos
// con el PageView (deslizar entre fotos) y el InteractiveViewer (pellizcar/zoom), que era
// la causa real de que el zoom fallara al azar, se trabara y se viera recortado.
// ============================================================================
class _GaleriaZoomFullScreen extends StatefulWidget {
  final List<String> fotos;
  final int initialIndex;
  const _GaleriaZoomFullScreen({required this.fotos, required this.initialIndex});

  @override
  State<_GaleriaZoomFullScreen> createState() => _GaleriaZoomFullScreenState();
}

class _GaleriaZoomFullScreenState extends State<_GaleriaZoomFullScreen> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.fotos.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _fallback() {
    return Container(
      color: const Color(0x33FFFFFF),
      child: const Center(child: Icon(Icons.person, color: Colors.white70, size: 70)),
    );
  }

  Widget _buildFoto(String raw) {
    final r = raw.trim();
    if (r.isEmpty) return _fallback();
    if (r.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: r,
        fit: BoxFit.contain,
        placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Color(0xFFBEB3FF))),
        errorWidget: (_, __, ___) => _fallback(),
      );
    } else if (r.startsWith('assets/')) {
      return Image.asset(r, fit: BoxFit.contain, errorBuilder: (_, __, ___) => _fallback());
    } else {
      return Image.file(File(r), fit: BoxFit.contain, errorBuilder: (_, __, ___) => _fallback());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.fotos.length,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              itemBuilder: (context, i) {
                return InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: Center(child: _buildFoto(widget.fotos[i])),
                );
              },
            ),
            Positioned(
              top: 10,
              right: 10,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                  child: const Icon(Icons.close, color: Colors.white, size: 26),
                ),
              ),
            ),
            if (widget.fotos.length > 1)
              Positioned(
                top: 16,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.fotos.length,
                        (i) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == _currentIndex ? Colors.white : Colors.white30,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 🛡️ BURBUJA DE REPORTE (MATCHY STYLE) CON DETECTOR DE MENTIRAS
// ============================================================================
class _ReportDialog extends StatefulWidget {
  final String reportadoNombre;
  final String reportadoUid;
  final VoidCallback onSuccess;
  final Function(String) onError;

  const _ReportDialog({
    required this.reportadoNombre,
    required this.reportadoUid,
    required this.onSuccess,
    required this.onError,
  });

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _detailsCtrl = TextEditingController();

  String? _selectedCategory;
  bool _sending = false;

  final List<String> _categorias = [
    'Fotos falsas o robadas (Catfish).',
    'Comportamiento inapropiado o acoso.',
    'Parece ser menor de edad.',
    'Desnudos o imágenes de violencia y odio.',
    'Spam, publicidad o estafa.',
    'Otro.'
  ];

  // Filtro de Fricción
  bool get _isFormValid {
    return _nameCtrl.text.trim().isNotEmpty &&
        _emailCtrl.text.trim().isNotEmpty &&
        _selectedCategory != null &&
        _detailsCtrl.text.trim().length >= 30;
  }

  Future<void> _enviarReporte() async {
    if (!_isFormValid || _sending) return;

    setState(() => _sending = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final reporterUid = currentUser?.uid ?? 'Desconocido';
      final reporterEmailAuth = currentUser?.email ?? 'Sin correo registrado';

      // 🔥 EXTRACCIÓN DE LA VERDAD: Buscar el nombre real del denunciante en la BD
      String reporterNombreReal = 'Desconocido';
      try {
        final docUser = await FirebaseFirestore.instance.collection('users').doc(reporterUid).get();
        if (docUser.exists) {
          reporterNombreReal = docUser.data()?['nombre'] ?? 'Sin nombre';
        }
      } catch (_) {}

      final textoEstructurado = """
🚨 REPORTE DE PERFIL (Matchy Security)
Denunciado: ${widget.reportadoNombre}
UID Denunciado: ${widget.reportadoUid}

--- FIRMADO POR EL USUARIO (FORMULARIO) ---
Nombre dado: ${_nameCtrl.text.trim()}
Correo dado: ${_emailCtrl.text.trim()}

--- DATOS REALES DEL SISTEMA (LIE DETECTOR) ---
Nombre real en App: $reporterNombreReal
Correo real de Ingreso: $reporterEmailAuth
UID Denunciante: $reporterUid

--- EVIDENCIA ---
Motivo: $_selectedCategory
Detalles:
${_detailsCtrl.text.trim()}
""";

      // 🔥 FIX CRÍTICO: Usar el formato exacto 'message' que exige la extensión de Google
      await FirebaseFirestore.instance.collection('buzon_soporte').add({
        'uid': reporterUid,
        'email_usuario': _emailCtrl.text.trim(),
        'estado': 'pendiente',
        'to': 'matchyoficial@gmail.com',
        'message': { // <- Esto es lo que activa al robot del correo
          'subject': '🚨 ALERTA MATCHY: Reporte contra ${widget.reportadoNombre}',
          'text': textoEstructurado,
        }
      });

      if (mounted) {
        Navigator.pop(context); // Cierra el diálogo
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        widget.onError(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white24, width: 1),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, 10))],
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🛡️ CABECERA
              const Icon(Icons.shield_outlined, color: Color(0xFFFF5252), size: 40),
              const SizedBox(height: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  "REPORTAR A ${widget.reportadoNombre.toUpperCase()}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, fontFamily: 'Poppins'),
                ),
              ),
              const SizedBox(height: 20),

              // 📝 BLOQUE DE IDENTIDAD (El candado)
              _buildTextField(_nameCtrl, "Tu Nombre (Obligatorio)", Icons.person_outline),
              const SizedBox(height: 12),
              _buildTextField(_emailCtrl, "Tu Correo (Obligatorio)", Icons.email_outlined, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 20),

              // 🏷️ BLOQUE DE MOTIVO
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    dropdownColor: const Color(0xFF2A2A2A),
                    hint: const Text("Selecciona el motivo...", style: TextStyle(color: Colors.white54, fontSize: 14)),
                    value: _selectedCategory,
                    icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
                    items: _categorias.map((String cat) {
                      return DropdownMenuItem<String>(
                        value: cat,
                        child: Text(cat, style: const TextStyle(color: Colors.white, fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedCategory = val),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ✍️ BLOQUE DE EVIDENCIA (Mínimo 30 letras)
              TextField(
                controller: _detailsCtrl,
                maxLines: 4,
                maxLength: 500,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Cuéntanos qué pasó (Mínimo 30 letras)...",
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.all(15),
                  counterText: '${_detailsCtrl.text.trim().length} / 500',
                  counterStyle: TextStyle(
                    color: _detailsCtrl.text.trim().length >= 30 ? const Color(0xFF00E676) : const Color(0xFFFF5252),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // ⚠️ CANDADO PSICOLÓGICO FINAL
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5252).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFF5252).withOpacity(0.3)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("⚠️ ", style: TextStyle(fontSize: 16)),
                    Expanded(
                      child: Text(
                        "Aviso de Seguridad: Un moderador humano revisará este caso detalladamente. Usar esta herramienta para dañar a otros por motivos personales, o falsas acusaciones, es una violación de nuestras reglas y causará la suspensión de tu propio perfil.",
                        style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // 🔘 BOTONES DE ACCIÓN
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _sending ? null : () => Navigator.pop(context),
                      child: const Text("CANCELAR", style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: _isFormValid && !_sending ? _enviarReporte : null,
                      child: Container(
                        height: 45,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: _isFormValid
                              ? const LinearGradient(colors: [Color(0xFFFF5252), Color(0xFFD50000)])
                              : LinearGradient(colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)]),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: _sending
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(
                            "ENVIAR",
                            style: TextStyle(
                                color: _isFormValid ? Colors.white : Colors.white38,
                                fontWeight: FontWeight.bold
                            )
                        ),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, IconData icon, {TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white54, size: 20),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      ),
    );
  }
}