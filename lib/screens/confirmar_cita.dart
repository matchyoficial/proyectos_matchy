// 📂 lib/screens/confirmar_cita.dart
// ✅ PANTALLA ÉXITO (FIX CONSTRUCTOR + CONFETI + PULSO)
// 🔥 FIX: Parámetros opcionales para evitar errores de compilación en otras pantallas.
// 🔥 UI: Confeti dorado programático infinito.
// 🔥 UI: Textos dorados con pulso infinito y control total.
// 🔥 UI: Cápsulas de fotos limpias.
// 🔥 NAV: Bloqueo de botón atrás (WillPopScope / PopScope).

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:proyectos_matchy/screens/panel_screen.dart';

class ConfirmarCitaScreen extends StatefulWidget {
  // ✅ FIX: Ya no son 'required' para que no rompa tu otro archivo.
  // Si no se pasan datos, usa los valores por defecto (= ...).
  final String ownerNombre;
  final String ownerFoto;
  final String matchyNombre;
  final String matchyFoto;

  const ConfirmarCitaScreen({
    super.key,
    this.ownerNombre = 'Tú',
    this.ownerFoto = '', // Se manejará con placeholder si llega vacía
    this.matchyNombre = 'Tu Match',
    this.matchyFoto = '',
  });

  @override
  State<ConfirmarCitaScreen> createState() => _ConfirmarCitaScreenState();
}

class _ConfirmarCitaScreenState extends State<ConfirmarCitaScreen> with TickerProviderStateMixin {
  // ===========================================================================
  // 🔴🔴 ZONA DE CHINCHES MAESTROS (CONTROL TOTAL) 🔴🔴
  // ===========================================================================

  // 1. LOGO
  static const double kLogoHeight = 45.0;
  static const double kLogoTopSpace = 35.0;

  // 2. TEXTOS Y TÍTULOS
  static const double kSizeTitulo1 = 29.0;      // "CITA CONFIRMADA CON"
  static const double kSizeTitulo2 = 45.0;      // "ÉXITO"
  static const double kSizeSubtitulo = 29.0;    // "DISFRUTEN SU CITA"
  static const double kSizeNombres = 15.0;      // Nombres bajo fotos
  static const double kSizeTips = 14.0;         // Texto de los tips
  static const double kSizeBtnText = 16.0;      // Texto botón

  // 3. FOTOS
  static const double kFotoRadius = 18.0;       // Redondeo fotos
  static const double kFotoSize = 160.0;        // Tamaño cuadrado fotos
  static const double kFotoLabelSize = 0.0;    // "TÚ" / "TU MATCH"

  // 4. ANIMACIONES (PULSO)
  static const double kPulseMin = 1.0;
  static const double kPulseMax = 1.05;
  static const int kPulseDurationMs = 1000;

  // 5. COLORES Y ESTILOS
  static const List<Color> kGoldColors = [Color(0xFFFFD700), Color(0xFFFFB300), Color(0xFFFFE082)];
  static const List<Color> kBtnGradient = [Color(0xF7292993), Color(0xFF1A1A24)];
  static const Color kConfettiColor1 = Color(0xFFFFD700);
  static const Color kConfettiColor2 = Color(0xFFFFC107);
  static const Color kConfettiColor3 = Color(0xFFFFF59D);

  // ===========================================================================

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Confeti
  late AnimationController _confettiController;
  final List<_Particle> _particles = [];
  final Random _rnd = Random();

  @override
  void initState() {
    super.initState();

    // 1. Animación Pulso Infinito
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: kPulseDurationMs));
    _pulseAnimation = Tween<double>(begin: kPulseMin, end: kPulseMax).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    // 2. Confeti Infinito
    _confettiController = AnimationController(vsync: this, duration: const Duration(seconds: 10)); // Duración base para ticks
    _initConfetti();
    _confettiController.repeat(); // Loop infinito
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
    // Bloquear botón atrás físico de Android
    return PopScope(
      canPop: false, // Bloquea el gesto de volver
      onPopInvoked: (didPop) {
        if (didPop) return;
        // Opcional: Mostrar mensaje o simplemente no hacer nada
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // 1. FONDO
            Positioned.fill(child: Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover)),

            // 2. CONFETI (Detrás del contenido pero sobre el fondo)
            Positioned.fill(child: CustomPaint(painter: _ConfettiPainter(particles: _particles))),

            // 3. CONTENIDO
            Column(
              children: [
                SizedBox(height: kLogoTopSpace),
                SizedBox(height: kLogoHeight, child: Image.asset('assets/images/logomatchyplano.png')),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        const SizedBox(height: 15),

                        // 🔥 TÍTULOS DORADOS PULSANTES
                        ScaleTransition(
                          scale: _pulseAnimation,
                          child: Column(
                            children: [
                              _GoldText(text: "CITA CONFIRMADA CON", fontSize: kSizeTitulo1),
                              _GoldText(text: "ÉXITO", fontSize: kSizeTitulo2),
                            ],
                          ),
                        ),

                        const SizedBox(height: 5),

                        // 🔥 CÁPSULAS FOTOS (LIMPIAS)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFotoCapsula(widget.ownerNombre, widget.ownerFoto, "TÚ"),
                            const SizedBox(width: 19),
                            _buildFotoCapsula(widget.matchyNombre, widget.matchyFoto, "TU MATCH"),
                          ],
                        ),

                        const SizedBox(height: 9),

                        ScaleTransition(
                          scale: _pulseAnimation,
                          child: const _GoldText(text: "¡DISFRUTEN SU CITA!", fontSize: kSizeSubtitulo),
                        ),

                        const SizedBox(height: 13),

                        // 🔥 TIPS DE SEGURIDAD
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

                        // BOTÓN VOLVER (ÚNICA SALIDA)
                        _PremiumButton(text: "VOLVER AL PANEL", onTap: _irAlPanel),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // 4. FADE OUT
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

  // ... (Helpers visuales) ...
  Widget _buildFotoCapsula(String nombre, String assetOrUrl, String label) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
          child: Text(label, style: const TextStyle(color: Colors.white, fontSize: _ConfirmarCitaScreenState.kFotoLabelSize, fontWeight: FontWeight.bold)),
        ),
        Container(
          width: kFotoSize, height: kFotoSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kFotoRadius),
            border: Border.all(color: Colors.white24, width: 2),
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 4))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(kFotoRadius - 2),
            child: assetOrUrl.startsWith('http')
                ? Image.network(assetOrUrl, fit: BoxFit.cover, errorBuilder: (_,__,___) => Image.asset('assets/images/perfil1.jpg', fit: BoxFit.cover))
                : Image.asset(assetOrUrl.isEmpty ? 'assets/images/perfil1.jpg' : assetOrUrl, fit: BoxFit.cover, errorBuilder: (_,__,___) => Image.asset('assets/images/perfil1.jpg', fit: BoxFit.cover)),
          ),
        ),
        const SizedBox(height: 12),
        Text(nombre, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: kSizeNombres, shadows: [Shadow(color: Colors.black, blurRadius: 4)])),
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
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(colors: _ConfirmarCitaScreenState.kGoldColors, begin: Alignment.topCenter, end: Alignment.bottomCenter).createShader(bounds),
      child: Text(text, textAlign: TextAlign.center, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w900, color: Colors.white, fontFamily: 'Poppins', shadows: const [Shadow(color: Colors.black, offset: Offset(0, 2), blurRadius: 4)])),
    );
  }
}

class _PremiumButton extends StatelessWidget {
  final String text; final VoidCallback onTap;
  const _PremiumButton({required this.text, required this.onTap});
  @override Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: Container(width: MediaQuery.of(context).size.width * 0.7, height: 55, decoration: BoxDecoration(gradient: const LinearGradient(colors: _ConfirmarCitaScreenState.kBtnGradient, begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(30), boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 5))], border: Border.all(color: Colors.white24)), alignment: Alignment.center, child: Text(text, style: const TextStyle(color: Colors.white, fontSize: _ConfirmarCitaScreenState.kSizeBtnText, fontWeight: FontWeight.w900, letterSpacing: 1.0, fontFamily: 'Poppins'))));
  }
}

// Confeti Classes (Reciclaje infinito)
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