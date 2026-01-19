import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proyectos_matchy/models/lugar_data.dart';
import 'package:proyectos_matchy/widgets/lugar_card.dart';
import 'package:proyectos_matchy/screens/lugar_plantilla_screen.dart';

class BaresScreen extends StatelessWidget {
  final String? matchyUidInvitado; // 🟢 DATO OPCIONAL
  const BaresScreen({super.key, this.matchyUidInvitado});

  static const List<Color> kCapsulaGradient = [Color(0xFF2E2E4D), Color(0xFF1A1A24)];
  static const Color kBorderColor = Colors.white12;
  static const double kCapsulaRadius = 24.0;
  static const double kTitleSize = 16.0;
  static const double kCardGap = 2.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover)),
          Column(
            children: [
              const SizedBox(height: 35),
              Image.asset('assets/images/logomatchyplano.png', height: 45),
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  decoration: BoxDecoration(gradient: const LinearGradient(colors: kCapsulaGradient, begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(kCapsulaRadius), border: Border.all(color: kBorderColor, width: 1), boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 5))]),
                  child: Row(
                    children: [
                      GestureDetector(onTap: () => Navigator.pop(context), child: Container(width: 40, height: 40, decoration: const BoxDecoration(color: Colors.white10, shape: BoxShape.circle), child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18))),
                      const Expanded(child: Text('BARES', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: kTitleSize, fontWeight: FontWeight.w900, letterSpacing: 1.2, fontFamily: 'Poppins'))),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance.collection('lugares').where('tipos', arrayContains: 'bar').where('activo', isEqualTo: true).orderBy('orden').snapshots(),
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
                                Navigator.of(context).push(MaterialPageRoute(builder: (_) => LugarPlantillaScreen(lugar: lugar, matchyUidInvitado: matchyUidInvitado)));
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
          Positioned(bottom: 0, left: 0, right: 0, height: 80, child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.95)])))),
        ],
      ),
    );
  }
}