// 📂 lib/screens/intereses_invitacion_screen.dart
// ✅ PANTALLA DESTINO PARA QUIEN RECIBE LA INVITACIÓN DE COMUNIDAD
// 🎯 Diseño basado en nueva_cita_solicitud_screen.dart (misma tarjeta, tipografías, capsula de foto).
// 🔥 Escucha en tiempo real el documento de la invitación (StreamBuilder), así que al elegir un
//    sitio la pantalla se actualiza sola sin recargar.
// 💛 Botón "ESCOGER" dorado pulsante (misma técnica de animación que _BotonDescuentosAnimado).
// 👤 Foto de perfil del invitador es clickeable -> PerfilUsuarioXScreen (no requiere modificar esa
//    pantalla: su botón de regreso ya usa Navigator.pop, que regresa aquí automáticamente).
// 🖼️ Las 3 fotos de sitios son clickeables -> LugarPlantillaSinBotonScreen (sin modificar, se
//    autoalimenta de datos completos por id/nombre).
// ✍️ Al escoger, se actualiza Firestore YA (no placeholder): status, sitioElegidoId, respondedAt.
// 🔔 NUEVO: al escoger, se notifica al invitador Y se navega de inmediato a Citas
//    (vía HomeShell.go(index: 1), mismo patrón que panel_screen.dart usa para "ir a Mis Citas",
//    así conserva la barra de navegación inferior).

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:proyectos_matchy/models/lugar_data.dart';
import 'package:proyectos_matchy/widgets/foto_perfil_usuario.dart';
import 'package:proyectos_matchy/widgets/banner_publicidad.dart';
import 'package:proyectos_matchy/screens/lugar_plantilla_sin_boton_screen.dart';
import 'package:proyectos_matchy/screens/perfil_usuariox_screen.dart';
import 'package:proyectos_matchy/screens/home_shell.dart'; // 🆕 NUEVO

class InteresesInvitacionScreen extends StatefulWidget {
  static const String routeName = 'intereses_invitacion';
  final String invitacionId;

  const InteresesInvitacionScreen({super.key, required this.invitacionId});

  @override
  State<InteresesInvitacionScreen> createState() => _InteresesInvitacionScreenState();
}

class _InteresesInvitacionScreenState extends State<InteresesInvitacionScreen> {
  // ===========================================================================
  // 🛡️ ZONA DE CHINCHES MAESTROS (mismos valores que nueva_cita_solicitud_screen.dart)
  // ===========================================================================
  static const Color kCardBackground = Color(0x20FFFFFF);
  static const double kCardRadius = 30.0;
  static const double kFotoPerfilSize = 130.0;
  static const double kFotoPerfilRadius = 24.0;

  static const TextStyle kTituloStyle = TextStyle(color: Colors.white, fontSize: 29, fontWeight: FontWeight.w900, fontFamily: 'Poppins', letterSpacing: 0.5);
  static const TextStyle kSubtituloStyle = TextStyle(color: Colors.white70, fontSize: 20, fontWeight: FontWeight.w600, fontFamily: 'Poppins');
  // ===========================================================================

  bool _procesando = false;

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
    Future.delayed(const Duration(seconds: 3), () {
      if (entry.mounted) entry.remove();
    });
  }

  LugarData _lugarDesdeMapa(Map<String, dynamic> sitioMap) {
    final foto = (sitioMap['fotoPortada'] ?? '').toString();
    return LugarData(
      id: (sitioMap['id'] ?? '').toString(),
      nombre: (sitioMap['nombre'] ?? '').toString(),
      direccion: (sitioMap['direccion'] ?? '').toString(),
      bio: '',
      fotos: foto.isNotEmpty ? [foto] : const [],
      fotoPortada: foto,
      sitioWeb: '',
      orden: 9999,
      sedes: const [],
    );
  }

  void _abrirDetalleSitio(Map<String, dynamic> sitioMap) {
    if ((sitioMap['id'] ?? '').toString().isEmpty) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => LugarPlantillaSinBotonScreen(lugar: _lugarDesdeMapa(sitioMap))));
  }

  // 🔔 NUEVO: recibe inviterUid + invitadoNombre para poder notificar al invitador
  Future<void> _escogerSitio(Map<String, dynamic> sitioMap, {required String inviterUid, required String invitadoNombre}) async {
    if (_procesando) return;
    setState(() => _procesando = true);

    try {
      await FirebaseFirestore.instance.collection('invitaciones_citas').doc(widget.invitacionId).update({
        'sitioElegidoId': sitioMap['id'],
        'sitioElegidoNombre': sitioMap['nombre'],
        'status': 'elegido',
        'respondedAt': FieldValue.serverTimestamp(),
      });

      // 🔔 NUEVO: notificamos al invitador
      if (inviterUid.isNotEmpty) {
        try {
          await FirebaseFirestore.instance.collection('users').doc(inviterUid).collection('notifications').add({
            'type': 'interes_elegido',
            'title': '¡ELIGIERON UN SITIO!',
            'body': '$invitadoNombre quiere ir a una cita contigo, eligió ${sitioMap['nombre']} para su cita. ¡Agenda tu cita ya!',
            'invitacionId': widget.invitacionId,
            'read': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        } catch (_) {}
      }

      if (!mounted) return;
      _mostrarBurbuja("¡Listo! Elegiste ${sitioMap['nombre']}.", const Color(0xFF00E676), Icons.check_circle_rounded);

      // 🔔 NUEVO: breve pausa para que se vea la burbuja, luego saltamos directo a Citas
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      HomeShell.go(context, index: 1);
    } catch (e) {
      if (mounted) _mostrarBurbuja("Error al confirmar: $e", const Color(0xFFFF5252), Icons.error_outline_rounded);
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover)),

          Column(
            children: [
              const SizedBox(height: 15),
              SafeArea(
                  bottom: false,
                  child: Image.asset('assets/images/logomatchyplano.png', height: 45)
              ),
              const SizedBox(height: 5),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('invitaciones_citas').doc(widget.invitacionId).snapshots(),
                    builder: (context, snap) {
                      if (!snap.hasData) return const Center(child: Padding(padding: EdgeInsets.only(top: 100), child: CircularProgressIndicator(color: Colors.white)));
                      if (!snap.data!.exists) return const Center(child: Padding(padding: EdgeInsets.only(top: 100), child: Text("Esta invitación ya no existe", style: TextStyle(color: Colors.white))));

                      final data = snap.data!.data() as Map<String, dynamic>;
                      final inviterUid = (data['inviterUid'] ?? '').toString();
                      final inviterNombre = (data['inviterNombre'] ?? 'Alguien').toString();
                      final invitadoNombre = (data['invitadoNombre'] ?? '').toString(); // 🆕 usado en la notificación
                      final status = (data['status'] ?? 'pending').toString();
                      final sitioElegidoId = data['sitioElegidoId'] as String?;
                      final yaRespondido = status == 'elegido';

                      final sitiosRaw = (data['sitios'] as List<dynamic>? ?? []);
                      final sitios = sitiosRaw.map((e) => Map<String, dynamic>.from(e as Map)).toList();

                      return Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: kCardBackground,
                              borderRadius: BorderRadius.circular(kCardRadius),
                              border: Border.all(color: Colors.white12, width: 1),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // 🔝 "ARRIBA EL NOMBRE DE QUIEN HACE LA INVITACIÓN"
                                FittedBox(fit: BoxFit.scaleDown, child: Text(inviterNombre.toUpperCase(), style: kTituloStyle, textAlign: TextAlign.center)),
                                const SizedBox(height: 6),
                                FittedBox(fit: BoxFit.scaleDown, child: const Text("está interesado(a) en ir contigo\na alguno de estos 3 sitios", style: kSubtituloStyle, textAlign: TextAlign.center)),

                                const SizedBox(height: 22),

                                // 👤 FOTO DE PERFIL CLICKEABLE -> perfil_usuariox_screen.dart
                                GestureDetector(
                                  onTap: inviterUid.isEmpty ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => PerfilUsuarioXScreen(uid: inviterUid))),
                                  child: Container(
                                    width: kFotoPerfilSize,
                                    height: kFotoPerfilSize,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(kFotoPerfilRadius),
                                      boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 15, offset: Offset(0, 8))],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(kFotoPerfilRadius),
                                      child: FotoPerfilUsuario(uid: inviterUid, fit: BoxFit.cover, alignment: Alignment.topCenter),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 26),

                                // 🖼️ LOS 3 SITIOS EN UNA SOLA FILA
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (int i = 0; i < 3; i++) ...[
                                      if (i > 0) const SizedBox(width: 10),
                                      _SitioColumn(
                                        sitio: i < sitios.length ? sitios[i] : const {},
                                        activo: !yaRespondido && !_procesando,
                                        elegido: yaRespondido && sitioElegidoId != null && sitioElegidoId == (i < sitios.length ? sitios[i]['id'] : null),
                                        respondido: yaRespondido,
                                        onTapFoto: () => _abrirDetalleSitio(i < sitios.length ? sitios[i] : const {}),
                                        onEscoger: () => _escogerSitio(
                                          i < sitios.length ? sitios[i] : const {},
                                          inviterUid: inviterUid,
                                          invitadoNombre: invitadoNombre,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // 🔥 BANNER PUBLICITARIO
                          const BannerPublicidad(),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),

          Positioned(
            bottom: 0, left: 0, right: 0, height: 90,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.95)],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            top: 50,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 1),
                ),
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
// 🖼️ COLUMNA DE UN SITIO: foto horizontal clickeable + botón dorado "ESCOGER"
// ============================================================================
class _SitioColumn extends StatelessWidget {
  final Map<String, dynamic> sitio;
  final bool activo;
  final bool elegido;
  final bool respondido;
  final VoidCallback onTapFoto;
  final VoidCallback onEscoger;

  const _SitioColumn({
    required this.sitio,
    required this.activo,
    required this.elegido,
    required this.respondido,
    required this.onTapFoto,
    required this.onEscoger,
  });

  @override
  Widget build(BuildContext context) {
    final nombre = (sitio['nombre'] ?? '').toString();
    final foto = (sitio['fotoPortada'] ?? '').toString();

    return Expanded(
      child: Column(
        children: [
          GestureDetector(
            onTap: onTapFoto,
            child: AspectRatio(
              aspectRatio: 1.25, // horizontal, sin deformarse (BoxFit.cover recorta, nunca estira)
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: elegido ? Border.all(color: const Color(0xFF00E676), width: 2) : null,
                  boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 4))],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _SafeSitioImage(url: foto),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
                          stops: const [0.4, 1.0],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 6, right: 6, bottom: 6,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.bottomCenter,
                        child: Text(
                          nombre.toUpperCase(),
                          maxLines: 1,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Poppins',
                              shadows: [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 2))]),
                        ),
                      ),
                    ),
                    if (elegido)
                      const Positioned(
                        top: 4, right: 4,
                        child: Icon(Icons.check_circle_rounded, color: Color(0xFF00E676), size: 20, shadows: [Shadow(color: Colors.black, blurRadius: 4)]),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _BotonEscogerDorado(
            activo: activo,
            elegido: elegido,
            respondido: respondido,
            onTap: onEscoger,
          ),
        ],
      ),
    );
  }
}

class _SafeSitioImage extends StatelessWidget {
  final String url;
  const _SafeSitioImage({required this.url});

  @override
  Widget build(BuildContext context) {
    final v = url.trim();
    if (v.startsWith('http')) {
      return CachedNetworkImage(
        key: ValueKey(v),
        imageUrl: v,
        fit: BoxFit.cover,
        memCacheHeight: 300,
        placeholder: (context, url) => Container(color: Colors.black26, child: const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFBEB3FF))))),
        errorWidget: (_, __, ___) => Container(color: Colors.grey[900], child: const Icon(Icons.broken_image, color: Colors.white24, size: 18)),
      );
    }
    if (v.startsWith('assets/')) {
      return Image.asset(v, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey[900]));
    }
    return Container(color: Colors.grey[900], child: const Icon(Icons.image_not_supported, color: Colors.white24, size: 18));
  }
}

// ============================================================================
// 💛 BOTÓN "ESCOGER" DORADO PULSANTE (misma técnica de animación que
//    _BotonDescuentosAnimado de cita_nueva_screen.dart)
// ============================================================================
class _BotonEscogerDorado extends StatefulWidget {
  final bool activo;
  final bool elegido;
  final bool respondido;
  final VoidCallback onTap;

  const _BotonEscogerDorado({
    required this.activo,
    required this.elegido,
    required this.respondido,
    required this.onTap,
  });

  @override
  State<_BotonEscogerDorado> createState() => _BotonEscogerDoradoState();
}

class _BotonEscogerDoradoState extends State<_BotonEscogerDorado> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800), lowerBound: 0.94, upperBound: 1.06)..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ya respondiste y ESTE fue el sitio elegido
    if (widget.elegido) {
      return Container(
        height: 34,
        decoration: BoxDecoration(color: const Color(0xFF00E676), borderRadius: BorderRadius.circular(14)),
        alignment: Alignment.center,
        child: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text("ELEGIDO ✓", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 11, fontFamily: 'Poppins')),
          ),
        ),
      );
    }

    // Ya respondiste, pero este NO fue el elegido -> apagado, sin pulso
    if (widget.respondido) {
      return Container(
        height: 34,
        decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(14)),
        alignment: Alignment.center,
        child: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text("NO ELEGIDO", style: TextStyle(color: Colors.white38, fontWeight: FontWeight.w700, fontSize: 10, fontFamily: 'Poppins')),
          ),
        ),
      );
    }

    // Aún sin responder -> botón dorado pulsante
    return ScaleTransition(
      scale: _controller,
      child: GestureDetector(
        onTap: widget.activo ? widget.onTap : null,
        child: Container(
          height: 34,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFF8C00)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            boxShadow: [BoxShadow(color: const Color(0xFFFFC107).withOpacity(0.6), blurRadius: 10, spreadRadius: 1)],
          ),
          alignment: Alignment.center,
          child: const FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text("ESCOGER", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 11, fontFamily: 'Poppins', letterSpacing: 0.5)),
            ),
          ),
        ),
      ),
    );
  }
}