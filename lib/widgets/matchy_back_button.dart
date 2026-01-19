// 📂 lib/widgets/matchy_back_button.dart
// 🔙 Botón de regreso reutilizable (ESTILO CHEVRON PROYECTO)
// 🔥 UI: Círculo con borde fino + Icono iOS New.

import 'package:flutter/material.dart';

class MatchyBackButton extends StatelessWidget {
  final double top;   // Distancia desde arriba (dentro del SafeArea)
  final double left;  // Distancia desde la izquierda

  const MatchyBackButton({
    super.key,
    this.top = 10,    // Ajustado para que no quede muy abajo
    this.left = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      child: SafeArea(
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3), // Fondo semitransparente
              shape: BoxShape.circle,               // Totalmente redondo
              border: Border.all(color: Colors.white24, width: 1), // Borde fino
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.arrow_back_ios_new, // El icono Chevron correcto
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}