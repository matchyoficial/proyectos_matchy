// 📂 lib/screens/cita_detalle_screen.dart
// ✅ DETALLE DE CITA CONFIRMADA (status: matched) — TARJETA DE CÓDIGO Y GPS
// 🔥 Recibe todos sus datos de visualización por constructor (lugar, Matchy, fecha/hora,
//    intención/preferencia, ambos códigos, isOwner) — no necesita StreamBuilder para pintar
//    la pantalla, solo escribe a Firestore cuando se confirma el código.
// 🆕 GPS DINÁMICO: radio efectivo = 35m base + el margen de error (accuracy) que el GPS reporta
//    en el momento, con techo absoluto de 100m. Se toman hasta 3 lecturas en ~2 segundos y se
//    usa la más precisa. El lat/lng del lugar se obtiene con una consulta puntual a
//    citas/{citaId} al momento de confirmar (no venía en el constructor).
// 🎨 REDISEÑO: encabezado fusionado (foto del lugar + foto del Matchy sobrepuesta abajo-derecha
//    con bordes redondeados, clickeable a su perfil), título "DATOS DE TU CITA", y una sola
//    cápsula de vidrio con 5 filas (persona / lugar / fecha en letras + hora / intención /
//    preferencia), todo protegido con FittedBox para que el texto nunca se salga.
// 🆕 BURBUJA 24H: el campo de código ahora vuelve a avisar "Este espacio para tu código estará
//    habilitado 24 horas antes de tu cita." si lo tocas antes de tiempo, y no deja escribir.
// 🆕 CIERRE DE CITA + PUNTOS (vía transacción de Firestore, sin condiciones de carrera):
//    al confirmar mi código+GPS, si el otro usuario YA había confirmado el suyo, la cita se
//    cierra en la misma operación (status: 'finished', resultado: 'completada_exitosa'), se
//    suma +1 a citas_consecutivas_exitosas de ambos, y cada 3 citas consecutivas exitosas se
//    suman +20 a confiabilidad de ambos (tope 100) — y navego a ConfirmarCitaScreen (sin poder
//    volver atrás). Si el otro AÚN no ha confirmado, solo guardo mi lado y muestro la burbuja
//    "DILE A TU MATCHY QUE PONGA TU CÓDIGO PARA CONFIRMAR LA CITA", sin navegar. Se agregó un
//    spinner "LEYENDO CÓDIGOS..." con mínimo de 1.5s visible, y un chequeo de seguridad interno
//    (la cita debe seguir en 'matched') por si el Juez Supremo de citas_screen.dart ya la cerró
//    por tiempo límite antes de terminar de confirmar.
// 🆕 FIX NAVEGACIÓN AUTOMÁTICA (usuario que confirma primero): antes, quien ponía su código
//    de primero solo escribía su lado en Firestore y se quedaba esperando sin ningún aviso —
//    si el otro confirmaba minutos después, su pantalla nunca se enteraba y quedaba "colgada"
//    sin ir a ConfirmarCitaScreen. Ahora esta pantalla escucha en tiempo real el documento de
//    la cita (snapshots) mientras está abierta: en cuanto detecta que quedó status:'finished'
//    + resultado:'completada_exitosa' (sin importar quién la cerró ni cuánto tiempo pasó),
//    navega sola a ConfirmarCitaScreen, leyendo antes los puntos/racha actualizados del propio
//    usuario.
// 🆕 El código ya NO se borra después de mostrar "DILE A TU MATCHY..." — se deja escrito en el
//    campo para que, si el usuario quiere, pueda darle "Confirmar Cita" otra vez como respaldo
//    manual.
// 🆕 Ese respaldo manual quedó blindado: si el usuario le da "Confirmar Cita" de nuevo después
//    de que la cita YA se cerró con éxito (mientras él esperaba), ya no le sale el mensaje
//    falso de "se cerró por tiempo límite" — ahora se distingue ese caso y lo manda igual a
//    ConfirmarCitaScreen.
//    Todo lo demás del archivo (lógica de código/GPS, _obtenerMejorUbicacion, _radioEfectivo,
//    _fechaAmigable) queda exactamente igual a la versión anterior. No se tocó citas_screen.dart
//    ni confirmar_cita.dart.

import 'dart:async'; // 🆕 NUEVO — necesario para StreamSubscription
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geolocator/geolocator.dart';

import 'package:proyectos_matchy/screens/perfil_usuariox_screen.dart';
import 'package:proyectos_matchy/screens/confirmar_cita.dart'; // 🆕 NUEVO

class CitaDetalleScreen extends StatefulWidget {
  final String citaId;
  final String lugarId;
  final String lugarNombre;
  final String lugarDireccion;
  final String lugarFotoPortada;
  final String matchyNombre;
  final String matchyFoto;
  final String matchyUid;
  final int matchyEdad;
  final String fecha;
  final String hora;
  final String intencion;
  final String preferencia;
  final String miCodigoCita;
  final String codigoDelOtro;
  final bool isOwner;
  final DateTime citaDateTime;

  const CitaDetalleScreen({
    super.key,
    required this.citaId,
    required this.lugarId,
    required this.lugarNombre,
    required this.lugarDireccion,
    required this.lugarFotoPortada,
    required this.matchyNombre,
    required this.matchyFoto,
    required this.matchyUid,
    required this.matchyEdad,
    required this.fecha,
    required this.hora,
    required this.intencion,
    required this.preferencia,
    required this.miCodigoCita,
    required this.codigoDelOtro,
    required this.isOwner,
    required this.citaDateTime,
  });

  @override
  State<CitaDetalleScreen> createState() => _CitaDetalleScreenState();
}

class _CitaDetalleScreenState extends State<CitaDetalleScreen> {
  // 🆕 GPS DINÁMICO
  static const double kRadioGPSBase = 35.0;    // se queda igual, sin tocar
  static const double kRadioGPSTecho = 100.0;  // techo absoluto, nunca se supera

  // 🎨 ZONA DE CHINCHES — ENCABEZADO FUSIONADO
  static const double kFotoLugarHeight = 200.0;
  static const double kFotoLugarRadius = 24.0;
  static const double kUserPhotoSize = 90.0;
  static const double kUserPhotoMargin = 15.0;
  static const double kUserPhotoRadius = 18.0; // bordes redondeados, NO circular
  static const double kTitleSize = 20.0;
  static const Color kGlassColor = Color(0x33FFFFFF);
  static const Color kAccentColor = Color(0xFFBEB3FF);

  final TextEditingController _codigoCtrl = TextEditingController();
  bool _confirmando = false;

  // 🆕 Oyente en tiempo real sobre el documento de la cita, y bandera para no navegar dos veces.
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _citaListener;
  bool _yaNavegueAExito = false;

  @override
  void initState() {
    super.initState();
    _iniciarEscuchaCita(); // 🆕 NUEVO
  }

  @override
  void dispose() {
    _citaListener?.cancel(); // 🆕 NUEVO
    _codigoCtrl.dispose();
    super.dispose();
  }

  // ===========================================================================
  // 🆕 OYENTE EN TIEMPO REAL: detecta cuando el OTRO usuario cierra la cita con éxito
  // mientras esta pantalla sigue abierta esperando, y navega solo a ConfirmarCitaScreen.
  // ===========================================================================
  void _iniciarEscuchaCita() {
    _citaListener = FirebaseFirestore.instance
        .collection('citas')
        .doc(widget.citaId)
        .snapshots()
        .listen((snap) {
      if (!mounted || _yaNavegueAExito) return;
      final data = snap.data();
      if (data == null) return;
      if (data['status'] == 'finished' && data['resultado'] == 'completada_exitosa') {
        _navegarAExitoDesdeFirestore();
      }
    });
  }

  // 🆕 Lleva a ConfirmarCitaScreen leyendo los datos frescos del propio usuario (para saber si
  // su racha llegó a 3 y ganó puntos) — usado tanto por el oyente automático de arriba como por
  // el respaldo manual dentro de _confirmarCita() cuando la cita ya se cerró con éxito.
  Future<void> _navegarAExitoDesdeFirestore() async {
    if (_yaNavegueAExito) return;
    _yaNavegueAExito = true;
    await _citaListener?.cancel();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final myUid = user.uid;
    final otherUid = widget.matchyUid;

    bool ganaronPuntos = false;
    int citasFaltantes = 0;
    String miNombreFresco = 'Tú';
    String miFotoFresca = '';
    String otroNombreFresco = widget.matchyNombre;
    String otroFotoFresca = widget.matchyFoto;

    try {
      final miSnap = await FirebaseFirestore.instance.collection('users').doc(myUid).get();
      final miData = miSnap.data() ?? {};
      miNombreFresco = (miData['nombre'] ?? 'Tú').toString();
      miFotoFresca = (miData['profilePhotoUrl'] ?? '').toString();
      final miContadorFinal = (miData['citas_consecutivas_exitosas'] as num?)?.toInt() ?? 0;
      ganaronPuntos = miContadorFinal == 3;
      citasFaltantes = ganaronPuntos ? 0 : (3 - (miContadorFinal % 3));
    } catch (_) {}

    try {
      final otroSnap = await FirebaseFirestore.instance.collection('users').doc(otherUid).get();
      final otroData = otroSnap.data() ?? {};
      otroNombreFresco = (otroData['nombre'] ?? widget.matchyNombre).toString();
      otroFotoFresca = (otroData['profilePhotoUrl'] ?? '').toString();
    } catch (_) {}

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => ConfirmarCitaScreen(
          ownerNombre: miNombreFresco,
          ownerFoto: miFotoFresca,
          matchyNombre: otroNombreFresco,
          matchyFoto: otroFotoFresca,
          ganaronPuntos: ganaronPuntos,
          citasFaltantes: citasFaltantes,
        ),
      ),
          (route) => false,
    );
  }

  // 🐛 FIX: mismo formateador exacto que usa _CitaCard en citas_screen.dart, para que la fecha
  // se vea en palabras y consistente en toda la app.
  String _fechaAmigable(DateTime d) {
    const List<String> dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    const List<String> meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return "${dias[d.weekday - 1]} ${d.day} de ${meses[d.month - 1]}";
  }

  // 🆕 ¿ya se puede usar el campo de código? (24 horas antes de la cita)
  bool get _codigoHabilitado => DateTime.now().isAfter(widget.citaDateTime.subtract(const Duration(hours: 24)));

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

  // ===========================================================================
  // ✍️ CONFIRMAR CITA (código + GPS dinámico + transacción de cierre/puntos)
  // ===========================================================================
  Future<void> _confirmarCita() async {
    if (_confirmando) return;
    final ingresado = _codigoCtrl.text.trim().toUpperCase();

    if (ingresado.isEmpty) {
      _mostrarBurbuja("Escribe el código que te dio tu Matchy.", Colors.orangeAccent, Icons.info_outline_rounded);
      return;
    }

    // 🆕 Puerta de las 24 horas (respaldo por si se llega a confirmar sin pasar por el campo)
    if (!_codigoHabilitado) {
      _mostrarBurbuja("Este espacio para tu código estará habilitado 24 horas antes de tu cita.", Colors.orangeAccent, Icons.lock_clock_rounded);
      return;
    }

    setState(() => _confirmando = true);
    final inicio = DateTime.now();

    try {
      if (ingresado != widget.codigoDelOtro.toUpperCase()) {
        _mostrarBurbuja("Código incorrecto. Revísalo con tu Matchy.", const Color(0xFFFF5252), Icons.error_outline_rounded);
        return;
      }

      // Obtenemos lat/lng directo de la cita (no venía en el constructor)
      double lat = 0.0, lng = 0.0;
      try {
        final citaSnapPrevia = await FirebaseFirestore.instance.collection('citas').doc(widget.citaId).get();
        final cdataPrevia = citaSnapPrevia.data() ?? {};
        lat = (cdataPrevia['latitude'] as num?)?.toDouble() ?? 0.0;
        lng = (cdataPrevia['longitude'] as num?)?.toDouble() ?? 0.0;
      } catch (_) {}

      final pos = await _obtenerMejorUbicacion();
      if (pos == null) {
        _mostrarBurbuja("No pudimos obtener tu ubicación. Activa el GPS e inténtalo de nuevo.", const Color(0xFFFF5252), Icons.location_off_rounded);
        return;
      }

      final distancia = Geolocator.distanceBetween(pos.latitude, pos.longitude, lat, lng);
      final radioEfectivo = _radioEfectivo(pos.accuracy);
      if (distancia > radioEfectivo) {
        _mostrarBurbuja(
          "Estás a ${distancia.round()}m del lugar. Tu GPS tiene un margen de ±${pos.accuracy.round()}m ahora mismo — si estás en el lugar, intenta de nuevo en unos segundos o acércate a una ventana.",
          const Color(0xFFFF5252),
          Icons.social_distance_rounded,
        );
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final myUid = user.uid;
      final otherUid = widget.matchyUid;
      final myField = widget.isOwner ? 'gpsCheckOwner' : 'gpsCheckMatchy';
      final otherField = widget.isOwner ? 'gpsCheckMatchy' : 'gpsCheckOwner';

      final citaRef = FirebaseFirestore.instance.collection('citas').doc(widget.citaId);
      final myUserRef = FirebaseFirestore.instance.collection('users').doc(myUid);
      final otherUserRef = FirebaseFirestore.instance.collection('users').doc(otherUid);

      bool citaCompletada = false;
      bool citaYaCerrada = false;
      String? resultadoAlCerrarse; // 🆕 distingue cierre exitoso de cierre por tiempo límite
      bool yoGanePuntos = false;
      int miContadorNuevo = 0;

      // 🆕 TRANSACCIÓN: evita condiciones de carrera si ambos confirman casi al mismo tiempo.
      // Si al leer el documento el otro ya tiene su campo en true, en esta misma operación
      // atómica cerramos la cita y sumamos los puntos de ambos. Si no, solo guardamos mi lado.
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final citaSnap = await tx.get(citaRef);
        final cdata = citaSnap.data() ?? {};

        // 🛡️ Chequeo de seguridad: si la cita ya no está 'matched' (por ejemplo, el Juez
        // Supremo de citas_screen.dart ya la cerró por tiempo límite, o ya se cerró con éxito
        // mientras yo esperaba), no la sobrescribimos.
        if ((cdata['status'] ?? 'matched') != 'matched') {
          citaYaCerrada = true;
          resultadoAlCerrarse = (cdata['resultado'] ?? '').toString(); // 🆕
          return;
        }

        final otroYaConfirmo = cdata[otherField] == true;

        if (otroYaConfirmo) {
          final myUserSnap = await tx.get(myUserRef);
          final otherUserSnap = await tx.get(otherUserRef);

          // 🆕 CICLO 1→2→3 (nunca pasa de 3): si el contador actual ya estaba en 3 (la cita
          // anterior alcanzó la meta y otorgó puntos), esta cita reinicia el ciclo y guarda 1.
          // Si no, simplemente sube en 1. Los puntos se otorgan justo cuando el nuevo valor
          // llega a 3 (se alcanza a guardar el 3 en Firebase antes de reiniciar en la siguiente).
          final myActual = (myUserSnap.data()?['citas_consecutivas_exitosas'] as num?)?.toInt() ?? 0;
          final otherActual = (otherUserSnap.data()?['citas_consecutivas_exitosas'] as num?)?.toInt() ?? 0;

          final myRacha = myActual >= 3 ? 1 : myActual + 1;
          final otherRacha = otherActual >= 3 ? 1 : otherActual + 1;

          final myConf = ((myUserSnap.data()?['confiabilidad'] as num?)?.toInt() ?? 100);
          final otherConf = ((otherUserSnap.data()?['confiabilidad'] as num?)?.toInt() ?? 100);

          final myGanaPuntos = myRacha == 3;
          final otherGanaPuntos = otherRacha == 3;

          final myConfNueva = myGanaPuntos ? (myConf + 20).clamp(0, 100) : myConf;
          final otherConfNueva = otherGanaPuntos ? (otherConf + 20).clamp(0, 100) : otherConf;

          tx.update(myUserRef, {'citas_consecutivas_exitosas': myRacha, 'confiabilidad': myConfNueva});
          tx.update(otherUserRef, {'citas_consecutivas_exitosas': otherRacha, 'confiabilidad': otherConfNueva});
          tx.update(citaRef, {myField: true, 'status': 'finished', 'resultado': 'completada_exitosa'});

          citaCompletada = true;
          yoGanePuntos = myGanaPuntos;
          miContadorNuevo = myRacha;
        } else {
          tx.update(citaRef, {myField: true});
        }
      });

      // 🆕 Si mi propia transacción fue la que cerró la cita con éxito, bloqueo de una vez
      // cualquier intento del oyente en tiempo real de navegar por su cuenta (evita duplicar).
      if (citaCompletada) {
        _yaNavegueAExito = true;
        await _citaListener?.cancel();
      }

      // ⏳ Mínimo de tiempo visible del spinner "LEYENDO CÓDIGOS..." para que no parpadee.
      final transcurrido = DateTime.now().difference(inicio);
      const minimoVisible = Duration(milliseconds: 1500);
      if (transcurrido < minimoVisible) {
        await Future.delayed(minimoVisible - transcurrido);
      }

      if (!mounted) return;

      if (citaYaCerrada) {
        // 🆕 Si la cita ya se cerró pero fue con ÉXITO (probablemente mientras yo esperaba a
        // mi Matchy), no es un error — lo llevo igual a la pantalla de éxito.
        if (resultadoAlCerrarse == 'completada_exitosa') {
          await _navegarAExitoDesdeFirestore();
        } else {
          _mostrarBurbuja("Esta cita ya se cerró por tiempo límite.", const Color(0xFFFF5252), Icons.event_busy_rounded);
        }
        return;
      }

      if (citaCompletada) {
        // Datos frescos de ambos usuarios para la pantalla de éxito
        String miNombreFresco = 'Tú';
        String miFotoFresca = '';
        String otroNombreFresco = widget.matchyNombre;
        String otroFotoFresca = widget.matchyFoto;
        try {
          final miSnap = await FirebaseFirestore.instance.collection('users').doc(myUid).get();
          final miData = miSnap.data() ?? {};
          miNombreFresco = (miData['nombre'] ?? 'Tú').toString();
          miFotoFresca = (miData['profilePhotoUrl'] ?? '').toString();
        } catch (_) {}
        try {
          final otroSnap = await FirebaseFirestore.instance.collection('users').doc(otherUid).get();
          final otroData = otroSnap.data() ?? {};
          otroNombreFresco = (otroData['nombre'] ?? widget.matchyNombre).toString();
          otroFotoFresca = (otroData['profilePhotoUrl'] ?? '').toString();
        } catch (_) {}

        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => ConfirmarCitaScreen(
              ownerNombre: miNombreFresco,
              ownerFoto: miFotoFresca,
              matchyNombre: otroNombreFresco,
              matchyFoto: otroFotoFresca,
              ganaronPuntos: yoGanePuntos,
              citasFaltantes: yoGanePuntos ? 0 : (3 - (miContadorNuevo % 3)),
            ),
          ),
              (route) => false,
        );
      } else {
        _mostrarBurbuja("DILE A TU MATCHY QUE PONGA TU CÓDIGO PARA CONFIRMAR LA CITA", const Color(0xFF00E676), Icons.hourglass_top_rounded);
        // 🆕 Ya no se borra el código: se deja escrito por si el usuario quiere darle
        // "Confirmar Cita" otra vez más tarde como respaldo manual.
      }
    } catch (e) {
      _mostrarBurbuja("Error al confirmar: $e", const Color(0xFFFF5252), Icons.error_outline_rounded);
    } finally {
      if (mounted) setState(() => _confirmando = false);
    }
  }

  // ===========================================================================
  // 🎨 FILA DE INFORMACIÓN DE LA CÁPSULA (persona / lugar / fecha+hora / intención / preferencia)
  // ===========================================================================
  Widget _buildInfoRow(IconData icon, String text, {bool isAccent = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: isAccent ? kAccentColor : Colors.white70, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              text,
              style: TextStyle(color: isAccent ? kAccentColor : Colors.white, fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Poppins', height: 1.1),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool codigoHabilitado = _codigoHabilitado;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover)),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 15, 20, 60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 🆕 LOGO MATCHY (faltaba, mismo patrón que el resto de las pantallas)
                  const SizedBox(height: 40),
                  Center(child: Image.asset('assets/images/logomatchyplano.png', height: 45)),
                  const SizedBox(height: 25),

                  // 🖼️ ENCABEZADO FUSIONADO: foto del lugar + foto del Matchy sobrepuesta
                  Container(
                    height: kFotoLugarHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(kFotoLugarRadius),
                      boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 5))],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        widget.lugarFotoPortada.trim().startsWith('http')
                            ? CachedNetworkImage(
                          imageUrl: widget.lugarFotoPortada,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: Colors.black26),
                          errorWidget: (_, __, ___) => Container(color: Colors.grey[900], child: const Icon(Icons.broken_image, color: Colors.white24)),
                        )
                            : Container(color: Colors.grey[900], child: const Icon(Icons.image_not_supported, color: Colors.white24)),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter, end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                              stops: const [0.5, 1.0],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: kUserPhotoMargin,
                          right: kUserPhotoMargin,
                          child: GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PerfilUsuarioXScreen(uid: widget.matchyUid))),
                            child: Container(
                              width: kUserPhotoSize,
                              height: kUserPhotoSize,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(kUserPhotoRadius),
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 8, offset: const Offset(0, 4))],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(kUserPhotoRadius - 2),
                                child: widget.matchyFoto.trim().startsWith('http')
                                    ? CachedNetworkImage(
                                  imageUrl: widget.matchyFoto,
                                  fit: BoxFit.cover,
                                  alignment: Alignment.topCenter,
                                  errorWidget: (_, __, ___) => Container(color: Colors.grey[900], child: const Icon(Icons.person, color: Colors.white24)),
                                )
                                    : Container(color: Colors.grey[900], child: const Icon(Icons.person, color: Colors.white24)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // 🏷️ TÍTULO
                  const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "DATOS DE TU CITA",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: kTitleSize, fontWeight: FontWeight.w900, fontFamily: 'Poppins', shadows: [Shadow(color: Colors.black, blurRadius: 10, offset: Offset(0, 2))]),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // 🛡️ CÁPSULA DE INFORMACIÓN — 5 FILAS
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: kGlassColor, borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      children: [
                        _buildInfoRow(Icons.person, "${widget.matchyNombre.toUpperCase()}, ${widget.matchyEdad}"),
                        const SizedBox(height: 10),
                        _buildInfoRow(Icons.store_mall_directory_rounded, widget.lugarNombre.toUpperCase()),
                        const SizedBox(height: 10),
                        _buildInfoRow(Icons.calendar_month_rounded, "${_fechaAmigable(widget.citaDateTime)} - ${widget.hora}".toUpperCase(), isAccent: true),
                        const SizedBox(height: 10),
                        _buildInfoRow(Icons.chat_bubble_outline_rounded, "INTENCIÓN: ${widget.intencion}".toUpperCase()),
                        const SizedBox(height: 10),
                        _buildInfoRow(Icons.tune_rounded, "PREFERENCIA: ${widget.preferencia}".toUpperCase()),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 🎯 BLOQUE DE CÓDIGO / CONFIRMAR CITA / SEGURIDAD (diseño intacto)
                  Container(
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
                            widget.miCodigoCita.isEmpty ? '········' : widget.miCodigoCita,
                            style: const TextStyle(color: Color(0xFFBEB3FF), fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 6, fontFamily: 'Poppins'),
                          ),
                        ),

                        const SizedBox(height: 20),

                        const Text("CONFIRMAR CITA", style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Poppins', letterSpacing: 1.0)),
                        const SizedBox(height: 8),

                        // 🆕 CAMPO DE CÓDIGO CON PUERTA DE 24 HORAS
                        GestureDetector(
                          onTap: codigoHabilitado
                              ? null
                              : () => _mostrarBurbuja("Este espacio para tu código estará habilitado 24 horas antes de tu cita.", Colors.orangeAccent, Icons.lock_clock_rounded),
                          child: AbsorbPointer(
                            absorbing: !codigoHabilitado,
                            child: TextField(
                              controller: _codigoCtrl,
                              textCapitalization: TextCapitalization.characters,
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 3, fontFamily: 'Poppins'),
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                hintText: "CÓDIGO DE ${widget.matchyNombre}",
                                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13, letterSpacing: 1, fontFamily: 'Poppins'),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.08),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),
                        GestureDetector(
                          onTap: _confirmando ? null : _confirmarCita,
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF00E676), Color(0xFF00B84D)]),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.center,
                            child: _confirmando
                                ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)),
                                SizedBox(width: 12),
                                Text("LEYENDO CÓDIGOS...", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13, fontFamily: 'Poppins')),
                              ],
                            )
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
                  ),
                ],
              ),
            ),
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
}