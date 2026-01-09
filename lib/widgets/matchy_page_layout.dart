// 📂 lib/widgets/matchy_page_layout.dart

import 'package:flutter/material.dart';

/// Layout general Matchy:
/// - Fondo con imagen
/// - Logo arriba
/// - Contenido scrolleable
/// ⚠️ SIN barra inferior (la maneja HomeScreen).
class MatchyPageLayout extends StatelessWidget {
  final String backgroundAsset;   // 🔴 CHINCHE LAYOUT A — fondo
  final String logoAsset;         // 🔴 CHINCHE LAYOUT B — logo
  final Widget scrollContent;     // 🔴 CHINCHE LAYOUT C — contenido

  final double topSpacing;
  final double logoHeight;
  final double logoOffsetY;
  final double spaceLogoToScroll;

  const MatchyPageLayout({
    super.key,
    required this.backgroundAsset,
    required this.logoAsset,
    required this.scrollContent,
    this.topSpacing = 35,
    this.logoHeight = 50,
    this.logoOffsetY = 0,
    this.spaceLogoToScroll = 15,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            backgroundAsset,
            fit: BoxFit.cover,
          ),
        ),
        Column(
          children: [
            SizedBox(height: topSpacing),
            Transform.translate(
              offset: Offset(0, logoOffsetY),
              child: Image.asset(
                logoAsset,
                height: logoHeight,
              ),
            ),
            SizedBox(height: spaceLogoToScroll),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 90),
                child: scrollContent,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
