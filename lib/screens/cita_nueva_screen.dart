// 📂 lib/screens/cita_nueva_screen.dart
// ✅ PANTALLA CITA NUEVA (FINAL + FOTO INTELIGENTE)
// 🔥 FIX: Implementado 'FotoPerfilUsuario' para actualizar fotos en tiempo real.
// 🔥 FIX: 'Lugares Populares' usa la lógica original (LugarCard + Firebase 'popular').
// 🔥 LOGIC: Acepta 'matchyUidInvitado' y lo pasa a las categorías y lugares.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:proyectos_matchy/state/profile_form_provider.dart';
import 'package:proyectos_matchy/models/lugar_data.dart';
import 'package:proyectos_matchy/widgets/lugar_card.dart';
import 'package:proyectos_matchy/widgets/foto_perfil_usuario.dart'; // 👈 WIDGET NUEVO

// PANTALLAS DESTINO
import 'package:proyectos_matchy/screens/restaurantes_screen.dart';
import 'package:proyectos_matchy/screens/bares_screen.dart';
import 'package:proyectos_matchy/screens/cafes_screen.dart';
import 'package:proyectos_matchy/screens/actividades_screen.dart';
import 'package:proyectos_matchy/screens/zona_de_descuentos_screen.dart';
import 'package:proyectos_matchy/screens/lugar_plantilla_screen.dart';

class CitaNuevaScreen extends ConsumerWidget {
  final String nombreUsuario;
  final String nombreMatch;
  final String fotoUsuario;
  final String fotoMatch;

  // 🟢 EL PAQUETE SECRETO (Dato Fantasma)
  final String? matchyUidInvitado;

  const CitaNuevaScreen({
    super.key,
    required this.nombreUsuario,
    required this.nombreMatch,
    required this.fotoUsuario,
    required this.fotoMatch,
    this.matchyUidInvitado,
  });

  String _nombreSeguro(String raw) {
    final clean = raw.trim();
    if (clean.isEmpty) return 'TU';
    final parts = clean.split(RegExp(r'\s+'));
    return parts.isNotEmpty ? parts.first.toUpperCase() : 'TU';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileFormProvider);
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    final String? fotoProvider = profile.fotosCargadas.isNotEmpty ? profile.fotosCargadas.first : null;
    final String fotoUserFinal = fotoProvider ?? (fotoUsuario.isNotEmpty ? fotoUsuario : 'assets/images/perfil1.jpg');

    final String nombreUserFinal = profile.nombre.isNotEmpty ? _nombreSeguro(profile.nombre) : _nombreSeguro(nombreUsuario);
    final String nombreMatchFinal = _nombreSeguro(nombreMatch);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Fondo
          Positioned.fill(child: Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover)),

          // 2. Contenido
          Column(
            children: [
              const SizedBox(height: 35),
              Image.asset('assets/images/logomatchyplano.png', height: 45),
              const SizedBox(height: 23),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 120),
                  child: Column(
                    children: [
                      // Header Fotos (Con Widget Inteligente)
                      _HeaderFotos(
                        fotoUser: fotoUserFinal, // Foto local si existe
                        nombreUser: nombreUserFinal,
                        userUid: myUid, // UID para buscar foto real si no hay local

                        fotoMatch: fotoMatch, // Foto fallback
                        nombreMatch: nombreMatchFinal,
                        matchUid: matchyUidInvitado, // UID del matchy
                      ),

                      const SizedBox(height: 20),

                      // Texto "¿A Dónde?"
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            children: [
                              const TextSpan(
                                text: "¿A DÓNDE QUIERES TU CITA CON\n",
                                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600, fontFamily: 'Poppins', height: 1.2),
                              ),
                              TextSpan(
                                text: nombreMatch.toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, fontFamily: 'Poppins', letterSpacing: 1.0, height: 1.2),
                              ),
                              const TextSpan(text: "?", style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      // Botón Descuentos
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: _BotonDescuentosAnimado(),
                      ),

                      const SizedBox(height: 30),

                      // Grid Categorías (Pasa el dato)
                      _GridCategorias(matchyUidInvitado: matchyUidInvitado),

                      const SizedBox(height: 30),

                      // Lugares Populares (CONECTADO A FIREBASE CORRECTAMENTE)
                      _LugaresPopularesList(matchyUidInvitado: matchyUidInvitado),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Degradado Inferior
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

          // Botón Atrás
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

// ===============================================================
// 🔹 HEADER FOTOS (ACTUALIZADO)
// ===============================================================
class _HeaderFotos extends StatelessWidget {
  final String fotoUser, nombreUser;
  final String fotoMatch, nombreMatch;
  final String? userUid, matchUid;

  const _HeaderFotos({
    required this.fotoUser, required this.nombreUser, this.userUid,
    required this.fotoMatch, required this.nombreMatch, this.matchUid,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildCapsula(fotoUser, nombreUser, uid: userUid),
        const SizedBox(width: 20),
        _buildCapsula(fotoMatch, nombreMatch, uid: matchUid),
      ],
    );
  }

  Widget _buildCapsula(String pathFallback, String nombre, {String? uid}) {
    return Container(
      width: 110, height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 5))],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
              borderRadius: BorderRadius.circular(20),
              // 🔥 USAMOS EL WIDGET SI TENEMOS UID
              child: uid != null
                  ? FotoPerfilUsuario(uid: uid, fit: BoxFit.cover, alignment: Alignment.topCenter)
                  : _SafeImage(path: pathFallback)
          ),
          Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.9)], stops: const [0.6, 1.0]))),
          Positioned(bottom: 15, left: 0, right: 0, child: Text(nombre, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800, fontFamily: 'Poppins'))),
        ],
      ),
    );
  }
}

// ===============================================================
// 🔹 BOTÓN DESCUENTOS
// ===============================================================
class _BotonDescuentosAnimado extends StatefulWidget {
  const _BotonDescuentosAnimado();
  @override
  State<_BotonDescuentosAnimado> createState() => _BotonDescuentosAnimadoState();
}

class _BotonDescuentosAnimadoState extends State<_BotonDescuentosAnimado> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800), lowerBound: 0.96, upperBound: 1.04)..repeat(reverse: true);
    _scaleAnimation = _controller;
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: double.infinity, height: 55,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFF8C00)], begin: Alignment.topLeft, end: Alignment.bottomRight), boxShadow: [BoxShadow(color: const Color(0xFFFFC107).withOpacity(0.6), blurRadius: 15, spreadRadius: 2, offset: const Offset(0, 0))]),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ZonaDeDescuentosScreen())),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.stars_rounded, color: Colors.black, size: 28), SizedBox(width: 10), Text("ZONA DE DESCUENTOS", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 18, fontFamily: 'Poppins')), SizedBox(width: 10), Icon(Icons.stars_rounded, color: Colors.black, size: 28)]),
          ),
        ),
      ),
    );
  }
}

// ===============================================================
// 🔹 GRID CATEGORÍAS
// ===============================================================
class _GridCategorias extends StatelessWidget {
  final String? matchyUidInvitado;
  const _GridCategorias({this.matchyUidInvitado});

  @override
  Widget build(BuildContext context) {
    const double cardHeight = 110;
    const double gap = 12;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(children: [
            Expanded(child: _CatCard("RESTAURANTES", "assets/images/iconorestaurante.png", cardHeight, () => Navigator.push(context, MaterialPageRoute(builder: (_) => RestaurantesScreen(matchyUidInvitado: matchyUidInvitado))))),
            const SizedBox(width: gap),
            Expanded(child: _CatCard("BARES", "assets/images/iconobares.png", cardHeight, () => Navigator.push(context, MaterialPageRoute(builder: (_) => BaresScreen(matchyUidInvitado: matchyUidInvitado))))),
          ]),
          const SizedBox(height: gap),
          Row(children: [
            Expanded(child: _CatCard("CAFÉS", "assets/images/iconocafeteria.png", cardHeight, () => Navigator.push(context, MaterialPageRoute(builder: (_) => CafesScreen(matchyUidInvitado: matchyUidInvitado))))),
            const SizedBox(width: gap),
            Expanded(child: _CatCard("ACTIVIDADES", "assets/images/iconoactividades.png", cardHeight, () => Navigator.push(context, MaterialPageRoute(builder: (_) => ActividadesScreen(matchyUidInvitado: matchyUidInvitado))))),
          ]),
        ],
      ),
    );
  }

  Widget _CatCard(String title, String asset, double h, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Stack( // 🔥 TÍTULO ENCIMA DE LA FOTO
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            height: h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 4))],
              image: DecorationImage(image: AssetImage(asset), fit: BoxFit.cover),
            ),
          ),
          // Sombra para legibilidad
          Container(
            height: h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.7)], stops: const [0.6, 1.0]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, shadows: [Shadow(color: Colors.black, blurRadius: 4)])),
          ),
        ],
      ),
    );
  }
}

// ===============================================================
// 🔥 LUGARES POPULARES (LÓGICA ORIGINAL RESTAURADA)
// ===============================================================
class _LugaresPopularesList extends StatelessWidget {
  final String? matchyUidInvitado;
  const _LugaresPopularesList({this.matchyUidInvitado});

  @override
  Widget build(BuildContext context) {
    const double alturaLugarPopular = 150;

    return Column(
      children: [
        const Text(
            "LUGARES MÁS POPULARES",
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)
        ),
        const SizedBox(height: 14),

        // 🔥 STREAM BUILDER ORIGINAL (CORRECTO)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('lugares')
                .where('popular', isGreaterThan: 0) // 🔥 Filtro original
                .orderBy('popular')                 // 🔥 Orden original
                .snapshots(),
            builder: (context, snap) {
              if (snap.hasError) {
                return const Text("Error cargando populares", style: TextStyle(color: Colors.white54));
              }
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              }

              final docs = snap.data!.docs;
              if (docs.isEmpty) {
                return const Text("No hay lugares populares activos.", style: TextStyle(color: Colors.white54));
              }

              return Column(
                children: List.generate(docs.length, (index) {
                  final lugar = LugarData.fromMap(
                    id: docs[index].id,
                    data: docs[index].data(),
                  );

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    // 🔥 USAMOS EL WIDGET LugarCard ORIGINAL
                    child: LugarCard(
                      lugar: lugar,
                      altoTarjeta: alturaLugarPopular,
                      onTap: () {
                        // 🔥 PASAMOS EL DATO AL CLICK
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LugarPlantillaScreen(
                              lugar: lugar,
                              matchyUidInvitado: matchyUidInvitado,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ===============================================================
// 🔹 UTILIDAD IMAGEN
// ===============================================================
class _SafeImage extends StatelessWidget {
  final String path;
  const _SafeImage({required this.path});
  @override
  Widget build(BuildContext context) {
    final p = path.trim();
    if (p.startsWith('http')) return Image.network(p, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(color: Colors.grey));
    if (File(p).existsSync()) return Image.file(File(p), fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(color: Colors.grey));
    return Image.asset(p.isNotEmpty ? p : 'assets/images/perfil1.jpg', fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(color: Colors.grey));
  }
}