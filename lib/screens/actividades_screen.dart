// 📂 lib/screens/actividades_screen.dart
// ✅ ACTIVIDADES BLINDADO (ESTRATEGIA ADAPTATIVA + GEOLOCALIZACIÓN)
// 🔥 BLINDAJE: Texto de cabecera estandarizado a 16pt y protegido con FittedBox.
// 🔥 DATOS: Filtro estricto por Ciudad y País inyectado.
// 🔥 UI: Diseño Premium con cápsula y fade out inferior intactos.
// 🎯 NEW: modoSeleccionCita — se pasa hacia LugarPlantillaScreen; si vuelve un lugar elegido,
//    esta pantalla se cierra devolviéndolo también (relevo hacia intereses_citas_screen.dart).

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 🔥 Import agregado para leer al usuario
import 'package:proyectos_matchy/models/lugar_data.dart';
import 'package:proyectos_matchy/widgets/lugar_card.dart';
import 'package:proyectos_matchy/screens/lugar_plantilla_screen.dart';

class ActividadesScreen extends StatefulWidget {
  final String? matchyUidInvitado;
  final bool modoSeleccionCita; // 🎯 NUEVO

  const ActividadesScreen({
    super.key,
    this.matchyUidInvitado,
    this.modoSeleccionCita = false, // 🎯 NUEVO — default false, no rompe usos existentes
  });

  @override
  State<ActividadesScreen> createState() => _ActividadesScreenState();
}

class _ActividadesScreenState extends State<ActividadesScreen> {
  // 🛡️ CHINCHES MAESTROS (BLINDADOS)
  static const List<Color> kCapsulaGradient = [Color(0xFF2E2E4D), Color(0xFF1A1A24)];
  static const Color kBorderColor = Colors.white12;
  static const double kCapsulaRadius = 24.0;
  static const double kTitleSize = 16.0;
  static const double kCardGap = 2.0;

  String _userCiudad = 'Cali';
  String _userPais = 'Colombia';
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _fetchUserLocation();
  }

  // 🔥 LECTURA SILENCIOSA DE LA UBICACIÓN DEL USUARIO ACTUAL
  Future<void> _fetchUserLocation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (snap.exists && snap.data() != null) {
          if (mounted) {
            setState(() {
              _userCiudad = (snap.data()!['ciudad'] ?? 'Cali').toString();
              _userPais = (snap.data()!['pais'] ?? 'Colombia').toString();
              _isLoadingLocation = false;
            });
          }
          return;
        }
      } catch (_) {}
    }
    if (mounted) {
      setState(() => _isLoadingLocation = false);
    }
  }

  // 🎯 NUEVO: maneja el tap de una tarjeta, con o sin modo selección
  Future<void> _onLugarTap(LugarData lugar) async {
    if (widget.modoSeleccionCita) {
      final resultado = await Navigator.of(context).push<LugarData>(
        MaterialPageRoute(
          builder: (_) => LugarPlantillaScreen(
            lugar: lugar,
            matchyUidInvitado: widget.matchyUidInvitado,
            modoSeleccionCita: true,
          ),
        ),
      );
      if (resultado != null && mounted) {
        Navigator.of(context).pop(resultado);
      }
      return;
    }

    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => LugarPlantillaScreen(
            lugar: lugar,
            matchyUidInvitado: widget.matchyUidInvitado
        )
    ));
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
                                  'ACTIVIDADES',
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
                // 🔥 ESPERA A TENER EL GPS PARA CARGAR
                child: _isLoadingLocation
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFFBEB3FF)))
                    : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  // 🔒 LOS NUEVOS CANDADOS: Filtro por Ciudad y País inyectado
                  stream: FirebaseFirestore.instance
                      .collection('lugares')
                      .where('tipos', arrayContains: 'actividad')
                      .where('activo', isEqualTo: true)
                      .where('pais', isEqualTo: _userPais)
                      .where('ciudad', isEqualTo: _userCiudad)
                      .orderBy('orden')
                      .snapshots(),
                  builder: (context, snap) {
                    if (snap.hasError) return const Center(child: Text("Error de carga", style: TextStyle(color: Colors.white54)));
                    if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: Colors.white));

                    final docs = snap.data!.docs;

                    if (docs.isEmpty) {
                      return const Center(child: Text("No hay actividades en tu ciudad", style: TextStyle(color: Colors.white54, fontFamily: 'Poppins')));
                    }

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
                              onTap: () => _onLugarTap(lugar),
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