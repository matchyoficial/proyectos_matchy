// 📂 lib/main.dart
// ✅ MAIN BLINDADO: Configuración Global + Presencia en Tiempo Real.
// ✅ LOCALIZACIONES: Español/Inglés configurado.
// ✅ PRESENCIA: WidgetsBindingObserver inyectado para actualizar "En línea".

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ✅ Necesario para Presencia
import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ Necesario para Presencia
import 'firebase_options.dart';

// ✅ LOCALIZACIONES
import 'package:flutter_localizations/flutter_localizations.dart';

// Importamos el Portero (Splash)
import 'package:proyectos_matchy/screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

// 🔥 MyApp ahora es StatefulWidget para manejar el Observer de Presencia
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    // 1. Iniciamos la escucha del ciclo de vida de la app
    WidgetsBinding.instance.addObserver(this);
    // 2. Marcamos como online al iniciar
    _updateOnlineStatus(true);
  }

  @override
  void dispose() {
    // 3. Limpiamos el observer al cerrar
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 4. Lógica de cambio de estado:
    // Resumed = App en primer plano.
    // Paused/Inactive/Detached = App minimizada o cerrada.
    if (state == AppLifecycleState.resumed) {
      _updateOnlineStatus(true);
    } else {
      _updateOnlineStatus(false);
    }
  }

  // 🔥 FUNCIÓN MAESTRA DE PRESENCIA
  // Garantiza que el campo 'isOnline' y 'lastSeen' se actualicen en Firestore
  Future<void> _updateOnlineStatus(bool online) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'isOnline': online,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Error silencioso para no interrumpir la experiencia del usuario
      debugPrint("Error actualizando presencia: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Matchy',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Poppins', // Estandarizando la fuente global
      ),

      // 🔴 IDIOMA BASE
      locale: const Locale('es', 'ES'),

      // 🔴 IDIOMAS SOPORTADOS
      supportedLocales: const [
        Locale('es', 'ES'),
        Locale('en', 'US'),
      ],

      // 🔴 DELEGATES
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // ✅ EL PORTERO: Aquí inicia la lógica de sincronización
      home: const SplashScreen(),
    );
  }
}