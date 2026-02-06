// 📂 lib/screens/matchys_detalle_screen.dart
// ✅ DETALLE DE MATCHY (DISEÑO UNIFICADO TIPO PANEL)
// 🔥 FIX: Cabecera cambiada a "Cápsula Horizontal": Foto cuadrada (110x110) izquierda + Info derecha.
// 🔥 UI: Foto alineada al TopCenter para no cortar cabezas.
// 🔥 LOGIC: Bloqueo de usuario y botones intactos.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  // Variables para el bloqueo
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

  void _manejarClickNuevaCita() {
    if (_isUserBlocked) {
      final dias = _userStrikes * 5;
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

  @override void dispose() { _controller.dispose(); super.dispose(); }

  // ===========================================================================
  // 🔴🔴 ZONA DE CHINCHES MAESTROS 🔴🔴
  // ===========================================================================

  // DIMENSIONES ESTILO PANEL
  static const double kFotoSize = 110.0; // Foto cuadrada
  static const double kCardBorderRadius = 25.0;

  static const double kHistorialHeight = 250.0;
  static const Color kCapsulaColor = Color(0x33FFFFFF);
  static const Color kGoldColor = Color(0xFFFFC107);

  static const List<Color> kBtnNuevaCitaGradient = [Color(0xFFBEB3FF), Color(0xFF8A80CC)];
  static const List<Color> kBtnBlockedGradient = [Color(0xFF424242), Color(0xFF212121)];

  static const double kButtonRadius = 20.0;
  static const List<BoxShadow> kButtonShadow = [BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 4))];

  // POP-UP
  static const Color kPopUpBackground = Color(0xFF1A1A1A);
  static const double kPopUpRadius = 25.0;
  static const double kPopUpTitleSize = 22.0;
  static const double kPopUpDateSize = 16.0;
  static const Color kPopUpIconColor = Color(0xFFBEB3FF);
  static const double kPopUpFotoHeight = 250.0;

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

                  // 🔥 CAMBIO PRINCIPAL: CÁPSULA ESTILO PANEL (ROW)
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
                          // 🟦 FOTO CUADRADA IZQUIERDA (110x110)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: SizedBox(
                              width: kFotoSize,
                              height: kFotoSize,
                              // 🔥 Alineación TopCenter para la cara
                              child: FotoPerfilUsuario(
                                  uid: widget.matchyData.uid,
                                  fit: BoxFit.cover,
                                  alignment: Alignment.topCenter
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          // 📝 INFO LATERAL DERECHA
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  widget.matchyData.nombre.toUpperCase(),
                                  style: const TextStyle(color: Colors.white, fontSize: 22.0, fontWeight: FontWeight.w900, fontFamily: 'Poppins', height: 1.0),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
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

                  // TÍTULO
                  const Text("TU HISTORIAL CON TU MATCHY", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900, fontFamily: 'Poppins', shadows: [Shadow(color: Colors.black, blurRadius: 6, offset: Offset(0, 3))])),
                  const SizedBox(height: 4),

                  // HISTORIAL
                  Container(
                    height: kHistorialHeight, padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: kCapsulaColor, borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.white10)),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('citas').orderBy('updatedAt', descending: true).snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) return const Icon(Icons.error, color: Colors.white);
                        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.white));

                        final allDocs = snapshot.data?.docs ?? [];
                        final docs = allDocs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final status = data['status'];
                          final ownerUid = data['ownerUid'];
                          final matchyUid = data['matchyUid'];

                          if (status != 'finished') return false;
                          bool soyYoOwner = ownerUid == myUid;
                          bool soyYoMatchy = matchyUid == myUid;
                          bool esElMatchy = matchyUid == widget.matchyData.uid;
                          bool esElOwner = ownerUid == widget.matchyData.uid;

                          return (soyYoOwner && esElMatchy) || (soyYoMatchy && esElOwner);
                        }).toList();

                        if (docs.isEmpty) return const Center(child: Text("Aún no tienen citas completadas.", style: TextStyle(color: Colors.white54, fontSize: 12)));

                        return GridView.builder(
                          physics: const BouncingScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.3),
                          itemCount: docs.length,
                          itemBuilder: (ctx, i) {
                            final d = docs[i].data() as Map<String, dynamic>;
                            final nombreLugar = (d['lugarNombre'] ?? 'Cita').toString();
                            final fotoLugar = (d['lugarFotoPortada'] ?? '').toString();
                            String fechaMostrable = "Fecha";
                            if (d['fecha'] != null) fechaMostrable = d['fecha'].toString();
                            else if (d['fechaHora'] != null) fechaMostrable = d['fechaHora'].toString().split(' ').first;

                            return GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  barrierDismissible: true,
                                  builder: (ctx) => Dialog(
                                    backgroundColor: Colors.transparent, insetPadding: const EdgeInsets.all(20),
                                    child: Stack(
                                      alignment: Alignment.topRight,
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(color: kPopUpBackground, borderRadius: BorderRadius.circular(kPopUpRadius), border: Border.all(color: Colors.white12), boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 15, offset: Offset(0, 5))]),
                                          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                                            ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(kPopUpRadius)), child: SizedBox(height: kPopUpFotoHeight, child: Image.network(fotoLugar, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(color: Colors.grey[800], child: const Icon(Icons.broken_image, color: Colors.white54))))),
                                            Padding(padding: const EdgeInsets.all(20.0), child: Column(children: [
                                              Text(nombreLugar.toUpperCase(), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: kPopUpTitleSize, fontFamily: 'Poppins', height: 1.0)),
                                              const SizedBox(height: 4),
                                              Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.calendar_today, color: kPopUpIconColor, size: 16), const SizedBox(width: 5), Text("Fecha: $fechaMostrable", style: const TextStyle(color: Colors.white70, fontSize: kPopUpDateSize, height: 1.0))]),
                                            ])),
                                          ]),
                                        ),
                                        Padding(padding: const EdgeInsets.all(10.0), child: GestureDetector(onTap: () => Navigator.pop(ctx), child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 20)))),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Stack(fit: StackFit.expand, children: [
                                  Image.network(fotoLugar, fit: BoxFit.cover, errorBuilder: (_,__,___)=>Container(color: Colors.grey[800])),
                                  Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.95)], stops: const [0.5, 1.0]))),
                                  Positioned(bottom: 8, left: 8, right: 8, child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                                    Text(nombreLugar.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, fontFamily: 'Poppins', shadows: [Shadow(color: Colors.black, blurRadius: 4)])),
                                    Text(fechaMostrable, style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold)),
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

                  // 🔥 BOTÓN NUEVA CITA (PROTEGIDO)
                  if (_isLoadingStatus)
                    const Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(color: Colors.white))
                  else
                    GestureDetector(
                      onTap: _manejarClickNuevaCita,
                      child: Container(
                          width: double.infinity, height: 50,
                          decoration: BoxDecoration(
                              gradient: LinearGradient(colors: _isUserBlocked ? kBtnBlockedGradient : kBtnNuevaCitaGradient),
                              borderRadius: BorderRadius.circular(kButtonRadius),
                              boxShadow: kButtonShadow,
                              border: Border.all(color: Colors.white24, width: 0.5)
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isUserBlocked) ...[
                                const Icon(Icons.lock, color: Colors.white54, size: 16),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                  _isUserBlocked ? "CUENTA BLOQUEADA" : "NUEVA CITA CON TU MATCHY",
                                  style: TextStyle(
                                      color: _isUserBlocked ? Colors.white54 : Colors.black,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                      letterSpacing: 0.5
                                  )
                              ),
                            ],
                          )
                      ),
                    ),

                  const SizedBox(height: 20),

                  // BOTÓN DESCUENTOS
                  ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                          width: double.infinity, height: 55,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFF8C00)]), boxShadow: [BoxShadow(color: kGoldColor.withOpacity(0.6), blurRadius: 15)]),
                          child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: ()=>Navigator.push(context, MaterialPageRoute(builder: (_)=>const ZonaDeDescuentosScreen())),
                                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.stars_rounded, color: Colors.black), SizedBox(width: 10), Text("ZONA DE DESCUENTOS", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)), SizedBox(width: 10), Icon(Icons.stars_rounded, color: Colors.black)])
                              )
                          )
                      )
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