// 📂 lib/main.dart
// ✅ Flujo: Splash → Registro → Home (Panel)
// ✅ PASO 4.2: Activar Riverpod (estado/lógica segura)

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // ✅ IMPORTANTE

// ✅ Riverpod
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 🔴 CHINCHE MAIN R1 — ProviderScope

// 🔴 CHINCHE MAIN A — Importar pantallas principales
import 'package:proyectos_matchy/screens/splash_screen.dart';
import 'package:proyectos_matchy/screens/registro_screen.dart';
import 'package:proyectos_matchy/home_screen.dart';

void main() {
  // 🔴 CHINCHE MAIN R2 — Envolvemos toda la app con ProviderScope
  // Esto habilita Riverpod para TODO el proyecto (Android + iOS).
  runApp(
    const ProviderScope(
      child: MatchyApp(),
    ),
  );
}

class MatchyApp extends StatelessWidget {
  const MatchyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // 🌍 Localización en español
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'),
      ],
      locale: const Locale('es', 'ES'),

      // 🔴 CHINCHE MAIN B — Pantalla inicial: Splash
      home: const SplashScreen(),

      // 🔴 CHINCHE MAIN C — Rutas por nombre (opcionales)
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/registro': (context) => const RegistroScreen(),
        '/home': (context) => const HomeScreen(),
      },

      // 🔴 CHINCHE MAIN D — Tema global
      theme: ThemeData(
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: Colors.black,
        useMaterial3: true,
      ),
    );
  }
}
