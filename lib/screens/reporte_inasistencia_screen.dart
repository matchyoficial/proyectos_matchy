// 📂 lib/screens/reporte_inasistencia_screen.dart
// ✅ REPORTE DE INASISTENCIA BLINDADO
// 🔥 LOGICA NUEVA: Botón Azul cobra 10 pts individualmente.
// 🔥 UI NUEVA: Texto explicativo estilo Matchy sobre los botones.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart'; // 📍 LIBRERÍA GPS
import 'package:proyectos_matchy/screens/home_shell.dart';

class ReporteInasistenciaScreen extends StatefulWidget {
  final String citaId;
  const ReporteInasistenciaScreen({super.key, required this.citaId});

  @override
  State<ReporteInasistenciaScreen> createState() => _ReporteInasistenciaScreenState();
}

class _ReporteInasistenciaScreenState extends State<ReporteInasistenciaScreen> {
  static const double kLogoHeight = 40.0;
  static const double kRelojFontSize = 53.0;
  static const double kRelojLetterSpacing = 4.0;

  // ===========================================================================
  // 🎛️ INTERRUPTOR DE PRUEBAS MAESTRO
  // ===========================================================================
  static const bool kModoPruebasGPS = true;
  // ===========================================================================

  static const int kRadioToleranciaMetros = 200;

  String _tiempoRestante = "--:--:--";
  Timer? _timer;
  bool _isLoading = false;
  DateTime? _deadline;

  @override
  void initState() {
    super.initState();
    _cargarDatosCita();
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  DateTime _parsearFechaManual(String fStr, String hStr) {
    try {
      final parts = fStr.trim().split(RegExp(r'[/ -]'));
      if (parts.length < 3) return DateTime.now();
      int d = int.parse(parts[0]), m = int.parse(parts[1]), y = int.parse(parts[2]);
      String rawHora = hStr.toUpperCase().replaceAll('.', '').trim();
      bool esPM = rawHora.contains("PM");
      final timeParts = rawHora.replaceAll(RegExp(r'[^0-9:]'), '').split(':');
      if (timeParts.length < 2) return DateTime.now();
      int h = int.parse(timeParts[0]), min = int.parse(timeParts[1]);
      if (esPM && h != 12) h += 12; else if (!esPM && h == 12) h = 0;
      return DateTime(y, m, d, h, min);
    } catch (_) { return DateTime.now(); }
  }

  Future<void> _cargarDatosCita() async {
    setState(() => _isLoading = true);
    try {
      final doc = await FirebaseFirestore.instance.collection('citas').doc(widget.citaId).get();
      if (!doc.exists) { _mostrarError("Cita no encontrada."); return; }
      final data = doc.data()!;
      final f = (data['fecha'] ?? '').toString();
      final h = (data['hora'] ?? '').toString();
      if (f.isEmpty || h.isEmpty) return;
      _deadline = _parsearFechaManual(f, h).add(const Duration(hours: 2));
      _startTimer();
    } catch (e) { debugPrint("Error: $e"); }
    finally { if (mounted) setState(() => _isLoading = false); }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_deadline == null) return;
      final diff = _deadline!.difference(DateTime.now());
      if (diff.isNegative) {
        _timer?.cancel();
        if (mounted) setState(() => _tiempoRestante = "00:00:00");
        if (!_isLoading) _ejecutarCastigoAutomatico();
      } else {
        final h = diff.inHours.toString().padLeft(2, '0');
        final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
        final s = (diff.inSeconds % 60).toString().padLeft(2, '0');
        if (mounted) setState(() => _tiempoRestante = "$h:$m:$s");
      }
    });
  }

  // 🔹 BOTÓN VERDE: GPS
  Future<void> _verificarUbicacionYReclamar() async {
    setState(() => _isLoading = true);
    try {
      final citaDoc = await FirebaseFirestore.instance.collection('citas').doc(widget.citaId).get();
      final data = citaDoc.data()!;
      final double lat = (data['latitude'] as num?)?.toDouble() ?? 0.0;
      final double lng = (data['longitude'] as num?)?.toDouble() ?? 0.0;

      if (lat == 0.0 || lng == 0.0) throw "Sin coordenadas guardadas.";

      LocationPermission p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) {
        p = await Geolocator.requestPermission();
        if (p == LocationPermission.denied) throw "Permiso denegado.";
      }

      Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      double dist = Geolocator.distanceBetween(pos.latitude, pos.longitude, lat, lng);

      if (kModoPruebasGPS) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("🛠️ TEST: Distancia ${dist.toInt()}m."), backgroundColor: Colors.blue));
        await _ejecutarSentencia('INOCENTE');
      } else {
        if (dist <= kRadioToleranciaMetros) await _ejecutarSentencia('INOCENTE');
        else throw "Estás a ${dist.toInt()}m. Debes estar en el sitio.";
      }
    } catch (e) { if (mounted) _mostrarError(e.toString()); }
    finally { if (mounted) setState(() => _isLoading = false); }
  }

  // 🔹 BOTÓN AZUL: PENALIDAD INDIVIDUAL (-10 PTS)
  Future<void> _mostrarAlertaPenalidadIndividual() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.blueAccent)),
        title: const Text("SALIDA RÁPIDA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          "Si decides no asistir o acordaron cancelar, puedes salirte de la cita ahora.\n\n"
              "📉 COSTO: -10 PUNTOS\n⛔ SIN BLOQUEOS NI STRIKES\n\n"
              "¿Aceptas pagar 10 puntos para cerrar tu parte?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("VOLVER", style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () { Navigator.pop(ctx); _ejecutarPenalidadIndividual(); },
            child: const Text("ACEPTAR (-10 PTS)", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _ejecutarPenalidadIndividual() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final citaRef = FirebaseFirestore.instance.collection('citas').doc(widget.citaId);
        final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

        final citaSnap = await tx.get(citaRef);
        final userSnap = await tx.get(userRef);

        if (!citaSnap.exists) throw "Error cita";
        final cData = citaSnap.data()!;

        bool isOwner = cData['ownerUid'] == user.uid;
        bool isMatchy = cData['matchyUid'] == user.uid;
        if (!isOwner && !isMatchy) throw "Error de usuario";

        // 1. Descuento 10 pts sin bloqueo
        int score = (userSnap.data()?['confiabilidad'] as num?)?.toInt() ?? 100;
        tx.update(userRef, {'confiabilidad': (score - 10).clamp(0, 100)});

        // 2. Marcar usuario como finalizado
        if (isOwner) tx.update(citaRef, {'ownerFinalized': true});
        else tx.update(citaRef, {'matchyFinalized': true});

        // 3. Si AMBOS finalizaron, cerrar cita. Si no, dejarla viva.
        bool oFin = (cData['ownerFinalized'] == true) || isOwner;
        bool mFin = (cData['matchyFinalized'] == true) || isMatchy;

        if (oFin && mFin) {
          tx.update(citaRef, {'status': 'finished', 'resultado': 'mutual_penalty_closed', 'finalizedAt': FieldValue.serverTimestamp()});
        }
      });
      if (mounted) HomeShell.go(context, index: 1);
    } catch (e) { if (mounted) _mostrarError("$e"); }
    finally { if (mounted) setState(() => _isLoading = false); }
  }

  // 🔹 TIMER: CASTIGO AUTOMÁTICO (-20 PTS + BLOQUEO)
  Future<void> _ejecutarCastigoAutomatico() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final citaRef = FirebaseFirestore.instance.collection('citas').doc(widget.citaId);
        final doc = await tx.get(citaRef);
        if (!doc.exists) return;
        final data = doc.data()!;

        // Solo castiga a quien NO haya finalizado (pagado los 10pts)
        if (data['ownerFinalized'] != true) await _aplicarCastigoGrave(tx, data['ownerUid']);
        if (data['matchyFinalized'] != true) await _aplicarCastigoGrave(tx, data['matchyUid']);

        tx.update(citaRef, {'status': 'finished', 'resultado': 'expired_timeout'});
      });
      if (mounted) HomeShell.go(context, index: 1);
    } catch (_) {}
    finally { if (mounted) setState(() => _isLoading = false); }
  }

  Future<void> _aplicarCastigoGrave(Transaction tx, String? uid) async {
    if (uid == null) return;
    final ref = FirebaseFirestore.instance.collection('users').doc(uid);
    final snap = await tx.get(ref);
    if (snap.exists) {
      int score = (snap.data()?['confiabilidad'] as num?)?.toInt() ?? 100;
      int strikes = (snap.data()?['strikes'] as num?)?.toInt() ?? 0;
      int newS = strikes + 1;
      tx.update(ref, {
        'confiabilidad': (score - 20).clamp(0, 100),
        'strikes': newS,
        'citas_consecutivas_exitosas': 0,
        'userStatus': newS >= 5 ? 'blocked_permanent' : 'blocked',
        'bloqueadoHasta': Timestamp.fromDate(DateTime.now().add(Duration(days: newS * 5))),
      });
    }
  }

  // 🔹 CULPABLE / INOCENTE
  Future<void> _ejecutarSentencia(String tipo) async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        if (tipo == 'CULPABLE') {
          final snap = await tx.get(userRef);
          int score = (snap.data()?['confiabilidad'] as num?)?.toInt() ?? 100;
          int strikes = (snap.data()?['strikes'] as num?)?.toInt() ?? 0;
          int newS = strikes + 1;
          tx.update(userRef, {
            'confiabilidad': (score - 20).clamp(0, 100),
            'strikes': newS,
            'citas_consecutivas_exitosas': 0,
            'userStatus': newS >= 5 ? 'blocked_permanent' : 'blocked',
            'bloqueadoHasta': Timestamp.fromDate(DateTime.now().add(Duration(days: newS * 5))),
          });
          tx.update(FirebaseFirestore.instance.collection('citas').doc(widget.citaId), {'status': 'finished', 'resultado': 'absent_confessed', 'culpableUid': user.uid});
        } else if (tipo == 'INOCENTE') {
          tx.update(FirebaseFirestore.instance.collection('citas').doc(widget.citaId), {'status': 'dispute', 'reclamo_por': user.uid, 'reclamo_at': FieldValue.serverTimestamp()});
        }
      });
      if (mounted) HomeShell.go(context, index: 1);
    } catch (e) { if (mounted) _mostrarError("$e"); }
    finally { if (mounted) setState(() => _isLoading = false); }
  }

  void _mostrarError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: Opacity(opacity: 0.3, child: Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover))),
          SafeArea(
            child: Column(
              children: [
                Padding(padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10), child: Stack(alignment: Alignment.center, children: [Align(alignment: Alignment.centerLeft, child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context))), Image.asset('assets/images/logomatchyplano.png', height: kLogoHeight)])),
                Expanded(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 30), child: Column(children: [
                  const SizedBox(height: 30),
                  const Icon(Icons.timer_off_outlined, color: Colors.redAccent, size: 50),
                  const Text("TIEMPO RESTANTE", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, fontFamily: 'Poppins')),

                  const SizedBox(height: 15),
                  Container(height: 90, width: double.infinity, alignment: Alignment.center, decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.redAccent.withOpacity(0.5), width: 2)), child: FittedBox(fit: BoxFit.scaleDown, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Text(_tiempoRestante, style: const TextStyle(color: Color(0xFFFF5252), fontSize: 50, fontFamily: 'monospace', fontWeight: FontWeight.w900, letterSpacing: 2.0))))),

                  const SizedBox(height: 20),
                  // 🔥 TEXTO EXPLICATIVO MATCHY STYLE
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white12)),
                    child: const Column(children: [
                      _InfoRow(icon: Icons.location_on, color: Color(0xFF00E676), title: "ESTOY AQUÍ", desc: "GPS valida tu ubicación. No pierdes puntos."),
                      SizedBox(height: 10),
                      _InfoRow(icon: Icons.handshake, color: Color(0xFF64B5F6), title: "NO IRÉ / ACUERDO", desc: "Salida rápida. Costo: -10 Puntos. Sin bloqueos."),
                      SizedBox(height: 10),
                      _InfoRow(icon: Icons.warning, color: Color(0xFFFF5252), title: "FALLÉ", desc: "Asumes la culpa. Costo: -20 Puntos + Strike."),
                    ]),
                  ),
                  const SizedBox(height: 25),

                  if (_isLoading) const Padding(padding: EdgeInsets.only(top: 20), child: CircularProgressIndicator(color: Colors.white)) else ...[
                    _SentenciaButton(text: "YO SÍ ASISTÍ, MI MATCHY NO", icon: Icons.person_pin_circle_rounded, gradient: [const Color(0xFF00E676), const Color(0xFF00C853)], onTap: _verificarUbicacionYReclamar),
                    const SizedBox(height: 16),
                    _SentenciaButton(text: "NINGUNO ASISTIÓ / ACUERDO", icon: Icons.handshake_rounded, gradient: [const Color(0xFF64B5F6), const Color(0xFF1976D2)], onTap: _mostrarAlertaPenalidadIndividual),
                    const SizedBox(height: 16),
                    _SentenciaButton(text: "NO PUDE ASISTIR", icon: Icons.cancel_presentation_rounded, gradient: [const Color(0xFFFF5252), const Color(0xFFD32F2F)], onTap: () => _ejecutarSentencia('CULPABLE')),
                  ],
                  const SizedBox(height: 30),
                ]))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Widget auxiliar para la guía de texto
class _InfoRow extends StatelessWidget {
  final IconData icon; final Color color; final String title; final String desc;
  const _InfoRow({required this.icon, required this.color, required this.title, required this.desc});
  @override Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(width: 8),
      Expanded(child: RichText(text: TextSpan(style: const TextStyle(fontFamily: 'Poppins', fontSize: 13), children: [
        TextSpan(text: "$title: ", style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        TextSpan(text: desc, style: const TextStyle(color: Colors.white70))
      ])))
    ]);
  }
}

class _SentenciaButton extends StatelessWidget {
  final String text; final IconData icon; final List<Color> gradient; final VoidCallback onTap;
  const _SentenciaButton({required this.text, required this.icon, required this.gradient, required this.onTap});
  @override Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: Container(width: double.infinity, height: 55, padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(gradient: LinearGradient(colors: gradient), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white24)), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: Colors.white, size: 22), const SizedBox(width: 10), Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14))))])));
  }
}