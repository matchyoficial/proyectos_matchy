// 📂 lib/screens/registro_screen.dart
// ✅ PANTALLA DE ACCESO BLINDADA (LOGICA CORREGIDA)
// 🔥 FIX: Eliminado bucle infinito que bloqueaba la persistencia de sesión.
// 🔥 FIX: Escritura en Firestore garantizada antes de navegar.
// 🔥 UI: Diseño visual y "Chinches Maestros" intactos.

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
  // 🛡️ ZONA DE CHINCHES MAESTROS (CONTROL DE POSICIONES)
  // ==========================================================
  static const int kFuerzaTecho = 2;  // Empuje desde arriba hacia el Logo
  static const int kFuerzaMedio = 1;  // Empuje entre Logo y Botón
  static const int kFuerzaSuelo = 3;  // Empuje desde abajo hacia el Texto

  static const double kLogoHeight = 70.0;     // Tamaño del Logo
  static const double kButtonHeight = 55.0;   // Altura del Botón
  static const double kButtonWidthPercent = 0.85; // Ancho del botón (85%)
  static const double kEspacioBotonTexto = 15.0; // Separación fija

  static const List<Shadow> kTextShadow = [
    Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 1))
  ];
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

  // 🛡️ LÓGICA CORREGIDA: Sin bucles infinitos, lectura directa y segura
  Future<bool> _gestionarUsuarioEnFirestore(User user) async {
    try {
      // 1. Referencia al documento del usuario
      final userRef = _db.collection('users').doc(user.uid);

      // 2. Leemos UNA VEZ de manera autoritativa (servidor)
      final docSnapshot = await userRef.get(const GetOptions(source: Source.server));

      if (docSnapshot.exists) {
        // A. USUARIO EXISTENTE: Solo actualizamos la última vez que entró
        await userRef.update({
          'lastLoginAt': FieldValue.serverTimestamp(),
        });

        final data = docSnapshot.data();
        // Retornamos si ya completó el onboarding
        return data?['onboarding_completed'] == true;

      } else {
        // B. USUARIO NUEVO: Creamos el registro desde cero
        await userRef.set({
          'uid': user.uid,
          'email': user.email,
          'nombre': user.displayName ?? '',
          'profilePhotoUrl': user.photoURL ?? '',
          'provider': 'google',
          'createdAt': FieldValue.serverTimestamp(),
          'onboarding_completed': false, // Importante: Nuevo usuario = false
          'lastLoginAt': FieldValue.serverTimestamp(),
        });

        return false; // Es nuevo, así que no ha completado onboarding
      }
    } catch (e) {
      debugPrint("⚠️ Error en Firestore: $e");
      rethrow; // Lanzamos el error para que lo maneje el try/catch principal
    }
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    if (_loading) return;

    setState(() {
      _loading = true;
      _statusMessage = "Cargando...";
    });

    try {
      // 1. INICIO GOOGLE (Nativo)
      final googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        // Usuario canceló la ventana de Google
        setState(() { _loading = false; _statusMessage = "Continuar con Google"; });
        return;
      }

      // 2. OBTENER CREDENCIALES
      final auth = await googleUser.authentication;
      final cred = GoogleAuthProvider.credential(
          accessToken: auth.accessToken,
          idToken: auth.idToken
      );

      // 3. IMPACTAR FIREBASE (El momento crítico)
      if (mounted) setState(() => _statusMessage = "Autenticando...");

      // Guardamos la sesión en Firebase Authentication
      final userCred = await _auth.signInWithCredential(cred);
      final user = userCred.user;

      if (user == null) throw Exception('No se pudo obtener el usuario.');

      // 4. GESTIÓN FIRESTORE (Sin bucles raros)
      if (mounted) setState(() => _statusMessage = "Verificando cuenta...");

      // Esta función ahora es sólida y lineal
      final esUsuarioCompleto = await _gestionarUsuarioEnFirestore(user);

      // 5. NAVEGACIÓN FINAL
      // Solo navegamos si todo lo anterior salió bien
      if (esUsuarioCompleto) {
        _irHomeShellPanel(context);
      } else {
        _irADatos(context);
      }

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de acceso: $e'), backgroundColor: Colors.red)
      );
      setState(() { _loading = false; _statusMessage = "Reintentar"; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double buttonWidth = size.width * kButtonWidthPercent;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Fondo
          Positioned.fill(child: Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover)),

          // 2. Contenido Elástico
          SafeArea(
            child: SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // A. RESORTE TECHO
                  Spacer(flex: kFuerzaTecho),

                  // B. LOGO
                  Image.asset('assets/images/logo_matchy2.png', height: kLogoHeight),

                  // C. RESORTE MEDIO
                  Spacer(flex: kFuerzaMedio),

                  // D. GRUPO BOTÓN + TEXTO
                  Column(
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
                            elevation: 8,
                            shadowColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: _loading
                                  ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.purple)),
                                  const SizedBox(width: 15),
                                  Text(_statusMessage, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, shadows: kTextShadow)),
                                ],
                              )
                                  : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset('assets/images/ic_google.png', height: 24, errorBuilder: (_,__,___) => const Icon(Icons.login, color: Colors.grey)),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Continuar con Google',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Poppins', shadows: kTextShadow),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: kEspacioBotonTexto),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "Al continuar aceptas nuestros Términos y Condiciones",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11, shadows: kTextShadow),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // E. RESORTE SUELO
                  Spacer(flex: kFuerzaSuelo),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}