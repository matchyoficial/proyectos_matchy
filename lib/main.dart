// 📂 lib/main.dart
// ✅ MAIN LIMPIO: Configuraciones globales y punto de entrada.
// ✅ LOCALIZACIONES: Español configurado correctamente.
// ✅ HOME: Apunta a SplashScreen, que ahora actúa como el "Portero Maestro".

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Matchy',
      theme: ThemeData(useMaterial3: true),

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