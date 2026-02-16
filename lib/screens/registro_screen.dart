// 📂 lib/screens/registro_screen.dart
// ✅ PANTALLA DE ACCESO BLINDADA (DISTRIBUCIÓN CONTROLADA)
// 🔥 FIX: Botón Google al centro, Términos abajo, Logo arriba.
// 🔥 CONTROL: Sección "Chinches Maestros" para ajustar alturas sin romper el responsive.
// 🔥 UI: Diseño visual intacto.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:proyectos_matchy/screens/datos_screen.dart';
import 'package:proyectos_matchy/screens/home_shell.dart';

class RegistroScreen extends ConsumerStatefulWidget {
  const RegistroScreen({super.key});

  @override
  ConsumerState<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends ConsumerState<RegistroScreen> {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  bool _loading = false;
  String _statusMessage = "Continuar con Google";

  // ==========================================================
  // 🛡️ ZONA DE CHINCHES MAESTROS (CONTROL DE POSICIONES)
  // ==========================================================
  // Edita estos números para subir o bajar elementos.
  // Son "Fuerzas de Empuje" (Mayor número = Más espacio).

  static const int kFuerzaTecho = 2;  // Empuje desde arriba hacia el Logo
  static const int kFuerzaMedio = 1;  // Empuje entre Logo y Botón
  static const int kFuerzaSuelo = 3;  // Empuje desde abajo hacia el Texto

  static const double kLogoHeight = 70.0;     // Tamaño del Logo
  static const double kButtonHeight = 55.0;   // Altura del Botón
  static const double kButtonWidthPercent = 0.85; // Ancho del botón (85% de pantalla)
  static const double kEspacioBotonTexto = 15.0; // Separación fija entre botón y texto

  static const List<Shadow> kTextShadow = [
    Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 1))
  ];
  // ==========================================================

  void _irADatos(BuildContext context) {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DatosScreen()),
            (route) => false
    );
  }

  void _irHomeShellPanel(BuildContext context) {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeShell(initialIndex: 2)),
            (route) => false
    );
  }

  Future<bool> _autenticarYValidarContraFuego(User user) async {
    int intento = 0;
    while (true) {
      intento++;
      try {
        if (intento > 1) {
          if (mounted) setState(() => _statusMessage = "Asegurando conexión... ($intento)");
          await Future.delayed(const Duration(seconds: 2));
          await user.reload();
          await user.getIdToken(true);
        }

        final docSnapshot = await _db.collection('users').doc(user.uid).get(const GetOptions(source: Source.server));

        if (docSnapshot.exists) {
          await _db.collection('users').doc(user.uid).update({
            'lastLoginAt': FieldValue.serverTimestamp(),
          });
          final data = docSnapshot.data();
          return data?['onboarding_completed'] == true;
        } else {
          await _db.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'email': user.email,
            'nombre': user.displayName ?? '',
            'profilePhotoUrl': user.photoURL ?? '',
            'provider': 'google',
            'createdAt': FieldValue.serverTimestamp(),
            'onboarding_completed': false,
            'lastLoginAt': FieldValue.serverTimestamp(),
          });
          return false;
        }
      } catch (e) {
        debugPrint("⚠️ Intento $intento fallido. Error: $e");
        if (intento > 10) await Future.delayed(const Duration(seconds: 3));
      }
    }
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _statusMessage = "Cargando...";
    });

    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() { _loading = false; _statusMessage = "Continuar con Google"; });
        return;
      }

      final auth = await googleUser.authentication;
      final cred = GoogleAuthProvider.credential(accessToken: auth.accessToken, idToken: auth.idToken);

      final userCred = await _auth.signInWithCredential(cred);
      final user = userCred.user;
      if (user == null) throw Exception('Error crítico de autenticación.');

      if (mounted) setState(() => _statusMessage = "Verificando cuenta...");
      await user.getIdToken(true);
      final esUsuarioCompleto = await _autenticarYValidarContraFuego(user);

      if (esUsuarioCompleto) {
        _irHomeShellPanel(context);
      } else {
        _irADatos(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      setState(() { _loading = false; _statusMessage = "Reintentar"; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double buttonWidth = size.width * kButtonWidthPercent;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Fondo
          Positioned.fill(child: Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover)),

          // 2. Contenido Elástico
          SafeArea(
            child: SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // A. RESORTE TECHO: Empuja el logo hacia abajo
                  Spacer(flex: kFuerzaTecho),

                  // B. LOGO
                  Image.asset('assets/images/logo_matchy2.png', height: kLogoHeight),

                  // C. RESORTE MEDIO: Separa el Logo del Botón
                  Spacer(flex: kFuerzaMedio),

                  // D. GRUPO BOTÓN + TEXTO (Se mueven juntos)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: buttonWidth,
                        height: kButtonHeight,
                        child: ElevatedButton(
                          onPressed: _loading ? null : () => _signInWithGoogle(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                            elevation: 8,
                            shadowColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: _loading
                                  ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.purple)),
                                  const SizedBox(width: 15),
                                  Text(_statusMessage, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, shadows: kTextShadow)),
                                ],
                              )
                                  : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset('assets/images/ic_google.png', height: 24, errorBuilder: (_,__,___) => const Icon(Icons.login, color: Colors.grey)),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Continuar con Google',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Poppins', shadows: kTextShadow),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Separación pequeña fija entre botón y texto
                      const SizedBox(height: kEspacioBotonTexto),

                      // Texto de términos
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "Al continuar aceptas nuestros Términos y Condiciones",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11, shadows: kTextShadow),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // E. RESORTE SUELO: Empuja todo hacia arriba desde el fondo
                  Spacer(flex: kFuerzaSuelo),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}