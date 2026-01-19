// 📂 lib/screens/reprogramar_cita_aceptar_screen.dart
// ✅ PANTALLA PARA ACEPTAR REPROGRAMACIÓN (FINAL)
// 🔥 FIX: Ahora envía notificación de confirmación al usuario que solicitó el cambio.
// 🔥 Mantiene formato de fecha en español.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:proyectos_matchy/screens/panel_screen.dart';
import 'package:proyectos_matchy/widgets/matchy_page_layout.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 🟢 Necesario para current user

class ReprogramarCitaAceptarScreen extends StatefulWidget {
  final String citaId;

  const ReprogramarCitaAceptarScreen({super.key, required this.citaId});

  @override
  State<ReprogramarCitaAceptarScreen> createState() => _ReprogramarCitaAceptarScreenState();
}

class _ReprogramarCitaAceptarScreenState extends State<ReprogramarCitaAceptarScreen> {
  // ... (Tus chinches de diseño siguen igual) ...
  static const double kCardHeight = 280.0;
  static const double kCardBorderRadius = 25.0;
  static const double kCardMarginH = 20.0;
  static const double kUserPhotoSize = 90.0;
  static const double kUserPhotoMargin = 15.0;
  static const double kUserPhotoRadius = 18.0;
  static const Color kGlassColor = Color(0x33FFFFFF);
  static const Color kAccentColor = Color(0xFFE0D4FF);
  static const Color kPrimaryButton = Color(0xFF6B4EE6);
  static const Color kSelectionColor = Color(0xFF4CAF50);
  static const double kTitleSize = 24.0;

  bool _loading = true;
  Map<String, dynamic>? _citaData;
  List<DateTime> _opcionesRecibidas = [];
  int? _seleccionIndex;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _fetchCitaData();
  }

  Future<void> _fetchCitaData() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('citas').doc(widget.citaId).get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        final List<dynamic> rawOptions = data['repro_options'] ?? [];
        final List<DateTime> parsedOptions = rawOptions.map((e) {
          if (e is Timestamp) return e.toDate();
          return DateTime.now();
        }).toList();

        setState(() {
          _citaData = data;
          _opcionesRecibidas = parsedOptions;
          _loading = false;
        });
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  String _formatearFechaEspanol(DateTime date) {
    const dias = ['LUNES', 'MARTES', 'MIÉRCOLES', 'JUEVES', 'VIERNES', 'SÁBADO', 'DOMINGO'];
    const meses = ['ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN', 'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC'];
    final diaSemana = dias[date.weekday - 1];
    final mes = meses[date.month - 1];
    final diaNum = date.day;
    return "$diaSemana $diaNum $mes";
  }

  // 🔴 AQUÍ ESTÁ LA ACTUALIZACIÓN: NOTIFICAR AL SOLICITANTE
  Future<void> _confirmarHorario() async {
    if (_seleccionIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("⚠️ DEBES SELECCIONAR UN HORARIO PARA CONFIRMAR"),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    setState(() => _saving = true);

    try {
      final db = FirebaseFirestore.instance;
      final batch = db.batch(); // Usamos Batch para seguridad

      final DateTime nuevaFecha = _opcionesRecibidas[_seleccionIndex!];

      // Formato para guardar
      final String fechaStr = DateFormat('dd/MM/yyyy').format(nuevaFecha);
      final String horaStr = DateFormat('hh:mm a').format(nuevaFecha);

      // Referencias
      final citaRef = db.collection('citas').doc(widget.citaId);

      // Identificar a quién notificar (al que pidió el cambio)
      final String requesterUid = (_citaData?['repro_by_uid'] ?? '').toString();
      final String myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

      // 1. Actualizar Cita
      batch.update(citaRef, {
        'status': 'matched', // Vuelve a estar activa
        'fecha': fechaStr,
        'hora': horaStr,
        'repro_accepted_at': FieldValue.serverTimestamp(),
      });

      // 2. Crear Notificación de Confirmación (Si existe el ID del solicitante)
      if (requesterUid.isNotEmpty && requesterUid != myUid) {
        final notifRef = db.collection('users').doc(requesterUid).collection('notifications').doc();
        batch.set(notifRef, {
          'type': 'repro_accepted',
          'citaId': widget.citaId,
          'title': '¡NUEVA FECHA CONFIRMADA!',
          'body': 'Tu Matchy ha aceptado el horario: $fechaStr a las $horaStr.',
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
          title: const Text("¡CITA REPROGRAMADA!", style: TextStyle(color: kSelectionColor, fontWeight: FontWeight.w900), textAlign: TextAlign.center),
          content: Text("TU CITA HA SIDO ACTUALIZADA PARA EL\n$fechaStr A LAS $horaStr", style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
          actions: [
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const PanelScreen()), (r) => false);
                },
                child: const Text("EXCELENTE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      );

    } catch (e) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(color: kAccentColor)));
    if (_citaData == null) return const Scaffold(backgroundColor: Colors.black, body: Center(child: Text("ERROR AL CARGAR CITA", style: TextStyle(color: Colors.white))));

    final String lugarFoto = _citaData!['lugarFotoPortada'] ?? _citaData!['lugarFoto'] ?? '';
    final String lugarNombre = _citaData!['lugarNombre'] ?? 'LUGAR';
    final String matchyFoto = _citaData!['matchyFoto'] ?? _citaData!['candidatoFoto'] ?? '';
    final String matchyNombre = _citaData!['matchyNombre'] ?? _citaData!['candidatoNombre'] ?? 'MATCHY';
    final String fechaVieja = _citaData!['fecha'] ?? '--/--';
    final String horaVieja = _citaData!['hora'] ?? '--:--';

    return Scaffold(
      body: MatchyPageLayout(
        backgroundAsset: 'assets/images/fondo.jpg',
        logoAsset: 'assets/images/logomatchyplano.png',
        topSpacing: 35,
        logoHeight: 45,
        spaceLogoToScroll: 20,
        scrollContent: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: Column(
            children: [

              // TARJETA LUGAR
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
                            child: matchyFoto.isNotEmpty
                                ? Image.network(matchyFoto, fit: BoxFit.cover, alignment: Alignment.topCenter)
                                : Image.asset('assets/images/perfil1.jpg', fit: BoxFit.cover, alignment: Alignment.topCenter),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // TITULO
              const Text(
                "SOLICITUD DE CAMBIO",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: kTitleSize, fontWeight: FontWeight.w900, fontFamily: 'Poppins', shadows: [Shadow(color: Colors.black, blurRadius: 10, offset: Offset(0, 2))]),
              ),

              const SizedBox(height: 15),

              // CÁPSULA INFO
              Container(
                margin: const EdgeInsets.symmetric(horizontal: kCardMarginH),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: kGlassColor, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  children: [
                    _buildInfoRow(Icons.person, "SOLICITADO POR: ${matchyNombre.toUpperCase()}"),
                    const SizedBox(height: 10),
                    _buildInfoRow(Icons.store_mall_directory_rounded, lugarNombre.toUpperCase()),
                    const SizedBox(height: 10),
                    _buildInfoRow(Icons.history_rounded, "ANTERIOR: $fechaVieja - $horaVieja".toUpperCase(), isAccent: false, isStrike: true),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: kCardMarginH),
                child: Text(
                  "TU MATCHY PROPONE ESTOS HORARIOS.\nELIGE EL QUE MEJOR TE QUEDE:",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'Poppins', height: 1.4),
                ),
              ),

              const SizedBox(height: 20),

              // LISTA OPCIONES
              if (_opcionesRecibidas.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text("NO SE ENCONTRARON OPCIONES VÁLIDAS", style: TextStyle(color: Colors.red)),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: kCardMarginH),
                  child: Column(
                    children: List.generate(_opcionesRecibidas.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildOptionCard(index, _opcionesRecibidas[index]),
                      );
                    }),
                  ),
                ),

              const SizedBox(height: 20),

              // BOTÓN
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: kCardMarginH),
                child: SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _seleccionIndex != null ? kSelectionColor : Colors.grey.shade800,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 8,
                    ),
                    onPressed: (_saving || _seleccionIndex == null) ? null : _confirmarHorario,
                    child: _saving
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(
                      "CONFIRMAR NUEVO HORARIO",
                      style: TextStyle(color: _seleccionIndex != null ? Colors.white : Colors.white38, fontWeight: FontWeight.w900, fontSize: 16, fontFamily: 'Poppins'),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {bool isAccent = false, bool isStrike = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: isAccent ? kAccentColor : Colors.white70, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: TextStyle(color: isAccent ? kAccentColor : (isStrike ? Colors.white38 : Colors.white), fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Poppins', decoration: isStrike ? TextDecoration.lineThrough : null, decorationColor: Colors.white38))),
      ],
    );
  }

  Widget _buildOptionCard(int index, DateTime date) {
    final bool isSelected = _seleccionIndex == index;
    final String dateFormatted = _formatearFechaEspanol(date);
    final String timeFormatted = DateFormat('hh:mm a').format(date).toUpperCase();

    return GestureDetector(
      onTap: () => setState(() => _seleccionIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? kSelectionColor.withOpacity(0.2) : kGlassColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isSelected ? kSelectionColor : Colors.white10, width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isSelected ? kSelectionColor : Colors.white38, width: 2), color: isSelected ? kSelectionColor : Colors.transparent),
              child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
            ),
            const SizedBox(width: 15),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("OPCIÓN ${index + 1}", style: TextStyle(color: isSelected ? kSelectionColor : kAccentColor, fontSize: 10, fontWeight: FontWeight.bold)),
                Text("$dateFormatted - $timeFormatted", style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}