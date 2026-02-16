// 📂 lib/screens/splash_screen.dart
// ✅ Splash definitivo BLINDADO (LÓGICA CORREGIDA)
// 🔥 FIX: Rompe el bucle de Registro.
// 🔥 LOGIC: Si estás logueado pero faltan datos, te manda a DatosScreen, NUNCA a Registro.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:proyectos_matchy/screens/registro_screen.dart';
import 'package:proyectos_matchy/screens/home_shell.dart';
import 'package:proyectos_matchy/screens/datos_screen.dart'; // ✅ Importante para redireccionar correctamente

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:proyectos_matchy/state/profile_form_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  static const int splashSeconds = 2;
  static const String _kOnboardingCompletedKey = 'matchy_onboarding_completed_v1';
  static const String _kUsersCollection = 'users';

  @override
  void initState() {
    super.initState();
    _decidirRuta();
  }

  Future<void> _decidirRuta() async {
    // Pequeña espera para mostrar el logo
    await Future.delayed(const Duration(seconds: splashSeconds));
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;

    // ---------------------------------------------------------
    // CASO A: USUARIO LOGUEADO EN FIREBASE
    // ---------------------------------------------------------
    if (user != null) {
      // 1. Cargar datos en memoria (Riverpod) para que la app no se sienta vacía al entrar
      await ref.read(profileFormProvider.notifier).bootstrapFromFirestore();

      // 2. Verificar estado del perfil en la Nube
      final onboardingCompleto = await _checkOnboardingCloud(user.uid);

      if (!mounted) return;

      if (onboardingCompleto) {
        // ✅ Todo perfecto (Tiene bandera 'onboarding_completed') -> Al Panel
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeShell(initialIndex: 2)),
        );
      } else {
        // ⚠️ Falta completar perfil -> A Datos (AQUÍ ESTABA EL ERROR ANTES)
        // Antes te mandaba al Registro. Ahora te manda a llenar lo que falta.
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DatosScreen()),
        );
      }
      return;
    }

    // ---------------------------------------------------------
    // CASO B: USUARIO NO LOGUEADO
    // ---------------------------------------------------------
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const RegistroScreen()),
    );
  }

  // 🛡️ Verificación simplificada y robusta
  Future<bool> _checkOnboardingCloud(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(_kUsersCollection)
          .doc(uid)
          .get();

      if (!doc.exists) return false;
      final data = doc.data();

      // Confiamos en la bandera maestra que pone DatosScreen al guardar.
      return data?['onboarding_completed'] == true;
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
            height: 200,
          ),
        ),
      ),
    );
  }
}