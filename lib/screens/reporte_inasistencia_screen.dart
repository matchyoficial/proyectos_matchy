// 📂 lib/screens/reporte_inasistencia_screen.dart
// ✅ SALA DE REPORTE (VERSIÓN FINAL CON BLOQUEO)
// 🔥 UI: Usa tus "Chinches Maestros" personalizados.
// 🔥 LOGIC: CULPABLE = -20 pts. Si Score < 60 o Strikes >= 3 -> BLOQUEO DE PERFIL.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:proyectos_matchy/screens/home_shell.dart';
import 'package:intl/intl.dart';

class ReporteInasistenciaScreen extends StatefulWidget {
  final String citaId;

  const ReporteInasistenciaScreen({super.key, required this.citaId});

  @override
  State<ReporteInasistenciaScreen> createState() => _ReporteInasistenciaScreenState();
}

class _ReporteInasistenciaScreenState extends State<ReporteInasistenciaScreen> {
  // ===========================================================================
  // 🔴🔴 ZONA DE CHINCHES MAESTROS (TUS AJUSTES) 🔴🔴
  // ===========================================================================

  // 1. LOGO Y HEADER
  static const double kLogoHeight           = 40.0;
  static const double kLogoTopMargin        = 10.0;

  // 2. TEXTOS DE ALERTA
  static const double kIconoAlertaSize      = 60.0;
  static const double kTituloSize           = 32.0;
  static const double kSubtituloSize        = 19.0;
  static const double kEspacioTituloReloj   = 20.0;

  // 3. RELOJ GIGANTE
  static const double kRelojFontSize        = 55.0;
  static const double kRelojContainerHeight = 110.0;
  static const double kRelojLetterSpacing   = 4.0;

  // 4. TEXTOS INFORMATIVOS
  static const double kAdvertenciaSize      = 17.0;

  // 5. BOTONES DE ACCIÓN
  static const double kBotonesGap           = 16.0;
  static const double kBotonHeight          = 60.0;
  static const double kBotonFontSize        = 14.0;

  // COLORES DE BOTONES
  static const List<Color> kBtnYoFui        = [Color(0xFF00E676), Color(0xFF00C853)];
  static const List<Color> kBtnNoFui        = [Color(0xFFFF5252), Color(0xFFD32F2F)];
  static const List<Color> kBtnMutuo        = [Color(0xFF64B5F6), Color(0xFF1976D2)];

  // ===========================================================================

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
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // 🔥 PARSER MANUAL DE FECHA
  DateTime _parsearFechaManual(String fStr, String hStr) {
    try {
      final parts = fStr.trim().split(RegExp(r'[/ -]'));
      if (parts.length < 3) return DateTime.now();

      int d = int.parse(parts[0]);
      int m = int.parse(parts[1]);
      int y = int.parse(parts[2]);

      String rawHora = hStr.toUpperCase().replaceAll('.', '').trim();
      bool esPM = rawHora.contains("PM");

      String soloNumeros = rawHora.replaceAll(RegExp(r'[^0-9:]'), '');
      final timeParts = soloNumeros.split(':');
      int hora = int.parse(timeParts[0]);
      int min = int.parse(timeParts[1]);

      if (esPM && hora != 12) hora += 12;
      if (!esPM && hora == 12) hora = 0;

      return DateTime(y, m, d, hora, min);
    } catch (e) {
      return DateTime.now();
    }
  }

  Future<void> _cargarDatosCita() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('citas').doc(widget.citaId).get();
      if (!doc.exists) return;

      final data = doc.data()!;
      final String fTexto = (data['fecha'] ?? '').toString();
      final String hTexto = (data['hora'] ?? '').toString();

      DateTime fechaCita = _parsearFechaManual(fTexto, hTexto);
      _deadline = fechaCita.add(const Duration(hours: 2));

      _startTimer();

    } catch (e) {
      debugPrint("Error cargando cita: $e");
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_deadline == null) return;

      final now = DateTime.now();
      final difference = _deadline!.difference(now);

      if (difference.isNegative) {
        _timer?.cancel();
        if (mounted) setState(() => _tiempoRestante = "00:00:00");
        if (!_isLoading) _ejecutarCastigoAutomatico();
      } else {
        final h = difference.inHours.toString().padLeft(2, '0');
        final m = (difference.inMinutes % 60).toString().padLeft(2, '0');
        final s = (difference.inSeconds % 60).toString().padLeft(2, '0');
        if (mounted) setState(() => _tiempoRestante = "$h:$m:$s");
      }
    });
  }

  Future<void> _ejecutarCastigoAutomatico() async {
    setState(() => _isLoading = true);
    try {
      final citaDoc = await FirebaseFirestore.instance.collection('citas').doc(widget.citaId).get();
      if (!citaDoc.exists) return;
      final data = citaDoc.data()!;

      if (data['status'] == 'finished') {
        if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeShell(initialIndex: 1)), (route) => false);
        return;
      }

      final String ownerUid = data['ownerUid'];
      final String matchyUid = data['matchyUid'];

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final ownerRef = FirebaseFirestore.instance.collection('users').doc(ownerUid);
        final matchyRef = FirebaseFirestore.instance.collection('users').doc(matchyUid);
        final citaRef = FirebaseFirestore.instance.collection('citas').doc(widget.citaId);

        // Castigo Owner
        final ownerSnap = await transaction.get(ownerRef);
        if (ownerSnap.exists) {
          int score = (ownerSnap.data()?['confiabilidad'] as num?)?.toInt() ?? 100;
          transaction.update(ownerRef, {'confiabilidad': (score - 10).clamp(0, 100)});
        }

        // Castigo Matchy
        final matchySnap = await transaction.get(matchyRef);
        if (matchySnap.exists) {
          int score = (matchySnap.data()?['confiabilidad'] as num?)?.toInt() ?? 100;
          transaction.update(matchyRef, {'confiabilidad': (score - 10).clamp(0, 100)});
        }

        transaction.update(citaRef, {
          'status': 'finished',
          'resultado': 'expired_timeout',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tiempo agotado. La cita se cerró automáticamente."), backgroundColor: Colors.red));
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeShell(initialIndex: 1)), (route) => false);
      }
    } catch (e) {
      debugPrint("Error castigo automático: $e");
    }
  }

  // ⚖️ JUEZ MANUAL (CON LÓGICA DE BLOQUEO AGREGADA)
  Future<void> _ejecutarSentencia(String tipo) async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final citaRef = FirebaseFirestore.instance.collection('citas').doc(widget.citaId);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {

        // 🚨 AQUÍ ESTÁ EL ARREGLO DE BLOQUEO
        if (tipo == 'CULPABLE') {
          // 1. Leer datos actuales del usuario
          final userSnap = await transaction.get(userRef);
          int currentScore = (userSnap.data()?['confiabilidad'] as num?)?.toInt() ?? 100;
          int currentStrikes = (userSnap.data()?['strikes'] as num?)?.toInt() ?? 0;

          // 2. Calcular nuevos valores
          int newScore = (currentScore - 20).clamp(0, 100);
          int newStrikes = currentStrikes + 1;

          Map<String, dynamic> updates = {
            'confiabilidad': newScore,
            'strikes': newStrikes,
          };

          // 3. 🚨 REGLA DE BLOQUEO: Si Score < 60 o Strikes >= 3
          if (newScore < 60 || newStrikes >= 3) {
            updates['userStatus'] = 'blocked';
            updates['isBlocked'] = true; // Doble check por si acaso
          }

          transaction.update(userRef, updates);

          transaction.update(citaRef, {
            'status': 'finished',
            'resultado': 'absent_confessed',
            'culpableUid': user.uid
          });
        }
        else if (tipo == 'INOCENTE') {
          transaction.update(citaRef, {'status': 'dispute', 'reclamo_por': user.uid, 'reclamo_at': FieldValue.serverTimestamp()});
        }
        else if (tipo == 'MUTUO') {
          transaction.update(citaRef, {'status': 'mutual_cancel_request', 'solicitado_por': user.uid});
        }
      });

      if (mounted) {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeShell(initialIndex: 1)), (route) => false);
      }

    } catch (e) {
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
                Padding(
                  padding: EdgeInsets.only(top: kLogoTopMargin, left: 10, right: 10),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(alignment: Alignment.centerLeft, child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 28), onPressed: () => Navigator.pop(context))),
                      Image.asset('assets/images/logomatchyplano.png', height: kLogoHeight),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        Icon(Icons.timer_off_outlined, color: Colors.redAccent, size: kIconoAlertaSize),
                        const SizedBox(height: 10),

                        Text("TIEMPO RESTANTE", style: TextStyle(color: Colors.white, fontSize: kTituloSize, fontWeight: FontWeight.w900, fontFamily: 'Poppins', letterSpacing: 1.0)),
                        const SizedBox(height: 5),

                        Text("Para reportar el estado de tu cita", style: TextStyle(color: Colors.white54, fontSize: kSubtituloSize)),
                        SizedBox(height: kEspacioTituloReloj),

                        // RELOJ
                        Container(
                          height: kRelojContainerHeight, width: double.infinity, alignment: Alignment.center,
                          decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.redAccent.withOpacity(0.5), width: 2), boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.2), blurRadius: 20, spreadRadius: 2)]),
                          child: Text(_tiempoRestante, style: TextStyle(color: const Color(0xFFFF5252), fontSize: kRelojFontSize, fontFamily: 'monospace', fontWeight: FontWeight.w900, letterSpacing: kRelojLetterSpacing, shadows: [BoxShadow(color: Colors.red.withOpacity(0.6), blurRadius: 15)])),
                        ),

                        const SizedBox(height: 10),
                        const Text(
                            "Si el contador llega a cero sin confirmación, ambos perderán 10 puntos de confiabilidad.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.orangeAccent, fontSize: kAdvertenciaSize, fontStyle: FontStyle.italic)
                        ),

                        const SizedBox(height: 50),

                        // BOTONES
                        if (_isLoading)
                          const CircularProgressIndicator(color: Colors.white)
                        else ...[
                          _SentenciaButton(text: "YO SÍ ASISTÍ, MI MATCHY NO", icon: Icons.person_pin_circle_rounded, gradient: kBtnYoFui, onTap: () => _ejecutarSentencia('INOCENTE')),
                          SizedBox(height: kBotonesGap),
                          _SentenciaButton(text: "NINGUNO ASISTIÓ / ACUERDO", icon: Icons.handshake_rounded, gradient: kBtnMutuo, onTap: () => _ejecutarSentencia('MUTUO')),
                          SizedBox(height: kBotonesGap),
                          _SentenciaButton(text: "NO PUDE ASISTIR", icon: Icons.cancel_presentation_rounded, gradient: kBtnNoFui, onTap: () => _ejecutarSentencia('CULPABLE')),
                        ],
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SentenciaButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _SentenciaButton({required this.text, required this.icon, required this.gradient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity, height: _ReporteInasistenciaScreenState.kBotonHeight,
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: gradient), borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: gradient.last.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))], border: Border.all(color: Colors.white24, width: 1)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Text(text, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: _ReporteInasistenciaScreenState.kBotonFontSize, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }
}