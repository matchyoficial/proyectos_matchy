// 📂 lib/screens/citas_pendientes_detalle.dart
// ✅ DETALLE CITA PENDIENTE (DISEÑO PREMIUM)
// 🔥 UI: Botón "BORRAR CITA" (Rojo suave).
// 🔥 LÓGICA: Borrado físico de la cita (delete) sin penalidad.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:proyectos_matchy/screens/panel_screen.dart';
import 'package:proyectos_matchy/screens/match_screen.dart';
import 'package:proyectos_matchy/screens/perfil_usuariox_screen.dart';
import 'package:proyectos_matchy/widgets/foto_perfil_usuario.dart';

// ============================================================
// FIRESTORE KEYS
// ============================================================
const String kCitasCollection = 'citas';
const String kCandidatosSubcol = 'candidatos';
const String kMatchysCollection = 'matchys';
const String kHistorialSubcol = 'historial';

const String kCandUid = 'uid';
const String kCandNombre = 'nombre';
const String kCandEdad = 'edad';
const String kCandFoto = 'foto';
const String kCandCreatedAt = 'createdAt';

const String kFechaField = 'fecha';
const String kHoraField = 'hora';
const String kPreferenciaField = 'preferencia';
const String kIntencionField = 'intencion';

const String kLugarField = 'lugar';
const String kLugarNombreField = 'nombre';
const String kLugarDireccionField = 'direccion';
const String kLugarFotoPortadaField = 'fotoPortada';

const String kUsersCollection = 'users';

// ===========================================================================
// 🔴🔴 ZONA DE CHINCHES MAESTROS (DISEÑO PREMIUM) 🔴🔴
// ===========================================================================

// 1. LOGO
const double kLogoHeight = 45.0;
const double kLogoTopSpace = 35.0;

// 2. SOMBRAS Y BORDES
const List<BoxShadow> kCardShadow = [BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 5))];
const List<BoxShadow> kCapsuleShadow = [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))];
const BorderSide kPremiumBorder = BorderSide(color: Colors.white24, width: 1);

// 3. BOTONES
const List<Color> kButtonGradientBack = [Color(0xFF2E2E4D), Color(0xFF1A1A24)];
// 🔥 CAMBIO: Rojo suave para borrar (No penaliza)
const List<Color> kButtonGradientDelete = [Color(0xFFEF5350), Color(0xFFE57373)];

const double kButtonRadius = 25.0;
const List<BoxShadow> kButtonShadow = [BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 4))];

// 4. TEXTOS
const List<Shadow> kTextShadow = [Shadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 4)];

// ============================================================
// MODELOS
// ============================================================
class _CitaFS {
  final String docId;
  final String nombreLugar;
  final String direccionLugar;
  final String fotoLugar;
  final String fecha;
  final String hora;
  final String preferencia;
  final String intencion;

  const _CitaFS({
    required this.docId,
    required this.nombreLugar,
    required this.direccionLugar,
    required this.fotoLugar,
    required this.fecha,
    required this.hora,
    required this.preferencia,
    required this.intencion,
  });
}

class _CandidatoFS {
  final String uid;
  final String nombre;
  final int edad;
  final String foto;

  const _CandidatoFS({
    required this.uid,
    required this.nombre,
    required this.edad,
    required this.foto,
  });

  static _CandidatoFS fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    int edad = 0;
    final e = data[kCandEdad];
    if (e is int) edad = e;
    if (e is String) edad = int.tryParse(e) ?? 0;

    return _CandidatoFS(
      uid: (data[kCandUid] ?? doc.id).toString().trim(),
      nombre: (data[kCandNombre] ?? '').toString().trim(),
      edad: edad,
      foto: (data[kCandFoto] ?? '').toString().trim(),
    );
  }
}

// ============================================================
// SCREEN
// ============================================================
class CitasPendientesDetalleScreen extends ConsumerStatefulWidget {
  final String citaId;
  const CitasPendientesDetalleScreen({super.key, required this.citaId});

  @override
  ConsumerState<CitasPendientesDetalleScreen> createState() =>
      _CitasPendientesDetalleScreenState();
}

class _CitasPendientesDetalleScreenState
    extends ConsumerState<CitasPendientesDetalleScreen> {

  bool _busy = false;
  _CitaFS? _cita;

  // Cacheamos el stream para evitar recreaciones
  Stream<QuerySnapshot<Map<String, dynamic>>>? _candidatosStreamCache;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _cargarCita();
    });
    // Inicializamos el stream una sola vez
    _candidatosStreamCache = FirebaseFirestore.instance
        .collection(kCitasCollection)
        .doc(widget.citaId)
        .collection(kCandidatosSubcol)
        .orderBy(kCandCreatedAt, descending: true)
        .limit(40)
        .snapshots();
  }

  void _goBackToPanel() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const PanelScreen()),
          (r) => false,
    );
  }

  String _s(dynamic v) => v is String ? v : (v?.toString() ?? '');
  int _i(dynamic v) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  Future<void> _cargarCita() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(kCitasCollection)
          .doc(widget.citaId)
          .get();

      if (!doc.exists) {
        setState(() => _cita = null);
        return;
      }
      final data = doc.data() ?? {};

      final nombreRoot = _s(data['lugarNombre']).trim();
      final dirRoot = _s(data['lugarDireccion']).trim();
      final fotoRoot = _s(data['lugarFotoPortada']).trim();

      final lugarMap = (data[kLugarField] is Map)
          ? Map<String, dynamic>.from(data[kLugarField] as Map)
          : <String, dynamic>{};
      final nombreViejo = _s(lugarMap[kLugarNombreField]).trim();
      final dirViejo = _s(lugarMap[kLugarDireccionField]).trim();
      final fotoVieja = _s(lugarMap[kLugarFotoPortadaField]).trim();

      final nombreFinal = nombreRoot.isNotEmpty ? nombreRoot : nombreViejo;
      final dirFinal = dirRoot.isNotEmpty ? dirRoot : dirViejo;
      final fotoFinal = fotoRoot.isNotEmpty
          ? fotoRoot
          : fotoVieja.isNotEmpty
          ? fotoVieja
          : 'assets/images/perfil1.jpg';

      setState(() {
        _cita = _CitaFS(
          docId: doc.id,
          nombreLugar: nombreFinal,
          direccionLugar: dirFinal,
          fotoLugar: fotoFinal,
          fecha: _s(data[kFechaField]).trim(),
          hora: _s(data[kHoraField]).trim(),
          preferencia: _s(data[kPreferenciaField]).trim(),
          intencion: _s(data[kIntencionField]).trim(),
        );
      });
    } catch (_) {
      setState(() => _cita = null);
    }
  }

  // 🔥 LÓGICA DE BORRADO AUTOMÁTICO (RELOJ)
  Future<void> _cancelarAuto() async {
    // Si el reloj llega a cero, borramos la cita físicamente
    await FirebaseFirestore.instance
        .collection(kCitasCollection)
        .doc(widget.citaId)
        .delete();

    if (!mounted) return;
    _goBackToPanel();
  }

  // Helper de hidratación (se mantiene pero no afecta UI loop)
  Future<_CandidatoFS> _hydrateCandidateFromUsers(_CandidatoFS c) async {
    final hasName = c.nombre.trim().isNotEmpty;
    final hasAge = c.edad > 0;
    final hasPhoto = c.foto.trim().isNotEmpty;
    if (hasName && hasAge && hasPhoto) return c;

    try {
      final snap = await FirebaseFirestore.instance.collection(kUsersCollection).doc(c.uid).get();
      if (!snap.exists) return c;
      final data = snap.data() ?? {};

      String nombre = _s(data['nombre']).trim();
      if (nombre.isEmpty) nombre = _s(data['displayName']).trim();

      final int edad = _i(data['edad']);

      String foto = _s(data['profilePhotoUrl']).trim();
      if (foto.isEmpty) foto = _s(data['foto']).trim();
      if (foto.isEmpty) foto = _s(data['fotoPerfil']).trim();

      return _CandidatoFS(
        uid: c.uid,
        nombre: hasName ? c.nombre : nombre,
        edad: hasAge ? c.edad : edad,
        foto: hasPhoto ? c.foto : foto,
      );
    } catch (_) {
      return c;
    }
  }

  Future<void> _hacerMatchyFlow({
    required _CandidatoFS c,
    required _CitaFS cita,
  }) async {
    if (_busy) return;
    setState(() => _busy = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final db = FirebaseFirestore.instance;
    final citaRef = db.collection(kCitasCollection).doc(cita.docId);

    final matchyId = '${user.uid}__${c.uid}';
    final matchyRef = db.collection(kMatchysCollection).doc(matchyId);
    final historialRef = matchyRef.collection(kHistorialSubcol).doc();

    final myMatchyRef = db.collection('users').doc(user.uid).collection('my_matchys').doc(c.uid);
    final otherMatchyRef = db.collection('users').doc(c.uid).collection('my_matchys').doc(user.uid);

    try {
      final cFull = await _hydrateCandidateFromUsers(c);

      final myUserSnap = await db.collection('users').doc(user.uid).get();
      final myData = myUserSnap.data() ?? {};
      final myName = _s(myData['nombre']);
      final myAge = _i(myData['edad']);
      final myPhoto = _s(myData['profilePhotoUrl']);

      await db.runTransaction((tx) async {
        final citaSnap = await tx.get(citaRef);
        if (!citaSnap.exists) throw Exception('La cita no existe');

        final status = (citaSnap.data()?['status'] ?? '').toString();
        if (status != 'online') throw Exception('La cita ya fue cerrada');

        tx.update(citaRef, {
          'status': 'matched',
          'matchyUid': cFull.uid,
          'matchyNombre': cFull.nombre,
          'matchyEdad': cFull.edad,
          'matchyFoto': cFull.foto,
          'matchySelectedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        tx.set(matchyRef, {
          'ownerUid': user.uid,
          'candidatoUid': cFull.uid,
          'lastCitaAt': FieldValue.serverTimestamp(),
          'citasCount': FieldValue.increment(1),
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        tx.set(historialRef, {
          'citaId': cita.docId,
          'fechaHora': '${cita.fecha} ${cita.hora}',
          'lugarNombre': cita.nombreLugar,
          'lugarDireccion': cita.direccionLugar,
          'lugarFotoPortada': cita.fotoLugar,
          'createdAt': FieldValue.serverTimestamp(),
        });

        tx.set(myMatchyRef, {
          'nombre': cFull.nombre,
          'edad': cFull.edad,
          'fotoUrl': cFull.foto,
          'matchId': matchyId,
          'lastInteraction': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        tx.set(otherMatchyRef, {
          'nombre': myName,
          'edad': myAge,
          'fotoUrl': myPhoto,
          'matchId': matchyId,
          'lastInteraction': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

      });

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MatchScreen(
            candidatoId: cFull.uid,
            candidatoNombre: cFull.nombre,
            candidatoEdad: cFull.edad,
            candidatoFotoAsset: cFull.foto.isEmpty ? 'assets/images/perfil1.jpg' : cFull.foto,
            citaId: cita.docId,
            lugarNombre: cita.nombreLugar,
            lugarFoto: cita.fotoLugar,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error cerrando la cita: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // Formateador manual para asegurar español
  String _fechaLarga(String fechaCorta) {
    try {
      final f = fechaCorta.split('/');
      final d = int.parse(f[0]);
      final m = int.parse(f[1]);
      final y = int.parse(f[2]);
      final dt = DateTime(y, m, d);
      const dias = ['lunes','martes','miércoles','jueves','viernes','sábado','domingo'];
      const meses = ['enero','febrero','marzo','abril','mayo','junio','julio','agosto','septiembre','octubre','noviembre','diciembre'];
      return "${dias[dt.weekday - 1]} $d de ${meses[m - 1]} $y";
    } catch (_) { return fechaCorta; }
  }

  @override
  Widget build(BuildContext context) {
    final cita = _cita;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. FONDO
          Positioned.fill(child: Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover)),

          Column(
            children: [
              const SizedBox(height: kLogoTopSpace),
              SizedBox(height: kLogoHeight, child: Image.asset('assets/images/logomatchyplano.png')),
              const SizedBox(height: 14),
              Expanded(child: cita == null ? _buildError() : _buildDetalle(cita)),
            ],
          ),

          // 2. 🔥 DEGRADADO INFERIOR (FADE OUT)
          Positioned(
            bottom: 0, left: 0, right: 0, height: 90,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.95)],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 90),
      child: Column(
        children: [
          const SizedBox(height: 18),
          _box('❌ No pude cargar la cita.'),
          const SizedBox(height: 16),
          _PremiumButton(
            text: 'VOLVER AL PANEL',
            gradient: kButtonGradientBack,
            onTap: _goBackToPanel,
          ),
        ],
      ),
    );
  }

  Widget _buildDetalle(_CitaFS cita) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // FOTO CON SOMBRA
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: kCardShadow,
            ),
            child: _fotoLugar(cita.fotoLugar),
          ),
          const SizedBox(height: 20),

          // 🔥 TITULO CENTRADO CON SOMBRA
          Text(
            cita.nombreLugar.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              fontFamily: 'Poppins',
              shadows: kTextShadow,
              letterSpacing: 0.5,
            ),
          ),

          const SizedBox(height: 6),

          // 🔥 DIRECCIÓN
          Text(
            cita.direccionLugar,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 19,
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
              shadows: kTextShadow,
            ),
          ),

          const SizedBox(height: 25),

          // 🔥 FECHA GRANDE FORMATO LARGO
          Text(
            _fechaLarga(cita.fecha).toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFF8F7FA),
              fontSize: 22,
              fontWeight: FontWeight.w900,
              fontFamily: 'Poppins',
              shadows: kTextShadow,
            ),
          ),

          // 🔥 HORA DEBAJO
          Text(
            cita.hora,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
              shadows: kTextShadow,
            ),
          ),

          const SizedBox(height: 15),

          // 🔥 CHIPS ABAJO
          Row(
              children: [
                Expanded(child: _infoChip(icon: '🎯', text: cita.intencion)),
                const SizedBox(width: 10),
                Expanded(child: _infoChip(icon: '👥', text: cita.preferencia))
              ]
          ),

          const SizedBox(height: 25),

          // 🔥 RELOJ AISLADO (SIN PARPADEO)
          _RelojPremium(
            fecha: cita.fecha,
            hora: cita.hora,
            nombreLugar: cita.nombreLugar,
            onCancel: _cancelarAuto,
          ),

          const SizedBox(height: 30),

          const Text(
            '¿CON QUIÉN QUIERES IR A TU CITA?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              fontFamily: 'Poppins',
              shadows: kTextShadow,
            ),
          ),

          const SizedBox(height: 15),

          // GRIDVIEW (El stream se crea una vez en initState para evitar flicker)
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _candidatosStreamCache,
            builder: (_, snap) {
              if (snap.hasError) return _box('❌ Error cargando candidatos.');
              if (!snap.hasData) return const Padding(padding: EdgeInsets.symmetric(vertical: 18), child: Center(child: CircularProgressIndicator()));
              final docs = snap.data!.docs;
              if (docs.isEmpty) return _box('Aún no hay candidatos.\nCuando alguien haga swipe a la derecha, aparecerá aquí.', soft: true);

              final candidatos = docs.map(_CandidatoFS.fromDoc).toList();

              // GRID directo sin FutureBuilder envolvente
              return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: candidatos.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.86),
                  itemBuilder: (_, i) {
                    return _CandidatoCard(
                        candidato: candidatos[i],
                        busy: _busy,
                        onTapFoto: () => _openPerfil(candidatos[i].uid),
                        onMatchy: () async => await _hacerMatchyFlow(c: candidatos[i], cita: _cita!)
                    );
                  }
              );
            },
          ),

          const SizedBox(height: 30),

          // 🔥 BOTÓN VOLVER
          _PremiumButton(
            text: 'VOLVER AL PANEL',
            gradient: kButtonGradientBack,
            onTap: _goBackToPanel,
          ),

          const SizedBox(height: 12),

          // 🔥 BOTÓN BORRAR (CAMBIO CLAVE)
          _PremiumButton(
            text: 'BORRAR CITA',
            gradient: kButtonGradientDelete, // Color suave
            onTap: () async {
              // 🔥 LÓGICA DE BORRADO FÍSICO (DELETE)
              await FirebaseFirestore.instance.collection(kCitasCollection).doc(cita.docId).delete();

              if (!mounted) return;
              _goBackToPanel();
            },
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _openPerfil(String uid) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PerfilUsuarioXScreen(uid: uid)));
  bool _isNetwork(String v) => v.startsWith('http://') || v.startsWith('https://');
  Widget _fotoLugar(String v) {
    final src = v.trim();
    Widget w = (src.isEmpty) ? Image.asset('assets/images/perfil1.jpg', fit: BoxFit.cover) : (_isNetwork(src) ? Image.network(src, fit: BoxFit.cover, errorBuilder: (_,__,___) => Image.asset('assets/images/perfil1.jpg', fit: BoxFit.cover)) : Image.asset(src, fit: BoxFit.cover, errorBuilder: (_,__,___) => Image.asset('assets/images/perfil1.jpg', fit: BoxFit.cover)));
    return Container(height: 190, clipBehavior: Clip.antiAlias, decoration: BoxDecoration(borderRadius: BorderRadius.circular(22)), child: w);
  }
  Widget _box(String t, {bool soft = false}) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0x33FFFFFF), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white12)), child: Text(t, textAlign: TextAlign.center, style: TextStyle(color: soft ? Colors.white70 : Colors.white, fontFamily: 'Poppins', fontWeight: FontWeight.w700)));

  Widget _infoChip({required String icon, required String text}) {
    final t = text.trim().isEmpty ? '—' : text.trim();
    return Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0x33FFFFFF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: kPremiumBorder.color, width: 0.5),
          boxShadow: kCapsuleShadow,
        ),
        child: Column(
            children: [
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 4),
              Text(
                  t.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Poppins')
              )
            ]
        )
    );
  }
}

// -----------------------------------------------------------
// 🔥 WIDGET RELOJ AISLADO (SIN PARPADEO)
// -----------------------------------------------------------
class _RelojPremium extends StatefulWidget {
  final String fecha;
  final String hora;
  final String nombreLugar;
  final VoidCallback onCancel;

  const _RelojPremium({required this.fecha, required this.hora, required this.nombreLugar, required this.onCancel});

  @override
  State<_RelojPremium> createState() => _RelojPremiumState();
}

class _RelojPremiumState extends State<_RelojPremium> {
  Timer? _timer;
  Duration _restante = Duration.zero;
  bool _alerta1hMostrada = false;

  @override
  void initState() {
    super.initState();
    _actualizar();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _actualizar();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _actualizar() {
    final dt = _parse(widget.fecha, widget.hora);
    if (dt == null) return;
    final limite = dt.subtract(const Duration(hours: 12));
    final now = DateTime.now();
    final diff = limite.difference(now);

    if (!_alerta1hMostrada && diff <= const Duration(hours: 1) && diff > Duration.zero) {
      _alerta1hMostrada = true;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Te queda 1 hora para escoger tu matchy en la cita del ${widget.nombreLugar}")));
    }
    if (diff.isNegative || diff == Duration.zero) {
      widget.onCancel();
    }
    setState(() {
      _restante = diff.isNegative ? Duration.zero : diff;
    });
  }

  DateTime? _parse(String fecha, String hora) {
    try {
      final f = fecha.split('/');
      if (f.length != 3) return null;
      final day = int.parse(f[0]);
      final month = int.parse(f[1]);
      final year = int.parse(f[2]);
      final upper = hora.toUpperCase();
      final isPM = upper.contains('PM');
      final clean = upper.replaceAll('AM', '').replaceAll('PM', '').trim();
      final hm = clean.split(':');
      int h = int.parse(hm[0]);
      int m = int.parse(hm[1]);
      if (isPM) { if (h != 12) h += 12; } else { if (h == 12) h = 0; }
      return DateTime(year, month, day, h, m);
    } catch (_) { return null; }
  }

  String _fmt(Duration d) {
    final s = d.inSeconds;
    final h = (s ~/ 3600).toString().padLeft(2, '0');
    final m = ((s % 3600) ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$h:$m:$ss';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(colors: [Color(0x88FF4081), Color(0x88FF5252)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        border: Border.all(color: Colors.white24, width: 1),
        boxShadow: kCardShadow,
      ),
      child: Column(
          children: [
            Text(
                _fmt(_restante),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                  letterSpacing: 2.0,
                  shadows: kTextShadow,
                )
            ),
            const SizedBox(height: 6),
            const Text(
                'TIEMPO PARA ELEGIR TU MATCHY',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Poppins',
                  letterSpacing: 1.0,
                )
            )
          ]
      ),
    );
  }
}

class _PremiumButton extends StatelessWidget {
  final String text;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _PremiumButton({required this.text, required this.gradient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 55,
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradient),
          borderRadius: BorderRadius.circular(kButtonRadius),
          boxShadow: kButtonShadow,
          border: Border.all(color: Colors.white24, width: 1),
        ),
        alignment: Alignment.center,
        child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900, fontFamily: 'Poppins', letterSpacing: 0.5)
        ),
      ),
    );
  }
}

class _CandidatoCard extends StatelessWidget {
  final _CandidatoFS candidato;
  final Future<void> Function() onMatchy;
  final VoidCallback onTapFoto;
  final bool busy;
  const _CandidatoCard({required this.candidato, required this.onMatchy, required this.onTapFoto, required this.busy});

  // 🔥 USO DEL WIDGET INTELIGENTE (No parpadea gracias a que el padre no se reconstruye)
  Widget _buildImage() {
    return FotoPerfilUsuario(
      uid: candidato.uid,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
    );
  }

  @override
  Widget build(BuildContext context) {
    const double radio = 18;
    const double altoBoton = 36;
    final nombre = candidato.nombre.trim().isNotEmpty ? candidato.nombre : 'Sin nombre';
    final edadTxt = candidato.edad > 0 ? ', ${candidato.edad}' : '';
    return Column(children: [
      Expanded(
          child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(radio),
              child: InkWell(
                  borderRadius: BorderRadius.circular(radio),
                  onTap: onTapFoto,
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(radio),
                      child: Stack(
                          children: [
                            Positioned.fill(child: _buildImage()),
                            Positioned(bottom: 0, left: 0, right: 0, height: 70, child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, Colors.black.withOpacity(0.9)], begin: Alignment.topCenter, end: Alignment.bottomCenter)))),
                            Positioned(bottom: 10, left: 10, right: 10, child: Text('$nombre$edadTxt', maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, fontFamily: 'Poppins', shadows: kTextShadow)))
                          ]
                      )
                  )
              )
          )
      ),
      const SizedBox(height: 8),
      SizedBox(
          width: double.infinity,
          height: altoBoton,
          child: ElevatedButton(
              onPressed: busy ? null : () async => await onMatchy(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC107),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 4,
                shadowColor: Colors.black54,
              ),
              child: busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) : const Text('HACER MATCHY', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w900, fontFamily: 'Poppins'))
          )
      )
    ]);
  }
}