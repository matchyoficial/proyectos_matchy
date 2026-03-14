// 📂 lib/screens/citas_pendientes_detalle.dart
// ✅ DISEÑO "MATCHY EVENT STYLE" (CORREGIDO Y FINAL)
// 🔥 FIX ERROR: kGoldBtn1 ahora es visible para todos los widgets.
// 🔥 UI: Título centrado, Reloj Neón estilo "Sin Bloqueo", Sombras Premium.
// 🔥 UI: Cápsula adaptable, Letrero de "Aún no hay postulados" incluido.
// 🚀 NEW LOGIC: Spinner aislado (Solo carga el candidato seleccionado).
// 🚀 NEW UI: Efecto "¡ES TU MATCHY!" inyectado en la foto al seleccionar.
// 🎫 STATUS: Destino oficial de Notificaciones Golden Ticket.
// 🧹 FIX: Limpieza automática de notificaciones al hacer Matchy.
// 🛠️ FIX FECHA: Cálculo dinámico del día de la semana para evitar "Jueves" fijo.

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:proyectos_matchy/screens/panel_screen.dart';
import 'package:proyectos_matchy/screens/match_screen.dart';
import 'package:proyectos_matchy/screens/perfil_usuariox_screen.dart';
import 'package:proyectos_matchy/widgets/foto_perfil_usuario.dart';

// ============================================================
// 🛡️ ZONA DE CHINCHES MAESTROS (CONFIGURACIÓN VISUAL)
// ============================================================

// 1. DIMENSIONES
const double kLogoHeight = 45.0;          // Altura del logo
const double kCardLugarHeight = 170.0;    // Altura tarjeta lugar
const double kAvatarRadius = 15.0;        // Redondeo fotos candidatos

// 2. COLORES PALETA "EVENT STYLE"
const Color kNeonGreen = Color(0xFF76FF03);       // Verde neón reloj
const Color kPurpleContainer = Color(0xFF4A3485); // Fondo morado cápsula
const Color kCapsulaTituloBg = Color(0xFFFFC107); // Amarillo título
const Color kDarkBg = Color(0xFF6B31B3);          // Fondo oscuro
const Color kGlassBg = Color(0xFF111111);         // Fondo reloj
const Color kGoldBtn1 = Color(0xFFFFC107);        // Dorado Principal (Para sombras y gradientes)
const Color kGoldBtn2 = Color(0xFFFFD54F);        // Dorado Claro

// 3. GRADIENTES
const List<Color> kBtnGoldGradient = [kGoldBtn1, kGoldBtn2];
const List<Color> kBtnBackGradient = [Color(0xFF2E2E4D), Color(0xFF491351)];
const List<Color> kBtnDeleteGradient = [Color(0xFFEF5350), Color(0xFFE57373)];

// 4. SOMBRAS PREMIUM
const List<BoxShadow> kPremiumBoxShadow = [
  BoxShadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 4), spreadRadius: 1)
];
const List<BoxShadow> kNeonGlowShadow = [
  BoxShadow(color: kNeonGreen, blurRadius: 10, offset: Offset(0, 0), spreadRadius: -2),
  BoxShadow(color: Colors.black87, blurRadius: 12, offset: Offset(0, 6), spreadRadius: 1)
];
const List<Shadow> kTextShadowStrong = [
  Shadow(color: Colors.black, blurRadius: 6, offset: Offset(0, 2))
];

// ============================================================
// FIRESTORE KEYS
// ============================================================
const String kCitasCollection = 'citas';
const String kCandidatosSubcol = 'candidatos';
const String kMatchysCollection = 'matchys';
const String kHistorialSubcol = 'historial';
const String kUsersCollection = 'users';

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
    required this.docId, required this.nombreLugar, required this.direccionLugar,
    required this.fotoLugar, required this.fecha, required this.hora,
    required this.preferencia, required this.intencion,
  });
}

class _CandidatoFS {
  final String uid;
  final String nombre;
  final int edad;
  final String foto;
  const _CandidatoFS({required this.uid, required this.nombre, required this.edad, required this.foto});

  static _CandidatoFS fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    int edad = 0;
    final e = data['edad'];
    if (e is int) edad = e;
    if (e is String) edad = int.tryParse(e) ?? 0;
    return _CandidatoFS(
      uid: (data['uid'] ?? doc.id).toString().trim(),
      nombre: (data['nombre'] ?? '').toString().trim(),
      edad: edad,
      foto: (data['foto'] ?? '').toString().trim(),
    );
  }
}

class CitasPendientesDetalleScreen extends ConsumerStatefulWidget {
  final String citaId;
  const CitasPendientesDetalleScreen({super.key, required this.citaId});

  @override
  ConsumerState<CitasPendientesDetalleScreen> createState() => _CitasPendientesDetalleScreenState();
}

class _CitasPendientesDetalleScreenState extends ConsumerState<CitasPendientesDetalleScreen> with SingleTickerProviderStateMixin {

  // 🔥 NUEVA VARIABLE: En vez de un booleano global, guardamos quién fue seleccionado
  String? _candidatoSeleccionadoId;

  _CitaFS? _cita;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _candidatosStreamCache;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _cargarCita();
    });
    _candidatosStreamCache = FirebaseFirestore.instance
        .collection(kCitasCollection).doc(widget.citaId)
        .collection(kCandidatosSubcol).orderBy('createdAt', descending: true).limit(40).snapshots();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _goBackToPanel() {
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const PanelScreen()), (r) => false);
  }

  String _s(dynamic v) => v is String ? v : (v?.toString() ?? '');

  Future<void> _cargarCita() async {
    try {
      final doc = await FirebaseFirestore.instance.collection(kCitasCollection).doc(widget.citaId).get();
      if (!doc.exists) { setState(() => _cita = null); return; }
      final data = doc.data() ?? {};

      final sedeNombre = _s(data['sedeNombre']).trim();
      final sedeDireccion = _s(data['sedeDireccion']).trim();
      final nombreRoot = _s(data['lugarNombre']).trim();
      final dirRoot = _s(data['lugarDireccion']).trim();
      final fotoRoot = _s(data['lugarFotoPortada']).trim();
      final lugarMap = (data['lugar'] is Map) ? Map<String, dynamic>.from(data['lugar'] as Map) : <String, dynamic>{};

      final nombreFinal = sedeNombre.isNotEmpty ? sedeNombre : (nombreRoot.isNotEmpty ? nombreRoot : _s(lugarMap['nombre']));
      final dirFinal = sedeDireccion.isNotEmpty ? sedeDireccion : (dirRoot.isNotEmpty ? dirRoot : _s(lugarMap['direccion']));
      final fotoFinal = fotoRoot.isNotEmpty ? fotoRoot : (_s(lugarMap['fotoPortada']).isNotEmpty ? _s(lugarMap['fotoPortada']) : 'assets/images/perfil1.jpg');

      setState(() {
        _cita = _CitaFS(
          docId: doc.id, nombreLugar: nombreFinal, direccionLugar: dirFinal, fotoLugar: fotoFinal,
          fecha: _s(data['fecha']).trim(), hora: _s(data['hora']).trim(),
          preferencia: _s(data['preferencia']).trim(), intencion: _s(data['intencion']).trim(),
        );
      });
    } catch (_) { setState(() => _cita = null); }
  }

  Future<_CandidatoFS> _hydrateCandidateFromUsers(_CandidatoFS c) async {
    if (c.nombre.isNotEmpty && c.edad > 0 && c.foto.isNotEmpty) return c;
    try {
      final snap = await FirebaseFirestore.instance.collection(kUsersCollection).doc(c.uid).get();
      final d = snap.data() ?? {};
      return _CandidatoFS(
        uid: c.uid,
        nombre: c.nombre.isNotEmpty ? c.nombre : (_s(d['nombre']).isNotEmpty ? _s(d['nombre']) : 'Usuario'),
        edad: c.edad > 0 ? c.edad : (d['edad'] is int ? d['edad'] : 0),
        foto: c.foto.isNotEmpty ? c.foto : (_s(d['profilePhotoUrl']).isNotEmpty ? _s(d['profilePhotoUrl']) : ''),
      );
    } catch (_) { return c; }
  }

  Future<void> _hacerMatchyFlow({required _CandidatoFS c, required _CitaFS cita}) async {
    if (_candidatoSeleccionadoId != null) return; // Prevenir doble toque

    setState(() => _candidatoSeleccionadoId = c.uid); // 🔥 Activamos el spinner solo en este candidato

    final user = FirebaseAuth.instance.currentUser; if (user == null) return;
    final db = FirebaseFirestore.instance;

    try {
      final cFull = await _hydrateCandidateFromUsers(c);
      final mySnap = await db.collection(kUsersCollection).doc(user.uid).get();
      final myData = mySnap.data() ?? {};

      await db.runTransaction((tx) async {
        final cRef = db.collection(kCitasCollection).doc(cita.docId);
        final cSnap = await tx.get(cRef);
        if (!cSnap.exists || cSnap.data()?['status'] != 'online') throw Exception('Cita no disponible');

        tx.update(cRef, {
          'status': 'matched',
          'matchyUid': cFull.uid, 'matchyNombre': cFull.nombre, 'matchyEdad': cFull.edad, 'matchyFoto': cFull.foto,
          'matchySelectedAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp()
        });

        final mId = '${user.uid}__${c.uid}';
        tx.set(db.collection(kMatchysCollection).doc(mId), {'ownerUid': user.uid, 'candidatoUid': cFull.uid, 'lastCitaAt': FieldValue.serverTimestamp(), 'citasCount': FieldValue.increment(1)}, SetOptions(merge: true));
        tx.set(db.collection(kMatchysCollection).doc(mId).collection(kHistorialSubcol).doc(), {'citaId': cita.docId, 'lugarNombre': cita.nombreLugar, 'fechaHora': '${cita.fecha} ${cita.hora}', 'createdAt': FieldValue.serverTimestamp()});

        tx.set(db.collection('users').doc(user.uid).collection('my_matchys').doc(c.uid), {'nombre': cFull.nombre, 'edad': cFull.edad, 'fotoUrl': cFull.foto, 'matchId': mId, 'lastInteraction': FieldValue.serverTimestamp()}, SetOptions(merge: true));
        tx.set(db.collection('users').doc(c.uid).collection('my_matchys').doc(user.uid), {'nombre': _s(myData['nombre']), 'edad': myData['edad'] ?? 0, 'fotoUrl': _s(myData['profilePhotoUrl']), 'matchId': mId, 'lastInteraction': FieldValue.serverTimestamp()}, SetOptions(merge: true));
      });

      // 🔥 FIX: LIMPIEZA AUTOMÁTICA DE NOTIFICACIONES (Golden Tickets)
      try {
        final notifsSnap = await db.collection(kUsersCollection).doc(user.uid)
            .collection('notifications')
            .where('citaId', isEqualTo: cita.docId)
            .get();

        for (final doc in notifsSnap.docs) {
          await doc.reference.delete();
        }
      } catch (_) {
        // Fallo silencioso en limpieza, no afecta el flujo principal
      }

      if (!mounted) return;

      // Pequeño delay opcional para que el usuario disfrute el letrero "Es tu matchy" un segundito más
      await Future.delayed(const Duration(milliseconds: 600));

      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => MatchScreen(
          candidatoId: cFull.uid, candidatoNombre: cFull.nombre, candidatoEdad: cFull.edad, candidatoFotoAsset: cFull.foto,
          citaId: cita.docId, lugarNombre: cita.nombreLugar, lugarFoto: cita.fotoLugar, soyElOwner: true
      )));

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _candidatoSeleccionadoId = null);
    }
  }

  // POPUP INFO
  void _showPlaceDetailPopup(_CitaFS cita) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(color: const Color(0xFF2A1860), borderRadius: BorderRadius.circular(25), boxShadow: kPremiumBoxShadow),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 180, width: double.infinity,
                  child: Image.network(cita.fotoLugar, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(color: Colors.grey)),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(cita.nombreLugar.toUpperCase(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, fontFamily: 'Poppins')),
                      const SizedBox(height: 8),
                      Text(cita.direccionLugar, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 15, fontFamily: 'Poppins')),
                      const SizedBox(height: 25),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _PopupInfoItem(icon: Icons.star, label: "INTENCIÓN", value: cita.intencion),
                          _PopupInfoItem(icon: Icons.favorite, label: "INTERÉS", value: cita.preferencia),
                        ],
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: 150,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6B4EE6), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), elevation: 5),
                          child: const Text("CERRAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🛡️ BLINDAJE ANTI-DEFORMACIÓN
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Fondo
            Positioned.fill(child: Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover)),

            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.black45, shape: BoxShape.circle, border: Border.all(color: Colors.white24), boxShadow: kPremiumBoxShadow), child: const Icon(Icons.chevron_left, color: Colors.white, size: 26)),
                        ),
                        Image.asset('assets/images/logomatchyplano.png', height: kLogoHeight),
                        const SizedBox(width: 42),
                      ],
                    ),
                  ),

                  Expanded(
                    child: _cita == null
                        ? const Center(child: CircularProgressIndicator(color: Colors.white))
                        : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 5, 16, 120),
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _BannerPlaceCard(cita: _cita!, onTapDetail: () => _showPlaceDetailPopup(_cita!)),
                          const SizedBox(height: 15),
                          _FechaHoraBlock(fecha: _fechaLarga(_cita!.fecha), hora: _cita!.hora),
                          const SizedBox(height: 20),
                          _RelojNeonRedisenado(fecha: _cita!.fecha, hora: _cita!.hora, onCancel: () async {
                            await FirebaseFirestore.instance.collection(kCitasCollection).doc(_cita!.docId).delete();
                            if (mounted) _goBackToPanel();
                          }),
                          const SizedBox(height: 25),
                          const _CapsulaTitulo(text: "CON QUIÉN QUIERES IR A TU CITA"),
                          const SizedBox(height: 15),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: kPurpleContainer.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(color: Colors.white10),
                              boxShadow: kPremiumBoxShadow,
                            ),
                            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                              stream: _candidatosStreamCache,
                              builder: (_, snap) {
                                if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: Colors.white));
                                final docs = snap.data!.docs;
                                if (docs.isEmpty) {
                                  return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Aún no hay postulados.\nEspera a que lleguen matchys.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white60, fontSize: 13))));
                                }
                                final list = docs.map(_CandidatoFS.fromDoc).toList();
                                return GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: list.length,
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.72, crossAxisSpacing: 12, mainAxisSpacing: 12),
                                  itemBuilder: (_, i) {
                                    final candidato = list[i];
                                    final bool isSelected = _candidatoSeleccionadoId == candidato.uid;
                                    final bool isAnyBusy = _candidatoSeleccionadoId != null;

                                    return _CardCandidatoGoldPremium(
                                        c: candidato,
                                        isSelected: isSelected,
                                        isAnyBusy: isAnyBusy,
                                        pulseAnimation: _pulseAnimation,
                                        onTapPerfil: (uid) => Navigator.push(context, MaterialPageRoute(builder: (_) => PerfilUsuarioXScreen(uid: uid))),
                                        onMatch: (c) => _hacerMatchyFlow(c: c, cita: _cita!)
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 30),
                          _ButtonFinalPremium(text: "VOLVER AL PANEL", gradient: kBtnBackGradient, onTap: _goBackToPanel),
                          const SizedBox(height: 12),
                          _ButtonFinalDelete(text: "BORRAR CITA", gradient: kBtnDeleteGradient, onTap: () async {
                            await FirebaseFirestore.instance.collection(kCitasCollection).doc(_cita!.docId).delete();
                            if (mounted) _goBackToPanel();
                          }),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // FADEOUT NEGRO INFERIOR
            Positioned(bottom: 0, left: 0, right: 0, height: 120, child: IgnorePointer(child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.95)], stops: const [0.0, 0.8]))))),
          ],
        ),
      ),
    );
  }

  String _fechaLarga(String f) { try { var p = f.split('/'); const ms = ['Enero','Febrero','Marzo','Abril','Mayo','Junio','Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre']; const ds = ['Lunes','Martes','Miércoles','Jueves','Viernes','Sábado','Domingo']; DateTime dt = DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0])); return "${ds[dt.weekday-1]} ${p[0]} de ${ms[int.parse(p[1])-1]} ${p[2]}"; } catch(_) { return f; } }
}

// ============================================================
// WIDGETS REDISEÑADOS FINAL
// ============================================================

class _BannerPlaceCard extends StatelessWidget {
  final _CitaFS cita; final VoidCallback onTapDetail;
  const _BannerPlaceCard({required this.cita, required this.onTapDetail});
  @override Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTapDetail,
      child: Container(
        height: kCardLugarHeight,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: kPremiumBoxShadow,
            image: DecorationImage(image: NetworkImage(cita.fotoLugar), fit: BoxFit.cover, onError: (_,__) {})
        ),
        child: Stack(
          children: [
            Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.95)], stops: const [0.3, 1.0]))),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(cita.nombreLugar.toUpperCase(), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900, fontFamily: 'Poppins', shadows: kTextShadowStrong)),
                  const SizedBox(height: 8),
                  Text(cita.direccionLugar, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500, fontFamily: 'Poppins', shadows: kTextShadowStrong)),
                ],
              ),
            ),
            Positioned(top: 10, right: 10, child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.black45, shape: BoxShape.circle, boxShadow: kPremiumBoxShadow), child: const Icon(Icons.zoom_in, color: Colors.white, size: 20)))
          ],
        ),
      ),
    );
  }
}

class _FechaHoraBlock extends StatelessWidget {
  final String fecha; final String hora;
  const _FechaHoraBlock({required this.fecha, required this.hora});
  @override Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
        boxShadow: kPremiumBoxShadow,
      ),
      child: Column(
        children: [
          Text(fecha.toUpperCase(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
          const SizedBox(height: 4),
          Text(hora, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, fontFamily: 'Poppins')),
        ],
      ),
    );
  }
}

class _RelojNeonRedisenado extends StatefulWidget { final String fecha; final String hora; final VoidCallback onCancel; const _RelojNeonRedisenado({required this.fecha, required this.hora, required this.onCancel}); @override State<_RelojNeonRedisenado> createState() => _RelojNeonRedisenadoState(); }
class _RelojNeonRedisenadoState extends State<_RelojNeonRedisenado> {
  Timer? _timer; Duration _d = Duration.zero;
  @override void initState() { super.initState(); _calc(); _timer = Timer.periodic(const Duration(seconds: 1), (_) => _calc()); }
  @override void dispose() { _timer?.cancel(); super.dispose(); }
  void _calc() {
    try {
      final f = widget.fecha.split('/'); final hP = widget.hora.replaceAll('AM','').replaceAll('PM','').trim().split(':');
      var h = int.parse(hP[0]); if (widget.hora.contains('PM') && h!=12) h+=12; if (widget.hora.contains('AM') && h==12) h=0;
      final dt = DateTime(int.parse(f[2]), int.parse(f[1]), int.parse(f[0]), h, int.parse(hP[1]));
      final lim = dt.subtract(const Duration(hours: 12));
      setState(() => _d = lim.difference(DateTime.now()));
      if (_d.isNegative) widget.onCancel();
    } catch (_) {}
  }
  @override Widget build(BuildContext context) {
    final d = (_d.inDays).toString().padLeft(2, '0'); final h = (_d.inHours % 24).toString().padLeft(2, '0'); final m = (_d.inMinutes % 60).toString().padLeft(2, '0');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kGlassBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kNeonGreen.withOpacity(0.5), width: 1),
        boxShadow: kNeonGlowShadow,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _DigitColumn(d, "DÍAS"),
              const SizedBox(width: 10),
              const Text(":", style: TextStyle(color: kNeonGreen, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(width: 10),
              _DigitColumn(h, "HORAS"),
              const SizedBox(width: 10),
              const Text(":", style: TextStyle(color: kNeonGreen, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(width: 10),
              _DigitColumn(m, "MIN"),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 8, height: 8, decoration: const BoxDecoration(color: kNeonGreen, shape: BoxShape.circle)), const SizedBox(width: 8), const Text("TIEMPO PARA ESCOGER A TU MATCHY", style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5))]),
          )
        ],
      ),
    );
  }
}
class _DigitColumn extends StatelessWidget { final String n; final String label; const _DigitColumn(this.n, this.label); @override Widget build(BuildContext context) { return Column(children: [Text(n, style: const TextStyle(color: kNeonGreen, fontSize: 30, fontFamily: 'monospace', fontWeight: FontWeight.bold, shadows: [Shadow(color: kNeonGreen, blurRadius: 8)])), const SizedBox(height: 2), Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold))]); } }

class _CapsulaTitulo extends StatelessWidget {
  final String text;
  const _CapsulaTitulo({required this.text});
  @override Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: kCapsulaTituloBg,
        borderRadius: BorderRadius.circular(25),
        boxShadow: kPremiumBoxShadow,
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.star, color: Colors.black, size: 18), const SizedBox(width: 8), Text(text, style: const TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w900, fontFamily: 'Poppins')), const SizedBox(width: 8), const Icon(Icons.star, color: Colors.black, size: 18)]),
    );
  }
}

// 🔥 WIDGET ACTUALIZADO CON LÓGICA DE "EL ELEGIDO" Y OVERLAY FESTIVO
class _CardCandidatoGoldPremium extends StatelessWidget {
  final _CandidatoFS c;
  final bool isSelected;
  final bool isAnyBusy;
  final Animation<double> pulseAnimation;
  final Function(String) onTapPerfil;
  final Function(_CandidatoFS) onMatch;

  const _CardCandidatoGoldPremium({
    required this.c,
    required this.isSelected,
    required this.isAnyBusy,
    required this.pulseAnimation,
    required this.onTapPerfil,
    required this.onMatch
  });

  @override Widget build(BuildContext context) {
    return Column(
        children: [
          Expanded(
              child: GestureDetector(
                  onTap: () => onTapPerfil(c.uid),
                  child: Container(
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(kAvatarRadius), color: Colors.black, boxShadow: kPremiumBoxShadow),
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(kAvatarRadius),
                          child: Stack(
                              fit: StackFit.expand,
                              children: [
                                FotoPerfilUsuario(uid: c.uid, fit: BoxFit.cover),
                                Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.9)], stops: const [0.6, 1.0]))),
                                Positioned(bottom: 8, left: 5, right: 5, child: Text("${c.nombre}, ${c.edad}", textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900, shadows: [Shadow(color: Colors.black, blurRadius: 2)]))),

                                // 🔥 OVERLAY MÁGICO "¡ES TU MATCHY!"
                                if (isSelected)
                                  Container(
                                    color: Colors.black.withOpacity(0.65), // Oscurece la foto
                                    child: Center(
                                      child: Transform.rotate(
                                        angle: -0.15, // Inclinación fiestera
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: kNeonGreen, // Neónazo
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: kNeonGlowShadow,
                                            border: Border.all(color: Colors.white, width: 2),
                                          ),
                                          child: const Text(
                                            "¡ES TU\nMATCHY!",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w900,
                                                height: 1.1
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ]
                          )
                      )
                  )
              )
          ),
          const SizedBox(height: 8),
          ScaleTransition(
              scale: pulseAnimation,
              child: GestureDetector(
                  onTap: isAnyBusy ? null : () => onMatch(c),
                  child: Container(
                      width: double.infinity,
                      height: 35,
                      // 🔥 Si otro está cargando, este botón se pone gris. Si este está cargando, mantiene su oro.
                      decoration: BoxDecoration(
                          gradient: LinearGradient(colors: isAnyBusy && !isSelected ? [Colors.grey.shade800, Colors.grey.shade900] : kBtnGoldGradient),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: isAnyBusy && !isSelected ? [] : [BoxShadow(color: kGoldBtn1, blurRadius: 6, offset: const Offset(0, 2))]
                      ),
                      alignment: Alignment.center,
                      child: isSelected
                          ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : Text("HACER MATCHY", style: TextStyle(color: isAnyBusy && !isSelected ? Colors.white54 : Colors.black, fontSize: 10, fontWeight: FontWeight.w900))
                  )
              )
          )
        ]
    );
  }
}

class _ButtonFinalPremium extends StatelessWidget {
  final String text; final List<Color> gradient; final VoidCallback onTap;
  const _ButtonFinalPremium({required this.text, required this.gradient, required this.onTap});
  @override Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: Container(height: 50, decoration: BoxDecoration(gradient: LinearGradient(colors: gradient), borderRadius: BorderRadius.circular(25), boxShadow: kPremiumBoxShadow), alignment: Alignment.center, child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))));
  }
}

class _ButtonFinalDelete extends StatelessWidget {
  final String text; final List<Color> gradient; final VoidCallback onTap;
  const _ButtonFinalDelete({required this.text, required this.gradient, required this.onTap});
  @override Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: Container(height: 50, decoration: BoxDecoration(gradient: LinearGradient(colors: gradient), borderRadius: BorderRadius.circular(25), boxShadow: kPremiumBoxShadow), alignment: Alignment.center, child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))));
  }
}

class _PopupInfoItem extends StatelessWidget {
  final IconData icon; final String label; final String value;
  const _PopupInfoItem({required this.icon, required this.label, required this.value});
  @override Widget build(BuildContext context) {
    return Column(children: [Icon(icon, color: Colors.white54, size: 20), const SizedBox(height: 4), Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)), Text(value.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))]);
  }
}