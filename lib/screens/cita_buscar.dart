// 📂 lib/screens/cita_buscar.dart
// ✅ CITA BUSCAR — Swipe tipo Tinder (Matchy style) + FIRESTORE REAL
// ✅ Swipe IZQUIERDA = DESCARTAR persistente
// ✅ Swipe DERECHA = CREA CANDIDATO (docId = uid, idempotente)
// ✅ Tap foto candidato => abre CandidatoGaleriaScreen (diseño restaurante)
// ✅ Tap foto lugar => abre LugarGaleriaScreen (diseño restaurante)
// ✅ FIX: corazón NO opaco
// ✅ FIX SWIPE: fling usa DIAGONAL real (no queda esquina)
// ✅ FIX CRÍTICO: Firestore NO bloquea swipe (write en background)
// ✅ NUEVO CLAVE: el usuario NO ve SUS PROPIAS citas (guardia)
// ✅ NUEVO (2026): lógica REAL con genero + preferencias (mutua)
// ✅ NUEVO: si NO hay citas -> mensaje claro + OCULTA botones
// ✅ NUEVO: flecha SIEMPRE vuelve a Panel

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:proyectos_matchy/widgets/matchy_page_layout.dart';

// ✅ Pantallas reales (ya existen en tu proyecto)
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
  // ============================================================
  // SWIPE
  // ============================================================
  static const double decisionThresholdPx = 75.0; // 🔴 CHINCHE SWIPE 1
  static const double rotationDivisor = 14.0; // 🔴 CHINCHE SWIPE 2
  static const double opacityDivisor = 100.0; // 🔴 CHINCHE SWIPE 3

  // 🔴 CHINCHE SWIPE 4 — VELOCIDAD MEDIA (antes 300)
  // Ajuste: más “cine” y menos “teletransportación”.
  static const int flingDurationMs = 380;

  static const int resetDurationMs = 250; // 🔴 CHINCHE SWIPE 5

  // 🔴 CHINCHE SWIPE 6 — qué tan lejos se va el fling (basado en diagonal)
  static const double offscreenDiagMultiplier = 2.2;

  // 🔴 CHINCHE SWIPE 7 — extra por rotación / esquinas
  static const double offscreenExtraPx = 180.0;

  // ============================================================
  // MATCHY STYLE
  // ============================================================
  static const String backgroundAsset = 'assets/images/fondo.jpg'; // 🔴 CHINCHE MATCHY 1
  static const String logoAsset = 'assets/images/logomatchyplano.png'; // 🔴 CHINCHE MATCHY 2
  static const double topSpacing = 35.0; // 🔴 CHINCHE MATCHY 3
  static const double logoHeight = 50.0;
  static const double logoOffsetY = 0.0;
  static const double spaceLogoToScroll = 15.0;

  // ============================================================
  // LAYOUT
  // ============================================================
  static const double screenSideMargin = 14.0; // 🔴 CHINCHE UI 1
  static const double gapLogoToSwipeBlock = 8.0; // 🔴 CHINCHE UI 2
  static const double photoHeightFactorOfScreen = 0.52; // 🔴 CHINCHE UI 3
  static const double photoMinHeight = 380.0; // 🔴 CHINCHE UI 4
  static const double photoMaxHeight = 560.0; // 🔴 CHINCHE UI 5
  static const double infoCardHeight = 165.0; // 🔴 CHINCHE UI 6
  static const double gapPhotoToInfo = 14.0; // 🔴 CHINCHE UI 7
  static const double photoRadius = 28.0; // 🔴 CHINCHE UI 8
  static const double infoRadius = 16.0; // 🔴 CHINCHE UI 9
  static const double shadowOpacity = 0.45; // 🔴 CHINCHE UI 10
  static const double shadowBlur = 12.0;
  static const double shadowOffsetY = 7.0;

  // ============================================================
  // TITULO ABAJO-IZQUIERDA
  // ============================================================
  static const double titleLeft = 24.0; // 🔴 CHINCHE TITLE X
  static const double titleBottom = 16.0; // 🔴 CHINCHE TITLE Y
  static const double titleNameSize = 27.0; // 🔴 CHINCHE TITLE SIZE 1
  static const double titleAgeSize = 27.0; // 🔴 CHINCHE TITLE SIZE 2
  static const double titleMaxWidthFactor = 0.78; // 🔴 CHINCHE TITLE WIDTH
  static const double titleShadowBlur = 10.0; // 🔴 CHINCHE TITLE SHADOW 1
  static const double titleShadowOpacity = 0.70; // 🔴 CHINCHE TITLE SHADOW 2

  // ============================================================
  // DEGRADADO FOTO
  // ============================================================
  static const double photoGradientHeight = 170.0; // 🔴 CHINCHE GRAD 1
  static const double photoGradientBottomOpacity = 0.85; // 🔴 CHINCHE GRAD 2

  // ============================================================
  // BOTONES
  // ============================================================
  static const double actionButtonSize = 76.0; // 🔴 CHINCHE BTN 1
  static const double actionIconSize = 70.0; // 🔴 CHINCHE BTN 2
  static const Color actionCircleColor = Color(0xFF7E79B6); // 🔴 CHINCHE BTN 3
  static const double actionButtonsGap = 74.0; // 🔴 CHINCHE BTN 4
  static const double gapSwipeBlockToButtons = 18.0; // 🔴 CHINCHE BTN 5
  static const double bottomPadding = 14.0; // 🔴 CHINCHE BTN 6
  static const String iconClose = 'assets/images/ic_close_white.png'; // 🔴 CHINCHE BTN 7
  static const String iconFav = 'assets/images/ic_favorite_white.png';

  // ============================================================
  // UNDO (NO SE MUESTRA)
  // ============================================================
  static const bool showUndoButton = false; // 🔴 CHINCHE UNDO 0

  // ============================================================
  // 🔴 CHINCHE STATUS 1 — status publico real en tu DB
  // ============================================================
  static const String publicStatus = 'online';

  // ============================================================
  // Firestore collections/fields
  // ============================================================
  static const String kCitasCol = 'citas';
  static const String kUsersCol = 'users';
  static const String kSubCandidatos = 'candidatos';
  static const String kSubDescartes = 'descartes'; // 🔴 CHINCHE DESC 1

  // 🔴 CHINCHE FIRESTORE 2 — campo ownerUid en la cita
  static const String kOwnerUidField = 'ownerUid';

  // 🔴 CHINCHE FIRESTORE 3 — campo lugar (map) (legacy)
  static const String kLugarField = 'lugar';
  static const String kLugarNombreField = 'nombre';
  static const String kLugarDireccionField = 'direccion';
  static const String kLugarFotoPortadaField = 'fotoPortada';

  // 🔴 CHINCHE FIRESTORE 4 — fecha/hora (strings)
  static const String kFechaField = 'fecha';
  static const String kHoraField = 'hora';

  // 🔴 CHINCHE USERS 1 — campos en users/{uid}
  static const String kUserGeneroField = 'genero';
  static const String kUserPreferenciaCitasField = 'preferenciaCitas';

  // ============================================================
  // Estado swipe
  // ============================================================
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
  // Streams
  // ============================================================
  Stream<DocumentSnapshot<Map<String, dynamic>>> _userDocStream(String uid) {
    return FirebaseFirestore.instance.collection(kUsersCol).doc(uid).snapshots();
  }

  // ✅ IMPORTANTE:
  // - SOLO filtramos por status aquí
  // - NO usamos isNotEqualTo (evita líos de índices/inequality)
  // - La exclusión de “mis propias citas” se hace en app (guardia)
  Stream<QuerySnapshot<Map<String, dynamic>>> _citasPublicasStream() {
    return FirebaseFirestore.instance
        .collection(kCitasCol)
        .where('status', isEqualTo: publicStatus)
        .limit(50) // 🔴 CHINCHE LIMIT 1
        .snapshots();
  }

  // ============================================================
  // Helpers Firestore (writes)
  // ============================================================
  Future<void> _writeDescartado({
    required String citaId,
    required String currentUid,
  }) async {
    await FirebaseFirestore.instance
        .collection(kCitasCol)
        .doc(citaId)
        .collection(kSubDescartes)
        .doc(currentUid)
        .set({
      'uid': currentUid,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _writeCandidato({
    required _CitaCardModel model,
    required String currentUid,
  }) async {
    await FirebaseFirestore.instance
        .collection(kCitasCol)
        .doc(model.citaId)
        .collection(kSubCandidatos)
        .doc(currentUid)
        .set({
      'uid': currentUid,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ============================================================
  // Movement
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

  double _screenDiagonal(Size s) => math.sqrt(s.width * s.width + s.height * s.height);

  Future<void> _flingOut({
    required bool toRight,
    required Size screenSize,
    required _CitaCardModel model,
    required String currentUid,
  }) async {
    if (_topIndex >= _deck.length) return;

    _isAnimating = true;

    // ✅ OFFSCREEN: diagonal real => nunca queda “esquina”
    final diag = _screenDiagonal(screenSize);
    final targetDx =
        (toRight ? 1 : -1) * (diag * offscreenDiagMultiplier + offscreenExtraPx);

    // 1) Animar salida
    await _animateTo(targetDx, const Duration(milliseconds: flingDurationMs));

    // 2) AVANZAR TARJETA INMEDIATO (NO BLOQUEAR UI)
    if (!mounted) return;
    setState(() {
      _topIndex++;
      _dx = 0.0;
    });

    // 3) Escribir Firestore en background (sin bloquear swipe)
    Future<void>(() async {
      try {
        if (toRight) {
          await _writeCandidato(model: model, currentUid: currentUid);
        } else {
          await _writeDescartado(citaId: model.citaId, currentUid: currentUid);
        }
      } catch (e) {
        debugPrint('Firestore write error en swipe: $e');
      }
    });
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_isAnimating) return;
    setState(() => _dx += details.delta.dx);
  }

  Future<void> _handlePanEnd(
      DragEndDetails details, Size screenSize, String currentUid) async {
    if (_isAnimating) return;

    final decisionMade = _dx.abs() >= decisionThresholdPx;
    if (!decisionMade) {
      await _resetCard();
      return;
    }

    final int idx = _topIndex;
    if (idx < 0 || idx >= _deck.length) {
      await _resetCard();
      return;
    }

    final model = _deck[idx];

    if (_dx < 0) {
      await _flingOut(
        toRight: false,
        screenSize: screenSize,
        model: model,
        currentUid: currentUid,
      );
      return;
    }

    await _flingOut(
      toRight: true,
      screenSize: screenSize,
      model: model,
      currentUid: currentUid,
    );
  }

  Future<void> _onNopeTap(Size screenSize, String currentUid) async {
    if (_isAnimating) return;
    if (_topIndex >= _deck.length) return;

    _dx = -decisionThresholdPx;
    final model = _deck[_topIndex];
    await _flingOut(
      toRight: false,
      screenSize: screenSize,
      model: model,
      currentUid: currentUid,
    );
  }

  Future<void> _onLikeTap(Size screenSize, String currentUid) async {
    if (_isAnimating) return;
    if (_topIndex >= _deck.length) return;

    _dx = decisionThresholdPx;
    final model = _deck[_topIndex];
    await _flingOut(
      toRight: true,
      screenSize: screenSize,
      model: model,
      currentUid: currentUid,
    );
  }

  // ============================================================
  // Helpers de formato fecha/hora
  // ============================================================
  String _two(int n) => n.toString().padLeft(2, '0');

  String _formatFecha(DateTime dt) => '${_two(dt.day)}/${_two(dt.month)}/${dt.year}';

  String _formatHora(DateTime dt) {
    int h = dt.hour;
    final ampm = h >= 12 ? 'PM' : 'AM';
    h = h % 12;
    if (h == 0) h = 12;
    return '$h:${_two(dt.minute)} $ampm';
  }

  // ============================================================
  // Normalizaciones (preferencia / genero)
  // ============================================================
  String _normalizePref(String v) {
    final t = v.trim().toLowerCase();
    if (t.contains('hombre')) return 'Hombres';
    if (t.contains('mujer')) return 'Mujeres';
    if (t.contains('amb')) return 'Ambos';
    return 'Ambos';
  }

  // users/{uid}.genero viene como: "hombre" | "mujer" | "otro" | "prefiero no decirlo"
  String _normalizeGenero(String v) {
    final t = v.trim().toLowerCase();
    if (t.contains('hombre')) return 'Hombres';
    if (t.contains('mujer')) return 'Mujeres';
    if (t.contains('otro')) return 'Otro';
    if (t.contains('prefiero')) return 'NoDecir';
    return 'NoDecir';
  }

  // ============================================================
  // ✅ Reglas correctas de visibilidad (mutua)
  // ============================================================
  bool _citaAceptaGeneroUsuario({
    required String preferenciaCita,
    required String generoUsuarioNorm, // 'Hombres' | 'Mujeres' | 'Otro' | 'NoDecir'
  }) {
    final pref = _normalizePref(preferenciaCita);

    // Si la cita acepta Ambos, entra cualquiera.
    if (pref == 'Ambos') return true;

    // Si el usuario no declara genero (o es "Otro"), solo entra si la cita acepta Ambos.
    if (generoUsuarioNorm != 'Hombres' && generoUsuarioNorm != 'Mujeres') {
      return false;
    }

    return pref == generoUsuarioNorm;
  }

  bool _usuarioAceptaGeneroDelDueno({
    required String prefUsuarioGlobal,
    required String generoDuenoNorm, // 'Hombres' | 'Mujeres' | 'Otro' | 'NoDecir'
  }) {
    final pref = _normalizePref(prefUsuarioGlobal);

    if (pref == 'Ambos') return true;

    // Si el dueño no declara genero (o es "Otro"), solo entra si el usuario acepta Ambos.
    if (generoDuenoNorm != 'Hombres' && generoDuenoNorm != 'Mujeres') {
      return false;
    }

    return pref == generoDuenoNorm;
  }

  // ============================================================
  // Deck builder
  // ============================================================
  List<String> _safeStringList(dynamic v) {
    if (v is List) {
      return v.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
    }
    return <String>[];
  }

  Map<String, dynamic> _safeMap(dynamic v) {
    if (v is Map) return Map<String, dynamic>.from(v);
    return <String, dynamic>{};
  }

  String _s(dynamic v) => v is String ? v : (v?.toString() ?? '');

  // 🔴 CHINCHE CREADOR 1 — lectura REAL desde mapa "creador"
  Map<String, dynamic> _readCreadorMap(Map<String, dynamic> data) {
    final m = _safeMap(data['creador']);
    return m;
  }

  List<_CitaCardModel> _mapDocsToDeck({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    required String currentUid,
  }) {
    final out = <_CitaCardModel>[];

    for (final d in docs) {
      final data = d.data();

      final ownerUid = _s(data[kOwnerUidField]).trim();

      // ✅ Guardia: NO mostrar propias
      if (ownerUid.isNotEmpty && ownerUid == currentUid) continue;

      // ✅ Lugar (puede venir en map "lugar" o plano)
      final lugar = _safeMap(data[kLugarField]);

      final String nombreLugar = _s(lugar[kLugarNombreField]).trim().isNotEmpty
          ? _s(lugar[kLugarNombreField]).trim()
          : _s(data['nombre']).trim().isNotEmpty
          ? _s(data['nombre']).trim()
          : _s(data['nombreLugar']).trim().isNotEmpty
          ? _s(data['nombreLugar']).trim()
          : 'Lugar';

      final String direccionLugar = _s(lugar[kLugarDireccionField]).trim().isNotEmpty
          ? _s(lugar[kLugarDireccionField]).trim()
          : _s(data['direccion']).trim().isNotEmpty
          ? _s(data['direccion']).trim()
          : _s(data['direccionLugar']).trim().isNotEmpty
          ? _s(data['direccionLugar']).trim()
          : 'Sin dirección';

      // ✅ Preferencia de ESTA cita (a quién acepta)
      final String preferenciaCita = _s(data['preferencia']).trim().isEmpty
          ? 'Ambos'
          : _s(data['preferencia']).trim();

      final String fotoPortada = _s(lugar[kLugarFotoPortadaField]).trim().isNotEmpty
          ? _s(lugar[kLugarFotoPortadaField]).trim()
          : _s(data['fotoPortada']).trim().isNotEmpty
          ? _s(data['fotoPortada']).trim()
          : _s(data['fotoLugar']).trim().isNotEmpty
          ? _s(data['fotoLugar']).trim()
          : _s(data['fotoLugarAsset']).trim();

      final placePhotos = <String>[];
      if (fotoPortada.isNotEmpty) placePhotos.add(fotoPortada);

      final fotos = _safeStringList(data['fotos']);
      for (final f in fotos) {
        if (!placePhotos.contains(f)) placePhotos.add(f);
      }
      if (placePhotos.isEmpty) placePhotos.add('assets/images/perfil1.jpg');

      String fecha = _s(data[kFechaField]).trim();
      String hora = _s(data[kHoraField]).trim();

      // Si existe scheduledAt Timestamp, prioriza
      final sched = data['scheduledAt'];
      if (sched is Timestamp) {
        final dt = sched.toDate();
        fecha = _formatFecha(dt);
        hora = _formatHora(dt);
      } else {
        if (fecha.isEmpty) fecha = _s(data['fecha']).trim();
        if (hora.isEmpty) hora = _s(data['hora']).trim();
      }

      final String intencion = _s(data['intencion']).trim().isEmpty
          ? 'Amistad'
          : _s(data['intencion']).trim();

      // 🔴 CHINCHE CREADOR 2 — prioridad: mapa creador.{nombre,edad,foto,uid}
      final creador = _readCreadorMap(data);
      final creadorNombre = _s(creador['nombre']).trim();
      final creadorEdadRaw = creador['edad'];
      final creadorFoto = _s(creador['foto']).trim();
      final creadorUid = _s(creador['uid']).trim();

      // ✅ Fallbacks por si hay citas viejas “planas”
      final legacyNombre = _s(data['creadorNombre']).trim();
      final legacyEdadRaw = data['creadorEdad'];
      final legacyFoto = _s(data['creadorFoto']).trim();

      final String finalNombre = creadorNombre.isNotEmpty
          ? creadorNombre
          : (legacyNombre.isNotEmpty ? legacyNombre : 'Usuario');

      final int finalEdad = (creadorEdadRaw is int)
          ? creadorEdadRaw
          : int.tryParse(creadorEdadRaw?.toString() ?? '') ??
          ((legacyEdadRaw is int)
              ? legacyEdadRaw
              : int.tryParse(legacyEdadRaw?.toString() ?? '') ?? 0);

      final String finalFoto = creadorFoto.isNotEmpty ? creadorFoto : legacyFoto;

      // ✅ ownerUid real: si viene vacío, usa creador.uid
      final String finalOwnerUid = ownerUid.isNotEmpty
          ? ownerUid
          : (creadorUid.isNotEmpty ? creadorUid : 'unknown'); // 🔴 CHINCHE SAFE 1

      out.add(
        _CitaCardModel(
          citaId: d.id,
          ownerUid: finalOwnerUid,
          creatorName: finalNombre,
          creatorAge: finalEdad,
          creatorPhoto: finalFoto,
          placePhotos: placePhotos,
          placeName: nombreLugar,
          placeAddress: direccionLugar,
          fecha: fecha.isEmpty ? 'Fecha pendiente' : fecha,
          hora: hora.isEmpty ? 'Hora pendiente' : hora,
          intencion: intencion,
          preferencia: preferenciaCita,
        ),
      );
    }

    return out;
  }

  Future<List<_CitaCardModel>> _filterOutDescartadas({
    required List<_CitaCardModel> input,
    required String currentUid,
  }) async {
    if (input.isEmpty) return input;

    final out = <_CitaCardModel>[];
    for (final m in input) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection(kCitasCol)
            .doc(m.citaId)
            .collection(kSubDescartes)
            .doc(currentUid)
            .get();
        if (!doc.exists) out.add(m);
      } catch (_) {
        out.add(m);
      }
    }
    return out;
  }

  // ✅ NUEVO: filtro por compatibilidad MUTUA usando genero (users) + preferencia global (users) + preferencia cita (citas)
  Future<List<_CitaCardModel>> _filterByGeneroMutuo({
    required List<_CitaCardModel> input,
    required String currentUid,
    required String generoUsuarioNorm,
    required String prefUsuarioGlobal,
  }) async {
    if (input.isEmpty) return input;

    // 1) Obtener generos de dueños (unique)
    final ownerUids = input
        .map((e) => e.ownerUid.trim())
        .where((e) => e.isNotEmpty && e != 'unknown' && e != currentUid)
        .toSet()
        .toList();

    final Map<String, String> generoPorUid = {};

    await Future.wait(ownerUids.map((ouid) async {
      try {
        final snap = await FirebaseFirestore.instance.collection(kUsersCol).doc(ouid).get();
        final data = snap.data() ?? {};
        final generoRaw = (data[kUserGeneroField] ?? '').toString();
        generoPorUid[ouid] = _normalizeGenero(generoRaw);
      } catch (_) {
        generoPorUid[ouid] = 'NoDecir';
      }
    }));

    // 2) Aplicar regla mutua
    final out = <_CitaCardModel>[];

    for (final m in input) {
      final generoDueno = generoPorUid[m.ownerUid] ?? 'NoDecir';

      final ok1 = _citaAceptaGeneroUsuario(
        preferenciaCita: m.preferencia,
        generoUsuarioNorm: generoUsuarioNorm,
      );

      final ok2 = _usuarioAceptaGeneroDelDueno(
        prefUsuarioGlobal: prefUsuarioGlobal,
        generoDuenoNorm: generoDueno,
      );

      if (ok1 && ok2) out.add(m);
    }

    return out;
  }

  Future<List<_CitaCardModel>> _applyAllFilters({
    required List<_CitaCardModel> rawDeck,
    required String currentUid,
    required String generoUsuarioNorm,
    required String prefUsuarioGlobal,
  }) async {
    final step1 = await _filterOutDescartadas(input: rawDeck, currentUid: currentUid);
    final step2 = await _filterByGeneroMutuo(
      input: step1,
      currentUid: currentUid,
      generoUsuarioNorm: generoUsuarioNorm,
      prefUsuarioGlobal: prefUsuarioGlobal,
    );
    return step2;
  }

  // ============================================================
  // Back: SIEMPRE vuelve a Panel
  // ============================================================
  void _backToPanel() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
      return;
    }
    nav.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const PanelScreen()),
          (route) => false,
    );
  }

  // ============================================================
  // UI
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Debes iniciar sesión para buscar citas.',
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

          // 🔙 Flecha garantizada a Panel
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

  Widget _buildBody(String uid) {
    final Size screen = MediaQuery.sizeOf(context);
    final double blockWidth = screen.width - (screenSideMargin * 2);

    final double rawPhotoHeight = screen.height * photoHeightFactorOfScreen;
    final double photoHeight = rawPhotoHeight.clamp(photoMinHeight, photoMaxHeight);

    final double swipeBlockHeight = photoHeight + gapPhotoToInfo + infoCardHeight;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _userDocStream(uid),
      builder: (context, userSnap) {
        final userData = userSnap.data?.data() ?? {};

        final prefUsuarioGlobal = _normalizePref(
          (userData[kUserPreferenciaCitasField] ?? 'Ambos').toString(),
        );

        final generoUsuarioNorm = _normalizeGenero(
          (userData[kUserGeneroField] ?? 'Prefiero no decirlo').toString(),
        );

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _citasPublicasStream(),
          builder: (context, citasSnap) {
            if (citasSnap.hasError) {
              return Center(
                child: Text(
                  'Error cargando citas: ${citasSnap.error}',
                  style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              );
            }

            if (!citasSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = citasSnap.data!.docs;

            final rawDeck = _mapDocsToDeck(
              docs: docs,
              currentUid: uid,
            );

            return FutureBuilder<List<_CitaCardModel>>(
              future: _applyAllFilters(
                rawDeck: rawDeck,
                currentUid: uid,
                generoUsuarioNorm: generoUsuarioNorm,
                prefUsuarioGlobal: prefUsuarioGlobal,
              ),
              builder: (context, filteredSnap) {
                if (filteredSnap.connectionState == ConnectionState.waiting && _deck.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                final newDeck = filteredSnap.data ?? rawDeck;

                final bool needsReset = _deck.length != newDeck.length ||
                    (_deck.isNotEmpty &&
                        newDeck.isNotEmpty &&
                        _deck.first.citaId != newDeck.first.citaId);

                if (needsReset) {
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
                  if (_topIndex > _deck.length) _topIndex = _deck.length;
                }

                final noMore = _deck.isEmpty || _topIndex >= _deck.length;

                return Center(
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
                                    onCreatorPhotoTap: () {
                                      final model = _deck[_topIndex + 1];
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => CandidatoGaleriaScreen(
                                            userUid: model.ownerUid,
                                            fallbackSinglePhoto: model.creatorPhoto,
                                            placeName: model.placeName,
                                            placeAddress: model.placeAddress,
                                            fecha: model.fecha,
                                            hora: model.hora,
                                            preferencia: model.preferencia,
                                            intencion: model.intencion,
                                          ),
                                        ),
                                      );
                                    },
                                    onPlacePhotoTap: () {
                                      final model = _deck[_topIndex + 1];
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => LugarGaleriaScreen(
                                            placePhotos: model.placePhotos,
                                            placeName: model.placeName,
                                            placeAddress: model.placeAddress,
                                            fecha: model.fecha,
                                            hora: model.hora,
                                            preferencia: model.preferencia,
                                            intencion: model.intencion,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              if (!noMore)
                                Positioned.fill(
                                  child: GestureDetector(
                                    onPanUpdate: _handlePanUpdate,
                                    onPanEnd: (d) => _handlePanEnd(d, screen, uid),
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
                                          onCreatorPhotoTap: () {
                                            final model = _deck[_topIndex];
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) => CandidatoGaleriaScreen(
                                                  userUid: model.ownerUid,
                                                  fallbackSinglePhoto: model.creatorPhoto,
                                                  placeName: model.placeName,
                                                  placeAddress: model.placeAddress,
                                                  fecha: model.fecha,
                                                  hora: model.hora,
                                                  preferencia: model.preferencia,
                                                  intencion: model.intencion,
                                                ),
                                              ),
                                            );
                                          },
                                          onPlacePhotoTap: () {
                                            final model = _deck[_topIndex];
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) => LugarGaleriaScreen(
                                                  placePhotos: model.placePhotos,
                                                  placeName: model.placeName,
                                                  placeAddress: model.placeAddress,
                                                  fecha: model.fecha,
                                                  hora: model.hora,
                                                  preferencia: model.preferencia,
                                                  intencion: model.intencion,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                              // ✅ EMPTY STATE: SOLO MENSAJE (sin preferencia/género)
                              if (noMore)
                                Positioned.fill(
                                  child: Center(
                                    child: Container(
                                      width: blockWidth * 0.92,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.38),
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(color: Colors.white24, width: 1),
                                      ),
                                      child: const Text(
                                        // 🔴 CHINCHE EMPTY 1 — texto final limpio
                                        'No hay citas disponibles ahora.\n\n'
                                            'Vuelve a intentarlo más tarde.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          height: 1.25,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // ✅ Si no hay citas, NO mostramos botones X / ❤️
                        if (!noMore) ...[
                          SizedBox(height: gapSwipeBlockToButtons),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _AssetCircleButton(
                                asset: iconClose,
                                size: actionButtonSize,
                                iconSize: actionIconSize,
                                backgroundColor: actionCircleColor,
                                onTap: () => _onNopeTap(screen, uid),
                              ),
                              SizedBox(width: actionButtonsGap),
                              _AssetCircleButton(
                                asset: iconFav,
                                size: actionButtonSize,
                                iconSize: actionIconSize,
                                backgroundColor: actionCircleColor,
                                onTap: () => _onLikeTap(screen, uid),
                              ),
                            ],
                          ),
                          SizedBox(height: bottomPadding),
                        ] else ...[
                          const SizedBox(height: 18),
                        ],
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

// ================================================================
// SWIPE BUNDLE (FOTO + INFO)
// ================================================================
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

  bool _isNetwork(String v) => v.startsWith('http://') || v.startsWith('https://');

  Widget _buildCreatorPhoto() {
    final src = model.creatorPhoto.trim();
    if (src.isEmpty) {
      return Image.asset(
        model.creatorPhotoFallbackAsset,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
      );
    }
    if (_isNetwork(src)) {
      return Image.network(
        src,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        errorBuilder: (_, __, ___) =>
            Image.asset(model.creatorPhotoFallbackAsset, fit: BoxFit.cover),
      );
    }
    return Image.asset(
      src,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      errorBuilder: (_, __, ___) =>
          Image.asset(model.creatorPhotoFallbackAsset, fit: BoxFit.cover),
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
              borderRadius: BorderRadius.circular(_CitaBuscarScreenState.photoRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_CitaBuscarScreenState.shadowOpacity),
                  blurRadius: _CitaBuscarScreenState.shadowBlur,
                  offset: Offset(0, _CitaBuscarScreenState.shadowOffsetY),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                GestureDetector(onTap: onCreatorPhotoTap, child: _buildCreatorPhoto()),
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
                            Colors.black.withOpacity(_CitaBuscarScreenState.photoGradientBottomOpacity),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: _CitaBuscarScreenState.titleLeft,
                  bottom: _CitaBuscarScreenState.titleBottom,
                  child: IgnorePointer(
                    ignoring: true,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: width * _CitaBuscarScreenState.titleMaxWidthFactor,
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
                                fontSize: _CitaBuscarScreenState.titleNameSize,
                                fontWeight: FontWeight.w900,
                                shadows: [
                                  Shadow(
                                    blurRadius: _CitaBuscarScreenState.titleShadowBlur,
                                    color: Colors.black.withOpacity(_CitaBuscarScreenState.titleShadowOpacity),
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            TextSpan(
                              text: model.creatorAge > 0 ? ', ${model.creatorAge}' : '',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: _CitaBuscarScreenState.titleAgeSize,
                                fontWeight: FontWeight.w900,
                                shadows: [
                                  Shadow(
                                    blurRadius: _CitaBuscarScreenState.titleShadowBlur,
                                    color: Colors.black.withOpacity(_CitaBuscarScreenState.titleShadowOpacity),
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

                if (_CitaBuscarScreenState.showUndoButton) const SizedBox.shrink(),

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
            model: model,
            onPlaceTap: onPlacePhotoTap,
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

  const _CitaInfoCard({
    required this.width,
    required this.height,
    required this.model,
    required this.onPlaceTap,
  });

  bool _isNetwork(String v) => v.startsWith('http://') || v.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    final src = (model.placePhotos.isNotEmpty ? model.placePhotos.first : '').trim();

    Widget bg;
    if (src.isEmpty) {
      bg = Image.asset('assets/images/perfil1.jpg', fit: BoxFit.cover);
    } else if (_isNetwork(src)) {
      bg = Image.network(
        src,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset('assets/images/perfil1.jpg', fit: BoxFit.cover),
      );
    } else {
      bg = Image.asset(
        src,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset('assets/images/perfil1.jpg', fit: BoxFit.cover),
      );
    }

    return GestureDetector(
      onTap: onPlaceTap,
      child: Container(
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
            bg,
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
                          model.fecha,
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
                        model.hora,
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
                    'Preferencia: ${model.preferencia}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.0,
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
                      fontSize: 13.0,
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
                    model.placeName,
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
                    model.placeAddress,
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
  final String citaId;
  final String ownerUid;

  final String creatorName;
  final int creatorAge;
  final String creatorPhoto;
  final String creatorPhotoFallbackAsset;

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
    this.creatorPhotoFallbackAsset = 'assets/images/perfil1.jpg',
    required this.placePhotos,
    required this.placeName,
    required this.placeAddress,
    required this.fecha,
    required this.hora,
    required this.intencion,
    required this.preferencia,
  });
}
