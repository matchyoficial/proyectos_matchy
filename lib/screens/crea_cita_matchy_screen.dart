// 📂 lib/screens/crea_cita_matchy_screen.dart
// ✅ CREAR CITA PRIVADA (FADE OUT + NUBE ESTILIZADA)
// 🔥 UI FIX: Agregado degradado negro inferior (Fade Out).
// 🔥 UI FIX: Nube informativa con estilo idéntico a 'Reprogramar' y texto justificado ordenado.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:proyectos_matchy/models/lugar_data.dart';
import 'package:proyectos_matchy/widgets/matchy_back_button.dart';
import 'package:proyectos_matchy/screens/cita_creada_screen.dart';

class CreaCitaMatchyScreen extends StatefulWidget {
  final LugarData lugar;
  final String matchyUidInvitado;

  const CreaCitaMatchyScreen({
    super.key,
    required this.lugar,
    required this.matchyUidInvitado,
  });

  @override
  State<CreaCitaMatchyScreen> createState() => _CreaCitaMatchyScreenState();
}

class _CreaCitaMatchyScreenState extends State<CreaCitaMatchyScreen> {
  // UI Constants
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

  // SELECTORES DE FECHA/HORA
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

  Future<void> _seleccionarHora() async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: _pickedTime ?? now,
      builder: (context, child) => Localizations.override(context: context, locale: const Locale('es', 'ES'), child: child!),
    );
    if (picked != null) {
      final hour = picked.hour;
      final minute = picked.minute.toString().padLeft(2, '0');
      final amPm = hour < 12 ? 'AM' : 'PM';
      final displayHour = hour % 12 == 0 ? 12 : hour % 12;
      setState(() {
        _pickedTime = picked;
        _hora = '$displayHour:$minute $amPm';
      });
    }
  }

  String _generarCodigoUnico(String uid, String tipo) {
    final seed = '${DateTime.now().millisecondsSinceEpoch}-$uid-$tipo';
    final h = seed.codeUnits.fold<int>(0, (p, c) => (p + c) % 999999);
    return 'PVT${h.toString().padLeft(6, '0')}';
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

  // -------------------------------------------------------------
  // 🔥 LÓGICA DE ENVÍO + NOTIFICACIÓN
  // -------------------------------------------------------------
  Future<String> _enviarInvitacionFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No hay sesión iniciada');
    if (_pickedDate == null || _pickedTime == null) throw Exception('Selecciona fecha y hora');

    final scheduledAt = DateTime(_pickedDate!.year, _pickedDate!.month, _pickedDate!.day, _pickedTime!.hour, _pickedTime!.minute);

    // Datos del Creador
    final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final dataUser = snap.data() ?? {};
    final ownerNombre = (dataUser['nombre'] ?? 'Alguien').toString();
    final ownerEdad = dataUser['edad'] is int ? dataUser['edad'] : 0;
    final ownerFoto = (dataUser['profilePhotoUrl'] ?? '').toString();

    // Datos del Invitado
    final snapMatchy = await FirebaseFirestore.instance.collection('users').doc(widget.matchyUidInvitado).get();
    final dataMatchy = snapMatchy.data() ?? {};
    final matchyNombre = (dataMatchy['nombre'] ?? 'Matchy').toString();
    final matchyEdad = dataMatchy['edad'] is int ? dataMatchy['edad'] : 0;
    final matchyFoto = (dataMatchy['profilePhotoUrl'] ?? '').toString();

    final codigoOwner = _generarCodigoUnico(user.uid, 'HOST');
    final codigoMatchy = _generarCodigoUnico(widget.matchyUidInvitado, 'GUEST');

    final lugar = widget.lugar;
    final sedeFinal = (_sedeSeleccionada != null) ? _sedeSeleccionada! : SedeData(id: '', nombre: '', direccion: lugar.direccion);

    final docRef = FirebaseFirestore.instance.collection(_citasCollection).doc();
    final citaId = docRef.id;

    // 1. Guardar Cita
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
      'lugarDireccion': lugar.direccion,
      'lugarFotoPortada': lugar.fotoPortada,
      'lugarFotos': lugar.fotos.take(8).toList(),
      'sedeId': sedeFinal.id,
      'sedeNombre': sedeFinal.nombre,
      'sedeDireccion': sedeFinal.direccion,
    });

    // 2. 🔥 ENVIAR NOTIFICACIÓN AL INVITADO
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.matchyUidInvitado) // Buzón del invitado
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

      Navigator.of(context).push(MaterialPageRoute(builder: (_) => CitaCreadaScreen(
          citaId: citaId,
          lugar: widget.lugar,
          fecha: _fecha,
          hora: _hora,
          preferencia: 'Privada',
          intencion: 'Cita Matchy'
      )));

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
          // FONDO
          Positioned.fill(child: Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover)),
          const MatchyBackButton(top: 10, left: 16),

          Column(
            children: [
              const SizedBox(height: espacioBarraLogo),
              Image.asset('assets/images/logomatchyplano.png', height: alturaLogo),
              const SizedBox(height: espacioLogoScroll),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: margenInferiorPantalla),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        "PLANEA TU CITA CON TU MATCHY",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: kTituloPantallaSize,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(color: Colors.black, blurRadius: 4)]
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),

                      // FOTO
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: kMargenFotoHorizontal),
                        child: Container(
                          height: kAlturaFoto,
                          width: double.infinity,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(kRadioFoto),
                            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 4))],
                          ),
                          child: fotoUrl.isNotEmpty
                              ? Image.network(fotoUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Image.asset('assets/images/perfil1.jpg', fit: BoxFit.cover))
                              : Image.asset('assets/images/perfil1.jpg', fit: BoxFit.cover),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // NOMBRE
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            lugar.nombre.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: kTituloLugarSize,
                              fontWeight: FontWeight.w900,
                              height: 1.0,
                              shadows: [Shadow(color: Colors.black, blurRadius: 5, offset: Offset(0, 2))],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          _sedeSeleccionada != null ? _sedeSeleccionada!.direccion : lugar.direccion,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: kDireccionSize,
                            fontWeight: FontWeight.w500,
                            height: 1.1,
                            shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      // FECHA Y HORA
                      _BotonPremium(
                        text: _fecha.isEmpty ? "SELECCIONAR FECHA" : "FECHA: $_fecha",
                        icon: Icons.calendar_today,
                        width: width * 0.85,
                        fontSize: kTextoBotonSize,
                        height: kAlturaBoton,
                        onTap: _sending ? null : _seleccionarFecha,
                      ),
                      const SizedBox(height: 12),

                      _BotonPremium(
                        text: _hora.isEmpty ? "SELECCIONAR HORA" : "HORA: $_hora",
                        icon: Icons.access_time,
                        width: width * 0.85,
                        fontSize: kTextoBotonSize,
                        height: kAlturaBoton,
                        onTap: _sending ? null : _seleccionarHora,
                      ),
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
                              builder: (_) => SafeArea(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF1E1E2C),
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: lugar.sedes.map((s) {
                                      return InkWell(
                                        onTap: () => Navigator.pop(context, s),
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(vertical: 6),
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(colors: [Color(0xFF6A5ACD), Color(0xFF4527A0)]),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
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
                                    }).toList(),
                                  ),
                                ),
                              ),
                            );
                            if (sede != null) setState(() => _sedeSeleccionada = sede);
                          },
                        ),

                      const SizedBox(height: 40),

                      // BOTÓN DE ACCIÓN
                      _BotonPremium(
                        text: "ENVIAR INVITACIÓN",
                        width: width * 0.85,
                        isAction: true,
                        isLoading: _sending,
                        fontSize: kTextoBotonSize,
                        height: kAlturaBoton,
                        onTap: _sending ? null : _onEnviarInvitacion,
                      ),

                      const SizedBox(height: 30),

                      // 🔥 NUBE INFORMATIVA ESTILIZADA (Estilo Reprogramar + Justify)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.white24, width: 1),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start, // Alineado arriba
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 28),
                            SizedBox(width: 15),
                            Expanded(
                              child: Text(
                                "Se enviará una notificación a tu Matchy. Hablen por chat antes de fijar la cita para evitar cancelaciones y penalizaciones.",
                                textAlign: TextAlign.justify, // 🔥 JUSTIFICADO
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800, // Bold fuerte como en reprogramar
                                    fontSize: 14.9,
                                    fontFamily: 'Poppins',
                                    height: 1.3
                                ),
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

          // 🔥 FADE OUT INFERIOR
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
}

class _BotonPremium extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final double width;
  final double height;
  final double fontSize;
  final IconData? icon;
  final bool isAction;
  final bool isLoading;

  const _BotonPremium({
    required this.text,
    this.onTap,
    required this.width,
    this.height = 50,
    this.fontSize = 14,
    this.icon,
    this.isAction = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = isAction
        ? const LinearGradient(colors: [Color(0xFF7B1FA2), Color(0xFF4A148C)])
        : const LinearGradient(colors: [Color(0xFF5E35B1), Color(0xFF311B92)]);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 5, offset: Offset(0, 3))],
        border: Border.all(color: Colors.white12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Center(
            child: isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[Icon(icon, color: Colors.white70, size: 20), const SizedBox(width: 8)],
                Text(
                  text,
                  style: TextStyle(color: Colors.white, fontSize: fontSize, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}