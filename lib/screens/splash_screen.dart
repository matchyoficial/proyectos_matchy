// 📂 lib/screens/splash_screen.dart
// ✅ SPLASH "CANDADO ESTRICTO" (CORREGIDO - SIN LETRA Ñ)
// 🔥 FIX: Renombrado _buildDiseñoSplash a _buildDisenoSplash para evitar error de compilación.
// 🔥 GARANTÍA: El mismo código de seguridad estricta, ahora compilable.

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
  static const String _kUsersCollection = 'users';
  bool _navigating = false; // Semáforo para evitar doble navegación

  @override
  Widget build(BuildContext context) {
    // 🛡️ EL CENTINELA: StreamBuilder escucha directamente al núcleo de Auth
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {

        // 1. ESTADO: CARGANDO (Firebase está leyendo el disco)
        // Mientras la conexión esté esperando, mostramos el diseño estático.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildDisenoSplash();
        }

        // 2. ESTADO: RESPUESTA RECIBIDA
        // Apenas tenemos dato (sea User o null), ejecutamos la lógica UNA VEZ.
        if (!_navigating) {
          _navigating = true; // Bloqueamos para que no se repita

          // Usamos addPostFrameCallback para navegar DESPUÉS de que se dibuje el frame
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _gestionarNavegacion(snapshot.data);
          });
        }

        // Mientras navegamos, seguimos mostrando el logo para que no parpadee blanco
        return _buildDisenoSplash();
      },
    );
  }

  Future<void> _gestionarNavegacion(User? user) async {
    if (user == null) {
      // ❌ CASO B: NO HAY USUARIO (Confirmado 100% por Firebase)
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const RegistroScreen()),
      );
    } else {
      // ✅ CASO A: HAY USUARIO (Confirmado 100% por Firebase)
      try {
        // 1. Inyectamos vida a la memoria (Riverpod)
        await ref.read(profileFormProvider.notifier).bootstrapFromFirestore();

        // 2. Verificamos la integridad de los datos en la Nube
        final perfilCompleto = await _checkOnboardingCloud(user.uid);

        if (!mounted) return;

        if (perfilCompleto) {
          // -> AL PANEL
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeShell(initialIndex: 2)),
          );
        } else {
          // -> A DATOS (Usuario existe pero no terminó registro)
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const DatosScreen()),
          );
        }
      } catch (e) {
        // Si falla la lectura de datos, por seguridad mandamos a DatosScreen
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DatosScreen()),
        );
      }
    }
  }

  Future<bool> _checkOnboardingCloud(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(_kUsersCollection)
          .doc(uid)
          .get();

      if (!doc.exists) return false;
      return doc.data()?['onboarding_completed'] == true;
    } catch (_) {
      return false;
    }
  }

  Widget _buildDisenoSplash() {
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
                errorBuilder: (_,__,___) => const SizedBox(),
              ),
              const SizedBox(height: 40),
              // Indicador visual: "No te has trabado, estoy esperando a Firebase"
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