// 📂 lib/screens/reprogramar_cita_aceptar_screen.dart
// ✅ PANTALLA PARA ACEPTAR REPROGRAMACIÓN BLINDADA (SMART CACHE PRO INYECTADO)
// 🔥 CACHÉ PRO: Renderizado instantáneo (0ms) en la foto del banner del lugar.
// 🔥 BLINDAJE: Título estandarizado a 20pt. Textos variables elásticos.
// 🔥 UI: FotoPerfilUsuario y lógica de WriteBatch intactas.
// 💄 UI: Botón Back Chevron (Arriba-Izquierda) y Fadeout Inferior.
// 🔔 NOTIFICACIÓN: Actualizada con Nombre de Lugar y Usuario (Formato Campana).

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart'; // 🔥 Motor de caché
import 'package:proyectos_matchy/screens/panel_screen.dart';
import 'package:proyectos_matchy/widgets/matchy_page_layout.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:proyectos_matchy/widgets/foto_perfil_usuario.dart';

class ReprogramarCitaAceptarScreen extends StatefulWidget {
  final String citaId;

  const ReprogramarCitaAceptarScreen({super.key, required this.citaId});

  @override
  State<ReprogramarCitaAceptarScreen> createState() => _ReprogramarCitaAceptarScreenState();
}

class _ReprogramarCitaAceptarScreenState extends State<ReprogramarCitaAceptarScreen> {
  // 🛡️ ZONA DE CHINCHES MAESTROS (DISEÑO BLINDADO)
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

  // Regla de Oro: Título de sección a 20pt
  static const double kTitleSize = 20.0;

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

  // Helper para formatear fecha manual (evita problemas de locale)
  String _formatearFechaEspanol(DateTime date) {
    const dias = ['LUNES', 'MARTES', 'MIÉRCOLES', 'JUEVES', 'VIERNES', 'SÁBADO', 'DOMINGO'];
    const meses = ['ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN', 'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC'];
    final diaSemana = dias[date.weekday - 1];
    final mes = meses[date.month - 1];
    final diaNum = date.day;
    // Ejemplo: MIÉRCOLES 14 FEB
    return "$diaSemana $diaNum $mes";
  }

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
      final batch = db.batch();

      final DateTime nuevaFecha = _opcionesRecibidas[_seleccionIndex!];
      // Formato para guardar en Firestore (strings simples)
      final String fechaStr = DateFormat('dd/MM/yyyy').format(nuevaFecha);
      final String horaStr = DateFormat('hh:mm a').format(nuevaFecha);

      final citaRef = db.collection('citas').doc(widget.citaId);
      final String requesterUid = (_citaData?['repro_by_uid'] ?? '').toString();
      final String myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

      batch.update(citaRef, {
        'status': 'matched', // Vuelve a estado normal
        'fecha': fechaStr,
        'hora': horaStr,
        'repro_accepted_at': FieldValue.serverTimestamp(),
      });

      // Notificar al solicitante
      if (requesterUid.isNotEmpty && requesterUid != myUid) {
        // 🔥 Lógica inyectada para capturar nombres y lugar
        final String ownerUid = (_citaData?['ownerUid'] ?? '').toString();
        final String ownerName = (_citaData?['ownerNombre'] ?? 'Usuario').toString();
        final String matchyName = (_citaData?['matchyNombre'] ?? _citaData?['candidatoNombre'] ?? 'Usuario').toString();
        final String myName = (myUid == ownerUid) ? ownerName : matchyName;
        final String placeName = (_citaData?['lugarNombre'] ?? 'CITA').toString();

        final notifRef = db.collection('users').doc(requesterUid).collection('notifications').doc();
        batch.set(notifRef, {
          'type': 'repro_accepted',
          'citaId': widget.citaId,
          // 🔔 NOTIFICACIÓN BLINDADA CON LUGAR Y NOMBRE
          'title': 'CAMBIO ACEPTADO: ${placeName.toUpperCase()} 📅',
          'body': '$myName confirmó el nuevo horario para el $fechaStr a las $horaStr.',
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
          'fromUid': myUid,
        });
      }

      await batch.commit();

      if (!mounted) return;

      // Popup de éxito
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const FittedBox(fit: BoxFit.scaleDown, child: Text("¡CITA REPROGRAMADA!", style: TextStyle(color: kSelectionColor, fontWeight: FontWeight.w900))),
          content: Text("TU CITA HA SIDO ACTUALIZADA PARA EL\n$fechaStr A LAS $horaStr", style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
          actions: [
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  // Volver al Panel y limpiar stack
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
    final String matchyNombre = _citaData!['matchyNombre'] ?? _citaData!['candidatoNombre'] ?? 'MATCHY';
    final String fechaVieja = _citaData!['fecha'] ?? '--/--';
    final String horaVieja = _citaData!['hora'] ?? '--:--';
    final String reproByUid = (_citaData!['repro_by_uid'] ?? '').toString();

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
                          // 🔥 FOTO LUGAR CON SMART CACHE
                          lugarFoto.isNotEmpty
                              ? CachedNetworkImage(
                            key: ValueKey(lugarFoto),
                            imageUrl: lugarFoto,
                            fit: BoxFit.cover,
                            memCacheHeight: (kCardHeight * 3).toInt(),
                            placeholder: (context, url) => Container(color: Colors.black26),
                            errorWidget: (context, url, error) => Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover),
                          )
                              : Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover),
                          // GRADIENTE OSCURO
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                                stops: const [0.5, 1.0],
                              ),
                            ),
                          ),

                          // FOTO PERFIL (SOLICITANTE)
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
                                  uid: reproByUid,
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
                      child: const Text(
                        "SOLICITUD DE CAMBIO",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: kTitleSize, fontWeight: FontWeight.w900, fontFamily: 'Poppins', shadows: [Shadow(color: Colors.black, blurRadius: 10, offset: Offset(0, 2))]),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // 🛡️ CÁPSULA INFO BLINDADA
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

                  // 🛡️ BOTÓN CONFIRMAR BLINDADO
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
                            : FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "CONFIRMAR NUEVO HORARIO",
                            style: TextStyle(color: _seleccionIndex != null ? Colors.white : Colors.white38, fontWeight: FontWeight.w900, fontSize: 16, fontFamily: 'Poppins'),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 120), // Espacio extra para scroll
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

  Widget _buildInfoRow(IconData icon, String text, {bool isAccent = false, bool isStrike = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: isAccent ? kAccentColor : Colors.white70, size: 20),
        const SizedBox(width: 12),
        Expanded(
            child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(text, style: TextStyle(color: isAccent ? kAccentColor : (isStrike ? Colors.white38 : Colors.white), fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Poppins', decoration: isStrike ? TextDecoration.lineThrough : null, decorationColor: Colors.white38))
            )
        ),
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
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("OPCIÓN ${index + 1}", style: TextStyle(color: isSelected ? kSelectionColor : kAccentColor, fontSize: 10, fontWeight: FontWeight.bold)),
                  FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text("$dateFormatted - $timeFormatted", style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Poppins'))
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}