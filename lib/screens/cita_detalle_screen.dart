// 📂 lib/screens/cita_detalle_screen.dart
// ✅ DETALLE DE CITA + SISTEMA DE REDENCIÓN (BLINDADO)
// 🔥 FIX: Captura de lugarId para pasar a la plantilla de información del sitio.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proyectos_matchy/widgets/matchy_page_layout.dart';
import 'package:proyectos_matchy/screens/perfil_usuariox_screen.dart';
import 'package:proyectos_matchy/screens/reprogramar_cita_screen.dart';
import 'package:proyectos_matchy/screens/confirmar_cita.dart';
import 'package:proyectos_matchy/screens/lugar_plantilla_sin_boton_screen.dart';
import 'package:proyectos_matchy/models/lugar_data.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:proyectos_matchy/widgets/foto_perfil_usuario.dart';
import 'package:proyectos_matchy/screens/cancelar_cita_screen.dart';

const double kCardTitleSize      = 20.0;
const double kCardSubtitleSize   = 18.0;
const double kDateFontSize       = 17.0;
const double kFotoSize           = 110.0;
const double kCardBorderRadius   = 25.0;
const double kCodeFontSize       = 24.0;
const double kCapsulaRadius      = 25.0;
const double kButtonRadius = 18.0;
const List<BoxShadow> kButtonShadow = [BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 4))];
const List<Color> kBtnConfirmGradient   = [Color(0xFF00C853), Color(0xFF007E33)];
const List<Color> kBtnReproGradient     = [Color(0xFF4FC3F7), Color(0xFF0288D1)];
const List<Color> kBtnCancelGradient    = [Color(0xFFFF4B4B), Color(0xFFB71C1C)];

class CitaDetalleScreen extends StatefulWidget {
  final String citaId;
  final String lugarId; // 🔥 AÑADIDO
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
  final DateTime? citaDateTime;
  final bool isOwner;

  const CitaDetalleScreen({
    super.key,
    required this.citaId,
    required this.lugarId, // 🔥 AÑADIDO
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
    this.codigoDelOtro = '',
    this.citaDateTime,
    this.isOwner = true,
  });

  @override
  State<CitaDetalleScreen> createState() => _CitaDetalleScreenState();
}

class _CitaDetalleScreenState extends State<CitaDetalleScreen> {
  final TextEditingController _codigoMatchyController = TextEditingController();
  bool _procesandoValidacion = false;
  bool _navegandoExito = false;
  StreamSubscription<DocumentSnapshot>? _citaSubscription;

  String _displayNombre = "";
  String _displayDireccion = "";

  @override
  void initState() {
    super.initState();
    _displayNombre = widget.lugarNombre;
    _displayDireccion = widget.lugarDireccion;

    _citaSubscription = FirebaseFirestore.instance.collection('citas').doc(widget.citaId).snapshots().listen((snapshot) async {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final sNom = (data['sedeNombre'] ?? '').toString().trim();
        final sDir = (data['sedeDireccion'] ?? '').toString().trim();
        if (mounted && (sNom.isNotEmpty || sDir.isNotEmpty)) {
          setState(() { if (sNom.isNotEmpty) _displayNombre = sNom; if (sDir.isNotEmpty) _displayDireccion = sDir; });
        }
        if (data['status'] == 'finished' && !_navegandoExito && mounted) {
          final resultados = await _distribuirPuntosDeRedencion();
          if (mounted) _procesarExito(ganaronPuntos: resultados['gano'] ?? false, citasFaltantes: resultados['faltan'] ?? 0);
        }
      }
    });
  }

  @override void dispose() { _codigoMatchyController.dispose(); _citaSubscription?.cancel(); super.dispose(); }

  bool get _esCancelable { if (widget.citaDateTime == null) return true; final ahora = DateTime.now(); return widget.citaDateTime!.difference(ahora).inHours >= 12; }

  String _getFechaAmigable() {
    try {
      DateTime fechaReal;
      if (widget.citaDateTime != null) { fechaReal = widget.citaDateTime!; } else {
        final partes = widget.fecha.trim().split(RegExp(r'[/ -]'));
        if (partes.length >= 3) { fechaReal = DateTime(int.parse(partes[2]), int.parse(partes[1]), int.parse(partes[0])); } else { return widget.fecha; }
      }
      const List<String> dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
      const List<String> meses = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
      return "${dias[fechaReal.weekday - 1]} ${fechaReal.day} ${meses[fechaReal.month - 1]}";
    } catch (e) { return widget.fecha; }
  }

  Future<Map<String, dynamic>> _distribuirPuntosDeRedencion() async {
    bool ganoPuntos = false; int faltantes = 0; final myUid = FirebaseAuth.instance.currentUser?.uid; if (myUid == null) return {'gano': false, 'faltan': 0};
    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(myUid);
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(userRef); if (!snap.exists) return; final d = snap.data()!;
        int confiabilidad = (d['confiabilidad'] as num?)?.toInt() ?? 100;
        int racha = (d['citas_consecutivas_exitosas'] as num?)?.toInt() ?? 0;
        racha++; if (racha >= 3) { confiabilidad += 20; if (confiabilidad > 100) confiabilidad = 100; racha = 0; ganoPuntos = true; }
        faltantes = ganoPuntos ? 0 : (3 - racha);
        tx.update(userRef, { 'confiabilidad': confiabilidad, 'citas_consecutivas_exitosas': racha });
      });
    } catch (e) { debugPrint("Error: $e"); }
    return {'gano': ganoPuntos, 'faltan': faltantes};
  }

  Future<void> _procesarExito({bool ganaronPuntos = false, int citasFaltantes = 0}) async {
    if (_navegandoExito) return; setState(() => _navegandoExito = true);
    final user = FirebaseAuth.instance.currentUser; String myName = "Tú", myPhoto = "";
    if (user != null) { final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get(); final d = snap.data() ?? {}; myName = d['nombre'] ?? 'Tú'; myPhoto = d['profilePhotoUrl'] ?? ''; }
    if (!mounted) return; Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ConfirmarCitaScreen(ownerNombre: myName, ownerFoto: myPhoto, matchyNombre: widget.matchyNombre, matchyFoto: widget.matchyFoto, ganaronPuntos: ganaronPuntos, citasFaltantes: citasFaltantes)));
  }

  Future<void> _validarYConfirmar() async {
    if (_procesandoValidacion || _navegandoExito) return; final codigoIngresado = _codigoMatchyController.text.trim().toUpperCase(), codigoCorrecto = widget.codigoDelOtro.trim().toUpperCase();
    if (codigoIngresado.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Por favor ingresa el código de tu Matchy"), backgroundColor: Colors.orange)); return; }
    if (codigoIngresado == codigoCorrecto) {
      setState(() => _procesandoValidacion = true);
      try {
        final result = await FirebaseFirestore.instance.runTransaction((transaction) async {
          DocumentSnapshot snapshot = await transaction.get(FirebaseFirestore.instance.collection('citas').doc(widget.citaId));
          if (!snapshot.exists) throw Exception("Error: Cita no encontrada"); final data = snapshot.data() as Map<String, dynamic>;
          String miCampo = widget.isOwner ? 'ownerConfirmado' : 'matchyConfirmado', otroCampo = widget.isOwner ? 'matchyConfirmado' : 'ownerConfirmado', nombreOtro = widget.isOwner ? (data['matchyNombre'] ?? 'tu matchy') : (data['ownerNombre'] ?? 'tu matchy');
          bool elOtroYaConfirmo = data[otroCampo] == true; Map<String, dynamic> updates = { miCampo: true, 'updatedAt': FieldValue.serverTimestamp() };
          if (elOtroYaConfirmo) { updates['status'] = 'finished'; updates['citaExitosa'] = true; updates['finalizedAt'] = FieldValue.serverTimestamp(); }
          transaction.update(snapshot.reference, updates); return {'finished': elOtroYaConfirmo, 'otherName': nombreOtro};
        });
        final resultMap = result as Map<String, dynamic>; bool isFinished = resultMap['finished'] as bool; String otherName = resultMap['otherName'] as String;
        if (isFinished) { final resultadoGamificacion = await _distribuirPuntosDeRedencion(); _procesarExito(ganaronPuntos: resultadoGamificacion['gano'] ?? false, citasFaltantes: resultadoGamificacion['faltan'] ?? 0); } else {
          setState(() => _procesandoValidacion = false); if (!mounted) return; showDialog(context: context, barrierDismissible: false, builder: (ctx) => AlertDialog(backgroundColor: const Color(0xFF1A1A1A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.white24)), title: const Icon(Icons.check_circle_outline, color: Color(0xFF00C853), size: 48), content: Column(mainAxisSize: MainAxisSize.min, children: [const Text("¡TU CÓDIGO ES CORRECTO!", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)), const SizedBox(height: 20), Text("DILE A ${otherName.toUpperCase()} QUE PONGA SU CÓDIGO PARA COMPLETAR LA CITA.", textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.4)), const SizedBox(height: 20), const LinearProgressIndicator(color: Color(0xFFBEB3FF), backgroundColor: Colors.white10), const SizedBox(height: 10), const Text("Esperando confirmación del otro...", style: TextStyle(color: Colors.white38, fontSize: 12, fontStyle: FontStyle.italic))]), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ENTENDIDO", style: TextStyle(color: Colors.white)))]));
        }
      } catch (e) { if (mounted) { setState(() => _procesandoValidacion = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"))); } }
    } else { showDialog(context: context, builder: (ctx) => AlertDialog(backgroundColor: const Color(0xFF1A1A1A), title: const Text("CÓDIGO INCORRECTO", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)), content: const Text("El código ingresado no coincide con el de tu cita. Verifícalo e intenta de nuevo.", style: TextStyle(color: Colors.white70)), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("INTENTAR DE NUEVO", style: TextStyle(color: Colors.white)))])); }
  }

  void _gestionarCancelacion() { Navigator.push(context, MaterialPageRoute(builder: (_) => CancelarCitaScreen(citaId: widget.citaId, otherUserId: widget.matchyUid))); }

  Widget _buildPanelStyleCard({required Widget image, required String title, required String subtitle, String? extraTitle, String? footerText, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(kCardBorderRadius), boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 5))], border: Border.all(color: Colors.white12)),
        child: Row(children: [
          ClipRRect(borderRadius: BorderRadius.circular(20), child: SizedBox(width: kFotoSize, height: kFotoSize, child: image)), const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Row(children: [Text(title.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: kCardTitleSize, fontWeight: FontWeight.w900, fontFamily: 'Poppins', height: 1.0)), if (extraTitle != null) ...[const SizedBox(width: 6), Text(extraTitle, style: const TextStyle(color: Colors.white, fontSize: kCardTitleSize, fontWeight: FontWeight.w900, fontFamily: 'Poppins'))]])),
            const SizedBox(height: 6), FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: kCardSubtitleSize, fontWeight: FontWeight.w500))), if (footerText != null) ...[const SizedBox(height: 8), Text(footerText, style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold))]
          ])),
          const Icon(Icons.chevron_right, color: Colors.white24),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        MatchyPageLayout(
          backgroundAsset: 'assets/images/fondo.jpg', logoAsset: 'assets/images/logomatchyplano.png', topSpacing: 35, logoHeight: 45, spaceLogoToScroll: 15,
          scrollContent: SizedBox(width: double.infinity, child: SingleChildScrollView(physics: const BouncingScrollPhysics(), padding: const EdgeInsets.only(bottom: 120), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildPanelStyleCard(
              onTap: () {
                // 🔥 FIX: USAMOS EL lugarId PARA CARGAR LA INFO REAL
                final lugarTemp = LugarData(id: widget.lugarId, nombre: _displayNombre, direccion: _displayDireccion, fotoPortada: widget.lugarFotoPortada, fotos: [widget.lugarFotoPortada], bio: '', sitioWeb: '', sedes: [], orden: 0);
                Navigator.push(context, MaterialPageRoute(builder: (_) => LugarPlantillaSinBotonScreen(lugar: lugarTemp)));
              },
              image: widget.lugarFotoPortada.isNotEmpty ? Image.network(widget.lugarFotoPortada, fit: BoxFit.cover, alignment: Alignment.topCenter) : Container(color: Colors.white10),
              title: _displayNombre, subtitle: _displayDireccion,
            ),
            const SizedBox(height: 20),
            _buildPanelStyleCard(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PerfilUsuarioXScreen(uid: widget.matchyUid))), image: FotoPerfilUsuario(uid: widget.matchyUid, fit: BoxFit.cover, alignment: Alignment.topCenter), title: widget.matchyNombre, extraTitle: "${widget.matchyEdad}", subtitle: "Ver perfil completo", footerText: "Toca para ver detalles >"),
            const SizedBox(height: 20),
            Column(children: [Row(children: [Expanded(child: _buildVividCapsule(Icons.calendar_month, _getFechaAmigable(), fontSize: kDateFontSize)), const SizedBox(width: 12), Expanded(child: _buildVividCapsule(Icons.access_time_filled, widget.hora))]), const SizedBox(height: 12), Row(children: [Expanded(child: _buildVividCapsule(Icons.star, widget.intencion)), const SizedBox(width: 12), Expanded(child: _buildVividCapsule(Icons.favorite, widget.preferencia))])]),
            const SizedBox(height: 25),
            Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFF1A1A1A).withOpacity(0.95), borderRadius: BorderRadius.circular(kCapsulaRadius), border: Border.all(color: Colors.white10)), child: Column(children: [_buildDisplayCode(widget.miCodigoCita), const SizedBox(height: 15), _buildInputCode(), const SizedBox(height: 20), _PremiumButton(text: _procesandoValidacion ? "VALIDANDO..." : "CONFIRMA TU CITA", gradient: kBtnConfirmGradient, onTap: _validarYConfirmar), const SizedBox(height: 12), const Text("POR TU SEGURIDAD SOLO DALE A TU MATCHY TU CÓDIGO EN EL LUGAR DE LA CITA", textAlign: TextAlign.center, style: TextStyle(color: Colors.orangeAccent, fontSize: 16, fontWeight: FontWeight.bold))])),
            const SizedBox(height: 20),
            _PremiumButton(text: "REPROGRAMAR CITA", gradient: kBtnReproGradient, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReprogramarCitaScreen(citaId: widget.citaId)))),
            const SizedBox(height: 15),
            Opacity(opacity: _esCancelable ? 1.0 : 0.5, child: _PremiumButton(text: "CANCELAR CITA", gradient: kBtnCancelGradient, onTap: _esCancelable ? _gestionarCancelacion : () {})),
            if (!_esCancelable) const Padding(padding: EdgeInsets.only(top: 12.0), child: Text("Faltan menos de 12 horas. Solo puedes reprogramar.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 19))),
          ])))),
        ),
        Positioned(bottom: 0, left: 0, right: 0, height: 90, child: IgnorePointer(child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.95)], stops: const [0.0, 1.0]))))),
        Positioned(top: 50, left: 16, child: GestureDetector(onTap: () => Navigator.pop(context), child: Container(width: 42, height: 42, decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), shape: BoxShape.circle, border: Border.all(color: Colors.white24, width: 1)), child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20)))),
      ]),
    );
  }

  Widget _buildVividCapsule(IconData icon, String text, {double fontSize = 18.0}) { return Container(padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withOpacity(0.1))), child: Column(children: [Icon(icon, color: Colors.white, size: 28), const SizedBox(height: 8), FittedBox(fit: BoxFit.scaleDown, child: Text(text.toUpperCase(), textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: fontSize, fontWeight: FontWeight.bold)))])); }
  Widget _buildDisplayCode(String code) { return Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 18), decoration: BoxDecoration(color: const Color(0xFF6B4EE6), borderRadius: BorderRadius.circular(15)), child: Column(children: [const Text("MI CÓDIGO", style: TextStyle(color: Colors.white70, fontSize: 15, letterSpacing: 1.5)), FittedBox(fit: BoxFit.scaleDown, child: Text(code.isEmpty ? "---" : code, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: kCodeFontSize, letterSpacing: 2.0)))])); }
  Widget _buildInputCode() { return Container(decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white24)), child: TextField(controller: _codigoMatchyController, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 2.0), textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(hintText: "PON EL CÓDIGO DE TU MATCHY", hintStyle: TextStyle(color: Colors.white24, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 12)))); }
}

class _PremiumButton extends StatelessWidget {
  final String text; final List<Color> gradient; final VoidCallback onTap;
  const _PremiumButton({required this.text, required this.gradient, required this.onTap});
  @override Widget build(BuildContext context) { return GestureDetector(onTap: onTap, child: Container(width: double.infinity, height: 55, padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradient), borderRadius: BorderRadius.circular(kButtonRadius), boxShadow: kButtonShadow, border: Border.all(color: Colors.white24, width: 1)), alignment: Alignment.center, child: FittedBox(fit: BoxFit.scaleDown, child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5))))); }
}