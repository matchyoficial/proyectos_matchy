// 📂 lib/screens/comunidad.dart
// ✅ PANTALLA COMUNIDAD (PERFILES COMPLETOS ESTILO PERFIL_USUARIOX + MOTOR DE SWIPE)
// 🔥 MOTOR DE SWIPE: misma física que cita_buscar.dart (drag, fling, rotación, opacidad de letreros).
// 🛡️ GESTOS: RawGestureDetector + HorizontalDragGestureRecognizer -> se puede arrastrar en TODA la
//    tarjeta sin romper el scroll vertical (para leer el perfil completo), igual que Tinder.
// 🧨 RECHAZOS: swipe izquierda oculta el perfil 1 mes. Al 3er rechazo acumulado, se oculta para siempre.
// 💜 INTERÉS: swipe derecha navega a intereses_citas_screen.dart. El registro real de "me interesa"
//    y el avance del mazo YA NO ocurren aquí — ver fix crítico abajo.
// 🎯 FILTRO: preferencia de citas MUTUA (mi preferencia vs su género, y viceversa) — mismo patrón que
//    cita_buscar.dart. Campos confirmados contra datos_screen.dart: 'genero' ('Hombre'/'Mujer'/'Otro'/
//    'NoDecir') y 'preferenciaCitas' ('Hombres'/'Mujeres'/'Ambos').
// 📢 PUBLICIDAD: mismo sistema exacto que cita_buscar.dart (colección 'publicidad_swap', filtro por
//    pais/ciudad, caché diario en SharedPreferences, inserción cada ~5 tarjetas, PublicidadSwapCard).
// 🐛 FIX CRÍTICO: antes, al hacer swipe derecha, se escribía de inmediato en 'perfil_intereses'
//    (escondiendo ese perfil PARA SIEMPRE) y se avanzaba el mazo, SIN IMPORTAR si el usuario
//    completaba el formulario de intereses_citas_screen.dart o le daba "atrás" a mitad de camino.
//    Ahora: la escritura en 'perfil_intereses' se movió a intereses_citas_screen.dart (solo ocurre
//    si la invitación se envía de verdad), y el avance del mazo depende del valor que devuelve esa
//    pantalla al cerrarse — Navigator.push<bool>(...). Si vuelve `true` (invitación enviada), el
//    mazo avanza normal. Si vuelve null/false (canceló), la tarjeta regresa suavemente a su lugar
//    con _resetCard(), lista para reintentarlo.
// 🆕 LOTES ALEATORIOS: antes, la consulta a Firestore siempre pedía los usuarios ordenados por
//    documentId desde el principio de la lista, así que cada vez que se abría Comunidad aparecían
//    siempre los mismos primeros perfiles, en el mismo orden. Ahora cada sesión arranca desde un
//    punto aleatorio de la lista (con vuelta automática al principio si se llega al final antes de
//    completar un lote), y además cada lote que llega se revuelve antes de mostrarse.
// 🆕 SCROLL SIEMPRE ARRIBA: se agregó un ScrollController compartido para la tarjeta que está al
//    frente, que se reinicia a la parte superior cada vez que se pasa a un perfil nuevo (like/nope/
//    anuncio) y cada vez que una tarjeta regresa a su lugar después de cancelar en
//    intereses_citas_screen.dart — sin importar cuánto se haya bajado leyendo el perfil.
// ⚠️ IMPORTANTE: revisa tus reglas de seguridad de Firestore — esta pantalla necesita permiso de
//    "list" sobre la colección 'users' (no solo "get" por UID), o la consulta fallará en tiempo real.

import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:proyectos_matchy/screens/panel_screen.dart';
import 'package:proyectos_matchy/screens/intereses_citas_screen.dart';
import 'package:proyectos_matchy/widgets/foto_perfil_usuario.dart';
import 'package:proyectos_matchy/widgets/termometro_confiabilidad.dart';
import 'package:proyectos_matchy/widgets/publicidad_swap_card.dart';

class ComunidadScreen extends StatefulWidget {
  static const String routeName = 'comunidad';
  const ComunidadScreen({super.key});

  @override
  State<ComunidadScreen> createState() => _ComunidadScreenState();
}

class _ComunidadScreenState extends State<ComunidadScreen> with SingleTickerProviderStateMixin {
  // 🛡️ FÍSICA DEL SWIPE (idéntica a cita_buscar.dart)
  static const double decisionThresholdPx = 75.0;
  static const double rotationDivisor = 14.0;
  static const double opacityDivisor = 100.0;
  static const int flingDurationMs = 340;
  static const int resetDurationMs = 240;
  static const double offscreenDiagMultiplier = 2.2;
  static const double offscreenExtraPx = 180.0;

  // 🛡️ DISEÑO (idéntico a perfil_usuariox_screen.dart)
  static const String kUsersCollection = 'users';
  static const double altoFotoPrincipal = 450;
  static const List<Shadow> kTextShadow = [Shadow(color: Colors.black, blurRadius: 10, offset: Offset(0, 4))];
  static const List<BoxShadow> kChipShadow = [BoxShadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 3))];
  static const int maxShortLength = 14;
  static const double gapX = 10;
  static const double chipPadV = 10;
  static const double chipPadH = 10;
  static const double chipFont = 13;

  // 🔥 MATCHING / FILTRO / RECHAZOS
  static const String kSubBloqueados = 'blocked_users';
  static const String kSubRechazos = 'perfil_rechazos';
  static const String kSubIntereses = 'perfil_intereses';
  static const String kUserGeneroField = 'genero';
  static const String kUserPreferenciaCitasField = 'preferenciaCitas';
  static const int kMaxRechazosPermanente = 3;
  static const int kDiasCooldownRechazo = 30;

  // 🆕 Alfabeto usado para generar un ID "de mentiras" con el que saltar a un punto aleatorio
  // dentro del orden por documentId — no corresponde a ningún usuario real, solo sirve como
  // punto de comparación para la consulta.
  static const String _kIdAlphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

  List<_ComunidadCardModel> _deck = [];
  int _topIndex = 0;
  double _dx = 0.0;
  bool _isAnimating = false;

  late final AnimationController _controller;
  Animation<double>? _dxAnim;

  DocumentSnapshot? _lastDoc;
  bool _isLoading = true;
  bool _hasMore = true;
  String _uid = '';
  String _prefGlobal = '';
  String _generoUser = '';
  List<String> _misBloqueados = [];

  // 🆕 Punto de partida aleatorio de esta sesión, y bandera de si ya dimos la vuelta completa.
  String? _randomStartId;
  bool _wrappedAround = false;

  // 🆕 Control de scroll compartido de la tarjeta que está al frente.
  final ScrollController _cardScrollController = ScrollController();

  // 📢 PUBLICIDAD (idéntico a cita_buscar.dart)
  String _userPais = 'Colombia';
  String _userCiudad = 'Cali';

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
    _initComunidad();
  }

  @override
  void dispose() {
    _controller.dispose();
    _cardScrollController.dispose(); // 🆕
    super.dispose();
  }

  // 🆕 Genera un ID al azar (mismo formato de caracteres que usa Firestore) para usarlo como
  // punto de partida aleatorio de la consulta.
  String _randomDocId({int length = 20}) {
    final rnd = math.Random();
    return List.generate(length, (_) => _kIdAlphabet[rnd.nextInt(_kIdAlphabet.length)]).join();
  }

  Future<void> _initComunidad() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _uid = user.uid;

    _randomStartId = _randomDocId(); // 🆕 punto de partida aleatorio para esta sesión

    try {
      final blockSnap = await FirebaseFirestore.instance
          .collection(kUsersCollection)
          .doc(_uid)
          .collection(kSubBloqueados)
          .get();
      _misBloqueados = blockSnap.docs.map((d) => d.id).toList();

      final snap = await FirebaseFirestore.instance.collection(kUsersCollection).doc(_uid).get();
      final udata = snap.data() ?? {};
      _prefGlobal = _normPref((udata[kUserPreferenciaCitasField] ?? 'Ambos').toString());
      _generoUser = _normGenero((udata[kUserGeneroField] ?? 'Prefiero no decirlo').toString());
      _userPais = (udata['pais'] ?? 'Colombia').toString();
      _userCiudad = (udata['ciudad'] ?? 'Cali').toString();
    } catch (_) {
      _prefGlobal = 'Ambos';
      _generoUser = 'NoDecir';
    }

    await _fetchUsersBatch();
  }

  // ===========================================================================
  // 🔤 NORMALIZACIÓN Y MATCHING (mismo patrón que cita_buscar.dart)
  // ===========================================================================
  String _normPref(String v) {
    final t = v.toLowerCase();
    if (t.contains('hombre')) return 'Hombres';
    if (t.contains('mujer')) return 'Mujeres';
    return 'Ambos';
  }

  String _normGenero(String v) {
    final t = v.toLowerCase();
    if (t.contains('hombre')) return 'Hombres';
    if (t.contains('mujer')) return 'Mujeres';
    return 'NoDecir';
  }

  bool _perfilAcepta({required String prefPerfil, required String generoUser}) {
    final p = _normPref(prefPerfil);
    if (p == 'Ambos') return true;
    return p == generoUser;
  }

  bool _userAcepta({required String prefGlobal, required String generoOtro}) {
    final p = _normPref(prefGlobal);
    if (p == 'Ambos') return true;
    return p == generoOtro;
  }

  // ===========================================================================
  // 📡 FETCH + FILTRO DE PERFILES
  // ===========================================================================
  Future<void> _fetchUsersBatch() async {
    if (!_hasMore || !mounted) return;
    setState(() => _isLoading = true);

    try {
      Query q = FirebaseFirestore.instance
          .collection(kUsersCollection)
          .orderBy(FieldPath.documentId)
          .limit(15);

      if (_lastDoc != null) {
        q = q.startAfterDocument(_lastDoc!);
      } else if (_randomStartId != null && !_wrappedAround) {
        // 🆕 Solo se usa en la PRIMERA página de esta sesión (sin _lastDoc todavía y sin haber
        // dado la vuelta aún), para que cada vez que se abra Comunidad se empiece a mostrar
        // perfiles desde un lugar distinto de la lista.
        q = q.startAt([_randomStartId]);
      }

      final snap = await q.get();

      if (snap.docs.isEmpty) {
        // 🆕 Si llegamos al final de la lista de usuarios sin completar un lote y todavía no
        // habíamos dado la vuelta, reiniciamos desde el verdadero principio (documentId más
        // chico) para no dejar perfiles sin mostrar — solo cambia por dónde se empieza.
        if (!_wrappedAround) {
          _wrappedAround = true;
          _lastDoc = null;
          await _fetchUsersBatch();
          return;
        }
        if (mounted) setState(() { _hasMore = false; _isLoading = false; });
        return;
      }

      _lastDoc = snap.docs.last;

      final rawCards = await _mapDocsToDeck(docs: snap.docs as List<QueryDocumentSnapshot<Map<String, dynamic>>>);
      final validCards = await _applyFilters(raw: rawCards);
      validCards.shuffle(math.Random()); // 🆕 revuelve el orden del lote antes de mostrarlo

      if (!mounted) return;

      setState(() {
        _deck.addAll(validCards);
        _isLoading = false;
      });

      _precacheDeckImages(validCards);

      // 📢 INYECCIÓN DE PUBLICIDAD (idéntico a cita_buscar.dart)
      if (validCards.isNotEmpty) {
        _inyectarAdSiAplica();
      } else if (_hasMore) {
        _fetchUsersBatch();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _precacheDeckImages(List<_ComunidadCardModel> cards) {
    for (final c in cards) {
      for (final url in c.galeria) {
        if (url.startsWith('http')) {
          precacheImage(CachedNetworkImageProvider(url), context).catchError((_) {});
        }
      }
    }
  }

  Future<List<_ComunidadCardModel>> _mapDocsToDeck({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  }) async {
    final out = <_ComunidadCardModel>[];
    for (final d in docs) {
      if (d.id == _uid) continue; // 🔥 Nunca mostrar mi propio perfil
      final data = d.data();

      final nombre = (data['nombre'] ?? '').toString().trim();
      if (nombre.isEmpty) continue; // Perfil incompleto, no se muestra

      final edadRaw = data['edad'];
      final int edad = edadRaw is int ? edadRaw : int.tryParse(edadRaw?.toString() ?? '') ?? 0;
      final profesion = (data['profesion'] ?? '').toString().trim();
      final ciudad = (data['ciudad'] ?? '').toString().trim();
      final pais = (data['pais'] ?? '').toString().trim();
      final bio = (data['biografia'] ?? '').toString().trim();
      final detalle = (data['detalle'] ?? '').toString().trim();
      final isVerified = data['isVerified'] == true;
      final sobreMi = (data['sobreMiSeleccion'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
      final busco = (data['buscoSeleccion'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
      final intereses = (data['interesesSeleccion'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
      final galeria = (data['photoUrls'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
      final puntaje = (data['confiabilidad'] as num?)?.toInt() ?? 100;
      final generoOtro = _normGenero((data[kUserGeneroField] ?? 'Prefiero no decirlo').toString());
      final prefOtro = (data[kUserPreferenciaCitasField] ?? 'Ambos').toString();
      final userStatus = (data['userStatus'] ?? 'active').toString();
      final strikes = (data['strikes'] as num?)?.toInt() ?? 0;
      final bloqueadoHasta = (data['bloqueadoHasta'] as Timestamp?)?.toDate();

      out.add(_ComunidadCardModel(
        uid: d.id,
        nombre: nombre,
        edad: edad,
        profesion: profesion,
        ciudad: ciudad,
        pais: pais,
        bio: bio,
        detalle: detalle,
        isVerified: isVerified,
        sobreMi: sobreMi,
        busco: busco,
        intereses: intereses,
        galeria: galeria,
        puntaje: puntaje,
        generoOtro: generoOtro,
        prefOtro: prefOtro,
        userStatus: userStatus,
        strikes: strikes,
        bloqueadoHasta: bloqueadoHasta,
      ));
    }
    return out;
  }

  Future<List<_ComunidadCardModel>> _applyFilters({required List<_ComunidadCardModel> raw}) async {
    final out = <_ComunidadCardModel>[];
    for (final m in raw) {
      // 🧨 Escudo anti-bloqueados
      if (_misBloqueados.contains(m.uid)) continue;

      // 🔥 Filtro mutuo de preferencia/género
      final aceptaPerfil = _perfilAcepta(prefPerfil: m.prefOtro, generoUser: _generoUser);
      final aceptaUser = _userAcepta(prefGlobal: _prefGlobal, generoOtro: m.generoOtro);
      if (!aceptaPerfil || !aceptaUser) continue;

      // 🔥 Escudo de rechazos: cooldown de 1 mes / oculto permanente tras 3 rechazos
      try {
        final rechazoSnap = await FirebaseFirestore.instance
            .collection(kUsersCollection)
            .doc(_uid)
            .collection(kSubRechazos)
            .doc(m.uid)
            .get();
        if (rechazoSnap.exists) {
          final rdata = rechazoSnap.data() ?? {};
          if (rdata['permanente'] == true) continue;
          final ocultarHasta = (rdata['ocultarHasta'] as Timestamp?)?.toDate();
          if (ocultarHasta != null && ocultarHasta.isAfter(DateTime.now())) continue;
        }
      } catch (_) {}

      // 🔥 Ya le enviaste una invitación real antes -> no repetir
      try {
        final interesSnap = await FirebaseFirestore.instance
            .collection(kUsersCollection)
            .doc(_uid)
            .collection(kSubIntereses)
            .doc(m.uid)
            .get();
        if (interesSnap.exists) continue;
      } catch (_) {}

      out.add(m);
    }
    return out;
  }

  // ===========================================================================
  // 📢 PUBLICIDAD (idéntico a cita_buscar.dart, adaptado al mazo de comunidad)
  // ===========================================================================
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
            final adCard = _ComunidadCardModel.ad(adUrl, adId);
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
      debugPrint("🎯 [ADS-COMUNIDAD] Error crítico: $e");
    }
  }

  // ===========================================================================
  // ✍️ ESCRITURA: RECHAZO
  // (la escritura de "interés" ya no vive aquí — se movió a intereses_citas_screen.dart)
  // ===========================================================================
  Future<void> _writeRechazo(String otroUid) async {
    final ref = FirebaseFirestore.instance
        .collection(kUsersCollection)
        .doc(_uid)
        .collection(kSubRechazos)
        .doc(otroUid);
    final snap = await ref.get();
    int count = 0;
    if (snap.exists) count = ((snap.data() ?? {})['rechazos'] as num?)?.toInt() ?? 0;
    final nuevoCount = count + 1;
    final permanente = nuevoCount >= kMaxRechazosPermanente;
    await ref.set({
      'rechazos': nuevoCount,
      'permanente': permanente,
      'ocultarHasta': permanente ? null : Timestamp.fromDate(DateTime.now().add(const Duration(days: kDiasCooldownRechazo))),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ===========================================================================
  // 🌀 MOTOR DE ANIMACIÓN (idéntico a cita_buscar.dart)
  // ===========================================================================
  double get _rotationDeg => _dx / rotationDivisor;
  double get _likeOpacityValue => _dx > 0 ? (_dx.abs() / opacityDivisor).clamp(0.0, 1.0) : 0.0;
  double get _nopeOpacityValue => _dx < 0 ? (_dx.abs() / opacityDivisor).clamp(0.0, 1.0) : 0.0;

  Future<void> _animateTo(double target, Duration dur) async {
    _controller.stop();
    _controller.duration = dur;
    _dxAnim = Tween<double>(begin: _dx, end: target).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    await _controller.forward(from: 0.0);
  }

  // 🆕 Reinicia el scroll de la tarjeta al tope, para que cada perfil nuevo (o el mismo que
  // regresa después de cancelar en intereses_citas_screen.dart) siempre empiece arriba.
  void _resetCardScroll() {
    if (_cardScrollController.hasClients) {
      _cardScrollController.jumpTo(0);
    }
  }

  Future<void> _resetCard({bool alsoResetScroll = false}) async {
    _isAnimating = true;
    await _animateTo(0.0, const Duration(milliseconds: resetDurationMs));
    if (alsoResetScroll) _resetCardScroll(); // 🆕
  }

  double _screenDiag(Size s) => math.sqrt(s.width * s.width + s.height * s.height);

  Future<void> _flingOut({required bool right, required Size size, required _ComunidadCardModel model}) async {
    if (_topIndex >= _deck.length) return;
    _isAnimating = true;
    final diag = _screenDiag(size);
    final target = (right ? 1 : -1) * (diag * offscreenDiagMultiplier + offscreenExtraPx);
    await _animateTo(target, const Duration(milliseconds: flingDurationMs));
    if (!mounted) return;

    // 📢 ANUNCIO: solo se marca como visto y se avanza el mazo (sin navegar, sin rechazo/interés)
    if (model.isAd) {
      setState(() { _topIndex++; _dx = 0.0; });
      _resetCardScroll(); // 🆕
      final prefs = await SharedPreferences.getInstance();
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await prefs.setString('seen_ad_${model.uid}_$_uid', today);
      return;
    }

    if (right) {
      // 💜 SWIPE DERECHA: navega a intereses_citas_screen.dart y ESPERA su resultado.
      // 🐛 FIX: el mazo solo avanza si de verdad se completó y envió la invitación (pop(true)).
      // Si se canceló (atrás, o cualquier otra salida), la tarjeta regresa a su lugar.
      if (!mounted) return;
      final invitacionEnviada = await Navigator.of(context).push<bool>(MaterialPageRoute(
          builder: (_) => InteresesCitasScreen(
            uidInteres: model.uid,
            nombreInteres: model.nombre,
            edadInteres: model.edad,
          )));
      if (!mounted) return;

      if (invitacionEnviada == true) {
        setState(() { _topIndex++; _dx = 0.0; });
        _resetCardScroll(); // 🆕
        if (_deck.length - _topIndex <= 3 && !_isLoading && _hasMore) _fetchUsersBatch();
      } else {
        // Canceló sin completar el formulario: la tarjeta regresa suavemente a su lugar,
        // deslizándose desde donde voló hasta el centro (misma animación que ya existía), y el
        // scroll también vuelve arriba. 🆕
        await _resetCard(alsoResetScroll: true);
      }
      return;
    }

    // 🧨 SWIPE IZQUIERDA: registrar rechazo, avanzar mazo
    setState(() { _topIndex++; _dx = 0.0; });
    _resetCardScroll(); // 🆕

    if (_deck.length - _topIndex <= 3 && !_isLoading && _hasMore) {
      _fetchUsersBatch();
    }

    Future(() async {
      try { await _writeRechazo(model.uid); } catch (_) {}
    });
  }

  void _onHorizontalDragUpdate(DragUpdateDetails d) {
    if (_isAnimating) return;
    setState(() => _dx += d.delta.dx);
  }

  Future<void> _onHorizontalDragEnd(DragEndDetails d, Size size) async {
    if (_isAnimating) return;
    if (_dx.abs() < decisionThresholdPx) { await _resetCard(); return; }
    if (_topIndex >= _deck.length) return;
    final model = _deck[_topIndex];
    await _flingOut(right: _dx > 0, size: size, model: model);
  }

  Future<void> _onNope(Size size) async {
    if (_isAnimating || _topIndex >= _deck.length) return;
    _isAnimating = true;
    final isAd = _deck[_topIndex].isAd;
    await _animateTo(isAd ? -40 : -decisionThresholdPx - 60, const Duration(milliseconds: 300));
    await _flingOut(right: false, size: size, model: _deck[_topIndex]);
  }

  Future<void> _onLike(Size size) async {
    if (_isAnimating || _topIndex >= _deck.length) return;
    _isAnimating = true;
    final model = _deck[_topIndex];
    await _animateTo(model.isAd ? 40 : decisionThresholdPx + 60, const Duration(milliseconds: 300));
    await _flingOut(right: true, size: size, model: model);
  }

  // ===========================================================================
  // 🔔 BURBUJA + 🛡️ REPORTES (idéntico a perfil_usuariox_screen.dart)
  // ===========================================================================
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

  void _mostrarDialogoReporte(String reportadoNombre, String reportadoUid) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ReportDialogComunidad(
        reportadoNombre: reportadoNombre,
        reportadoUid: reportadoUid,
        onSuccess: () {
          _mostrarBurbuja("Reporte enviado. Nuestro equipo lo revisará pronto.", const Color(0xFF00E676), Icons.check_circle_outline_rounded);
        },
        onError: (e) {
          _mostrarBurbuja("Error al enviar reporte: $e", const Color(0xFFFF5252), Icons.error_outline_rounded);
        },
      ),
    );
  }

  void _backToPanel() {
    final nav = Navigator.of(context);
    if (nav.canPop()) { nav.pop(); return; }
    nav.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const PanelScreen()), (_) => false);
  }

  // ===========================================================================
  // 🖼️ RENDER DE TARJETA (perfil normal vs. anuncio)
  // ===========================================================================
  Widget _buildCardContent(_ComunidadCardModel model, {required bool isFrontCard}) {
    if (model.isAd) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return PublicidadSwapCard(
            imageUrl: model.adUrl,
            width: constraints.maxWidth,
            totalHeight: constraints.maxHeight,
            isFrontCard: isFrontCard,
            onAutoDismiss: () => _onNope(MediaQuery.sizeOf(context)),
          );
        },
      );
    }
    return _ComunidadPerfilCard(
      model: model,
      likeOpacity: isFrontCard ? _likeOpacityValue : 0.0,
      nopeOpacity: isFrontCard ? _nopeOpacityValue : 0.0,
      onLikeTap: isFrontCard ? () => _onLike(MediaQuery.sizeOf(context)) : () {},
      onNopeTap: isFrontCard ? () => _onNope(MediaQuery.sizeOf(context)) : () {},
      onReport: isFrontCard ? () => _mostrarDialogoReporte(model.nombre, model.uid) : () {},
      scrollController: isFrontCard ? _cardScrollController : null, // 🆕
    );
  }

  // ===========================================================================
  // 🖼️ BUILD
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: Text('Debes iniciar sesión', style: TextStyle(color: Colors.white))));
    }

    final Size screen = MediaQuery.sizeOf(context);
    final bool noMore = _deck.isEmpty || _topIndex >= _deck.length;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover)),

          Column(
            children: [
              const SizedBox(height: 45),
              SizedBox(height: 45, child: Image.asset('assets/images/logomatchyplano.png')),
              const SizedBox(height: 14),
              Expanded(
                child: (_isLoading && (_deck.isEmpty || _topIndex >= _deck.length))
                    ? const _ComunidadSpinner()
                    : Stack(
                  children: [
                    if (!noMore && _topIndex + 1 < _deck.length)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: _buildCardContent(_deck[_topIndex + 1], isFrontCard: false),
                        ),
                      ),

                    if (!noMore)
                      Positioned.fill(
                        child: RawGestureDetector(
                          behavior: HitTestBehavior.opaque,
                          gestures: {
                            HorizontalDragGestureRecognizer: GestureRecognizerFactoryWithHandlers<HorizontalDragGestureRecognizer>(
                                  () => HorizontalDragGestureRecognizer(),
                                  (HorizontalDragGestureRecognizer instance) {
                                instance
                                  ..onUpdate = _onHorizontalDragUpdate
                                  ..onEnd = (details) => _onHorizontalDragEnd(details, screen);
                              },
                            ),
                          },
                          child: Transform.translate(
                            offset: Offset(_dx, 0),
                            child: Transform.rotate(
                              angle: _rotationDeg * (math.pi / 180),
                              child: _buildCardContent(_deck[_topIndex], isFrontCard: true),
                            ),
                          ),
                        ),
                      ),

                    if (noMore && !_isLoading)
                      Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 30),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(color: Colors.black.withOpacity(0.38), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white24, width: 1)),
                          child: const Text('No hay más perfiles disponibles por ahora.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          // 🔥 LETREROS (visibles en toda la pantalla durante el arrastre)
          IgnorePointer(
            child: Stack(
              children: [
                Positioned(
                  left: 20, top: 110,
                  child: Opacity(
                    opacity: _likeOpacityValue,
                    child: Transform.rotate(
                      angle: -20 * (math.pi / 180),
                      child: const _ChoiceBadgeComunidad(text: 'ME INTERESA', borderColor: Color(0xFF63FF68), textColor: Color(0xFF63FF68)),
                    ),
                  ),
                ),
                Positioned(
                  right: 20, top: 110,
                  child: Opacity(
                    opacity: _nopeOpacityValue,
                    child: Transform.rotate(
                      angle: 20 * (math.pi / 180),
                      child: const _ChoiceBadgeComunidad(text: 'NO ME\nINTERESA', borderColor: Color(0xFFFF6E63), textColor: Color(0xFFFF6E63)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            top: 50, left: 16,
            child: GestureDetector(
              onTap: _backToPanel,
              child: Container(
                width: 42, height: 42,
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), shape: BoxShape.circle, border: Border.all(color: Colors.white24, width: 1)),
                child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 🎡 SPINNER DE CARGA
// ============================================================================
class _ComunidadSpinner extends StatelessWidget {
  const _ComunidadSpinner();

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
            "Buscando perfiles nuevos para ti...",
            style: TextStyle(color: Colors.white70, fontSize: 15, fontFamily: 'Poppins', fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 🏷️ LETRERO DE DECISIÓN
// ============================================================================
class _ChoiceBadgeComunidad extends StatelessWidget {
  final String text;
  final Color borderColor;
  final Color textColor;
  const _ChoiceBadgeComunidad({required this.text, required this.borderColor, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(border: Border.all(color: borderColor, width: 4), borderRadius: BorderRadius.circular(8)),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textColor, shadows: [Shadow(blurRadius: 10, color: Colors.black.withOpacity(0.30))]),
      ),
    );
  }
}

// ============================================================================
// 🔘 BOTÓN CIRCULAR DE ACCIÓN
// ============================================================================
class _CircleActionBtnComunidad extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double size;
  const _CircleActionBtnComunidad({required this.icon, required this.color, required this.onTap, required this.size});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(width: 70, alignment: Alignment.center, color: Colors.transparent, child: Icon(icon, color: color, size: size)),
    );
  }
}

// ============================================================================
// 💎 TARJETA DE VERIFICACIÓN BIOMÉTRICA
// ============================================================================
class _CardVerificacionBiometricaComunidad extends StatelessWidget {
  const _CardVerificacionBiometricaComunidad();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x33FFFFFF),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 3))],
        border: Border.all(color: const Color(0xFF00B4DB).withOpacity(0.5), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFF00B4DB).withOpacity(0.15), shape: BoxShape.circle),
            child: const Icon(Icons.verified, color: Color(0xFF00B4DB), size: 28),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Text(
              "Este perfil fue verificado con biometría facial ✔️",
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600, height: 1.3, fontFamily: 'Poppins'),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 👤 TARJETA DE PERFIL COMPLETO (idéntica visualmente a perfil_usuariox_screen.dart)
// ============================================================================
class _ComunidadPerfilCard extends StatelessWidget {
  final _ComunidadCardModel model;
  final double likeOpacity;
  final double nopeOpacity;
  final VoidCallback onLikeTap;
  final VoidCallback onNopeTap;
  final VoidCallback onReport;
  final ScrollController? scrollController; // 🆕

  const _ComunidadPerfilCard({
    required this.model,
    required this.likeOpacity,
    required this.nopeOpacity,
    required this.onLikeTap,
    required this.onNopeTap,
    required this.onReport,
    this.scrollController, // 🆕
  });

  bool get _estaBloqueado {
    if (model.userStatus == 'blocked' || model.userStatus == 'blocked_permanent') {
      if (model.bloqueadoHasta != null) return model.bloqueadoHasta!.isAfter(DateTime.now());
      return true;
    }
    return false;
  }

  DateTime? get _fechaTermometro {
    if (!_estaBloqueado) return null;
    return model.bloqueadoHasta ?? DateTime.now().add(Duration(days: model.strikes * 5 > 0 ? model.strikes * 5 : 1));
  }

  Widget _fallback() {
    return Container(color: const Color(0x33FFFFFF), child: const Center(child: Icon(Icons.person, color: Colors.white70, size: 70)));
  }

  Widget _buildImage(String? raw) {
    if (raw == null || raw.trim().isEmpty) return _fallback();
    final v = raw.trim();
    if (v.startsWith('http')) {
      return CachedNetworkImage(
        key: ValueKey(v),
        imageUrl: v,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        memCacheHeight: 1200,
        placeholder: (context, url) => Container(color: Colors.black26, child: const Center(child: CircularProgressIndicator(color: Color(0xFFBEB3FF), strokeWidth: 2))),
        errorWidget: (_, __, ___) => _fallback(),
      );
    }
    if (v.startsWith('assets/')) {
      return Image.asset(v, fit: BoxFit.cover, alignment: Alignment.topCenter, errorBuilder: (_, __, ___) => _fallback());
    }
    return _fallback();
  }

  Widget _galeriaFoto(String url) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 400,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))]),
      child: _buildImage(url),
    );
  }

  Widget _cardTexto(String titulo, String texto) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x33FFFFFF),
        borderRadius: BorderRadius.circular(20),
        boxShadow: _ComunidadScreenState.kChipShadow,
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(titulo, style: const TextStyle(color: Color(0xFFB3D9FF), fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Poppins', shadows: _ComunidadScreenState.kTextShadow)),
          ),
          const SizedBox(height: 8),
          Text(texto, style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Poppins')),
        ],
      ),
    );
  }

  List<List<String>> _buildRows(List<String> all) {
    final cleaned = all.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    final rows = <List<String>>[];
    int i = 0;
    while (i < cleaned.length) {
      final cur = cleaned[i];
      if (cur.length > _ComunidadScreenState.maxShortLength) { rows.add([cur]); i += 1; continue; }
      if (i + 1 < cleaned.length && cleaned[i + 1].length <= _ComunidadScreenState.maxShortLength) {
        rows.add([cur, cleaned[i + 1]]); i += 2;
      } else { rows.add([cur]); i += 1; }
    }
    return rows;
  }

  Widget _chip(String txt) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: EdgeInsets.symmetric(vertical: _ComunidadScreenState.chipPadV, horizontal: _ComunidadScreenState.chipPadH),
      decoration: BoxDecoration(color: const Color(0x66FFFFFF), borderRadius: BorderRadius.circular(50), boxShadow: _ComunidadScreenState.kChipShadow),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              txt,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white, fontSize: _ComunidadScreenState.chipFont, fontFamily: 'Poppins', fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardChips(String titulo, List<String> items) {
    if (items.isEmpty) return const SizedBox();
    final rows = _buildRows(items);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x33FFFFFF),
        borderRadius: BorderRadius.circular(20),
        boxShadow: _ComunidadScreenState.kChipShadow,
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(titulo, style: const TextStyle(color: Color(0xFFB3D9FF), fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Poppins', shadows: _ComunidadScreenState.kTextShadow)),
          ),
          const SizedBox(height: 10),
          Column(
            children: rows.map((fila) {
              if (fila.length == 1) return Row(children: [Expanded(child: _chip(fila[0]))]);
              return Row(
                children: [
                  Expanded(child: _chip(fila[0])),
                  const SizedBox(width: _ComunidadScreenState.gapX),
                  Expanded(child: _chip(fila[1])),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover)),
          SingleChildScrollView(
            controller: scrollController, // 🆕
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  height: _ComunidadScreenState.altoFotoPrincipal,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.45), blurRadius: 10, offset: const Offset(0, 6))],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      Positioned.fill(child: FotoPerfilUsuario(uid: model.uid, fit: BoxFit.cover, alignment: Alignment.topCenter)),
                      Positioned(
                        left: 0, right: 0, bottom: 0,
                        child: Container(height: 180, decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.95)]))),
                      ),
                      Positioned(
                        left: 30, bottom: 30, right: 30,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (model.isVerified)
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00B4DB).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: const Color(0xFF00B4DB), width: 1),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.verified, color: Color(0xFF00B4DB), size: 14),
                                      SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          "PERFIL VERIFICADO",
                                          style: TextStyle(color: Color(0xFF00B4DB), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.6, fontFamily: 'Poppins'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Row(
                                children: [
                                  Text(model.nombre, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'Poppins', shadows: _ComunidadScreenState.kTextShadow)),
                                  if (model.edad > 0) Text(', ${model.edad}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'Poppins', shadows: _ComunidadScreenState.kTextShadow)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(model.profesion.isEmpty ? '—' : model.profesion, style: const TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Poppins', shadows: _ComunidadScreenState.kTextShadow)),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                model.ciudad.isEmpty && model.pais.isEmpty
                                    ? 'Sin ubicación'
                                    : (model.ciudad.isNotEmpty && model.pais.isNotEmpty ? '${model.ciudad} - ${model.pais}' : (model.ciudad.isNotEmpty ? model.ciudad : model.pais)),
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Poppins', shadows: _ComunidadScreenState.kTextShadow),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                TermometroConfiabilidad(puntaje: model.puntaje, fechaDesbloqueo: _fechaTermometro, mostrarReloj: false),
                const SizedBox(height: 6),

                if (model.isVerified) const _CardVerificacionBiometricaComunidad(),

                _cardTexto('Biografía', model.bio.isEmpty ? '—' : model.bio),
                if (model.sobreMi.isNotEmpty) _cardChips('Sobre mí', model.sobreMi),
                if (model.galeria.length >= 2) _galeriaFoto(model.galeria[1]),
                if (model.busco.isNotEmpty) _cardChips('Busco...', model.busco),
                if (model.galeria.length >= 3) _galeriaFoto(model.galeria[2]),
                if (model.intereses.isNotEmpty) _cardChips('Intereses y Hobbies', model.intereses),
                if (model.galeria.length >= 4) _galeriaFoto(model.galeria[3]),
                _cardTexto('Un detalle que me enamora', model.detalle.isEmpty ? '—' : model.detalle),
                if (model.galeria.length >= 5) _galeriaFoto(model.galeria[4]),

                const SizedBox(height: 10),

                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  height: 64,
                  decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white12)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _CircleActionBtnComunidad(icon: Icons.close, color: Colors.white54, size: 30, onTap: onNopeTap),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.arrow_back_rounded, color: Color(0xFFFF6E63), size: 14),
                                SizedBox(width: 4),
                                Text("NO", style: TextStyle(color: Color(0xFFFF6E63), fontSize: 13, fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
                                Text("   -   ¿TE INTERESA?   -   ", style: TextStyle(color: Colors.white54, fontSize: 15, fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                                Text("SÍ", style: TextStyle(color: Color(0xFF00E676), fontSize: 13, fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward_rounded, color: Color(0xFF00E676), size: 14),
                              ],
                            ),
                          ),
                        ),
                      ),
                      _CircleActionBtnComunidad(icon: Icons.favorite, color: const Color(0xFF7E208E), size: 30, onTap: onLikeTap),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Center(
                  child: TextButton.icon(
                    onPressed: onReport,
                    icon: const Icon(Icons.flag_rounded, color: Colors.white54, size: 18),
                    label: const Text("¿Algo no está bien? Reportar perfil", style: TextStyle(color: Colors.white54, fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.bold)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.white12, width: 1)),
                      backgroundColor: Colors.white.withOpacity(0.05),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 📦 MODELO DE TARJETA (ahora con soporte para anuncios, idéntico a _CitaCardModel)
// ============================================================================
class _ComunidadCardModel {
  final bool isAd;
  final String adUrl;
  final String uid;
  final String nombre;
  final int edad;
  final String profesion;
  final String ciudad;
  final String pais;
  final String bio;
  final String detalle;
  final bool isVerified;
  final List<String> sobreMi;
  final List<String> busco;
  final List<String> intereses;
  final List<String> galeria;
  final int puntaje;
  final String generoOtro;
  final String prefOtro;
  final String userStatus;
  final int strikes;
  final DateTime? bloqueadoHasta;

  const _ComunidadCardModel({
    this.isAd = false,
    this.adUrl = '',
    required this.uid,
    required this.nombre,
    required this.edad,
    required this.profesion,
    required this.ciudad,
    required this.pais,
    required this.bio,
    required this.detalle,
    required this.isVerified,
    required this.sobreMi,
    required this.busco,
    required this.intereses,
    required this.galeria,
    required this.puntaje,
    required this.generoOtro,
    required this.prefOtro,
    required this.userStatus,
    required this.strikes,
    this.bloqueadoHasta,
  });

  factory _ComunidadCardModel.ad(String url, String idRealFirebase) {
    return _ComunidadCardModel(
      isAd: true,
      adUrl: url,
      uid: idRealFirebase,
      nombre: '',
      edad: 0,
      profesion: '',
      ciudad: '',
      pais: '',
      bio: '',
      detalle: '',
      isVerified: false,
      sobreMi: const [],
      busco: const [],
      intereses: const [],
      galeria: const [],
      puntaje: 100,
      generoOtro: '',
      prefOtro: '',
      userStatus: 'active',
      strikes: 0,
      bloqueadoHasta: null,
    );
  }
}

// ============================================================================
// 🛡️ DIÁLOGO DE REPORTE (idéntico a perfil_usuariox_screen.dart)
// ============================================================================
class _ReportDialogComunidad extends StatefulWidget {
  final String reportadoNombre;
  final String reportadoUid;
  final VoidCallback onSuccess;
  final Function(String) onError;

  const _ReportDialogComunidad({
    required this.reportadoNombre,
    required this.reportadoUid,
    required this.onSuccess,
    required this.onError,
  });

  @override
  State<_ReportDialogComunidad> createState() => _ReportDialogComunidadState();
}

class _ReportDialogComunidadState extends State<_ReportDialogComunidad> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _detailsCtrl = TextEditingController();

  String? _selectedCategory;
  bool _sending = false;

  final List<String> _categorias = [
    'Fotos falsas o robadas (Catfish).',
    'Comportamiento inapropiado o acoso.',
    'Parece ser menor de edad.',
    'Desnudos o imágenes de violencia y odio.',
    'Spam, publicidad o estafa.',
    'Otro.'
  ];

  bool get _isFormValid {
    return _nameCtrl.text.trim().isNotEmpty &&
        _emailCtrl.text.trim().isNotEmpty &&
        _selectedCategory != null &&
        _detailsCtrl.text.trim().length >= 30;
  }

  Future<void> _enviarReporte() async {
    if (!_isFormValid || _sending) return;

    setState(() => _sending = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final reporterUid = currentUser?.uid ?? 'Desconocido';
      final reporterEmailAuth = currentUser?.email ?? 'Sin correo registrado';

      String reporterNombreReal = 'Desconocido';
      try {
        final docUser = await FirebaseFirestore.instance.collection('users').doc(reporterUid).get();
        if (docUser.exists) {
          reporterNombreReal = docUser.data()?['nombre'] ?? 'Sin nombre';
        }
      } catch (_) {}

      final textoEstructurado = """
🚨 REPORTE DE PERFIL (Matchy Security - Comunidad)
Denunciado: ${widget.reportadoNombre}
UID Denunciado: ${widget.reportadoUid}

--- FIRMADO POR EL USUARIO (FORMULARIO) ---
Nombre dado: ${_nameCtrl.text.trim()}
Correo dado: ${_emailCtrl.text.trim()}

--- DATOS REALES DEL SISTEMA (LIE DETECTOR) ---
Nombre real en App: $reporterNombreReal
Correo real de Ingreso: $reporterEmailAuth
UID Denunciante: $reporterUid

--- EVIDENCIA ---
Motivo: $_selectedCategory
Detalles:
${_detailsCtrl.text.trim()}
""";

      await FirebaseFirestore.instance.collection('buzon_soporte').add({
        'uid': reporterUid,
        'email_usuario': _emailCtrl.text.trim(),
        'estado': 'pendiente',
        'to': 'matchyoficial@gmail.com',
        'message': {
          'subject': '🚨 ALERTA MATCHY: Reporte contra ${widget.reportadoNombre}',
          'text': textoEstructurado,
        }
      });

      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        widget.onError(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white24, width: 1),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, 10))],
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.shield_outlined, color: Color(0xFFFF5252), size: 40),
              const SizedBox(height: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  "REPORTAR A ${widget.reportadoNombre.toUpperCase()}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, fontFamily: 'Poppins'),
                ),
              ),
              const SizedBox(height: 20),

              _buildTextField(_nameCtrl, "Tu Nombre (Obligatorio)", Icons.person_outline),
              const SizedBox(height: 12),
              _buildTextField(_emailCtrl, "Tu Correo (Obligatorio)", Icons.email_outlined, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(15)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    dropdownColor: const Color(0xFF2A2A2A),
                    hint: const Text("Selecciona el motivo...", style: TextStyle(color: Colors.white54, fontSize: 14)),
                    value: _selectedCategory,
                    icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
                    items: _categorias.map((String cat) {
                      return DropdownMenuItem<String>(value: cat, child: Text(cat, style: const TextStyle(color: Colors.white, fontSize: 13)));
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedCategory = val),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _detailsCtrl,
                maxLines: 4,
                maxLength: 500,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Cuéntanos qué pasó (Mínimo 30 letras)...",
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.all(15),
                  counterText: '${_detailsCtrl.text.trim().length} / 500',
                  counterStyle: TextStyle(
                    color: _detailsCtrl.text.trim().length >= 30 ? const Color(0xFF00E676) : const Color(0xFFFF5252),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 15),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5252).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFF5252).withOpacity(0.3)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("⚠️ ", style: TextStyle(fontSize: 16)),
                    Expanded(
                      child: Text(
                        "Aviso de Seguridad: Un moderador humano revisará este caso detalladamente. Usar esta herramienta para dañar a otros por motivos personales, o falsas acusaciones, es una violación de nuestras reglas y causará la suspensión de tu propio perfil.",
                        style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _sending ? null : () => Navigator.pop(context),
                      child: const Text("CANCELAR", style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: _isFormValid && !_sending ? _enviarReporte : null,
                      child: Container(
                        height: 45,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: _isFormValid
                              ? const LinearGradient(colors: [Color(0xFFFF5252), Color(0xFFD50000)])
                              : LinearGradient(colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)]),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: _sending
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text("ENVIAR", style: TextStyle(color: _isFormValid ? Colors.white : Colors.white38, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, IconData icon, {TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white54, size: 20),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      ),
    );
  }
}