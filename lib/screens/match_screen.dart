// 📂 lib/screens/match_screen.dart
// ✅ MATCH SCREEN — “TENEMOS UN MATCHY”
// ✅ FIX: título en 2 renglones + padding lateral para no recortarse
// ✅ LOGICA: botón "INICIAR CHAT..." crea/asegura thread en provider y navega a ChatDetalleScreen
// ⚠️ NO cambia diseños (solo el título como pediste)

import 'dart:math' as math;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:proyectos_matchy/state/profile_form_provider.dart';
import 'package:proyectos_matchy/screens/chat_screen.dart'; // 🔴 provider + modelos
import 'package:proyectos_matchy/screens/chat_detalle_screen.dart';

class MatchScreen extends ConsumerStatefulWidget {
  // 🔴 CHINCHE MATCH DATA 1 — ID estable del candidato (chica1, chica4, etc.)
  final String candidatoId;

  // Datos candidato (izquierda)
  final String candidatoNombre;
  final int candidatoEdad;
  final String candidatoFotoAsset;

  const MatchScreen({
    super.key,
    required this.candidatoId,
    required this.candidatoNombre,
    required this.candidatoEdad,
    required this.candidatoFotoAsset,
  });

  @override
  ConsumerState<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends ConsumerState<MatchScreen>
    with TickerProviderStateMixin {
  late final AnimationController _titleCtrl;
  late final AnimationController _cardsCtrl;
  late final AnimationController _confettiCtrl;
  late final AnimationController _buttonPulseCtrl;

  late final List<_ConfettiPiece> _confetti;

  // ============================================================
  // 🔴 CHINCHE MATCH UI 1 — tamaños generales (NUMÉRICOS)
  // ============================================================
  static const double topLogoSpace = 28.0; // 🔴
  static const double logoHeight = 48.0; // 🔴
  static const double titleTopSpace = 10.0; // 🔴
  static const double cardsTopSpace = 18.0; // 🔴
  static const double cardsHeight = 230.0; // 🔴
  static const double namesTopSpace = 12.0; // 🔴
  static const double buttonTopSpace = 18.0; // 🔴
  static const double buttonHeight = 52.0; // 🔴
  static const double sidePadding = 18.0; // 🔴
  static const double midGapAfterNames = 10.0; // 🔴

  // ============================================================
  // 🔴 CHINCHE TITLE 1 — PADDING LATERAL Y 2 RENGLONES
  // ============================================================
  static const double titleSidePadding = 14.0; // 🔴 CHINCHE (aumenta si quieres más aire)
  static const double titleLineGap = 2.0; // 🔴 CHINCHE separación entre renglones
  static const double titleLine1FontSize = 34.0; // 🔴 CHINCHE "TENEMOS UN" (mismo tamaño)
  static const double titleLine2FontSize = 44.0; // 🔴 CHINCHE "MATCHY" (más grande)
  static const double titleLetterSpacing = 0.6; // 🔴
  static const double titleShadowBlur = 14.0; // 🔴
  static const double titleShadowOffsetY = 5.0; // 🔴

  // ============================================================
  // 🔴 CHINCHE CARDS 1 — CONTROL ANCHO/ESPACIADO
  // ============================================================
  static const double cardsHorizontalGap = 14.0; // 🔴
  static const double cardRadius = 26.0; // 🔴
  static const double cardBorder = 3.0; // 🔴
  static const double cardMinWidth = 145.0; // 🔴
  static const double cardMaxWidth = 190.0; // 🔴

  // ============================================================
  // 🔴 CHINCHE HEART 1 — tamaño/posición del corazón central
  // ============================================================
  static const double heartSize = 74.0; // 🔴
  static const double heartIconSize = 36.0; // 🔴
  static const double heartBorderWidth = 2.0; // 🔴
  static const double heartScaleAmp = 0.06; // 🔴

  // ============================================================
  // 🔴 CHINCHE NAME 1 — tamaños nombres (debajo)
  // ============================================================
  static const double nameFontSize = 18.0; // 🔴
  static const double nameOpacity = 0.92; // 🔴
  static const double nameBoxRadius = 18.0; // 🔴
  static const double nameBoxPadH = 10.0; // 🔴
  static const double nameBoxPadV = 12.0; // 🔴

  // ============================================================
  // 🔴 CHINCHE TEXTOS ABAJO
  // ============================================================
  static const double quoteFontSize = 15.0; // 🔴
  static const double noteFontSize = 12.0; // 🔴
  static const double noteTopGap = 6.0; // 🔴

  // ============================================================
  // 🔴 CHINCHE COLORS — Matchy vibe
  // ============================================================
  static const Color matchyPurple = Color(0xFF7E79B6);
  static const Color matchyLilac = Color(0xFFE0D4FF);
  static const Color matchyYellow = Color(0xFFFFC107);
  static const Color noteRed = Color(0xFFFF5252);

  @override
  void initState() {
    super.initState();

    _titleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _cardsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _buttonPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();

    _confetti = _buildConfettiPieces(90); // 🔴 CHINCHE CONFETTI 1
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _cardsCtrl.dispose();
    _confettiCtrl.dispose();
    _buttonPulseCtrl.dispose();
    super.dispose();
  }

  List<_ConfettiPiece> _buildConfettiPieces(int count) {
    final rnd = math.Random();
    return List.generate(count, (_) {
      return _ConfettiPiece(
        x: rnd.nextDouble(),
        y: rnd.nextDouble(),
        size: 4.0 + rnd.nextDouble() * 8.0,
        speed: 0.2 + rnd.nextDouble() * 0.9,
        rot: rnd.nextDouble() * math.pi,
        rotSpeed: (rnd.nextDouble() - 0.5) * 1.8,
        hue: rnd.nextDouble(),
      );
    });
  }

  String _primerNombre(String full) {
    final clean = full.trim();
    if (clean.isEmpty) return 'Usuario';
    return clean.split(RegExp(r'\s+')).first;
  }

  // ✅ ACCIÓN: crear/asegurar thread y abrir ChatDetalleScreen
  void _startChat() {
    final profile = ref.read(profileFormProvider);

    final String miNombre = _primerNombre(profile.nombre);
    final int miEdad = int.tryParse(profile.edad.trim()) ?? 0;

    final String suNombre = _primerNombre(widget.candidatoNombre);
    final int suEdad = widget.candidatoEdad;

    // ✅ 1) Guardar/asegurar en la lista de chats
    ref.read(chatThreadsProvider.notifier).upsertThread(
      id: widget.candidatoId,
      nombre: suNombre,
      edad: suEdad,
      fotoAsset: widget.candidatoFotoAsset,
    );

    // ✅ 2) Abrir pantalla de chat detalle real
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatDetalleScreen(
          nombre: suNombre,
          edad: suEdad.toString(),
          id: widget.candidatoId,
        ),
      ),
    );

    // Snack mini para feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Chat creado: $miNombre ↔ $suNombre'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileFormProvider);

    final String miNombre = _primerNombre(profile.nombre);
    final int miEdad = int.tryParse(profile.edad.trim()) ?? 0;

    // Foto principal del usuario
    final String? miFoto = profile.fotosCargadas.isNotEmpty
        ? profile.fotosCargadas.first
        : null;

    final bool miFotoIsFile = (miFoto ?? '').startsWith('/') ||
        (miFoto ?? '').contains(r':\') ||
        (miFoto ?? '').startsWith('file:');

    final String miFotoFallback = 'assets/images/perfil1.jpg';

    final String suNombre = _primerNombre(widget.candidatoNombre);
    final int suEdad = widget.candidatoEdad;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover),
          ),

          // Confeti
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _confettiCtrl,
                builder: (_, __) {
                  return CustomPaint(
                    painter: _ConfettiPainter(
                      t: _confettiCtrl.value,
                      pieces: _confetti,
                    ),
                  );
                },
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: sidePadding),
              child: Column(
                children: [
                  const SizedBox(height: topLogoSpace),

                  SizedBox(
                    height: logoHeight,
                    child: Image.asset('assets/images/logomatchyplano.png'),
                  ),

                  const SizedBox(height: titleTopSpace),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  ),

                  // ============================================================
                  // ✅ TÍTULO NUEVO: 2 RENGLONES + PADDING LATERAL
                  // ============================================================
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: titleSidePadding, // 🔴 CHINCHE
                    ),
                    child: AnimatedBuilder(
                      animation: _titleCtrl,
                      builder: (_, __) {
                        final bounce =
                            1.0 + (math.sin(_titleCtrl.value * math.pi) * 0.05);

                        return Transform.scale(
                          scale: bounce,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _AnimatedGradientTitle(
                                text: 'TENEMOS UN',
                                fontSize: titleLine1FontSize, // 🔴 CHINCHE
                                letterSpacing: titleLetterSpacing,
                                shadowBlur: titleShadowBlur,
                                shadowOffsetY: titleShadowOffsetY,
                                t: _titleCtrl.value,
                              ),
                              const SizedBox(height: titleLineGap), // 🔴 CHINCHE
                              _AnimatedGradientTitle(
                                text: 'MATCHY',
                                fontSize: titleLine2FontSize, // 🔴 CHINCHE
                                letterSpacing: titleLetterSpacing,
                                shadowBlur: titleShadowBlur,
                                shadowOffsetY: titleShadowOffsetY,
                                t: _titleCtrl.value,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: cardsTopSpace),

                  // Cards (igual)
                  SizedBox(
                    height: cardsHeight,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final double totalW = constraints.maxWidth;
                        final double rawCardW =
                            (totalW - cardsHorizontalGap) / 2.0;

                        final double cardW = rawCardW
                            .clamp(cardMinWidth, cardMaxWidth)
                            .toDouble();

                        final double rowW = (cardW * 2.0) + cardsHorizontalGap;

                        final double wiggle =
                            math.sin(_cardsCtrl.value * math.pi * 2.0) * 6.0;

                        return Center(
                          child: SizedBox(
                            width: rowW,
                            height: cardsHeight,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Transform.translate(
                                      offset: Offset(0.0, -wiggle),
                                      child: _MatchPhotoCard(
                                        width: cardW,
                                        height: cardsHeight,
                                        label: 'TU MATCH',
                                        image: Image.asset(
                                          widget.candidatoFotoAsset,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              Image.asset(miFotoFallback,
                                                  fit: BoxFit.cover),
                                        ),
                                        radius: cardRadius,
                                        border: cardBorder,
                                        glowColor: matchyYellow,
                                      ),
                                    ),
                                    Transform.translate(
                                      offset: Offset(0.0, wiggle),
                                      child: _MatchPhotoCard(
                                        width: cardW,
                                        height: cardsHeight,
                                        label: 'TÚ',
                                        image: _buildMiFotoWidget(
                                          miFoto,
                                          miFotoIsFile,
                                          miFotoFallback,
                                        ),
                                        radius: cardRadius,
                                        border: cardBorder,
                                        glowColor: matchyLilac,
                                      ),
                                    ),
                                  ],
                                ),

                                Transform.scale(
                                  scale: 1.0 +
                                      (math.sin(_cardsCtrl.value * math.pi) *
                                          heartScaleAmp),
                                  child: Container(
                                    width: heartSize,
                                    height: heartSize,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.25),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: matchyLilac.withOpacity(0.9),
                                        width: heartBorderWidth,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.favorite,
                                      color: const Color(0xFFFF4D6D),
                                      size: heartIconSize,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: namesTopSpace),

                  Row(
                    children: [
                      Expanded(child: _NameLine(name: suNombre, age: suEdad)),
                      const SizedBox(width: 14.0),
                      Expanded(child: _NameLine(name: miNombre, age: miEdad)),
                    ],
                  ),

                  const SizedBox(height: midGapAfterNames),

                  // Botón chat (misma estética)
                  AnimatedBuilder(
                    animation: _buttonPulseCtrl,
                    builder: (_, __) {
                      final pulse = 1.0 +
                          (math.sin(_buttonPulseCtrl.value * math.pi) * 0.02);

                      return Transform.scale(
                        scale: pulse,
                        child: SizedBox(
                          width: double.infinity,
                          height: buttonHeight,
                          child: ElevatedButton(
                            onPressed: _startChat, // ✅ LOGICA NUEVA
                            style: ElevatedButton.styleFrom(
                              backgroundColor: matchyPurple,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18.0),
                              ),
                              elevation: 8.0,
                            ),
                            child: const Text(
                              'INICIAR CHAT CON TU MATCH',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.0,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Poppins',
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16.0),

                  Text(
                    'DE UN CAFÉ AL AMOR Y LA AMISTAD HAY UN SOLO PASO',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.92),
                      fontSize: quoteFontSize,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                      shadows: [
                        Shadow(
                          blurRadius: 10.0,
                          color: Colors.black.withOpacity(0.45),
                          offset: const Offset(0.0, 2.0),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: noteTopGap),

                  Text(
                    'RECUERDA EN MATCHY EL QUE INVITA PAGA.\nBUENA SUERTE EN TU CITA.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: noteRed,
                      fontSize: noteFontSize,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w900,
                      height: 1.25,
                      letterSpacing: 0.2,
                      shadows: [
                        Shadow(
                          blurRadius: 10.0,
                          color: Colors.black.withOpacity(0.55),
                          offset: const Offset(0.0, 2.0),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiFotoWidget(String? path, bool isFile, String fallback) {
    if (path != null && path.trim().isNotEmpty && isFile) {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        errorBuilder: (_, __, ___) => Image.asset(
          fallback,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),
      );
    }

    return Image.asset(
      (path == null || path.trim().isEmpty) ? fallback : path,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      errorBuilder: (_, __, ___) => Image.asset(
        fallback,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
      ),
    );
  }
}

// ============================================================
// 🔹 TÍTULO CON GRADIENTE ANIMADO
// ============================================================

class _AnimatedGradientTitle extends StatelessWidget {
  final String text;
  final double fontSize;
  final double letterSpacing;
  final double shadowBlur;
  final double shadowOffsetY;
  final double t;

  const _AnimatedGradientTitle({
    required this.text,
    required this.fontSize,
    required this.letterSpacing,
    required this.shadowBlur,
    required this.shadowOffsetY,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final dx = (t * 2.0 - 1.0) * 0.9; // 🔴 CHINCHE TITLE GRAD 1

    return ShaderMask(
      shaderCallback: (rect) {
        return LinearGradient(
          begin: Alignment(-1.0 + dx, -1.0),
          end: Alignment(1.0 + dx, 1.0),
          colors: const [
            Color(0xFFFFC107),
            Color(0xFFFF4D6D),
            Color(0xFF7E79B6),
            Color(0xFFE0D4FF),
          ],
        ).createShader(rect);
      },
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          fontFamily: 'Poppins',
          letterSpacing: letterSpacing,
          shadows: [
            Shadow(
              blurRadius: shadowBlur,
              color: Colors.black.withOpacity(0.55),
              offset: Offset(0.0, shadowOffsetY),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 🔹 TARJETA FOTO
// ============================================================

class _MatchPhotoCard extends StatelessWidget {
  final double width;
  final double height;
  final String label;
  final Widget image;
  final double radius;
  final double border;
  final Color glowColor;

  const _MatchPhotoCard({
    required this.width,
    required this.height,
    required this.label,
    required this.image,
    required this.radius,
    required this.border,
    required this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    const double glowBlur = 18.0; // 🔴
    const double glowOffsetY = 10.0; // 🔴
    const double darkBlur = 14.0; // 🔴
    const double darkOffsetY = 10.0; // 🔴
    const double overlayHeight = 95.0; // 🔴

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: glowColor.withOpacity(0.25),
            blurRadius: glowBlur,
            offset: const Offset(0.0, glowOffsetY),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.55),
            blurRadius: darkBlur,
            offset: const Offset(0.0, darkOffsetY),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            image,
            Positioned(
              left: 0.0,
              right: 0.0,
              bottom: 0.0,
              height: overlayHeight,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.80),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.85),
                    width: border,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12.0,
              top: 12.0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.28),
                  borderRadius: BorderRadius.circular(14.0),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.0,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Poppins',
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 🔹 NOMBRE + EDAD
// ============================================================

class _NameLine extends StatelessWidget {
  final String name;
  final int age;

  const _NameLine({
    required this.name,
    required this.age,
  });

  @override
  Widget build(BuildContext context) {
    final color = Colors.white.withOpacity(_MatchScreenState.nameOpacity);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: _MatchScreenState.nameBoxPadH,
        vertical: _MatchScreenState.nameBoxPadV,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.18),
        borderRadius: BorderRadius.circular(_MatchScreenState.nameBoxRadius),
        border: Border.all(color: Colors.white.withOpacity(0.14), width: 1.0),
      ),
      child: Text(
        age > 0 ? '$name, $age' : name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: _MatchScreenState.nameFontSize,
          fontWeight: FontWeight.w900,
          fontFamily: 'Poppins',
          shadows: [
            Shadow(
              blurRadius: 12.0,
              color: Colors.black.withOpacity(0.55),
              offset: const Offset(0.0, 3.0),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 🎉 CONFETI
// ============================================================

class _ConfettiPiece {
  double x;
  double y;
  final double size;
  final double speed;
  double rot;
  final double rotSpeed;
  final double hue;

  _ConfettiPiece({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.rot,
    required this.rotSpeed,
    required this.hue,
  });
}

class _ConfettiPainter extends CustomPainter {
  final double t;
  final List<_ConfettiPiece> pieces;

  _ConfettiPainter({
    required this.t,
    required this.pieces,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final rnd = math.Random(7);

    for (final p in pieces) {
      final yy = ((p.y + t * p.speed) % 1.0) * size.height;
      final xx = (p.x * size.width) + math.sin((t + p.hue) * 8.0) * 10.0;
      final rot = p.rot + t * p.rotSpeed;

      final palette = [
        const Color(0xFFFFC107),
        const Color(0xFFFF4D6D),
        const Color(0xFF7E79B6),
        const Color(0xFFE0D4FF),
        const Color(0xFF63FF68),
        const Color(0xFFFF6E63),
      ];
      final c = palette[(p.hue * palette.length)
          .floor()
          .clamp(0, palette.length - 1)];

      paint.color = c.withOpacity(0.75);

      final isCircle = rnd.nextBool();

      canvas.save();
      canvas.translate(xx, yy);
      canvas.rotate(rot);

      if (isCircle) {
        canvas.drawCircle(Offset.zero, p.size * 0.45, paint);
      } else {
        final rect = Rect.fromCenter(
          center: Offset.zero,
          width: p.size,
          height: p.size * 0.55,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(p.size * 0.25)),
          paint,
        );
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.t != t;
  }
}
