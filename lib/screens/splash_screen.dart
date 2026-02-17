// 📂 lib/screens/splash_screen.dart
// ✅ SPLASH "SINCRONIZACIÓN ESTRICTA" (ARQUITECTURA PROFESIONAL)
// 🔥 FIX VISUAL: Garantiza 3 segundos de logo usando Future.wait.
// 🔥 FIX LÓGICO: Espera la señal 'first' de Firebase. No adivina, sabe.
// 🔥 RESULTADO: Jamás salta a registro por error ni deja de mostrar el logo.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:proyectos_matchy/screens/registro_screen.dart';
import 'package:proyectos_matchy/screens/home_shell.dart';
import 'package:proyectos_matchy/screens/datos_screen.dart';
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
    // 🛡️ EL CANDADO DE TIEMPO Y DATOS
    // Lanzamos dos tareas al aire y esperamos a que AMBAS aterricen.
    // 1. Tarea Visual: Esperar 3 segundos.
    // 2. Tarea Datos: Obtener el primer estado válido de Firebase (User o Null).

    final resultados = await Future.wait([
      Future.delayed(const Duration(seconds: _minSeconds)), // [0]
      FirebaseAuth.instance.authStateChanges().first,       // [1]
    ]);

    // Aquí ya pasaron al menos 3 segundos Y Firebase ya respondió.
    // Es imposible que falle por velocidad.

    final user = resultados[1] as User?;

    if (!mounted) return;

    if (user == null) {
      // ❌ NO HAY SESIÓN: Vamos a Registro
      _irA(const RegistroScreen());
    } else {
      // ✅ HAY SESIÓN: Verificamos datos del usuario
      await _procesarUsuarioLogueado(user);
    }
  }

  Future<void> _procesarUsuarioLogueado(User user) async {
    try {
      // 1. Inyectamos datos en Riverpod
      await ref.read(profileFormProvider.notifier).bootstrapFromFirestore();

      // 2. Verificamos Firestore (Registro completo)
      final perfilCompleto = await _checkOnboardingCloud(user.uid);

      if (!mounted) return;

      if (perfilCompleto) {
        // Todo perfecto -> Panel
        _irA(const HomeShell(initialIndex: 2));
      } else {
        // Falta completar perfil -> Datos
        _irA(const DatosScreen());
      }
    } catch (e) {
      // Si falla algo crítico (ej. internet), mandamos a Datos por seguridad
      if (mounted) _irA(const DatosScreen());
    }
  }

  Future<bool> _checkOnboardingCloud(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(_kUsersCollection)
          .doc(uid)
          .get();
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
    // WIDGET PURAMENTE VISUAL
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/fondo.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/logo_matchy.png',
                height: 200,
                // Si la imagen falla, muestra algo para saber que el código corre
                errorBuilder: (_,__,___) => const Icon(Icons.favorite, size: 80, color: Colors.white),
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(
                color: Color(0xFFBEB3FF),
                strokeWidth: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}