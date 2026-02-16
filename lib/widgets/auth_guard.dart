// 📂 lib/widgets/auth_guard.dart
// ✅ GUARDIA DE SEGURIDAD REACTIVO (DOBLE CANDADO)
// 🔥 CANDADO 1: StreamBuilder escucha el estado de autenticación en tiempo real.
// 🔥 CANDADO 2: FutureBuilder verifica la integridad de los datos en Firestore antes de abrir.
// 🛡️ SEGURIDAD: Previene acceso a cuentas vacías o corruptas.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proyectos_matchy/screens/registro_screen.dart';
import 'package:proyectos_matchy/screens/home_shell.dart';
import 'package:proyectos_matchy/screens/datos_screen.dart';

class AuthGuard extends StatelessWidget {
  const AuthGuard({super.key});

  // 🔹 Lógica del Candado 2: Verificar si los datos existen y están completos
  Future<bool> _verificarIntegridadDatos(String uid) async {
    try {
      // Forzamos lectura del servidor para asegurar que no sea caché vieja corrupta
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!doc.exists) return false; // El usuario existe en Auth pero no tiene datos -> Incompleto

      final data = doc.data();
      // Verificamos la bandera maestra
      return data?['onboarding_completed'] == true;
    } catch (e) {
      debugPrint("⚠️ Error verificando integridad: $e");
      return false; // Ante la duda, bloquear acceso y mandar a datos
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔒 CANDADO 1: Escucha activa de la sesión (Auth)
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {

        // A. Esperando respuesta inicial de Firebase (Splash)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _PantallaDeCarga(mensaje: "Conectando...");
        }

        // B. No hay usuario logueado -> Pantalla de Registro
        if (!snapshot.hasData || snapshot.data == null) {
          return const RegistroScreen();
        }

        // C. Hay usuario -> 🔒 CANDADO 2: Verificar integridad de datos
        final User user = snapshot.data!;

        return FutureBuilder<bool>(
          future: _verificarIntegridadDatos(user.uid),
          builder: (context, dataSnapshot) {

            // C.1. Verificando base de datos (Splash)
            if (dataSnapshot.connectionState == ConnectionState.waiting) {
              return const _PantallaDeCarga(mensaje: "Verificando perfil...");
            }

            // C.2. Si perfil completo -> HOME (Entrada permitida)
            if (dataSnapshot.hasData && dataSnapshot.data == true) {
              return const HomeShell(initialIndex: 2);
            }

            // C.3. Si perfil incompleto o nuevo -> DATOS SCREEN
            return const DatosScreen();
          },
        );
      },
    );
  }
}

// 🎨 Widget Privado: Diseño de Carga (Splash) para no repetir código
class _PantallaDeCarga extends StatelessWidget {
  final String mensaje;
  const _PantallaDeCarga({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo
          Positioned.fill(
            child: Image.asset(
              'assets/images/fondo.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_,__,___) => Container(color: Colors.black),
            ),
          ),
          // Contenido Centro
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                    'assets/images/logomatchyplano.png',
                    height: 80,
                    errorBuilder: (_,__,___) => const Icon(Icons.favorite, size: 80, color: Colors.white)
                ),
                const SizedBox(height: 40),
                const CircularProgressIndicator(color: Color(0xFFBEB3FF)),
                const SizedBox(height: 20),
                Text(
                  mensaje,
                  style: const TextStyle(
                      color: Colors.white70,
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      decoration: TextDecoration.none
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}