// 📂 lib/main.dart
// ✅ Riverpod root
// ✅ Firebase initializeApp
// ✅ FIX DatePicker/TimePicker en español: MaterialLocalizations + supportedLocales

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// ✅ LOCALIZACIONES (FIX del error rojo)
import 'package:flutter_localizations/flutter_localizations.dart';

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

      // 🔴 CHINCHE MAIN LOCALE 1 — idioma base de la app
      locale: const Locale('es', 'ES'),

      // 🔴 CHINCHE MAIN LOCALE 2 — idiomas soportados
      supportedLocales: const [
        Locale('es', 'ES'),
        Locale('en', 'US'),
      ],

      // 🔴 CHINCHE MAIN LOCALE 3 — delegates obligatorios
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // ✅ Ruta inicial correcta
      home: const SplashScreen(),
    );
  }
}
