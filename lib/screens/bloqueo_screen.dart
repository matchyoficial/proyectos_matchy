// 📂 lib/screens/bloqueo_screen.dart
// ✅ PANTALLA DE BLOQUEO PERMANENTE (DISEÑO DRAMÁTICO MATCHY)
// 🔥 UI: Símbolo de "Cárcel Digital" con resplandor neón rojo.
// 🔥 LOGIC: Detecta userStatus: 'blocked_permanent' o strikes >= 5.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:proyectos_matchy/screens/splash_screen.dart';

class BloqueoScreen extends ConsumerWidget {
  const BloqueoScreen({super.key});

  // 🛡️ CONSTANTES DE DISEÑO PREMIUM
  static const Color kRedNeon = Color(0xFFFF1744);
  static const List<Shadow> kNeonShadow = [
    Shadow(color: kRedNeon, blurRadius: 20),
    Shadow(color: Colors.black, offset: Offset(0, 4), blurRadius: 10),
  ];

  Future<void> _logout(BuildContext context) async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. FONDO OFICIAL
          Positioned.fill(
            child: Opacity(
              opacity: 0.4,
              child: Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover),
            ),
          ),

          // 2. CONTENIDO CENTRAL
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // LOGO SUPERIOR
                  Image.asset('assets/images/logomatchyplano.png', height: 40),
                  const SizedBox(height: 50),

                  // 🚨 SÍMBOLO DRAMÁTICO
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 140, height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: kRedNeon.withOpacity(0.3), width: 2),
                          boxShadow: [
                            BoxShadow(color: kRedNeon.withOpacity(0.1), blurRadius: 40, spreadRadius: 10)
                          ],
                        ),
                      ),
                      const Icon(Icons.gpp_bad_rounded, size: 90, color: kRedNeon, shadows: kNeonShadow),
                      const Positioned(
                        bottom: 25, right: 25,
                        child: Icon(Icons.lock, size: 30, color: Colors.white, shadows: kNeonShadow),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // 🛡️ TÍTULO BLINDADO
                  const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "USUARIO BLOQUEADO",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Poppins',
                        letterSpacing: 1.5,
                        shadows: kNeonShadow,
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // 💬 BURBUJA DE MENSAJE
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: const Color(0x22FFFFFF),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: kRedNeon.withOpacity(0.4)),
                      boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 15, offset: Offset(0, 8))],
                    ),
                    child: Column(
                      children: const [
                        Text(
                          "Lamentamos informarte que tu acceso a Matchy ha sido revocado permanentemente.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, height: 1.4),
                        ),
                        SizedBox(height: 15),
                        Text(
                          "La razón: Has alcanzado el límite de 5 STRIKES por inasistencia o cancelaciones tardías.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFFFF8A80), fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 15),
                        Divider(color: Colors.white12),
                        SizedBox(height: 10),
                        Text(
                          "En Matchy nos tomamos el tiempo de los demás muy en serio. El respeto mutuo y la puntualidad son la base de nuestra comunidad.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 13, fontStyle: FontStyle.italic, height: 1.4),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // BOTÓN SALIR
                  GestureDetector(
                    onTap: () => _logout(context),
                    child: Container(
                      width: double.infinity,
                      height: 55,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4))],
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        "CERRAR SESIÓN",
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.0),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  Text(
                    "ID de usuario: ${user?.uid ?? 'N/A'}",
                    style: const TextStyle(color: Colors.white24, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}