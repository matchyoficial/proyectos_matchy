// 📂 lib/screens/nueva_cita_solicitud_screen.dart
// ✅ PANTALLA DE SOLICITUD DE CITA BLINDADA (SMART CACHE PRO INYECTADO)
// 🔥 CACHÉ PRO: Renderizado instantáneo (0ms) en la foto del lugar.
// 🔥 FIX: Notificaciones de campana enriquecidas con Nombre y Lugar.
// 🔥 FIX: Burbuja Flotante "Matchy Style" en reemplazo del SnackBar nativo.
// 🔥 BLINDAJE: Textos protegidos con FittedBox SIN ALTERAR tamaños de fuente originales.
// 🔥 UI: FotoPerfilUsuario con Alignment.topCenter y Fade Out inferior respetados.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart'; // 🔥 Motor de caché
import 'package:proyectos_matchy/screens/reprogramar_cita_screen.dart';
import 'package:proyectos_matchy/widgets/foto_perfil_usuario.dart';

class NuevaCitaSolicitudScreen extends StatefulWidget {
  final String citaId;

  const NuevaCitaSolicitudScreen({super.key, required this.citaId});

  @override
  State<NuevaCitaSolicitudScreen> createState() => _NuevaCitaSolicitudScreenState();
}

class _NuevaCitaSolicitudScreenState extends State<NuevaCitaSolicitudScreen> {
  bool _procesando = false;

  // ===========================================================================
  // 🛡️ ZONA DE CHINCHES MAESTROS (DISEÑO BLINDADO)
  // ===========================================================================
  static const Color kCardBackground = Color(0x20FFFFFF);
  static const double kCardRadius = 30.0;
  static const double kFotoPerfilSize = 130.0;
  static const double kFotoPerfilRadius = 24.0;
  static const double kFotoLugarHeight = 180.0;
  static const double kFotoLugarRadius = 20.0;

  static const List<Color> kBtnAceptarGradient = [Color(0xFF00C853), Color(0xFF009624)];
  static const List<Color> kBtnSugerirGradient = [Color(0xFF7E208E), Color(0xFC4B3F60)];

  static const TextStyle kTituloStyle = TextStyle(color: Colors.white, fontSize: 29, fontWeight: FontWeight.w900, fontFamily: 'Poppins', letterSpacing: 0.5);
  static const TextStyle kSubtituloStyle = TextStyle(color: Colors.white70, fontSize: 21, fontWeight: FontWeight.w600, fontFamily: 'Poppins');

  static const TextStyle kNombreLugarStyle = TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, fontFamily: 'Poppins', height: 1.0);
  static const TextStyle kDireccionStyle = TextStyle(color: Colors.white60, fontSize: 19, fontWeight: FontWeight.w500, height: 1.0);

  static const TextStyle kFechaStyle = TextStyle(color: Color(0xFFFFD700), fontSize: 20, fontWeight: FontWeight.w800, fontFamily: 'Poppins');
  static const TextStyle kHoraStyle = TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold);
  // ===========================================================================

  // 🔥 SISTEMA DE BURBUJAS FLOTANTES MATCHY STYLE
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
    Future.delayed(const Duration(seconds: 2), () {
      if (entry.mounted) entry.remove();
    });
  }

  Future<void> _aceptarCita(String ownerUid, String lugarNombre, String myName) async {
    setState(() => _procesando = true);
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    try {
      await FirebaseFirestore.instance.collection('citas').doc(widget.citaId).update({
        'status': 'matched',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (ownerUid.isNotEmpty) {
        await FirebaseFirestore.instance.collection('users').doc(ownerUid).collection('notifications').add({
          'type': 'cita_aceptada',
          'title': '¡CITA ACEPTADA: $lugarNombre!',
          'body': '$myName aceptó tu invitación. ¡Prepara tu salida!',
          'citaId': widget.citaId,
          'senderUid': myUid,
          'createdAt': FieldValue.serverTimestamp(),
          'read': false,
        });
      }

      if (!mounted) return;

      // 🔔 Burbuja Premium de Éxito
      _mostrarBurbuja("¡Éxito! Cita Aceptada.", const Color(0xFF00C853), Icons.check_circle_rounded);

      // ⏳ Retraso sutil para que el usuario alcance a ver la burbuja antes de salir
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;
      Navigator.pop(context);

    } catch (e) {
      if (!mounted) return;
      _mostrarBurbuja("Error: $e", const Color(0xFFFF5252), Icons.error_outline_rounded);
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  void _sugerirOtroMomento() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ReprogramarCitaScreen(citaId: widget.citaId)));
  }

  String _formatearFechaLarga(String fechaCorta) {
    try {
      final parts = fechaCorta.split('/');
      if (parts.length != 3) return fechaCorta;
      final dt = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      return DateFormat("EEEE d 'de' MMMM yyyy", 'es_ES').format(dt).toUpperCase();
    } catch (e) {
      return fechaCorta;
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
                    stream: FirebaseFirestore.instance.collection('citas').doc(widget.citaId).snapshots(),
                    builder: (context, snap) {
                      if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: Colors.white));
                      if (!snap.data!.exists) return const Center(child: Text("Cita no encontrada", style: TextStyle(color: Colors.white)));

                      final data = snap.data!.data() as Map<String, dynamic>;
                      final lugarNombre = (data['lugarNombre'] ?? 'Lugar').toString().toUpperCase();
                      final lugarFoto = (data['lugarFotoPortada'] ?? '').toString();
                      final direccion = (data['sedeDireccion'] != null && data['sedeDireccion'].toString().isNotEmpty)
                          ? data['sedeDireccion'].toString()
                          : (data['lugarDireccion'] ?? '').toString();

                      final fechaRaw = (data['fecha'] ?? '').toString();
                      final horaRaw = (data['hora'] ?? '').toString();
                      final fechaBonita = _formatearFechaLarga(fechaRaw);

                      final ownerNombre = (data['ownerNombre'] ?? 'Tu Matchy').toString().toUpperCase();
                      final ownerUid = (data['ownerUid'] ?? '').toString();

                      // 👤 Capturamos el nombre de quien acepta (El Matchy / Candidato)
                      final myName = (data['matchyNombre'] ?? data['candidatoNombre'] ?? 'Tu Matchy').toString();

                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: kCardBackground,
                          borderRadius: BorderRadius.circular(kCardRadius),
                          border: Border.all(color: Colors.white12, width: 1),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 🛡️ BLINDAJE: Título estandarizado
                            FittedBox(fit: BoxFit.scaleDown, child: const Text("INVITACIÓN DE CITA", style: kTituloStyle, textAlign: TextAlign.center)),
                            const SizedBox(height: 4),
                            // 🛡️ BLINDAJE: Nombre del Matchy
                            FittedBox(fit: BoxFit.scaleDown, child: Text("$ownerNombre te ha invitado", style: kSubtituloStyle, textAlign: TextAlign.center)),
                            const SizedBox(height: 25),

                            Container(
                              width: kFotoPerfilSize,
                              height: kFotoPerfilSize,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(kFotoPerfilRadius),
                                boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 15, offset: Offset(0, 8))],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(kFotoPerfilRadius),
                                child: FotoPerfilUsuario(
                                  uid: ownerUid,
                                  fit: BoxFit.cover,
                                  alignment: Alignment.topCenter,
                                ),
                              ),
                            ),

                            const SizedBox(height: 25),

                            if (lugarFoto.isNotEmpty)
                              Container(
                                height: kFotoLugarHeight,
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 20),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(kFotoLugarRadius),
                                  boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 5))],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(kFotoLugarRadius),
                                  // 🔥 SMART CACHE INYECTADO
                                  child: CachedNetworkImage(
                                      key: ValueKey(lugarFoto),
                                      imageUrl: lugarFoto,
                                      fit: BoxFit.cover,
                                      alignment: Alignment.topCenter,
                                      memCacheHeight: (kFotoLugarHeight * 3).toInt(), // Optimizador RAM (180 * 3 = 540)
                                      placeholder: (context, url) => Container(color: Colors.black26, child: const Center(child: CircularProgressIndicator(color: Color(0xFFBEB3FF), strokeWidth: 2))),
                                      errorWidget: (_, __, ___) => Container(color: Colors.grey[900], child: const Icon(Icons.broken_image, color: Colors.white24))
                                  ),
                                ),
                              ),

                            // 🛡️ BLINDAJE: Nombre de lugar
                            FittedBox(fit: BoxFit.scaleDown, child: Text(lugarNombre, textAlign: TextAlign.center, style: kNombreLugarStyle)),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.location_on, color: Colors.white60, size: 16),
                                const SizedBox(width: 4),
                                // 🛡️ BLINDAJE: Dirección
                                Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        direccion,
                                        textAlign: TextAlign.center,
                                        style: kDireccionStyle,
                                        maxLines: 1,
                                      ),
                                    )
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: Column(
                                children: [
                                  // 🛡️ BLINDAJE: Fecha y Hora
                                  FittedBox(fit: BoxFit.scaleDown, child: Text(fechaBonita, textAlign: TextAlign.center, style: kFechaStyle)),
                                  const SizedBox(height: 4),
                                  FittedBox(fit: BoxFit.scaleDown, child: Text(horaRaw, textAlign: TextAlign.center, style: kHoraStyle)),
                                ],
                              ),
                            ),

                            const SizedBox(height: 14),

                            _BotonPremiumAccion(
                              text: "ACEPTAR CITA",
                              gradient: kBtnAceptarGradient,
                              icon: Icons.check_circle_rounded,
                              isLoading: _procesando,
                              onTap: _procesando ? null : () => _aceptarCita(ownerUid, lugarNombre, myName),
                            ),

                            const SizedBox(height: 15),

                            _BotonPremiumAccion(
                              text: "SUGERIR OTRO MOMENTO",
                              gradient: kBtnSugerirGradient,
                              icon: Icons.edit_calendar_rounded,
                              onTap: _sugerirOtroMomento,
                            ),
                          ],
                        ),
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

class _BotonPremiumAccion extends StatelessWidget {
  final String text;
  final List<Color> gradient;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isLoading;

  const _BotonPremiumAccion({
    required this.text,
    required this.gradient,
    required this.icon,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 4))],
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Center(
            child: isLoading
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      text,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          fontFamily: 'Poppins'
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}