// 📂 lib/screens/nueva_cita_solicitud_screen.dart
// ✅ PANTALLA DE SOLICITUD DE CITA (FOTO INTELIGENTE + FIX CABEZAS)
// 🔥 FIX: Implementado 'FotoPerfilUsuario' en la foto del solicitante.
// 🔥 FIX UI: Fotos con 'alignment: Alignment.topCenter' (Anti-corte).
// 🔥 UI: Diseño Premium + Fade Out inferior + Botón Chevron.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:proyectos_matchy/screens/reprogramar_cita_screen.dart';
import 'package:proyectos_matchy/widgets/foto_perfil_usuario.dart'; // 👈 WIDGET NUEVO

class NuevaCitaSolicitudScreen extends StatefulWidget {
  final String citaId;

  const NuevaCitaSolicitudScreen({super.key, required this.citaId});

  @override
  State<NuevaCitaSolicitudScreen> createState() => _NuevaCitaSolicitudScreenState();
}

class _NuevaCitaSolicitudScreenState extends State<NuevaCitaSolicitudScreen> {
  bool _procesando = false;

  // ===========================================================================
  // 🔴🔴 ZONA DE CHINCHES MAESTROS (DISEÑO) 🔴🔴
  // ===========================================================================
  static const Color kCardBackground = Color(0x20FFFFFF); // Cristalino sutil
  static const double kCardRadius = 30.0;
  static const double kFotoPerfilSize = 130.0; // Grande
  static const double kFotoPerfilRadius = 24.0;
  static const double kFotoLugarHeight = 180.0; // Larga
  static const double kFotoLugarRadius = 20.0;

  // Botones
  static const List<Color> kBtnAceptarGradient = [Color(0xFF00C853), Color(0xFF009624)]; // Verde
  static const List<Color> kBtnSugerirGradient = [Color(0xFF7E208E), Color(0xFC4B3F60)]; // Morado Premium

  // Tipografía (Compacta)
  static const TextStyle kTituloStyle = TextStyle(color: Colors.white, fontSize: 29, fontWeight: FontWeight.w900, fontFamily: 'Poppins', letterSpacing: 0.5);
  static const TextStyle kSubtituloStyle = TextStyle(color: Colors.white70, fontSize: 21, fontWeight: FontWeight.w600, fontFamily: 'Poppins');

  // 🔥 Texto Compacto (Height 1.0)
  static const TextStyle kNombreLugarStyle = TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, fontFamily: 'Poppins', height: 1.0);
  static const TextStyle kDireccionStyle = TextStyle(color: Colors.white60, fontSize: 19, fontWeight: FontWeight.w500, height: 1.0);

  static const TextStyle kFechaStyle = TextStyle(color: Color(0xFFFFD700), fontSize: 20, fontWeight: FontWeight.w800, fontFamily: 'Poppins');
  static const TextStyle kHoraStyle = TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold);
  // ===========================================================================

  Future<void> _aceptarCita(String ownerUid) async {
    setState(() => _procesando = true);
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    try {
      await FirebaseFirestore.instance.collection('citas').doc(widget.citaId).update({
        'status': 'matched',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (ownerUid.isNotEmpty) {
        await FirebaseFirestore.instance.collection('users').doc(ownerUid).collection('notifications').add({
          'type': 'cita_aceptada',
          'title': '¡Cita Aceptada!',
          'body': 'Tu matchy aceptó la invitación. ¡Prepara tu salida!',
          'citaId': widget.citaId,
          'senderUid': myUid,
          'createdAt': FieldValue.serverTimestamp(),
          'read': false,
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Cita confirmada!"), backgroundColor: Colors.green));
      Navigator.pop(context);

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  void _sugerirOtroMomento() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReprogramarCitaScreen(citaId: widget.citaId),
      ),
    );
  }

  String _formatearFechaLarga(String fechaCorta) {
    try {
      final parts = fechaCorta.split('/');
      if (parts.length != 3) return fechaCorta;
      final dt = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      return DateFormat("EEEE d 'de' MMMM yyyy", 'es_ES').format(dt).toUpperCase();
    } catch (e) {
      return fechaCorta;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Fondo
          Positioned.fill(child: Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover)),

          // 2. Contenido Scrollable
          Column(
            children: [
              const SizedBox(height: 15),
              SafeArea(
                  bottom: false,
                  child: Image.asset('assets/images/logomatchyplano.png', height: 45)
              ),
              const SizedBox(height: 5),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 100), // Padding inferior extra para el fade
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('citas').doc(widget.citaId).snapshots(),
                    builder: (context, snap) {
                      if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: Colors.white));
                      if (!snap.data!.exists) return const Center(child: Text("Cita no encontrada", style: TextStyle(color: Colors.white)));

                      final data = snap.data!.data() as Map<String, dynamic>;

                      final lugarNombre = (data['lugarNombre'] ?? 'Lugar').toString().toUpperCase();
                      final lugarFoto = (data['lugarFotoPortada'] ?? '').toString();
                      final direccion = (data['sedeDireccion'] != null && data['sedeDireccion'].toString().isNotEmpty)
                          ? data['sedeDireccion'].toString()
                          : (data['lugarDireccion'] ?? '').toString();

                      final fechaRaw = (data['fecha'] ?? '').toString();
                      final horaRaw = (data['hora'] ?? '').toString();
                      final fechaBonita = _formatearFechaLarga(fechaRaw);

                      final ownerNombre = (data['ownerNombre'] ?? 'Tu Matchy').toString().toUpperCase();
                      final ownerUid = (data['ownerUid'] ?? '').toString();

                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: kCardBackground,
                          borderRadius: BorderRadius.circular(kCardRadius),
                          border: Border.all(color: Colors.white12, width: 1),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text("INVITACIÓN DE CITA", style: kTituloStyle, textAlign: TextAlign.center),
                            const SizedBox(height: 4),
                            Text("$ownerNombre te ha invitado", style: kSubtituloStyle, textAlign: TextAlign.center),
                            const SizedBox(height: 25),

                            // FOTO PERFIL (ANTI-CORTE DE CABEZA + WIDGET INTELIGENTE)
                            Container(
                              width: kFotoPerfilSize,
                              height: kFotoPerfilSize,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(kFotoPerfilRadius),
                                boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 15, offset: Offset(0, 8))],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(kFotoPerfilRadius),
                                // 🔥 AQUÍ ESTÁ EL CAMBIO
                                child: FotoPerfilUsuario(
                                  uid: ownerUid,
                                  fit: BoxFit.cover,
                                  alignment: Alignment.topCenter, // 🔥 Anti-corte de cabezas
                                ),
                              ),
                            ),

                            const SizedBox(height: 25),

                            // FOTO LUGAR (ANTI-CORTE)
                            if (lugarFoto.isNotEmpty)
                              Container(
                                height: kFotoLugarHeight,
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 20),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(kFotoLugarRadius),
                                  boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 5))],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(kFotoLugarRadius),
                                  child: Image.network(
                                      lugarFoto,
                                      fit: BoxFit.cover,
                                      alignment: Alignment.topCenter // 🔥 FIX: Prioriza el techo/cielo
                                  ),
                                ),
                              ),

                            // INFO LUGAR (COMPACTA)
                            Text(lugarNombre, textAlign: TextAlign.center, style: kNombreLugarStyle),
                            const SizedBox(height: 4), // Espacio mínimo
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.location_on, color: Colors.white60, size: 16),
                                const SizedBox(width: 4),
                                Flexible(
                                    child: Text(
                                        direccion,
                                        textAlign: TextAlign.center,
                                        style: kDireccionStyle,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis
                                    )
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // FECHA Y HORA
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: Column(
                                children: [
                                  Text(fechaBonita, textAlign: TextAlign.center, style: kFechaStyle),
                                  const SizedBox(height: 4),
                                  Text(horaRaw, textAlign: TextAlign.center, style: kHoraStyle),
                                ],
                              ),
                            ),

                            const SizedBox(height: 14),

                            // BOTONES
                            _BotonPremiumAccion(
                              text: "ACEPTAR CITA",
                              gradient: kBtnAceptarGradient,
                              icon: Icons.check_circle_rounded,
                              isLoading: _procesando,
                              onTap: _procesando ? null : () => _aceptarCita(ownerUid),
                            ),

                            const SizedBox(height: 15),

                            _BotonPremiumAccion(
                              text: "SUGERIR OTRO MOMENTO",
                              gradient: kBtnSugerirGradient,
                              icon: Icons.edit_calendar_rounded,
                              onTap: _sugerirOtroMomento,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),

          // 3. 🔥 DEGRADADO INFERIOR (FADE OUT)
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

          // 4. 🔥 BOTÓN CHEVRON (Estilo idéntico al proyecto)
          Positioned(
            top: 50,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BotonPremiumAccion extends StatelessWidget {
  final String text;
  final List<Color> gradient;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isLoading;

  const _BotonPremiumAccion({
    required this.text,
    required this.gradient,
    required this.icon,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 4))],
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Center(
            child: isLoading
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Text(
                  text,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      fontFamily: 'Poppins'
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}