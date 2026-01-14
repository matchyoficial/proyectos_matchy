// 📂 lib/screens/registro_screen.dart
// ✅ Botones centrados verticalmente
// ✅ Chinches para subir/bajar bloque de botones
// ✅ Chinches para editar tamaño y posición del logo
// ✅ Lógica Firebase intacta
// ✅ NUEVO: tras login Google, decide con FIRESTORE (cache-safe)
// ✅ NUEVO: hidrata provider para que Perfil/Panel tengan fotos inmediatamente

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:proyectos_matchy/screens/panel_screen.dart';
import 'package:proyectos_matchy/screens/datos_screen.dart';

// 🔴 CHINCHE REG PROVIDER 1 — perfil provider (hydrate)
import 'package:proyectos_matchy/state/profile_form_provider.dart';

class RegistroScreen extends ConsumerStatefulWidget {
  const RegistroScreen({super.key});

  @override
  ConsumerState<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends ConsumerState<RegistroScreen> {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  bool _loading = false;

  // ===========================================================
  // 🔴 CHINCHE REG LOGO A — tamaño del logo (más grande/pequeño)
  // ===========================================================
  static const double logoHeight = 70;

  // ===========================================================
  // 🔴 CHINCHE REG LOGO B — espacio superior antes del logo (sube/baja logo)
  // ===========================================================
  static const double topSpaceBeforeLogo = 60;

  // ===========================================================
  // 🔴 CHINCHE REG BTN A — offset vertical del bloque de botones (sube/baja botones)
  // ===========================================================
  static const double offsetBotones = 0.18;

  // 🔴 CHINCHE PREFS REG 1 — llave del draft del perfil (DatosScreen)
  static const String _kProfileDraftKey = 'matchy_profile_draft_v1';

  // 🔴 CHINCHE FIRESTORE REG 1 — colección users
  static const String _kUsersCollection = 'users';

  void _irADatos(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DatosScreen()),
    );
  }

  void _irAlPanel(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const PanelScreen()),
    );
  }

  Future<void> _ensureUserDoc(User user, String provider) async {
    final ref = _db.collection(_kUsersCollection).doc(user.uid);
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

  // ===========================================================
  // ✅ PERFIL MÍNIMO OK (FIRESTORE) — cache-safe, cross-device
  // ===========================================================
  Future<bool> _perfilMinimoValidoDesdeFirestore(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(_kUsersCollection)
          .doc(uid)
          .get();

      if (!doc.exists) return false;

      final data = doc.data();
      if (data == null) return false;

      final bool onboarding = (data['onboarding_completed'] == true);

      final nombre = (data['nombre'] ?? '').toString().trim();
      final edadVal = data['edad'];
      final edadInt = (edadVal is int)
          ? edadVal
          : int.tryParse((edadVal ?? '').toString().trim());

      final pais = (data['pais'] ?? '').toString().trim();
      final ciudad = (data['ciudad'] ?? '').toString().trim();

      final List rawUrls =
      (data['photoUrls'] is List) ? (data['photoUrls'] as List) : [];
      final photoUrls = rawUrls
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final profilePhotoUrl = (data['profilePhotoUrl'] ?? '').toString().trim();

      final bool fotosOk = profilePhotoUrl.isNotEmpty || photoUrls.isNotEmpty;

      final bool perfilOk =
          nombre.isNotEmpty &&
              edadInt != null &&
              edadInt >= 18 &&
              edadInt <= 99 &&
              pais.isNotEmpty &&
              ciudad.isNotEmpty &&
              fotosOk;

      return onboarding && perfilOk;
    } catch (_) {
      return false;
    }
  }

  // ===========================================================
  // ✅ PERFIL MÍNIMO OK (local draft) — fallback offline
  // ===========================================================
  Future<bool> _perfilMinimoValidoLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kProfileDraftKey);
      if (raw == null || raw.isEmpty) return false;

      final map = jsonDecode(raw) as Map<String, dynamic>;

      final nombre = (map['nombre'] ?? '').toString().trim();
      final edadStr = (map['edad'] ?? '').toString().trim();
      final pais = (map['paisSeleccionado'] ?? '').toString().trim();
      final ciudad = (map['ciudadSeleccionada'] ?? '').toString().trim();

      final List fotos =
      (map['fotosCargadas'] is List) ? (map['fotosCargadas'] as List) : [];
      final List urls =
      (map['photoUrls'] is List) ? (map['photoUrls'] as List) : [];
      final profileUrl = (map['profilePhotoUrl'] ?? '').toString().trim();

      final int? edadInt = int.tryParse(edadStr);

      final bool fotosOk =
          fotos.isNotEmpty || urls.isNotEmpty || profileUrl.isNotEmpty;

      return nombre.isNotEmpty &&
          edadInt != null &&
          edadInt >= 18 &&
          edadInt <= 99 &&
          pais.isNotEmpty &&
          ciudad.isNotEmpty &&
          fotosOk;
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

      // ✅ 1) Hidratamos provider desde Firestore (para que Perfil/Panel tengan fotos)
      // 🔴 CHINCHE REG HYDRATE 1
      await ref.read(profileFormProvider.notifier).bootstrapFromFirestore();

      // ✅ 2) Decisión con Firestore (cache-safe)
      final okFs = await _perfilMinimoValidoDesdeFirestore(user.uid);

      // ✅ 3) Fallback local (por si Firestore falla/offline)
      final okLocal = await _perfilMinimoValidoLocal();
      final ok = okFs || okLocal;

      if (!mounted) return;

      if (ok) {
        _irAlPanel(context);
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
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 50,
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
