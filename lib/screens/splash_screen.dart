// 📂 lib/screens/splash_screen.dart
// ✅ PASO 4.9B — Splash definitivo BLINDADO
//    - Usa flag onboarding_completed PERO valida datos mínimos (anti-bugs)
//    - Si la flag está true pero el perfil está incompleto → vuelve a Registro
//    - Android + iOS con una sola lógica

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:proyectos_matchy/screens/registro_screen.dart';
import 'package:proyectos_matchy/screens/panel_screen.dart';

// Estado global (solo para debug visual si quieres)
import 'package:proyectos_matchy/state/app_state.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  // 🔴 CHINCHE SPLASH CONF 1 — mostrar texto debug (apágalo en producción)
  static const bool mostrarDebug = true;

  // 🔴 CHINCHE SPLASH CONF 2 — duración splash (segundos)
  static const int splashSeconds = 2;

  // 🔴 CHINCHE SPLASH STORAGE 1 — llaves de persistencia (NO dependemos de imports privados)
  static const String _kOnboardingCompletedKey = 'matchy_onboarding_completed_v1';
  static const String _kProfileDraftKey = 'matchy_profile_draft_v1';

  @override
  void initState() {
    super.initState();
    _decidirRuta();
  }

  Future<void> _decidirRuta() async {
    final prefs = await SharedPreferences.getInstance();

    // 1) Lee la flag
    final bool flagOnboarding = prefs.getBool(_kOnboardingCompletedKey) ?? false;

    // 2) Valida si realmente existe un perfil mínimo válido
    final bool perfilMinimoOk = await _perfilMinimoValido(prefs);

    // 🔴 CHINCHE SPLASH LOGIC 1 — decisión real: flag + datos válidos
    final bool onboardingCompleto = flagOnboarding && perfilMinimoOk;

    // 3) Espera UX del splash
    await Future.delayed(const Duration(seconds: splashSeconds));
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => onboardingCompleto ? const PanelScreen() : const RegistroScreen(),
      ),
    );
  }

  // ✅ Validador mínimo (anti-crash / anti-flag-corrupta)
  Future<bool> _perfilMinimoValido(SharedPreferences prefs) async {
    try {
      final raw = prefs.getString(_kProfileDraftKey);
      if (raw == null || raw.isEmpty) return false;

      final map = jsonDecode(raw) as Map<String, dynamic>;

      final String nombre = ((map['nombre'] ?? '') as String).trim();
      final String edadStr = ((map['edad'] ?? '') as String).trim();
      final String pais = ((map['paisSeleccionado'] ?? '') as String).trim();
      final String ciudad = ((map['ciudadSeleccionada'] ?? '') as String).trim();
      final List<dynamic> fotosDyn = (map['fotosCargadas'] ?? const []) as List<dynamic>;

      final int? edadInt = int.tryParse(edadStr);

      final bool nombreOk = nombre.isNotEmpty;
      final bool edadOk = edadInt != null && edadInt >= 18 && edadInt <= 99;
      final bool paisOk = pais.isNotEmpty;
      final bool ciudadOk = ciudad.isNotEmpty;
      final bool fotosOk = fotosDyn.isNotEmpty;

      return nombreOk && edadOk && paisOk && ciudadOk && fotosOk;
    } catch (_) {
      // Si el JSON está corrupto, no bloqueamos: tratamos como NO completo
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Debug opcional Riverpod (counter)
    final appState = ref.watch(appControllerProvider);

    return Scaffold(
      body: Container(
        // 🔴 CHINCHE SPLASH UI 1 — fondo splash
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/fondo.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            // LOGO CENTRAL
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/logo_matchy.png',
                    height: 200, // 🔴 CHINCHE SPLASH UI 2 — tamaño logo
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      letterSpacing: 4,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // DEBUG VISUAL (opcional)
            if (mostrarDebug)
              Positioned(
                left: 0,
                right: 0,
                bottom: 24, // 🔴 CHINCHE SPLASH UI 3 — posición debug
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Riverpod OK · Counter: ${appState.counter}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
