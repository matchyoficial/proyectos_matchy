// 📂 lib/screens/reporte_inasistencia_screen.dart
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
  // 🎛️ INTERRUPTOR DE PRUEBAS MAESTRO (MODO TESTER)
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
      int d = int.parse(parts[0]), m = int.parse(parts[1]), y = int.parse(parts[2]);
      String rawHora = hStr.toUpperCase().replaceAll('.', '').trim();
      bool esPM = rawHora.contains("PM");
      final timeParts = rawHora.replaceAll(RegExp(r'[^0-9:]'), '').split(':');
      int h = int.parse(timeParts[0]), min = int.parse(timeParts[1]);
      if (esPM && h != 12) h += 12; else if (!esPM && h == 12) h = 0;
      return DateTime(y, m, d, h, min);
    } catch (_) { return DateTime.now(); }
  }

  Future<void> _cargarDatosCita() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('citas').doc(widget.citaId).get();
      if (!doc.exists) return;
      final data = doc.data()!;
      final f = (data['fecha'] ?? '').toString();
      final h = (data['hora'] ?? '').toString();

      if (f.isEmpty || h.isEmpty) return;

      _deadline = _parsearFechaManual(f, h).add(const Duration(hours: 2));
      _startTimer();
    } catch (e) { debugPrint("Error cargando cita: $e"); }
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

  Future<void> _verificarUbicacionYReclamar() async {
    setState(() => _isLoading = true);
    try {
      final citaDoc = await FirebaseFirestore.instance.collection('citas').doc(widget.citaId).get();
      if (!citaDoc.exists) throw "Cita no encontrada";

      final citaData = citaDoc.data()!;
      final double latLugar = (citaData['latitude'] as num?)?.toDouble() ?? 0.0;
      final double lngLugar = (citaData['longitude'] as num?)?.toDouble() ?? 0.0;

      if (latLugar == 0.0 || lngLugar == 0.0) {
        throw "Esta cita no tiene coordenadas guardadas.";
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw "Permiso de ubicación denegado.";
      }

      Position userPos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      double distanciaMetros = Geolocator.distanceBetween(userPos.latitude, userPos.longitude, latLugar, lngLugar);

      if (kModoPruebasGPS) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("🛠️ MODO PRUEBAS: Distancia real: ${distanciaMetros.toStringAsFixed(1)}m."),
            backgroundColor: Colors.blueAccent,
          ));
        }
        await _ejecutarSentencia('INOCENTE');
      } else {
        if (distanciaMetros <= kRadioToleranciaMetros) {
          await _ejecutarSentencia('INOCENTE');
        } else {
          throw "Estás a ${distanciaMetros.toInt()}m del lugar. Debes estar en el sitio.";
        }
      }
    } catch (e) {
      if (mounted) _mostrarError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _mostrarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  Future<void> _ejecutarCastigoAutomatico() async {
    setState(() => _isLoading = true);
    try {
      final citaDoc = await FirebaseFirestore.instance.collection('citas').doc(widget.citaId).get();
      if (!citaDoc.exists) return;
      final data = citaDoc.data()!;

      // 🛡️ VERIFICACIÓN DE UIDs (Para evitar crash)
      final String? oUid = data['ownerUid'];
      final String? mUid = data['matchyUid'];

      if (oUid == null || mUid == null) {
        debugPrint("Error: Faltan UIDs en el documento de la cita.");
        return;
      }

      await FirebaseFirestore.instance.runTransaction((tx) async {
        for (String uid in [oUid, mUid]) {
          final ref = FirebaseFirestore.instance.collection('users').doc(uid);
          final snap = await tx.get(ref);
          if (snap.exists) {
            int score = (snap.data()?['confiabilidad'] as num?)?.toInt() ?? 100;
            int strikes = (snap.data()?['strikes'] as num?)?.toInt() ?? 0;
            int newStrikes = strikes + 1;
            tx.update(ref, {
              'confiabilidad': (score - 20).clamp(0, 100),
              'strikes': newStrikes,
              'citas_consecutivas_exitosas': 0,
              'userStatus': newStrikes >= 5 ? 'blocked_permanent' : 'blocked',
              'bloqueadoHasta': Timestamp.fromDate(DateTime.now().add(Duration(days: newStrikes * 5))),
            });
          }
        }
        tx.update(FirebaseFirestore.instance.collection('citas').doc(widget.citaId), {'status': 'finished', 'resultado': 'expired_timeout'});
      });
      if (mounted) HomeShell.go(context, index: 1);
    } catch (e) {
      debugPrint("Error en castigo automático: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
          int newStrikes = strikes + 1;
          tx.update(userRef, {
            'confiabilidad': (score - 20).clamp(0, 100),
            'strikes': newStrikes,
            'citas_consecutivas_exitosas': 0,
            'userStatus': newStrikes >= 5 ? 'blocked_permanent' : 'blocked',
            'bloqueadoHasta': Timestamp.fromDate(DateTime.now().add(Duration(days: newStrikes * 5))),
          });
          tx.update(FirebaseFirestore.instance.collection('citas').doc(widget.citaId), {'status': 'finished', 'resultado': 'absent_confessed', 'culpableUid': user.uid});
        } else if (tipo == 'INOCENTE') {
          tx.update(FirebaseFirestore.instance.collection('citas').doc(widget.citaId), {'status': 'dispute', 'reclamo_por': user.uid, 'reclamo_at': FieldValue.serverTimestamp()});
        } else if (tipo == 'MUTUO') {
          tx.update(FirebaseFirestore.instance.collection('citas').doc(widget.citaId), {
            'status': 'cancelled',
            'resultado': 'mutual_agreement',
            'canceladoAt': FieldValue.serverTimestamp(),
            'canceladoPor': 'mutual_agreement_button'
          });
        }
      });
      if (mounted) HomeShell.go(context, index: 1);
    } catch (e) {
      if (mounted) _mostrarError("Error en sentencia: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                  const SizedBox(height: 40), const Icon(Icons.timer_off_outlined, color: Colors.redAccent, size: 60),
                  const FittedBox(fit: BoxFit.scaleDown, child: Text("TIEMPO RESTANTE", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, fontFamily: 'Poppins', letterSpacing: 1.0))),
                  const Text("Para reportar el estado de tu cita", style: TextStyle(color: Colors.white54, fontSize: 19)),
                  const SizedBox(height: 20),
                  Container(height: 110, width: double.infinity, alignment: Alignment.center, decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.redAccent.withOpacity(0.5), width: 2)), child: FittedBox(fit: BoxFit.scaleDown, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Text(_tiempoRestante, style: const TextStyle(color: Color(0xFFFF5252), fontSize: kRelojFontSize, fontFamily: 'monospace', fontWeight: FontWeight.w900, letterSpacing: kRelojLetterSpacing))))),
                  const SizedBox(height: 10),
                  const Text("Si el contador llega a cero sin confirmación, ambos perderán 20 puntos y sus rachas.", textAlign: TextAlign.center, style: TextStyle(color: Colors.orangeAccent, fontSize: 17, fontStyle: FontStyle.italic)),
                  const SizedBox(height: 50),
                  if (_isLoading)
                    const Padding(padding: EdgeInsets.only(top: 20), child: CircularProgressIndicator(color: Colors.white))
                  else ...[
                    _SentenciaButton(text: "YO SÍ ASISTÍ, MI MATCHY NO", icon: Icons.person_pin_circle_rounded, gradient: [const Color(0xFF00E676), const Color(0xFF00C853)], onTap: _verificarUbicacionYReclamar),
                    const SizedBox(height: 16),
                    _SentenciaButton(text: "NINGUNO ASISTIÓ / ACUERDO", icon: Icons.handshake_rounded, gradient: [const Color(0xFF64B5F6), const Color(0xFF1976D2)], onTap: () => _ejecutarSentencia('MUTUO')),
                    const SizedBox(height: 16),
                    _SentenciaButton(text: "NO PUDE ASISTIR", icon: Icons.cancel_presentation_rounded, gradient: [const Color(0xFFFF5252), const Color(0xFFD32F2F)], onTap: () => _ejecutarSentencia('CULPABLE')),
                  ],
                ]))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SentenciaButton extends StatelessWidget {
  final String text; final IconData icon; final List<Color> gradient; final VoidCallback onTap;
  const _SentenciaButton({required this.text, required this.icon, required this.gradient, required this.onTap});
  @override Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: Container(width: double.infinity, height: 60, padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(gradient: LinearGradient(colors: gradient), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white24)), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: Colors.white, size: 22), const SizedBox(width: 10), Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14))))])));
  }
}