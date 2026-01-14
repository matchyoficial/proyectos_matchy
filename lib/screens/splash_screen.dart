// 📂 lib/screens/splash_screen.dart
// ✅ Splash definitivo BLINDADO (CACHE-SAFE)
// ✅ Decide ruta con FIRESTORE si hay sesión (cross-device)
// ✅ Si NO hay sesión, usa SharedPreferences como fallback

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:proyectos_matchy/screens/registro_screen.dart';
import 'package:proyectos_matchy/screens/panel_screen.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:proyectos_matchy/state/profile_form_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  // 🔴 CHINCHE SPLASH CONF 1 — duración splash (segundos)
  static const int splashSeconds = 2;

  static const String _kOnboardingCompletedKey = 'matchy_onboarding_completed_v1';
  static const String _kProfileDraftKey = 'matchy_profile_draft_v1';

  static const String _kUsersCollection = 'users';

  @override
  void initState() {
    super.initState();
    _decidirRuta();
  }

  Future<void> _decidirRuta() async {
    await Future.delayed(const Duration(seconds: splashSeconds));
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;

    // ✅ 1) Si hay sesión, Firestore manda
    if (user != null) {
      final ok = await _onboardingCompletoDesdeFirestore(user.uid);

      // 🔴 CHINCHE SPLASH HYDRATE 1 — hidrata provider (fotos/datos) antes de entrar a la app
      await ref.read(profileFormProvider.notifier).bootstrapFromFirestore();

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ok ? const PanelScreen() : const RegistroScreen(),
        ),
      );
      return;
    }

    // ✅ 2) Sin sesión, fallback local
    final prefs = await SharedPreferences.getInstance();
    final bool flagOnboarding = prefs.getBool(_kOnboardingCompletedKey) ?? false;
    final bool perfilMinimoOk = await _perfilMinimoValidoLocal(prefs);
    final bool onboardingCompleto = flagOnboarding && perfilMinimoOk;

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => onboardingCompleto ? const PanelScreen() : const RegistroScreen(),
      ),
    );
  }

  Future<bool> _onboardingCompletoDesdeFirestore(String uid) async {
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

      final List photoUrlsRaw =
      (data['photoUrls'] is List) ? (data['photoUrls'] as List) : [];
      final List<String> photoUrls = photoUrlsRaw
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

  Future<bool> _perfilMinimoValidoLocal(SharedPreferences prefs) async {
    try {
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

      final edadInt = int.tryParse(edadStr);

      final bool fotosOk =
          profileUrl.isNotEmpty || urls.isNotEmpty || fotos.isNotEmpty;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/fondo.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Image.asset(
            'assets/images/logo_matchy.png',
            height: 200, // 🔴 CHINCHE SPLASH UI 2
          ),
        ),
      ),
    );
  }
}
