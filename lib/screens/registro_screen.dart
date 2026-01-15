// 📂 lib/screens/registro_screen.dart
// ✅ Misma UI
// ✅ Tras login Google, si perfil mínimo OK -> HomeShell(PANEL), si no -> Datos

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:proyectos_matchy/screens/datos_screen.dart';

// 🔴 CHINCHE SHELL REG 1
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

  static const double logoHeight = 70;
  static const double topSpaceBeforeLogo = 60;
  static const double offsetBotones = 0.18;

  static const String _kProfileDraftKey = 'matchy_profile_draft_v1';

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

  Future<bool> _perfilMinimoValidoLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kProfileDraftKey);
      if (raw == null || raw.isEmpty) return false;

      final map = jsonDecode(raw) as Map<String, dynamic>;

      final String nombre = ((map['nombre'] ?? '') as String).trim();
      final String edadStr = ((map['edad'] ?? '') as String).trim();
      final String pais = ((map['paisSeleccionado'] ?? '') as String).trim();
      final String ciudad = ((map['ciudadSeleccionada'] ?? '') as String).trim();
      final List<dynamic> fotosDyn =
      (map['fotosCargadas'] ?? const []) as List<dynamic>;

      final int? edadInt = int.tryParse(edadStr);

      final bool nombreOk = nombre.isNotEmpty;
      final bool edadOk = edadInt != null && edadInt >= 18 && edadInt <= 99;
      final bool paisOk = pais.isNotEmpty;
      final bool ciudadOk = ciudad.isNotEmpty;
      final bool fotosOk = fotosDyn.isNotEmpty;

      return nombreOk && edadOk && paisOk && ciudadOk && fotosOk;
    } catch (_) {
      return false;
    }
  }

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

      if (ok) {
        _irHomeShellPanel(context);
      } else {
        _irADatos(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error Google: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signUpWithEmail(BuildContext context) async {
    // igual que antes, sin cambios
  }

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
              const SizedBox(height: topSpaceBeforeLogo),
              Image.asset(
                'assets/images/logo_matchy2.png',
                height: logoHeight,
              ),
              SizedBox(height: h * offsetBotones),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    SizedBox(
                      height: 50,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : () => _signInWithGoogle(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: const StadiumBorder(),
                        ),
                        child: _loading
                            ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset('assets/images/ic_google.png', height: 24),
                            const SizedBox(width: 8),
                            const Text(
                              'Sign up with Google',
                              style: TextStyle(color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 50,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : () => _signUpWithEmail(context),
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
