// 📂 lib/screens/crea_cita_matchy_screen.dart
// ✅ CREAR CITA PRIVADA BLINDADA (SMART CACHE PRO INYECTADO)
// 🔥 CACHÉ PRO: Renderizado instantáneo (0ms) sincronizado con la pantalla anterior.
// 🔥 FIX: Se inicializan ownerCastigado, matchyCastigado, etc. en FALSE.
// 🔥 UI FIX: Selector de hora moderno 12h (AM/PM) en PANTALLA EMERGENTE CENTRAL.
// 🔥 FIX DE SEGURIDAD: Generador criptográfico estandarizado de 8 caracteres (Random.secure).
// 🆕 NEW: parámetro opcional invitacionId — cuando viene desde el botón "PROGRAMAR" de
//    citas_screen.dart (invitación de Comunidad ya respondida), marca esa invitación como
//    'agendado' justo DESPUÉS de que la cita real se crea con éxito (nunca antes). Si
//    invitacionId es null (uso normal, ej. desde lugar_plantilla_screen.dart), no pasa nada nuevo.

import 'dart:io';
import 'dart:ui'; // 🔥 Para el efecto de desenfoque
import 'dart:math'; // 🔥 Para el generador de códigos seguro
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // 🔥 Para los rodillos modernos
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart'; // 🔥 Motor de caché

import 'package:proyectos_matchy/models/lugar_data.dart';
import 'package:proyectos_matchy/widgets/matchy_back_button.dart';
import 'package:proyectos_matchy/screens/cita_creada_screen.dart';

class CreaCitaMatchyScreen extends StatefulWidget {
  final LugarData lugar;
  final String matchyUidInvitado;
  final String? invitacionId; // 🆕 NUEVO

  const CreaCitaMatchyScreen({
    super.key,
    required this.lugar,
    required this.matchyUidInvitado,
    this.invitacionId, // 🆕 NUEVO — opcional, no rompe usos existentes
  });

  @override
  State<CreaCitaMatchyScreen> createState() => _CreaCitaMatchyScreenState();
}

class _CreaCitaMatchyScreenState extends State<CreaCitaMatchyScreen> {
  static const double kAlturaFoto = 210.0;
  static const double kMargenFotoHorizontal = 23.0;
  static const double kRadioFoto = 24.0;
  static const double kTituloLugarSize = 26.0;
  static const double kDireccionSize = 21.0;
  static const double kTituloPantallaSize = 16.0;
  static const double kTextoBotonSize = 14.0;
  static const double kAlturaBoton = 52.0;

  String _fecha = '';
  String _hora = '';
  DateTime? _pickedDate;
  TimeOfDay? _pickedTime;
  bool _sending = false;
  SedeData? _sedeSeleccionada;

  static const String _citasCollection = 'citas';

  @override
  void initState() {
    super.initState();
    if (widget.lugar.sedes.length == 1) {
      _sedeSeleccionada = widget.lugar.sedes.first;
    }
  }

  Future<void> _seleccionarFecha() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('es', 'ES'),
      initialDate: _pickedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      builder: (context, child) => Localizations.override(context: context, locale: const Locale('es', 'ES'), child: child!),
    );
    if (picked != null) {
      setState(() {
        _pickedDate = picked;
        _fecha = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  // 🔥 SELECTOR EMERGENTE CENTRAL (12H RODILLO)
  Future<void> _seleccionarHora() async {
    int selHora = 7;
    int selMin = 0;
    int selAmPm = 1; // Default PM

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
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: FixedExtentScrollController(initialItem: 6),
                            itemExtent: 45,
                            onSelectedItemChanged: (index) => selHora = index + 1,
                            children: List.generate(12, (i) => Center(child: Text("${i + 1}", style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)))),
                          ),
                        ),
                        const Text(":", style: TextStyle(color: Color(0xFFBEB3FF), fontSize: 25, fontWeight: FontWeight.bold)),
                        Expanded(
                          child: CupertinoPicker(
                            itemExtent: 45,
                            onSelectedItemChanged: (index) => selMin = index,
                            children: List.generate(60, (i) => Center(child: Text(i.toString().padLeft(2, '0'), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)))),
                          ),
                        ),
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
                          int finalHour = selHora;
                          if (selAmPm == 1 && finalHour != 12) finalHour += 12;
                          if (selAmPm == 0 && finalHour == 12) finalHour = 0;

                          setState(() {
                            _pickedTime = TimeOfDay(hour: finalHour, minute: selMin);
                            final amPmStr = selAmPm == 0 ? 'AM' : 'PM';
                            _hora = '$selHora:${selMin.toString().padLeft(2, '0')} $amPmStr';
                          });
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
  }

  // 🔥 NUEVO GENERADOR CRIPTOGRÁFICO SEGURO ESTANDARIZADO
  String _generarCodigoRandom8D() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random.secure();
    return String.fromCharCodes(Iterable.generate(
      8, (_) => chars.codeUnitAt(rnd.nextInt(chars.length)),
    ));
  }

  String _pickFotoLugar(LugarData lugar) {
    final fp = lugar.fotoPortada.trim();
    if (fp.startsWith('http')) return fp;
    for (final f in lugar.fotos) {
      final t = f.trim();
      if (t.startsWith('http')) return t;
    }
    return '';
  }

  Future<String> _enviarInvitacionFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No hay sesión iniciada');
    if (_pickedDate == null || _pickedTime == null) throw Exception('Selecciona fecha y hora');

    final scheduledAt = DateTime(_pickedDate!.year, _pickedDate!.month, _pickedDate!.day, _pickedTime!.hour, _pickedTime!.minute);

    final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final dataUser = snap.data() ?? {};
    final ownerNombre = (dataUser['nombre'] ?? 'Alguien').toString();
    final ownerEdad = dataUser['edad'] is int ? dataUser['edad'] : 0;
    final ownerFoto = (dataUser['profilePhotoUrl'] ?? '').toString();

    final snapMatchy = await FirebaseFirestore.instance.collection('users').doc(widget.matchyUidInvitado).get();
    final dataMatchy = snapMatchy.data() ?? {};
    final matchyNombre = (dataMatchy['nombre'] ?? 'Matchy').toString();
    final matchyEdad = dataMatchy['edad'] is int ? dataMatchy['edad'] : 0;
    final matchyFoto = (dataMatchy['profilePhotoUrl'] ?? '').toString();

    final placeSnap = await FirebaseFirestore.instance.collection('lugares').doc(widget.lugar.id).get();
    final placeData = placeSnap.data() ?? {};
    final Map<String, dynamic> sedesMap = placeData['sedes'] is Map ? Map<String, dynamic>.from(placeData['sedes']) : {};

    double finalLat = 0.0;
    double finalLng = 0.0;
    String sedeIdUsada = '';
    String sedeNombreUsado = '';
    String sedeDireccionUsada = '';

    if (_sedeSeleccionada != null) {
      sedeIdUsada = _sedeSeleccionada!.id;
      sedeNombreUsado = _sedeSeleccionada!.nombre;
      sedeDireccionUsada = _sedeSeleccionada!.direccion;

      if (sedesMap.containsKey(sedeIdUsada)) {
        final sData = Map<String, dynamic>.from(sedesMap[sedeIdUsada]);
        finalLat = (sData['latitude'] ?? sData['latitud'] ?? 0.0).toDouble();
        finalLng = (sData['longitude'] ?? sData['longitud'] ?? 0.0).toDouble();
      }
    } else {
      if (sedesMap.isNotEmpty) {
        var sData = sedesMap['sede_1'];
        if (sData == null) sData = sedesMap.values.first;
        if (sData is Map) {
          finalLat = (sData['latitude'] ?? sData['latitud'] ?? 0.0).toDouble();
          finalLng = (sData['longitude'] ?? sData['longitud'] ?? 0.0).toDouble();
          sedeIdUsada = 'sede_1';
          sedeNombreUsado = (sData['nombre'] ?? '').toString();
          sedeDireccionUsada = (sData['direccion'] ?? '').toString();
        }
      } else {
        finalLat = (placeData['latitude'] ?? placeData['latitud'] ?? 0.0).toDouble();
        finalLng = (placeData['longitude'] ?? placeData['longitud'] ?? 0.0).toDouble();
        sedeDireccionUsada = widget.lugar.direccion;
      }
    }

    // 🔥 GENERACIÓN DE CÓDIGOS CRIPTOGRÁFICOS Y ÚNICOS
    final codigoOwner = _generarCodigoRandom8D();
    String codigoMatchy = _generarCodigoRandom8D();
    while (codigoMatchy == codigoOwner) {
      codigoMatchy = _generarCodigoRandom8D();
    }

    final lugar = widget.lugar;

    final docRef = FirebaseFirestore.instance.collection(_citasCollection).doc();
    final citaId = docRef.id;

    await docRef.set({
      'isPrivate': true,
      'status': 'pending_approval',
      'ownerUid': user.uid,
      'ownerNombre': ownerNombre,
      'ownerEdad': ownerEdad,
      'ownerFoto': ownerFoto,
      'codigoOwner': codigoOwner,
      'matchyUid': widget.matchyUidInvitado,
      'matchyNombre': matchyNombre,
      'matchyEdad': matchyEdad,
      'matchyFoto': matchyFoto,
      'codigoMatchy': codigoMatchy,
      'fecha': _fecha,
      'hora': _hora,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'preferencia': 'Privada',
      'intencion': 'Consensuada',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lugarNombre': lugar.nombre,
      'lugarId': lugar.id,
      'lugarDireccion': lugar.direccion,
      'lugarFotoPortada': lugar.fotoPortada,
      'lugarFotos': lugar.fotos.take(8).toList(),
      'sedeId': sedeIdUsada,
      'sedeNombre': sedeNombreUsado,
      'sedeDireccion': sedeDireccionUsada,
      'latitude': finalLat,
      'longitude': finalLng,
      'ownerPropusoAcuerdo': false,
      'matchyPropusoAcuerdo': false,
      'ownerCastigado': false,
      'matchyCastigado': false,
      'gpsCheckOwner': false,
      'gpsCheckMatchy': false,
      'resultado': '',
    });

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.matchyUidInvitado)
        .collection('notifications')
        .add({
      'type': 'invitacion_cita',
      'title': '¡Nueva Invitación!',
      'body': '$ownerNombre te ha invitado a una cita en ${lugar.nombre}.',
      'citaId': citaId,
      'senderUid': user.uid,
      'senderFoto': ownerFoto,
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    });

    // 🆕 NUEVO: si venimos del flujo "PROGRAMAR" de Citas (invitación de Comunidad ya elegida),
    // marcamos esa invitación como 'agendado' SOLO ahora que la cita real ya existe en Firestore.
    // Así, si el usuario entra y se devuelve sin terminar, la tarjeta "PROGRAMAR" sigue esperándolo.
    if (widget.invitacionId != null && widget.invitacionId!.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('invitaciones_citas').doc(widget.invitacionId).update({'status': 'agendado'});
      } catch (_) {}
    }

    return citaId;
  }

  Future<void> _onEnviarInvitacion() async {
    if (_sending) return;
    if (_pickedDate == null || _pickedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona fecha y hora')));
      return;
    }
    setState(() => _sending = true);
    try {
      final citaId = await _enviarInvitacionFirestore();
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => CitaCreadaScreen(citaId: citaId, lugar: widget.lugar, fecha: _fecha, hora: _hora, preferencia: 'Privada', intencion: 'Cita Matchy')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const double espacioBarraLogo = 35;
    const double alturaLogo = 50;
    const double espacioLogoScroll = 15;
    const double margenInferiorPantalla = 110;

    final lugar = widget.lugar;
    final width = MediaQuery.of(context).size.width;
    final fotoUrl = _pickFotoLugar(lugar);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover)),
          const MatchyBackButton(top: 10, left: 16),
          Column(
            children: [
              const SizedBox(height: espacioBarraLogo),
              Image.asset('assets/images/logomatchyplano.png', height: alturaLogo),
              const SizedBox(height: espacioLogoScroll),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: margenInferiorPantalla),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: const Text("PLANEA TU CITA CON TU MATCHY", style: TextStyle(color: Colors.white, fontSize: kTituloPantallaSize, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black, blurRadius: 4)]), textAlign: TextAlign.center),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 🔥 FOTO BLINDADA CON SMART CACHE PRO (Sincronización a 0ms)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: kMargenFotoHorizontal),
                        child: Container(
                          height: kAlturaFoto,
                          width: double.infinity,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(kRadioFoto), boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 4))]),
                          child: fotoUrl.isNotEmpty
                              ? CachedNetworkImage(
                            key: ValueKey(fotoUrl), // Candado para renderizado instantáneo
                            imageUrl: fotoUrl,
                            fit: BoxFit.cover,
                            memCacheHeight: (kAlturaFoto * 3).toInt(), // Limitador de RAM
                            placeholder: (context, url) => Container(color: const Color(0xFF1A1A1A), child: const Center(child: CircularProgressIndicator(color: Color(0xFFBEB3FF), strokeWidth: 2))),
                            errorWidget: (_, __, ___) => Image.asset('assets/images/perfil1.jpg', fit: BoxFit.cover),
                          )
                              : Image.asset('assets/images/perfil1.jpg', fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(lugar.nombre.toUpperCase(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: kTituloLugarSize, fontWeight: FontWeight.w900, height: 1.0, shadows: [Shadow(color: Colors.black, blurRadius: 5, offset: Offset(0, 2))])),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(_sedeSeleccionada != null ? _sedeSeleccionada!.direccion : lugar.direccion, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: kDireccionSize, fontWeight: FontWeight.w500, height: 1.1, shadows: [Shadow(color: Colors.black, blurRadius: 4)])),
                        ),
                      ),
                      const SizedBox(height: 25),
                      _BotonPremium(text: _fecha.isEmpty ? "SELECCIONAR FECHA" : "FECHA: $_fecha", icon: Icons.calendar_today, width: width * 0.85, fontSize: kTextoBotonSize, height: kAlturaBoton, onTap: _sending ? null : _seleccionarFecha),
                      const SizedBox(height: 12),
                      _BotonPremium(text: _hora.isEmpty ? "SELECCIONAR HORA" : "HORA: $_hora", icon: Icons.access_time, width: width * 0.85, fontSize: kTextoBotonSize, height: kAlturaBoton, onTap: _sending ? null : _seleccionarHora),
                      const SizedBox(height: 12),
                      if (lugar.sedes.length >= 2)
                        _BotonPremium(
                          text: _sedeSeleccionada == null ? 'SELECCIONAR SEDE' : _sedeSeleccionada!.nombre.toUpperCase(),
                          icon: Icons.store,
                          width: width * 0.85,
                          fontSize: kTextoBotonSize,
                          height: kAlturaBoton,
                          onTap: _sending ? null : () async {
                            final sede = await showModalBottomSheet<SedeData>(
                              context: context,
                              backgroundColor: Colors.transparent,
                              isScrollControlled: true,
                              builder: (_) => SafeArea(
                                child: Container(
                                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
                                  padding: const EdgeInsets.all(16),
                                  decoration: const BoxDecoration(color: Color(0xFF1E1E2C), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 10), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                                      const Text("SELECCIONA UNA SEDE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                      const SizedBox(height: 10),
                                      Expanded(
                                        child: ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: lugar.sedes.length,
                                          itemBuilder: (ctx, i) {
                                            final s = lugar.sedes[i];
                                            return InkWell(
                                              onTap: () => Navigator.pop(context, s),
                                              child: Container(
                                                margin: const EdgeInsets.symmetric(vertical: 6),
                                                padding: const EdgeInsets.all(14),
                                                decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF6A5ACD), Color(0xFF4527A0)]), borderRadius: BorderRadius.circular(16)),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(s.direccion, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                                                    const SizedBox(height: 6),
                                                    Text(s.nombre, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                            if (sede != null) setState(() => _sedeSeleccionada = sede);
                          },
                        ),
                      const SizedBox(height: 40),
                      _BotonPremium(text: "ENVIAR INVITACIÓN", width: width * 0.85, isAction: true, isLoading: _sending, fontSize: kTextoBotonSize, height: kAlturaBoton, onTap: _sending ? null : _onEnviarInvitacion),
                      const SizedBox(height: 30),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white12, width: 1)),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white70, size: 24),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                "Se enviará una notificación a tu Matchy. Hablen por chat antes de fijar la cita para evitar cancelaciones y penalizaciones.",
                                textAlign: TextAlign.start,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14, fontFamily: 'Poppins', height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(bottom: 0, left: 0, right: 0, height: 90, child: IgnorePointer(child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.95)], stops: const [0.0, 1.0]))))),
        ],
      ),
    );
  }
}

class _BotonPremium extends StatelessWidget {
  final String text; final VoidCallback? onTap; final double width; final double height; final double fontSize; final IconData? icon; final bool isAction; final bool isLoading;
  const _BotonPremium({required this.text, this.onTap, required this.width, this.height = 50, this.fontSize = 14, this.icon, this.isAction = false, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    final gradient = isAction ? const LinearGradient(colors: [Color(0xFF7B1FA2), Color(0xFF4A148C)]) : const LinearGradient(colors: [Color(0xFF5E35B1), Color(0xFF311B92)]);
    return Container(
      width: width, height: height,
      decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(18), boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 5, offset: Offset(0, 3))], border: Border.all(color: Colors.white12)),
      child: Material(color: Colors.transparent, child: InkWell(borderRadius: BorderRadius.circular(18), onTap: onTap, child: Center(child: isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [if (icon != null) ...[Icon(icon, color: Colors.white70, size: 20), const SizedBox(width: 8)], Text(text, style: TextStyle(color: Colors.white, fontSize: fontSize, fontWeight: FontWeight.bold, letterSpacing: 0.5))]),
        ),
      )))),
    );
  }
}