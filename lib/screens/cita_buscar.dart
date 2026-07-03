// 📂 lib/screens/cita_buscar.dart
// ✅ PANTALLA RADAR TINDER-STYLE (BLINDADA CON CACHÉ Y ANTI-FANTASMAS)
// 🔥 INYECCIÓN DE ÉLITE: Check Azul visible en las tarjetas de perfil.
// 🛡️ RADAR INVISIBLE: Filtro omnidireccional en tiempo real (<3h) sin bloquear animaciones.
// 🧨 ESCUDO WIPE-OUT INYECTADO: Ignora y oculta citas publicadas por usuarios bloqueados.
// 🕐 FIX MARGEN MÍNIMO 12H: solo se muestran citas con AL MENOS 12 horas de margen antes de
//    que ocurran (12h00m exactas cuentan; 11h59m o menos, se ocultan). Es el tiempo mínimo que
//    necesita el dueño para revisar candidatos y elegir uno antes de la cita — complementa la
//    regla ya existente en creacita_screen.dart (que solo valida al MOMENTO de crear la cita,
//    no mientras sigue publicada). Sin límite superior. Citas sin fecha parseable se excluyen
//    (no se puede garantizar que cumplan la regla).

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:proyectos_matchy/widgets/matchy_page_layout.dart';
import 'package:proyectos_matchy/screens/panel_screen.dart';
import 'package:proyectos_matchy/screens/perfil_usuariox_screen.dart';
import 'package:proyectos_matchy/screens/lugar_plantilla_sin_boton_screen.dart';
import 'package:proyectos_matchy/models/lugar_data.dart';
import 'package:proyectos_matchy/widgets/publicidad_swap_card.dart';

class CitaBuscarScreen extends StatefulWidget {
  static const String routeName = 'cita_buscar';
  const CitaBuscarScreen({super.key});

  @override
  State<CitaBuscarScreen> createState() => _CitaBuscarScreenState();
}

class _CitaBuscarScreenState extends State<CitaBuscarScreen> with SingleTickerProviderStateMixin {
  static const double kCardTopMargin      = 30.0;
  static const double kCardWidthFactor    = 0.93;
  static const double kCardHeightFactor   = 0.81;
  static const double kCardBorderRadius   = 24.0;
  static const Color  kCardBackground     = Color(0xFF1A1A1A);

  static const double kInfoHeight    = 80.0;
  static const double kBarHeight     = 55.0;
  static const double kButtonsHeight = 60.0;
  static const double kGapSmall      = 5.0;
  static const double kGapTiny       = 1.0;

  static const double decisionThresholdPx = 75.0;
  static const double rotationDivisor = 14.0;
  static const double opacityDivisor = 100.0;
  static const int flingDurationMs = 340;
  static const int resetDurationMs = 240;
  static const double offscreenDiagMultiplier = 2.2;
  static const double offscreenExtraPx = 180.0;

  static const String backgroundAsset = 'assets/images/fondo.jpg';
  static const String logoAsset = 'assets/images/logomatchyplano.png';
  static const double topSpacing = 35.0;
  static const double logoHeight = 40.0;
  static const double logoOffsetY = 0.0;
  static const double spaceLogoToScroll = 10.0;

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

  // 🕐 NEW: margen mínimo requerido entre "ahora" y la hora de la cita para que se muestre
  static const Duration kMargenMinimoAntesDeCita = Duration(hours: 12);

  List<_CitaCardModel> _deck = [];
  int _topIndex = 0;
  double _dx = 0.0;
  bool _isAnimating = false;

  late final AnimationController _controller;
  Animation<double>? _dxAnim;
  final Map<String, Map<String, dynamic>> _userCache = {};

  DocumentSnapshot? _lastDoc;
  bool _isLoading = true;
  bool _hasMore = true;
  String _uid = '';
  String _prefGlobal = '';
  String _generoUser = '';
  String _userPais = 'Colombia';
  String _userCiudad = 'Cali';

  // 🔥 RADAR INVISIBLE: Variables
  StreamSubscription<QuerySnapshot>? _agendaSub;
  List<DateTime> _misHorariosOcupados = [];
  List<String> _misBloqueados = []; // 🧨 WIPE-OUT: Lista Negra en Memoria

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es_ES', null);
    _controller = AnimationController(vsync: this)
      ..addListener(() => setState(() => _dx = _dxAnim?.value ?? _dx))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _dxAnim = null;
          _isAnimating = false;
        }
      });

    _initMatchySpeed();
  }

  @override
  void dispose() {
    _agendaSub?.cancel(); // 🔥 Apagamos el Radar al salir
    _controller.dispose();
    super.dispose();
  }

  void _mostrarBurbuja(String mensaje, Color color, IconData icono) {
    if (!mounted) return;
    final overlayState = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 20, left: 25, right: 25),
            child: Material(
              color: Colors.transparent,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 500),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E2C).withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.7), width: 2),
                    boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 5))],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
                        child: Icon(icono, color: color, size: 28),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                          child: Text(
                            mensaje,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Poppins'),
                          )
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlayState.insert(entry);
    Future.delayed(const Duration(seconds: 4), () {
      if (entry.mounted) entry.remove();
    });
  }

  // 🔥 RADAR INVISIBLE: Conexión en tiempo real
  void _initRadarRealTime() {
    final db = FirebaseFirestore.instance;
    _agendaSub = db.collection(kCitasCol)
        .where(Filter.or(Filter('ownerUid', isEqualTo: _uid), Filter('matchyUid', isEqualTo: _uid)))
        .snapshots().listen((snap) {
      final List<DateTime> nuevosHorarios = [];
      for (var doc in snap.docs) {
        final data = doc.data();
        final status = data['status'] ?? '';
        if (status != 'finished' && status != 'cancelled') {
          DateTime? t;
          if (data['scheduledAt'] != null) {
            t = (data['scheduledAt'] as Timestamp).toDate();
          } else {
            t = _parseDateManual(data['fecha']?.toString() ?? '', data['hora']?.toString() ?? '');
          }
          if (t != null) nuevosHorarios.add(t);
        }
      }
      _misHorariosOcupados = nuevosHorarios;

      if (_deck.isNotEmpty && mounted) {
        final mazoLimpio = _deck.where((card) {
          if (card.isAd || card.scheduledAt == null) return true;
          for (var ocupado in _misHorariosOcupados) {
            if (card.scheduledAt!.difference(ocupado).inMinutes.abs() < 180) return false;
          }
          return true;
        }).toList();
        if (mazoLimpio.length != _deck.length) setState(() => _deck = mazoLimpio);
      }
    });
  }

  DateTime? _parseDateManual(String fTexto, String hTexto) {
    try {
      final parts = fTexto.trim().split(RegExp(r'[/ -]'));
      if (parts.length >= 3) {
        int d = int.parse(parts[0]), m = int.parse(parts[1]), y = int.parse(parts[2]);
        String rawHora = hTexto.toUpperCase().replaceAll('.', '').trim();
        bool esPM = rawHora.contains("PM");
        final tP = rawHora.replaceAll(RegExp(r'[^0-9:]'), '').split(':');
        if (tP.isNotEmpty && tP[0].isNotEmpty) {
          int hh = int.parse(tP[0]);
          int mm = tP.length > 1 ? int.parse(tP[1]) : 0;
          if (esPM && hh != 12) hh += 12; else if (!esPM && hh == 12) hh = 0;
          return DateTime(y, m, d, hh, mm);
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> _initMatchySpeed() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _uid = user.uid;

    try {
      // 🧨 WIPE-OUT PROTOCOL: Cargar lista de bloqueados en segundo plano
      final blockSnap = await FirebaseFirestore.instance.collection(kUsersCol).doc(_uid).collection('blocked_users').get();
      _misBloqueados = blockSnap.docs.map((doc) => doc.id).toList();

      final snap = await FirebaseFirestore.instance.collection(kUsersCol).doc(_uid).get();
      final udata = snap.data() ?? {};
      _prefGlobal = _normPref((udata[kUserPreferenciaCitasField] ?? 'Ambos').toString());
      _generoUser = _normGenero((udata[kUserGeneroField] ?? 'Prefiero no decirlo').toString());
      _userPais = (udata['pais'] ?? 'Colombia').toString();
      _userCiudad = (udata['ciudad'] ?? 'Cali').toString();
    } catch (_) {
      _prefGlobal = 'Ambos';
      _generoUser = 'NoDecir';
    }

    _initRadarRealTime(); // 🔥 Enciende el radar invisible
    await _fetchCitasBatch();
  }

  Future<void> _inyectarAdSiAplica() async {
    if (_deck.isEmpty || _topIndex >= _deck.length) return;

    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    try {
      final snap = await FirebaseFirestore.instance.collection('publicidad_swap')
          .where('activo', isEqualTo: true)
          .where('pais', isEqualTo: _userPais)
          .where('ciudad', isEqualTo: _userCiudad)
          .limit(20)
          .get();

      if (snap.docs.isEmpty) return;

      List<QueryDocumentSnapshot> anunciosDisponibles = [];
      for (var doc in snap.docs) {
        final adId = doc.id;
        final lastSeenDate = prefs.getString('seen_ad_${adId}_$_uid');
        if (lastSeenDate != today) {
          anunciosDisponibles.add(doc);
        }
      }

      if (anunciosDisponibles.isEmpty) return;

      anunciosDisponibles.shuffle();

      setState(() {
        int remainingCards = _deck.length - _topIndex;
        int adsNeeded = (remainingCards / 5).floor();

        if (adsNeeded == 0 && !_deck.any((card) => card.isAd)) {
          adsNeeded = 1;
        }

        int adsInjected = 0;
        for (int i = 0; i < adsNeeded && i < anunciosDisponibles.length; i++) {
          final adData = anunciosDisponibles[i].data() as Map<String, dynamic>;
          final adUrl = adData['foto']?.toString() ?? '';
          final adId = anunciosDisponibles[i].id;

          if (adUrl.isNotEmpty) {
            final adCard = _CitaCardModel.ad(adUrl, adId);
            int insertIndex = _topIndex + 4 + (adsInjected * 5);
            if (insertIndex < _deck.length) {
              _deck.insert(insertIndex, adCard);
            } else {
              _deck.add(adCard);
            }
            adsInjected++;
            precacheImage(CachedNetworkImageProvider(adUrl), context).catchError((_) {});
          }
        }
      });
    } catch (e) {
      debugPrint("🎯 [ADS] Error crítico: $e");
    }
  }

  Future<void> _fetchCitasBatch() async {
    if (!_hasMore || !mounted) return;
    setState(() => _isLoading = true);

    try {
      Query q = FirebaseFirestore.instance
          .collection(kCitasCol)
          .where('status', isEqualTo: publicStatus)
          .limit(15);

      if (_lastDoc != null) {
        q = q.startAfterDocument(_lastDoc!);
      }

      final snap = await q.get();

      if (snap.docs.isEmpty) {
        if (mounted) setState(() { _hasMore = false; _isLoading = false; });
        return;
      }

      _lastDoc = snap.docs.last;

      final rawCards = await _mapDocsToDeck(docs: snap.docs as List<QueryDocumentSnapshot<Map<String, dynamic>>>, uid: _uid);
      final validCards = await _applyFilters(raw: rawCards, uid: _uid, generoUser: _generoUser, prefGlobal: _prefGlobal);

      if (!mounted) return;

      setState(() {
        _deck.addAll(validCards);
        _isLoading = false;
      });

      _precacheDeckImages(validCards);

      if (validCards.isNotEmpty) {
        _inyectarAdSiAplica();
      } else if (_hasMore) {
        _fetchCitasBatch();
      }

    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _precacheDeckImages(List<_CitaCardModel> newCards) {
    for (var card in newCards) {
      if (card.isAd) continue;
      if (card.creatorPhoto.startsWith('http')) {
        precacheImage(CachedNetworkImageProvider(card.creatorPhoto), context).catchError((_) {});
      }
      if (card.placePhotos.isNotEmpty && card.placePhotos.first.startsWith('http')) {
        precacheImage(CachedNetworkImageProvider(card.placePhotos.first), context).catchError((_) {});
      }
    }
  }

  double get _rotationDeg => _dx / rotationDivisor;
  double get _likeOpacityValue => _dx > 0 ? (_dx.abs() / opacityDivisor).clamp(0.0, 1.0) : 0.0;
  double get _nopeOpacityValue => _dx < 0 ? (_dx.abs() / opacityDivisor).clamp(0.0, 1.0) : 0.0;

  Future<void> _animateTo(double target, Duration dur) async {
    _controller.stop();
    _controller.duration = dur;
    _dxAnim = Tween<double>(begin: _dx, end: target).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    await _controller.forward(from: 0.0);
  }

  Future<void> _resetCard() async {
    _isAnimating = true;
    await _animateTo(0.0, const Duration(milliseconds: resetDurationMs));
  }

  double _screenDiag(Size s) => math.sqrt(s.width * s.width + s.height * s.height);

  Future<void> _flingOut({required bool right, required Size size, required _CitaCardModel model, required String uid, required int durationMs}) async {
    if (_topIndex >= _deck.length) return;
    _isAnimating = true;
    final diag = _screenDiag(size);
    final target = (right ? 1 : -1) * (diag * offscreenDiagMultiplier + offscreenExtraPx);
    await _animateTo(target, Duration(milliseconds: durationMs));
    if (!mounted) return;

    setState(() { _topIndex++; _dx = 0.0; });

    if (model.isAd) {
      final prefs = await SharedPreferences.getInstance();
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await prefs.setString('seen_ad_${model.citaId}_$_uid', today);
      return;
    }

    if (_deck.length - _topIndex <= 3 && !_isLoading && _hasMore) {
      _fetchCitasBatch();
    }

    Future(() async {
      try {
        if (right) { await _writeCandidato(model: model, uid: uid); } else { await _writeDescartado(citaId: model.citaId, uid: uid); }
      } catch (_) {}
    });
  }

  void _onPanUpdate(DragUpdateDetails d) { if (_isAnimating) return; setState(() => _dx += d.delta.dx); }

  // 🔥 GESTO LIBERADO: Vuela directo a la derecha
  Future<void> _onPanEnd(DragEndDetails d, Size size, String uid) async {
    if (_isAnimating) return;
    if (_dx.abs() < decisionThresholdPx) { await _resetCard(); return; }
    if (_topIndex >= _deck.length) return;
    final model = _deck[_topIndex];

    await _flingOut(right: _dx > 0, size: size, model: model, uid: uid, durationMs: flingDurationMs);
  }

  Future<void> _onNope(Size size, String uid) async {
    if (_isAnimating || _topIndex >= _deck.length) return;
    _isAnimating = true;
    final isAd = _deck[_topIndex].isAd;
    await _animateTo(isAd ? -40 : -decisionThresholdPx - 60, const Duration(milliseconds: 300));
    await _flingOut(right: false, size: size, model: _deck[_topIndex], uid: uid, durationMs: 450);
  }

  // 🔥 BOTÓN LIBERADO: Vuela directo a la derecha
  Future<void> _onLike(Size size, String uid) async {
    if (_isAnimating || _topIndex >= _deck.length) return;
    _isAnimating = true;
    final model = _deck[_topIndex];
    await _animateTo(model.isAd ? 40 : decisionThresholdPx + 60, const Duration(milliseconds: 300));
    await _flingOut(right: true, size: size, model: model, uid: uid, durationMs: 450);
  }

  Future<void> _writeDescartado({required String citaId, required String uid}) async {
    await FirebaseFirestore.instance.collection(kCitasCol).doc(citaId).collection(kSubDescartes).doc(uid).set({'uid': uid, 'createdAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
  }

  Future<void> _writeCandidato({required _CitaCardModel model, required String uid}) async {
    String nombre = ''; int edad = 0; String foto = '';
    try {
      final mySnap = await FirebaseFirestore.instance.collection(kUsersCol).doc(uid).get();
      final d = mySnap.data() ?? {};
      nombre = _pickNombreFromUserDoc(d); edad = _pickEdadFromUserDoc(d); foto = _pickFotoFromUserDoc(d);
    } catch (_) {}

    await FirebaseFirestore.instance.collection(kCitasCol).doc(model.citaId).collection(kSubCandidatos).doc(uid).set({
      'uid': uid, 'createdAt': FieldValue.serverTimestamp(), 'nombre': nombre, 'edad': edad, 'foto': foto, 'citaId': model.citaId, 'ownerUid': model.ownerUid,
    }, SetOptions(merge: true));

    if (model.ownerUid.isNotEmpty && model.ownerUid != 'unknown') {
      await FirebaseFirestore.instance
          .collection(kUsersCol)
          .doc(model.ownerUid)
          .collection('notifications')
          .add({
        'type': 'golden_ticket',
        'title': '¡NUEVO CANDIDATO!',
        'body': '$nombre está interesada en ir contigo a tu cita en ${model.placeName}',
        'citaId': model.citaId,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  String _s(dynamic v) => v is String ? v : (v?.toString() ?? '');
  String _two(int n) => n.toString().padLeft(2, '0');
  String _fmtFechaLarga(DateTime dt) { try { final f = DateFormat("EEEE d 'de' MMMM", 'es_ES'); String s = f.format(dt); return s.replaceFirst(s[0], s[0].toUpperCase()); } catch (_) { return "${dt.day}/${dt.month}"; } }
  String _fmtHora24(DateTime dt) { try { return DateFormat('h:mm a').format(dt); } catch (_) { return "${dt.hour}:${_two(dt.minute)}"; } }
  List<String> _safeList(dynamic v) => v is List ? v.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList() : <String>[];
  Map<String, dynamic> _safeMap(dynamic v) => v is Map ? Map<String, dynamic>.from(v) : {};
  String _normPref(String v) { final t = v.toLowerCase(); if (t.contains('hombre')) return 'Hombres'; if (t.contains('mujer')) return 'Mujeres'; return 'Ambos'; }
  String _normGenero(String v) { final t = v.toLowerCase(); if (t.contains('hombre')) return 'Hombres'; if (t.contains('mujer')) return 'Mujeres'; return 'NoDecir'; }
  bool _citaAcepta({required String prefCita, required String generoUser}) { final p = _normPref(prefCita); if (p == 'Ambos') return true; return p == generoUser; }
  bool _userAcepta({required String prefGlobal, required String genDueno}) { final p = _normPref(prefGlobal); if (p == 'Ambos') return true; return p == genDueno; }
  String _pickNombreFromUserDoc(Map<String, dynamic> d) => (d['nombre'] ?? d['name'] ?? d['displayName'] ?? '').toString().trim();
  int _pickEdadFromUserDoc(Map<String, dynamic> d) { final e = d['edad'] ?? d['age']; if (e is int) return e; if (e is String) return int.tryParse(e) ?? 0; return 0; }
  int _pickPuntualidadFromUserDoc(Map<String, dynamic> d) { final p = d['confiabilidad']; if (p is int) return p; if (p is num) return p.toInt(); return 100; }
  String _pickFotoFromUserDoc(Map<String, dynamic> d) { final keys = ['profilePhotoUrl', 'photoUrl', 'fotoPerfil', 'foto']; for (final k in keys) { final v = (d[k] ?? '').toString().trim(); if (v.isNotEmpty) return v; } final list1 = (d['photoUrls'] as List<dynamic>? ?? []).map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList(); if (list1.isNotEmpty) return list1.first; return ''; }
  Map<String, dynamic> _readCreador(Map<String, dynamic> data) => _safeMap(data['creador']);

  Future<Map<String, dynamic>> _getUserDocCached(String uid) async {
    if (_userCache.containsKey(uid)) return _userCache[uid]!;
    try { final snap = await FirebaseFirestore.instance.collection(kUsersCol).doc(uid).get(); final d = snap.data() ?? {}; _userCache[uid] = d; return d; } catch (_) { _userCache[uid] = {}; return {}; }
  }

  // 🔥 RADAR INVISIBLE: Filtro Matemático
  // 🕐 FIX MARGEN MÍNIMO DE 12H: solo se muestran citas con AL MENOS 12 horas de margen antes
  // de que ocurran (12h00m exactas cuentan como válidas; 11h59m o menos, se ocultan). Es el
  // tiempo mínimo que necesita el dueño para revisar candidatos y elegir uno antes de la cita.
  // Sin límite superior — una cita a 3 meses se muestra igual si cumple el margen mínimo.
  // Citas sin fecha parseable se excluyen (no se puede garantizar que cumplan la regla).
  Future<List<_CitaCardModel>> _applyFilters({required List<_CitaCardModel> raw, required String uid, required String generoUser, required String prefGlobal}) async {
    final out = <_CitaCardModel>[];
    final ahora = DateTime.now();

    for (final m in raw) {

      // 🧨 WIPE-OUT: ESCUDO ANTI-BLOQUEADOS (Si su UID está en mi lista negra, lo salto al instante)
      if (!m.isAd && _misBloqueados.contains(m.ownerUid)) continue;

      // 🕐 FIX MARGEN MÍNIMO DE 12H (no aplica a anuncios)
      if (!m.isAd) {
        if (m.scheduledAt == null) continue;
        final faltante = m.scheduledAt!.difference(ahora);
        if (faltante < kMargenMinimoAntesDeCita) continue;
      }

      if (!m.isAd && m.scheduledAt != null) {
        bool chocaRadar = false;
        for (var ocupado in _misHorariosOcupados) {
          if (m.scheduledAt!.difference(ocupado).inMinutes.abs() < 180) {
            chocaRadar = true;
            break;
          }
        }
        if (chocaRadar) continue;
      }

      final docDesc = await FirebaseFirestore.instance.collection(kCitasCol).doc(m.citaId).collection(kSubDescartes).doc(uid).get();
      final docCand = await FirebaseFirestore.instance.collection(kCitasCol).doc(m.citaId).collection(kSubCandidatos).doc(uid).get();
      if (docDesc.exists || docCand.exists) continue;
      out.add(m);
    }
    final ownerUids = out.map((e) => e.ownerUid).where((e) => e.isNotEmpty && e != uid).toSet().toList();
    final genDueno = <String, String>{};
    for (final ou in ownerUids) { try { final snap = await FirebaseFirestore.instance.collection(kUsersCol).doc(ou).get(); genDueno[ou] = _normGenero((snap.data() ?? {})[kUserGeneroField]?.toString() ?? ''); } catch (_) { genDueno[ou] = 'NoDecir'; } }
    final filtrados = <_CitaCardModel>[];
    for (final m in out) { final g = genDueno[m.ownerUid] ?? 'NoDecir'; if (_citaAcepta(prefCita: m.preferencia, generoUser: generoUser) && _userAcepta(prefGlobal: prefGlobal, genDueno: g)) { filtrados.add(m); } }
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
      String fechaRaw = _s(data[kFechaField]); String horaRaw = _s(data[kHoraField]);

      // 🔥 Se añade la asignación del nuevo campo invisible scheduledAt a la data
      DateTime? dtRadar;
      final sched = data['scheduledAt'];
      if (sched is Timestamp) {
        dtRadar = sched.toDate();
        fechaRaw = _fmtFechaLarga(dtRadar);
        horaRaw = _fmtHora24(dtRadar);
      } else {
        dtRadar = _parseDateManual(fechaRaw, horaRaw);
      }

      final intencion = _s(data['intencion']).isEmpty ? 'Amistad' : _s(data['intencion']);
      final prefCita = _s(data['preferencia']).isEmpty ? 'Ambos' : _s(data['preferencia']);
      final creador = _readCreador(data);
      String creadorNombre = _s(creador['nombre']).trim(); final creadorEdadRaw = creador['edad']; String creadorFoto = _s(creador['foto']).trim(); final creadorUidFromObj = _s(creador['uid']).trim(); final legacyNombre = _s(data['creadorNombre']).trim(); final legacyEdadRaw = data['creadorEdad']; final legacyFoto = _s(data['creadorFoto']).trim();
      final ownerFinal = ownerUid.isNotEmpty ? ownerUid : (creadorUidFromObj.isNotEmpty ? creadorUidFromObj : 'unknown');
      int edadFinal = 0; int puntajeFinal = 100; bool userIsVerified = false;

      if (creadorEdadRaw is int) { edadFinal = creadorEdadRaw; } else { edadFinal = int.tryParse(creadorEdadRaw?.toString() ?? '') ?? 0; }
      if (edadFinal <= 0) { if (legacyEdadRaw is int) { edadFinal = legacyEdadRaw; } else { edadFinal = int.tryParse(legacyEdadRaw?.toString() ?? '') ?? 0; } }
      if (creadorNombre.isEmpty) creadorNombre = legacyNombre;
      String fotoFinal = creadorFoto.isNotEmpty ? creadorFoto : legacyFoto;

      if (ownerFinal.isNotEmpty && ownerFinal != 'unknown') {
        final u = await _getUserDocCached(ownerFinal);
        if (creadorNombre.isEmpty) { final n = _pickNombreFromUserDoc(u); if (n.isNotEmpty) creadorNombre = n; }
        if (edadFinal <= 0) { final e = _pickEdadFromUserDoc(u); if (e > 0) edadFinal = e; }
        if (fotoFinal.isEmpty || fotoFinal == 'assets/images/perfil1.jpg') { final f = _pickFotoFromUserDoc(u); if (f.isNotEmpty) fotoFinal = f; }
        puntajeFinal = _pickPuntualidadFromUserDoc(u);
        userIsVerified = u['isVerified'] == true;
      }
      if (creadorNombre.isEmpty) creadorNombre = 'Usuario';
      if (fotoFinal.isEmpty) fotoFinal = 'assets/images/perfil1.jpg';

      out.add(_CitaCardModel(
        citaId: d.id, ownerUid: ownerFinal, creatorName: creadorNombre, creatorAge: edadFinal, creatorPhoto: fotoFinal,
        placePhotos: placePhotos, placeName: nombreLugar, placeAddress: direccionLugar,
        fecha: fechaRaw.isEmpty ? 'Fecha pendiente' : fechaRaw, hora: horaRaw.isEmpty ? 'Hora pendiente' : horaRaw,
        scheduledAt: dtRadar, // 🔥 Se pasa el dato al modelo
        intencion: intencion, preferencia: prefCita, puntualidad: puntajeFinal, isVerified: userIsVerified,
      ));
    }
    return out;
  }

  void _backToPanel() { final nav = Navigator.of(context); if (nav.canPop()) { nav.pop(); return; } nav.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const PanelScreen()), (_) => false); }

  Widget _buildCardContent(_CitaCardModel model, double blockW, double safeHeight, double likeOp, double nopeOp, {bool isFrontCard = false}) {
    if (model.isAd) {
      return PublicidadSwapCard(
        imageUrl: model.adUrl,
        width: blockW,
        totalHeight: safeHeight,
        isFrontCard: isFrontCard,
        onAutoDismiss: () => _onNope(MediaQuery.sizeOf(context), _uid),
      );
    }
    return _SwipeBundleSolid(
      model: model, likeOpacity: likeOp, nopeOpacity: nopeOp, width: blockW, totalHeight: safeHeight,
      onCreatorPhotoTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PerfilUsuarioXScreen(uid: model.ownerUid))),
      onPlacePhotoTap: () { final lugar = LugarData(id: model.citaId, nombre: model.placeName, direccion: model.placeAddress, bio: '', fotos: model.placePhotos, fotoPortada: model.placePhotos.first, sitioWeb: '', orden: 9999, sedes: const []); Navigator.of(context).push(MaterialPageRoute(builder: (_) => LugarPlantillaSinBotonScreen(lugar: lugar))); },
      onLikeTap: () => _onLike(MediaQuery.sizeOf(context), _uid),
      onNopeTap: () => _onNope(MediaQuery.sizeOf(context), _uid),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('Debes iniciar sesión', style: TextStyle(color: Colors.white))));
    final Size screen = MediaQuery.sizeOf(context);
    final double blockW = screen.width * kCardWidthFactor;
    final double safeHeight = screen.height * kCardHeightFactor;

    return Scaffold(
      body: Stack(
        children: [
          MatchyPageLayout(
            backgroundAsset: backgroundAsset, logoAsset: logoAsset, topSpacing: topSpacing,
            logoHeight: logoHeight, logoOffsetY: logoOffsetY, spaceLogoToScroll: spaceLogoToScroll,
            scrollContent: _buildBody(blockW, safeHeight),
          ),
          Positioned(top: 10, left: 16, child: SafeArea(child: Material(color: Colors.black.withOpacity(0.25), shape: const CircleBorder(), child: InkWell(customBorder: const CircleBorder(), onTap: _backToPanel, child: const SizedBox(width: 42, height: 42, child: Icon(Icons.arrow_back, color: Colors.white)))))),
        ],
      ),
    );
  }

  Widget _buildBody(double blockW, double safeHeight) {
    final noMore = _deck.isEmpty || _topIndex >= _deck.length;

    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: kCardTopMargin),
        child: SizedBox(
          width: blockW, height: safeHeight,
          child: Stack(
            children: [
              if (_isLoading && (_deck.isEmpty || _topIndex >= _deck.length))
                const Positioned.fill(child: _MatchySpinner()),

              if (!_isLoading || _deck.isNotEmpty) ...[
                if (!noMore && _topIndex + 1 < _deck.length)
                  Positioned.fill(child: _buildCardContent(_deck[_topIndex + 1], blockW, safeHeight, 0.0, 0.0, isFrontCard: false)),

                if (!noMore)
                  Positioned.fill(
                      child: GestureDetector(
                          onPanUpdate: _onPanUpdate,
                          onPanEnd: (d) => _onPanEnd(d, MediaQuery.sizeOf(context), _uid),
                          child: Transform.translate(
                              offset: Offset(_dx, 0),
                              child: Transform.rotate(
                                  angle: _rotationDeg * (math.pi / 180),
                                  child: _buildCardContent(_deck[_topIndex], blockW, safeHeight, _likeOpacityValue, _nopeOpacityValue, isFrontCard: true)
                              )
                          )
                      )
                  ),

                if (noMore && !_isLoading)
                  Positioned.fill(child: Center(child: Container(width: blockW * 0.92, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), decoration: BoxDecoration(color: Colors.black.withOpacity(0.38), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white24, width: 1)), child: const Text('No hay citas disponibles ahora.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700))))),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MatchySpinner extends StatelessWidget {
  const _MatchySpinner();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 60, height: 60,
                child: CircularProgressIndicator(
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7E208E)),
                  strokeWidth: 6,
                  backgroundColor: Colors.white.withOpacity(0.1),
                ),
              ),
              const SizedBox(
                width: 40, height: 40,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            "Buscando citas nuevas para ti...",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SwipeBundleSolid extends StatelessWidget {
  final _CitaCardModel model; final double likeOpacity; final double nopeOpacity; final double width; final double totalHeight;
  final VoidCallback onCreatorPhotoTap; final VoidCallback onPlacePhotoTap; final VoidCallback onLikeTap; final VoidCallback onNopeTap;

  const _SwipeBundleSolid({required this.model, required this.likeOpacity, required this.nopeOpacity, required this.width, required this.totalHeight, required this.onCreatorPhotoTap, required this.onPlacePhotoTap, required this.onLikeTap, required this.onNopeTap});

  bool _isNet(String v) => v.startsWith('http');
  bool _isAsset(String v) => v.startsWith('assets/');

  Widget _buildPhoto(String url, VoidCallback onTap, {bool isProfile = false}) {
    final src = url.trim();
    final int cacheH = isProfile ? 800 : 400;
    Widget imgWidget;

    if (src.isEmpty) {
      imgWidget = Image.asset('assets/images/perfil1.jpg', fit: BoxFit.cover);
    }
    else if (_isNet(src)) {
      imgWidget = CachedNetworkImage(
          key: ValueKey(src),
          imageUrl: src,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          memCacheHeight: cacheH,
          placeholder: (context, url) => Container(
              color: Colors.black26,
              alignment: Alignment.center,
              child: const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFBEB3FF)))
          ),
          errorWidget: (context, url, error) => Image.asset('assets/images/perfil1.jpg', fit: BoxFit.cover)
      );
    }
    else {
      imgWidget = Image.asset(_isAsset(src) ? src : 'assets/images/perfil1.jpg', fit: BoxFit.cover, alignment: Alignment.topCenter, errorBuilder: (_, __, ___) => Image.asset('assets/images/perfil1.jpg', fit: BoxFit.cover));
    }

    return GestureDetector(
        onTap: onTap,
        child: Container(
            width: width,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_CitaBuscarScreenState.kCardBorderRadius),
                boxShadow: isProfile ? [const BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 5))] : null
            ),
            child: Stack(
                fit: StackFit.expand,
                children: [
                  imgWidget,
                  if (isProfile) Positioned(bottom: 0, left: 0, right: 0, child: Container(height: 120, decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.95)])))),
                  if (isProfile)
                    Positioned(
                        left: 16, right: 16, bottom: 12,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (model.isVerified)
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00B4DB).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: const Color(0xFF00B4DB), width: 1),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.verified, color: Color(0xFF00B4DB), size: 12),
                                      SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          "PERFIL VERIFICADO",
                                          style: TextStyle(
                                              color: Color(0xFF00B4DB),
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                              fontFamily: 'Poppins'
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: RichText(
                                    text: TextSpan(
                                        children: [
                                          TextSpan(text: model.creatorName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                                          TextSpan(text: ', ${model.creatorAge}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900))
                                        ]
                                    )
                                )
                            ),
                          ],
                        )
                    ),

                  if (!isProfile) Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.95)], stops: const [0.3, 1.0]))),
                  if (!isProfile) Positioned(left: 14, right: 14, bottom: 12, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: [
                    FittedBox(fit: BoxFit.scaleDown, child: Text(model.placeName.toUpperCase(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, height: 0.9))),
                    const SizedBox(height: 2),
                    FittedBox(fit: BoxFit.scaleDown, child: Text(model.placeAddress, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 14, fontFamily: 'Poppins')))
                  ])),
                  Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), shape: BoxShape.circle),
                        child: const Icon(Icons.person_search, color: Colors.white, size: 24),
                      )
                  ),
                ]
            )
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width, height: totalHeight,
      decoration: BoxDecoration(color: _CitaBuscarScreenState.kCardBackground, borderRadius: BorderRadius.circular(_CitaBuscarScreenState.kCardBorderRadius), boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, 6))]),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Column(
            children: [
              Expanded(flex: 72, child: _buildPhoto(model.creatorPhoto, onCreatorPhotoTap, isProfile: true)),
              const SizedBox(height: _CitaBuscarScreenState.kGapSmall),
              SizedBox(height: _CitaBuscarScreenState.kInfoHeight, child: FittedBox(fit: BoxFit.scaleDown, child: Container(width: width * 0.95, height: _CitaBuscarScreenState.kInfoHeight, padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.white.withOpacity(0.10), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white12)), child: Container(padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: FittedBox(alignment: Alignment.centerLeft, fit: BoxFit.scaleDown, child: Text(model.fecha, style: const TextStyle(color: Color(0xFFFFC107), fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Poppins')))), const SizedBox(width: 10), Text(model.hora, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 21, fontFamily: 'Poppins'))]),
                const SizedBox(height: 4),
                Container(height: 1, color: Colors.white12),
                const SizedBox(height: 4),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Text("Intención: ", style: TextStyle(color: Colors.white54, fontSize: 15, fontFamily: 'Poppins')),
                        Expanded(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(model.intencion, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Poppins')))),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text("Preferencia: ", style: TextStyle(color: Colors.white54, fontSize: 15, fontFamily: 'Poppins')),
                        Expanded(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(model.preferencia, style: const TextStyle(color: Color(0xFFE0D4FF), fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Poppins')))),
                      ],
                    ),
                  ),
                ])
              ]))))),
              const SizedBox(height: _CitaBuscarScreenState.kGapSmall),
              Expanded(flex: 30, child: _buildPhoto((model.placePhotos.isNotEmpty ? model.placePhotos.first : ''), onPlacePhotoTap, isProfile: false)),
              const SizedBox(height: _CitaBuscarScreenState.kGapSmall),
              SizedBox(height: _CitaBuscarScreenState.kBarHeight, child: FittedBox(fit: BoxFit.scaleDown, child: Container(width: width * 0.90, height: _CitaBuscarScreenState.kBarHeight, padding: const EdgeInsets.symmetric(horizontal: 4), decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white12)), child: _MiniTermometro(puntaje: model.puntualidad)))),
              const SizedBox(height: _CitaBuscarScreenState.kGapTiny),

              SizedBox(
                  height: _CitaBuscarScreenState.kButtonsHeight,
                  child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Container(
                          width: width * 0.90,
                          height: _CitaBuscarScreenState.kButtonsHeight,
                          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white12)),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _CircleActionBtn(icon: Icons.close, color: Colors.white54, size: 28, onTap: onNopeTap),
                                Expanded(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(Icons.arrow_back_rounded, color: Color(0xFFFF6E63), size: 14),
                                          SizedBox(width: 4),
                                          Text("NO", style: TextStyle(color: Color(0xFFFF6E63), fontSize: 13, fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
                                          Text("   -   ¿POSTULARTE A ESTA CITA?   -   ", style: TextStyle(color: Colors.white54, fontSize: 15, fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                                          Text("SÍ", style: TextStyle(color: Color(0xFF00E676), fontSize: 13, fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
                                          SizedBox(width: 4),
                                          Icon(Icons.arrow_forward_rounded, color: Color(0xFF00E676), size: 14),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                _CircleActionBtn(icon: Icons.favorite, color: const Color(0xFF7E208E), size: 28, onTap: onLikeTap)
                              ]
                          )
                      )
                  )
              ),
              const SizedBox(height: 12),
            ],
          ),

          IgnorePointer(
              child: Stack(
                  children: [
                    Positioned(
                        left: 20,
                        top: 60,
                        child: Opacity(
                            opacity: likeOpacity,
                            child: Transform.rotate(
                                angle: -20 * (math.pi / 180),
                                child: const _ChoiceBadge(text: 'ME INTERESA', borderColor: Color(0xFF63FF68), textColor: Color(0xFF63FF68))
                            )
                        )
                    ),
                    Positioned(
                        right: 20,
                        top: 60,
                        child: Opacity(
                            opacity: nopeOpacity,
                            child: Transform.rotate(
                                angle: 20 * (math.pi / 180),
                                child: const _ChoiceBadge(text: 'NO ME\nINTERESA', borderColor: Color(0xFFFF6E63), textColor: Color(0xFFFF6E63))
                            )
                        )
                    )
                  ]
              )
          ),
        ],
      ),
    );
  }
}

class _MiniTermometro extends StatelessWidget {
  final int puntaje;
  const _MiniTermometro({required this.puntaje});

  Color _getColor(int s) { if(s>=80) return const Color(0xFF00E676); if(s>=50) return const Color(0xFFFFC107); if(s>=20) return const Color(0xFFFF5722); return const Color(0xFFD50000); }

  @override
  Widget build(BuildContext context) {
    final color = _getColor(puntaje);
    final double ancho = (puntaje / 100).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("PUNTUALIDAD", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w800, fontFamily: 'Poppins')), Text("$puntaje%", style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w900, fontFamily: 'Poppins'))]),
        const SizedBox(height: 6),
        Container(height: 8, width: double.infinity, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(4)), child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: ancho, child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4), boxShadow: [BoxShadow(color: color.withOpacity(0.6), blurRadius: 6)]))))
      ]),
    );
  }
}

class _CircleActionBtn extends StatelessWidget { final IconData icon; final Color color; final VoidCallback onTap; final double size; const _CircleActionBtn({required this.icon, required this.color, required this.onTap, required this.size}); @override Widget build(BuildContext context) { return GestureDetector(onTap: onTap, child: Container(width: 70, alignment: Alignment.center, color: Colors.transparent, child: Icon(icon, color: color, size: size))); } }

class _ChoiceBadge extends StatelessWidget {
  final String text;
  final Color borderColor;
  final Color textColor;
  const _ChoiceBadge({required this.text, required this.borderColor, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(border: Border.all(color: borderColor, width: 4), borderRadius: BorderRadius.circular(8)),
        child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textColor, shadows: [Shadow(blurRadius: 10, color: Colors.black.withOpacity(0.30))])
        )
    );
  }
}

class _CitaCardModel {
  final bool isAd;
  final String adUrl;
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
  final DateTime? scheduledAt; // 🔥 Nuevo campo invisible para radar
  final String intencion;
  final String preferencia;
  final int puntualidad;
  final bool isVerified;

  const _CitaCardModel({
    this.isAd = false,
    this.adUrl = '',
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
    this.scheduledAt,
    required this.intencion,
    required this.preferencia,
    this.puntualidad = 100,
    this.isVerified = false,
  });

  factory _CitaCardModel.ad(String url, String idRealFirebase) {
    return _CitaCardModel(
        isAd: true,
        adUrl: url,
        citaId: idRealFirebase,
        ownerUid: '', creatorName: '', creatorAge: 0, creatorPhoto: '',
        placePhotos: [], placeName: '', placeAddress: '',
        fecha: '', hora: '', scheduledAt: null, intencion: '', preferencia: '', isVerified: false
    );
  }
}