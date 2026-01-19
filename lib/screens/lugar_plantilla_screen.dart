// 📂 lib/screens/lugar_plantilla_screen.dart
// ✅ LUGAR PLANTILLA (DISEÑO PREMIUM + GALERÍA PRO)
// 🔥 UI: Galería con Zoom y Dots indicadores.
// 🔥 UI: Textos centrados con sombra, Bio justificada.
// 🔥 UI: Botones Premium y Fade Out inferior.
// ✅ LOGIC: Mantiene el Switch (Cita Pública vs Matchy Privada).

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:proyectos_matchy/models/lugar_data.dart';
import 'package:proyectos_matchy/screens/creacita_screen.dart';
import 'package:proyectos_matchy/screens/crea_cita_matchy_screen.dart';

class LugarPlantillaScreen extends StatefulWidget {
  final LugarData lugar;
  final String? matchyUidInvitado;

  const LugarPlantillaScreen({
    super.key,
    required this.lugar,
    this.matchyUidInvitado,
  });

  @override
  State<LugarPlantillaScreen> createState() => _LugarPlantillaScreenState();
}

class _LugarPlantillaScreenState extends State<LugarPlantillaScreen> {
  // ===========================================================================
  // 🔴🔴 ZONA DE CHINCHES MAESTROS (CONFIGURACIÓN VISUAL) 🔴🔴
  // ===========================================================================

  // 1. LOGO
  static const double kLogoHeight = 50.0;
  static const double kLogoTopSpace = 40.0;

  // 2. TEXTOS
  static const List<Shadow> kTextShadow = [
    Shadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 6),
  ];
  static const TextStyle kTitleStyle = TextStyle(
      color: Colors.white,
      fontSize: 28,
      fontWeight: FontWeight.w900,
      fontFamily: 'Poppins',
      height: 1.1,
      shadows: kTextShadow
  );
  static const TextStyle kAddressStyle = TextStyle(
      color: Colors.white70,
      fontSize: 16,
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w500,
      shadows: kTextShadow
  );

  // 3. BOTONES
  static const List<Color> kGradientAction = [Color(0xFF6B4EE6), Color(0xFF4527A0)];
  static const List<Color> kGradientWeb = [Color(0xFF007BFF), Color(0xFF0056B3)];

  // ===========================================================================

  final PageController _pageCtrl = PageController();
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Auto-scroll de la galería
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      if (widget.lugar.fotos.length < 2) return;
      final next = ((_pageCtrl.page?.round() ?? 0) + 1) % widget.lugar.fotos.length;
      _pageCtrl.animateToPage(next, duration: const Duration(milliseconds: 800), curve: Curves.easeInOutCubic);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lugar = widget.lugar;
    final bool esCitaPrivada = widget.matchyUidInvitado != null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. FONDO
          Positioned.fill(child: Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover)),

          Column(
            children: [
              SizedBox(height: kLogoTopSpace),
              SizedBox(height: kLogoHeight, child: Image.asset('assets/images/logomatchyplano.png')),
              const SizedBox(height: 16),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center, // Centrado general
                    children: [

                      // 🔥 GALERÍA PRO (Zoom + Dots)
                      _buildProGallery(lugar.fotos),

                      const SizedBox(height: 20),

                      // TITULO Y DIRECCIÓN CENTRADOS CON SOMBRA
                      Text(lugar.nombre.toUpperCase(), textAlign: TextAlign.center, style: kTitleStyle),
                      const SizedBox(height: 6),
                      Text(lugar.direccion, textAlign: TextAlign.center, style: kAddressStyle),

                      const SizedBox(height: 20),

                      // BIO JUSTIFICADA
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Text(
                            lugar.bio,
                            textAlign: TextAlign.justify, // Justificado
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                height: 1.5,
                                fontFamily: 'Poppins'
                            )
                        ),
                      ),

                      const SizedBox(height: 30),

                      // BOTÓN WEB (Si existe)
                      if (lugar.hasSitioWeb) ...[
                        _PremiumButton(
                          text: "VISITAR SITIO WEB",
                          gradient: kGradientWeb,
                          icon: Icons.public,
                          onTap: () async => launchUrl(Uri.parse(lugar.sitioWeb)),
                        ),
                        const SizedBox(height: 16)
                      ],

                      // 🔥 BOTÓN ACCIÓN (EL SWITCH)
                      _PremiumButton(
                          text: esCitaPrivada ? "INVITAR A TU MATCHY" : "CREAR CITA AQUÍ",
                          gradient: kGradientAction,
                          icon: Icons.calendar_month_rounded,
                          onTap: () {
                            if (esCitaPrivada) {
                              Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => CreaCitaMatchyScreen(
                                    lugar: lugar,
                                    matchyUidInvitado: widget.matchyUidInvitado!,
                                  )
                              ));
                            } else {
                              Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => CreaCitaScreen(lugar: lugar)
                              ));
                            }
                          }
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 2. 🔥 DEGRADADO INFERIOR (FADE OUT)
          Positioned(
            bottom: 0, left: 0, right: 0, height: 100,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.95)],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // 3. BOTÓN ATRÁS
          const Positioned(
              top: 50, left: 16,
              child: _BotonAtrasSimple()
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // WIDGET: GALERÍA PRO (Slider + Zoom + Dots)
  // ===============================================================
  Widget _buildProGallery(List<String> fotos) {
    return Column(
      children: [
        Container(
          height: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 15, offset: Offset(0, 8))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                PageView.builder(
                    controller: _pageCtrl,
                    itemCount: fotos.length,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemBuilder: (_, i) {
                      // InteractiveViewer permite hacer Zoom con los dedos
                      return InteractiveViewer(
                        child: Image.network(
                          fotos[i],
                          fit: BoxFit.cover,
                          loadingBuilder: (_, child, progress) => progress == null ? child : Container(color: Colors.white10, child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                          errorBuilder: (_,__,___) => Container(color: Colors.grey[800], child: const Icon(Icons.broken_image, color: Colors.white54)),
                        ),
                      );
                    }
                ),

                // Gradiente interno para que se vean los dots
                Positioned(
                  bottom: 0, left: 0, right: 0, height: 60,
                  child: Container(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.topCenter, end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black.withOpacity(0.6)]
                        )
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // DOTS INDICATORS
        if (fotos.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(fotos.length, (index) {
              final bool isActive = index == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 6,
                width: isActive ? 24 : 6, // Píldora si activo, punto si no
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFFBEB3FF) : Colors.white24,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
      ],
    );
  }
}

// ===============================================================
// WIDGET: BOTÓN PREMIUM REUTILIZABLE
// ===============================================================
class _PremiumButton extends StatelessWidget {
  final String text;
  final List<Color> gradient;
  final VoidCallback onTap;
  final IconData? icon;

  const _PremiumButton({required this.text, required this.gradient, required this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradient),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: gradient.last.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6)),
          ],
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if(icon != null)...[Icon(icon, color: Colors.white, size: 20), const SizedBox(width: 10)],
            Text(
                text,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    fontFamily: 'Poppins',
                    letterSpacing: 1.0
                )
            ),
          ],
        ),
      ),
    );
  }
}

// ===============================================================
// WIDGET: BOTÓN ATRÁS SIMPLE
// ===============================================================
class _BotonAtrasSimple extends StatelessWidget {
  const _BotonAtrasSimple();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white12)
        ),
        child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
      ),
    );
  }
}