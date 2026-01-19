// 📂 lib/widgets/matchy_page_layout.dart

import 'package:flutter/material.dart';

/// Layout general Matchy:
/// - Fondo con imagen
/// - Logo arriba
/// - Contenido scrolleable
/// ⚠️ SIN barra inferior (la maneja HomeScreen).
class MatchyPageLayout extends StatelessWidget {

  // ===========================================================================
  // 🔴🔴 ZONA DE CHINCHES MAESTROS (CONFIGURACIÓN DEL ESQUELETO) 🔴🔴
  // ===========================================================================

  // 1. POSICIÓN VERTICAL DEL LOGO (Desde el techo de la pantalla)
  // Aumenta este valor para bajar todo el bloque del logo.
  static const double kDefaultTopSpacing = 35.0;

  // 2. TAMAÑO DEL LOGO
  // Cambia esto para hacer el logo Matchy más grande o pequeño.
  static const double kDefaultLogoHeight = 45.0;

  // 3. AJUSTE FINO VERTICAL (OFFSET)
  // Usa valores negativos (-10) para subirlo un poco o positivos (10) para bajarlo,
  // sin afectar el espacio de arriba.
  static const double kDefaultLogoOffsetY = 0.0;

  // 4. SEPARACIÓN LOGO -> CONTENIDO
  // Es el aire que hay entre el logo y donde empiezan las tarjetas o textos.
  static const double kDefaultSpaceToScroll = 15.0;

  // 5. FINAL DEL SCROLL (PADDING INFERIOR)
  // IMPORTANTE: Aumenta esto si el último elemento queda tapado por el menú
  // o por el degradado negro inferior. (120 es un valor seguro).
  static const double kDefaultBottomScroll = 120.0;

  // ===========================================================================

  final String backgroundAsset;
  final String logoAsset;
  final Widget scrollContent;

  // Variables que pueden sobreescribir los defaults si se pasan
  final double topSpacing;
  final double logoHeight;
  final double logoOffsetY;
  final double spaceLogoToScroll;
  final double bottomScrollPadding; // Nueva variable para el final

  const MatchyPageLayout({
    super.key,
    required this.backgroundAsset,
    required this.logoAsset,
    required this.scrollContent,
    // Usamos los CHINCHES como valores por defecto:
    this.topSpacing = kDefaultTopSpacing,
    this.logoHeight = kDefaultLogoHeight,
    this.logoOffsetY = kDefaultLogoOffsetY,
    this.spaceLogoToScroll = kDefaultSpaceToScroll,
    this.bottomScrollPadding = kDefaultBottomScroll,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. FONDO (Cubre toda la pantalla)
        Positioned.fill(
          child: Image.asset(
            backgroundAsset,
            fit: BoxFit.cover,
          ),
        ),

        // 2. ESTRUCTURA VERTICAL
        Column(
          children: [
            // Espacio techo
            SizedBox(height: topSpacing),

            // Logo (con ajuste fino)
            Transform.translate(
              offset: Offset(0, logoOffsetY),
              child: Image.asset(
                logoAsset,
                height: logoHeight,
              ),
            ),

            // Espacio entre logo y contenido
            SizedBox(height: spaceLogoToScroll),

            // Contenido Scrolleable (Toma el resto del espacio)
            Expanded(
              child: SingleChildScrollView(
                // Aquí aplicamos el margen inferior para el scroll
                padding: EdgeInsets.only(bottom: bottomScrollPadding),
                physics: const BouncingScrollPhysics(), // Efecto rebote iOS/Android moderno
                child: scrollContent,
              ),
            ),
          ],
        ),
      ],
    );
  }
}