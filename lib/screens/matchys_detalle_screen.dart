// 📂 lib/screens/matchys_detalle_screen.dart
// ✅ DETALLE DE MATCHY BLINDADO (SMART CACHE PRO + FILTRO DE HISTORIA FELIZ)
// 🔥 FILTRO: Solo muestra citas finalizadas que NO sean fallidas.
// 🔥 CACHÉ PRO: Renderizado instantáneo en el Historial (Grid) y en el Pop-Up (0ms).
// 🔥 UI: Carta de detalle con botones separados de Eliminar (Tenue) y Bloquear (Nuclear).
// 🧨 WIPE-OUT PROTOCOL INYECTADO: Destruye citas, chats, matchys y añade a lista negra.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:proyectos_matchy/widgets/matchy_page_layout.dart';
import 'package:proyectos_matchy/screens/matchys_screen.dart';
import 'package:proyectos_matchy/screens/perfil_usuariox_screen.dart';
import 'package:proyectos_matchy/screens/cita_nueva_screen.dart';
import 'package:proyectos_matchy/screens/zona_de_descuentos_screen.dart';
import 'package:proyectos_matchy/widgets/foto_perfil_usuario.dart';

class MatchysDetalleScreen extends StatefulWidget {
  final MatchyData matchyData;
  const MatchysDetalleScreen({super.key, required this.matchyData});
  @override State<MatchysDetalleScreen> createState() => _MatchysDetalleScreenState();
}

class _MatchysDetalleScreenState extends State<MatchysDetalleScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  bool _isUserBlocked = false;
  int _userStrikes = 0;
  bool _isLoadingStatus = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800), lowerBound: 0.95, upperBound: 1.05)..repeat(reverse: true);
    _scaleAnimation = _controller;
    _verificarEstadoUsuario();
  }

  Future<void> _verificarEstadoUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoadingStatus = false);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        final status = (data['userStatus'] ?? 'active').toString();
        final strikes = (data['strikes'] as num?)?.toInt() ?? 0;
        final bloqueadoHasta = data['bloqueadoHasta'] as Timestamp?;

        bool bloqueado = false;
        if (status == 'blocked') bloqueado = true;
        if (bloqueadoHasta != null && bloqueadoHasta.toDate().isAfter(DateTime.now())) bloqueado = true;

        setState(() {
          _isUserBlocked = bloqueado;
          _userStrikes = strikes;
        });
      }
    } catch (e) {
      debugPrint("Error verificando bloqueo: $e");
    } finally {
      if (mounted) setState(() => _isLoadingStatus = false);
    }
  }

  void _mostrarDetalleCitaHistorica(String foto, String lugar, String fecha) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                child: CachedNetworkImage(
                  key: ValueKey(foto),
                  imageUrl: foto,
                  fit: BoxFit.cover,
                  height: 250,
                  width: double.infinity,
                  memCacheHeight: 750,
                  placeholder: (context, url) => Container(height: 250, color: Colors.black26, child: const Center(child: CircularProgressIndicator(color: Color(0xFFBEB3FF), strokeWidth: 2))),
                  errorWidget: (_, __, ___) => Container(height: 250, color: Colors.grey[900], child: const Icon(Icons.broken_image, color: Colors.white24)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        lugar.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, fontFamily: 'Poppins'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
                      child: Text(
                        "CITA REALIZADA EL: $fecha",
                        style: const TextStyle(color: Color(0xFFBEB3FF), fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF6B4EE6), Color(0xFF4527A0)]),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Text("CERRAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _manejarClickNuevaCita() {
    if (_isUserBlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.lock_outline, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(child: Text(
                    "BLOQUEADO.\nTienes $_userStrikes strike(s). Resuelve tus pendientes.",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)
                )),
              ],
            ),
            backgroundColor: const Color(0xFFC62828),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(20),
            duration: const Duration(seconds: 4),
          )
      );
    } else {
      Navigator.push(context, MaterialPageRoute(
          builder: (_) => CitaNuevaScreen(
            nombreUsuario: 'Yo',
            nombreMatch: widget.matchyData.nombre,
            fotoUsuario: '',
            fotoMatch: widget.matchyData.fotoUrl,
            matchyUidInvitado: widget.matchyData.uid,
          )
      ));
    }
  }

  Future<void> _eliminarConexionTotal() async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;
    final matchyUid = widget.matchyData.uid;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.redAccent)),
      );

      final batch = FirebaseFirestore.instance.batch();
      final citasRef = FirebaseFirestore.instance.collection('citas');

      final snapshot1 = await citasRef.where('ownerUid', isEqualTo: myUid).where('matchyUid', isEqualTo: matchyUid).get();
      for (var doc in snapshot1.docs) { batch.delete(doc.reference); }

      final snapshot2 = await citasRef.where('ownerUid', isEqualTo: matchyUid).where('matchyUid', isEqualTo: myUid).get();
      for (var doc in snapshot2.docs) { batch.delete(doc.reference); }

      final myMatchyRef = FirebaseFirestore.instance.collection('users').doc(myUid).collection('my_matchys').doc(matchyUid);
      final suMatchyRef = FirebaseFirestore.instance.collection('users').doc(matchyUid).collection('my_matchys').doc(myUid);

      batch.delete(myMatchyRef);
      batch.delete(suMatchyRef);

      await batch.commit();

      if (mounted) {
        Navigator.pop(context); // loading
        Navigator.pop(context); // dialog
        Navigator.pop(context); // screen
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint("Error eliminando conexion: $e");
    }
  }

  void _mostrarAlertaEliminarMatchy() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white24, width: 1), // Borde tenue
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.link_off_rounded, color: Colors.white54, size: 60),
              const SizedBox(height: 16),
              const Text(
                "¿ELIMINAR MATCHY?",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'Poppins'),
              ),
              const SizedBox(height: 12),
              const Text(
                "Se eliminará la conexión actual y el historial de citas. Podrán volver a conectar en el futuro.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.5),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(15)),
                        alignment: Alignment.center,
                        child: const Text("CANCELAR", style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        _eliminarConexionTotal();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(15)),
                        alignment: Alignment.center,
                        child: const Text("ELIMINAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
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

  // 🧨 PROTOCOLO WIPE-OUT (BORRADO NUCLEAR Y LISTA NEGRA)
  Future<void> _bloquearUsuarioDefinitivo() async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;
    final matchyUid = widget.matchyData.uid;

    try {
      showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.redAccent)));

      final batch = FirebaseFirestore.instance.batch();

      // 1. Destrucción de Citas Compartidas (Historial)
      final citasRef = FirebaseFirestore.instance.collection('citas');
      final snapshotCitas1 = await citasRef.where('ownerUid', isEqualTo: myUid).where('matchyUid', isEqualTo: matchyUid).get();
      for (var doc in snapshotCitas1.docs) { batch.delete(doc.reference); }
      final snapshotCitas2 = await citasRef.where('ownerUid', isEqualTo: matchyUid).where('matchyUid', isEqualTo: myUid).get();
      for (var doc in snapshotCitas2.docs) { batch.delete(doc.reference); }

      // 2. Destrucción de Chats Activos
      final chatsRef = FirebaseFirestore.instance.collection('chat_threads');
      final snapshotChats = await chatsRef.where('participantUids', arrayContains: myUid).get();
      for (var doc in snapshotChats.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participantUids'] ?? []);
        if (participants.contains(matchyUid)) {
          batch.delete(doc.reference);
        }
      }

      // 3. Destrucción de Conexión (Matchys)
      final myMatchyRef = FirebaseFirestore.instance.collection('users').doc(myUid).collection('my_matchys').doc(matchyUid);
      final suMatchyRef = FirebaseFirestore.instance.collection('users').doc(matchyUid).collection('my_matchys').doc(myUid);
      batch.delete(myMatchyRef);
      batch.delete(suMatchyRef);

      // 4. Exilio (Lista Negra para filtrar publicaciones)
      final myBlockRef = FirebaseFirestore.instance.collection('users').doc(myUid).collection('blocked_users').doc(matchyUid);
      batch.set(myBlockRef, {'blockedAt': FieldValue.serverTimestamp(), 'uid': matchyUid});

      await batch.commit();

      if (mounted) {
        Navigator.pop(context); // Cierra loading
        Navigator.pop(context); // Cierra popup
        Navigator.pop(context); // Sale de la pantalla de detalle
        _mostrarBurbuja("Usuario y todo su historial bloqueados y eliminados.", const Color(0xFFD32F2F), Icons.block);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint("Error bloqueando usuario: $e");
    }
  }

  void _mostrarAlertaBloquearUsuario() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.redAccent.withOpacity(0.5), width: 2),
            boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.15), blurRadius: 20, spreadRadius: 2)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.block_flipped, color: Colors.redAccent, size: 60),
              const SizedBox(height: 16),
              const Text(
                "¿BLOQUEAR USUARIO?",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'Poppins'),
              ),
              const SizedBox(height: 12),
              const Text(
                "Esta acción es permanente. Se eliminará el historial, la conexión actual y jamás volverás a ver sus publicaciones ni podrá contactarte.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.5),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
                        alignment: Alignment.center,
                        child: const Text("CANCELAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        _bloquearUsuarioDefinitivo();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)]),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))],
                        ),
                        alignment: Alignment.center,
                        child: const Text("BLOQUEAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
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

  void _mostrarBurbuja(String mensaje, Color color, IconData icono) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [Icon(icono, color: Colors.white), const SizedBox(width: 10), Expanded(child: Text(mensaje, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)))]),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(20),
          duration: const Duration(seconds: 3),
        )
    );
  }

  @override void dispose() { _controller.dispose(); super.dispose(); }

  // ===========================================================================
  // 🛡️ ZONA DE CHINCHES MAESTROS (CONTROL DE UI)
  // ===========================================================================
  static const double kHistorialHeight = 280.0;
  static const double kFotoRatio = 1.4;
  static const double kFotoSize = 110.0;
  static const double kCardBorderRadius = 25.0;
  static const Color kCapsulaColor = Color(0x33FFFFFF);
  static const List<Color> kBtnNuevaCitaGradient = [Color(0xFFBEB3FF), Color(0xFF8A80CC)];
  static const List<Color> kBtnBlockedGradient = [Color(0xFF424242), Color(0xFF212121)];
  static const double kButtonRadius = 20.0;
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MatchyPageLayout(
            backgroundAsset: 'assets/images/fondo.jpg',
            logoAsset: 'assets/images/logomatchyplano.png',
            topSpacing: 35,
            logoHeight: 45,
            spaceLogoToScroll: 20,
            scrollContent: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PerfilUsuarioXScreen(uid: widget.matchyData.uid))),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(kCardBorderRadius),
                        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 5))],
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: SizedBox(
                              width: kFotoSize,
                              height: kFotoSize,
                              child: FotoPerfilUsuario(
                                  uid: widget.matchyData.uid,
                                  fit: BoxFit.cover,
                                  alignment: Alignment.topCenter
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    widget.matchyData.nombre.toUpperCase(),
                                    style: const TextStyle(color: Colors.white, fontSize: 22.0, fontWeight: FontWeight.w900, fontFamily: 'Poppins', height: 1.0),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "${widget.matchyData.edad} AÑOS",
                                  style: const TextStyle(color: Colors.white70, fontSize: 16.0, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 8),
                                const Text("Ver perfil completo >", style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.white24),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: const Text(
                        "TU HISTORIAL CON TU MATCHY",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, fontFamily: 'Poppins', shadows: [Shadow(color: Colors.black, blurRadius: 6, offset: Offset(0, 3))])
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2. HISTORIAL (CON FILTRO DE EXCLUSIÓN)
                  Container(
                    height: kHistorialHeight,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: kCapsulaColor, borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.white10)),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('citas').orderBy('updatedAt', descending: true).snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) return const Icon(Icons.error, color: Colors.white);
                        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.white));

                        final docs = (snapshot.data?.docs ?? []).where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final status = data['status'];
                          final res = (data['resultado'] ?? '').toString();
                          final ownerUid = data['ownerUid'];
                          final matchyUid = data['matchyUid'];

                          bool esFallo = res == 'expired_by_inactivity' ||
                              res == 'timeout_punished' ||
                              res == 'cancelled_penalty';

                          if (status != 'finished' || esFallo) return false;

                          return (ownerUid == myUid && matchyUid == widget.matchyData.uid) || (matchyUid == myUid && ownerUid == widget.matchyData.uid);
                        }).toList();

                        if (docs.isEmpty) return const Center(child: Text("Aún no tienen citas completadas.", style: TextStyle(color: Colors.white54, fontSize: 12)));

                        return GridView.builder(
                          padding: EdgeInsets.zero,
                          physics: const BouncingScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: kFotoRatio
                          ),
                          itemCount: docs.length,
                          itemBuilder: (ctx, i) {
                            final d = docs[i].data() as Map<String, dynamic>;
                            final nombreLugar = (d['lugarNombre'] ?? 'Cita').toString();
                            final fotoLugar = (d['lugarFotoPortada'] ?? '').toString();
                            String fechaMostrable = d['fecha']?.toString() ?? d['fechaHora']?.toString().split(' ').first ?? "Fecha";

                            return GestureDetector(
                              onTap: () => _mostrarDetalleCitaHistorica(fotoLugar, nombreLugar, fechaMostrable),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Stack(fit: StackFit.expand, children: [
                                  CachedNetworkImage(
                                    key: ValueKey(fotoLugar),
                                    imageUrl: fotoLugar,
                                    fit: BoxFit.cover,
                                    memCacheHeight: 300,
                                    placeholder: (context, url) => Container(color: Colors.black26),
                                    errorWidget: (_,__,___) => Container(color: Colors.grey[800]),
                                  ),
                                  Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.95)], stops: const [0.5, 1.0]))),
                                  Positioned(bottom: 8, left: 8, right: 8, child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                                    FittedBox(fit: BoxFit.scaleDown, child: Text(nombreLugar.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10, fontFamily: 'Poppins'))),
                                    Text(fechaMostrable, style: const TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.bold)),
                                  ]))
                                ]),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 25),

                  if (_isLoadingStatus)
                    const Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(color: Colors.white))
                  else
                    GestureDetector(
                      onTap: _manejarClickNuevaCita,
                      child: Container(
                          width: double.infinity, height: 50,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                              gradient: LinearGradient(colors: _isUserBlocked ? kBtnBlockedGradient : kBtnNuevaCitaGradient),
                              borderRadius: BorderRadius.circular(kButtonRadius),
                              border: Border.all(color: Colors.white24, width: 0.5)
                          ),
                          alignment: Alignment.center,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_isUserBlocked) ...[const Icon(Icons.lock, color: Colors.white54, size: 16), const SizedBox(width: 8)],
                                Text(
                                    _isUserBlocked ? "CUENTA BLOQUEADA" : "NUEVA CITA CON TU MATCHY",
                                    style: TextStyle(color: _isUserBlocked ? Colors.white54 : Colors.black, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5)
                                ),
                              ],
                            ),
                          )
                      ),
                    ),

                  const SizedBox(height: 20),

                  ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                          width: double.infinity, height: 55,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFF8C00)]), boxShadow: [BoxShadow(color: const Color(0xFFFFC107).withOpacity(0.6), blurRadius: 15)]),
                          child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: ()=>Navigator.push(context, MaterialPageRoute(builder: (_)=>const ZonaDeDescuentosScreen())),
                                  child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.stars_rounded, color: Colors.black),
                                        SizedBox(width: 10),
                                        Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text("ZONA DE DESCUENTOS", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)))),
                                        SizedBox(width: 10),
                                        Icon(Icons.stars_rounded, color: Colors.black)
                                      ]
                                  )
                              )
                          )
                      )
                  ),

                  const SizedBox(height: 20),

                  // BOTÓN: ELIMINAR MATCHY (Tenue)
                  GestureDetector(
                    onTap: _mostrarAlertaEliminarMatchy,
                    child: Container(
                      width: double.infinity,
                      height: 55,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white12),
                      ),
                      alignment: Alignment.center,
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          "ELIMINAR MATCHY",
                          style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 14, letterSpacing: 0.5),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // BOTÓN: BLOQUEAR USUARIO (Agresivo)
                  GestureDetector(
                    onTap: _mostrarAlertaBloquearUsuario,
                    child: Container(
                      width: double.infinity,
                      height: 55,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)]),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      alignment: Alignment.center,
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          "BLOQUEAR USUARIO",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
          Positioned(bottom: 0, left: 0, right: 0, height: 90, child: IgnorePointer(child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.95)], stops: const [0.0, 1.0]))))),
          Positioned(top: 50, left: 16, child: GestureDetector(onTap: ()=>Navigator.pop(context), child: Container(width: 42, height: 42, decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), shape: BoxShape.circle, border: Border.all(color: Colors.white24)), child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20)))),
        ],
      ),
    );
  }
}