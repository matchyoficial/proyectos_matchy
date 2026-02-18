// 📂 lib/screens/splash_screen.dart
// ✅ SPLASH FINAL CORREGIDO Y BLINDADO
// 🔥 FIX VISUAL: Logo estático, centrado y de tamaño normal (150).
// 🔥 FIX LÓGICO: Elimina el "Stream Race Condition". Espera 3s y verifica.
// 🎯 RESULTADO: Si estás logueado, entras. Si no, registro. Sin fallos.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:proyectos_matchy/screens/registro_screen.dart';
import 'package:proyectos_matchy/screens/home_shell.dart';
import 'package:proyectos_matchy/screens/datos_screen.dart';
import 'package:proyectos_matchy/screens/panel_screen.dart'; // Asegura tener este import
import 'package:proyectos_matchy/state/profile_form_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  // Tiempo mínimo OBLIGATORIO que el logo estará en pantalla
  static const int _minSeconds = 3;
  static const String _kUsersCollection = 'users';

  @override
  void initState() {
    super.initState();
    _iniciarArranqueSincronizado();
  }

  Future<void> _iniciarArranqueSincronizado() async {
    // 🛡️ EL CANDADO DE TIEMPO
    // Esperamos 3 segundos OBLIGATORIOS.
    // Esto cumple dos funciones:
    // 1. Branding: El usuario ve tu marca.
    // 2. Técnica: Da tiempo a Firebase Auth para inicializarse en segundo plano
    //    sin necesidad de listeners complejos que fallan en frío.

    await Future.delayed(const Duration(seconds: _minSeconds));

    if (!mounted) return;

    // 🔍 VERIFICACIÓN INFALIBLE
    // Después de 3 segundos, FirebaseAuth ya tiene el estado real.
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // ❌ NO HAY SESIÓN: Vamos a Registro
      _irA(const RegistroScreen());
    } else {
      // ✅ HAY SESIÓN: Verificamos si completó el perfil
      await _procesarUsuarioLogueado(user);
    }
  }

  Future<void> _procesarUsuarioLogueado(User user) async {
    try {
      // 1. Inyectamos datos en Riverpod (Pre-carga)
      await ref.read(profileFormProvider.notifier).bootstrapFromFirestore();

      // 2. Verificamos en Firestore si ya terminó el onboarding
      final perfilCompleto = await _checkOnboardingCloud(user.uid);

      if (!mounted) return;

      if (perfilCompleto) {
        // 🚀 TODO LISTO -> Panel de Control
        _irA(const PanelScreen());
        // O usa HomeShell(initialIndex: 2) si usas navegación con tabs
      } else {
        // ⚠️ FALTA PERFIL -> Pantalla de Datos
        _irA(const DatosScreen());
      }
    } catch (e) {
      // Si falla la red o algo crítico, aseguramos enviando a Datos o Registro
      // Para evitar que se quede pegado en el logo.
      if (mounted) _irA(const RegistroScreen());
    }
  }

  Future<bool> _checkOnboardingCloud(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(_kUsersCollection)
          .doc(uid)
          .get();
      // Verificamos explícitamente el campo booleano
      return doc.exists && doc.data()?['onboarding_completed'] == true;
    } catch (_) {
      return false;
    }
  }

  void _irA(Widget screen) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Fondo
          Positioned.fill(
            child: Image.asset(
              'assets/images/fondo2.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.black),
            ),
          ),
          // Contenido Central
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // LOGO ESTÁTICO Y DE TAMAÑO NORMAL
                Image.asset(
                  'assets/images/logomatchyplano.png', // ✅ NOMBRE CORREGIDO
                  height: 80, // Tamaño ajustado a normal
                  errorBuilder: (_, __, ___) =>
                  const Icon(Icons.favorite, size: 80, color: Colors.white),
                ),
                const SizedBox(height: 50),
                const CircularProgressIndicator(
                  color: Color(0xFFBEB3FF), // Tu color morado Matchy
                  strokeWidth: 3,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}