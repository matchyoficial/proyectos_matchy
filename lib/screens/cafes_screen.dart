// 📂 lib/screens/cafes_screen.dart
// ✅ CAFÉS BLINDADO (ESTRATEGIA ADAPTATIVA)
// 🔥 BLINDAJE: Texto de cabecera estandarizado a 16pt y protegido con FittedBox.
// 🔥 UI: Diseño Premium con cápsula azul oscuro y fade out inferior intactos.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proyectos_matchy/models/lugar_data.dart';
import 'package:proyectos_matchy/widgets/lugar_card.dart';
import 'package:proyectos_matchy/screens/lugar_plantilla_screen.dart';

class CafesScreen extends StatelessWidget {
  final String? matchyUidInvitado; // 🟢 DATO OPCIONAL
  const CafesScreen({super.key, this.matchyUidInvitado});

  // 🛡️ CHINCHES MAESTROS (BLINDADOS)
  static const List<Color> kCapsulaGradient = [Color(0xFF2E2E4D), Color(0xFF1A1A24)];
  static const Color kBorderColor = Colors.white12;
  static const double kCapsulaRadius = 24.0;
  static const double kTitleSize = 16.0; // Estandarizado a 16pt
  static const double kCardGap = 2.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. FONDO
          Positioned.fill(child: Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover)),

          Column(
            children: [
              const SizedBox(height: 35),
              Image.asset('assets/images/logomatchyplano.png', height: 45),
              const SizedBox(height: 15),

              // 2. CABECERA CÁPSULA PREMIUM BLINDADA
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: kCapsulaGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight
                      ),
                      borderRadius: BorderRadius.circular(kCapsulaRadius),
                      border: Border.all(color: kBorderColor, width: 1),
                      boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 5))]
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                              width: 40, height: 40,
                              decoration: const BoxDecoration(color: Colors.white10, shape: BoxShape.circle),
                              child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18)
                          )
                      ),

                      // BLINDAJE: Texto adaptativo a 16pt
                      const Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                  'CAFÉS',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: kTitleSize,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.2,
                                      fontFamily: 'Poppins'
                                  )
                              ),
                            ),
                          )
                      ),

                      const SizedBox(width: 40),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('lugares')
                      .where('tipos', arrayContains: 'cafe')
                      .where('activo', isEqualTo: true)
                      .orderBy('orden')
                      .snapshots(),
                  builder: (context, snap) {
                    if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: Colors.white));
                    final docs = snap.data!.docs;

                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 120),
                      child: Column(
                        children: List.generate(docs.length, (index) {
                          final d = docs[index];
                          final lugar = LugarData.fromMap(id: d.id, data: d.data());
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: kCardGap),
                            child: LugarCard(
                              lugar: lugar,
                              altoTarjeta: index == 0 ? 150 : 170,
                              onTap: () {
                                // 🟢 PASAMOS EL DATO (Si existe)
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (_) => LugarPlantillaScreen(
                                        lugar: lugar,
                                        matchyUidInvitado: matchyUidInvitado
                                    )
                                ));
                              },
                            ),
                          );
                        }),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // 3. FADE OUT INFERIOR
          Positioned(
              bottom: 0, left: 0, right: 0, height: 80,
              child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withOpacity(0.95)]
                      )
                  )
              )
          ),
        ],
      ),
    );
  }
}