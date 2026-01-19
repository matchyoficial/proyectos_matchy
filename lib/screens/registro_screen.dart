// 📂 lib/screens/registro_screen.dart
// ✅ PANTALLA DE ACCESO (PORTERO NUCLEAR - PRUEBA DE ESCRITURA)
// 🔥 FIX EXTREMO: El "Portero" ahora intenta ESCRIBIR en la BD (Update Timestamp).
//    La escritura requiere permisos estrictos. Si la escritura pasa, el token es válido.
//    Si falla, reintenta infinitamente recargando credenciales.
// 🔥 SEGURIDAD: Jamás navega si la escritura falla.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:proyectos_matchy/screens/datos_screen.dart';
import 'package:proyectos_matchy/screens/home_shell.dart';

class RegistroScreen extends ConsumerStatefulWidget {
  const RegistroScreen({super.key});

  @override
  ConsumerState<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends ConsumerState<RegistroScreen> {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  bool _loading = false;
  String _statusMessage = "Continuar con Google";

  // ==========================================================
  // 🔴🔴 ZONA DE CHINCHES MAESTROS (CONFIGURACIÓN UI) 🔴🔴
  // ==========================================================
  static const double kLogoHeight = 70.0;
  static const double kLogoTopSpace = 120.0;
  static const double kButtonVerticalPosition = 0.5;
  static const double kButtonHeight = 55.0;
  static const double kButtonWidthPercent = 0.85;
  // ==========================================================

  void _irADatos(BuildContext context) {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DatosScreen()),
            (route) => false
    );
  }

  void _irHomeShellPanel(BuildContext context) {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeShell(initialIndex: 2)),
            (route) => false
    );
  }

  // 🔹 PORTERO NUCLEAR: Bucle de Autenticación + Escritura
  // Retorna 'true' si el usuario ya existía y está completo.
  // Retorna 'false' si es usuario nuevo (se creó el esqueleto).
  Future<bool> _autenticarYValidarContraFuego(User user) async {
    int intento = 0;

    // Bucle infinito hasta éxito o cancelación manual del usuario (cerrando app)
    while (true) {
      intento++;
      try {
        if (intento > 1) {
          if (mounted) setState(() => _statusMessage = "Asegurando conexión... ($intento)");

          // Si falló, castigamos con espera y recarga agresiva
          await Future.delayed(const Duration(seconds: 2));
          await user.reload(); // Recarga usuario desde servidor
          await user.getIdToken(true); // Fuerza token nuevo
        }

        // 1. Intentamos leer el documento (Directo del servidor, sin caché)
        final docSnapshot = await _db.collection('users').doc(user.uid).get(const GetOptions(source: Source.server));

        if (docSnapshot.exists) {
          // CASO A: Usuario Existe
          // PRUEBA DE FUEGO: Intentamos ESCRIBIR. Si esto pasa, tenemos permisos full.
          await _db.collection('users').doc(user.uid).update({
            'lastLoginAt': FieldValue.serverTimestamp(),
          });

          // Verificamos si completó el onboarding
          final data = docSnapshot.data();
          return data?['onboarding_completed'] == true;

        } else {
          // CASO B: Usuario Nuevo (No existe documento)
          // PRUEBA DE FUEGO: Intentamos CREAR.
          await _db.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'email': user.email,
            'nombre': user.displayName ?? '',
            'profilePhotoUrl': user.photoURL ?? '',
            'provider': 'google',
            'createdAt': FieldValue.serverTimestamp(),
            'onboarding_completed': false,
            'lastLoginAt': FieldValue.serverTimestamp(),
          });
          return false; // Es nuevo
        }

      } catch (e) {
        debugPrint("⚠️ Intento $intento fallido. Error: $e");
        // Si el error es de permisos o red, el bucle 'while(true)' lo atrapará y reintentará.
        // No salimos del bucle hasta tener éxito.

        if (intento > 10) {
          // Si falla demasiado, damos un respiro al UI pero seguimos intentando
          await Future.delayed(const Duration(seconds: 3));
        }
      }
    }
  }

  // 🔹 GOOGLE SIGN IN
  Future<void> _signInWithGoogle(BuildContext context) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _statusMessage = "Cargando...";
    });

    try {
      // 1. Google Auth Nativo
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() {
          _loading = false;
          _statusMessage = "Continuar con Google";
        });
        return;
      }

      final auth = await googleUser.authentication;
      final cred = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );

      // 2. Firebase Auth Login
      final userCred = await _auth.signInWithCredential(cred);
      final user = userCred.user;
      if (user == null) throw Exception('Error crítico de autenticación.');

      // 3. 🛑 EL PORTERO NUCLEAR
      // Aquí la app se detiene hasta que la función retorne.
      // La función NO retorna hasta que haya escrito exitosamente en Firestore.
      if (mounted) setState(() => _statusMessage = "Verificando cuenta...");

      // Forzamos primer refresco de token antes de entrar al ring
      await user.getIdToken(true);

      final esUsuarioCompleto = await _autenticarYValidarContraFuego(user);

      // 4. DECISIÓN (Solo llegamos aquí si la conexión es 100% exitosa y probada)
      if (esUsuarioCompleto) {
        _irHomeShellPanel(context);
      } else {
        _irADatos(context);
      }

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      setState(() {
        _loading = false;
        _statusMessage = "Reintentar";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double buttonWidth = size.width * kButtonWidthPercent;

    return Scaffold(
      body: Stack(
        children: [
          // 1. FONDO
          Positioned.fill(
            child: Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover),
          ),

          // 2. LOGO
          Positioned(
            top: kLogoTopSpace,
            left: 0, right: 0,
            child: Center(
              child: Image.asset('assets/images/logo_matchy2.png', height: kLogoHeight),
            ),
          ),

          // 3. BOTÓN
          Positioned(
            top: (size.height * kButtonVerticalPosition) - (kButtonHeight / 2),
            left: (size.width - buttonWidth) / 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: buttonWidth,
                  height: kButtonHeight,
                  child: ElevatedButton(
                    onPressed: _loading ? null : () => _signInWithGoogle(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      elevation: 5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: _loading
                        ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.purple)),
                        const SizedBox(width: 15),
                        Text(_statusMessage, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    )
                        : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('assets/images/ic_google.png', height: 24, errorBuilder: (_,__,___) => const Icon(Icons.login, color: Colors.grey)),
                        const SizedBox(width: 12),
                        const Text(
                          'Continuar con Google',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  "Al continuar aceptas nuestros Términos y Condiciones",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}