// 📂 lib/screens/reporte_inasistencia_screen.dart
// ✅ SALA DE REPORTE (EL TRIBUNAL)
// 🔥 UI: Reloj Casio Gigante + Botones de Sentencia.
// 🔥 LOGIC: Calcula tiempo restante (2h límite) y ejecuta castigos/disputas.
// 🔥 CONTROL: Zona de Chinches Maestros incluida.

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
  // 🔴🔴 ZONA DE CHINCHES MAESTROS (CONFIGURACIÓN VISUAL) 🔴🔴
  // ===========================================================================

  // 1. LOGO Y HEADER
  static const double kLogoHeight           = 40.0;
  static const double kLogoTopMargin        = 10.0;

  // 2. TEXTOS DE ALERTA
  static const double kTituloSize           = 26.0; // "TIEMPO RESTANTE"
  static const double kSubtituloSize        = 14.0; // "Para reportar..."
  static const double kEspacioTituloReloj   = 20.0;

  // 3. RELOJ GIGANTE (CASIO STYLE)
  static const double kRelojFontSize        = 55.0; // Números grandes
  static const double kRelojContainerHeight = 110.0; // Altura caja negra
  static const double kRelojLetterSpacing   = 4.0;  // Separación números

  // 4. BOTONES DE ACCIÓN (SENTENCIA)
  static const double kBotonesGap           = 16.0; // Espacio entre botones
  static const double kBotonHeight          = 60.0; // Altura botones
  static const double kBotonFontSize        = 14.0;

  // COLORES DE BOTONES
  static const List<Color> kBtnYoFui        = [Color(0xFF00E676), Color(0xFF00C853)]; // Verde (Acusación)
  static const List<Color> kBtnNoFui        = [Color(0xFFFF5252), Color(0xFFD32F2F)]; // Rojo (Confesión)
  static const List<Color> kBtnMutuo        = [Color(0xFF64B5F6), Color(0xFF1976D2)]; // Azul (Acuerdo)

  // ===========================================================================

  String _tiempoRestante = "--:--:--";
  Timer? _timer;
  bool _isLoading = false;
  DateTime? _deadline; // Hora cita + 2 horas

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

  Future<void> _cargarDatosCita() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('citas').doc(widget.citaId).get();
      if (!doc.exists) return;

      final data = doc.data()!;

      // Calcular Deadline (Hora Cita + 2 Horas)
      DateTime fechaCita;
      if (data['scheduledAt'] is Timestamp) {
        fechaCita = (data['scheduledAt'] as Timestamp).toDate();
      } else {
        // Fallback por si es string (usamos lógica simple o actual)
        fechaCita = DateTime.now();
      }

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
        // SE ACABÓ EL TIEMPO
        _timer?.cancel();
        setState(() => _tiempoRestante = "00:00:00");
        // Aquí podrías disparar el castigo automático si el usuario está viendo la pantalla
      } else {
        final h = difference.inHours.toString().padLeft(2, '0');
        final m = (difference.inMinutes % 60).toString().padLeft(2, '0');
        final s = (difference.inSeconds % 60).toString().padLeft(2, '0');
        setState(() => _tiempoRestante = "$h:$m:$s");
      }
    });
  }

  // ⚖️ LÓGICA DEL TRIBUNAL
  Future<void> _ejecutarSentencia(String tipo) async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final citaRef = FirebaseFirestore.instance.collection('citas').doc(widget.citaId);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {

        // 1. CONFESIÓN ("NO PUDE IR") -> Castigo Inmediato (-20%)
        if (tipo == 'CULPABLE') {
          final userSnap = await transaction.get(userRef);
          int currentScore = (userSnap.data()?['confiabilidad'] as num?)?.toInt() ?? 100;
          int newScore = (currentScore - 20).clamp(0, 100); // Castigo duro por faltar

          transaction.update(userRef, {
            'confiabilidad': newScore,
            'strikes': FieldValue.increment(1), // Suma strike
          });

          transaction.update(citaRef, {
            'status': 'finished',
            'resultado': 'absent_confessed',
            'culpableUid': user.uid,
          });
        }

        // 2. ACUSACIÓN ("YO SÍ FUI") -> Abre Disputa
        else if (tipo == 'INOCENTE') {
          transaction.update(citaRef, {
            'status': 'dispute', // Pasa a revisión manual o espera reporte del otro
            'reclamo_por': user.uid,
            'reclamo_at': FieldValue.serverTimestamp(),
          });
          // Nota: Aquí no bajamos puntos aún, esperamos a ver qué dice el otro.
        }

        // 3. MUTUO ACUERDO -> Castigo Leve o Neutro
        else if (tipo == 'MUTUO') {
          // Asumamos castigo leve (-5% o nada si ambos coinciden)
          // Por ahora lo marcamos para revisión
          transaction.update(citaRef, {
            'status': 'mutual_cancel_request',
            'solicitado_por': user.uid,
          });
        }

      });

      if (mounted) {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeShell(initialIndex: 1)), (route) => false);

        String msg = "";
        if (tipo == 'CULPABLE') msg = "Reporte enviado. Se ha aplicado la penalidad por inasistencia.";
        if (tipo == 'INOCENTE') msg = "Reporte enviado. Esperaremos la confirmación de tu Matchy.";
        if (tipo == 'MUTUO') msg = "Solicitud de cancelación mutua enviada.";

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: tipo == 'CULPABLE' ? Colors.red : Colors.blue,
        ));
      }

    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Fondo Sutil
          Positioned.fill(
            child: Opacity(
              opacity: 0.3,
              child: Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // 1. HEADER
                Padding(
                  padding: EdgeInsets.only(top: kLogoTopMargin, left: 10, right: 10),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 28),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
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

                        // 2. TEXTOS DE ALERTA
                        Icon(Icons.timer_off_outlined, color: Colors.redAccent, size: 50),
                        const SizedBox(height: 10),
                        Text(
                          "TIEMPO RESTANTE",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: kTituloSize,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Poppins',
                              letterSpacing: 1.0
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "Para reportar el estado de tu cita",
                          style: TextStyle(color: Colors.white54, fontSize: kSubtituloSize),
                        ),

                        SizedBox(height: kEspacioTituloReloj),

                        // 3. RELOJ GIGANTE (CASIO)
                        Container(
                          height: kRelojContainerHeight,
                          width: double.infinity,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              color: const Color(0xFF111111), // Negro casi puro
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.redAccent.withOpacity(0.5), width: 2),
                              boxShadow: [
                                BoxShadow(color: Colors.redAccent.withOpacity(0.2), blurRadius: 20, spreadRadius: 2)
                              ]
                          ),
                          child: Text(
                            _tiempoRestante,
                            style: TextStyle(
                                color: const Color(0xFFFF5252), // Rojo Digital
                                fontSize: kRelojFontSize,
                                fontFamily: 'monospace', // Estilo Digital
                                fontWeight: FontWeight.w900,
                                letterSpacing: kRelojLetterSpacing,
                                shadows: [
                                  BoxShadow(color: Colors.red.withOpacity(0.6), blurRadius: 15)
                                ]
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                        const Text(
                          "Si el contador llega a cero sin confirmación, ambos perderán 10 puntos de confiabilidad.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.orangeAccent, fontSize: 13, fontStyle: FontStyle.italic),
                        ),

                        const SizedBox(height: 50),

                        // 4. BOTONES DE SENTENCIA
                        if (_isLoading)
                          const CircularProgressIndicator(color: Colors.white)
                        else ...[
                          _SentenciaButton(
                            text: "YO SÍ ASISTÍ, MI MATCHY NO",
                            icon: Icons.person_pin_circle_rounded,
                            gradient: kBtnYoFui,
                            onTap: () => _ejecutarSentencia('INOCENTE'),
                          ),

                          SizedBox(height: kBotonesGap),

                          _SentenciaButton(
                            text: "NINGUNO ASISTIÓ / ACUERDO",
                            icon: Icons.handshake_rounded,
                            gradient: kBtnMutuo,
                            onTap: () => _ejecutarSentencia('MUTUO'),
                          ),

                          SizedBox(height: kBotonesGap),

                          _SentenciaButton(
                            text: "NO PUDE ASISTIR",
                            icon: Icons.cancel_presentation_rounded,
                            gradient: kBtnNoFui,
                            onTap: () => _ejecutarSentencia('CULPABLE'),
                          ),
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

  const _SentenciaButton({
    required this.text,
    required this.icon,
    required this.gradient,
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: _ReporteInasistenciaScreenState.kBotonHeight,
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: gradient),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: gradient.last.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))
          ],
          border: Border.all(color: Colors.white24, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Text(
              text,
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: _ReporteInasistenciaScreenState.kBotonFontSize,
                  letterSpacing: 0.5
              ),
            ),
          ],
        ),
      ),
    );
  }
}