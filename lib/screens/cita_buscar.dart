// 📂 lib/screens/cita_buscar.dart
// ✅ CITA BUSCAR — Swipe tipo Tinder (Matchy style) + LOGICA REAL (local)
// ✅ FIX:
//    - ❌ Eliminado título viejo que crasheaba (Incorrect use of ParentDataWidget)
//    - ✅ Nuevo título ABAJO-IZQUIERDA (primer nombre + edad) bien armado
//    - ✅ Undo arriba izq (se mantiene)
//    - ✅ Degradado abajo tipo Perfil
//    - ✅ Chinches para mover X/Y + tamaños
//
// ⚠️ BADGES LIKE/NOPE: siguen en código pero OCULTOS e INACTIVOS.

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:proyectos_matchy/widgets/matchy_page_layout.dart';
import 'package:proyectos_matchy/screens/perfil_screen.dart';

import 'package:proyectos_matchy/state/profile_form_provider.dart';
import 'package:proyectos_matchy/screens/citas_pendientes_screen.dart';

class CitaBuscarScreen extends ConsumerStatefulWidget {
  static const String routeName = 'cita_buscar'; // 🔴 CHINCHE A — ruta (texto)
  const CitaBuscarScreen({super.key});

  @override
  ConsumerState<CitaBuscarScreen> createState() => _CitaBuscarScreenState();
}

class _CitaBuscarScreenState extends ConsumerState<CitaBuscarScreen>
    with SingleTickerProviderStateMixin {
  // ============================================================
  // 🔹 SWIPE
  // ============================================================
  static const double decisionThresholdPx = 75.0; // 🔴 CHINCHE SWIPE 1
  static const double rotationDivisor = 14.0; // 🔴 CHINCHE SWIPE 2
  static const double opacityDivisor = 100.0; // 🔴 CHINCHE SWIPE 3
  static const int flingDurationMs = 300; // 🔴 CHINCHE SWIPE 4
  static const int resetDurationMs = 300; // 🔴 CHINCHE SWIPE 5
  static const double offscreenMultiplier = 1.35; // 🔴 CHINCHE SWIPE 6

  // ============================================================
  // 🔹 MATCHY STYLE
  // ============================================================
  static const String backgroundAsset = 'assets/images/fondo.jpg'; // 🔴 CHINCHE MATCHY 1
  static const String logoAsset = 'assets/images/logomatchyplano.png'; // 🔴 CHINCHE MATCHY 2

  static const double topSpacing = 35.0; // 🔴 CHINCHE MATCHY 3
  static const double logoHeight = 50.0;
  static const double logoOffsetY = 0.0;
  static const double spaceLogoToScroll = 15.0;

  // ============================================================
  // 🔹 DEMO
  // ============================================================
  static const String imagesFolder = 'assets/images/'; // 🔴 CHINCHE DEMO 1
  static const String girlExt = '.png'; // 🔴 CHINCHE DEMO 2
  static const int demoCount = 10; // 🔴 CHINCHE DEMO 3

  // ============================================================
  // 🔹 LAYOUT
  // ============================================================
  static const double screenSideMargin = 14.0; // 🔴 CHINCHE UI 1
  static const double gapLogoToSwipeBlock = 8.0; // 🔴 CHINCHE UI 2

  static const double photoHeightFactorOfScreen = 0.52; // 🔴 CHINCHE UI 3
  static const double photoMinHeight = 420.0; // 🔴 CHINCHE UI 4
  static const double photoMaxHeight = 560.0; // 🔴 CHINCHE UI 5

  static const double infoCardHeight = 165.0; // 🔴 CHINCHE UI 6
  static const double gapPhotoToInfo = 14.0; // 🔴 CHINCHE UI 7

  static const double photoRadius = 28.0; // 🔴 CHINCHE UI 8
  static const double infoRadius = 16.0; // 🔴 CHINCHE UI 9

  static const double shadowOpacity = 0.45; // 🔴 CHINCHE UI 10
  static const double shadowBlur = 12.0;
  static const double shadowOffsetY = 7.0;

  // ============================================================
  // ✅ NUEVO: TÍTULO ABAJO-IZQUIERDA (CHINCHES)
  // ============================================================
  static const double titleLeft = 24.0; // 🔴 CHINCHE TITLE X — mueve izquierda/derecha
  static const double titleBottom = 16.0; // 🔴 CHINCHE TITLE Y — sube/baja desde abajo
  static const double titleNameSize = 27.0; // 🔴 CHINCHE TITLE SIZE 1 — nombre
  static const double titleAgeSize = 27.0; // 🔴 CHINCHE TITLE SIZE 2 — edad
  static const double titleMaxWidthFactor = 0.78; // 🔴 CHINCHE TITLE WIDTH — 0.78 = no invade todo

  static const double titleShadowBlur = 10.0; // 🔴 CHINCHE TITLE SHADOW 1
  static const double titleShadowOpacity = 0.70; // 🔴 CHINCHE TITLE SHADOW 2

  // ============================================================
  // 🔹 DEGRADADO FOTO (tipo Perfil)
  // ============================================================
  static const double photoGradientHeight = 170.0; // 🔴 CHINCHE GRAD 1
  static const double photoGradientBottomOpacity = 0.85; // 🔴 CHINCHE GRAD 2

  // ============================================================
  // 🔹 BOTONES
  // ============================================================
  static const double actionButtonSize = 76.0; // 🔴 CHINCHE BTN 1
  static const double actionIconSize = 70.0; // 🔴 CHINCHE BTN 2
  static const Color actionCircleColor = Color(0xFF7E79B6); // 🔴 CHINCHE BTN 3
  static const double actionButtonsGap = 74.0; // 🔴 CHINCHE BTN 4
  static const double gapSwipeBlockToButtons = 24.0; // 🔴 CHINCHE BTN 5
  static const double bottomPadding = 18.0; // 🔴 CHINCHE BTN 6

  static const String iconClose = 'assets/images/ic_close_white.png'; // 🔴 CHINCHE BTN 7
  static const String iconFav = 'assets/images/ic_favorite_white.png';

  // ============================================================
  // 🔹 UNDO (ARRIBA IZQUIERDA)
  // ============================================================
  static const double undoSize = 44.0; // 🔴 CHINCHE UNDO 1
  static const double undoLeft = 14.0; // 🔴 CHINCHE UNDO 2
  static const double undoTop = 14.0; // 🔴 CHINCHE UNDO 2
  static const double undoBgOpacity = 0.35; // 🔴 CHINCHE UNDO 3

  // ============================================================
  // Estado
  // ============================================================
  late List<_CitaCardModel> _deck;
  int _topIndex = 0;

  final List<int> _undoStack = <int>[]; // 🔴 CHINCHE UNDO STATE 1

  double _dx = 0.0;
  bool _isAnimating = false;

  late final AnimationController _controller;
  Animation<double>? _dxAnim;

  @override
  void initState() {
    super.initState();
    _deck = _buildInitialDeck();
    _controller = AnimationController(vsync: this)
      ..addListener(() {
        if (_dxAnim != null) setState(() => _dx = _dxAnim!.value);
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _dxAnim = null;
          _isAnimating = false;
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ============================================================
  // 🔹 DECK: provider + demo
  // ============================================================
  List<_CitaCardModel> _buildInitialDeck() {
    final profile = ref.read(profileFormProvider);

    final String nombreCreador =
    profile.nombre.trim().isEmpty ? 'Usuario' : profile.nombre.trim();

    final int edadCreador = int.tryParse(profile.edad.trim()) ?? 0;

    final String? fotoPrincipal =
    profile.fotosCargadas.isNotEmpty ? profile.fotosCargadas.first : null;

    final List<CitaPendiente> pendientes = ref.read(citasPendientesProvider);

    final List<_CitaCardModel> list = [];

    for (final c in pendientes) {
      final String creatorPhotoValue = fotoPrincipal ?? '';
      list.add(
        _CitaCardModel(
          creatorName: nombreCreador,
          creatorAge: edadCreador,
          creatorPhoto: creatorPhotoValue,
          creatorPhotoIsFile: creatorPhotoValue.startsWith('/') ||
              creatorPhotoValue.contains(r':\') ||
              creatorPhotoValue.startsWith('file:'),
          placePhotoAsset: c.fotoLugarAsset,
          placeName: c.nombreLugar,
          placeAddress: c.direccionLugar,
          fecha: c.fecha,
          hora: c.hora,
          intencion: (c is dynamic && (c as dynamic).intencion != null)
              ? ((c as dynamic).intencion as String)
              : 'Amistad',
        ),
      );
    }

    final names = <String>[
      'Anita',
      'Leila',
      'Sara',
      'Valentina',
      'Camila',
      'Juliana',
      'Laura',
      'Paula',
      'Daniela',
      'Sofía',
    ];
    final ages = <int>[24, 27, 25, 26, 23, 28, 22, 29, 21, 27];

    while (list.length < demoCount) {
      final i = list.length;
      final idx = (i % demoCount) + 1;
      final assetGirl = '$imagesFolder' 'chica$idx$girlExt';

      list.add(
        _CitaCardModel(
          creatorName: names[i % names.length],
          creatorAge: ages[i % ages.length],
          creatorPhoto: assetGirl,
          creatorPhotoIsFile: false,
          placePhotoAsset: 'assets/images/faro1.jpg',
          placeName: 'EL FARO PIZZERIA',
          placeAddress: 'Carrera 26 # 5-157',
          fecha: '05/10/2025',
          hora: '8:30 PM',
          intencion: 'Amistad',
        ),
      );
    }

    return list;
  }

  // ============================================================
  // Movimiento
  // ============================================================
  double get _rotationDeg => _dx / rotationDivisor;

  double get _likeOpacityValue {
    final o = (_dx > 0) ? (_dx.abs() / opacityDivisor) : 0.0;
    return o.clamp(0.0, 1.0);
  }

  double get _nopeOpacityValue {
    final o = (_dx < 0) ? (_dx.abs() / opacityDivisor) : 0.0;
    return o.clamp(0.0, 1.0);
  }

  Future<void> _animateTo(double targetDx, Duration duration) async {
    _controller.stop();
    _controller.duration = duration;
    _dxAnim = Tween<double>(begin: _dx, end: targetDx).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    await _controller.forward(from: 0.0);
  }

  Future<void> _resetCard() async {
    _isAnimating = true;
    await _animateTo(0.0, const Duration(milliseconds: resetDurationMs));
  }

  Future<void> _flingOut({required bool toRight, required double width}) async {
    _isAnimating = true;

    final targetDx = (toRight ? 1 : -1) * width * offscreenMultiplier;
    await _animateTo(targetDx, const Duration(milliseconds: flingDurationMs));

    if (_topIndex < _deck.length) _undoStack.add(_topIndex);

    if (_topIndex < _deck.length) {
      setState(() {
        _topIndex++;
        _dx = 0.0;
      });
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_isAnimating) return;
    setState(() => _dx += details.delta.dx);
  }

  Future<void> _handlePanEnd(DragEndDetails details, double width) async {
    if (_isAnimating) return;

    final decisionMade = _dx.abs() >= decisionThresholdPx;
    if (decisionMade) {
      await _flingOut(toRight: _dx >= 0, width: width);
    } else {
      await _resetCard();
    }
  }

  Future<void> _onNopeTap(double width) async {
    if (_isAnimating) return;
    _dx = -decisionThresholdPx;
    await _flingOut(toRight: false, width: width);
  }

  Future<void> _onLikeTap(double width) async {
    if (_isAnimating) return;
    _dx = decisionThresholdPx;
    await _flingOut(toRight: true, width: width);
  }

  Future<void> _onUndoTap() async {
    if (_isAnimating) return;
    if (_undoStack.isEmpty) return;

    final int last = _undoStack.removeLast();
    setState(() {
      _topIndex = last;
      _dx = 0.0;
    });
    await _resetCard();
  }

  void _openCreatorProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PerfilScreen(showBottomNav: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final noMore = _topIndex >= _deck.length;
    final Size screen = MediaQuery.sizeOf(context);

    final double blockWidth = screen.width - (screenSideMargin * 2);

    final double rawPhotoHeight = screen.height * photoHeightFactorOfScreen;
    final double photoHeight =
    rawPhotoHeight.clamp(photoMinHeight, photoMaxHeight);

    final double swipeBlockHeight =
        photoHeight + gapPhotoToInfo + infoCardHeight;

    return Scaffold(
      body: MatchyPageLayout(
        backgroundAsset: backgroundAsset,
        logoAsset: logoAsset,
        topSpacing: topSpacing,
        logoHeight: logoHeight,
        logoOffsetY: logoOffsetY,
        spaceLogoToScroll: spaceLogoToScroll,
        scrollContent: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: gapLogoToSwipeBlock),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: blockWidth,
                  height: swipeBlockHeight,
                  child: Stack(
                    children: [
                      if (!noMore && _topIndex + 1 < _deck.length)
                        Positioned.fill(
                          child: _SwipeBundle(
                            model: _deck[_topIndex + 1],
                            likeOpacity: 0.0,
                            nopeOpacity: 0.0,
                            width: blockWidth,
                            photoHeight: photoHeight,
                            infoHeight: infoCardHeight,
                            onUndo: _onUndoTap,
                            canUndo: _undoStack.isNotEmpty,
                            onPhotoTap: _openCreatorProfile,
                          ),
                        ),
                      if (!noMore)
                        Positioned.fill(
                          child: GestureDetector(
                            onPanUpdate: _handlePanUpdate,
                            onPanEnd: (d) => _handlePanEnd(d, blockWidth),
                            child: Transform.translate(
                              offset: Offset(_dx, 0),
                              child: Transform.rotate(
                                angle: _rotationDeg * (math.pi / 180),
                                child: _SwipeBundle(
                                  model: _deck[_topIndex],
                                  likeOpacity: _likeOpacityValue,
                                  nopeOpacity: _nopeOpacityValue,
                                  width: blockWidth,
                                  photoHeight: photoHeight,
                                  infoHeight: infoCardHeight,
                                  onUndo: _onUndoTap,
                                  canUndo: _undoStack.isNotEmpty,
                                  onPhotoTap: _openCreatorProfile,
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (noMore)
                        const Positioned.fill(
                          child: Center(
                            child: Text(
                              'No hay más citas cerca de ti...\nVuelve a intentarlo más tarde',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF777777),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: gapSwipeBlockToButtons),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _AssetCircleButton(
                      asset: iconClose,
                      size: actionButtonSize,
                      iconSize: actionIconSize,
                      backgroundColor: actionCircleColor,
                      onTap: () => _onNopeTap(blockWidth),
                    ),
                    SizedBox(width: actionButtonsGap),
                    _AssetCircleButton(
                      asset: iconFav,
                      size: actionButtonSize,
                      iconSize: actionIconSize,
                      backgroundColor: actionCircleColor,
                      onTap: () => _onLikeTap(blockWidth),
                    ),
                  ],
                ),
                SizedBox(height: bottomPadding),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ================================================================
// 🔹 SWIPE BUNDLE (FOTO + INFO)
// ================================================================
class _SwipeBundle extends StatelessWidget {
  final _CitaCardModel model;
  final double likeOpacity;
  final double nopeOpacity;

  final double width;
  final double photoHeight;
  final double infoHeight;

  final VoidCallback onUndo;
  final bool canUndo;
  final VoidCallback onPhotoTap;

  const _SwipeBundle({
    required this.model,
    required this.likeOpacity,
    required this.nopeOpacity,
    required this.width,
    required this.photoHeight,
    required this.infoHeight,
    required this.onUndo,
    required this.canUndo,
    required this.onPhotoTap,
  });

  Widget _buildCreatorPhoto() {
    if (model.creatorPhotoIsFile && model.creatorPhoto.trim().isNotEmpty) {
      return Image.file(
        File(model.creatorPhoto),
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        errorBuilder: (_, __, ___) => Image.asset(
          model.creatorPhotoFallbackAsset,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),
      );
    }

    return Image.asset(
      model.creatorPhoto.trim().isEmpty
          ? model.creatorPhotoFallbackAsset
          : model.creatorPhoto,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
    );
  }

  String _firstName(String fullName) {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return 'Usuario';
    final parts = trimmed.split(RegExp(r'\s+'));
    return parts.isEmpty ? trimmed : parts.first;
  }

  @override
  Widget build(BuildContext context) {
    final String primerNombre = _firstName(model.creatorName);

    return SizedBox(
      width: width,
      child: Column(
        children: [
          Container(
            width: width,
            height: photoHeight,
            decoration: BoxDecoration(
              borderRadius:
              BorderRadius.circular(_CitaBuscarScreenState.photoRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withOpacity(_CitaBuscarScreenState.shadowOpacity),
                  blurRadius: _CitaBuscarScreenState.shadowBlur,
                  offset: Offset(0, _CitaBuscarScreenState.shadowOffsetY),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ✅ Tap foto
                GestureDetector(
                  onTap: onPhotoTap,
                  child: _buildCreatorPhoto(),
                ),

                // ✅ Degradado abajo tipo Perfil
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    ignoring: true,
                    child: Container(
                      height: _CitaBuscarScreenState.photoGradientHeight,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(
                              _CitaBuscarScreenState.photoGradientBottomOpacity,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ✅ NUEVO TÍTULO abajo-izquierda (SIN CRASHEAR)
                Positioned(
                  left: _CitaBuscarScreenState.titleLeft, // 🔴 CHINCHE TITLE X
                  bottom: _CitaBuscarScreenState.titleBottom, // 🔴 CHINCHE TITLE Y
                  child: IgnorePointer(
                    ignoring: true,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth:
                        width * _CitaBuscarScreenState.titleMaxWidthFactor, // 🔴 CHINCHE TITLE WIDTH
                      ),
                      child: RichText(
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: primerNombre,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: _CitaBuscarScreenState.titleNameSize, // 🔴 CHINCHE TITLE SIZE 1
                                fontWeight: FontWeight.w900,
                                shadows: [
                                  Shadow(
                                    blurRadius: _CitaBuscarScreenState.titleShadowBlur,
                                    color: Colors.black.withOpacity(
                                      _CitaBuscarScreenState.titleShadowOpacity,
                                    ),
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            TextSpan(
                              text: ', ${model.creatorAge}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: _CitaBuscarScreenState.titleAgeSize, // 🔴 CHINCHE TITLE SIZE 2
                                fontWeight: FontWeight.w900,
                                shadows: [
                                  Shadow(
                                    blurRadius: _CitaBuscarScreenState.titleShadowBlur,
                                    color: Colors.black.withOpacity(
                                      _CitaBuscarScreenState.titleShadowOpacity,
                                    ),
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ✅ UNDO arriba izquierda (se mantiene)
                Positioned(
                  left: _CitaBuscarScreenState.undoLeft,
                  top: _CitaBuscarScreenState.undoTop,
                  child: IgnorePointer(
                    ignoring: !canUndo,
                    child: Opacity(
                      opacity: canUndo ? 1.0 : 0.35,
                      child: Material(
                        color: Colors.black.withOpacity(
                            _CitaBuscarScreenState.undoBgOpacity),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: onUndo,
                          child: SizedBox(
                            width: _CitaBuscarScreenState.undoSize,
                            height: _CitaBuscarScreenState.undoSize,
                            child: const Center(
                              child: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // BADGES ocultos
                IgnorePointer(
                  ignoring: true,
                  child: Opacity(
                    opacity: 0.0,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 16,
                          top: 90,
                          child: Opacity(
                            opacity: likeOpacity,
                            child: Transform.rotate(
                              angle: -30 * (math.pi / 180),
                              child: const _ChoiceBadge(
                                text: 'LIKE',
                                borderColor: Color(0xFF63FF68),
                                textColor: Color(0xFF63FF68),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 16,
                          top: 90,
                          child: Opacity(
                            opacity: nopeOpacity,
                            child: Transform.rotate(
                              angle: 30 * (math.pi / 180),
                              child: const _ChoiceBadge(
                                text: 'NOPE',
                                borderColor: Color(0xFFFF6E63),
                                textColor: Color(0xFFFF6E63),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: _CitaBuscarScreenState.gapPhotoToInfo),

          _CitaInfoCard(
            width: width,
            height: infoHeight,
            placePhotoAsset: model.placePhotoAsset,
            fecha: model.fecha,
            hora: model.hora,
            placeName: model.placeName,
            placeAddress: model.placeAddress,
            intencion: model.intencion,
          ),
        ],
      ),
    );
  }
}

// ================================================================
// 🔹 INFO CARD
// ================================================================
class _CitaInfoCard extends StatelessWidget {
  final double width;
  final double height;

  final String placePhotoAsset;
  final String fecha;
  final String hora;
  final String placeName;
  final String placeAddress;
  final String intencion;

  const _CitaInfoCard({
    required this.width,
    required this.height,
    required this.placePhotoAsset,
    required this.fecha,
    required this.hora,
    required this.placeName,
    required this.placeAddress,
    required this.intencion,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_CitaBuscarScreenState.infoRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.30),
            blurRadius: 10.0,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            placePhotoAsset,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Image.asset('assets/images/faro1.jpg', fit: BoxFit.cover),
          ),
          Container(color: Colors.black.withOpacity(0.35)),
          Positioned(
            left: 14.0,
            right: 14.0,
            top: 10.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        fecha,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22.0,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      hora,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19.0,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Intención: $intencion',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 14.0,
            right: 14.0,
            bottom: 12.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  placeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.0,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  placeAddress,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// UI Components
// ================================================================
class _ChoiceBadge extends StatelessWidget {
  final String text;
  final Color borderColor;
  final Color textColor;

  const _ChoiceBadge({
    required this.text,
    required this.borderColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w900,
          shadows: [Shadow(blurRadius: 10, color: Color.fromRGBO(0, 0, 0, 0.30))],
        ).copyWith(color: textColor),
      ),
    );
  }
}

class _AssetCircleButton extends StatelessWidget {
  final String asset;
  final double size;
  final double iconSize;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _AssetCircleButton({
    required this.asset,
    required this.size,
    required this.iconSize,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      shape: const CircleBorder(),
      elevation: 3.0,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: Image.asset(
              asset,
              width: iconSize,
              height: iconSize,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

// ================================================================
// Model
// ================================================================
class _CitaCardModel {
  final String creatorName;
  final int creatorAge;

  final String creatorPhoto;
  final bool creatorPhotoIsFile;

  final String creatorPhotoFallbackAsset;

  final String placePhotoAsset;
  final String placeName;
  final String placeAddress;
  final String fecha;
  final String hora;
  final String intencion;

  const _CitaCardModel({
    required this.creatorName,
    required this.creatorAge,
    required this.creatorPhoto,
    required this.creatorPhotoIsFile,
    this.creatorPhotoFallbackAsset = 'assets/images/perfil1.jpg',
    required this.placePhotoAsset,
    required this.placeName,
    required this.placeAddress,
    required this.fecha,
    required this.hora,
    required this.intencion,
  });
}
