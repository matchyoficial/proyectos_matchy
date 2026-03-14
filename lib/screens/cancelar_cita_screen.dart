// 📂 lib/screens/cancelar_cita_screen.dart
// ✅ PANTALLA DE CANCELACIÓN BLINDADA (LÓGICA DE BLOQUEO + NOTIFICACIÓN ALERTA)
// 🔥 LOGIC: -20 Puntos, Strike +1, Bloqueo (x5 días), Racha 0.
// 🔥 NOTIF: Envía alerta roja al otro usuario con fecha y lugar.
// 🔒 FIX: Parseo de Fecha y Hora exacto para que el bloqueo de 12h sea milimétrico.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:proyectos_matchy/screens/home_shell.dart';
import 'package:proyectos_matchy/screens/reprogramar_cita_screen.dart';

class CancelarCitaScreen extends StatefulWidget {
  final String citaId;
  final String otherUserId;

  const CancelarCitaScreen({
    super.key,
    required this.citaId,
    required this.otherUserId
  });

  @override
  State<CancelarCitaScreen> createState() => _CancelarCitaScreenState();
}

class _CancelarCitaScreenState extends State<CancelarCitaScreen> {
  // ===========================================================================
  // 🛡️ ZONA DE CHINCHES MAESTROS (MANTENIENDO TAMAÑOS SOLICITADOS)
  // ===========================================================================

  static const double kLogoTopMargin        = 6.0;
  static const double kLogoHeight           = 40.0;

  static const double kIconoWarningTopGap   = 30.0;
  static const double kIconoWarningSize     = 75.0;
  static const double kCirculoWarningSize   = 20.0;

  static const double kTituloFontSize       = 36.0;
  static const double kTituloTopGap         = 25.0;
  static const double kDescripcionFontSize  = 18.0;
  static const double kDescripcionTopGap    = 15.0;

  static const double kCapsulaTopGap        = 35.0;
  static const double kCapsulaPadding       = 16.0;
  static const double kMiniTermoHeight      = 8.0;

  static const double kBotonReproTopGap     = 27.0;
  static const double kBotonReproHeight     = 55.0;
  static const double kBotonReproFontSize   = 16.0;

  static const double kTextoInfoFontSize    = 19.0;
  static const double kTextoInfoTopGap      = 12.0;

  static const double kBotonRojoTopGap      = 43.0;
  static const double kBotonRojoHeight      = 50.0;
  static const double kBotonRojoFontSize    = 14.0;

  // ===========================================================================

  bool _isLoading = false;
  DateTime? _citaDateTime; // Variable para almacenar la fecha y hora exactas

  @override
  void initState() {
    super.initState();
    _fetchCitaDate();
  }

  // 🔥 Carga la fecha y hora de la cita para validar la regla de las 12 horas milimétricamente
  Future<void> _fetchCitaDate() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('citas').doc(widget.citaId).get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        final fechaStr = data['fecha'] as String? ?? '';
        final horaStr = data['hora'] as String? ?? ''; // 🔥 Extraemos la hora

        // Parseo de Fecha DD/MM/YYYY
        final partes = fechaStr.trim().split(RegExp(r'[/ -]'));
        if (partes.length >= 3) {
          int d = int.parse(partes[0]);
          int m = int.parse(partes[1]);
          int y = int.parse(partes[2]);

          int hh = 0;
          int mm = 0;

          // 🔥 Parseo de Hora Exacto (Soporta AM/PM a 24h)
          if (horaStr.isNotEmpty) {
            try {
              String rawHora = horaStr.toUpperCase().replaceAll('.', '').trim();
              bool esPM = rawHora.contains("PM");
              final tP = rawHora.replaceAll(RegExp(r'[^0-9:]'), '').split(':');
              if (tP.isNotEmpty) {
                hh = int.parse(tP[0]);
                if (tP.length > 1) {
                  mm = int.parse(tP[1]);
                }
                if (esPM && hh != 12) hh += 12;
                else if (!esPM && hh == 12) hh = 0;
              }
            } catch (e) {
              debugPrint("Error parseando hora en cancelación: $e");
            }
          }

          final dt = DateTime(y, m, d, hh, mm); // 🔥 DateTime ahora tiene Hora y Minuto reales
          setState(() {
            _citaDateTime = dt;
          });
        }
      }
    } catch (_) {}
  }

  // 🔥 LÓGICA DE TIEMPO: Retorna TRUE si faltan más de 12h (Zona Segura)
  bool get _zonaSegura12h {
    if (_citaDateTime == null) return true; // Si aún carga, permitimos por defecto
    final ahora = DateTime.now();
    return _citaDateTime!.difference(ahora).inHours >= 12;
  }

  // 🔥 ALERTA DE BLOQUEO REPROGRAMACIÓN
  void _mostrarAlertaBloqueoReprogramar() {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.white24)),
            title: const Text("⏳ TIEMPO AGOTADO", style: TextStyle(color: Color(0xFFFFC107), fontWeight: FontWeight.w900)),
            content: const Text(
              "YA NO ES POSIBLE REPROGRAMAR PORQUE FALTAN MENOS DE 12 HORAS PARA TU CITA.\n\nPOR RESPETO A TU MATCHY, DEBES ASISTIR O CANCELAR ASUMIENDO LA PENALIDAD.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, height: 1.4, fontSize: 14),
            ),
            actions: [
              Center(
                child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("ENTENDIDO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                ),
              )
            ]
        )
    );
  }

  Future<void> _ejecutarCancelacion() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final citaRef = FirebaseFirestore.instance.collection('citas').doc(widget.citaId);
    final notifRef = FirebaseFirestore.instance.collection('users').doc(widget.otherUserId).collection('notifications').doc();

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userSnapshot = await transaction.get(userRef);
        final citaSnapshot = await transaction.get(citaRef); // 🔥 Leemos la cita para los datos del texto

        // 1. Datos Actuales del Usuario
        int currentScore = (userSnapshot.data()?['confiabilidad'] as num?)?.toInt() ?? 100;
        int currentStrikes = (userSnapshot.data()?['strikes'] as num?)?.toInt() ?? 0;
        String myName = (userSnapshot.data()?['nombre'] ?? 'Usuario').toString();

        // 2. Datos de la Cita (Para la notificación)
        String lugarNombre = (citaSnapshot.data()?['lugarNombre'] ?? 'la cita').toString();
        String fechaCita = (citaSnapshot.data()?['fecha'] ?? '').toString();

        // 3. Cálculo de Penalización (-20 Puntos)
        int newScore = (currentScore - 20).clamp(0, 100);

        // 4. Cálculo de Bloqueo (Strikes y Días)
        int newStrikes = currentStrikes + 1;
        int diasCastigo = newStrikes * 5;
        DateTime fechaDesbloqueo = DateTime.now().add(Duration(days: diasCastigo));

        // 5. Actualización Atómica - USUARIO (Castigo)
        transaction.update(userRef, {
          'confiabilidad': newScore,
          'strikes': newStrikes,
          'citas_consecutivas_exitosas': 0, // 🔥 RESET DE RACHA
          'userStatus': newStrikes >= 5 ? 'blocked_permanent' : 'blocked',
          'bloqueadoHasta': Timestamp.fromDate(fechaDesbloqueo),
        });

        // 6. Actualización Atómica - CITA (Cancelación)
        transaction.update(citaRef, {
          'status': 'cancelled',
          'canceladoPor': user.uid,
          'canceladoAt': FieldValue.serverTimestamp(),
          'resultado': 'cancelled_penalty',
        });

        // 7. Actualización Atómica - NOTIFICACIÓN (Alerta Roja)
        transaction.set(notifRef, {
          'type': 'cancellation_alert', // 🔴 TIPO ESPECIAL PARA ROJO
          'title': '🚫 CITA CANCELADA',
          'body': 'Lo sentimos, $myName ha cancelado la cita del $fechaCita en $lugarNombre. Se han aplicado las sanciones correspondientes a $myName.',
          'citaId': widget.citaId,
          'fromUid': user.uid,
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      if (mounted) {
        // Redirigir al HomeShell (que detectará el bloqueo y mostrará el candado o la pantalla de bloqueo)
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeShell(initialIndex: 0)),
                (route) => false
        );
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Cita cancelada. Se han aplicado las penalizaciones."),
              backgroundColor: Color(0xFFD50000),
            )
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
        setState(() => _isLoading = false);
      }
    }
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return const Color(0xFF00E676);
    if (score >= 50) return const Color(0xFFFFC107);
    if (score >= 20) return const Color(0xFFFF5722);
    return const Color(0xFFD50000);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    // Evaluamos la regla de las 12 horas
    final esSeguroReprogramar = _zonaSegura12h;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.3,
              child: Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover),
            ),
          ),

          SafeArea(
            child: StreamBuilder<DocumentSnapshot>(
                stream: user != null
                    ? FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots()
                    : null,
                builder: (context, snapshot) {
                  int myScore = 100;
                  if (snapshot.hasData && snapshot.data != null) {
                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                    myScore = (data?['confiabilidad'] as num?)?.toInt() ?? 100;
                  }

                  return Column(
                    children: [
                      // 1. HEADER
                      Padding(
                        padding: const EdgeInsets.only(top: kLogoTopMargin, left: 10, right: 10),
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
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            children: [
                              const SizedBox(height: kIconoWarningTopGap),

                              // 2. ICONO ADVERTENCIA
                              Container(
                                padding: const EdgeInsets.all(kCirculoWarningSize),
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFFD50000).withOpacity(0.1),
                                    border: Border.all(color: const Color(0xFFD50000), width: 2),
                                    boxShadow: [BoxShadow(color: const Color(0xFFD50000).withOpacity(0.2), blurRadius: 15)]
                                ),
                                child: const Icon(
                                  Icons.warning_amber_rounded,
                                  color: Color(0xFFD50000),
                                  size: kIconoWarningSize,
                                ),
                              ),

                              const SizedBox(height: kTituloTopGap),

                              // 3. TEXTOS BLINDADOS
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: const Text(
                                  "¿ESTÁS SEGURO?",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: kTituloFontSize,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'Poppins',
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                              const SizedBox(height: kDescripcionTopGap),
                              Text(
                                "Cancelar esta cita afectará negativamente tu reputación en la comunidad Matchy. Tu perfil será bloqueado TEMPORALMENTE",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: kDescripcionFontSize,
                                  height: 1.5,
                                ),
                              ),

                              const SizedBox(height: kCapsulaTopGap),

                              // 4. CÁPSULA NEGRA + MINI TERMÓMETRO BLINDADO
                              Container(
                                padding: const EdgeInsets.all(kCapsulaPadding),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1F1F1F),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white12),
                                  boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4))],
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.trending_down, color: Color(0xFFFF5252), size: 32),
                                        const SizedBox(width: 15),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: const [
                                              FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Text(
                                                  "PENALIDAD AUTOMÁTICA",
                                                  style: TextStyle(color: Color(0xFFFF5252), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                                ),
                                              ),
                                              SizedBox(height: 2),
                                              // 🔥 TEXTO CORREGIDO: -20 PUNTOS
                                              FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Text(
                                                  "-20 Puntos de Confiabilidad",
                                                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 15),
                                    Divider(color: Colors.white.withOpacity(0.1), height: 1),
                                    const SizedBox(height: 15),

                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text("Tu nivel actual:", style: TextStyle(color: Colors.white54, fontSize: 12)),
                                        Text("$myScore%", style: TextStyle(color: _getScoreColor(myScore), fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(5),
                                      child: SizedBox(
                                        height: kMiniTermoHeight,
                                        child: LinearProgressIndicator(
                                          value: myScore / 100,
                                          backgroundColor: Colors.white10,
                                          valueColor: AlwaysStoppedAnimation<Color>(_getScoreColor(myScore)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: kBotonReproTopGap),

                              // 5. BOTÓN REPROGRAMAR (MODIFICADO CON REGLA 12H)
                              SizedBox(
                                width: double.infinity,
                                height: kBotonReproHeight,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    // 🔥 CAMBIO DE COLOR: Verde si es seguro, Gris si <12h
                                    backgroundColor: esSeguroReprogramar ? const Color(0xFF00E676) : const Color(0xFF616161),
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                    elevation: 8,
                                    shadowColor: (esSeguroReprogramar ? const Color(0xFF00E676) : Colors.black).withOpacity(0.4),
                                  ),
                                  onPressed: () {
                                    if (esSeguroReprogramar) {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => ReprogramarCitaScreen(citaId: widget.citaId)));
                                    } else {
                                      _mostrarAlertaBloqueoReprogramar(); // Muestra burbuja si está bloqueado
                                    }
                                  },
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Text(
                                        // 🔥 CAMBIO DE TEXTO
                                        esSeguroReprogramar ? "REPROGRAMAR CITA" : "ACCIÓN BLOQUEADA (MENOS DE 12H)",
                                        style: TextStyle(fontSize: kBotonReproFontSize, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: kTextoInfoTopGap),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  "Si reprogramas, no perderás puntos.",
                                  style: TextStyle(color: Colors.white54, fontSize: kTextoInfoFontSize),
                                ),
                              ),

                              const SizedBox(height: kBotonRojoTopGap),

                              // 6. BOTÓN PENALIDAD (ROJO) - INTACTO
                              if (_isLoading)
                                const CircularProgressIndicator(color: Color(0xFFFF5252))
                              else
                                SizedBox(
                                  width: double.infinity,
                                  height: kBotonRojoHeight,
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFFFF5252),
                                      side: const BorderSide(color: Color(0xFFFF5252), width: 1.5),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                      backgroundColor: const Color(0xFFFF5252).withOpacity(0.05),
                                    ),
                                    onPressed: _ejecutarCancelacion,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: Text(
                                          "ASUMIR PENALIDAD Y CANCELAR",
                                          style: TextStyle(
                                              fontSize: kBotonRojoFontSize,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }
            ),
          ),
        ],
      ),
    );
  }
}