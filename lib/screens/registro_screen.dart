// 📂 lib/screens/registro_screen.dart
// ✅ Misma UI Matchy
// ✅ Botón REGISTRARSE ACTIVADO (email/password)
// ✅ Botones Google + Registro CENTRADOS en la mitad de la pantalla
// ✅ 🔴 CHINCHES de edición claros (posición, tamaño, espacios)
// ✅ Flujo intacto: Google / Email -> Datos o HomeShell

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // ==========================================================
  // 🔴 CHINCHE UI 1 — tamaño del logo
  // ==========================================================
  static const double logoHeight = 70;

  // ==========================================================
  // 🔴 CHINCHE UI 2 — espacio superior antes del logo
  // ==========================================================
  static const double topSpaceBeforeLogo = 60;

  // ==========================================================
  // 🔴 CHINCHE UI 3 — posición vertical del bloque de botones
  // 0.50 = centro exacto
  // 0.45 = un poco más arriba
  // 0.55 = un poco más abajo
  // ==========================================================
  static const double botonesVerticalFactor = 0.50;

  // ==========================================================
  // 🔴 CHINCHE UI 4 — altura de botones
  // ==========================================================
  static const double botonHeight = 52;

  // ==========================================================
  // 🔴 CHINCHE UI 5 — separación entre botones
  // ==========================================================
  static const double espacioEntreBotones = 16;

  static const String _kProfileDraftKey = 'matchy_profile_draft_v1';

  // ==========================================================
  // 🔹 NAVEGACIÓN
  // ==========================================================
  void _irADatos(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DatosScreen()),
    );
  }

  void _irHomeShellPanel(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeShell(initialIndex: 2)),
    );
  }

  // ==========================================================
  // 🔹 USER DOC
  // ==========================================================
  Future<void> _ensureUserDoc(User user, String provider) async {
    final ref = _db.collection('users').doc(user.uid);
    final snap = await ref.get();

    final data = <String, dynamic>{
      'uid': user.uid,
      'email': user.email,
      'provider': provider,
      'updatedAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
    };

    if (!snap.exists) {
      data['createdAt'] = FieldValue.serverTimestamp();
      data['onboarding_completed'] = false;
    }

    await ref.set(data, SetOptions(merge: true));
  }

  // ==========================================================
  // 🔹 PERFIL MÍNIMO
  // ==========================================================
  Future<bool> _perfilMinimoValidoLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kProfileDraftKey);
      if (raw == null || raw.isEmpty) return false;

      final map = jsonDecode(raw) as Map<String, dynamic>;

      final String nombre = (map['nombre'] ?? '').toString().trim();
      final int? edad = int.tryParse((map['edad'] ?? '').toString());
      final String pais = (map['paisSeleccionado'] ?? '').toString().trim();
      final String ciudad = (map['ciudadSeleccionada'] ?? '').toString().trim();
      final List fotos = (map['fotosCargadas'] ?? []) as List;

      return nombre.isNotEmpty &&
          edad != null &&
          edad >= 18 &&
          pais.isNotEmpty &&
          ciudad.isNotEmpty &&
          fotos.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // ==========================================================
  // 🔹 GOOGLE SIGN IN
  // ==========================================================
  Future<void> _signInWithGoogle(BuildContext context) async {
    if (_loading) return;
    setState(() => _loading = true);

    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final auth = await googleUser.authentication;
      final cred = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );

      final userCred = await _auth.signInWithCredential(cred);
      final user = userCred.user;
      if (user == null) throw Exception('Usuario nulo');

      await _ensureUserDoc(user, 'google');

      final ok = await _perfilMinimoValidoLocal();
      if (!mounted) return;

      ok ? _irHomeShellPanel(context) : _irADatos(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('❌ Error Google: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ==========================================================
  // 🔹 REGISTRO EMAIL/PASSWORD (ACTIVO)
  // ==========================================================
  Future<void> _signUpWithEmail(BuildContext context) async {
    if (_loading) return;
    setState(() => _loading = true);

    try {
      // 🔴 CHINCHE AUTH 1 — credenciales DEMO (puedes cambiarlas luego)
      final email = 'valentina@test.com';
      final password = '123456';

      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = cred.user;
      if (user == null) throw Exception('Usuario nulo');

      await _ensureUserDoc(user, 'email');

      if (!mounted) return;
      _irADatos(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('❌ Error registro: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ==========================================================
  // 🔹 UI
  // ==========================================================
  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover),
          ),
          Column(
            children: [
              SizedBox(height: topSpaceBeforeLogo),
              Image.asset(
                'assets/images/logo_matchy2.png',
                height: logoHeight,
              ),

              // 🔴 CHINCHE UI 6 — cálculo para centrar botones en pantalla
              SizedBox(height: h * botonesVerticalFactor - 120),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    SizedBox(
                      height: botonHeight,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                        _loading ? null : () => _signInWithGoogle(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: const StadiumBorder(),
                        ),
                        child: _loading
                            ? const SizedBox(
                          width: 22,
                          height: 22,
                          child:
                          CircularProgressIndicator(strokeWidth: 2),
                        )
                            : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/ic_google.png',
                              height: 24,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Sign up with Google',
                              style: TextStyle(color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: espacioEntreBotones),
                    SizedBox(
                      height: botonHeight,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                        _loading ? null : () => _signUpWithEmail(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6A5ACD),
                          shape: const StadiumBorder(),
                        ),
                        child: const Text(
                          'Registrarse',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
