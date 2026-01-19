// 📂 lib/widgets/lugar_card.dart
// ✅ LugarCard (CON CHINCHES MAESTROS)
// 🔥 FIX: Control total del degradado y sombras de texto.
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
  // 🔴🔴 ZONA DE CHINCHES MAESTROS (CONTROL VISUAL) 🔴🔴
  // ===========================================================================

  // 1. DEGRADADO (FONDO NEGRO DEL TEXTO)
  static const double kGradientOpacity = 0.99; // 0.0 transparente - 1.0 negro total
  static const double kGradientStopStart = 0.68; // Dónde empieza el negro (0.0 arriba - 1.0 abajo)

  // 2. SOMBRA DE TEXTOS (VISIBILIDAD)
  static const double kShadowOffsetX = 1.0;  // Mover sombra horizontal (Der/Izq)
  static const double kShadowOffsetY = 3.0;  // Mover sombra vertical (Arriba/Abajo)
  static const double kShadowBlur = 0.0;     // Intensidad del difuminado
  static const double kShadowOpacity = 1.0;  // Qué tan negra es la sombra (0.0 a 1.0)

  // 3. TAMAÑO CARDS (MODIFICADOR GLOBAL)
  // Suma o resta altura a todas las cards. Ej: 20.0 las hace más largas, -20.0 más cortas.
  static const double kAlturaExtraCards = 0.0;

  // 4. FUENTES
  static const double kNombreFontSize = 22.0;
  static const double kDireccionFontSize = 15.0;

  // 5. ESPACIADOS
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

    // Configuración de la sombra reutilizable
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
          // 🔥 AQUI SE APLICA EL CHINCHE DE ALTURA EXTRA
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
              // 🔹 GRADIENTE INFERIOR
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

              // 🔹 TEXTO CON SOMBRA
              Positioned(
                left: kTextoPaddingH,
                right: kTextoPaddingH,
                bottom: kTextoPaddingBottom,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      lugar.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: kNombreFontSize,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                        shadows: sombrasTexto, // 🔥 Sombra aplicada
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lugar.direccion,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: kDireccionFontSize,
                        fontWeight: FontWeight.w500,
                        height: 1.1,
                        shadows: sombrasTexto, // 🔥 Sombra aplicada
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