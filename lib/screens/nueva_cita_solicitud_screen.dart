// 📂 lib/screens/nueva_cita_solicitud_screen.dart
// ✅ PANTALLA "TE INVITARON A UNA CITA" (status: pending_approval, tú eres el matchy invitado)
// 🔥 StreamBuilder en vivo sobre citas/{citaId}: encabezado, tarjeta del owner (clickeable a su
//    perfil), tarjeta grande del lugar con foto, tarjeta de fecha/hora/intención/preferencia,
//    aviso de seguridad, botones ACEPTAR/RECHAZAR.
// 🆕 FIX: al aceptar la cita, además de la lógica existente (status -> 'matched' + notificación
//    al owner), ahora también:
//    1) Registra a ambos como matchys reales en my_matchys (ambos lados), mismo esquema exacto
//       que ya usa match_screen.dart: nombre, edad, fotoUrl, matchId ("{propioUid}_{delOtroUid}"),
//       lastInteraction.
//    2) Habilita el chat vía ChatActions.upsertThread() — mismo servicio que ya usa
//       match_screen.dart, sin inventar un camino nuevo.
//    3) Usa datos FRESCOS de Firestore (users/{uid}, campo 'profilePhotoUrl'), no los guardados
//       viejos en el documento de la cita.
//    Todo lo demás del archivo (build(), tarjetas, botón RECHAZAR, aviso de seguridad, StreamBuilder)
//    queda exactamente igual a la versión original.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:proyectos_matchy/services/chat_actions.dart'; // 🆕 NUEVO
import 'package:proyectos_matchy/screens/perfil_usuariox_screen.dart';
import 'package:proyectos_matchy/screens/lugar_plantilla_sin_boton_screen.dart';
import 'package:proyectos_matchy/models/lugar_data.dart';

class NuevaCitaSolicitudScreen extends StatefulWidget {
  static const String routeName = 'nueva_cita_solicitud';
  final String citaId;
  const NuevaCitaSolicitudScreen({super.key, required this.citaId});

  @override
  State<NuevaCitaSolicitudScreen> createState() => _NuevaCitaSolicitudScreenState();
}

class _NuevaCitaSolicitudScreenState extends State<NuevaCitaSolicitudScreen> {
  // ===========================================================================
  // 🛡️ ZONA DE CHINCHES MAESTROS
  // ===========================================================================
  static const Color kCardBackground = Color(0x20FFFFFF);
  static const double kCardRadius = 30.0;
  static const double kFotoOwnerSize = 64.0;
  static const double kFotoOwnerRadius = 16.0;
  static const double kAltoFotoLugar = 190.0;
  static const double kRadioFotoLugar = 24.0;

  bool _procesando = false;

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

  LugarData _lugarDesdeData(Map<String, dynamic> data) {
    final foto = (data['lugarFotoPortada'] ?? '').toString();
    return LugarData(
      id: (data['lugarId'] ?? '').toString(),
      nombre: (data['lugarNombre'] ?? 'Lugar').toString(),
      direccion: (data['lugarDireccion'] ?? '').toString(),
      bio: '',
      fotos: foto.isNotEmpty ? [foto] : const [],
      fotoPortada: foto,
      sitioWeb: '',
      orden: 9999,
      sedes: const [],
    );
  }

  void _abrirDetalleLugar(Map<String, dynamic> data) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => LugarPlantillaSinBotonScreen(lugar: _lugarDesdeData(data))));
  }

  // ===========================================================================
  // ✍️ ACEPTAR CITA — lógica original preservada + 3 escrituras nuevas integradas
  // ===========================================================================
  Future<void> _aceptarCita() async {
    if (_procesando) return;
    setState(() => _procesando = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final myUid = user.uid;

      final citaRef = FirebaseFirestore.instance.collection('citas').doc(widget.citaId);
      final citaSnap = await citaRef.get();
      final data = citaSnap.data() ?? {};
      final ownerUid = (data['ownerUid'] ?? '').toString();

      // --- LÓGICA ORIGINAL: confirmar la cita ---
      await citaRef.update({'status': 'matched'});

      // 🆕 Datos FRESCOS de ambos usuarios (no los guardados viejos en la cita) —
      // necesarios para el registro de matchys y el chat, ver más abajo.
      final mySnap = await FirebaseFirestore.instance.collection('users').doc(myUid).get();
      final myData = mySnap.data() ?? {};
      final myNombre = (myData['nombre'] ?? 'Alguien').toString();
      final myEdadRaw = myData['edad'];
      final myEdad = myEdadRaw is int ? myEdadRaw : int.tryParse(myEdadRaw?.toString() ?? '') ?? 0;
      final myFoto = (myData['profilePhotoUrl'] ?? '').toString();

      final ownerSnap = await FirebaseFirestore.instance.collection('users').doc(ownerUid).get();
      final ownerData = ownerSnap.data() ?? {};
      final ownerNombre = (ownerData['nombre'] ?? 'Alguien').toString();
      final ownerEdadRaw = ownerData['edad'];
      final ownerEdad = ownerEdadRaw is int ? ownerEdadRaw : int.tryParse(ownerEdadRaw?.toString() ?? '') ?? 0;
      final ownerFoto = (ownerData['profilePhotoUrl'] ?? '').toString();

      // --- LÓGICA ORIGINAL: notificación al owner ---
      await FirebaseFirestore.instance.collection('users').doc(ownerUid).collection('notifications').add({
        'type': 'cita_aceptada',
        'title': '¡Cita Confirmada!',
        'body': '$myNombre aceptó tu invitación.',
        'citaId': widget.citaId,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 🆕 NUEVO 1: registro de matchys — mismo esquema exacto que match_screen.dart
      await FirebaseFirestore.instance
          .collection('users').doc(myUid)
          .collection('my_matchys').doc(ownerUid)
          .set({
        'nombre': ownerNombre,
        'edad': ownerEdad,
        'fotoUrl': ownerFoto,
        'matchId': '${myUid}_$ownerUid',
        'lastInteraction': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('users').doc(ownerUid)
          .collection('my_matchys').doc(myUid)
          .set({
        'nombre': myNombre,
        'edad': myEdad,
        'fotoUrl': myFoto,
        'matchId': '${ownerUid}_$myUid',
        'lastInteraction': FieldValue.serverTimestamp(),
      });

      // 🆕 NUEVO 2: habilitar el chat — mismo servicio que ya usa match_screen.dart
      await ChatActions.upsertThread(
        peerUid: ownerUid,
        peerNombre: ownerNombre,
        peerEdad: ownerEdad,
        peerFoto: ownerFoto,
        myNombre: myNombre,
        myEdad: myEdad,
        myFoto: myFoto,
      );

      if (!mounted) return;
      _mostrarBurbuja("¡Cita confirmada! Ya son Matchys.", const Color(0xFF00E676), Icons.check_circle_rounded);
      await Future.delayed(const Duration(seconds: 2));
      if (mounted && Navigator.of(context).canPop()) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) _mostrarBurbuja("Error al confirmar: $e", const Color(0xFFFF5252), Icons.error_outline_rounded);
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  // ===========================================================================
  // 🚫 RECHAZAR CITA — lógica original preservada, sin cambios
  // ===========================================================================
  Future<void> _rechazarCita() async {
    if (_procesando) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.white24)),
        title: const Text("¿RECHAZAR ESTA CITA?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontFamily: 'Poppins')),
        content: const Text(
          "Esta acción no se puede deshacer. Se le avisará al owner que no aceptaste la invitación.",
          style: TextStyle(color: Colors.white70, fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCELAR", style: TextStyle(color: Colors.white54))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("SÍ, RECHAZAR", style: TextStyle(color: Color(0xFFFF5252), fontWeight: FontWeight.w900))),
        ],
      ),
    );
    if (confirmar != true) return;

    setState(() => _procesando = true);
    try {
      final citaRef = FirebaseFirestore.instance.collection('citas').doc(widget.citaId);
      final citaSnap = await citaRef.get();
      final data = citaSnap.data() ?? {};
      final ownerUid = (data['ownerUid'] ?? '').toString();
      final myNombre = (data['matchyNombre'] ?? 'Tu Matchy').toString();

      await citaRef.update({
        'status': 'finished',
        'resultado': 'rechazada_por_matchy',
      });

      if (ownerUid.isNotEmpty) {
        try {
          await FirebaseFirestore.instance.collection('users').doc(ownerUid).collection('notifications').add({
            'type': 'info',
            'title': 'Invitación rechazada',
            'body': '$myNombre no pudo aceptar tu invitación a la cita.',
            'citaId': widget.citaId,
            'read': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        } catch (_) {}
      }

      if (!mounted) return;
      _mostrarBurbuja("Invitación rechazada.", const Color(0xFFFF5252), Icons.block_rounded);
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted && Navigator.of(context).canPop()) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) _mostrarBurbuja("Error: $e", const Color(0xFFFF5252), Icons.error_outline_rounded);
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

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 15, 20, 60),
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('citas').doc(widget.citaId).snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 150),
                      child: Center(child: CircularProgressIndicator(color: Colors.white)),
                    );
                  }
                  if (!snap.data!.exists) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 150),
                      child: Center(child: Text("Esta invitación ya no existe", style: TextStyle(color: Colors.white))),
                    );
                  }

                  final data = snap.data!.data() as Map<String, dynamic>;
                  final ownerUid = (data['ownerUid'] ?? '').toString();
                  final ownerNombre = (data['ownerNombre'] ?? 'Alguien').toString();
                  final ownerEdad = (data['ownerEdad'] ?? '').toString();
                  final ownerFoto = (data['ownerFoto'] ?? '').toString();
                  final lugarNombre = (data['lugarNombre'] ?? 'Lugar').toString();
                  final lugarDireccion = (data['lugarDireccion'] ?? '').toString();
                  final lugarFoto = (data['lugarFotoPortada'] ?? '').toString();
                  final fecha = (data['fecha'] ?? '').toString();
                  final hora = (data['hora'] ?? '').toString();
                  final intencion = (data['intencion'] ?? '').toString();
                  final preferencia = (data['preferencia'] ?? '').toString();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40),
                      Center(child: Image.asset('assets/images/logomatchyplano.png', height: 45)),
                      const SizedBox(height: 25),

                      const Center(
                        child: Text(
                          "¡TE INVITARON A UNA CITA!",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22, fontFamily: 'Poppins'),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Center(
                        child: Text(
                          "Revisa el lugar, la fecha y decide si aceptas",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white54, fontSize: 13, fontFamily: 'Poppins'),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 👤 TARJETA DEL OWNER
                      GestureDetector(
                        onTap: ownerUid.isEmpty ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => PerfilUsuarioXScreen(uid: ownerUid))),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: kCardBackground, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white12)),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(kFotoOwnerRadius),
                                child: SizedBox(
                                  width: kFotoOwnerSize, height: kFotoOwnerSize,
                                  child: ownerFoto.trim().startsWith('http')
                                      ? CachedNetworkImage(
                                    imageUrl: ownerFoto,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(color: Colors.black26, child: const Center(child: CircularProgressIndicator(color: Color(0xFFBEB3FF), strokeWidth: 2))),
                                    errorWidget: (_, __, ___) => Container(color: Colors.grey[900], child: const Icon(Icons.person, color: Colors.white24)),
                                  )
                                      : Container(color: Colors.grey[900], child: const Icon(Icons.person, color: Colors.white24)),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("$ownerNombre, $ownerEdad", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'Poppins')),
                                    const Text("Te está invitando a esta cita", style: TextStyle(color: Colors.white54, fontSize: 12, fontFamily: 'Poppins')),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, color: Colors.white38),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 📍 TARJETA DEL LUGAR
                      GestureDetector(
                        onTap: () => _abrirDetalleLugar(data),
                        child: Container(
                          height: kAltoFotoLugar,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(kRadioFotoLugar), boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 5))]),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              lugarFoto.trim().startsWith('http')
                                  ? CachedNetworkImage(
                                imageUrl: lugarFoto,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(color: Colors.black26, child: const Center(child: CircularProgressIndicator(color: Color(0xFFBEB3FF), strokeWidth: 2))),
                                errorWidget: (_, __, ___) => Container(color: Colors.grey[900], child: const Icon(Icons.broken_image, color: Colors.white24)),
                              )
                                  : Container(color: Colors.grey[900], child: const Icon(Icons.image_not_supported, color: Colors.white24)),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.9)], stops: const [0.4, 1.0]),
                                ),
                              ),
                              Positioned(
                                left: 18, right: 18, bottom: 14,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(lugarNombre.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900, fontFamily: 'Poppins')),
                                    const SizedBox(height: 2),
                                    Text(lugarDireccion, style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Poppins')),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 📅 TARJETA DE FECHA/HORA/INTENCIÓN/PREFERENCIA
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white12)),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(fecha, style: const TextStyle(color: Color(0xFFFFC107), fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'Poppins')),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(hora, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17, fontFamily: 'Poppins')),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Container(height: 1, color: Colors.white12),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      const Text("Intención: ", style: TextStyle(color: Colors.white54, fontSize: 13, fontFamily: 'Poppins')),
                                      Expanded(child: Text(intencion, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Poppins'), overflow: TextOverflow.ellipsis)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      const Text("Pref: ", style: TextStyle(color: Colors.white54, fontSize: 13, fontFamily: 'Poppins')),
                                      Expanded(child: Text(preferencia, style: const TextStyle(color: Color(0xFFE0D4FF), fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Poppins'), overflow: TextOverflow.ellipsis)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 🛡️ AVISO DE SEGURIDAD
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white12)),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.shield_outlined, color: Colors.white70, size: 22),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                "Mantén tu cita en un lugar público. Al llegar, cada uno recibirá un código para confirmar su asistencia en persona.",
                                style: TextStyle(color: Colors.white70, fontSize: 12.5, fontFamily: 'Poppins', height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // ✅ ACEPTAR
                      GestureDetector(
                        onTap: _procesando ? null : _aceptarCita,
                        child: Container(
                          height: 54,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF00E676), Color(0xFF00B84D)]),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 3))],
                          ),
                          alignment: Alignment.center,
                          child: _procesando
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                              : const Text("ACEPTAR CITA", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16, fontFamily: 'Poppins', letterSpacing: 0.5)),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // 🚫 RECHAZAR
                      GestureDetector(
                        onTap: _procesando ? null : _rechazarCita,
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFFF6E63), width: 1.5),
                          ),
                          alignment: Alignment.center,
                          child: const Text("RECHAZAR", style: TextStyle(color: Color(0xFFFF6E63), fontWeight: FontWeight.w900, fontSize: 14, fontFamily: 'Poppins')),
                        ),
                      ),
                    ],
                  );
                },
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