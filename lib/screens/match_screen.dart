// 📂 lib/screens/match_screen.dart
// ✅ MATCH SCREEN (FINAL - ARQUITECTURA ROBUSTA)
// 🔥 FIX ANIMACIÓN: Restaurado el movimiento de flote de las tarjetas.
// 🔥 CHINCHE: Agregado control de intensidad del flote.

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:proyectos_matchy/state/profile_form_provider.dart';
import 'package:proyectos_matchy/screens/chat_detalle_screen.dart';
import 'package:proyectos_matchy/screens/home_shell.dart';
import 'package:proyectos_matchy/services/chat_actions.dart';

class MatchScreen extends ConsumerStatefulWidget {
  final String candidatoId;
  final String candidatoNombre;
  final int candidatoEdad;
  final String candidatoFotoAsset;

  // 🟢 DATOS DEL LUGAR (Se reciben directos)
  final String lugarNombre;
  final String lugarFoto;
  final String? citaId;

  final Future<void> Function()? onMatchAnimationFinished;

  const MatchScreen({
    super.key,
    required this.candidatoId,
    required this.candidatoNombre,
    required this.candidatoEdad,
    required this.candidatoFotoAsset,
    // Valores por defecto para seguridad
    this.lugarNombre = '',
    this.lugarFoto = '',
    this.citaId,
    this.onMatchAnimationFinished,
  });

  @override
  ConsumerState<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends ConsumerState<MatchScreen>
    with TickerProviderStateMixin {

  // ==============================================================================
  // 🔴🔴 ZONA DE CHINCHES MAESTROS DE EDICIÓN 🔴🔴
  // ==============================================================================

  // 1. BLOQUE TÍTULO
  static const double kTitleOffsetY = 11.0;
  static const double kTitleScale   = 1.0;

  // 2. BLOQUE MATCH (Personas)
  static const double kMatchOffsetY = -5.0;
  static const double kMatchScale   = 0.9;
  // 🔥 INTENSIDAD DEL FLOTE (Qué tan arriba/abajo se mueven las cartas)
  static const double kCardsWiggleIntensity = 6.0; // Aumenta para más movimiento

  // 3. BLOQUE LUGAR (Sitio)
  static const double kLugarOffsetY = -39.0;
  static const double kLugarScale   = 0.9;
  static const double kLugarHeight  = 160.0;

  // 4. BLOQUE BOTONES
  static const double kButtonsOffsetY = -29.0;
  static const double kButtonsScale   = 0.9;

  // ==============================================================================

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

  String _stableMyNombre = '';
  int _stableMyEdad = 0;
  String _stableMyFoto = '';
  String _stablePeerNombre = '';
  int _stablePeerEdad = 0;
  String _stablePeerFoto = '';
  bool _hydratingPeople = false;

  static const String kUsersCollection = 'users';
  static const String kEventsSubcollection = 'events';
  bool _creatingEvent = false;
  bool _eventCreated = false;
  bool _navigating = false;

  static const Color matchyPurple = Color(0xFF7E79B6);
  static const Color matchyLilac = Color(0xFFE0D4FF);
  static const Color matchyYellow = Color(0xFFFFC107);
  static const Color noteRed = Color(0xFFFF5252);

  @override
  void initState() {
    super.initState();
    _titleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
    _cardsCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);
    _buttonPulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);
    _confettiCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat();
    _confetti = _buildConfettiPieces(90);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _hydratePeopleFromFirestore();
    });

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

  // Helpers
  bool _isUrl(String v) => v.startsWith('http');
  bool _isAsset(String v) => v.startsWith('assets/');
  bool _looksLikeFilePath(String v) => v.contains(r':\') || v.startsWith('file:');
  List<_ConfettiPiece> _buildConfettiPieces(int count) { final rnd = math.Random(); return List.generate(count, (_) => _ConfettiPiece(x: rnd.nextDouble(), y: rnd.nextDouble(), size: 4.0 + rnd.nextDouble() * 8.0, speed: 0.2 + rnd.nextDouble() * 0.9, rot: rnd.nextDouble() * math.pi, rotSpeed: (rnd.nextDouble() - 0.5) * 1.8, hue: rnd.nextDouble())); }
  String _primerNombre(String f) => f.trim().split(RegExp(r'\s+')).first;
  String _pickMyPhoto(ProfileFormState p) => (p.profilePhotoUrl ?? '').isNotEmpty ? p.profilePhotoUrl! : (p.photoUrls.isNotEmpty ? p.photoUrls.first : 'assets/images/perfil1.jpg');

  Widget _imageSmart(String v, String fb) {
    if (v.isEmpty) return Image.asset(fb, fit: BoxFit.cover);
    if (_isUrl(v)) {
      return Image.network(v, fit: BoxFit.cover, alignment: Alignment.topCenter,
          loadingBuilder: (_, c, p) => p == null ? c : Container(color: Colors.black26, alignment: Alignment.center, child: const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
          errorBuilder: (_, __, ___) => Image.asset(fb, fit: BoxFit.cover));
    }
    if (_isAsset(v)) return Image.asset(v, fit: BoxFit.cover, alignment: Alignment.topCenter, errorBuilder: (_, __, ___) => Image.asset(fb, fit: BoxFit.cover));
    if (_looksLikeFilePath(v)) return Image.file(File(v.replaceFirst('file://', '')), fit: BoxFit.cover, alignment: Alignment.topCenter, errorBuilder: (_, __, ___) => Image.asset(fb, fit: BoxFit.cover));
    return Image.asset(fb, fit: BoxFit.cover);
  }

  Future<void> _hydratePeopleFromFirestore() async {
    if (_hydratingPeople) return;
    setState(() => _hydratingPeople = true);
    try {
      final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (widget.candidatoId.isNotEmpty) {
        final snap = await FirebaseFirestore.instance.collection(kUsersCollection).doc(widget.candidatoId).get();
        if (snap.exists) { final d = snap.data() ?? {}; _stablePeerNombre = (d['nombre']??'').toString(); _stablePeerEdad = int.tryParse((d['edad']??'0').toString())??0; _stablePeerFoto = (d['profilePhotoUrl']??'').toString(); }
      }
      if (myUid.isNotEmpty) {
        final snap = await FirebaseFirestore.instance.collection(kUsersCollection).doc(myUid).get();
        if (snap.exists) { final d = snap.data() ?? {}; _stableMyNombre = (d['nombre']??'').toString(); _stableMyEdad = int.tryParse((d['edad']??'0').toString())??0; _stableMyFoto = (d['profilePhotoUrl']??'').toString(); }
      }
    } catch (_) {} finally { if (mounted) setState(() => _hydratingPeople = false); }
  }

  // 🔴 AQUÍ SE GUARDAN LOS DATOS EN EL EVENTO 🔴
  Future<void> _createCandidateEventOnce({required String action}) async {
    if (_eventCreated || _creatingEvent) return;
    _creatingEvent = true;
    try {
      final me = FirebaseAuth.instance.currentUser;
      final myUid = me?.uid ?? '';
      final peerUid = widget.candidatoId.trim();
      if (myUid.isNotEmpty && peerUid.isNotEmpty) {
        final profile = ref.read(profileFormProvider);
        final String ownerFotoCandidate = _stableMyFoto.trim().isNotEmpty ? _stableMyFoto : _pickMyPhoto(profile);
        final String eventId = 'matchy_${myUid}_${peerUid}_${DateTime.now().millisecondsSinceEpoch}';

        await FirebaseFirestore.instance.collection(kUsersCollection).doc(peerUid).collection(kEventsSubcollection).doc(eventId).set({
          'type': 'matchy',
          'seen': false,
          'createdAt': FieldValue.serverTimestamp(),
          'source': 'match_screen',
          'action': action,
          'ownerUid': myUid,
          'ownerNombre': _stableMyNombre.isNotEmpty ? _stableMyNombre : profile.nombre,
          'ownerFoto': ownerFotoCandidate.isEmpty ? 'assets/images/perfil1.jpg' : ownerFotoCandidate,
          'candidatoUid': peerUid,

          // 🔥 GUARDAMOS LUGAR Y FOTO EN EL EVENTO
          'lugarNombre': widget.lugarNombre,
          'lugarFoto': widget.lugarFoto,
          'citaId': widget.citaId,
        });
        _eventCreated = true;
      }
    } catch (_) {} finally { _creatingEvent = false; }
  }

  Future<void> _startChat() async {
    if (_navigating) return;
    setState(() => _navigating = true);
    await _createCandidateEventOnce(action: 'chat');

    final suN = _primerNombre(_stablePeerNombre.isNotEmpty ? _stablePeerNombre : widget.candidatoNombre);
    final suF = _stablePeerFoto.isNotEmpty ? _stablePeerFoto : widget.candidatoFotoAsset;

    try {
      final tId = await ChatActions.upsertThread(
          peerUid: widget.candidatoId,
          peerNombre: suN,
          peerEdad: 0,
          peerFoto: suF,
          myNombre: 'Yo',
          myEdad: 0,
          myFoto: ''
      );

      if (!mounted) return;
      await HomeShell.consumeEvent();

      // 🔥 CORRECCIÓN: Agregamos otherUid para que coincida con ChatDetalleScreen
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(
              builder: (_) => ChatDetalleScreen(
                  id: tId,
                  otherUid: widget.candidatoId, // 👈 ¡AQUÍ ESTÁ EL ARREGLO!
                  nombre: suN,
                  edad: '',
                  foto: suF
              )
          )
      );
    } catch (_) { if(mounted) setState(() => _navigating = false); }
  }

  Future<void> _irACitas() async {
    if (_navigating) return;
    setState(() => _navigating = true);
    await _createCandidateEventOnce(action: 'citas');
    await HomeShell.consumeEvent();
    if (!mounted) return;
    HomeShell.go(context, index: 1);
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileFormProvider);
    final miNombre = _primerNombre(_stableMyNombre.isNotEmpty ? _stableMyNombre : profile.nombre);
    final miEdad = _stableMyEdad > 0 ? _stableMyEdad : (int.tryParse(profile.edad.trim()) ?? 0);
    final miFoto = _stableMyFoto.isNotEmpty ? _stableMyFoto : _pickMyPhoto(profile);
    final suNombre = _primerNombre(_stablePeerNombre.isNotEmpty ? _stablePeerNombre : widget.candidatoNombre);
    final suEdad = _stablePeerEdad > 0 ? _stablePeerEdad : widget.candidatoEdad;
    final suFoto = _stablePeerFoto.isNotEmpty ? _stablePeerFoto : widget.candidatoFotoAsset;

    // Usamos los datos directos
    final String nombreLugar = widget.lugarNombre.isNotEmpty ? widget.lugarNombre : 'LUGAR DE CITA';
    final String fotoLugar = widget.lugarFoto;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(child: Image.asset('assets/images/fondo.jpg', fit: BoxFit.fill, width: double.infinity, height: double.infinity)),
            Positioned.fill(child: IgnorePointer(child: AnimatedBuilder(animation: _confettiCtrl, builder: (_, __) => CustomPaint(painter: _ConfettiPainter(t: _confettiCtrl.value, pieces: _confetti))))),

            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 28.0),
                      SizedBox(height: 48.0, child: Image.asset('assets/images/logomatchyplano.png')),

                      // 1. TÍTULO
                      Transform.translate(offset: const Offset(0, kTitleOffsetY), child: Transform.scale(scale: kTitleScale, child: AnimatedBuilder(animation: _titleCtrl, builder: (_, __) => Column(children: [_AnimatedGradientTitle(text: 'TENEMOS UN', fontSize: 34.0, t: _titleCtrl.value), const SizedBox(height: 2.0), _AnimatedGradientTitle(text: 'MATCHY', fontSize: 44.0, t: _titleCtrl.value)])))),
                      const SizedBox(height: 15),

                      // 2. MATCH (TARJETAS FLOTANTES)
                      Transform.translate(
                        offset: const Offset(0, kMatchOffsetY),
                        child: Transform.scale(
                          scale: kMatchScale,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                height: 230.0,
                                child: LayoutBuilder(builder: (context, constraints) {
                                  final double cardW = ((constraints.maxWidth - 14.0) / 2.0).clamp(145.0, 190.0);

                                  // 🔥 ANIMACIÓN DE FLOTE RESTAURADA
                                  return AnimatedBuilder(
                                    animation: _cardsCtrl,
                                    builder: (context, child) {
                                      // Calcula el desplazamiento vertical (wiggle)
                                      final double wiggle = math.sin(_cardsCtrl.value * math.pi * 2.0) * kCardsWiggleIntensity;

                                      return Center(
                                        child: SizedBox(
                                          width: (cardW * 2.0) + 14.0,
                                          height: 230.0,
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  // Tarjeta Izquierda (se mueve en sentido opuesto)
                                                  Transform.translate(
                                                    offset: Offset(0.0, -wiggle),
                                                    child: _MatchPhotoCard(width: cardW, height: 230.0, label: 'TU MATCHY', image: _imageSmart(suFoto, 'assets/images/perfil1.jpg'), glowColor: matchyYellow),
                                                  ),
                                                  // Tarjeta Derecha
                                                  Transform.translate(
                                                    offset: Offset(0.0, wiggle),
                                                    child: _MatchPhotoCard(width: cardW, height: 230.0, label: 'TÚ', image: _imageSmart(miFoto, 'assets/images/perfil1.jpg'), glowColor: matchyLilac),
                                                  ),
                                                ],
                                              ),
                                              // Corazón Central (Pulsación)
                                              Transform.scale(
                                                scale: 1.0 + (math.sin(_cardsCtrl.value * math.pi) * 0.06),
                                                child: Container(width: 74.0, height: 74.0, decoration: BoxDecoration(color: Colors.black.withOpacity(0.25), shape: BoxShape.circle, border: Border.all(color: matchyLilac.withOpacity(0.9), width: 2.0)), child: const Icon(Icons.favorite, color: Color(0xFFFF4D6D), size: 36.0)),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }),
                              ),
                              const SizedBox(height: 12.0),
                              Row(children: [Expanded(child: _NameLine(name: suNombre, age: suEdad)), const SizedBox(width: 14.0), Expanded(child: _NameLine(name: miNombre, age: miEdad))]),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 3. LUGAR (Datos directos)
                      Transform.translate(offset: const Offset(0, kLugarOffsetY), child: Transform.scale(scale: kLugarScale, child: Container(
                        width: double.infinity, height: kLugarHeight,
                        decoration: BoxDecoration(color: const Color(0xFF1F1F1F), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 8, offset: const Offset(0, 4))]),
                        child: ClipRRect(borderRadius: BorderRadius.circular(20), child: Stack(fit: StackFit.expand, children: [
                          _imageSmart(fotoLugar, 'assets/images/fondo.jpg'),
                          Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.95)], stops: const [0.3, 1.0]))),
                          Positioned(bottom: 15, left: 15, right: 15, child: Text(nombreLugar.toUpperCase(), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, fontFamily: 'Poppins', height: 1.1, shadows: [Shadow(color: Colors.black, blurRadius: 10)]))),
                        ])),
                      ))),

                      const SizedBox(height: 20),

                      // 4. BOTONES
                      Transform.translate(offset: const Offset(0, kButtonsOffsetY), child: Transform.scale(scale: kButtonsScale, child: Column(children: [
                        AnimatedBuilder(animation: _buttonPulseCtrl, builder: (_, __) {
                          final pulse = 1.0 + (math.sin(_buttonPulseCtrl.value * math.pi) * 0.02);
                          return Transform.scale(scale: pulse, child: SizedBox(width: double.infinity, height: 52.0, child: ElevatedButton(onPressed: (_navigating) ? null : _startChat, style: ElevatedButton.styleFrom(backgroundColor: matchyPurple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.0)), elevation: 8.0), child: const Text('INICIAR CHAT CON TU MATCHY', style: TextStyle(color: Colors.white, fontSize: 14.0, fontWeight: FontWeight.w900, fontFamily: 'Poppins', letterSpacing: 0.4)))));
                        }),
                        const SizedBox(height: 10),
                        SizedBox(width: double.infinity, height: 48, child: ElevatedButton(onPressed: (_guardadoOk && !_guardando && !_navigating) ? _irACitas : null, style: ElevatedButton.styleFrom(backgroundColor: matchyYellow, disabledBackgroundColor: matchyYellow.withOpacity(0.35), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.0)), elevation: 6.0), child: _guardando ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Text(_guardadoOk ? 'IR A CITAS' : 'GUARDANDO CITA...', style: const TextStyle(color: Colors.black, fontSize: 13.0, fontWeight: FontWeight.w900, fontFamily: 'Poppins', letterSpacing: 0.3)))),
                        const SizedBox(height: 14.0),
                        Text('BUENA SUERTE CON TU CITA', textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.92), fontSize: 15.0, fontFamily: 'Poppins', fontWeight: FontWeight.w900, height: 1.15, shadows: [Shadow(blurRadius: 10.0, color: Colors.black.withOpacity(0.45), offset: const Offset(0.0, 2.0))])),
                        const SizedBox(height: 6.0),
                        const Text('RECUERDA EN MATCHY EL QUE INVITA PAGA.\nBUENA SUERTE EN TU CITA.', textAlign: TextAlign.center, style: TextStyle(color: noteRed, fontSize: 12.0, fontFamily: 'Poppins', fontWeight: FontWeight.w900, height: 1.25, letterSpacing: 0.2)),
                      ]))),

                      const SizedBox(height: 40),
                    ],
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

// Widgets Aux (Sin cambios)
class _AnimatedGradientTitle extends StatelessWidget { final String text; final double fontSize; final double t; const _AnimatedGradientTitle({required this.text, required this.fontSize, required this.t}); @override Widget build(BuildContext context) { final dx = (t * 2.0 - 1.0) * 0.9; return ShaderMask(shaderCallback: (rect) => LinearGradient(begin: Alignment(-1.0 + dx, -1.0), end: Alignment(1.0 + dx, 1.0), colors: const [Color(0xFFFFC107), Color(0xFFFF4D6D), Color(0xFF7E79B6), Color(0xFFE0D4FF)]).createShader(rect), child: Text(text, textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: fontSize, fontWeight: FontWeight.w900, fontFamily: 'Poppins', letterSpacing: 0.6, shadows: [Shadow(blurRadius: 14.0, color: Colors.black.withOpacity(0.55), offset: const Offset(0.0, 5.0))])),); } }
class _MatchPhotoCard extends StatelessWidget { final double width; final double height; final String label; final Widget image; final Color glowColor; const _MatchPhotoCard({required this.width, required this.height, required this.label, required this.image, required this.glowColor}); @override Widget build(BuildContext context) { return Container(width: width, height: height, decoration: BoxDecoration(borderRadius: BorderRadius.circular(26.0), boxShadow: [BoxShadow(color: glowColor.withOpacity(0.25), blurRadius: 18.0, offset: const Offset(0.0, 10.0)), BoxShadow(color: Colors.black.withOpacity(0.55), blurRadius: 14.0, offset: const Offset(0.0, 10.0))]), child: ClipRRect(borderRadius: BorderRadius.circular(26.0), child: Stack(fit: StackFit.expand, children: [image, Positioned(left: 0, right: 0, bottom: 0, height: 95.0, child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.80)])))), Positioned.fill(child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(26.0), border: Border.all(color: Colors.white.withOpacity(0.85), width: 3.0)))), Positioned(left: 12.0, top: 12.0, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0), decoration: BoxDecoration(color: Colors.black.withOpacity(0.28), borderRadius: BorderRadius.circular(14.0)), child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12.0, fontWeight: FontWeight.w900, fontFamily: 'Poppins', letterSpacing: 0.4))))]))); } }
class _NameLine extends StatelessWidget { final String name; final int age; const _NameLine({required this.name, required this.age}); @override Widget build(BuildContext context) { return Container(padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 12.0), decoration: BoxDecoration(color: Colors.black.withOpacity(0.18), borderRadius: BorderRadius.circular(18.0), border: Border.all(color: Colors.white.withOpacity(0.14), width: 1.0)), child: Text(age > 0 ? '$name, $age' : name, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.92), fontSize: 18.0, fontWeight: FontWeight.w900, fontFamily: 'Poppins', shadows: [Shadow(blurRadius: 12.0, color: Colors.black.withOpacity(0.55), offset: const Offset(0.0, 3.0))]))); } }
class _ConfettiPiece { double x; double y; final double size; final double speed; double rot; final double rotSpeed; final double hue; _ConfettiPiece({required this.x, required this.y, required this.size, required this.speed, required this.rot, required this.rotSpeed, required this.hue}); }
class _ConfettiPainter extends CustomPainter { final double t; final List<_ConfettiPiece> pieces; _ConfettiPainter({required this.t, required this.pieces}); @override void paint(Canvas canvas, Size size) { final paint = Paint(); final rnd = math.Random(7); for (final p in pieces) { final yy = ((p.y + t * p.speed) % 1.0) * size.height; final xx = (p.x * size.width) + math.sin((t + p.hue) * 8.0) * 10.0; final rot = p.rot + t * p.rotSpeed; final palette = [const Color(0xFFFFC107), const Color(0xFFFF4D6D), const Color(0xFF7E79B6), const Color(0xFFE0D4FF), const Color(0xFF63FF68), const Color(0xFFFF6E63)]; paint.color = palette[(p.hue * palette.length).floor().clamp(0, palette.length - 1)].withOpacity(0.75); canvas.save(); canvas.translate(xx, yy); canvas.rotate(rot); if (rnd.nextBool()) { canvas.drawCircle(Offset.zero, p.size * 0.45, paint); } else { canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.55), Radius.circular(p.size * 0.25)), paint); } canvas.restore(); } } @override bool shouldRepaint(covariant _ConfettiPainter old) => old.t != t; }