// 📂 lib/screens/match_screen.dart
// ✅ MATCH SCREEN — “TENEMOS UN MATCHY”
// ✅ FIX: ChatActions vive aquí (no depende de chat_screen.dart)
// ✅ FIX PRO: upsertThread (multiusuario) + threadId determinístico uidA__uidB
// ✅ FIX PRO: Abre ChatDetalle con threadId real
// ✅ FIX: ChatDetalleScreen requiere foto
// ✅ FIX HOME_SHELL: IR A CITAS vuelve al HomeShell (mantiene BottomNav)
// ✅ FIX FOTO "TÚ": ahora usa URL (Storage) > photoUrls > File local > fallback
// ✅ DEBUG REAL: muestra el error exacto si Firestore niega

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:proyectos_matchy/state/profile_form_provider.dart';

import 'package:proyectos_matchy/screens/chat_detalle_screen.dart';
import 'package:proyectos_matchy/screens/home_shell.dart'; // ✅ para mantener barra

// ============================================================
// ✅ CHAT ACTIONS (AQUÍ MISMO) — para no depender de chat_screen.dart
// ============================================================

/// 🔴 CHINCHE CHAT ACTIONS 1 — nombre colección threads
const String kChatThreadsCollection = 'chat_threads';

/// 🔴 CHINCHE CHAT ACTIONS 2 — fields thread
const String kThreadParticipantUids = 'participantUids';
const String kThreadMeta = 'meta';
const String kThreadCreatedAt = 'createdAt';
const String kThreadUpdatedAt = 'updatedAt';

class ChatActions {
  /// Construye ID determinístico: uidA__uidB (ordenado)
  static String buildThreadId(String uidA, String uidB) {
    final a = uidA.trim();
    final b = uidB.trim();
    if (a.isEmpty || b.isEmpty) return '';
    final pair = [a, b]..sort();
    return '${pair[0]}__${pair[1]}';
  }

  /// ✅ Crea/actualiza el thread y guarda meta para ambos usuarios.
  /// Retorna threadId real.
  static Future<String> upsertThread({
    required String peerUid,
    required String peerNombre,
    required int peerEdad,
    required String peerFoto,
    required String myNombre,
    required int myEdad,
    required String myFoto,
  }) async {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) {
      throw Exception('No hay sesión (FirebaseAuth.currentUser es null)');
    }

    final myUid = me.uid;
    final threadId = buildThreadId(myUid, peerUid);

    if (threadId.isEmpty) {
      throw Exception('threadId inválido (uids vacíos)');
    }

    final ref = FirebaseFirestore.instance
        .collection(kChatThreadsCollection)
        .doc(threadId);

    final snap = await ref.get();
    final now = FieldValue.serverTimestamp();

    final data = <String, dynamic>{
      kThreadParticipantUids: [myUid, peerUid],
      kThreadMeta: {
        myUid: {
          'nombre': myNombre,
          'edad': myEdad,
          'foto': myFoto,
        },
        peerUid: {
          'nombre': peerNombre,
          'edad': peerEdad,
          'foto': peerFoto,
        },
      },
      kThreadUpdatedAt: now,
      if (!snap.exists) kThreadCreatedAt: now,
    };

    // ✅ merge true para que no reviente si ya existía (con reglas ya arregladas)
    await ref.set(data, SetOptions(merge: true));
    return threadId;
  }
}

class MatchScreen extends ConsumerStatefulWidget {
  final String candidatoId; // 🔴 CHINCHE PRO 1 — ideal: UID real del otro usuario
  final String candidatoNombre;
  final int candidatoEdad;
  final String candidatoFotoAsset;

  final Future<void> Function()? onMatchAnimationFinished;

  const MatchScreen({
    super.key,
    required this.candidatoId,
    required this.candidatoNombre,
    required this.candidatoEdad,
    required this.candidatoFotoAsset,
    this.onMatchAnimationFinished,
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

  static const Duration _finishDelay = Duration(milliseconds: 2400);

  Timer? _finishTimer;
  bool _finishCalled = false;

  bool _guardadoOk = false;
  bool _guardando = false;

  static const double topLogoSpace = 28.0; // 🔴
  static const double logoHeight = 48.0; // 🔴
  static const double titleTopSpace = 10.0; // 🔴
  static const double cardsTopSpace = 18.0; // 🔴
  static const double cardsHeight = 230.0; // 🔴
  static const double namesTopSpace = 12.0; // 🔴
  static const double buttonHeight = 52.0; // 🔴
  static const double sidePadding = 18.0; // 🔴
  static const double midGapAfterNames = 10.0; // 🔴

  static const double titleSidePadding = 14.0; // 🔴
  static const double titleLineGap = 2.0; // 🔴
  static const double titleLine1FontSize = 34.0; // 🔴
  static const double titleLine2FontSize = 44.0; // 🔴
  static const double titleLetterSpacing = 0.6; // 🔴
  static const double titleShadowBlur = 14.0; // 🔴
  static const double titleShadowOffsetY = 5.0; // 🔴

  static const double cardsHorizontalGap = 14.0; // 🔴
  static const double cardRadius = 26.0; // 🔴
  static const double cardBorder = 3.0; // 🔴
  static const double cardMinWidth = 145.0; // 🔴
  static const double cardMaxWidth = 190.0; // 🔴

  static const double heartSize = 74.0; // 🔴
  static const double heartIconSize = 36.0; // 🔴
  static const double heartBorderWidth = 2.0; // 🔴
  static const double heartScaleAmp = 0.06; // 🔴

  static const double nameFontSize = 18.0; // 🔴
  static const double nameOpacity = 0.92; // 🔴
  static const double nameBoxRadius = 18.0; // 🔴
  static const double nameBoxPadH = 10.0; // 🔴
  static const double nameBoxPadV = 12.0; // 🔴

  static const double quoteFontSize = 15.0; // 🔴
  static const double noteFontSize = 12.0; // 🔴
  static const double noteTopGap = 6.0; // 🔴

  static const Color matchyPurple = Color(0xFF7E79B6);
  static const Color matchyLilac = Color(0xFFE0D4FF);
  static const Color matchyYellow = Color(0xFFFFC107);
  static const Color noteRed = Color(0xFFFF5252);

  bool _isUrl(String v) => v.startsWith('http://') || v.startsWith('https://');
  bool _isAsset(String v) => v.startsWith('assets/');
  bool _looksLikeFilePath(String v) =>
      v.startsWith('/') || v.contains(r':\') || v.startsWith('file:');

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

    _confetti = _buildConfettiPieces(90);

    _finishTimer = Timer(_finishDelay, () async {
      if (!mounted) return;
      if (_finishCalled) return;
      _finishCalled = true;

      if (widget.onMatchAnimationFinished == null) {
        setState(() => _guardadoOk = true);
        return;
      }

      setState(() => _guardando = true);

      try {
        await widget.onMatchAnimationFinished!.call();
        if (!mounted) return;
        setState(() => _guardadoOk = true);
      } catch (_) {
        if (!mounted) return;
        setState(() => _guardadoOk = false);
      } finally {
        if (mounted) setState(() => _guardando = false);
      }
    });
  }

  @override
  void dispose() {
    _finishTimer?.cancel();
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

  // 🔴 CHINCHE FOTO 1 — decide “mi foto” (URL > photoUrls > file > fallback)
  String _pickMyPhoto(ProfileFormState profile) {
    final url = (profile.profilePhotoUrl ?? '').trim();
    if (url.isNotEmpty) return url;

    if (profile.photoUrls.isNotEmpty) {
      final u = profile.photoUrls.first.trim();
      if (u.isNotEmpty) return u;
    }

    if (profile.fotosCargadas.isNotEmpty) {
      final p = profile.fotosCargadas.first.trim();
      if (p.isNotEmpty) return p;
    }

    return 'assets/images/perfil1.jpg';
  }

  Widget _imageSmart(String value, String fallback) {
    final v = value.trim();
    if (v.isEmpty) return Image.asset(fallback, fit: BoxFit.cover);

    if (_isUrl(v)) {
      return Image.network(
        v,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        errorBuilder: (_, __, ___) => Image.asset(fallback, fit: BoxFit.cover),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            color: Colors.black26,
            alignment: Alignment.center,
            child: const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
      );
    }

    if (_isAsset(v)) {
      return Image.asset(
        v,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        errorBuilder: (_, __, ___) => Image.asset(fallback, fit: BoxFit.cover),
      );
    }

    if (_looksLikeFilePath(v)) {
      return Image.file(
        File(v.replaceFirst('file://', '')),
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        errorBuilder: (_, __, ___) => Image.asset(fallback, fit: BoxFit.cover),
      );
    }

    return Image.asset(fallback, fit: BoxFit.cover);
  }

  // ✅ ACCIÓN: Firestore upsert (MULTIUSUARIO) + abrir chat
  Future<void> _startChat() async {
    final profile = ref.read(profileFormProvider);

    final String miNombre = _primerNombre(profile.nombre);
    final int miEdad = int.tryParse(profile.edad.trim()) ?? 0;

    const String miFotoFallback = 'assets/images/perfil1.jpg';
    final String miFotoSafe = _pickMyPhoto(profile); // ✅ ahora sí

    final String suNombre = _primerNombre(widget.candidatoNombre);

    try {
      final String threadId = await ChatActions.upsertThread(
        peerUid: widget.candidatoId,
        peerNombre: suNombre,
        peerEdad: widget.candidatoEdad,
        peerFoto: widget.candidatoFotoAsset,
        myNombre: miNombre,
        myEdad: miEdad,
        myFoto: miFotoSafe.isEmpty ? miFotoFallback : miFotoSafe,
      );

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatDetalleScreen(
            nombre: suNombre,
            edad: widget.candidatoEdad.toString(),
            id: threadId,
            foto: widget.candidatoFotoAsset,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      // ✅ DEBUG REAL para que nos diga exactamente qué negó Firestore
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ No se pudo crear el chat: $e')),
      );
    }
  }

  void _irACitas() {
    HomeShell.go(context, index: 1); // 🔴 CHINCHE SHELL NAV 1
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileFormProvider);

    final String miNombre = _primerNombre(profile.nombre);
    final int miEdad = int.tryParse(profile.edad.trim()) ?? 0;

    const String miFotoFallback = 'assets/images/perfil1.jpg';
    final String miFoto = _pickMyPhoto(profile);

    final String suNombre = _primerNombre(widget.candidatoNombre);
    final int suEdad = widget.candidatoEdad;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover),
          ),
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
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: titleSidePadding,
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
                                fontSize: titleLine1FontSize,
                                letterSpacing: titleLetterSpacing,
                                shadowBlur: titleShadowBlur,
                                shadowOffsetY: titleShadowOffsetY,
                                t: _titleCtrl.value,
                              ),
                              const SizedBox(height: titleLineGap),
                              _AnimatedGradientTitle(
                                text: 'MATCHY',
                                fontSize: titleLine2FontSize,
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
                                        image: _imageSmart(miFoto, miFotoFallback),
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
                            onPressed: _startChat,
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
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: (_guardadoOk && !_guardando) ? _irACitas : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: matchyYellow,
                        disabledBackgroundColor: matchyYellow.withOpacity(0.35),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18.0),
                        ),
                        elevation: 6.0,
                      ),
                      child: _guardando
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : Text(
                        _guardadoOk ? 'IR A CITAS' : 'GUARDANDO CITA...',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 13.0,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Poppins',
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14.0),
                  Text(
                    'BUENA SUERTE CON TU CITA',
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
    final dx = (t * 2.0 - 1.0) * 0.9;

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
    const double glowBlur = 18.0;
    const double glowOffsetY = 10.0;
    const double darkBlur = 14.0;
    const double darkOffsetY = 10.0;
    const double overlayHeight = 95.0;

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
                padding:
                const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
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
