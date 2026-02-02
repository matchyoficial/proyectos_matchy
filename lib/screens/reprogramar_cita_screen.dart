// 📂 lib/screens/reprogramar_cita_screen.dart
// ✅ PANTALLA REPROGRAMAR (FOTO INTELIGENTE + DISEÑO PREMIUM)
// 🔥 FIX: Implementado 'FotoPerfilUsuario' para actualizar la foto del matchy.
// 🔥 UI: Botón "Enviar" estilo Premium y Fade Out inferior.
// 🔥 LÓGICA: WriteBatch para transacciones seguras + Notificaciones.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:proyectos_matchy/screens/panel_screen.dart';
import 'package:proyectos_matchy/widgets/matchy_page_layout.dart';
import 'package:proyectos_matchy/widgets/foto_perfil_usuario.dart'; // 👈 WIDGET NUEVO

class ReprogramarCitaScreen extends StatefulWidget {
  final String citaId;

  const ReprogramarCitaScreen({super.key, required this.citaId});

  @override
  State<ReprogramarCitaScreen> createState() => _ReprogramarCitaScreenState();
}

class _ReprogramarCitaScreenState extends State<ReprogramarCitaScreen> {
  // ===========================================================================
  // 🔴 ZONA DE CHINCHES MAESTROS 🔴
  // ===========================================================================
  static const double kCardHeight = 180.0;
  static const double kCardBorderRadius = 25.0;
  static const double kCardMarginH = 20.0;
  static const double kUserPhotoSize = 90.0;
  static const double kUserPhotoMargin = 15.0;
  static const double kUserPhotoRadius = 18.0;

  static const Color kGlassColor = Color(0x33FFFFFF);
  static const Color kAccentColor = Color(0xFFE0D4FF);
  static const Color kPrimaryButtonColor = Color(0xFF6B4EE6); // Referencia base
  static const double kTitleSize = 24.0;

  // 🔥 ESTILO PREMIUM BOTÓN
  static const List<Color> kBtnSendGradient = [Color(0xFF6B4EE6), Color(0xFF4527A0)];
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
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 20, minute: 0),
      builder: (context, child) => Theme(data: pickerTheme, child: child!),
    );

    if (pickedTime == null) return;

    setState(() {
      _opciones[index] = DateTime(
        pickedDate.year, pickedDate.month, pickedDate.day,
        pickedTime.hour, pickedTime.minute,
      );
    });
  }

  Future<void> _enviarReprogramacion() async {
    if (_opciones.contains(null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("⚠️ DEBES SELECCIONAR LAS 3 OPCIONES"),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    final int currentCount = (_citaData?['repro_count'] ?? 0) as int;
    if (currentCount >= 1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("⛔ ESTA CITA YA FUE REPROGRAMADA UNA VEZ."),
        backgroundColor: Colors.red,
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
          'title': 'SOLICITUD DE CAMBIO',
          'body': 'Tu Matchy propone nuevos horarios para la cita.',
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
          title: const Text("SOLICITUD ENVIADA", style: TextStyle(color: kAccentColor, fontWeight: FontWeight.w900), textAlign: TextAlign.center),
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

    // Datos generales
    final String lugarFoto = _citaData!['lugarFotoPortada'] ?? _citaData!['lugarFoto'] ?? '';
    final String lugarNombre = _citaData!['lugarNombre'] ?? 'LUGAR';
    final String matchyNombre = _citaData!['matchyNombre'] ?? _citaData!['candidatoNombre'] ?? 'MATCHY';
    final String fechaActual = _citaData!['fecha'] ?? '--/--';
    final String horaActual = _citaData!['hora'] ?? '--:--';

    // Determinar UID de la otra persona para el Widget Inteligente
    final user = FirebaseAuth.instance.currentUser;
    final String myUid = user?.uid ?? '';
    final String ownerUid = (_citaData?['ownerUid'] ?? '').toString();
    final String candUid = (_citaData?['matchyUid'] ?? _citaData?['candidatoUid'] ?? '').toString();
    final String uidToShow = (myUid == ownerUid) ? candUid : ownerUid;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Contenido
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
                          Positioned(
                            top: 15, left: 15,
                            child: InkWell(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), shape: BoxShape.circle),
                                child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                              ),
                            ),
                          ),

                          // 🔥 FOTO MATCHY (WIDGET INTELIGENTE)
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
                                // 🔥 APLICADO AQUÍ
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
                  const Text("REPROGRAMAR CITA", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: kTitleSize, fontWeight: FontWeight.w900, fontFamily: 'Poppins', shadows: [Shadow(color: Colors.black, blurRadius: 10, offset: Offset(0, 2))])),
                  const SizedBox(height: 15),
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
                        _buildInfoRow(Icons.calendar_month_rounded, "$fechaActual - $horaActual".toUpperCase(), isAccent: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // BLOQUE RECOMENDACIÓN CHAT
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
                            "¡HOLA! ANTES DE ELEGIR NUEVAS FECHAS, TE SUGERIMOS HABLAR CON TU MATCHY POR EL CHAT PARA ACORDAR LOS HORARIOS Y EVITAR RECHAZOS.",
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

                  // 🔥 BOTÓN PREMIUM
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: kCardMarginH),
                    child: GestureDetector(
                      onTap: _sending ? null : _enviarReprogramacion,
                      child: Container(
                        width: double.infinity,
                        height: 55,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: kBtnSendGradient),
                          borderRadius: BorderRadius.circular(kButtonRadius),
                          boxShadow: kButtonShadow,
                          border: Border.all(color: Colors.white24, width: 1),
                        ),
                        alignment: Alignment.center,
                        child: _sending
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text("ENVIAR REPROGRAMACIÓN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, fontFamily: 'Poppins', letterSpacing: 0.5)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 120), // Espacio para fade out
                ],
              ),
            ),
          ),

          // 2. 🔥 DEGRADADO INFERIOR (FADE OUT)
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
          child: Text(text, style: TextStyle(color: isAccent ? kAccentColor : Colors.white, fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'Poppins', height: 1.1)),
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
            Expanded(child: Text(isSelected ? DateFormat('dd/MM/yyyy - hh:mm a').format(date).toUpperCase() : "SELECCIONAR OPCIÓN ${index + 1}", style: TextStyle(color: isSelected ? Colors.white : Colors.white54, fontWeight: FontWeight.w600, fontSize: 14, fontFamily: 'Poppins'))),
            Icon(Icons.calendar_today_rounded, color: isSelected ? kAccentColor : Colors.white24, size: 20),
          ],
        ),
      ),
    );
  }
}