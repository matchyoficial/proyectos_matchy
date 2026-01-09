// 📂 lib/screens/registro_screen.dart
// ✅ PASO 4.5 — Registro (Opción B aplicada, flujo coherente)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Pantallas
import 'package:proyectos_matchy/screens/panel_screen.dart';
import 'package:proyectos_matchy/screens/datos_screen.dart';

// Estado global
import 'package:proyectos_matchy/state/app_state.dart';

class RegistroScreen extends ConsumerWidget {
  const RegistroScreen({super.key});

  // 🔴 CHINCHE REG LOGIC 1 — guardar método de acceso elegido
  void _setMetodoAcceso(WidgetRef ref, String metodo) {
    debugPrint('Método de acceso seleccionado: $metodo');

    // FUTURO:
    // ref.read(appControllerProvider.notifier).setMetodoAcceso(metodo);
  }

  // 👉 SOLO usuarios ya listos entran al panel
  void _irAlPanel(BuildContext context, WidgetRef ref, String metodo) {
    _setMetodoAcceso(ref, metodo);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const PanelScreen()),
    );
  }

  // 👉 Nuevos usuarios SIEMPRE pasan por Datos
  void _irADatos(BuildContext context, WidgetRef ref, String metodo) {
    _setMetodoAcceso(ref, metodo);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DatosScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Stack(
        children: [
          // 🌆 Fondo global
          Positioned.fill(
            child: Image.asset(
              'assets/images/fondo.jpg',
              fit: BoxFit.cover,
            ),
          ),

          Column(
            children: [
              const SizedBox(height: 60),

              // 🔴 CHINCHE REG 1 — tamaño del logo
              Image.asset(
                'assets/images/logo_matchy2.png',
                height: 70,
              ),

              const SizedBox(height: 40),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // GOOGLE → DATOS
                    SizedBox(
                      height: 50,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () =>
                            _irADatos(context, ref, 'google'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                        child: Row(
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

                    const SizedBox(height: 12),

                    // FACEBOOK → DATOS
                    SizedBox(
                      height: 50,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () =>
                            _irADatos(context, ref, 'facebook'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1877F2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/ic_facebook.png',
                              height: 24,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Sign up with Facebook',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // EMAIL → DATOS
                    SizedBox(
                      height: 50,
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () =>
                            _irADatos(context, ref, 'email'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                        child: const Text(
                          'Sign up with Email',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // 🔥 REGISTRARSE (ANTES: Probar Perfil Bum)
                    SizedBox(
                      height: 50,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () =>
                            _irADatos(context, ref, 'registro'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6A5ACD),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
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

          // CONTINUAR → PANEL (usuarios ya registrados)
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: TextButton(
                onPressed: () =>
                    _irAlPanel(context, ref, 'continuar'),
                child: const Text(
                  'CONTINUAR',
                  style: TextStyle(
                    color: Colors.white,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
