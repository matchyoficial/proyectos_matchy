// 📂 lib/screens/lugar_galeria_screen.dart
// ✅ MATCHY — GALERÍA LUGAR + INFO CITA (FULL SCREEN, SIN SCROLL)
// ✅ Galería swipe horizontal con TODAS las fotos del lugar
// ✅ Info más grande y visible (Matchy style)
// ✅ Sin overflow en ningún dispositivo

import 'package:flutter/material.dart';
import 'package:proyectos_matchy/widgets/matchy_back_button.dart';

class LugarGaleriaScreen extends StatelessWidget {
  static const String routeName = 'lugar_galeria'; // 🔴 CHINCHE ROUTE 1

  final List<String> placePhotos;
  final String placeName;
  final String placeAddress;

  final String fecha;
  final String hora;
  final String preferencia;
  final String intencion;

  const LugarGaleriaScreen({
    super.key,
    required this.placePhotos,
    required this.placeName,
    required this.placeAddress,
    required this.fecha,
    required this.hora,
    required this.preferencia,
    required this.intencion,
  });

  static const String _bg = 'assets/images/fondo.jpg'; // 🔴 CHINCHE STYLE 1
  static const String _logo = 'assets/images/logomatchyplano.png'; // 🔴 CHINCHE STYLE 2
  static const String _fallbackPhoto = 'assets/images/faro1.jpg'; // 🔴 CHINCHE STYLE 3

  bool _isNetwork(String v) => v.startsWith('http://') || v.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    final fotos = placePhotos.isNotEmpty ? placePhotos : <String>[_fallbackPhoto];

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset(_bg, fit: BoxFit.cover)),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, c) {
                // 🔴 CHINCHE LAYOUT 1 — tamaños seguros
                const double side = 18.0;
                const double topPad = 10.0;
                const double logoH = 48.0;
                const double gapAfterLogo = 10.0;
                const double gapGalleryToInfo = 12.0;
                const double buttonH = 52.0;
                const double bottomPad = 14.0;

                final double maxH = c.maxHeight;

                // 🔴 CHINCHE INFO 1 — info más grande
                double infoH = (maxH * 0.26).clamp(150.0, 230.0);

                final double topBlockH = topPad + logoH + gapAfterLogo;
                final double bottomBlockH = bottomPad + buttonH;

                double galleryH = maxH - topBlockH - bottomBlockH - gapGalleryToInfo - infoH;

                // 🔴 CHINCHE GALLERY 1 — mínimo galería
                const double minGalleryH = 260.0;

                if (galleryH < minGalleryH) {
                  final deficit = (minGalleryH - galleryH);
                  infoH = (infoH - deficit).clamp(120.0, infoH);
                  galleryH = maxH - topBlockH - bottomBlockH - gapGalleryToInfo - infoH;
                }

                galleryH = galleryH.clamp(220.0, maxH);

                return Column(
                  children: [
                    SizedBox(height: topPad),
                    Image.asset(_logo, height: logoH),
                    SizedBox(height: gapAfterLogo),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: side),
                      child: SizedBox(
                        height: galleryH,
                        width: double.infinity,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(26),
                          child: PageView.builder(
                            itemCount: fotos.length,
                            itemBuilder: (_, i) {
                              final src = fotos[i].trim();
                              if (src.isEmpty) {
                                return Image.asset(_fallbackPhoto, fit: BoxFit.cover);
                              }
                              if (_isNetwork(src)) {
                                return Image.network(
                                  src,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      Image.asset(_fallbackPhoto, fit: BoxFit.cover),
                                );
                              }
                              return Image.asset(
                                src,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    Image.asset(_fallbackPhoto, fit: BoxFit.cover),
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: gapGalleryToInfo),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: side),
                      child: SizedBox(
                        height: infoH,
                        width: double.infinity,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.34),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: DefaultTextStyle(
                            style: const TextStyle(
                              color: Colors.white,
                              decoration: TextDecoration.none,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  placeName.isEmpty ? 'Lugar' : placeName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 19.0, // 🔴 CHINCHE INFO 2
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  placeAddress.isEmpty ? 'Sin dirección' : placeAddress,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13.5, // 🔴 CHINCHE INFO 3
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'FECHA: $fecha',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 16.0, // 🔴 CHINCHE INFO 4
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      hora,
                                      style: const TextStyle(
                                        fontSize: 16.0, // 🔴 CHINCHE INFO 5
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'PREFERENCIA CITA: $preferencia',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14.0, // 🔴 CHINCHE INFO 6
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'INTENCIÓN: $intencion',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14.0, // 🔴 CHINCHE INFO 7
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: bottomPad),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: side),
                      child: SizedBox(
                        width: double.infinity,
                        height: buttonH,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6A5ACD),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text(
                            'VOLVER',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const MatchyBackButton(top: 10, left: 16),
        ],
      ),
    );
  }
}
