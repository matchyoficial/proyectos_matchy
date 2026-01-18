// 📂 lib/screens/citas_pendientes_detalle.dart
// ✅ Conectado a Firestore REAL: citas/{citaDocId} + citas/{citaDocId}/candidatos
// ✅ FIX CLAVE: la flecha SIEMPRE vuelve a CitasPendientesScreen
// ✅ NUEVO: botón “VOLVER AL PANEL” (regresa al Panel)
// ✅ Mantiene diseño Matchy + reloj + grid + botón “HACER MATCHY”

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:proyectos_matchy/screens/citas_pendientes_screen.dart';
import 'package:proyectos_matchy/screens/match_screen.dart';
import 'package:proyectos_matchy/screens/panel_screen.dart';

// ================================================================
// 🔴 CHINCHE FIRESTORE 1 — colección citas
// ================================================================
const String kCitasCollection = 'citas';

// 🔴 CHINCHE FIRESTORE 3 — subcolección candidatos
const String kCandidatosSubcol = 'candidatos';

// 🔴 CHINCHE FIRESTORE 4 — fields candidatos
const String kCandUid = 'uid';
const String kCandNombre = 'nombre';
const String kCandEdad = 'edad';
const String kCandFoto = 'foto';
const String kCandCreatedAt = 'createdAt';

// 🔴 CHINCHE FIRESTORE 10 — fields cita
const String kFechaField = 'fecha';
const String kHoraField = 'hora';
const String kPreferenciaField = 'preferencia';
const String kIntencionField = 'intencion';
const String kLugarField = 'lugar';
const String kLugarNombreField = 'nombre';
const String kLugarDireccionField = 'direccion';
const String kLugarFotoPortadaField = 'fotoPortada';

// ================================================================
// 🔹 PERFIL PREVIEW SEGURO DEL CANDIDATO
// ================================================================
class CandidatoPerfilPreviewScreen extends StatelessWidget {
  final String nombre;
  final int edad;
  final String foto;

  const CandidatoPerfilPreviewScreen({
    super.key,
    required this.nombre,
    required this.edad,
    required this.foto,
  });

  bool _isNetwork(String v) => v.startsWith('http://') || v.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    // 🔴 CHINCHE PREVIEW 1 — alto foto (más grande = sube número)
    const double altoFoto = 320;

    Widget fotoWidget;
    if (foto.trim().isEmpty) {
      fotoWidget = Image.asset('assets/images/perfil1.jpg', fit: BoxFit.cover);
    } else if (_isNetwork(foto.trim())) {
      fotoWidget = Image.network(
        foto.trim(),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            Image.asset('assets/images/perfil1.jpg', fit: BoxFit.cover),
      );
    } else {
      fotoWidget = Image.asset(
        foto.trim(),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            Image.asset('assets/images/perfil1.jpg', fit: BoxFit.cover),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Column(
            children: [
              const SizedBox(height: 60),
              SizedBox(
                height: 50,
                child: Image.asset('assets/images/logomatchyplano.png'),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Stack(
                    children: [
                      SizedBox(
                        height: altoFoto,
                        width: double.infinity,
                        child: fotoWidget,
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 130,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.75),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: Text(
                          edad > 0 ? '$nombre, $edad' : nombre,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0x33FFFFFF),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Text(
                  'Perfil de candidato (preview).\n\nMás adelante lo conectamos al perfil real completo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.3,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ================================================================
// 🔹 MODELO CANDIDATO (FIRESTORE)
// ================================================================
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
    final uid = (data[kCandUid] ?? doc.id).toString().trim();
    final nombre = (data[kCandNombre] ?? 'Candidato').toString().trim();

    int edad = 0;
    final e = data[kCandEdad];
    if (e is int) edad = e;
    if (e is String) edad = int.tryParse(e) ?? 0;

    final foto = (data[kCandFoto] ?? '').toString().trim();

    return _CandidatoFS(
      uid: uid.isEmpty ? doc.id : uid,
      nombre: nombre,
      edad: edad,
      foto: foto,
    );
  }
}

// ================================================================
// 🔹 MODELO CITA (desde Firestore)
// ================================================================
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

class CitasPendientesDetalleScreen extends ConsumerStatefulWidget {
  // ✅ Ahora SI debe llegar docId real (desde Firestore)
  final String citaId;

  const CitasPendientesDetalleScreen({
    super.key,
    required this.citaId,
  });

  @override
  ConsumerState<CitasPendientesDetalleScreen> createState() =>
      _CitasPendientesDetalleScreenState();
}

class _CitasPendientesDetalleScreenState
    extends ConsumerState<CitasPendientesDetalleScreen> {
  Timer? _timer;

  // 🔴 CHINCHE RELOJ 1 — actualiza cada 1 segundo
  static const Duration _tick = Duration(seconds: 1);

  // 🔴 CHINCHE RELOJ 2 — alerta 1 sola vez cuando falte 1 hora o menos
  bool _alerta1hMostrada = false;

  // 🔴 CHINCHE RELOJ 3 — tiempo restante cacheado
  Duration _restante = Duration.zero;

  // 🔴 CHINCHE LOADING 1 — bloqueo taps cuando se procesa matchy
  bool _busy = false;

  _CitaFS? _cita;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(_tick, (_) {
      if (!mounted) return;
      _recalcularContadorYAlertar();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _cargarCita();
      _recalcularContadorYAlertar();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ================================================================
  // 🔙 FIX: la flecha SIEMPRE vuelve a CitasPendientesScreen
  // ================================================================
  void _goBackToPendientes() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const CitasPendientesScreen()),
          (route) => false,
    );
  }

  // ================================================================
  // 🔙 NUEVO: botón “VOLVER AL PANEL”
  // ================================================================
  void _goBackToPanel() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const PanelScreen()),
          (route) => false,
    );
  }

  // ================================================================
  // ✅ Cargar cita desde Firestore por docId
  // ================================================================
  Future<void> _cargarCita() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(kCitasCollection)
          .doc(widget.citaId.trim())
          .get();

      if (!doc.exists) {
        setState(() => _cita = null);
        return;
      }

      final data = doc.data() ?? {};
      final lugar = (data[kLugarField] is Map)
          ? Map<String, dynamic>.from(data[kLugarField])
          : <String, dynamic>{};

      String s(dynamic v) => v is String ? v : (v?.toString() ?? '');

      final cita = _CitaFS(
        docId: doc.id,
        nombreLugar: s(lugar[kLugarNombreField]).isEmpty ? 'Lugar' : s(lugar[kLugarNombreField]),
        direccionLugar: s(lugar[kLugarDireccionField]),
        fotoLugar: s(lugar[kLugarFotoPortadaField]),
        fecha: s(data[kFechaField]),
        hora: s(data[kHoraField]),
        preferencia: s(data[kPreferenciaField]),
        intencion: s(data[kIntencionField]),
      );

      setState(() => _cita = cita);
    } catch (_) {
      setState(() => _cita = null);
    }
  }

  // ================================================================
  // 🔥 STREAM CANDIDATOS: citas/{citaDocId}/candidatos
  // ================================================================
  Stream<QuerySnapshot<Map<String, dynamic>>> _candidatosStream(String citaDocId) {
    return FirebaseFirestore.instance
        .collection(kCitasCollection)
        .doc(citaDocId)
        .collection(kCandidatosSubcol)
    // 🔴 CHINCHE CANDS 1 — orden
        .orderBy(kCandCreatedAt, descending: true)
    // 🔴 CHINCHE CANDS 2 — límite
        .limit(40)
        .snapshots();
  }

  void _recalcularContadorYAlertar() {
    final cita = _cita;
    if (cita == null) return;

    final DateTime? citaDateTime = _parseCitaDateTime(cita.fecha, cita.hora);
    if (citaDateTime == null) {
      setState(() => _restante = Duration.zero);
      return;
    }

    // ✅ deadline = 12 horas antes
    final DateTime deadline = citaDateTime.subtract(const Duration(hours: 12));
    final now = DateTime.now();

    final Duration restante = deadline.difference(now);
    final Duration clamped = restante.isNegative ? Duration.zero : restante;

    if (!_alerta1hMostrada &&
        restante <= const Duration(hours: 1) &&
        restante > Duration.zero) {
      _alerta1hMostrada = true;

      final textoCita = '${cita.nombreLugar} • ${cita.fecha} • ${cita.hora}';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Te queda 1 hora para escoger a tu matchy en la cita del $textoCita'),
          duration: const Duration(seconds: 6),
        ),
      );
    }

    setState(() => _restante = clamped);
  }

  DateTime? _parseCitaDateTime(String fecha, String hora) {
    try {
      final f = fecha.trim();
      final h = hora.trim();

      final parts = f.split('/');
      if (parts.length != 3) return null;

      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);

      int hour24 = 0;
      int minute = 0;

      final upper = h.toUpperCase();

      if (upper.contains('AM') || upper.contains('PM')) {
        final isPM = upper.contains('PM');
        final clean = upper.replaceAll('AM', '').replaceAll('PM', '').trim();
        final hm = clean.split(':');
        if (hm.length != 2) return null;

        var hh = int.parse(hm[0].trim());
        minute = int.parse(hm[1].trim());

        if (isPM) {
          if (hh != 12) hh += 12;
        } else {
          if (hh == 12) hh = 0;
        }
        hour24 = hh;
      } else {
        final hm = upper.split(':');
        if (hm.length != 2) return null;
        hour24 = int.parse(hm[0].trim());
        minute = int.parse(hm[1].trim());
      }

      return DateTime(year, month, day, hour24, minute);
    } catch (_) {
      return null;
    }
  }

  String _formatHHMMSS(Duration d) {
    final total = d.inSeconds;
    final hh = (total ~/ 3600).toString().padLeft(2, '0');
    final mm = ((total % 3600) ~/ 60).toString().padLeft(2, '0');
    final ss = (total % 60).toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }

  // ================================================================
  // ✅ CÓDIGO determinístico
  // ================================================================
  String _buildMiCodigoCita({
    required String citaId,
    required String candidatoUid,
  }) {
    final seed = '$citaId-$candidatoUid';
    final hash = seed.codeUnits.fold<int>(0, (p, c) => (p + c) % 999999);
    final code = hash.toString().padLeft(6, '0');
    return 'MX$code';
  }

  // ================================================================
  // ✅ GUARDA EN FIRESTORE (de momento deja tu lógica intacta)
  // ================================================================
  Future<String?> _guardarCitaEnFirestore({
    required _CandidatoFS c,
    required _CitaFS cita,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final citaDateTime = _parseCitaDateTime(cita.fecha, cita.hora);
    if (citaDateTime == null) return null;

    final String miCodigo = _buildMiCodigoCita(
      citaId: cita.docId,
      candidatoUid: c.uid,
    );

    // 🔴 CHINCHE DOCID 1 — esto NO debería escribirse en "citas" (mezcla).
    // Lo dejamos tal cual para no romperte flujo hoy.
    final docId = '${user.uid}_${cita.docId}_${c.uid}';
    final docRef = FirebaseFirestore.instance.collection(kCitasCollection).doc(docId);

    await docRef.set({
      'ownerUid': user.uid,
      'status': 'proxima',
      'fechaHora': Timestamp.fromDate(citaDateTime),
      'matchUid': c.uid,
      'matchNombre': c.nombre,
      'matchEdad': c.edad,
      'matchFoto': c.foto,
      'lugarNombre': cita.nombreLugar,
      'lugarDireccion': cita.direccionLugar,
      'preferencia': cita.preferencia,
      'intencion': cita.intencion,
      'miCodigoCita': miCodigo,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return miCodigo;
  }

  Future<void> _hacerMatchyFlow({
    required _CandidatoFS c,
    required _CitaFS cita,
  }) async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Debes iniciar sesión para hacer matchy.')),
        );
        return;
      }

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MatchScreen(
            candidatoId: c.uid,
            candidatoNombre: c.nombre,
            candidatoEdad: c.edad,
            candidatoFotoAsset: c.foto.isEmpty ? 'assets/images/perfil1.jpg' : c.foto,
            onMatchAnimationFinished: () async {
              final miCodigo = await _guardarCitaEnFirestore(c: c, cita: cita);
              if (!mounted) return;

              if (miCodigo == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('❌ No se pudo crear la cita.')),
                );
              }
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error haciendo matchy: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  bool _isNetwork(String v) => v.startsWith('http://') || v.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    const double espacioBarraLogo = 35;
    const double alturaLogo = 50;
    const double espacioLogoTitulo = 12;
    const double paddingBottom = 90;

    final cita = _cita;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover),
          ),

          // ✅ Flecha “blindada”
          Positioned(
            top: 12,
            left: 12,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: _goBackToPendientes, // ✅ FIX
            ),
          ),

          Column(
            children: [
              const SizedBox(height: espacioBarraLogo),
              SizedBox(
                height: alturaLogo,
                child: Image.asset('assets/images/logomatchyplano.png'),
              ),
              const SizedBox(height: espacioLogoTitulo),

              Expanded(
                child: (cita == null)
                    ? SingleChildScrollView(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: paddingBottom,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0x33FFFFFF),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Text(
                          '❌ No pude cargar la cita.\n\n'
                              'DocId recibido: "${widget.citaId}"\n\n'
                              '🔴 Solución: esta pantalla debe recibir el docId real de Firestore.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            height: 1.25,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ✅ Botón a Panel
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.82,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _goBackToPanel,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6A5ACD),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text(
                            'VOLVER AL PANEL',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                    : SingleChildScrollView(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: paddingBottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // FOTO LUGAR
                      Container(
                        height: 190,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.45),
                              blurRadius: 10,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _buildFotoLugar(cita.fotoLugar),
                      ),

                      const SizedBox(height: 12),

                      // INFO
                      Text(
                        cita.nombreLugar,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '📍 ${cita.direccionLugar}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '📅 ${cita.fecha}   🕒 ${cita.hora}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '🎯 ${cita.intencion} • 👥 ${cita.preferencia}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontFamily: 'Poppins',
                        ),
                      ),

                      const SizedBox(height: 10),

                      Center(
                        child: Text(
                          _formatHHMMSS(_restante),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFFF5252),
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Center(
                        child: Text(
                          'TIEMPO PARA ELEGIR TU MATCHY',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFFFF5252),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),
                      const Text(
                        '¿CON QUIÉN QUIERES IR A TU CITA?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 10),

                      // GRID CANDIDATOS
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: _candidatosStream(cita.docId),
                        builder: (context, snap) {
                          if (snap.hasError) {
                            return _boxText('❌ Error cargando candidatos: ${snap.error}');
                          }
                          if (!snap.hasData) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 18),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          final docs = snap.data!.docs;
                          if (docs.isEmpty) {
                            return _boxText(
                              'Aún no hay candidatos.\nCuando alguien haga swipe a la derecha, aparecerá aquí.',
                              soft: true,
                            );
                          }

                          final candidatos = docs.map(_CandidatoFS.fromDoc).toList();

                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: candidatos.length,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              // 🔴 CHINCHE GRID 1 — espacios (más juntos = baja números)
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              // 🔴 CHINCHE GRID 2 — proporción (más alto = baja número)
                              childAspectRatio: 0.86,
                            ),
                            itemBuilder: (_, i) {
                              final c = candidatos[i];

                              return _CandidatoCard(
                                candidato: c,
                                busy: _busy,
                                onTapFoto: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => CandidatoPerfilPreviewScreen(
                                        nombre: c.nombre.isEmpty ? 'Candidato' : c.nombre,
                                        edad: c.edad,
                                        foto: c.foto,
                                      ),
                                    ),
                                  );
                                },
                                onMatchy: () async {
                                  await _hacerMatchyFlow(c: c, cita: cita);
                                },
                              );
                            },
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      // ✅ Botón extra para regresar al Panel
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.82,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _goBackToPanel,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6A5ACD),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text(
                            'VOLVER AL PANEL',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _boxText(String t, {bool soft = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x33FFFFFF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        t,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: soft ? Colors.white70 : Colors.white,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
          height: 1.25,
        ),
      ),
    );
  }

  Widget _buildFotoLugar(String pathOrUrl) {
    final v = pathOrUrl.trim();
    if (v.isEmpty) {
      return Image.asset('assets/images/perfil1.jpg', fit: BoxFit.cover);
    }
    if (_isNetwork(v)) {
      return Image.network(
        v,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            Image.asset('assets/images/perfil1.jpg', fit: BoxFit.cover),
      );
    }
    return Image.asset(
      v,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          Image.asset('assets/images/perfil1.jpg', fit: BoxFit.cover),
    );
  }
}

class _CandidatoCard extends StatelessWidget {
  final _CandidatoFS candidato;
  final VoidCallback onTapFoto;
  final Future<void> Function() onMatchy;
  final bool busy;

  const _CandidatoCard({
    required this.candidato,
    required this.onTapFoto,
    required this.onMatchy,
    required this.busy,
  });

  bool _isNetwork(String v) => v.startsWith('http://') || v.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    const double radio = 18;

    // 🔴 CHINCHE BTN 1 — alto botón (más grande = sube número)
    const double altoBoton = 36;

    Widget fotoWidget;
    if (candidato.foto.trim().isEmpty) {
      fotoWidget = Image.asset('assets/images/perfil1.jpg', fit: BoxFit.cover);
    } else if (_isNetwork(candidato.foto.trim())) {
      fotoWidget = Image.network(
        candidato.foto.trim(),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            Image.asset('assets/images/perfil1.jpg', fit: BoxFit.cover),
      );
    } else {
      fotoWidget = Image.asset(
        candidato.foto.trim(),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            Image.asset('assets/images/perfil1.jpg', fit: BoxFit.cover),
      );
    }

    final nombre = candidato.nombre.isEmpty ? 'Candidato' : candidato.nombre;
    final edadTxt = candidato.edad > 0 ? ', ${candidato.edad}' : '';

    return Column(
      children: [
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
                    Positioned.fill(child: fotoWidget),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 70,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.65),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 10,
                      right: 10,
                      bottom: 10,
                      child: Center(
                        child: Text(
                          '$nombre$edadTxt',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: altoBoton,
          child: ElevatedButton(
            onPressed: busy ? null : () async => await onMatchy(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFC107),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: busy
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Text(
              'HACER MATCHY',
              style: TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ),
      ],
    );
  }
}
