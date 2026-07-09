// 📂 lib/screens/reporte_inasistencia_screen.dart
// ✅ REPORTE DE INASISTENCIA (RESOLUCIÓN MANUAL DE CITAS EN CONFLICTO)
// 🔥 Se llega aquí desde citas_screen.dart cuando una cita está urgente (pasó su hora) o tiene
//    una propuesta/solicitud de acuerdo mutuo en curso.
// ⏱️ RELOJ EN VIVO: cuenta regresiva real (Timer.periodic, tick cada segundo) hacia el deadline
//    = hora de la cita + kVentanaResolucion (60 min). Formato HH:MM:SS, caja roja, ícono de alarma.
// 🆕 GPS DINÁMICO: radio efectivo = 40m base + el margen de error (accuracy) que el GPS reporta
//    en el momento, con techo absoluto de 100m. Se toman hasta 3 lecturas en ~2 segundos y se
//    usa la más precisa.
// 🛡️ Guía de Consecuencias, reloj, chevron: sin cambios de diseño.
// 🆕 ORDEN: bloque de código/GPS al final, después de los 3 botones de resolución.
// 🐛 FIX NUEVO: los 3 botones compartían UNA sola variable de estado (_procesandoBoton), así que
//    al tocar cualquiera, los 3 spinners giraban a la vez. Ahora cada botón tiene su propio
//    identificador (_botonEnProceso == 'yo_asisti' / 'ninguno_asistio' / 'no_pude_asistir') —
//    solo el que tocaste muestra su spinner. Los 3 siguen DESHABILITADOS mientras cualquiera
//    está en curso (correcto, evita doble-toque accidental), pero solo uno gira visualmente.
// 🆕 FIX "YO SÍ ASISTÍ, MI MATCHY NO": antes, al confirmar con éxito, solo mostraba una burbuja
//    genérica y dejaba al usuario parado en la misma pantalla con los 3 botones todavía activos
//    — daba la sensación de que el botón no hacía nada. Ahora muestra un mensaje claro
//    explicando que su asistencia ya quedó registrada y que está a salvo, y luego navega a
//    PanelScreen (sin poder volver atrás). Los otros 2 botones y el resto del archivo quedan
//    exactamente igual.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

import 'package:proyectos_matchy/screens/panel_screen.dart'; // 🆕 NUEVO

class ReporteInasistenciaScreen extends StatefulWidget {
  final String citaId;
  const ReporteInasistenciaScreen({super.key, required this.citaId});

  @override
  State<ReporteInasistenciaScreen> createState() => _ReporteInasistenciaScreenState();
}

class _ReporteInasistenciaScreenState extends State<ReporteInasistenciaScreen> {
  static const Duration kVentanaResolucion = Duration(minutes: 60);

  static const double kRadioGPSBase = 40.0;
  static const double kRadioGPSTecho = 100.0;

  final TextEditingController _codigoCtrl = TextEditingController();
  bool _confirmandoCodigo = false;

  // 🐛 FIX: en vez de un booleano compartido, guardamos CUÁL botón está procesando
  String? _botonEnProceso;

  Timer? _tickTimer;

  @override
  void initState() {
    super.initState();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _codigoCtrl.dispose();
    super.dispose();
  }

  DateTime? _parseFechaHora(String fTexto, String hTexto) {
    try {
      final parts = fTexto.trim().split(RegExp(r'[/ -]'));
      int d = int.parse(parts[0]), m = int.parse(parts[1]), y = int.parse(parts[2]);
      String rawHora = hTexto.toUpperCase().replaceAll('.', '').trim();
      bool esPM = rawHora.contains("PM");
      final tP = rawHora.replaceAll(RegExp(r'[^0-9:]'), '').split(':');
      if (tP.isEmpty || tP[0].isEmpty) return null;
      int hh = int.parse(tP[0]);
      int mm = tP.length > 1 ? int.parse(tP[1]) : 0;
      if (esPM && hh != 12) hh += 12; else if (!esPM && hh == 12) hh = 0;
      return DateTime(y, m, d, hh, mm);
    } catch (_) {
      return null;
    }
  }

  // ===========================================================================
  // 🔔 BURBUJA FLOTANTE (mismo patrón usado en todo el proyecto)
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

  // ===========================================================================
  // 🆕 GPS DINÁMICO: mejor lectura de hasta 3 intentos + radio efectivo con techo
  // ===========================================================================
  Future<Position?> _obtenerMejorUbicacion({int intentos = 3}) async {
    Position? mejor;
    for (int i = 0; i < intentos; i++) {
      try {
        final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        if (mejor == null || pos.accuracy < mejor.accuracy) {
          mejor = pos;
        }
      } catch (_) {
        // seguimos intentando con la siguiente lectura
      }
      if (i < intentos - 1) await Future.delayed(const Duration(milliseconds: 700));
    }
    return mejor;
  }

  double _radioEfectivo(double accuracy) {
    return (kRadioGPSBase + accuracy).clamp(kRadioGPSBase, kRadioGPSTecho);
  }

  // Devuelve null si la validación pasó, o un mensaje de error si no
  Future<String?> _validarGPS({required double lat, required double lng}) async {
    final pos = await _obtenerMejorUbicacion();
    if (pos == null) {
      return "No pudimos obtener tu ubicación. Activa el GPS e inténtalo de nuevo.";
    }
    final distancia = Geolocator.distanceBetween(pos.latitude, pos.longitude, lat, lng);
    final radioEfectivo = _radioEfectivo(pos.accuracy);
    if (distancia > radioEfectivo) {
      return "Estás a ${distancia.round()}m del lugar. Tu GPS tiene un margen de ±${pos.accuracy.round()}m ahora mismo — si estás en el lugar, intenta de nuevo en unos segundos o acércate a una ventana.";
    }
    return null;
  }

  // ===========================================================================
  // 🆕 BLOQUE: confirmar código + validar GPS dinámico
  // ===========================================================================
  Future<void> _confirmarConCodigo({
    required String codigoDelOtro,
    required bool isOwner,
    required double lat,
    required double lng,
  }) async {
    if (_confirmandoCodigo) return;
    final ingresado = _codigoCtrl.text.trim().toUpperCase();

    if (ingresado.isEmpty) {
      _mostrarBurbuja("Escribe el código que te dio tu Matchy.", Colors.orangeAccent, Icons.info_outline_rounded);
      return;
    }

    setState(() => _confirmandoCodigo = true);

    try {
      if (ingresado != codigoDelOtro.toUpperCase()) {
        _mostrarBurbuja("Código incorrecto. Revísalo con tu Matchy.", const Color(0xFFFF5252), Icons.error_outline_rounded);
        return;
      }

      final errorGPS = await _validarGPS(lat: lat, lng: lng);
      if (errorGPS != null) {
        _mostrarBurbuja(errorGPS, const Color(0xFFFF5252), Icons.social_distance_rounded);
        return;
      }

      final campo = isOwner ? 'gpsCheckOwner' : 'gpsCheckMatchy';
      await FirebaseFirestore.instance.collection('citas').doc(widget.citaId).update({campo: true});

      if (!mounted) return;
      _mostrarBurbuja("¡Cita confirmada! Tu asistencia quedó registrada.", const Color(0xFF00E676), Icons.check_circle_rounded);
      _codigoCtrl.clear();
    } catch (e) {
      _mostrarBurbuja("Error al confirmar: $e", const Color(0xFFFF5252), Icons.error_outline_rounded);
    } finally {
      if (mounted) setState(() => _confirmandoCodigo = false);
    }
  }

  // ===========================================================================
  // 🛡️ BOTONES DE RESOLUCIÓN (ahora con spinner individual por botón)
  // ===========================================================================

  Future<void> _accionYoAsisti({required bool isOwner, required double lat, required double lng}) async {
    if (_botonEnProceso != null) return;
    setState(() => _botonEnProceso = 'yo_asisti');
    try {
      final errorGPS = await _validarGPS(lat: lat, lng: lng);
      if (errorGPS != null) {
        _mostrarBurbuja(errorGPS, const Color(0xFFFF5252), Icons.social_distance_rounded);
        return;
      }
      final campo = isOwner ? 'gpsCheckOwner' : 'gpsCheckMatchy';
      await FirebaseFirestore.instance.collection('citas').doc(widget.citaId).update({campo: true});
      if (!mounted) return;

      // 🆕 Mensaje claro de que ya quedó a salvo, y navegación a PanelScreen
      _mostrarBurbuja(
        "Tu registro de asistencia ya quedó confirmado. Espera a que se cumplan los 60 minutos de esta cita, o a que tu Matchy también confirme — tú ya estás a salvo.",
        const Color(0xFF00E676),
        Icons.check_circle_rounded,
      );
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const PanelScreen()),
            (route) => false,
      );
    } catch (e) {
      _mostrarBurbuja("Error: $e", const Color(0xFFFF5252), Icons.error_outline_rounded);
    } finally {
      if (mounted) setState(() => _botonEnProceso = null);
    }
  }

  Future<void> _accionNingunoAsistio({required bool isOwner, required bool elOtroYaPropuso}) async {
    if (_botonEnProceso != null) return;
    setState(() => _botonEnProceso = 'ninguno_asistio');
    try {
      final campoMio = isOwner ? 'ownerPropusoAcuerdo' : 'matchyPropusoAcuerdo';
      final Map<String, dynamic> update = {campoMio: true};
      if (elOtroYaPropuso) {
        update['status'] = 'mutual_agreement_finish';
      } else {
        update['status'] = 'mutual_agreement_pending';
      }
      await FirebaseFirestore.instance.collection('citas').doc(widget.citaId).update(update);
      if (!mounted) return;
      _mostrarBurbuja(
        elOtroYaPropuso ? "Acuerdo confirmado. Se aplicarán -10 puntos a ambos." : "Propuesta enviada. Esperando que tu Matchy confirme.",
        const Color(0xFF448AFF),
        Icons.handshake_rounded,
      );
    } catch (e) {
      _mostrarBurbuja("Error: $e", const Color(0xFFFF5252), Icons.error_outline_rounded);
    } finally {
      if (mounted) setState(() => _botonEnProceso = null);
    }
  }

  Future<void> _accionNoPudeAsistir() async {
    if (_botonEnProceso != null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.white24)),
        title: const Text("¿ASUMIR TU FALTA?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontFamily: 'Poppins')),
        content: const Text(
          "Esto te restará -20 puntos, sumará un strike, y borrará tu racha actual — lo que puede generar un bloqueo temporal. Úsalo solo si de verdad no pudiste asistir.",
          style: TextStyle(color: Colors.white70, fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCELAR", style: TextStyle(color: Colors.white54))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("SÍ, ASUMIR", style: TextStyle(color: Color(0xFFFF5252), fontWeight: FontWeight.w900))),
        ],
      ),
    );
    if (confirmar != true) return;

    setState(() => _botonEnProceso = 'no_pude_asistir');
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance.runTransaction((tx) async {
        final citaRef = FirebaseFirestore.instance.collection('citas').doc(widget.citaId);
        final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
        final citaSnap = await tx.get(citaRef);
        final userSnap = await tx.get(userRef);

        final citaData = citaSnap.data() ?? {};
        final isOwner = citaData['ownerUid'] == user.uid;
        final campo = isOwner ? 'ownerCastigado' : 'matchyCastigado';

        int score = (userSnap.data()?['confiabilidad'] as num?)?.toInt() ?? 100;
        int strikes = (userSnap.data()?['strikes'] as num?)?.toInt() ?? 0;
        int newStrikes = strikes + 1;

        tx.update(userRef, {
          'confiabilidad': (score - 20).clamp(0, 100),
          'strikes': newStrikes,
          'citas_consecutivas_exitosas': 0,
          'userStatus': newStrikes >= 5 ? 'blocked_permanent' : 'blocked',
          'bloqueadoHasta': Timestamp.fromDate(DateTime.now().add(Duration(days: newStrikes * 5))),
        });

        tx.update(citaRef, {campo: true, 'status': 'finished', 'resultado': 'self_reported_absence'});
      });

      if (!mounted) return;
      _mostrarBurbuja("Registrado. Se aplicaron -20 puntos, un strike y se borró tu racha.", const Color(0xFFFF5252), Icons.report_problem_rounded);
      await Future.delayed(const Duration(seconds: 2));
      if (mounted && Navigator.of(context).canPop()) Navigator.of(context).pop();
    } catch (e) {
      _mostrarBurbuja("Error: $e", const Color(0xFFFF5252), Icons.error_outline_rounded);
    } finally {
      if (mounted) setState(() => _botonEnProceso = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover)),

          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('citas').doc(widget.citaId).snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: Colors.white));
              if (!snap.data!.exists) return const Center(child: Text("Esta cita ya no existe", style: TextStyle(color: Colors.white)));

              final data = snap.data!.data() as Map<String, dynamic>;
              final isOwner = data['ownerUid'] == myUid;
              final codigoOwner = (data['codigoOwner'] ?? '').toString();
              final codigoMatchy = (data['codigoMatchy'] ?? '').toString();
              final miCodigo = isOwner ? codigoOwner : codigoMatchy;
              final codigoDelOtro = isOwner ? codigoMatchy : codigoOwner;
              final lugarNombre = (data['lugarNombre'] ?? 'Lugar').toString();
              final lugarDireccion = (data['lugarDireccion'] ?? '').toString();
              final lat = (data['latitude'] as num?)?.toDouble() ?? 0.0;
              final lng = (data['longitude'] as num?)?.toDouble() ?? 0.0;
              final otroNombre = isOwner ? (data['matchyNombre'] ?? 'tu Matchy').toString() : (data['ownerNombre'] ?? 'tu Matchy').toString();
              final elOtroYaPropusoAcuerdo = isOwner ? data['matchyPropusoAcuerdo'] == true : data['ownerPropusoAcuerdo'] == true;

              DateTime? fechaReal;
              final sched = data['scheduledAt'];
              if (sched is Timestamp) {
                fechaReal = sched.toDate();
              } else {
                fechaReal = _parseFechaHora((data['fecha'] ?? '').toString(), (data['hora'] ?? '').toString());
              }
              final deadline = fechaReal?.add(kVentanaResolucion);
              Duration restante = Duration.zero;
              if (deadline != null) {
                final calc = deadline.difference(DateTime.now());
                restante = calc.isNegative ? Duration.zero : calc;
              }

              return SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 70, 20, 60),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(child: Image.asset('assets/images/logomatchyplano.png', height: 45)),
                      const SizedBox(height: 20),

                      // 1️⃣ RELOJ
                      _buildRelojCuentaRegresiva(restante, lugarNombre, lugarDireccion),

                      const SizedBox(height: 20),

                      // 2️⃣ GUÍA DE CONSECUENCIAS
                      _buildGuiaConsecuencias(),

                      const SizedBox(height: 24),

                      // 3️⃣ LOS 3 BOTONES DE RESOLUCIÓN (spinner individual por botón)
                      _BotonResolucion(
                        texto: "YO SÍ ASISTÍ, MI MATCHY NO",
                        icon: Icons.location_on_rounded,
                        colores: const [Color(0xFF00E676), Color(0xFF00B84D)],
                        cargando: _botonEnProceso == 'yo_asisti',
                        deshabilitado: _botonEnProceso != null,
                        onTap: () => _accionYoAsisti(isOwner: isOwner, lat: lat, lng: lng),
                      ),
                      const SizedBox(height: 12),
                      _BotonResolucion(
                        texto: "NINGUNO ASISTIÓ / ACUERDO",
                        icon: Icons.diamond_rounded,
                        colores: const [Color(0xFF448AFF), Color(0xFF2962FF)],
                        cargando: _botonEnProceso == 'ninguno_asistio',
                        deshabilitado: _botonEnProceso != null,
                        onTap: () => _accionNingunoAsistio(isOwner: isOwner, elOtroYaPropuso: elOtroYaPropusoAcuerdo),
                      ),
                      const SizedBox(height: 12),
                      _BotonResolucion(
                        texto: "NO PUDE ASISTIR",
                        icon: Icons.cancel_rounded,
                        colores: const [Color(0xFFFF5252), Color(0xFFD50000)],
                        cargando: _botonEnProceso == 'no_pude_asistir',
                        deshabilitado: _botonEnProceso != null,
                        onTap: _accionNoPudeAsistir,
                      ),

                      const SizedBox(height: 24),

                      // 4️⃣ BLOQUE DE CÓDIGO
                      _buildBloqueCodigo(
                        miCodigo: miCodigo,
                        codigoDelOtro: codigoDelOtro,
                        isOwner: isOwner,
                        lat: lat,
                        lng: lng,
                        otroNombre: otroNombre,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          Positioned(
            top: 50, left: 16,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
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

  Widget _buildRelojCuentaRegresiva(Duration restante, String lugarNombre, String lugarDireccion) {
    final horas = restante.inHours.toString().padLeft(2, '0');
    final minutos = (restante.inMinutes % 60).toString().padLeft(2, '0');
    final segundos = (restante.inSeconds % 60).toString().padLeft(2, '0');

    return Column(
      children: [
        const Icon(Icons.alarm_rounded, color: Color(0xFFFF5252), size: 40),
        const SizedBox(height: 6),
        const Text("TIEMPO RESTANTE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, fontFamily: 'Poppins', letterSpacing: 1.0)),
        const SizedBox(height: 4),
        Text(
          "$lugarNombre${lugarDireccion.isNotEmpty ? ' — $lugarDireccion' : ''}",
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white54, fontSize: 12, fontFamily: 'Poppins'),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFF5252), width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(
            "$horas:$minutos:$segundos",
            style: const TextStyle(color: Color(0xFFFF5252), fontSize: 36, fontWeight: FontWeight.w900, fontFamily: 'Poppins', letterSpacing: 2),
          ),
        ),
      ],
    );
  }

  Widget _buildGuiaConsecuencias() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0x20FFFFFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("GUÍA DE CONSECUENCIAS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15, fontFamily: 'Poppins')),
          const SizedBox(height: 14),
          _filaConsecuencia(icon: Icons.location_on_rounded, color: const Color(0xFF00E676), texto: "ESTOY AQUÍ: Validación por GPS. Protege tus puntos al 100% y asegura tu racha."),
          const SizedBox(height: 12),
          _filaConsecuencia(icon: Icons.diamond_rounded, color: const Color(0xFF448AFF), texto: "ACUERDO MUTUO: Requiere que AMBOS acepten (-10 Pts)."),
          const SizedBox(height: 12),
          _filaConsecuencia(icon: Icons.cancel_rounded, color: const Color(0xFFFF5252), texto: "ASUMO MI FALTA: Cancelación unilateral. -20 Pts + Strike + Borrado de Racha."),
        ],
      ),
    );
  }

  Widget _filaConsecuencia({required IconData icon, required Color color, required String texto}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(texto, style: const TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'Poppins', height: 1.3))),
      ],
    );
  }

  Widget _buildBloqueCodigo({
    required String miCodigo,
    required String codigoDelOtro,
    required bool isOwner,
    required double lat,
    required double lng,
    required String otroNombre,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0x20FFFFFF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("TU CÓDIGO", style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Poppins', letterSpacing: 1.0)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFBEB3FF))),
            alignment: Alignment.center,
            child: Text(
              miCodigo.isEmpty ? '········' : miCodigo,
              style: const TextStyle(color: Color(0xFFBEB3FF), fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 6, fontFamily: 'Poppins'),
            ),
          ),

          const SizedBox(height: 20),

          const Text("CONFIRMAR CITA", style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Poppins', letterSpacing: 1.0)),
          const SizedBox(height: 8),
          TextField(
            controller: _codigoCtrl,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 3, fontFamily: 'Poppins'),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: "CÓDIGO DE $otroNombre",
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 13, letterSpacing: 1, fontFamily: 'Poppins'),
              filled: true,
              fillColor: Colors.white.withOpacity(0.08),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _confirmandoCodigo ? null : () => _confirmarConCodigo(codigoDelOtro: codigoDelOtro, isOwner: isOwner, lat: lat, lng: lng),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF00E676), Color(0xFF00B84D)]),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: _confirmandoCodigo
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : const Text("CONFIRMAR CITA", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 15, fontFamily: 'Poppins')),
            ),
          ),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(12)),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, color: Colors.white54, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Por tu seguridad, nunca compartas tu código por chat. Entrégalo solo en persona.",
                    style: TextStyle(color: Colors.white54, fontSize: 12, fontFamily: 'Poppins', height: 1.3),
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

// ============================================================================
// 🔘 BOTÓN DE RESOLUCIÓN (widget compartido por los 3 botones)
// 🐛 FIX: nuevo parámetro `deshabilitado`, separado de `cargando` — así el spinner solo se
// muestra en el botón que se tocó, pero los 3 se bloquean mientras cualquiera está en curso.
// ============================================================================
class _BotonResolucion extends StatelessWidget {
  final String texto;
  final IconData icon;
  final List<Color> colores;
  final bool cargando;
  final bool deshabilitado;
  final VoidCallback onTap;

  const _BotonResolucion({
    required this.texto,
    required this.icon,
    required this.colores,
    required this.cargando,
    required this.deshabilitado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: deshabilitado ? null : onTap,
      child: Opacity(
        opacity: deshabilitado && !cargando ? 0.5 : 1.0,
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colores, begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 3))],
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(texto, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, fontFamily: 'Poppins')),
                ),
              ),
              if (cargando)
                const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              else
                const Icon(Icons.chevron_right_rounded, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }
}