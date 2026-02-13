// 📂 lib/screens/reporte_inasistencia_screen.dart
// ✅ REPORTE DE INASISTENCIA (TEXTOS DE CONSECUENCIAS ACTUALIZADOS)
// 🔥 CONFIGURACIÓN: Busca los comentarios con el emoji "🔥" para cambiar Tiempo y GPS.

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
  // 🔥🔥🔥 CONFIGURACIÓN DE GPS (TRUE = FAKE/CASA | FALSE = REAL/CALLE) 🔥🔥🔥
  // ===========================================================================
  static const bool kModoPruebasGPS = false;
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

      // =======================================================================
      // 🔥🔥🔥 CONFIGURACIÓN DE TIEMPO DE ESPERA 🔥🔥🔥
      // Cambia 'minutes' para pruebas rápidas. Producción: hours: 2
      // =======================================================================
      _deadline = _parsearFechaManual(f, h).add(const Duration(minutes: 5));
      // =======================================================================

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
        if (!_isLoading) _ejecutarCastigoAutomatico(); // ⏳ EL JUEZ
      } else {
        final h = diff.inHours.toString().padLeft(2, '0');
        final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
        final s = (diff.inSeconds % 60).toString().padLeft(2, '0');
        if (mounted) setState(() => _tiempoRestante = "$h:$m:$s");
      }
    });
  }

  // 🔹 WIDGET DE DIÁLOGO MATCHY STYLE
  void _mostrarDialogoMatchy({
    required String titulo,
    required String mensaje,
    required IconData icono,
    required Color color,
    required String botonTexto,
    required VoidCallback onCerrar,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: color, width: 1.5)),
        title: Row(children: [Icon(icono, color: color), const SizedBox(width: 10), Flexible(child: Text(titulo, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)))]),
        content: Text(mensaje, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onCerrar();
            },
            child: Text(botonTexto, style: TextStyle(color: color, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  // 🔹 1. BOTÓN VERDE (GPS - EL ESCUDO INFALIBLE)
  Future<void> _verificarUbicacionYReclamar() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final citaDoc = await FirebaseFirestore.instance.collection('citas').doc(widget.citaId).get();
      final data = citaDoc.data()!;
      final double lat = (data['latitude'] as num?)?.toDouble() ?? 0.0;
      final double lng = (data['longitude'] as num?)?.toDouble() ?? 0.0;

      if (lat == 0.0 || lng == 0.0) throw "Sin coordenadas guardadas.";

      LocationPermission p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) {
        p = await Geolocator.requestPermission();
        if (p == LocationPermission.denied) throw "Permiso GPS denegado.";
      }

      Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      double dist = Geolocator.distanceBetween(pos.latitude, pos.longitude, lat, lng);

      // LÓGICA DE VALIDACIÓN GPS
      bool gpsAprobado = false;
      if (kModoPruebasGPS) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("🛠️ TEST: Distancia ${dist.toInt()}m (Aprobado Fake)."), backgroundColor: Colors.blue));
        gpsAprobado = true;
      } else {
        if (dist <= kRadioToleranciaMetros) {
          gpsAprobado = true;
        } else {
          throw "Estás a ${dist.toInt()}m. Acércate más.";
        }
      }

      if (gpsAprobado) {
        // 🔥 REGISTRAMOS EL ESCUDO SAFE EN FIREBASE
        await FirebaseFirestore.instance.runTransaction((tx) async {
          final citaRef = FirebaseFirestore.instance.collection('citas').doc(widget.citaId);
          final doc = await tx.get(citaRef);
          if (!doc.exists) return;
          final cData = doc.data()!;
          bool isOwner = cData['ownerUid'] == user.uid;

          // Marca SAFE_GPS = TRUE. Esto es lo que revisa el Timer para no matarte.
          if (isOwner) {
            tx.update(citaRef, {'ownerSafeGPS': true, 'status': 'dispute'});
          } else {
            tx.update(citaRef, {'matchySafeGPS': true, 'status': 'dispute'});
          }
        });

        if (mounted) {
          _mostrarDialogoMatchy(
            titulo: "UBICACIÓN CONFIRMADA",
            mensaje: "¡Excelente! El GPS ha verificado que estás en el lugar correcto.\n\n"
                "Gracias por tu puntualidad y compromiso. Has asegurado tu asistencia y serás premiado con puntos de racha positiva.\n\n"
                "Ahora solo espera a tu Matchy.",
            icono: Icons.check_circle_outline,
            color: const Color(0xFF00E676),
            botonTexto: "¡GENIAL!",
            onCerrar: () => HomeShell.go(context, index: 1),
          );
        }
      }

    } catch (e) { if (mounted) _mostrarError(e.toString()); }
    finally { if (mounted) setState(() => _isLoading = false); }
  }

  // 🔹 2. BOTÓN AZUL (PACTO DE SANGRE)
  Future<void> _gestionarBotonAzul() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      bool pactoCerrado = false;

      await FirebaseFirestore.instance.runTransaction((tx) async {
        final citaRef = FirebaseFirestore.instance.collection('citas').doc(widget.citaId);
        final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

        final citaSnap = await tx.get(citaRef);
        final userSnap = await tx.get(userRef);
        if (!citaSnap.exists) throw "Error lectura";
        final cData = citaSnap.data()!;

        bool soyOwner = cData['ownerUid'] == user.uid;
        bool otroPropuso = soyOwner
            ? (cData['matchyPropusoAcuerdo'] == true)
            : (cData['ownerPropusoAcuerdo'] == true);

        if (otroPropuso) {
          // 🔥 PACTO CERRADO
          pactoCerrado = true;
          int score = (userSnap.data()?['confiabilidad'] as num?)?.toInt() ?? 100;
          tx.update(userRef, {'confiabilidad': (score - 10).clamp(0, 100)});

          tx.update(citaRef, {
            'status': 'finished',
            'resultado': 'mutual_agreement',
            'finalizedAt': FieldValue.serverTimestamp()
          });
        } else {
          // 🔥 SOLO PROPUESTA
          if (soyOwner) {
            tx.update(citaRef, {'ownerPropusoAcuerdo': true});
          } else {
            tx.update(citaRef, {'matchyPropusoAcuerdo': true});
          }
        }
      });

      if (mounted) {
        if (pactoCerrado) {
          _mostrarDialogoMatchy(
            titulo: "ACUERDO COMPLETADO",
            mensaje: "Se ha confirmado el mutuo acuerdo para cancelar la cita.\n\n"
                "Ambos usuarios han aceptado la responsabilidad. Se han descontado 10 puntos de tu confiabilidad, pero tu historial de bloqueos permanece limpio.\n\n"
                "¡Gracias por resolverlo pacíficamente!",
            icono: Icons.handshake_rounded,
            color: const Color(0xFF64B5F6),
            botonTexto: "ENTENDIDO",
            onCerrar: () => HomeShell.go(context, index: 1),
          );
        } else {
          _mostrarDialogoMatchy(
            titulo: "PROPUESTA ENVIADA",
            mensaje: "Has propuesto un acuerdo para no asistir.\n\n"
                "⚠️ IMPORTANTE: Esto NO te salva todavía.\n"
                "Tu Matchy DEBE aceptar también (marcando azul) antes de que el tiempo acabe.\n\n"
                "👉 Ve al chat y dile que acepte el acuerdo o ambos perderán 20 puntos y serán bloqueados.",
            icono: Icons.info_outline,
            color: const Color(0xFF64B5F6),
            botonTexto: "ACEPTAR",
            onCerrar: () => HomeShell.go(context, index: 1),
          );
        }
      }

    } catch (e) { if (mounted) _mostrarError("$e"); }
    finally { if (mounted) setState(() => _isLoading = false); }
  }

  // 🔹 3. BOTÓN ROJO (CULPABLE)
  Future<void> _ejecutarSentencia(String tipo) async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
        final citaRef = FirebaseFirestore.instance.collection('citas').doc(widget.citaId);

        if (tipo == 'CULPABLE') {
          final userSnap = await tx.get(userRef);
          if (userSnap.exists) {
            int score = (userSnap.data()?['confiabilidad'] as num?)?.toInt() ?? 100;
            int strikes = (userSnap.data()?['strikes'] as num?)?.toInt() ?? 0;
            int newS = strikes + 1;

            tx.update(userRef, {
              'confiabilidad': (score - 20).clamp(0, 100),
              'strikes': newS,
              'citas_consecutivas_exitosas': 0, // 🔥 BORRADO DE RACHA
              'userStatus': newS >= 5 ? 'blocked_permanent' : 'blocked',
              'bloqueadoHasta': Timestamp.fromDate(DateTime.now().add(Duration(days: newS * 5))),
            });
          }
          tx.update(citaRef, {'status': 'finished', 'resultado': 'absent_confessed', 'culpableUid': user.uid});
        }
      });
      if (mounted) {
        // 🔥 TEXTO FINAL DETALLADO CON BORRADO DE RACHA
        _mostrarDialogoMatchy(
          titulo: "REPORTE DE SANCIÓN",
          mensaje: "Has admitido tu inasistencia. Se han aplicado las siguientes sanciones:\n\n"
              "📉 -20 Puntos de confiabilidad.\n"
              "📉 Tu Racha se ha reiniciado a 0.\n"
              "⚠️ +1 Strike en tu historial.\n\n"
              "CONSECUENCIA:\n"
              "Tu cuenta ha sido BLOQUEADA TEMPORALMENTE. La duración del bloqueo aumenta con cada Strike acumulado.\n\n"
              "🚫 ¡OJO! Si llegas a 5 Strikes, el bloqueo será PERMANENTE e irreversible.",
          icono: Icons.warning_amber_rounded,
          color: const Color(0xFFFF5252),
          botonTexto: "ENTENDIDO",
          onCerrar: () => HomeShell.go(context, index: 1),
        );
      }
    } catch (e) { if (mounted) _mostrarError("$e"); }
    finally { if (mounted) setState(() => _isLoading = false); }
  }

  // ⏳ EL JUEZ (TIMER 00:00:00)
  Future<void> _ejecutarCastigoAutomatico() async {
    setState(() => _isLoading = true);
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;

    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final citaRef = FirebaseFirestore.instance.collection('citas').doc(widget.citaId);
        final doc = await tx.get(citaRef);
        if (!doc.exists) return; // Si la cita no existe, salimos
        final data = doc.data()!;

        // 1. REVISIÓN DE SEGURIDAD
        bool soyOwner = data['ownerUid'] == myUid;
        bool safeGPS = soyOwner ? (data['ownerSafeGPS'] == true) : (data['matchySafeGPS'] == true);
        bool acuerdoCerrado = data['resultado'] == 'mutual_agreement';
        bool yaFinalizada = data['status'] == 'finished' || data['status'] == 'dispute';

        if (yaFinalizada) return;

        // 2. SENTENCIA
        if (safeGPS) {
          tx.update(citaRef, {'status': 'dispute'});
        } else if (acuerdoCerrado) {
          // No castigo
        } else {
          // ❌ CULPABLE: CASTIGO AUTOMÁTICO
          final userRef = FirebaseFirestore.instance.collection('users').doc(myUid);
          final userSnap = await tx.get(userRef);

          if (userSnap.exists) {
            int score = (userSnap.data()?['confiabilidad'] as num?)?.toInt() ?? 100;
            int strikes = (userSnap.data()?['strikes'] as num?)?.toInt() ?? 0;
            int newS = strikes + 1;

            tx.update(userRef, {
              'confiabilidad': (score - 20).clamp(0, 100),
              'strikes': newS,
              'citas_consecutivas_exitosas': 0, // 🔥 BORRADO DE RACHA
              'userStatus': newS >= 5 ? 'blocked_permanent' : 'blocked',
              'bloqueadoHasta': Timestamp.fromDate(DateTime.now().add(Duration(days: newS * 5))),
            });
          }

          tx.update(citaRef, {'status': 'finished', 'resultado': 'expired_timeout'});
        }
      });

      if (mounted) HomeShell.go(context, index: 1);

    } catch (e) {
      debugPrint("❌ JUEZ ERROR: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error en castigo automático: $e"), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                  const SizedBox(height: 20),
                  const Icon(Icons.timer_off_outlined, color: Colors.redAccent, size: 50),
                  const Text("TIEMPO RESTANTE", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, fontFamily: 'Poppins')),

                  const SizedBox(height: 15),
                  Container(height: 90, width: double.infinity, alignment: Alignment.center, decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.redAccent.withOpacity(0.5), width: 2)), child: FittedBox(fit: BoxFit.scaleDown, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Text(_tiempoRestante, style: const TextStyle(color: Color(0xFFFF5252), fontSize: 50, fontFamily: 'monospace', fontWeight: FontWeight.w900, letterSpacing: 2.0))))),

                  const SizedBox(height: 25),
                  // 🔥 GUÍA DE CONSECUENCIAS (TEXTOS EXACTOS ORDENADOS)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text("GUÍA DE CONSECUENCIAS", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                        SizedBox(height: 12),
                        // VERDE
                        _GuiaItem(icon: Icons.location_pin, color: Color(0xFF00E676), text: "ESTOY AQUÍ: Validación por GPS. Protege tus puntos al 100%, asegura tu racha y evita sanciones."),
                        SizedBox(height: 10),
                        // AZUL
                        _GuiaItem(icon: Icons.handshake_rounded, color: Color(0xFF64B5F6), text: "ACUERDO MUTUO: Requiere que AMBOS acepten (-10 Pts). ⚠️ Si solo uno (o ninguno) confirma, se aplicará: Bloqueo Temporal, -20 Pts y Borrado de Racha."),
                        SizedBox(height: 10),
                        // ROJO
                        _GuiaItem(icon: Icons.cancel, color: Color(0xFFFF5252), text: "ASUMO MI FALTA: Cancelación unilateral. -20 Pts + Strike + Borrado de Racha. (Genera BLOQUEO TEMPORAL)."),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),

                  if (_isLoading) const Padding(padding: EdgeInsets.only(top: 20), child: CircularProgressIndicator(color: Colors.white)) else ...[
                    _SentenciaButton(text: "YO SÍ ASISTÍ, MI MATCHY NO", icon: Icons.person_pin_circle_rounded, gradient: [const Color(0xFF00E676), const Color(0xFF00C853)], onTap: _verificarUbicacionYReclamar),
                    const SizedBox(height: 16),
                    _SentenciaButton(text: "NINGUNO ASISTIÓ / ACUERDO", icon: Icons.handshake_rounded, gradient: [const Color(0xFF64B5F6), const Color(0xFF1976D2)], onTap: _gestionarBotonAzul),
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

class _GuiaItem extends StatelessWidget {
  final IconData icon; final Color color; final String text;
  const _GuiaItem({required this.icon, required this.color, required this.text});
  @override Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Poppins', fontWeight: FontWeight.w500)))
    ]);
  }
}

class _SentenciaButton extends StatelessWidget {
  final String text; final IconData icon; final List<Color> gradient; final VoidCallback onTap;
  const _SentenciaButton({required this.text, required this.icon, required this.gradient, required this.onTap});
  @override Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: Container(width: double.infinity, height: 60, padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(gradient: LinearGradient(colors: gradient), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white24)), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: Colors.white, size: 22), const SizedBox(width: 10), Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14))))])));
  }
}