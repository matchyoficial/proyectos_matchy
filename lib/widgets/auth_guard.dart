// 📂 lib/widgets/auth_guard.dart
// ✅ GUARDIA DE SEGURIDAD ABSOLUTO (CORREGIDO PARA FLUTTER FRAMEWORK)
// 🔥 FIX: Uso de addPostFrameCallback para evitar el error "setState called during build".
// 🔥 FIX: Navegación segura que no choca con el ciclo de vida del widget.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proyectos_matchy/screens/registro_screen.dart';
import 'package:proyectos_matchy/screens/home_shell.dart';
import 'package:proyectos_matchy/screens/datos_screen.dart';

class AuthGuard extends StatefulWidget {
  const AuthGuard({super.key});

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  String _status = "Iniciando...";

  @override
  void initState() {
    super.initState();
    // 🔥 FIX: Esperar a que termine el primer frame antes de iniciar lógica pesada
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _validarAccesoCompleto();
    });
  }

  Future<void> _validarAccesoCompleto() async {
    // 1. Verificar usuario local
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) _irALogin();
      return;
    }

    // 2. Bucle de Validación
    int intentos = 0;
    while (true) {
      intentos++;
      try {
        if (!mounted) return;
        setState(() => _status = "Validando credenciales... ($intentos)");

        // A. Forzar refresco
        await user.reload();
        await user.getIdToken(true);

        // B. Lectura de Prueba
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get(const GetOptions(source: Source.server));

        // C. Éxito -> Navegar
        if (mounted) {
          bool onboardingCompleto = false;
          if (doc.exists) {
            final data = doc.data();
            onboardingCompleto = data?['onboarding_completed'] == true;
          }
          _navegar(onboardingCompleto);
        }
        return;

      } catch (e) {
        debugPrint("⚠️ Intento $intentos fallido: $e");
        await Future.delayed(const Duration(seconds: 2));
      }
    }
  }

  void _irALogin() {
    // Usamos pushReplacement para reemplazar el Guard por el Login
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const RegistroScreen()),
    );
  }

  void _navegar(bool onboardingCompleto) {
    if (onboardingCompleto) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeShell(initialIndex: 2)),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DatosScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo imagen
          Positioned.fill(
            child: Image.asset(
              'assets/images/fondo.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_,__,___) => Container(color: Colors.black),
            ),
          ),

          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/images/logomatchyplano.png', height: 80, errorBuilder: (_,__,___) => const Icon(Icons.favorite, size: 80, color: Colors.white)),
                const SizedBox(height: 40),
                const CircularProgressIndicator(color: Color(0xFFBEB3FF)),
                const SizedBox(height: 20),
                Text(
                  _status,
                  style: const TextStyle(color: Colors.white70, fontFamily: 'Poppins', fontSize: 12, decoration: TextDecoration.none),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}