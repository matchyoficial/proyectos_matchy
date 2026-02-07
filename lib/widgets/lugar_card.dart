// 📂 lib/widgets/lugar_card.dart
// ✅ LugarCard (CON CHINCHES MAESTROS BLINDADO)
// 🔥 FIX: Blindaje adaptativo para nombres de lugares.
// 🔥 LOGIC: ImageProvider seguro.

import 'package:flutter/material.dart';
import '../models/lugar_data.dart';

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

  // ===========================================================================
  // 🛡️ ZONA DE CHINCHES MAESTROS (BLINDADA)
  // ===========================================================================

  static const double kGradientOpacity = 0.99;
  static const double kGradientStopStart = 0.68;

  static const double kShadowOffsetX = 1.0;
  static const double kShadowOffsetY = 3.0;
  static const double kShadowBlur = 0.0;
  static const double kShadowOpacity = 1.0;

  static const double kAlturaExtraCards = 0.0;

  // 4. FUENTES (Blindaje: bajamos el nombre a 20 para estandarizar títulos)
  static const double kNombreFontSize = 20.0; // Estandarizado a 20 según regla de oro
  static const double kDireccionFontSize = 14.0; // Reducido 1 punto para ganar aire

  static const double kCardRadius = 20.0;
  static const double kTextoPaddingH = 16.0;
  static const double kTextoPaddingBottom = 14.0;
  static const double kEspacioEntreCards = 18.0;

  // ===========================================================================

  bool _esUrl(String v) => v.startsWith('http://') || v.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    final String portada = lugar.fotoPortada.trim();

    ImageProvider<Object> imageProvider;
    if (_esUrl(portada)) {
      imageProvider = NetworkImage(portada);
    } else {
      imageProvider = const AssetImage('assets/images/asset_sitio.jpg');
    }

    final List<Shadow> sombrasTexto = [
      Shadow(
        color: Colors.black.withOpacity(kShadowOpacity),
        offset: const Offset(kShadowOffsetX, kShadowOffsetY),
        blurRadius: kShadowBlur,
      ),
    ];

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: kEspacioEntreCards),
        child: Container(
          height: altoTarjeta + kAlturaExtraCards,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kCardRadius),
            image: DecorationImage(
              image: imageProvider,
              fit: BoxFit.cover,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(kCardRadius),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(kGradientOpacity),
                      ],
                      stops: const [kGradientStopStart, 1.0],
                    ),
                  ),
                ),
              ),

              // 🔹 TEXTO BLINDADO
              Positioned(
                left: kTextoPaddingH,
                right: kTextoPaddingH,
                bottom: kTextoPaddingBottom,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // BLINDAJE: Nombre adaptativo
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        lugar.nombre.toUpperCase(), // Forzamos mayúsculas para estilo Matchy
                        maxLines: 1,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: kNombreFontSize,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                          shadows: sombrasTexto,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // BLINDAJE: Dirección adaptativa
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        lugar.direccion,
                        maxLines: 1,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: kDireccionFontSize,
                          fontWeight: FontWeight.w500,
                          height: 1.1,
                          shadows: sombrasTexto,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}