// 📂 lib/widgets/lugar_card.dart
// ✅ LugarCard (CON CHINCHES MAESTROS BLINDADO Y SMART CACHE PRO)
// 🔥 FIX: Blindaje adaptativo para nombres de lugares.
// 🔥 CACHÉ: Inyección de CachedNetworkImage con ValueKey.
// 🔥 RENDIMIENTO: memCacheHeight activado para carga ultrarrápida de las primeras 4 cartas.
// 🔥 UX: Spinner oscuro exclusivo para carga. Asset local SOLO para errores o sin foto.

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
  static const double kNombreFontSize = 20.0;
  static const double kDireccionFontSize = 14.0;

  static const double kCardRadius = 20.0;
  static const double kTextoPaddingH = 16.0;
  static const double kTextoPaddingBottom = 14.0;
  static const double kEspacioEntreCards = 18.0;

  // ===========================================================================

  bool _esUrl(String v) => v.startsWith('http://') || v.startsWith('https://');

  // 🔥 MÉTODO MAESTRO: Dibuja la tarjeta completa usando cualquier ImageProvider
  Widget _buildCardContent(ImageProvider imageProvider) {
    final List<Shadow> sombrasTexto = [
      Shadow(
        color: Colors.black.withOpacity(kShadowOpacity),
        offset: const Offset(kShadowOffsetX, kShadowOffsetY),
        blurRadius: kShadowBlur,
      ),
    ];

    return Container(
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
          // 🔹 GRADIENTE OSCURO INFERIOR
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
                      fontFamily: 'Poppins',
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
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 MÉTODO SPINNER: Mantiene la estructura visual intacta mientras carga
  Widget _buildLoadingPlaceholder() {
    return Container(
      height: altoTarjeta + kAlturaExtraCards,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A), // Fondo oscuro elegante
        borderRadius: BorderRadius.circular(kCardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFBEB3FF), // Morado Matchy
          strokeWidth: 2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String portada = lugar.fotoPortada.trim();
    final ImageProvider defaultAsset = const AssetImage('assets/images/asset_sitio.jpg');

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: kEspacioEntreCards),
        child: _esUrl(portada)
        // 🔥 SI ES URL, USAMOS EL MOTOR DE CACHÉ
            ? CachedNetworkImage(
          key: ValueKey(portada),
          imageUrl: portada,
          // 🚀 SUPERCARGADOR DE MEMORIA:
          // Multiplicamos por 3 (aprox. pixel ratio) para que la imagen se decodifique
          // exactamente al tamaño que se necesita, liberando RAM y acelerando la carga inicial.
          memCacheHeight: (altoTarjeta * 3).toInt(),

          // Construimos la tarjeta usando la imagen descargada/cacheada
          imageBuilder: (context, imageProvider) => _buildCardContent(imageProvider),

          // Mientras carga, mostramos ÚNICAMENTE el spinner oscuro
          placeholder: (context, url) => _buildLoadingPlaceholder(),

          // Si la URL falla (ej. borraste la foto de Firebase), mostramos el asset local
          errorWidget: (context, url, error) => _buildCardContent(defaultAsset),
        )
        // 🔥 SI NO ES URL (Viene vacío o corrupto), USAMOS ASSET DIRECTO
            : _buildCardContent(defaultAsset),
      ),
    );
  }
}