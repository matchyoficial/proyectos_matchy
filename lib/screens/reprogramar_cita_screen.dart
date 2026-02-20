// 📂 lib/screens/reprogramar_cita_screen.dart
// ✅ PANTALLA REPROGRAMAR BLINDADA (ESTRATEGIA ADAPTATIVA)
// 🔥 BLINDAJE: Título estandarizado a 20pt. Textos variables protegidos.
// 🔥 UI: Bloques informativos (Yellow/Red) intactos.
// 🔥 UI FIX: Selector de hora moderno 12h (AM/PM) en PANTALLA EMERGENTE CENTRAL.
// 🔔 NOTIFICACIÓN: Personalizada con Nombre de Lugar y Remitente.
// 💄 UI: Botón Back Chevron ubicado en la esquina superior izquierda (fuera de la foto).

import 'dart:ui'; // 🔥 Para el efecto de desenfoque
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // 🔥 Para los rodillos modernos
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:proyectos_matchy/screens/panel_screen.dart';
import 'package:proyectos_matchy/widgets/matchy_page_layout.dart';
import 'package:proyectos_matchy/widgets/foto_perfil_usuario.dart';

class ReprogramarCitaScreen extends StatefulWidget {
  final String citaId;

  const ReprogramarCitaScreen({super.key, required this.citaId});

  @override
  State<ReprogramarCitaScreen> createState() => _ReprogramarCitaScreenState();
}

class _ReprogramarCitaScreenState extends State<ReprogramarCitaScreen> {
  // ===========================================================================
  // 🛡️ ZONA DE CHINCHES MAESTROS (DISEÑO BLINDADO)
  // ===========================================================================
  static const double kCardHeight = 180.0;
  static const double kCardBorderRadius = 25.0;
  static const double kCardMarginH = 20.0;
  static const double kUserPhotoSize = 90.0;
  static const double kUserPhotoMargin = 15.0;
  static const double kUserPhotoRadius = 18.0;

  static const Color kGlassColor = Color(0x33FFFFFF);
  static const Color kAccentColor = Color(0xFFE0D4FF);
  static const Color kPrimaryButtonColor = Color(0xFF6B4EE6);

  // Regla de Oro: Título de sección a 20pt
  static const double kTitleSize = 20.0;

  static const List<Color> kBtnSendGradient = [Color(0xFF6B4EE6), Color(0xFF4527A0)];
  static const List<Color> kBtnDisabledGradient = [Color(0xFF424242), Color(0xFF212121)];
  static const double kButtonRadius = 18.0;
  static const List<BoxShadow> kButtonShadow = [
    BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 4))
  ];
  // ===========================================================================

  bool _loading = true;
  Map<String, dynamic>? _citaData;
  final List<DateTime?> _opciones = [null, null, null];
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _fetchCitaData();
  }

  Future<void> _fetchCitaData() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('citas').doc(widget.citaId).get();
      if (doc.exists) {
        setState(() {
          _citaData = doc.data();
          _loading = false;
        });
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _seleccionarFechaHora(int index) async {
    // 1. SELECCIÓN DE FECHA (CALENDARIO MATERIAL OSCURO)
    final now = DateTime.now();
    final pickerTheme = ThemeData.dark().copyWith(
      colorScheme: const ColorScheme.dark(
        primary: kPrimaryButtonColor,
        onPrimary: Colors.white,
        surface: Color(0xFF2A2A2A),
        onSurface: Colors.white,
      ),
      dialogBackgroundColor: const Color(0xFF2A2A2A),
    );

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
      builder: (context, child) => Theme(data: pickerTheme, child: child!),
    );

    if (pickedDate == null) return;

    if (!mounted) return;

    // 2. SELECCIÓN DE HORA (NUEVO RELOJ CENTRAL RODILLO)
    TimeOfDay? pickedTime;

    // Variables para el selector
    int selHora = 7;
    int selMin = 0;
    int selAmPm = 1; // 0: AM, 1: PM (Default 7:00 PM)

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 320,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2C),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white10),
                  boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 20, offset: Offset(0, 10))]
              ),
              child: Column(
                children: [
                  const Text("SELECCIONA LA HORA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 0.5)),
                  const SizedBox(height: 10),
                  const Divider(color: Colors.white10),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Horas
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: FixedExtentScrollController(initialItem: 6),
                            itemExtent: 45,
                            onSelectedItemChanged: (index) => selHora = index + 1,
                            children: List.generate(12, (i) => Center(child: Text("${i + 1}", style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)))),
                          ),
                        ),
                        const Text(":", style: TextStyle(color: Color(0xFFBEB3FF), fontSize: 25, fontWeight: FontWeight.bold)),
                        // Minutos
                        Expanded(
                          child: CupertinoPicker(
                            itemExtent: 45,
                            onSelectedItemChanged: (index) => selMin = index,
                            children: List.generate(60, (i) => Center(child: Text(i.toString().padLeft(2, '0'), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)))),
                          ),
                        ),
                        // AM/PM
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: FixedExtentScrollController(initialItem: 1),
                            itemExtent: 45,
                            onSelectedItemChanged: (index) => selAmPm = index,
                            children: const [
                              Center(child: Text("AM", style: TextStyle(color: Color(0xFFBEB3FF), fontSize: 18, fontWeight: FontWeight.w900))),
                              Center(child: Text("PM", style: TextStyle(color: Color(0xFFBEB3FF), fontSize: 18, fontWeight: FontWeight.w900))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR", style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 14))),
                      Container(width: 1, height: 20, color: Colors.white10),
                      TextButton(
                        onPressed: () {
                          // Lógica de conversión a 24h para guardar
                          int finalHour = selHora;
                          if (selAmPm == 1 && finalHour != 12) finalHour += 12;
                          if (selAmPm == 0 && finalHour == 12) finalHour = 0;

                          pickedTime = TimeOfDay(hour: finalHour, minute: selMin);
                          Navigator.pop(context);
                        },
                        child: const Text("ESTABLECER", style: TextStyle(color: Color(0xFFBEB3FF), fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.0)),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );

    if (pickedTime == null) return;

    setState(() {
      _opciones[index] = DateTime(
        pickedDate.year, pickedDate.month, pickedDate.day,
        pickedTime!.hour, pickedTime!.minute,
      );
    });
  }

  String _formatDateWithDay(DateTime dt) {
    const List<String> dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    String diaSemana = dias[dt.weekday - 1];
    String fechaNum = DateFormat('dd/MM/yyyy').format(dt);
    String hora = DateFormat('hh:mm a').format(dt);
    return "$diaSemana/$fechaNum - $hora".toUpperCase();
  }

  String _formatStoredDate(String dateStr) {
    try {
      final parts = dateStr.trim().split('/');
      if (parts.length != 3) return dateStr;
      final int day = int.parse(parts[0]);
      final int month = int.parse(parts[1]);
      final int year = int.parse(parts[2]);
      final dt = DateTime(year, month, day);
      const List<String> dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
      String diaSemana = dias[dt.weekday - 1];
      String d = day.toString().padLeft(2, '0');
      String m = month.toString().padLeft(2, '0');
      return "$diaSemana/$d/$m/$year";
    } catch (_) {
      return dateStr;
    }
  }

  Future<void> _enviarReprogramacion() async {
    final int currentCount = (_citaData?['repro_count'] ?? 0) as int;
    if (currentCount >= 1) return;

    if (_opciones.contains(null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("⚠️ DEBES SELECCIONAR LAS 3 OPCIONES"),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _sending = true);

    try {
      final db = FirebaseFirestore.instance;
      final batch = db.batch();

      final String myUid = user.uid;
      final String ownerUid = (_citaData?['ownerUid'] ?? '').toString();
      final String candidatoUid = (_citaData?['candidatoUid'] ?? _citaData?['matchyUid'] ?? '').toString();
      final String peerUid = (myUid == ownerUid) ? candidatoUid : ownerUid;

      // 🔥 DATOS PARA NOTIFICACIÓN PERSONALIZADA
      final String ownerName = (_citaData?['ownerNombre'] ?? 'Owner').toString();
      final String matchyName = (_citaData?['matchyNombre'] ?? (_citaData?['candidatoNombre'] ?? 'Matchy')).toString();
      final String myName = (myUid == ownerUid) ? ownerName : matchyName;
      final String placeName = (_citaData?['lugarNombre'] ?? 'CITA').toString();

      final List<Timestamp> optionsTimestamps = _opciones
          .map((dt) => Timestamp.fromDate(dt!))
          .toList();

      final citaRef = db.collection('citas').doc(widget.citaId);
      final notifRef = db.collection('users').doc(peerUid).collection('notifications').doc();

      batch.update(citaRef, {
        'status': 'reprogramming',
        'repro_by_uid': myUid,
        'repro_options': optionsTimestamps,
        'repro_count': FieldValue.increment(1),
        'repro_request_at': FieldValue.serverTimestamp(),
      });

      if (peerUid.isNotEmpty) {
        batch.set(notifRef, {
          'type': 'repro_request',
          'citaId': widget.citaId,
          // 🔔 TÍTULO Y CUERPO PERSONALIZADOS
          'title': 'REPROGRAMACIÓN: ${placeName.toUpperCase()} 🕒',
          'body': '$myName propone 3 nuevos horarios. Ve y elige el que más te sirva.',
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
          'fromUid': myUid,
        });
      }

      await batch.commit();

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const FittedBox(fit: BoxFit.scaleDown, child: Text("SOLICITUD ENVIADA", style: TextStyle(color: kAccentColor, fontWeight: FontWeight.w900))),
          content: const Text("LE HEMOS ENVIADO TUS PROPUESTAS A TU MATCHY. TE AVISAREMOS CUANDO CONFIRME UNA.", style: TextStyle(color: Colors.white70), textAlign: TextAlign.center),
          actions: [
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const PanelScreen()), (route) => false);
                },
                child: const Text("ENTENDIDO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      );

    } catch (e) {
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(color: kAccentColor)));
    if (_citaData == null) return const Scaffold(backgroundColor: Colors.black, body: Center(child: Text("ERROR CARGANDO CITA", style: TextStyle(color: Colors.white))));

    final String lugarFoto = _citaData!['lugarFotoPortada'] ?? _citaData!['lugarFoto'] ?? '';
    final String lugarNombre = _citaData!['lugarNombre'] ?? 'LUGAR';
    final String matchyNombre = _citaData!['matchyNombre'] ?? _citaData!['candidatoNombre'] ?? 'MATCHY';
    final String fechaActual = _citaData!['fecha'] ?? '--/--';
    final String horaActual = _citaData!['hora'] ?? '--:--';

    final user = FirebaseAuth.instance.currentUser;
    final String myUid = user?.uid ?? '';
    final String ownerUid = (_citaData?['ownerUid'] ?? '').toString();
    final String candUid = (_citaData?['matchyUid'] ?? _citaData?['candidatoUid'] ?? '').toString();
    final String uidToShow = (myUid == ownerUid) ? candUid : ownerUid;

    final int reproCount = (_citaData?['repro_count'] ?? 0) as int;
    final bool limitReached = reproCount >= 1;

    return Scaffold(
      body: Stack(
        children: [
          MatchyPageLayout(
            backgroundAsset: 'assets/images/fondo.jpg',
            logoAsset: 'assets/images/logomatchyplano.png',
            topSpacing: 35,
            logoHeight: 45,
            spaceLogoToScroll: 20,
            scrollContent: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: kCardMarginH),
                    height: kCardHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(kCardBorderRadius),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 5))],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(kCardBorderRadius),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          lugarFoto.isNotEmpty
                              ? Image.network(lugarFoto, fit: BoxFit.cover)
                              : Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                                stops: const [0.5, 1.0],
                              ),
                            ),
                          ),
                          // ❌ ANTES ESTABA AQUÍ EL BOTÓN DE ATRÁS, SE HA MOVIDO AL STACK PRINCIPAL.
                          Positioned(
                            bottom: kUserPhotoMargin,
                            right: kUserPhotoMargin,
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
                                child: FotoPerfilUsuario(
                                  uid: uidToShow,
                                  fit: BoxFit.cover,
                                  alignment: Alignment.topCenter,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // BLINDAJE: Título estandarizado a 20pt
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: const Text("REPROGRAMAR CITA", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: kTitleSize, fontWeight: FontWeight.w900, fontFamily: 'Poppins', shadows: [Shadow(color: Colors.black, blurRadius: 10, offset: Offset(0, 2))])),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // 🛡️ INFO CAPSULA BLINDADA
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: kCardMarginH),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: kGlassColor, borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      children: [
                        _buildInfoRow(Icons.person, matchyNombre.toUpperCase()),
                        const SizedBox(height: 10),
                        _buildInfoRow(Icons.store_mall_directory_rounded, lugarNombre.toUpperCase()),
                        const SizedBox(height: 10),
                        _buildInfoRow(Icons.calendar_month_rounded, "${_formatStoredDate(fechaActual)} - $horaActual".toUpperCase(), isAccent: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // BLOQUE RECOMENDACIÓN CHAT (INTACTO - SIN BLINDAJE PARA EVITAR ENCOGIMIENTO)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: kCardMarginH),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white24, width: 1),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 28),
                        SizedBox(width: 15),
                        Expanded(
                          child: Text(
                            "¡HOLA! ANTES DE ELEGIR NUEVAS FECHAS, TE SUGERIMOS HABLAR CON TU MATCHY POR EL CHAT PARA ACORDAR LOS HORARIOS, EVITAR RECHAZOS, BLOQUEOS Y CASTIGOS EN TUS RACHAS.",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13, fontFamily: 'Poppins', height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: kCardMarginH),
                    child: Text("ESCOGE 3 OPCIONES DE HORARIOS POSIBLES PARA TU NUEVA CITA", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, fontFamily: 'Poppins')),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: kCardMarginH),
                    child: Column(
                      children: [
                        _buildSelector(0),
                        const SizedBox(height: 12),
                        _buildSelector(1),
                        const SizedBox(height: 12),
                        _buildSelector(2),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 🛡️ BOTÓN PREMIUM BLINDADO
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: kCardMarginH),
                    child: GestureDetector(
                      onTap: (_sending || limitReached) ? null : _enviarReprogramacion,
                      child: Container(
                        width: double.infinity,
                        height: 55,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: limitReached ? kBtnDisabledGradient : kBtnSendGradient
                          ),
                          borderRadius: BorderRadius.circular(kButtonRadius),
                          boxShadow: kButtonShadow,
                          border: Border.all(color: Colors.white24, width: 1),
                        ),
                        alignment: Alignment.center,
                        child: _sending
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                              limitReached ? "OPCIÓN NO DISPONIBLE" : "ENVIAR REPROGRAMACIÓN",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, fontFamily: 'Poppins', letterSpacing: 0.5)
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ALERTA ROJA FIJA (INTACTA - SIN BLINDAJE PARA EVITAR ENCOGIMIENTO)
                  if (limitReached)
                    Padding(
                      padding: const EdgeInsets.only(top: 20, left: kCardMarginH, right: kCardMarginH),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD32F2F).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFFF5252), width: 1.5),
                          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 4))],
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(Icons.no_accounts_rounded, color: Colors.white, size: 32),
                            SizedBox(width: 15),
                            Expanded(
                              child: Text(
                                "ESTA CITA YA FUE REPROGRAMADA UNA VEZ, NO PUEDES VOLVER A REPROGRAMARLA",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Poppins',
                                    height: 1.3
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),

          // 🛡️ FADEOUT INFERIOR
          Positioned(
            bottom: 0, left: 0, right: 0, height: 90,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.95)],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // 🛡️ BOTÓN BACK FLOTANTE (ARRIBA IZQUIERDA)
          Positioned(
            top: 45, // Ajuste para SafeArea
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24),
                  boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2))],
                ),
                child: const Icon(Icons.chevron_left, color: Colors.white, size: 26),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
            child: Text(text, style: TextStyle(color: isAccent ? kAccentColor : Colors.white, fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'Poppins', height: 1.1)),
          ),
        ),
      ],
    );
  }

  Widget _buildSelector(int index) {
    final date = _opciones[index];
    final bool isSelected = date != null;
    return GestureDetector(
      onTap: () => _seleccionarFechaHora(index),
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: isSelected ? kPrimaryButtonColor.withOpacity(0.3) : kGlassColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isSelected ? kPrimaryButtonColor : Colors.white10, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(color: isSelected ? kPrimaryButtonColor : Colors.white10, shape: BoxShape.circle),
              child: Center(child: Text("${index + 1}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
            ),
            const SizedBox(width: 15),
            Expanded(
                child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(isSelected ? _formatDateWithDay(date) : "SELECCIONAR OPCIÓN ${index + 1}", style: TextStyle(color: isSelected ? Colors.white : Colors.white54, fontWeight: FontWeight.w600, fontSize: 14, fontFamily: 'Poppins'))
                )
            ),
            Icon(Icons.calendar_today_rounded, color: isSelected ? kAccentColor : Colors.white24, size: 20),
          ],
        ),
      ),
    );
  }
}