// 📂 lib/screens/matchys_screen.dart
// ✅ MATCHYS SCREEN (FOTO PERFIL INTELIGENTE + DISEÑO AJUSTABLE)
// 🔥 FIX: Implementado 'FotoPerfilUsuario' en la tarjeta del Matchy.
// 🔥 UI: Botones Premium y Chinches Maestros intactos.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:proyectos_matchy/widgets/matchy_page_layout.dart';

// IMPORTS DE NAVEGACIÓN
import 'package:proyectos_matchy/screens/cita_nueva_screen.dart';
import 'package:proyectos_matchy/screens/matchys_detalle_screen.dart';
import 'package:proyectos_matchy/screens/perfil_usuariox_screen.dart';
import 'package:proyectos_matchy/widgets/foto_perfil_usuario.dart'; // 👈 WIDGET NUEVO

// 🔵 MODELO DE DATOS MATCHY
class MatchyData {
  final String uid;       // El UID de la otra persona
  final String nombre;    // Su nombre para mostrar
  final int edad;         // Su edad
  final String fotoUrl;   // Su foto principal
  final String matchId;   // El ID de la conexión global

  const MatchyData({
    required this.uid,
    required this.nombre,
    required this.edad,
    required this.fotoUrl,
    required this.matchId,
  });
}

// 🔵 PROVIDER
final myMatchysProvider = StreamProvider<List<MatchyData>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return const Stream.empty();

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('my_matchys')
      .orderBy('lastInteraction', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return MatchyData(
        uid: doc.id,
        nombre: data['nombre'] ?? 'Sin Nombre',
        edad: (data['edad'] is int) ? data['edad'] : int.tryParse(data['edad'].toString()) ?? 0,
        fotoUrl: data['fotoUrl'] ?? '',
        matchId: data['matchId'] ?? '',
      );
    }).toList();
  });
});

class MatchysScreen extends ConsumerWidget {
  final bool showBottomNav;

  const MatchysScreen({super.key, this.showBottomNav = true});

  // ===========================================================================
  // 🔴🔴 ZONA DE CHINCHES MAESTROS (CONTROL TOTAL) 🔴🔴
  // ===========================================================================

  // 1. DISTANCIAS (Sube o baja los botones)
  static const double kSpacePhotoToButtons = 8.0;   // Distancia entre Foto y 1er Botón (Menos es más cerca)
  static const double kSpaceBetweenButtons = 6.0;   // Distancia entre los dos botones

  // 2. TAMAÑO DE TEXTO (Agrande o achica títulos de botones)
  static const double kButtonFontSize = 14.0;       // Tamaño de la fuente

  // 3. TAMAÑO DE BOTÓN
  static const double kButtonHeight = 34.0;         // Altura de los botones (Más compactos)

  // 4. ESTILOS PREMIUM
  static const List<Color> kBtnNewCitaGradient = [Color(0xFFBEB3FF), Color(0xFF8A80CC)]; // Lila Claro
  static const List<Color> kBtnHistorialGradient = [Color(0xFF7A43BF), Color(0xFF4A238F)]; // Morado Oscuro
  static const double kButtonRadius = 18.0;
  static const List<BoxShadow> kButtonShadow = [
    BoxShadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2))
  ];
  // ===========================================================================

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncMatchys = ref.watch(myMatchysProvider);

    return Scaffold(
      body: Stack(
        children: [
          // 1. Contenido Principal
          MatchyPageLayout(
            backgroundAsset: 'assets/images/fondo.jpg',
            logoAsset: 'assets/images/logomatchyplano.png',
            topSpacing: 35,
            logoHeight: 45, // Ajustado a 45 como pediste
            spaceLogoToScroll: 15,
            scrollContent: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // TÍTULO GRANDE
                  const Text(
                    'MIS MATCHYS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Poppins',
                      letterSpacing: 1.0,
                      shadows: [Shadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4))],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // SUBTÍTULO MOTIVACIONAL
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Text(
                      'ESTOS SON TUS MATCHYS\n¡ANÍMATE A HACER UNA NUEVA CITA Y ACCEDE A DESCUENTOS EN TU PRÓXIMA SALIDA!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        height: 1.4,
                        shadows: [Shadow(color: Colors.black, blurRadius: 2, offset: Offset(0, 1))],
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // GRID DE MATCHYS
                  asyncMatchys.when(
                    loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
                    error: (e, __) => Center(child: Text("Error: $e", style: const TextStyle(color: Colors.white))),
                    data: (matchys) {
                      if (matchys.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.only(top: 50),
                          child: Text(
                            "Aún no tienes matchys.\n¡Empieza a deslizar!",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white54, fontSize: 16),
                          ),
                        );
                      }

                      // GRID 2 COLUMNAS
                      return GridView.builder(
                        padding: const EdgeInsets.only(bottom: 120), // Espacio para Fade Out
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 20,
                          childAspectRatio: 0.55, // Ajustado para que quepan los botones
                        ),
                        itemCount: matchys.length,
                        itemBuilder: (context, index) {
                          return _MatchyCard(data: matchys[index]);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // 2. 🔥 DEGRADADO INFERIOR (FADE OUT)
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
        ],
      ),
      bottomNavigationBar: null,
    );
  }
}

// 🔵 TARJETA CON 2 BOTONES
class _MatchyCard extends StatelessWidget {
  final MatchyData data;

  const _MatchyCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. FOTO + INFO (Ocupa el espacio restante)
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PerfilUsuarioXScreen(uid: data.uid),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 4))],
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    // 🔥 AQUÍ ESTÁ EL CAMBIO: Usamos FotoPerfilUsuario
                    child: FotoPerfilUsuario(
                      uid: data.uid,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
                        stops: const [0.5, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12, left: 0, right: 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          data.nombre.toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, fontFamily: 'Poppins'),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "${data.edad} AÑOS",
                          style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // 🔥 CHINCHE 1: Distancia Foto -> Botones
        const SizedBox(height: MatchysScreen.kSpacePhotoToButtons),

        // 2. BOTÓN "CREAR NUEVA CITA" (PREMIUM)
        _PremiumButton(
          text: "CREAR NUEVA CITA",
          gradient: MatchysScreen.kBtnNewCitaGradient,
          textColor: Colors.black, // Letra negra para contraste
          fontSize: MatchysScreen.kButtonFontSize,
          height: MatchysScreen.kButtonHeight,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CitaNuevaScreen(
                  nombreUsuario: 'YO',
                  nombreMatch: data.nombre,
                  fotoUsuario: '',
                  fotoMatch: data.fotoUrl,
                  matchyUidInvitado: data.uid,
                ),
              ),
            );
          },
        ),

        // 🔥 CHINCHE 2: Distancia entre botones
        const SizedBox(height: MatchysScreen.kSpaceBetweenButtons),

        // 3. BOTÓN "TU HISTORIAL" (PREMIUM)
        _PremiumButton(
          text: "TU HISTORIAL",
          gradient: MatchysScreen.kBtnHistorialGradient,
          textColor: Colors.white,
          fontSize: MatchysScreen.kButtonFontSize,
          height: MatchysScreen.kButtonHeight,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MatchysDetalleScreen(matchyData: data),
              ),
            );
          },
        ),
      ],
    );
  }
}

// 🔥 WIDGET REUTILIZABLE: BOTÓN PREMIUM AJUSTABLE
class _PremiumButton extends StatelessWidget {
  final String text;
  final List<Color> gradient;
  final Color textColor;
  final VoidCallback onTap;
  final double fontSize;
  final double height;

  const _PremiumButton({
    required this.text,
    required this.gradient,
    required this.textColor,
    required this.onTap,
    required this.fontSize,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradient),
          borderRadius: BorderRadius.circular(MatchysScreen.kButtonRadius),
          boxShadow: MatchysScreen.kButtonShadow,
          border: Border.all(color: Colors.white24, width: 0.5),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
              color: textColor,
              fontSize: fontSize, // 🔥 Controlado por chinche
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5
          ),
        ),
      ),
    );
  }
}