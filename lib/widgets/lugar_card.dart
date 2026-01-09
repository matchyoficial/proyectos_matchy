// 📂 lib/widgets/lugar_card.dart
// ✅ Card reutilizable para Restaurantes / Bares / Cafés / Actividades
// ✅ Mantiene el diseño original (imagen + degradado + textos)

import 'package:flutter/material.dart';
import '../models/lugar_data.dart'; // ✅ import relativo seguro

class LugarCard extends StatelessWidget {
  final LugarData lugar;
  final double altoTarjeta;
  final VoidCallback onTap;

  const LugarCard({
    super.key,
    required this.lugar,
    required this.altoTarjeta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String image =
    lugar.fotos.isNotEmpty ? lugar.fotos.first : 'assets/images/perfil1.jpg';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: altoTarjeta,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.45),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
          image: DecorationImage(
            image: AssetImage(image),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          alignment: Alignment.bottomLeft,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.8),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lugar.nombre,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
                ),
              ),
              Text(
                lugar.direccion,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
