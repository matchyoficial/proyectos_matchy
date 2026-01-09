// 📂 lib/screens/faro_pizzeria_screen.dart
// ✅ Wrapper: Faro -> Plantilla genérica con data
// ✅ Sin lógica UI duplicada
// ✅ Fuente única de datos

import 'package:flutter/material.dart';
import 'package:proyectos_matchy/models/lugar_data.dart';
import 'package:proyectos_matchy/screens/lugar_plantilla_screen.dart';

class FaroPizzeriaScreen extends StatelessWidget {
  static const String routeName = 'faro';

  const FaroPizzeriaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const LugarData lugar = LugarData(
      id: 'faro', // 🔴 CHINCHE FARO DATA 1 — id único
      nombre: 'EL FARO PIZZERIA', // 🔴 CHINCHE FARO DATA 2
      direccion: 'Carrera 66 #5-152', // 🔴 CHINCHE FARO DATA 3
      bio:
      'El Faro Pizzería, fundada en el 2003 brinda una programación especial todos los días. '
          'Es el ambiente perfecto para disfrutar con amigos, buena música y una excelente pizza.', // 🔴 CHINCHE FARO DATA 4

      // 🔴 CHINCHE FARO FIX 1 — lista CONST (obligatorio)
      fotos: const [
        'assets/images/faro1.jpg',
        'assets/images/faro2.jpg',
        'assets/images/faro3.jpg',
        'assets/images/faro4.jpg',
        'assets/images/faro5.jpg',
        'assets/images/faro6.jpg',
        'assets/images/faro7.jpg',
        'assets/images/faro8.jpg',
      ],

      menuPdf: 'faro_pdf.pdf', // 🔴 CHINCHE FARO DATA 6 — pendiente backend
      mapsQuery: 'Carrera 66 #5-152, Cali', // 🔴 CHINCHE FARO DATA 7 (opcional)
    );

    return const LugarPlantillaScreen(
      lugar: lugar,
    );
  }
}
