// 📂 lib/screens/matchys_screen.dart
// ✅ MATCHYS SCREEN BLINDADA (ESTRATEGIA ADAPTATIVA)
// 🔥 FIX: Nombres y botones adaptativos que nunca desbordan.
// 🔥 UI: Títulos estandarizados a 20pt.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:proyectos_matchy/widgets/matchy_page_layout.dart';

// IMPORTS DE NAVEGACIÓN
import 'package:proyectos_matchy/screens/cita_nueva_screen.dart';
import 'package:proyectos_matchy/screens/matchys_detalle_screen.dart';
import 'package:proyectos_matchy/screens/perfil_usuariox_screen.dart';
import 'package:proyectos_matchy/widgets/foto_perfil_usuario.dart';

// 🔵 MODELO DE DATOS MATCHY (MANTENIDO)
class MatchyData {
  final String uid;
  final String nombre;
  final int edad;
  final String fotoUrl;
  final String matchId;

  const MatchyData({
    required this.uid,
    required this.nombre,
    required this.edad,
    required this.fotoUrl,
    required this.matchId,
  });
}

// 🔵 PROVIDERS (MANTENIDOS)
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

final currentUserStatusProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return const Stream.empty();

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((doc) {
    final data = doc.data();
    return {
      'userStatus': data?['userStatus'] ?? 'active',
      'strikes': data?['strikes'] ?? 0,
      'bloqueadoHasta': data?['bloqueadoHasta'],
    };
  });
});

class MatchysScreen extends ConsumerWidget {
  final bool showBottomNav;

  const MatchysScreen({super.key, this.showBottomNav = true});

  // ===========================================================================
  // 🛡️ ZONA DE CHINCHES MAESTROS (BLINDADA)
  // ===========================================================================
  static const double kSpacePhotoToButtons = 8.0;
  static const double kSpaceBetweenButtons = 6.0;
  static const double kButtonFontSize = 13.0; // Reducido 1pt para blindaje preventivo
  static const double kButtonHeight = 34.0;

  static const List<Color> kBtnNewCitaGradient = [Color(0xFFBEB3FF), Color(0xFF8A80CC)];
  static const List<Color> kBtnHistorialGradient = [Color(0xFF7A43BF), Color(0xFF4A238F)];
  static const List<Color> kBtnBlockedGradient = [Color(0xFF424242), Color(0xFF212121)];

  static const double kButtonRadius = 18.0;
  static const List<BoxShadow> kButtonShadow = [
    BoxShadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2))
  ];
  // ===========================================================================

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncMatchys = ref.watch(myMatchysProvider);
    final asyncStatus = ref.watch(currentUserStatusProvider);

    bool isBlocked = false;
    int strikes = 0;

    asyncStatus.whenData((data) {
      final status = data['userStatus'].toString();
      final bloqueadoHasta = data['bloqueadoHasta'] as Timestamp?;
      strikes = (data['strikes'] as num?)?.toInt() ?? 0;

      if (status == 'blocked') isBlocked = true;
      if (bloqueadoHasta != null && bloqueadoHasta.toDate().isAfter(DateTime.now())) isBlocked = true;
    });

    return Scaffold(
      body: Stack(
        children: [
          MatchyPageLayout(
            backgroundAsset: 'assets/images/fondo.jpg',
            logoAsset: 'assets/images/logomatchyplano.png',
            topSpacing: 35,
            logoHeight: 45,
            spaceLogoToScroll: 15,
            scrollContent: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // BLINDAJE TÍTULO: Adaptativo + Fuente 20pt (Regla de Oro)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: const Text(
                      'MIS MATCHYS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20, // Estandarizado
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Poppins',
                        letterSpacing: 1.0,
                        shadows: [Shadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4))],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

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
                        fontSize: 12, // Ajustado ligeramente para aire
                        fontWeight: FontWeight.w900,
                        height: 1.3,
                        shadows: [Shadow(color: Colors.black, blurRadius: 2, offset: Offset(0, 1))],
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

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

                      return GridView.builder(
                        padding: const EdgeInsets.only(bottom: 120),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 20,
                          childAspectRatio: 0.52, // Ajustado ligeramente para dar espacio a botones adaptativos
                        ),
                        itemCount: matchys.length,
                        itemBuilder: (context, index) {
                          return _MatchyCard(
                              data: matchys[index],
                              isBlocked: isBlocked,
                              strikes: strikes
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
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
        ],
      ),
    );
  }
}

class _MatchyCard extends StatelessWidget {
  final MatchyData data;
  final bool isBlocked;
  final int strikes;

  const _MatchyCard({required this.data, required this.isBlocked, required this.strikes});

  void _manejarClickCrearCita(BuildContext context) {
    if (isBlocked) {
      final dias = strikes * 5;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.lock_outline, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(child: Text(
                    "BLOQUEADO.\nTienes $strikes strike(s). Resuelve tus pendientes.",
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
                    bottom: 12, left: 8, right: 8,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // BLINDAJE NOMBRE: Adaptativo para que no rompa la foto
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            data.nombre.toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, fontFamily: 'Poppins'),
                          ),
                        ),
                        Text(
                          "${data.edad} AÑOS",
                          style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: MatchysScreen.kSpacePhotoToButtons),

        _PremiumButton(
          text: "CREAR NUEVA CITA",
          gradient: isBlocked ? MatchysScreen.kBtnBlockedGradient : MatchysScreen.kBtnNewCitaGradient,
          icon: isBlocked ? Icons.lock : null,
          textColor: isBlocked ? Colors.white54 : Colors.black,
          fontSize: MatchysScreen.kButtonFontSize,
          height: MatchysScreen.kButtonHeight,
          onTap: () => _manejarClickCrearCita(context),
        ),

        const SizedBox(height: MatchysScreen.kSpaceBetweenButtons),

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

class _PremiumButton extends StatelessWidget {
  final String text;
  final List<Color> gradient;
  final Color textColor;
  final VoidCallback onTap;
  final double fontSize;
  final double height;
  final IconData? icon;

  const _PremiumButton({
    required this.text,
    required this.gradient,
    required this.textColor,
    required this.onTap,
    required this.fontSize,
    required this.height,
    this.icon,
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
        padding: const EdgeInsets.symmetric(horizontal: 4),
        // BLINDAJE BOTÓN: Texto adaptativo (Nunca se sale del botón)
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: textColor, size: 12),
                const SizedBox(width: 4),
              ],
              Text(
                text,
                style: TextStyle(
                    color: textColor,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}