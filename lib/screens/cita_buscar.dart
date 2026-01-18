import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proyectos_matchy/widgets/matchy_page_layout.dart';
import 'package:proyectos_matchy/screens/lugar_galeria_screen.dart';
import 'package:proyectos_matchy/screens/candidato_galeria_screen.dart';
import 'package:proyectos_matchy/screens/panel_screen.dart';

class CitaBuscarScreen extends ConsumerStatefulWidget {
  static const String routeName = 'cita_buscar';
  const CitaBuscarScreen({super.key});
  @override
  ConsumerState<CitaBuscarScreen> createState() => _CitaBuscarScreenState();
}

class _CitaBuscarScreenState extends ConsumerState<CitaBuscarScreen>
    with SingleTickerProviderStateMixin {

  // ---------------------------
  // CONFIG DE SWIPE
  // ---------------------------
  static const double decisionThresholdPx = 75.0;
  static const double rotationDivisor = 14.0;
  static const double opacityDivisor = 100.0;

  // Velocidad del SWIPE ARRÁSTRADO
  static const int flingDurationMsSwipe = 680;

  // Velocidad de los BOTONES X / ❤️
  static const int flingDurationMsButtons = 900;

  static const int resetDurationMs = 250;
  static const double offscreenDiagMultiplier = 2.2;
  static const double offscreenExtraPx = 180.0;

  // ---------------------------
  // LAYOUT
  // ---------------------------
  static const String backgroundAsset = 'assets/images/fondo.jpg';
  static const String logoAsset = 'assets/images/logomatchyplano.png';
  static const double topSpacing = 35.0;
  static const double logoHeight = 50.0;
  static const double logoOffsetY = 0.0;
  static const double spaceLogoToScroll = 15.0;

  static const double screenSideMargin = 14.0;
  static const double gapLogoToSwipeBlock = 8.0;
  static const double photoHeightFactor = 0.52;
  static const double photoMinHeight = 380.0;
  static const double photoMaxHeight = 560.0;
  static const double infoCardHeight = 165.0;
  static const double gapPhotoToInfo = 14.0;
  static const double photoRadius = 28.0;
  static const double infoRadius = 16.0;

  static const double shadowOpacity = 0.45;
  static const double shadowBlur = 12.0;
  static const double shadowOffsetY = 7.0;

  static const double titleLeft = 24.0;
  static const double titleBottom = 16.0;
  static const double titleNameSize = 27.0;
  static const double titleAgeSize = 27.0;
  static const double titleMaxWidthFactor = 0.78;
  static const double titleShadowBlur = 10.0;
  static const double titleShadowOpacity = 0.70;

  static const double photoGradientHeight = 170.0;
  static const double photoGradientBottomOpacity = 0.85;

  static const double actionButtonSize = 76.0;
  static const double actionIconSize = 70.0;
  static const Color actionCircleColor = Color(0xFF7E79B6);
  static const double actionButtonsGap = 74.0;
  static const double gapSwipeBlockToButtons = 18.0;
  static const double bottomPadding = 14.0;
  static const String iconClose = 'assets/images/ic_close_white.png';
  static const String iconFav = 'assets/images/ic_favorite_white.png';

  static const bool showUndoButton = false;
  static const String publicStatus = 'online';

  // ---------------------------
  // FIRESTORE CONFIG
  // ---------------------------
  static const String kCitasCol = 'citas';
  static const String kUsersCol = 'users';
  static const String kSubCandidatos = 'candidatos';
  static const String kSubDescartes = 'descartes';
  static const String kOwnerUidField = 'ownerUid';
  static const String kLugarField = 'lugar';
  static const String kFechaField = 'fecha';
  static const String kHoraField = 'hora';
  static const String kUserGeneroField = 'genero';
  static const String kUserPreferenciaCitasField = 'preferenciaCitas';

  // ---------------------------
  // STATE
  // ---------------------------
  List<_CitaCardModel> _deck = const [];
  int _topIndex = 0;
  double _dx = 0.0;
  bool _isAnimating = false;

  late final AnimationController _controller;
  Animation<double>? _dxAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this)
      ..addListener(() => setState(() => _dx = _dxAnim?.value ?? _dx))
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

  // ---------------------------
  // STREAMS
  // ---------------------------
  Stream<DocumentSnapshot<Map<String, dynamic>>> _userDocStream(String uid) {
    return FirebaseFirestore.instance.collection(kUsersCol).doc(uid).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _citasPublicasStream() {
    return FirebaseFirestore.instance
        .collection(kCitasCol)
        .where('status', isEqualTo: publicStatus)
        .limit(50)
        .snapshots();
  }

  // ---------------------------
  // FIRESTORE WRITES
  // ---------------------------
  Future<void> _writeDescartado({
    required String citaId,
    required String uid,
  }) async {
    await FirebaseFirestore.instance
        .collection(kCitasCol)
        .doc(citaId)
        .collection(kSubDescartes)
        .doc(uid)
        .set({
      'uid': uid,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _writeCandidato({
    required _CitaCardModel model,
    required String uid,
  }) async {
    await FirebaseFirestore.instance
        .collection(kCitasCol)
        .doc(model.citaId)
        .collection(kSubCandidatos)
        .doc(uid)
        .set({
      'uid': uid,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
  // ---------------------------
  // SWIPE MOVEMENT
  // ---------------------------
  double get _rotationDeg => _dx / rotationDivisor;
  double get _likeOpacityValue =>
      _dx > 0 ? (_dx.abs() / opacityDivisor).clamp(0.0, 1.0) : 0.0;
  double get _nopeOpacityValue =>
      _dx < 0 ? (_dx.abs() / opacityDivisor).clamp(0.0, 1.0) : 0.0;

  Future<void> _animateTo(double target, Duration dur) async {
    _controller.stop();
    _controller.duration = dur;
    _dxAnim = Tween<double>(begin: _dx, end: target).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    await _controller.forward(from: 0.0);
  }

  Future<void> _resetCard() async {
    _isAnimating = true;
    await _animateTo(
      0.0,
      Duration(milliseconds: resetDurationMs),
    );
  }

  double _screenDiag(Size s) => math.sqrt(s.width * s.width + s.height * s.height);

  // ---------------------------
  // FLING OUT
  // ---------------------------
  Future<void> _flingOut({
    required bool right,
    required Size size,
    required _CitaCardModel model,
    required String uid,
    required int durationMs,
  }) async {
    if (_topIndex >= _deck.length) return;

    _isAnimating = true;

    final diag = _screenDiag(size);
    final target = (right ? 1 : -1) *
        (diag * offscreenDiagMultiplier + offscreenExtraPx);

    await _animateTo(
      target,
      Duration(milliseconds: durationMs),
    );

    if (!mounted) return;

    setState(() {
      _topIndex++;
      _dx = 0.0;
    });

    // Guardar like / dislike en segundo plano
    Future(() async {
      try {
        if (right) {
          await _writeCandidato(model: model, uid: uid);
        } else {
          await _writeDescartado(citaId: model.citaId, uid: uid);
        }
      } catch (_) {}
    });
  }

  // ---------------------------
  // SWIPE HANDLERS
  // ---------------------------
  void _onPanUpdate(DragUpdateDetails d) {
    if (_isAnimating) return;
    setState(() => _dx += d.delta.dx);
  }

  Future<void> _onPanEnd(DragEndDetails d, Size size, String uid) async {
    if (_isAnimating) return;

    if (_dx.abs() < decisionThresholdPx) {
      await _resetCard();
      return;
    }

    if (_topIndex >= _deck.length) return;

    final model = _deck[_topIndex];

    await _flingOut(
      right: _dx > 0,
      size: size,
      model: model,
      uid: uid,
      durationMs: flingDurationMsSwipe,   // swipe arrastrado
    );
  }

  Future<void> _onNope(Size size, String uid) async {
    if (_isAnimating || _topIndex >= _deck.length) return;

    _dx = -decisionThresholdPx;

    await _flingOut(
      right: false,
      size: size,
      model: _deck[_topIndex],
      uid: uid,
      durationMs: flingDurationMsButtons,   // botón X
    );
  }

  Future<void> _onLike(Size size, String uid) async {
    if (_isAnimating || _topIndex >= _deck.length) return;

    _dx = decisionThresholdPx;

    await _flingOut(
      right: true,
      size: size,
      model: _deck[_topIndex],
      uid: uid,
      durationMs: flingDurationMsButtons,   // botón ❤️
    );
  }

  // ---------------------------
  // HELPERS
  // ---------------------------
  String _s(dynamic v) => v is String ? v : (v?.toString() ?? '');

  String _two(int n) => n.toString().padLeft(2, '0');

  String _fmtFecha(DateTime dt) =>
      '${_two(dt.day)}/${_two(dt.month)}/${dt.year}';

  String _fmtHora(DateTime dt) {
    int h = dt.hour;
    final ampm = h >= 12 ? 'PM' : 'AM';
    h = h % 12;
    if (h == 0) h = 12;
    return '$h:${_two(dt.minute)} $ampm';
  }

  List<String> _safeList(dynamic v) =>
      v is List
          ? v.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList()
          : <String>[];

  Map<String, dynamic> _safeMap(dynamic v) =>
      v is Map ? Map<String, dynamic>.from(v) : {};

  String _normPref(String v) {
    final t = v.toLowerCase();
    if (t.contains('hombre')) return 'Hombres';
    if (t.contains('mujer')) return 'Mujeres';
    if (t.contains('amb')) return 'Ambos';
    return 'Ambos';
  }

  String _normGenero(String v) {
    final t = v.toLowerCase();
    if (t.contains('hombre')) return 'Hombres';
    if (t.contains('mujer')) return 'Mujeres';
    return 'NoDecir';
  }

  bool _citaAcepta({
    required String prefCita,
    required String generoUser,
  }) {
    final p = _normPref(prefCita);
    if (p == 'Ambos') return true;
    if (generoUser != 'Hombres' && generoUser != 'Mujeres') return false;
    return p == generoUser;
  }

  bool _userAcepta({
    required String prefGlobal,
    required String genDueno,
  }) {
    final p = _normPref(prefGlobal);
    if (p == 'Ambos') return true;
    if (genDueno != 'Hombres' && genDueno != 'Mujeres') return false;
    return p == genDueno;
  }

  // ---------------------------
  // FILTRO FINAL (NO REPETIR TARJETAS)
  // ---------------------------
  Future<List<_CitaCardModel>> _applyFilters({
    required List<_CitaCardModel> raw,
    required String uid,
    required String generoUser,
    required String prefGlobal,
  }) async {
    final out = <_CitaCardModel>[];

    for (final m in raw) {
      final docDesc = await FirebaseFirestore.instance
          .collection(kCitasCol)
          .doc(m.citaId)
          .collection(kSubDescartes)
          .doc(uid)
          .get();

      final docCand = await FirebaseFirestore.instance
          .collection(kCitasCol)
          .doc(m.citaId)
          .collection(kSubCandidatos)
          .doc(uid)
          .get();

      // Si ya hizo swipe derecha o izquierda → NO vuelve a salir
      if (docDesc.exists || docCand.exists) continue;

      out.add(m);
    }

    final ownerUids =
    out.map((e) => e.ownerUid).where((e) => e.isNotEmpty && e != uid).toSet().toList();

    final Map<String, String> genDueno = {};

    for (final ou in ownerUids) {
      try {
        final snap = await FirebaseFirestore.instance.collection(kUsersCol).doc(ou).get();
        genDueno[ou] =
            _normGenero((snap.data() ?? {})[kUserGeneroField]?.toString() ?? '');
      } catch (_) {
        genDueno[ou] = 'NoDecir';
      }
    }

    final filtrados = <_CitaCardModel>[];

    for (final m in out) {
      final g = genDueno[m.ownerUid] ?? 'NoDecir';

      if (_citaAcepta(prefCita: m.preferencia, generoUser: generoUser) &&
          _userAcepta(prefGlobal: prefGlobal, genDueno: g)) {
        filtrados.add(m);
      }
    }

    return filtrados;
  }
  // ---------------------------
  // MAPEO DE SNAPSHOTS → MODELOS
  // ---------------------------
  Map<String, dynamic> _readCreador(Map<String, dynamic> data) =>
      _safeMap(data['creador']);

  Future<List<_CitaCardModel>> _mapDocsToDeck({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    required String uid,
  }) async {
    final out = <_CitaCardModel>[];

    for (final d in docs) {
      final data = d.data();
      final ownerUid = _s(data[kOwnerUidField]).trim();

      // No mostrar mis propias citas
      if (ownerUid.isNotEmpty && ownerUid == uid) continue;

      final lugar = _safeMap(data[kLugarField]);
      final nombreLugar = _s(lugar['nombre']).isNotEmpty
          ? _s(lugar['nombre'])
          : _s(data['nombre']).isNotEmpty
          ? _s(data['nombre'])
          : 'Lugar';

      final direccionLugar = _s(lugar['direccion']).isNotEmpty
          ? _s(lugar['direccion'])
          : _s(data['direccion']).isNotEmpty
          ? _s(data['direccion'])
          : 'Sin dirección';

      final prefCita =
      _s(data['preferencia']).isEmpty ? 'Ambos' : _s(data['preferencia']);

      String fotoPortada = _s(lugar['fotoPortada']);
      if (fotoPortada.isEmpty) fotoPortada = _s(data['fotoPortada']);
      if (fotoPortada.isEmpty) fotoPortada = _s(data['fotoLugar']);
      if (fotoPortada.isEmpty) fotoPortada = _s(data['fotoLugarAsset']);

      final placePhotos = <String>[];
      if (fotoPortada.isNotEmpty) placePhotos.add(fotoPortada);
      for (final f in _safeList(data['fotos'])) {
        if (!placePhotos.contains(f)) placePhotos.add(f);
      }
      if (placePhotos.isEmpty) {
        placePhotos.add('assets/images/perfil1.jpg');
      }

      String fecha = _s(data[kFechaField]);
      String hora = _s(data[kHoraField]);
      final sched = data['scheduledAt'];

      if (sched is Timestamp) {
        final dt = sched.toDate();
        fecha = _fmtFecha(dt);
        hora = _fmtHora(dt);
      }

      final intencion =
      _s(data['intencion']).isEmpty ? 'Amistad' : _s(data['intencion']);

      final creador = _readCreador(data);

      String creadorNombre = _s(creador['nombre']);
      final creadorEdadRaw = creador['edad'];
      String creadorFoto = _s(creador['foto']);
      final creadorUid = _s(creador['uid']);

      final legacyNombre = _s(data['creadorNombre']);
      final legacyEdadRaw = data['creadorEdad'];
      final legacyFoto = _s(data['creadorFoto']);

      final ownerFinal = ownerUid.isNotEmpty
          ? ownerUid
          : (creadorUid.isNotEmpty ? creadorUid : 'unknown');

      // ---------------------------
      // NOMBRE FINAL DEL CREADOR
      // ---------------------------
      if (creadorNombre.isEmpty) {
        if (legacyNombre.isNotEmpty) {
          creadorNombre = legacyNombre;
        } else {
          try {
            final snapUser = await FirebaseFirestore.instance
                .collection(kUsersCol)
                .doc(ownerFinal)
                .get();

            final dUser = snapUser.data() ?? {};
            final nUser = _s(dUser['nombre']);

            creadorNombre = nUser.isNotEmpty ? nUser : 'Usuario';
          } catch (_) {
            creadorNombre = 'Usuario';
          }
        }
      }

      // ---------------------------
      // EDAD FINAL DEL CREADOR
      // ---------------------------
      final edadFinal =
      (creadorEdadRaw is int)
          ? creadorEdadRaw
          : int.tryParse(creadorEdadRaw?.toString() ?? '') ??
          (legacyEdadRaw is int
              ? legacyEdadRaw
              : int.tryParse(legacyEdadRaw?.toString() ?? '') ?? 0);

      // ---------------------------
      // FOTO FINAL DEL CREADOR
      // ---------------------------
      String fotoFinal =
      creadorFoto.isNotEmpty ? creadorFoto : legacyFoto;

      if (fotoFinal.isEmpty || fotoFinal == 'assets/images/perfil1.jpg') {
        try {
          final snapUser = await FirebaseFirestore.instance
              .collection(kUsersCol)
              .doc(ownerFinal)
              .get();

          final dUser = snapUser.data() ?? {};
          final List urls = dUser['photoUrls'] ?? [];

          if (urls.isNotEmpty &&
              urls.first.toString().trim().isNotEmpty) {
            fotoFinal = urls.first.toString().trim();
          }
        } catch (_) {}
      }

      out.add(
        _CitaCardModel(
          citaId: d.id,
          ownerUid: ownerFinal,
          creatorName: creadorNombre,
          creatorAge: edadFinal,
          creatorPhoto: fotoFinal,
          placePhotos: placePhotos,
          placeName: nombreLugar,
          placeAddress: direccionLugar,
          fecha: fecha.isEmpty ? 'Fecha pendiente' : fecha,
          hora: hora.isEmpty ? 'Hora pendiente' : hora,
          intencion: intencion,
          preferencia: prefCita,
        ),
      );
    }

    return out;
  }

  // ---------------------------
  // UI NAV
  // ---------------------------
  void _backToPanel() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
      return;
    }
    nav.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const PanelScreen()),
          (_) => false,
    );
  }

  // ---------------------------
  // BUILD PRINCIPAL
  // ---------------------------
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Debes iniciar sesión',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          MatchyPageLayout(
            backgroundAsset: backgroundAsset,
            logoAsset: logoAsset,
            topSpacing: topSpacing,
            logoHeight: logoHeight,
            logoOffsetY: logoOffsetY,
            spaceLogoToScroll: spaceLogoToScroll,
            scrollContent: _buildBody(user.uid),
          ),

          Positioned(
            top: 10,
            left: 16,
            child: SafeArea(
              child: Material(
                color: Colors.black.withOpacity(0.25),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _backToPanel,
                  child: const SizedBox(
                    width: 42,
                    height: 42,
                    child: Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------
  // BODY (DECK + BOTONES)
  // ---------------------------
  Widget _buildBody(String uid) {
    final Size screen = MediaQuery.sizeOf(context);
    final double blockW =
        screen.width - (screenSideMargin * 2);
    final double photoH =
    (screen.height * photoHeightFactor)
        .clamp(photoMinHeight, photoMaxHeight);
    final double swipeH = photoH + gapPhotoToInfo + infoCardHeight;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _userDocStream(uid),
      builder: (context, userSnap) {
        final udata = userSnap.data?.data() ?? {};
        final prefGlobal = _normPref(
            (udata[kUserPreferenciaCitasField] ?? 'Ambos').toString());
        final generoUser = _normGenero(
            (udata[kUserGeneroField] ?? 'Prefiero no decirlo').toString());

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _citasPublicasStream(),
          builder: (context, citasSnap) {
            if (citasSnap.hasError) {
              return Center(
                child: Text(
                  'Error: ${citasSnap.error}',
                  style: TextStyle(color: Colors.redAccent),
                ),
              );
            }

            if (!citasSnap.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final docs = citasSnap.data!.docs;

            return FutureBuilder<List<_CitaCardModel>>(
              future: _mapDocsToDeck(docs: docs, uid: uid).then(
                    (raw) => _applyFilters(
                  raw: raw,
                  uid: uid,
                  generoUser: generoUser,
                  prefGlobal: prefGlobal,
                ),
              ),
              builder: (context, filtered) {
                if (filtered.connectionState ==
                    ConnectionState.waiting &&
                    _deck.isEmpty) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                final newDeck = filtered.data ?? [];

                final needReset =
                    _deck.length != newDeck.length ||
                        (_deck.isNotEmpty &&
                            newDeck.isNotEmpty &&
                            _deck.first.citaId !=
                                newDeck.first.citaId);

                if (needReset) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    setState(() {
                      _deck = newDeck;
                      _topIndex = 0;
                      _dx = 0.0;
                    });
                  });
                } else {
                  _deck = newDeck;
                  if (_topIndex > _deck.length) {
                    _topIndex = _deck.length;
                  }
                }

                final noMore =
                    _deck.isEmpty || _topIndex >= _deck.length;

                return Center(
                  child: Padding(
                    padding:
                    EdgeInsets.only(top: gapLogoToSwipeBlock),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: blockW,
                          height: swipeH,
                          child: Stack(
                            children: [
                              if (!noMore &&
                                  _topIndex + 1 < _deck.length)
                                Positioned.fill(
                                  child: _SwipeBundle(
                                    model: _deck[_topIndex + 1],
                                    likeOpacity: 0.0,
                                    nopeOpacity: 0.0,
                                    width: blockW,
                                    photoHeight: photoH,
                                    infoHeight: infoCardHeight,
                                    onCreatorPhotoTap: () {
                                      final m = _deck[_topIndex + 1];
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              CandidatoGaleriaScreen(
                                                userUid: m.ownerUid,
                                                fallbackSinglePhoto:
                                                m.creatorPhoto,
                                                placeName: m.placeName,
                                                placeAddress:
                                                m.placeAddress,
                                                fecha: m.fecha,
                                                hora: m.hora,
                                                preferencia:
                                                m.preferencia,
                                                intencion: m.intencion,
                                              ),
                                        ),
                                      );
                                    },
                                    onPlacePhotoTap: () {
                                      final m = _deck[_topIndex + 1];
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              LugarGaleriaScreen(
                                                placePhotos:
                                                m.placePhotos,
                                                placeName: m.placeName,
                                                placeAddress:
                                                m.placeAddress,
                                                fecha: m.fecha,
                                                hora: m.hora,
                                                preferencia:
                                                m.preferencia,
                                                intencion: m.intencion,
                                              ),
                                        ),
                                      );
                                    },
                                  ),
                                ),

                              if (!noMore)
                                Positioned.fill(
                                  child: GestureDetector(
                                    onPanUpdate: _onPanUpdate,
                                    onPanEnd: (d) =>
                                        _onPanEnd(d, screen, uid),
                                    child: Transform.translate(
                                      offset: Offset(_dx, 0),
                                      child: Transform.rotate(
                                        angle: _rotationDeg *
                                            (math.pi / 180),
                                        child: _SwipeBundle(
                                          model: _deck[_topIndex],
                                          likeOpacity:
                                          _likeOpacityValue,
                                          nopeOpacity:
                                          _nopeOpacityValue,
                                          width: blockW,
                                          photoHeight: photoH,
                                          infoHeight:
                                          infoCardHeight,
                                          onCreatorPhotoTap: () {
                                            final m =
                                            _deck[_topIndex];
                                            Navigator.of(context)
                                                .push(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    CandidatoGaleriaScreen(
                                                      userUid:
                                                      m.ownerUid,
                                                      fallbackSinglePhoto:
                                                      m.creatorPhoto,
                                                      placeName:
                                                      m.placeName,
                                                      placeAddress:
                                                      m.placeAddress,
                                                      fecha: m.fecha,
                                                      hora: m.hora,
                                                      preferencia:
                                                      m.preferencia,
                                                      intencion:
                                                      m.intencion,
                                                    ),
                                              ),
                                            );
                                          },
                                          onPlacePhotoTap: () {
                                            final m =
                                            _deck[_topIndex];
                                            Navigator.of(context)
                                                .push(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    LugarGaleriaScreen(
                                                      placePhotos:
                                                      m.placePhotos,
                                                      placeName:
                                                      m.placeName,
                                                      placeAddress:
                                                      m.placeAddress,
                                                      fecha: m.fecha,
                                                      hora: m.hora,
                                                      preferencia:
                                                      m.preferencia,
                                                      intencion:
                                                      m.intencion,
                                                    ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                              if (noMore)
                                Positioned.fill(
                                  child: Center(
                                    child: Container(
                                      width: blockW * 0.92,
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 14),
                                      decoration: BoxDecoration(
                                        color: Colors.black
                                            .withOpacity(0.38),
                                        borderRadius:
                                        BorderRadius.circular(
                                            18),
                                        border: Border.all(
                                          color: Colors.white24,
                                          width: 1,
                                        ),
                                      ),
                                      child: const Text(
                                        'No hay citas disponibles ahora.\n\nVuelve a intentarlo más tarde.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight:
                                          FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        if (!noMore)
                          Column(
                            children: [
                              SizedBox(
                                  height: gapSwipeBlockToButtons),
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.center,
                                children: [
                                  _AssetCircleButton(
                                    asset: iconClose,
                                    size: actionButtonSize,
                                    iconSize: actionIconSize,
                                    backgroundColor:
                                    actionCircleColor,
                                    onTap: () =>
                                        _onNope(screen, uid),
                                  ),
                                  SizedBox(
                                      width: actionButtonsGap),
                                  _AssetCircleButton(
                                    asset: iconFav,
                                    size: actionButtonSize,
                                    iconSize: actionIconSize,
                                    backgroundColor:
                                    actionCircleColor,
                                    onTap: () =>
                                        _onLike(screen, uid),
                                  ),
                                ],
                              ),
                              SizedBox(height: bottomPadding),
                            ],
                          ),
                        if (noMore) const SizedBox(height: 18),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

// =====================================================
// SWIPE BUNDLE (FOTO + INFO + BADGES + TÍTULO)
// =====================================================
class _SwipeBundle extends StatelessWidget {
  final _CitaCardModel model;
  final double likeOpacity;
  final double nopeOpacity;
  final double width;
  final double photoHeight;
  final double infoHeight;
  final VoidCallback onCreatorPhotoTap;
  final VoidCallback onPlacePhotoTap;

  const _SwipeBundle({
    required this.model,
    required this.likeOpacity,
    required this.nopeOpacity,
    required this.width,
    required this.photoHeight,
    required this.infoHeight,
    required this.onCreatorPhotoTap,
    required this.onPlacePhotoTap,
  });

  bool _isNet(String v) =>
      v.startsWith('http://') || v.startsWith('https://');

  Widget _creatorPhoto() {
    final src = model.creatorPhoto.trim();

    if (src.isEmpty) {
      return Image.asset(
        'assets/images/perfil1.jpg',
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
      );
    }

    if (_isNet(src)) {
      return Image.network(
        src,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        errorBuilder: (_, __, ___) => Image.asset(
          'assets/images/perfil1.jpg',
          fit: BoxFit.cover,
        ),
      );
    }

    return Image.asset(
      src,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      errorBuilder: (_, __, ___) => Image.asset(
        'assets/images/perfil1.jpg',
        fit: BoxFit.cover,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        children: [
          Container(
            width: width,
            height: photoHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                  _CitaBuscarScreenState.photoRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(
                      _CitaBuscarScreenState.shadowOpacity),
                  blurRadius:
                  _CitaBuscarScreenState.shadowBlur,
                  offset: Offset(
                      0, _CitaBuscarScreenState.shadowOffsetY),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                GestureDetector(
                    onTap: onCreatorPhotoTap,
                    child: _creatorPhoto()),

                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    ignoring: true,
                    child: Container(
                      height:
                      _CitaBuscarScreenState.photoGradientHeight,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(
                                _CitaBuscarScreenState
                                    .photoGradientBottomOpacity),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ---------------------------
                // TÍTULO: NOMBRE + EDAD
                // ---------------------------
                Positioned(
                  left: _CitaBuscarScreenState.titleLeft,
                  bottom: _CitaBuscarScreenState.titleBottom,
                  child: IgnorePointer(
                    ignoring: true,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: width *
                            _CitaBuscarScreenState
                                .titleMaxWidthFactor,
                      ),
                      child: RichText(
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: model.creatorName,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: _CitaBuscarScreenState
                                    .titleNameSize,
                                fontWeight: FontWeight.w900,
                                shadows: [
                                  Shadow(
                                    blurRadius:
                                    _CitaBuscarScreenState
                                        .titleShadowBlur,
                                    color: Colors.black
                                        .withOpacity(
                                        _CitaBuscarScreenState
                                            .titleShadowOpacity),
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            TextSpan(
                              text: model.creatorAge > 0
                                  ? ', ${model.creatorAge}'
                                  : '',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: _CitaBuscarScreenState
                                    .titleAgeSize,
                                fontWeight: FontWeight.w900,
                                shadows: [
                                  Shadow(
                                    blurRadius:
                                    _CitaBuscarScreenState
                                        .titleShadowBlur,
                                    color: Colors.black
                                        .withOpacity(
                                        _CitaBuscarScreenState
                                            .titleShadowOpacity),
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

                // BADGES (LIKE / NOPE)
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

          SizedBox(
              height: _CitaBuscarScreenState.gapPhotoToInfo),

          _CitaInfoCard(
            width: width,
            height: infoHeight,
            model: model,
            onPlaceTap: onPlacePhotoTap,
          ),
        ],
      ),
    );
  }
}

// =====================================================
// INFO CARD
// =====================================================
class _CitaInfoCard extends StatelessWidget {
  final double width;
  final double height;
  final _CitaCardModel model;
  final VoidCallback onPlaceTap;

  const _CitaInfoCard({
    required this.width,
    required this.height,
    required this.model,
    required this.onPlaceTap,
  });

  bool _isNet(String v) => v.startsWith('http');

  @override
  Widget build(BuildContext context) {
    final src =
    (model.placePhotos.isNotEmpty ? model.placePhotos.first : '').trim();

    Widget bg;

    if (src.isEmpty) {
      bg = Image.asset('assets/images/perfil1.jpg', fit: BoxFit.cover);
    } else if (_isNet(src)) {
      bg = Image.network(src,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              Image.asset('assets/images/perfil1.jpg'));
    } else {
      bg = Image.asset(src,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              Image.asset('assets/images/perfil1.jpg'));
    }

    return GestureDetector(
      onTap: onPlaceTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius:
          BorderRadius.circular(_CitaBuscarScreenState.infoRadius),
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
            bg,
            Container(color: Colors.black.withOpacity(0.35)),
            Positioned(
              left: 14,
              right: 14,
              top: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          model.fecha,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Text(
                        model.hora,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Preferencia: ${model.preferencia}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Intención: ${model.intencion}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    model.placeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    model.placeAddress,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// BADGE LIKE / NOPE
// =====================================================
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
      padding:
      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w900,
          color: textColor,
          shadows: [
            Shadow(
              blurRadius: 10,
              color: Colors.black.withOpacity(0.30),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// BOTÓN REDONDO CON ASSET
// =====================================================
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

// =====================================================
// MODELO DE CITA
// =====================================================
class _CitaCardModel {
  final String citaId;
  final String ownerUid;
  final String creatorName;
  final int creatorAge;
  final String creatorPhoto;
  final List<String> placePhotos;
  final String placeName;
  final String placeAddress;
  final String fecha;
  final String hora;
  final String intencion;
  final String preferencia;

  const _CitaCardModel({
    required this.citaId,
    required this.ownerUid,
    required this.creatorName,
    required this.creatorAge,
    required this.creatorPhoto,
    required this.placePhotos,
    required this.placeName,
    required this.placeAddress,
    required this.fecha,
    required this.hora,
    required this.intencion,
    required this.preferencia,
  });
}
