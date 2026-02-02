// 📂 lib/screens/matchys_detalle_screen.dart
// ✅ DETALLE DE MATCHY (HISTORIAL FINAL + POP-UP COMPACTO)
// 🔥 FIX: Pop-up con textos compactos (height: 1.0) y sin aire extra.
// 🔥 CHINCHES: Nueva zona de configuración exclusiva para el Pop-up.
// 🔥 LOGIC: Mantiene la lectura correcta desde la colección 'citas'.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:proyectos_matchy/widgets/matchy_page_layout.dart';
import 'package:proyectos_matchy/screens/matchys_screen.dart';
import 'package:proyectos_matchy/screens/perfil_usuariox_screen.dart';
import 'package:proyectos_matchy/screens/cita_nueva_screen.dart';
import 'package:proyectos_matchy/screens/zona_de_descuentos_screen.dart';

class MatchysDetalleScreen extends StatefulWidget {
  final MatchyData matchyData;
  const MatchysDetalleScreen({super.key, required this.matchyData});
  @override State<MatchysDetalleScreen> createState() => _MatchysDetalleScreenState();
}

class _MatchysDetalleScreenState extends State<MatchysDetalleScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800), lowerBound: 0.95, upperBound: 1.05)..repeat(reverse: true);
    _scaleAnimation = _controller;
  }
  @override void dispose() { _controller.dispose(); super.dispose(); }

  // ===========================================================================
  // 🔴🔴 ZONA DE CHINCHES MAESTROS 🔴🔴
  // ===========================================================================

  // GENERAL
  static const double kFotoPerfilHeight = 350.0;
  static const double kHistorialHeight = 250.0;
  static const Color kCapsulaColor = Color(0x33FFFFFF);
  static const Color kGoldColor = Color(0xFFFFC107);
  static const List<Color> kBtnNuevaCitaGradient = [Color(0xFFBEB3FF), Color(0xFF8A80CC)];
  static const double kButtonRadius = 20.0;
  static const List<BoxShadow> kButtonShadow = [BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 4))];

  // 🔴 CHINCHES DEL POP-UP (ZOOM)
  static const Color kPopUpBackground = Color(0xFF0A3043); // Fondo oscuro
  static const double kPopUpRadius = 25.0; // Borde redondeado
  static const double kPopUpTitleSize = 22.0; // Tamaño Nombre Sitio
  static const double kPopUpDateSize = 21.0;  // Tamaño Fecha
  static const Color kPopUpIconColor = Color(0xFFBEB3FF); // Color ícono calendario
  static const double kPopUpFotoHeight = 250.0; // Altura foto zoom

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
                  // FOTO PERFIL GRANDE
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PerfilUsuarioXScreen(uid: widget.matchyData.uid))),
                    child: Container(
                      width: double.infinity, height: kFotoPerfilHeight,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 5))], border: Border.all(color: Colors.white24, width: 2)),
                      child: Stack(fit: StackFit.expand, children: [
                        ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: Image.network(
                                widget.matchyData.fotoUrl,
                                fit: BoxFit.cover,
                                alignment: Alignment.topCenter,
                                errorBuilder: (_,__,___) => Container(color: Colors.grey)
                            )
                        ),
                        Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.9)], stops: const [0.5, 1.0]))),
                        Positioned(bottom: 15, left: 0, right: 0, child: Column(children: [
                          Text(widget.matchyData.nombre.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, fontFamily: 'Poppins', shadows: [Shadow(color: Colors.black, blurRadius: 8, offset: Offset(0, 4))])),
                          Text("${widget.matchyData.edad} AÑOS", style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 2))])),
                        ])),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // TÍTULO
                  const Text("TU HISTORIAL CON TU MATCHY", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900, fontFamily: 'Poppins', shadows: [Shadow(color: Colors.black, blurRadius: 6, offset: Offset(0, 3))])),
                  const SizedBox(height: 4),

                  // 🔥 HISTORIAL FILTRADO
                  Container(
                    height: kHistorialHeight, padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: kCapsulaColor, borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.white10)),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('citas')
                          .orderBy('updatedAt', descending: true)
                          .snapshots(),
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
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.3
                          ),
                          itemCount: docs.length,
                          itemBuilder: (ctx, i) {
                            final d = docs[i].data() as Map<String, dynamic>;
                            final nombreLugar = (d['lugarNombre'] ?? 'Cita').toString();
                            final fotoLugar = (d['lugarFotoPortada'] ?? '').toString();

                            String fechaMostrable = "Fecha";
                            if (d['fecha'] != null) {
                              fechaMostrable = d['fecha'].toString();
                            } else if (d['fechaHora'] != null) {
                              fechaMostrable = d['fechaHora'].toString().split(' ').first;
                            }

                            return GestureDetector(
                              // 🔥 POP-UP CON CHINCHES Y TEXTO COMPACTO
                              onTap: () {
                                showDialog(
                                  context: context,
                                  barrierDismissible: true,
                                  builder: (ctx) => Dialog(
                                    backgroundColor: Colors.transparent,
                                    insetPadding: const EdgeInsets.all(20),
                                    child: Stack(
                                      alignment: Alignment.topRight,
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                              color: kPopUpBackground,
                                              borderRadius: BorderRadius.circular(kPopUpRadius),
                                              border: Border.all(color: Colors.white12),
                                              boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 15, offset: Offset(0, 5))]
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            children: [
                                              // FOTO POP-UP
                                              ClipRRect(
                                                borderRadius: const BorderRadius.vertical(top: Radius.circular(kPopUpRadius)),
                                                child: SizedBox(
                                                  height: kPopUpFotoHeight,
                                                  child: Image.network(fotoLugar, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(color: Colors.grey[800], child: const Icon(Icons.broken_image, color: Colors.white54))),
                                                ),
                                              ),

                                              // TEXTOS (FIX DE AIRE)
                                              Padding(
                                                padding: const EdgeInsets.all(20.0),
                                                child: Column(
                                                  children: [
                                                    Text(
                                                        nombreLugar.toUpperCase(),
                                                        textAlign: TextAlign.center,
                                                        maxLines: 2, // Por si es muy largo, máximo 2 líneas
                                                        overflow: TextOverflow.ellipsis,
                                                        style: const TextStyle(
                                                            color: Colors.white,
                                                            fontWeight: FontWeight.w900,
                                                            fontSize: kPopUpTitleSize,
                                                            fontFamily: 'Poppins',
                                                            height: 1.0 // 🔥 FIX: Elimina el aire vertical
                                                        )
                                                    ),
                                                    const SizedBox(height: 4), // 🔥 FIX: Espacio reducido
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        const Icon(Icons.calendar_today, color: kPopUpIconColor, size: 16),
                                                        const SizedBox(width: 5),
                                                        Text(
                                                            "Fecha: $fechaMostrable",
                                                            style: const TextStyle(
                                                                color: Colors.white70,
                                                                fontSize: kPopUpDateSize,
                                                                height: 1.0 // 🔥 FIX: Elimina el aire vertical
                                                            )
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(10.0),
                                          child: GestureDetector(
                                            onTap: () => Navigator.pop(ctx),
                                            child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 20)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.network(fotoLugar, fit: BoxFit.cover, errorBuilder: (_,__,___)=>Container(color: Colors.grey[800])),
                                    Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.95)], stops: const [0.5, 1.0]))),
                                    Positioned(
                                      bottom: 8, left: 8, right: 8,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(nombreLugar.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, fontFamily: 'Poppins', shadows: [Shadow(color: Colors.black, blurRadius: 4)])),
                                          Text(fechaMostrable, style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 25),

                  // BOTÓN NUEVA CITA
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(
                          builder: (_) => CitaNuevaScreen(
                            nombreUsuario: 'Yo',
                            nombreMatch: widget.matchyData.nombre,
                            fotoUsuario: '',
                            fotoMatch: widget.matchyData.fotoUrl,
                            matchyUidInvitado: widget.matchyData.uid,
                          )
                      ));
                    },
                    child: Container(
                        width: double.infinity, height: 50,
                        decoration: BoxDecoration(gradient: const LinearGradient(colors: kBtnNuevaCitaGradient), borderRadius: BorderRadius.circular(kButtonRadius), boxShadow: kButtonShadow, border: Border.all(color: Colors.white24, width: 0.5)),
                        alignment: Alignment.center,
                        child: const Text("NUEVA CITA CON TU MATCHY", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5))
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