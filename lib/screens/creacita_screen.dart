// 📂 lib/screens/creacita_screen.dart
// ✅ CREAR CITA (DISEÑO PREMIUM FINAL)
// 🔥 UI FIX: Nombre y Dirección compactos (1 línea, sin aire entre ellos).
// 🔥 UI: Degradado Fade Out inferior agregado.
// 🔥 UI: Botones Premium conservando los colores morados originales.
// 🔥 CHINCHES: Control total de tamaños de fuente y dimensiones.
// ⚙️ LOGIC: Intacta.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:proyectos_matchy/models/lugar_data.dart';
import 'package:proyectos_matchy/widgets/matchy_back_button.dart';
import 'package:proyectos_matchy/screens/cita_creada_screen.dart';

class CreaCitaScreen extends StatefulWidget {
  static const String routeName = 'creacita';
  final LugarData lugar;

  const CreaCitaScreen({super.key, required this.lugar});

  @override
  State<CreaCitaScreen> createState() => _CreaCitaScreenState();
}

class _CreaCitaScreenState extends State<CreaCitaScreen> {
  // -------------------------------------------------------------------------
  // 🔴🔴 ZONA DE CHINCHES MAESTROS (TAMAÑOS Y ESTILOS) 🔴🔴
  // -------------------------------------------------------------------------

  // 1. TAMAÑOS DE FUENTE (CONTROL GLOBAL)
  static const double kSizeTituloPantalla = 20.0; // "VAMOS A CREAR..."
  static const double kSizeNombreLugar = 26.0;    // Nombre del sitio
  static const double kSizeDireccion = 22.0;      // Dirección
  static const double kSizeSubtitulos = 18.0;     // "PREFERENCIA", "INTENCIÓN"
  static const double kSizeTextoBoton = 18.0;     // Texto dentro de botones
  static const double kSizeRadioOpcion = 13.0;    // Hombres, Mujeres...
  static const double kSizeNotaPie = 18.0;        // Texto legal abajo

  // 2. CONFIGURACIÓN FOTO
  static const double kAlturaFoto = 210.0;
  static const double kMargenFotoHorizontal = 23.0;
  static const double kRadioFoto = 24.0;

  // 3. LOGO
  static const double kAlturaLogo = 50.0;
  static const double kEspacioBarraLogo = 35.0;

  // 4. DIMENSIONES BOTONES
  static const double kAlturaBoton = 52.0;
  static const double kRadioBoton = 18.0;

  // -------------------------------------------------------------------------

  String _fecha = '';
  String _hora = '';
  String _preferencia = 'Hombres';
  String _intencion = 'Conocernos';

  DateTime? _pickedDate;
  TimeOfDay? _pickedTime;

  bool _creating = false;
  SedeData? _sedeSeleccionada;
  static const String _citasCollection = 'citas';

  // -------------------------------------------------------------
  // LÓGICA (INTACTA)
  // -------------------------------------------------------------
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
    return 'SCG${h.toString().padLeft(6, '0')}';
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

  Future<String> _crearCitaEnFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No hay sesión iniciada');
    if (_pickedDate == null || _pickedTime == null) throw Exception('Selecciona fecha y hora');

    final scheduledAt = DateTime(_pickedDate!.year, _pickedDate!.month, _pickedDate!.day, _pickedTime!.hour, _pickedTime!.minute);
    if (scheduledAt.difference(DateTime.now()).inHours < 12) throw Exception('La cita debe programarse con mínimo 12 horas de anticipación.');

    final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final dataUser = snap.data() ?? {};
    final ownerNombre = (dataUser['nombre'] ?? '').toString();
    final ownerEdad = dataUser['edad'] is int ? dataUser['edad'] : 0;
    final ownerFoto = (dataUser['profilePhotoUrl'] ?? '').toString();

    final codigoOwner = _generarCodigoUnico(user.uid, 'OWNER');
    final codigoMatchy = _generarCodigoUnico(user.uid, 'MATCHY');
    final lugar = widget.lugar;
    final sedeFinal = (_sedeSeleccionada != null) ? _sedeSeleccionada! : SedeData(id: '', nombre: '', direccion: lugar.direccion);

    final docRef = FirebaseFirestore.instance.collection(_citasCollection).doc();

    await docRef.set({
      'ownerUid': user.uid,
      'ownerNombre': ownerNombre,
      'ownerEdad': ownerEdad,
      'ownerFoto': ownerFoto,
      'codigoOwner': codigoOwner,
      'codigoMatchy': codigoMatchy,
      'fecha': _fecha,
      'hora': _hora,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'preferencia': _preferencia,
      'intencion': _intencion,
      'status': 'online',
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
    return docRef.id;
  }

  Future<void> _onCrearCitaPressed() async {
    if (_creating) return;
    if (_pickedDate == null || _pickedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona fecha y hora')));
      return;
    }
    setState(() => _creating = true);
    try {
      final citaId = await _crearCitaEnFirestore();
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => CitaCreadaScreen(citaId: citaId, lugar: widget.lugar, fecha: _fecha, hora: _hora, preferencia: _preferencia, intencion: _intencion)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  // -------------------------------------------------------------
  // UI BUILD
  // -------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final lugar = widget.lugar;
    final width = MediaQuery.of(context).size.width;
    final itemWidth = (width - 40 - 24) / 3;
    final fotoUrl = _pickFotoLugar(lugar);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. FONDO
          Positioned.fill(child: Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover)),

          Column(
            children: [
              const SizedBox(height: kEspacioBarraLogo),
              Image.asset('assets/images/logomatchyplano.png', height: kAlturaLogo),
              const SizedBox(height: 15),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 120), // Espacio para el fade out
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // TITULO PANTALLA
                      const Text(
                        "VAMOS A CREAR TU CITA PERFECTA",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: kSizeTituloPantalla,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(color: Colors.black, blurRadius: 4)]
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),

                      // 🔥 FOTO ANCHA MATCHY
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

                      // 🔥 NOMBRE Y DIRECCIÓN (COMPACTOS Y SIN AIRE)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            Text(
                              lugar.nombre.toUpperCase(),
                              textAlign: TextAlign.center,
                              maxLines: 1, // Forzar 1 línea
                              overflow: TextOverflow.ellipsis, // Adaptar si es largo
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: kSizeNombreLugar,
                                fontWeight: FontWeight.w900,
                                height: 1.0, // Altura de línea compacta (quita aire arriba/abajo)
                                shadows: [Shadow(color: Colors.black, blurRadius: 5, offset: Offset(0, 2))],
                              ),
                            ),
                            const SizedBox(height: 4), // Espacio mínimo entre nombre y dirección
                            Text(
                              _sedeSeleccionada != null ? _sedeSeleccionada!.direccion : lugar.direccion,
                              textAlign: TextAlign.center,
                              maxLines: 1, // Forzar 1 línea
                              overflow: TextOverflow.ellipsis, // Adaptar si es largo
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: kSizeDireccion,
                                fontWeight: FontWeight.w500,
                                height: 1.0,
                                shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),

                      // ---------------- BOTONES PREMIUM ----------------
                      _BotonPremium(
                        text: _fecha.isEmpty ? "SELECCIONAR FECHA" : "FECHA: $_fecha",
                        icon: Icons.calendar_today,
                        width: width * 0.85,
                        fontSize: kSizeTextoBoton,
                        height: kAlturaBoton,
                        onTap: _creating ? null : _seleccionarFecha,
                      ),
                      const SizedBox(height: 12),

                      _BotonPremium(
                        text: _hora.isEmpty ? "SELECCIONAR HORA" : "HORA: $_hora",
                        icon: Icons.access_time,
                        width: width * 0.85,
                        fontSize: kSizeTextoBoton,
                        height: kAlturaBoton,
                        onTap: _creating ? null : _seleccionarHora,
                      ),
                      const SizedBox(height: 12),

                      if (lugar.sedes.length >= 2)
                        _BotonPremium(
                          text: _sedeSeleccionada == null ? 'SELECCIONAR SEDE' : _sedeSeleccionada!.nombre.toUpperCase(),
                          icon: Icons.store,
                          width: width * 0.85,
                          fontSize: kSizeTextoBoton,
                          height: kAlturaBoton,
                          onTap: _creating ? null : () async {
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

                      const SizedBox(height: 25),

                      // ---------------- PREFERENCIA ----------------
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text("PREFERENCIA", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: kSizeSubtitulos))
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Wrap(spacing: 12, children: [
                          SizedBox(width: itemWidth, child: _RadioOpcion(label: 'Hombres', groupValue: _preferencia, fontSize: kSizeRadioOpcion, onChanged: (v) => setState(() => _preferencia = v))),
                          SizedBox(width: itemWidth, child: _RadioOpcion(label: 'Mujeres', groupValue: _preferencia, fontSize: kSizeRadioOpcion, onChanged: (v) => setState(() => _preferencia = v))),
                          SizedBox(width: itemWidth, child: _RadioOpcion(label: 'Ambos', groupValue: _preferencia, fontSize: kSizeRadioOpcion, onChanged: (v) => setState(() => _preferencia = v))),
                        ]),
                      ),

                      const SizedBox(height: 15),

                      // ---------------- INTENCIÓN ----------------
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text("INTENCIÓN", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: kSizeSubtitulos))
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Wrap(spacing: 12, runSpacing: 10, children: [
                          SizedBox(width: itemWidth, child: _RadioOpcion(label: 'Solo hablar', groupValue: _intencion, fontSize: kSizeRadioOpcion, onChanged: (v) => setState(() => _intencion = v))),
                          SizedBox(width: itemWidth, child: _RadioOpcion(label: 'Conocernos', groupValue: _intencion, fontSize: kSizeRadioOpcion, onChanged: (v) => setState(() => _intencion = v))),
                          SizedBox(width: itemWidth, child: _RadioOpcion(label: 'Algo casual', groupValue: _intencion, fontSize: kSizeRadioOpcion, onChanged: (v) => setState(() => _intencion = v))),
                          SizedBox(width: itemWidth, child: _RadioOpcion(label: 'Amistad', groupValue: _intencion, fontSize: kSizeRadioOpcion, onChanged: (v) => setState(() => _intencion = v))),
                          SizedBox(width: itemWidth, child: _RadioOpcion(label: 'Una relación', groupValue: _intencion, fontSize: kSizeRadioOpcion, onChanged: (v) => setState(() => _intencion = v))),
                          SizedBox(width: itemWidth, child: _RadioOpcion(label: 'Algo serio', groupValue: _intencion, fontSize: kSizeRadioOpcion, onChanged: (v) => setState(() => _intencion = v))),
                        ]),
                      ),

                      const SizedBox(height: 30),

                      // ---------------- BOTÓN ACCIÓN FINAL ----------------
                      _BotonPremium(
                        text: "CREAR TU CITA",
                        width: width * 0.85,
                        isAction: true,
                        isLoading: _creating,
                        fontSize: kSizeTextoBoton,
                        height: kAlturaBoton,
                        onTap: _creating ? null : _onCrearCitaPressed,
                      ),

                      const SizedBox(height: 20),

                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 36),
                        child: Text(
                          'Recuerda: La cita debe programarse con mínimo 12 horas de anticipación.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white54, fontSize: kSizeNotaPie, fontWeight: FontWeight.w400),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 2. 🔥 DEGRADADO INFERIOR (FADE OUT)
          Positioned(
            bottom: 0, left: 0, right: 0, height: 100,
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

          // 3. BOTÓN ATRÁS
          const MatchyBackButton(top: 10, left: 16),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// COMPONENTES PREMIUM REUTILIZABLES (COLORES ORIGINALES)
// -------------------------------------------------------------

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
    // 🎨 COLORES ORIGINALES (Morados)
    // Pero aplicados en un contenedor con Sombra y Borde Premium
    final gradient = isAction
        ? const LinearGradient(colors: [Color(0xFF7B1FA2), Color(0xFF4A148C)]) // Morado intenso original
        : const LinearGradient(colors: [Color(0xFF5E35B1), Color(0xFF311B92)]); // Morado oscuro original

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(_CreaCitaScreenState.kRadioBoton),
        // Sombra Premium
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 3))],
        // Borde sutil
        border: Border.all(color: Colors.white12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(_CreaCitaScreenState.kRadioBoton),
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
                  style: TextStyle(color: Colors.white, fontSize: fontSize, fontWeight: FontWeight.bold, letterSpacing: 0.5, fontFamily: 'Poppins'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RadioOpcion extends StatelessWidget {
  final String label;
  final String groupValue;
  final double fontSize;
  final ValueChanged<String> onChanged;

  const _RadioOpcion({required this.label, required this.groupValue, required this.onChanged, this.fontSize = 13});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Radio<String>(
          value: label,
          groupValue: groupValue,
          onChanged: (v) => onChanged(v!),
          activeColor: Colors.white,
          fillColor: MaterialStateProperty.all(Colors.white),
          visualDensity: VisualDensity.compact,
        ),
        Flexible(
          child: Text(label, style: TextStyle(color: Colors.white, fontSize: fontSize, fontFamily: 'Poppins')),
        ),
      ],
    );
  }
}