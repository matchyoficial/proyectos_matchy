// 📂 lib/screens/confirmar_cita.dart
// ✅ PANTALLA ÉXITO BLINDADA (SMART CACHE PRO INYECTADO)
// 🔥 CACHÉ PRO: Renderizado instantáneo (0ms) en las fotos de ambos usuarios.
// 🔥 BLINDAJE: Títulos y nombres protegidos con FittedBox.
// 🔥 UI: Mensajes de racha (naranja/cyan) intactos para evitar encogimiento.

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; // 🔥 Motor de caché
import 'package:proyectos_matchy/screens/panel_screen.dart';

class ConfirmarCitaScreen extends StatefulWidget {
  final String ownerNombre;
  final String ownerFoto;
  final String matchyNombre;
  final String matchyFoto;

  final bool ganaronPuntos;
  final int citasFaltantes;

  const ConfirmarCitaScreen({
    super.key,
    this.ownerNombre = 'Tú',
    this.ownerFoto = '',
    this.matchyNombre = 'Tu Match',
    this.matchyFoto = '',
    this.ganaronPuntos = false,
    this.citasFaltantes = 0,
  });

  @override
  State<ConfirmarCitaScreen> createState() => _ConfirmarCitaScreenState();
}

class _ConfirmarCitaScreenState extends State<ConfirmarCitaScreen> with TickerProviderStateMixin {
  // ===========================================================================
  // 🛡️ ZONA DE CHINCHES MAESTROS (DISEÑO ORIGINAL RESPETADO)
  // ===========================================================================

  static const double kLogoHeight = 45.0;
  static const double kLogoTopSpace = 35.0;

  static const double kSizeTitulo1 = 29.0;
  static const double kSizeTitulo2 = 45.0;
  static const double kSizeSubtitulo = 29.0;
  static const double kSizeNombres = 15.0;
  static const double kSizeTips = 14.0;
  static const double kSizeBtnText = 16.0;

  static const double kFotoSize = 130.0;
  static const double kFotoRadius = 24.0;
  static const double kFotoLabelSize = 0.0;

  static const double kPulseMin = 1.0;
  static const double kPulseMax = 1.05;
  static const int kPulseDurationMs = 1000;

  static const List<Color> kGoldColors = [Color(0xFFFFD700), Color(0xFFFFB300), Color(0xFFFFE082)];
  static const List<Color> kBtnGradient = [Color(0xF7292993), Color(0xFF1A1A24)];
  static const Color kConfettiColor1 = Color(0xFFFFD700);
  static const Color kConfettiColor2 = Color(0xFFFFC107);
  static const Color kConfettiColor3 = Color(0xFFFFF59D);
  static const Color kCyanNeon = Color(0xFF00E5FF);

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _confettiController;
  final List<_Particle> _particles = [];
  final Random _rnd = Random();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: kPulseDurationMs));
    _pulseAnimation = Tween<double>(begin: kPulseMin, end: kPulseMax).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    _confettiController = AnimationController(vsync: this, duration: const Duration(seconds: 10));
    _initConfetti();
    _confettiController.repeat();
    _confettiController.addListener(() {
      if (mounted) setState(() { for (var p in _particles) p.update(); });
    });
  }

  void _initConfetti() {
    for (int i = 0; i < 60; i++) {
      _particles.add(_Particle(random: _rnd));
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _irAlPanel() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const PanelScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(child: Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover)),
            Positioned.fill(child: CustomPaint(painter: _ConfettiPainter(particles: _particles))),

            Column(
              children: [
                const SizedBox(height: kLogoTopSpace),
                SizedBox(height: kLogoHeight, child: Image.asset('assets/images/logomatchyplano.png')),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        const SizedBox(height: 15),

                        ScaleTransition(
                          scale: _pulseAnimation,
                          child: Column(
                            children: const [
                              _GoldText(text: "CITA CONFIRMADA CON", fontSize: kSizeTitulo1),
                              _GoldText(text: "ÉXITO", fontSize: kSizeTitulo2),
                            ],
                          ),
                        ),

                        const SizedBox(height: 15),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFotoFija(widget.ownerNombre, widget.ownerFoto, "TÚ"),
                            const SizedBox(width: 30),
                            _buildFotoFija(widget.matchyNombre, widget.matchyFoto, "TU MATCH"),
                          ],
                        ),

                        const SizedBox(height: 15),

                        // 🛡️ MENSAJE DE RECOMPENSA (SIN FittedBox para evitar encogimiento)
                        if (widget.ganaronPuntos)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.orangeAccent, width: 1),
                            ),
                            child: const Text(
                              "🔥🔥🔥 ¡RACHA COMPLETADA! +20 PUNTOS DE PUNTUALIDAD 🔥🔥🔥",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Color(0xFFFF6D00), fontWeight: FontWeight.w900, fontSize: 14, fontFamily: 'Poppins', letterSpacing: 0.5),
                            ),
                          )
                        else if (widget.citasFaltantes > 0)
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.cyan.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: kCyanNeon.withOpacity(0.5), width: 1),
                            ),
                            child: Text(
                              "¡BIEN HECHO! COMPLETA ${widget.citasFaltantes} ${widget.citasFaltantes == 1 ? 'CITA MÁS' : 'CITAS MÁS'} SEGUIDAS PARA GANAR PUNTOS DE PUNTUALIDAD.",
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: kCyanNeon, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Poppins', letterSpacing: 0.5),
                            ),
                          ),

                        const SizedBox(height: 15),

                        ScaleTransition(
                          scale: _pulseAnimation,
                          child: const _GoldText(text: "¡DISFRUTEN SU CITA!", fontSize: kSizeSubtitulo),
                        ),

                        const SizedBox(height: 18),

                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E2C).withOpacity(0.9),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white12),
                            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 5))],
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.security, color: Color(0xFFBEB3FF), size: 20),
                                  SizedBox(width: 10),
                                  Text("TIPS DE SEGURIDAD", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.0)),
                                ],
                              ),
                              const SizedBox(height: 15),
                              _buildTip("Infórmale a un conocido sobre tu cita, lugar y persona con la que estás."),
                              _buildTip("Toma precauciones si decides ir a otro lugar."),
                              _buildTip("Si ves comportamientos extraños, termina la cita. No estás obligado a quedarte."),
                              _buildTip("Ante cualquier problema, comunícate con un familiar o la línea #123."),
                              _buildTip("En MATCHY velamos por tu seguridad, pero la responsabilidad es tuya."),
                              _buildTip("Te recomendamos mantener tu cita en el lugar pactado."),
                            ],
                          ),
                        ),

                        const SizedBox(height: 21),

                        _PremiumButton(text: "VOLVER AL PANEL", onTap: _irAlPanel),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            Positioned(
              bottom: 0, left: 0, right: 0, height: 100,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.95)],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFotoFija(String nombre, String assetOrUrl, String label) {
    return Column(
      children: [
        if (kFotoLabelSize > 0)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
            child: Text(label, style: const TextStyle(color: Colors.white, fontSize: kFotoLabelSize, fontWeight: FontWeight.bold)),
          ),

        Container(
          width: kFotoSize,
          height: kFotoSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kFotoRadius),
            border: Border.all(color: Colors.white24, width: 2),
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 5))],
            color: Colors.black26,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(kFotoRadius - 2),
            child: assetOrUrl.startsWith('http')
            // 🔥 SMART CACHE INYECTADO
                ? CachedNetworkImage(
              key: ValueKey(assetOrUrl),
              imageUrl: assetOrUrl,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              memCacheHeight: (kFotoSize * 3).toInt(), // Optimizador de RAM
              placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Color(0xFFBEB3FF), strokeWidth: 2)),
              errorWidget: (_,__,___) => Image.asset('assets/images/perfil1.jpg', fit: BoxFit.cover, alignment: Alignment.topCenter),
            )
                : Image.asset(assetOrUrl.isEmpty ? 'assets/images/perfil1.jpg' : assetOrUrl, fit: BoxFit.cover, alignment: Alignment.topCenter, errorBuilder: (_,__,___) => Image.asset('assets/images/perfil1.jpg', fit: BoxFit.cover, alignment: Alignment.topCenter)),
          ),
        ),

        const SizedBox(height: 12),

        SizedBox(
          width: kFotoSize + 20,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                  nombre,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: kSizeNombres, shadows: [Shadow(color: Colors.black, blurRadius: 4)])
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTip(String texto) {
    return Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.check_circle_outline, color: Color(0xFFBEB3FF), size: 16), const SizedBox(width: 10), Expanded(child: Text(texto, style: const TextStyle(color: Colors.white70, fontSize: kSizeTips, height: 1.3)))]));
  }
}

class _GoldText extends StatelessWidget {
  final String text; final double fontSize;
  const _GoldText({required this.text, required this.fontSize});
  @override Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(colors: _ConfirmarCitaScreenState.kGoldColors, begin: Alignment.topCenter, end: Alignment.bottomCenter).createShader(bounds),
          child: Text(text, textAlign: TextAlign.center, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w900, color: Colors.white, fontFamily: 'Poppins', shadows: const [Shadow(color: Colors.black, offset: Offset(0, 2), blurRadius: 4)])),
        ),
      ),
    );
  }
}

class _PremiumButton extends StatelessWidget {
  final String text; final VoidCallback onTap;
  const _PremiumButton({required this.text, required this.onTap});
  @override Widget build(BuildContext context) {
    return GestureDetector(
        onTap: onTap,
        child: Container(
            width: MediaQuery.of(context).size.width * 0.7,
            height: 55,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: _ConfirmarCitaScreenState.kBtnGradient, begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(30), boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 5))], border: Border.all(color: Colors.white24)),
            alignment: Alignment.center,
            child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(text, style: const TextStyle(color: Colors.white, fontSize: _ConfirmarCitaScreenState.kSizeBtnText, fontWeight: FontWeight.w900, letterSpacing: 1.0, fontFamily: 'Poppins'))
            )
        )
    );
  }
}

class _Particle {
  double x=0, y=0, speed=0, theta=0, radius=0; Color color=Colors.yellow;
  final Random random;
  _Particle({required this.random}) { reset(first: true); }
  void reset({bool first = false}) {
    x = random.nextDouble() * 400; y = first ? random.nextDouble() * 800 : -20;
    speed = 2 + random.nextDouble() * 4; theta = random.nextDouble() * 2 * pi; radius = 2 + random.nextDouble() * 3;
    color = [_ConfirmarCitaScreenState.kConfettiColor1, _ConfirmarCitaScreenState.kConfettiColor2, _ConfirmarCitaScreenState.kConfettiColor3, Colors.white][random.nextInt(4)];
  }
  void update() { y += speed; theta += 0.1; x += sin(theta) * 0.5; if (y > 950) reset(); }
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles; _ConfettiPainter({required this.particles});
  @override void paint(Canvas canvas, Size size) { final paint = Paint(); for (var p in particles) { paint.color = p.color; canvas.drawCircle(Offset(p.x, p.y), p.radius, paint); } }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}