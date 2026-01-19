// 📂 lib/screens/cita_buscar.dart
// ✅ CITA BUSCAR — Swipe tipo Tinder
// 🔥 FULL CONTROL: Chinches para tamaños, posiciones y textos.
// 🔥 NAV: Lugar lleva a Plantilla SIN botón.
// 🔧 FIX: Variables min/max height reincorporadas.
// 🔧 FIX: Foto lugar anclada al TOP + Fondo Negro.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:proyectos_matchy/widgets/matchy_page_layout.dart';
import 'package:proyectos_matchy/screens/panel_screen.dart';
import 'package:proyectos_matchy/screens/perfil_usuariox_screen.dart';
import 'package:proyectos_matchy/screens/lugar_plantilla_sin_boton_screen.dart';
import 'package:proyectos_matchy/models/lugar_data.dart';

class CitaBuscarScreen extends StatefulWidget {
  static const String routeName = 'cita_buscar';

  const CitaBuscarScreen({super.key});

  @override
  State<CitaBuscarScreen> createState() => _CitaBuscarScreenState();
}

class _CitaBuscarScreenState extends State<CitaBuscarScreen>
    with SingleTickerProviderStateMixin {

  // ==============================================================================
  // 🔴🔴 SECCIÓN CHINCHES DE EDICIÓN (Ajusta todo aquí) 🔴🔴
  // ==============================================================================

  // --- 1. CONTENEDOR FOTO (Arriba - Persona) ---
  static const double kPhotoHeightFactor = 0.43;  // Altura % de la pantalla
  static const double kPhotoMinHeight    = 380.0; // 🟢 Altura Mínima
  static const double kPhotoMaxHeight    = 560.0; // 🟢 Altura Máxima
  static const double kPhotoWidthFactor  = 1.0;   // Ancho %
  static const double kPhotoOffsetY      = 0.0;   // Desplazamiento vertical

  // --- 2. CONTENEDOR INFO (Abajo - Lugar) ---
  static const double kInfoHeight        = 260.0; // Altura fija (Aumenta esto para ver más negro abajo)
  static const double kInfoWidthFactor   = 1.0;   // Ancho %
  static const double kInfoOffsetY       = 0.0;   // Desplazamiento vertical
  static const double kGapPhotoToInfo    = 14.0;  // Espacio entre foto y tarjeta info

  // --- 3. TEXTOS (Tamaños de letra) ---
  static const double kTextNameSize      = 27.0;
  static const double kTextAgeSize       = 27.0;
  static const double kTextDateSize      = 26.0;
  static const double kTextTimeSize      = 26.0;
  static const double kTextPrefSize      = 11.0;
  static const double kTextIntentSize    = 11.0;
  static const double kTextPlaceNameSize = 27.0;
  static const double kTextAddressSize   = 14.0;

  // --- 4. BOTONES DE ACCIÓN ---
  static const double kButtonsSize       = 64.0;
  static const double kButtonsIconSize   = 70.0;
  static const double kButtonsGap        = 150.0;
  static const double kButtonsTopGap     = 20.0;

  // ==============================================================================
  // FIN SECCIÓN CHINCHES
  // ==============================================================================

  // ... (Resto de constantes de configuración interna) ...
  static const double decisionThresholdPx = 75.0;
  static const double rotationDivisor = 14.0;
  static const double opacityDivisor = 100.0;
  static const int flingDurationMs = 340;
  static const int resetDurationMs = 240;
  static const double offscreenDiagMultiplier = 2.2;
  static const double offscreenExtraPx = 180.0;

  static const String backgroundAsset = 'assets/images/fondo.jpg';
  static const String logoAsset = 'assets/images/logomatchyplano.png';
  static const String iconClose = 'assets/images/ic_close_white.png';
  static const String iconFav = 'assets/images/ic_favorite_white.png';

  static const double topSpacing = 35.0;
  static const double logoHeight = 50.0;
  static const double logoOffsetY = 0.0;
  static const double spaceLogoToScroll = 15.0;
  static const double screenSideMargin = 14.0;
  static const double gapLogoToSwipeBlock = 8.0;

  static const double photoRadius = 28.0;
  static const double infoRadius = 16.0;
  static const double shadowOpacity = 0.45;
  static const double shadowBlur = 12.0;
  static const double shadowOffsetY = 7.0;

  static const double titleLeft = 24.0;
  static const double titleBottom = 16.0;
  static const double titleMaxWidthFactor = 0.78;
  static const double titleShadowBlur = 10.0;
  static const double titleShadowOpacity = 0.70;

  static const double photoGradientHeight = 170.0;
  static const double photoGradientBottomOpacity = 0.85;
  static const Color actionCircleColor = Color(0xFF7E79B6);
  static const double bottomPadding = 14.0;

  static const String publicStatus = 'online';

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

  List<_CitaCardModel> _deck = const [];
  int _topIndex = 0;
  double _dx = 0.0;
  bool _isAnimating = false;

  late final AnimationController _controller;
  Animation<double>? _dxAnim;
  final Map<String, Map<String, dynamic>> _userCache = {};

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

  double get _rotationDeg => _dx / rotationDivisor;
  double get _likeOpacityValue => _dx > 0 ? (_dx.abs() / opacityDivisor).clamp(0.0, 1.0) : 0.0;
  double get _nopeOpacityValue => _dx < 0 ? (_dx.abs() / opacityDivisor).clamp(0.0, 1.0) : 0.0;

  Future<void> _animateTo(double target, Duration dur) async {
    _controller.stop();
    _controller.duration = dur;
    _dxAnim = Tween<double>(begin: _dx, end: target).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    await _controller.forward(from: 0.0);
  }

  Future<void> _resetCard() async {
    _isAnimating = true;
    await _animateTo(0.0, const Duration(milliseconds: resetDurationMs));
  }

  double _screenDiag(Size s) => math.sqrt(s.width * s.width + s.height * s.height);

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
    final target = (right ? 1 : -1) * (diag * offscreenDiagMultiplier + offscreenExtraPx);
    await _animateTo(target, Duration(milliseconds: durationMs));
    if (!mounted) return;
    setState(() {
      _topIndex++;
      _dx = 0.0;
    });
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
      durationMs: flingDurationMs,
    );
  }

  Future<void> _onNope(Size size, String uid) async {
    if (_isAnimating || _topIndex >= _deck.length) return;
    _dx = -decisionThresholdPx;
    await _flingOut(right: false, size: size, model: _deck[_topIndex], uid: uid, durationMs: flingDurationMs);
  }

  Future<void> _onLike(Size size, String uid) async {
    if (_isAnimating || _topIndex >= _deck.length) return;
    _dx = decisionThresholdPx;
    await _flingOut(right: true, size: size, model: _deck[_topIndex], uid: uid, durationMs: flingDurationMs);
  }

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

  Future<void> _writeDescartado({required String citaId, required String uid}) async {
    await FirebaseFirestore.instance
        .collection(kCitasCol).doc(citaId).collection(kSubDescartes).doc(uid)
        .set({'uid': uid, 'createdAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
  }

  Future<void> _writeCandidato({required _CitaCardModel model, required String uid}) async {
    String nombre = '';
    int edad = 0;
    String foto = '';
    try {
      final mySnap = await FirebaseFirestore.instance.collection(kUsersCol).doc(uid).get();
      final d = mySnap.data() ?? {};
      nombre = _pickNombreFromUserDoc(d);
      edad = _pickEdadFromUserDoc(d);
      foto = _pickFotoFromUserDoc(d);
    } catch (_) {}
    await FirebaseFirestore.instance
        .collection(kCitasCol).doc(model.citaId).collection(kSubCandidatos).doc(uid)
        .set({
      'uid': uid,
      'createdAt': FieldValue.serverTimestamp(),
      'nombre': nombre,
      'edad': edad,
      'foto': foto,
      'citaId': model.citaId,
      'ownerUid': model.ownerUid,
    }, SetOptions(merge: true));
  }

  String _s(dynamic v) => v is String ? v : (v?.toString() ?? '');
  String _two(int n) => n.toString().padLeft(2, '0');
  String _fmtFecha(DateTime dt) => '${_two(dt.day)}/${_two(dt.month)}/${dt.year}';
  String _fmtHora(DateTime dt) {
    int h = dt.hour;
    final ampm = h >= 12 ? 'PM' : 'AM';
    h = h % 12;
    if (h == 0) h = 12;
    return '$h:${_two(dt.minute)} $ampm';
  }

  List<String> _safeList(dynamic v) => v is List ? v.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList() : <String>[];
  Map<String, dynamic> _safeMap(dynamic v) => v is Map ? Map<String, dynamic>.from(v) : {};

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

  bool _citaAcepta({required String prefCita, required String generoUser}) {
    final p = _normPref(prefCita);
    if (p == 'Ambos') return true;
    return p == generoUser;
  }

  bool _userAcepta({required String prefGlobal, required String genDueno}) {
    final p = _normPref(prefGlobal);
    if (p == 'Ambos') return true;
    return p == genDueno;
  }

  String _pickNombreFromUserDoc(Map<String, dynamic> d) => (d['nombre'] ?? d['name'] ?? d['displayName'] ?? '').toString().trim();
  int _pickEdadFromUserDoc(Map<String, dynamic> d) {
    final e = d['edad'] ?? d['age'];
    if (e is int) return e;
    if (e is String) return int.tryParse(e) ?? 0;
    return 0;
  }

  String _pickFotoFromUserDoc(Map<String, dynamic> d) {
    final keys = ['profilePhotoUrl', 'photoUrl', 'fotoPerfil', 'foto', 'profilePhoto', 'photo'];
    for (final k in keys) {
      final v = (d[k] ?? '').toString().trim();
      if (v.isNotEmpty) return v;
    }
    final list1 = (d['photoUrls'] as List<dynamic>? ?? []).map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    if (list1.isNotEmpty) return list1.first;
    return '';
  }

  Map<String, dynamic> _readCreador(Map<String, dynamic> data) => _safeMap(data['creador']);

  Future<Map<String, dynamic>> _getUserDocCached(String uid) async {
    if (_userCache.containsKey(uid)) return _userCache[uid]!;
    try {
      final snap = await FirebaseFirestore.instance.collection(kUsersCol).doc(uid).get();
      final d = snap.data() ?? {};
      _userCache[uid] = d;
      return d;
    } catch (_) {
      _userCache[uid] = {};
      return {};
    }
  }

  Future<List<_CitaCardModel>> _applyFilters({
    required List<_CitaCardModel> raw,
    required String uid,
    required String generoUser,
    required String prefGlobal,
  }) async {
    final out = <_CitaCardModel>[];
    for (final m in raw) {
      final docDesc = await FirebaseFirestore.instance.collection(kCitasCol).doc(m.citaId).collection(kSubDescartes).doc(uid).get();
      final docCand = await FirebaseFirestore.instance.collection(kCitasCol).doc(m.citaId).collection(kSubCandidatos).doc(uid).get();
      if (docDesc.exists || docCand.exists) continue;
      out.add(m);
    }
    final ownerUids = out.map((e) => e.ownerUid).where((e) => e.isNotEmpty && e != uid).toSet().toList();
    final genDueno = <String, String>{};
    for (final ou in ownerUids) {
      try {
        final snap = await FirebaseFirestore.instance.collection(kUsersCol).doc(ou).get();
        genDueno[ou] = _normGenero((snap.data() ?? {})[kUserGeneroField]?.toString() ?? '');
      } catch (_) {
        genDueno[ou] = 'NoDecir';
      }
    }
    final filtrados = <_CitaCardModel>[];
    for (final m in out) {
      final g = genDueno[m.ownerUid] ?? 'NoDecir';
      if (_citaAcepta(prefCita: m.preferencia, generoUser: generoUser) && _userAcepta(prefGlobal: prefGlobal, genDueno: g)) {
        filtrados.add(m);
      }
    }
    return filtrados;
  }

  Future<List<_CitaCardModel>> _mapDocsToDeck({required List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, required String uid}) async {
    final out = <_CitaCardModel>[];
    for (final d in docs) {
      final data = d.data();
      final ownerUid = _s(data[kOwnerUidField]).trim();
      if (ownerUid == uid) continue;

      final lugar = _safeMap(data[kLugarField]);
      final nombreLugar = _s(lugar['nombre']).isNotEmpty ? _s(lugar['nombre']) : (_s(data['lugarNombre']).isNotEmpty ? _s(data['lugarNombre']) : (_s(data['nombre']).isNotEmpty ? _s(data['nombre']) : 'Lugar'));
      final direccionLugar = _s(lugar['direccion']).isNotEmpty ? _s(lugar['direccion']) : (_s(data['lugarDireccion']).isNotEmpty ? _s(data['lugarDireccion']) : (_s(data['direccion']).isNotEmpty ? _s(data['direccion']) : 'Sin dirección'));

      String fotoPortada = _s(lugar['fotoPortada']).trim();
      if (fotoPortada.isEmpty) fotoPortada = _s(lugar['foto']).trim();
      if (fotoPortada.isEmpty) fotoPortada = _s(data['lugarFotoPortada']).trim();
      if (fotoPortada.isEmpty) fotoPortada = _s(data['fotoLugar']).trim();

      final placePhotos = <String>[];
      if (fotoPortada.isNotEmpty) placePhotos.add(fotoPortada);
      for (final f in _safeList(lugar['fotos'])) { if (!placePhotos.contains(f)) placePhotos.add(f); }
      for (final f in _safeList(data['lugarFotos'])) { if (!placePhotos.contains(f)) placePhotos.add(f); }
      if (placePhotos.isEmpty) placePhotos.add('assets/images/perfil1.jpg');

      String fecha = _s(data[kFechaField]);
      String hora = _s(data[kHoraField]);
      final sched = data['scheduledAt'];
      if (sched is Timestamp) {
        final dt = sched.toDate();
        fecha = _fmtFecha(dt);
        hora = _fmtHora(dt);
      }

      final intencion = _s(data['intencion']).isEmpty ? 'Amistad' : _s(data['intencion']);
      final prefCita = _s(data['preferencia']).isEmpty ? 'Ambos' : _s(data['preferencia']);

      final creador = _readCreador(data);
      String creadorNombre = _s(creador['nombre']).trim();
      final creadorEdadRaw = creador['edad'];
      String creadorFoto = _s(creador['foto']).trim();
      final creadorUidFromObj = _s(creador['uid']).trim();
      final legacyNombre = _s(data['creadorNombre']).trim();
      final legacyEdadRaw = data['creadorEdad'];
      final legacyFoto = _s(data['creadorFoto']).trim();

      final ownerFinal = ownerUid.isNotEmpty ? ownerUid : (creadorUidFromObj.isNotEmpty ? creadorUidFromObj : 'unknown');
      int edadFinal = 0;
      if (creadorEdadRaw is int) { edadFinal = creadorEdadRaw; } else { edadFinal = int.tryParse(creadorEdadRaw?.toString() ?? '') ?? 0; }
      if (edadFinal <= 0) { if (legacyEdadRaw is int) { edadFinal = legacyEdadRaw; } else { edadFinal = int.tryParse(legacyEdadRaw?.toString() ?? '') ?? 0; } }
      if (creadorNombre.isEmpty) creadorNombre = legacyNombre;
      String fotoFinal = creadorFoto.isNotEmpty ? creadorFoto : legacyFoto;

      if (ownerFinal.isNotEmpty && ownerFinal != 'unknown') {
        final needNombre = creadorNombre.isEmpty;
        final needEdad = edadFinal <= 0;
        final needFoto = fotoFinal.isEmpty || fotoFinal == 'assets/images/perfil1.jpg';
        if (needNombre || needEdad || needFoto) {
          final u = await _getUserDocCached(ownerFinal);
          if (needNombre) { final n = _pickNombreFromUserDoc(u); if (n.isNotEmpty) creadorNombre = n; }
          if (needEdad) { final e = _pickEdadFromUserDoc(u); if (e > 0) edadFinal = e; }
          if (needFoto) { final f = _pickFotoFromUserDoc(u); if (f.isNotEmpty) fotoFinal = f; }
        }
      }
      if (creadorNombre.isEmpty) creadorNombre = 'Usuario';
      if (fotoFinal.isEmpty) fotoFinal = 'assets/images/perfil1.jpg';

      out.add(_CitaCardModel(
        citaId: d.id, ownerUid: ownerFinal, creatorName: creadorNombre, creatorAge: edadFinal,
        creatorPhoto: fotoFinal, placePhotos: placePhotos, placeName: nombreLugar, placeAddress: direccionLugar,
        fecha: fecha.isEmpty ? 'Fecha pendiente' : fecha, hora: hora.isEmpty ? 'Hora pendiente' : hora,
        intencion: intencion, preferencia: prefCita,
      ));
    }
    return out;
  }

  void _backToPanel() {
    final nav = Navigator.of(context);
    if (nav.canPop()) { nav.pop(); return; }
    nav.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const PanelScreen()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('Debes iniciar sesión', style: TextStyle(color: Colors.white))));

    return Scaffold(
      body: Stack(
        children: [
          MatchyPageLayout(
            backgroundAsset: backgroundAsset, logoAsset: logoAsset, topSpacing: topSpacing,
            logoHeight: logoHeight, logoOffsetY: logoOffsetY, spaceLogoToScroll: spaceLogoToScroll,
            scrollContent: _buildBody(user.uid),
          ),
          Positioned(
            top: 10, left: 16,
            child: SafeArea(
              child: Material(
                color: Colors.black.withOpacity(0.25), shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(), onTap: _backToPanel,
                  child: const SizedBox(width: 42, height: 42, child: Icon(Icons.arrow_back, color: Colors.white)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(String uid) {
    final Size screen = MediaQuery.sizeOf(context);
    final double blockW = screen.width - (screenSideMargin * 2);
    final double photoH = (screen.height * kPhotoHeightFactor).clamp(kPhotoMinHeight, kPhotoMaxHeight);
    final double swipeH = photoH + kGapPhotoToInfo + kInfoHeight;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _userDocStream(uid),
      builder: (context, userSnap) {
        final udata = userSnap.data?.data() ?? {};
        final prefGlobal = _normPref((udata[kUserPreferenciaCitasField] ?? 'Ambos').toString());
        final generoUser = _normGenero((udata[kUserGeneroField] ?? 'Prefiero no decirlo').toString());

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _citasPublicasStream(),
          builder: (context, citasSnap) {
            if (citasSnap.hasError) return Center(child: Text('Error: ${citasSnap.error}', style: const TextStyle(color: Colors.redAccent)));
            if (!citasSnap.hasData) return const Center(child: CircularProgressIndicator());
            final docs = citasSnap.data!.docs;

            return FutureBuilder<List<_CitaCardModel>>(
              future: _mapDocsToDeck(docs: docs, uid: uid).then((raw) => _applyFilters(raw: raw, uid: uid, generoUser: generoUser, prefGlobal: prefGlobal)),
              builder: (context, filtered) {
                if (filtered.connectionState == ConnectionState.waiting && _deck.isEmpty) return const Center(child: CircularProgressIndicator());
                final newDeck = filtered.data ?? [];
                final needReset = _deck.length != newDeck.length || (_deck.isNotEmpty && newDeck.isNotEmpty && _deck.first.citaId != newDeck.first.citaId);
                if (needReset) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    setState(() { _deck = newDeck; _topIndex = 0; _dx = 0.0; });
                  });
                } else { _deck = newDeck; if (_topIndex > _deck.length) _topIndex = _deck.length; }
                final noMore = _deck.isEmpty || _topIndex >= _deck.length;

                return Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: gapLogoToSwipeBlock),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: blockW, height: swipeH,
                          child: Stack(
                            children: [
                              if (!noMore && _topIndex + 1 < _deck.length)
                                Positioned.fill(
                                  child: _SwipeBundle(
                                    model: _deck[_topIndex + 1], likeOpacity: 0.0, nopeOpacity: 0.0,
                                    width: blockW, photoHeight: photoH, infoHeight: kInfoHeight,
                                    onCreatorPhotoTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PerfilUsuarioXScreen(uid: _deck[_topIndex + 1].ownerUid))),
                                    onPlacePhotoTap: () {
                                      final m = _deck[_topIndex + 1];
                                      final lugar = LugarData(id: m.citaId, nombre: m.placeName, direccion: m.placeAddress, bio: '', fotos: m.placePhotos, fotoPortada: m.placePhotos.first, sitioWeb: '', orden: 9999, sedes: const []);
                                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => LugarPlantillaSinBotonScreen(lugar: lugar)));
                                    },
                                  ),
                                ),
                              if (!noMore)
                                Positioned.fill(
                                  child: GestureDetector(
                                    onPanUpdate: _onPanUpdate, onPanEnd: (d) => _onPanEnd(d, screen, uid),
                                    child: Transform.translate(
                                      offset: Offset(_dx, 0),
                                      child: Transform.rotate(
                                        angle: _rotationDeg * (math.pi / 180),
                                        child: _SwipeBundle(
                                          model: _deck[_topIndex], likeOpacity: _likeOpacityValue, nopeOpacity: _nopeOpacityValue,
                                          width: blockW, photoHeight: photoH, infoHeight: kInfoHeight,
                                          onCreatorPhotoTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PerfilUsuarioXScreen(uid: _deck[_topIndex].ownerUid))),
                                          onPlacePhotoTap: () {
                                            final m = _deck[_topIndex];
                                            final lugar = LugarData(id: m.citaId, nombre: m.placeName, direccion: m.placeAddress, bio: '', fotos: m.placePhotos, fotoPortada: m.placePhotos.first, sitioWeb: '', orden: 9999, sedes: const []);
                                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => LugarPlantillaSinBotonScreen(lugar: lugar)));
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
                                      width: blockW * 0.92, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.38), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white24, width: 1)),
                                      child: const Text('No hay citas disponibles ahora.\n\nVuelve a intentarlo más tarde.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (!noMore)
                          Column(
                            children: [
                              const SizedBox(height: kButtonsTopGap),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _AssetCircleButton(asset: iconClose, size: kButtonsSize, iconSize: kButtonsIconSize, backgroundColor: actionCircleColor, onTap: () => _onNope(screen, uid)),
                                  const SizedBox(width: kButtonsGap),
                                  _AssetCircleButton(asset: iconFav, size: kButtonsSize, iconSize: kButtonsIconSize, backgroundColor: actionCircleColor, onTap: () => _onLike(screen, uid)),
                                ],
                              ),
                              const SizedBox(height: bottomPadding),
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
    required this.model, required this.likeOpacity, required this.nopeOpacity,
    required this.width, required this.photoHeight, required this.infoHeight,
    required this.onCreatorPhotoTap, required this.onPlacePhotoTap,
  });

  bool _isNet(String v) => v.startsWith('http');
  bool _isAsset(String v) => v.startsWith('assets/');

  Widget _creatorPhoto() {
    final src = model.creatorPhoto.trim();
    if (src.isEmpty) return Image.asset('assets/images/perfil1.jpg', fit: BoxFit.cover, alignment: Alignment.topCenter);
    if (_isNet(src)) {
      return Image.network(src, fit: BoxFit.cover, alignment: Alignment.topCenter,
          loadingBuilder: (_, c, p) => p == null ? c : Container(color: Colors.black26, alignment: Alignment.center, child: const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
          errorBuilder: (_, __, ___) => Image.asset('assets/images/perfil1.jpg', fit: BoxFit.cover, alignment: Alignment.topCenter));
    }
    return Image.asset(_isAsset(src) ? src : 'assets/images/perfil1.jpg', fit: BoxFit.cover, alignment: Alignment.topCenter,
        errorBuilder: (_, __, ___) => Image.asset('assets/images/perfil1.jpg', fit: BoxFit.cover, alignment: Alignment.topCenter));
  }

  @override
  Widget build(BuildContext context) {
    // 🔴 APLICANDO CHINCHES FOTO
    final double cardWidth = width * _CitaBuscarScreenState.kPhotoWidthFactor;

    return SizedBox(
      width: width,
      child: Column(
        children: [
          // Espacio para Offset Vertical
          SizedBox(height: _CitaBuscarScreenState.kPhotoOffsetY > 0 ? _CitaBuscarScreenState.kPhotoOffsetY : 0),
          Transform.translate(
            offset: Offset(0, _CitaBuscarScreenState.kPhotoOffsetY < 0 ? _CitaBuscarScreenState.kPhotoOffsetY : 0),
            child: Container(
              width: cardWidth,
              height: photoHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_CitaBuscarScreenState.photoRadius),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(_CitaBuscarScreenState.shadowOpacity), blurRadius: _CitaBuscarScreenState.shadowBlur, offset: Offset(0, _CitaBuscarScreenState.shadowOffsetY))],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  GestureDetector(onTap: onCreatorPhotoTap, child: _creatorPhoto()),
                  Positioned(left: 0, right: 0, bottom: 0, child: IgnorePointer(ignoring: true, child: Container(height: _CitaBuscarScreenState.photoGradientHeight, decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(_CitaBuscarScreenState.photoGradientBottomOpacity)]))))),
                  Positioned(
                    left: _CitaBuscarScreenState.titleLeft, bottom: _CitaBuscarScreenState.titleBottom,
                    child: IgnorePointer(
                      ignoring: true,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: cardWidth * _CitaBuscarScreenState.titleMaxWidthFactor),
                        child: RichText(
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          text: TextSpan(children: [
                            TextSpan(text: model.creatorName, style: TextStyle(color: Colors.white, fontSize: _CitaBuscarScreenState.kTextNameSize, fontWeight: FontWeight.w900, shadows: [Shadow(blurRadius: _CitaBuscarScreenState.titleShadowBlur, color: Colors.black.withOpacity(_CitaBuscarScreenState.titleShadowOpacity), offset: const Offset(0, 2))])),
                            TextSpan(text: model.creatorAge > 0 ? ', ${model.creatorAge}' : '', style: TextStyle(color: Colors.white, fontSize: _CitaBuscarScreenState.kTextAgeSize, fontWeight: FontWeight.w900, shadows: [Shadow(blurRadius: _CitaBuscarScreenState.titleShadowBlur, color: Colors.black.withOpacity(_CitaBuscarScreenState.titleShadowOpacity), offset: const Offset(0, 2))])),
                          ]),
                        ),
                      ),
                    ),
                  ),
                  IgnorePointer(
                    child: Opacity(
                      opacity: 0.0,
                      child: Stack(children: [
                        Positioned(left: 16, top: 90, child: Opacity(opacity: likeOpacity, child: Transform.rotate(angle: -30 * (math.pi / 180), child: const _ChoiceBadge(text: 'LIKE', borderColor: Color(0xFF63FF68), textColor: Color(0xFF63FF68))))),
                        Positioned(right: 16, top: 90, child: Opacity(opacity: nopeOpacity, child: Transform.rotate(angle: 30 * (math.pi / 180), child: const _ChoiceBadge(text: 'NOPE', borderColor: Color(0xFFFF6E63), textColor: Color(0xFFFF6E63))))),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: _CitaBuscarScreenState.kGapPhotoToInfo),

          // 🔴 APLICANDO CHINCHES INFO
          SizedBox(height: _CitaBuscarScreenState.kInfoOffsetY > 0 ? _CitaBuscarScreenState.kInfoOffsetY : 0),
          Transform.translate(
            offset: Offset(0, _CitaBuscarScreenState.kInfoOffsetY < 0 ? _CitaBuscarScreenState.kInfoOffsetY : 0),
            child: _CitaInfoCard(
              width: width * _CitaBuscarScreenState.kInfoWidthFactor,
              height: infoHeight,
              model: model,
              onPlaceTap: onPlacePhotoTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _CitaInfoCard extends StatelessWidget {
  final double width;
  final double height;
  final _CitaCardModel model;
  final VoidCallback onPlaceTap;

  const _CitaInfoCard({required this.width, required this.height, required this.model, required this.onPlaceTap});

  bool _isNet(String v) => v.startsWith('http');
  bool _isAsset(String v) => v.startsWith('assets/');

  @override
  Widget build(BuildContext context) {
    final src = (model.placePhotos.isNotEmpty ? model.placePhotos.first : '').trim();
    Widget bg;
    if (src.isEmpty) { bg = Image.asset('assets/images/perfil1.jpg', fit: BoxFit.cover); }
    else if (_isNet(src)) { bg = Image.network(src, fit: BoxFit.cover, alignment: Alignment.topCenter, loadingBuilder: (_, c, p) => p == null ? c : Container(color: Colors.black26, alignment: Alignment.center, child: const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))), errorBuilder: (_, __, ___) => Image.asset('assets/images/perfil1.jpg', fit: BoxFit.cover)); }
    else { bg = Image.asset(_isAsset(src) ? src : 'assets/images/perfil1.jpg', fit: BoxFit.cover, alignment: Alignment.topCenter, errorBuilder: (_, __, ___) => Image.asset('assets/images/perfil1.jpg', fit: BoxFit.cover)); }

    return GestureDetector(
      onTap: onPlaceTap,
      child: Container(
        width: width, height: height,
        decoration: BoxDecoration(
          color: Colors.black, // 🔥 FONDO NEGRO BASE
          borderRadius: BorderRadius.circular(_CitaBuscarScreenState.infoRadius),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.30), blurRadius: 10.0, offset: const Offset(0, 6))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            bg, Container(color: Colors.black.withOpacity(0.35)),
            Positioned(
              left: 14, right: 14, top: 10,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(model.fecha, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: _CitaBuscarScreenState.kTextDateSize, fontWeight: FontWeight.w900))),
                  Text(model.hora, style: const TextStyle(color: Colors.white, fontSize: _CitaBuscarScreenState.kTextTimeSize, fontWeight: FontWeight.w900)),
                ]),
                const SizedBox(height: 6),
                Text('Preferencia: ${model.preferencia}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: _CitaBuscarScreenState.kTextPrefSize, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('Intención: ${model.intencion}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: _CitaBuscarScreenState.kTextIntentSize, fontWeight: FontWeight.w700)),
              ]),
            ),
            Positioned(
              left: 14, right: 14, bottom: 12,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(model.placeName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: _CitaBuscarScreenState.kTextPlaceNameSize, fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(model.placeAddress, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: _CitaBuscarScreenState.kTextAddressSize, fontWeight: FontWeight.w600)),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceBadge extends StatelessWidget {
  final String text; final Color borderColor; final Color textColor;
  const _ChoiceBadge({required this.text, required this.borderColor, required this.textColor});
  @override Widget build(BuildContext context) { return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(border: Border.all(color: borderColor, width: 4), borderRadius: BorderRadius.circular(8)), child: Text(text, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: textColor, shadows: [Shadow(blurRadius: 10, color: Colors.black.withOpacity(0.30))]))); }
}

class _AssetCircleButton extends StatelessWidget {
  final String asset; final double size; final double iconSize; final Color backgroundColor; final VoidCallback onTap;
  const _AssetCircleButton({required this.asset, required this.size, required this.iconSize, required this.backgroundColor, required this.onTap});
  @override Widget build(BuildContext context) { return Material(color: backgroundColor, shape: const CircleBorder(), elevation: 3.0, child: InkWell(customBorder: const CircleBorder(), onTap: onTap, child: SizedBox(width: size, height: size, child: Center(child: Image.asset(asset, width: iconSize, height: iconSize, fit: BoxFit.contain))))); }
}

class _CitaCardModel {
  final String citaId; final String ownerUid; final String creatorName; final int creatorAge; final String creatorPhoto;
  final List<String> placePhotos; final String placeName; final String placeAddress; final String fecha; final String hora; final String intencion; final String preferencia;
  const _CitaCardModel({required this.citaId, required this.ownerUid, required this.creatorName, required this.creatorAge, required this.creatorPhoto, required this.placePhotos, required this.placeName, required this.placeAddress, required this.fecha, required this.hora, required this.intencion, required this.preferencia});
}