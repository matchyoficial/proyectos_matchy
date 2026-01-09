// 📂 lib/widgets/matchy_back_button.dart
// 🔙 Botón de regreso reutilizable

import 'package:flutter/material.dart';

class MatchyBackButton extends StatelessWidget {
  final double top;   // 🔴 CHINCHE BACK A — distancia desde arriba
  final double left;  // 🔴 CHINCHE BACK B — distancia desde la izquierda

  const MatchyBackButton({
    super.key,
    this.top = 20,     // ← lo bajamos de 40 a 20
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
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.45),
              borderRadius: BorderRadius.circular(19),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}
