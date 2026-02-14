// 📂 lib/screens/lugar_plantilla_sin_boton_screen.dart
// 🔥 PANTALLA SITIO BLINDADA (SOLO LECTURA - DISEÑO PREMIUM PRO)
// ✅ LOGIC: Carga Híbrida (ID + Rescate por Nombre) para citas viejas y nuevas.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proyectos_matchy/models/lugar_data.dart';

const double kLogoHeight = 50.0;
const double kLogoTopSpace = 40.0;
const double kLugarTituloFontSize = 30.0;
const double kLugarDireccionFontSize = 18.0;
const double kLugarGapNombreDireccion = 6;
const double kLugarGapDireccionBio = 20;
const List<Shadow> kTextShadow = [Shadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 6)];
const double kButtonRadius = 18.0;
const List<BoxShadow> kButtonShadow = [BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 5))];
const List<Color> kBtnWebGradient = [Color(0xFF007BFF), Color(0xFF0056B3)];
const List<Color> kNotifGradient = [Color(0xFF4A3B75), Color(0xFF1F1F1F)];

class LugarPlantillaSinBotonScreen extends StatefulWidget {
  final LugarData lugar;
  const LugarPlantillaSinBotonScreen({super.key, required this.lugar});
  @override State<LugarPlantillaSinBotonScreen> createState() => _LugarPlantillaSinBotonScreenState();
}

class _LugarPlantillaSinBotonScreenState extends State<LugarPlantillaSinBotonScreen> {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;
  Timer? _timer;
  Future<Map<String, dynamic>>? _firebaseDataFuture;
  List<String> _fotosCarrusel = [];

  @override
  void initState() {
    super.initState();
    _fotosCarrusel = List.from(widget.lugar.fotos);
    if (_fotosCarrusel.isEmpty && widget.lugar.fotoPortada.isNotEmpty) {
      _fotosCarrusel.add(widget.lugar.fotoPortada);
    }
    _firebaseDataFuture = _fetchDataFromFirebase();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || _fotosCarrusel.length < 2) return;
      final next = ((_pageCtrl.page?.round() ?? 0) + 1) % _fotosCarrusel.length;
      _pageCtrl.animateToPage(next, duration: const Duration(milliseconds: 800), curve: Curves.easeInOutCubic);
    });
  }

  Future<Map<String, dynamic>> _fetchDataFromFirebase() async {
    try {
      DocumentSnapshot? doc;

      // 1. INTENTO POR ID (Vía Directa para Citas Nuevas)
      if (widget.lugar.id.isNotEmpty && !widget.lugar.id.contains('PVT') && !widget.lugar.id.contains('SCG')) {
        doc = await FirebaseFirestore.instance.collection('lugares').doc(widget.lugar.id).get();
      }

      // 2. RESCATE POR NOMBRE (Para Citas Viejas o si el ID falló)
      if (doc == null || !doc.exists) {
        final query = await FirebaseFirestore.instance
            .collection('lugares')
            .where('nombre', isEqualTo: widget.lugar.nombre)
            .limit(1)
            .get();
        if (query.docs.isNotEmpty) doc = query.docs.first;
      }

      if (doc != null && doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final bio = data['bio']?.toString() ?? '';

        List<String> nuevasFotos = [];
        if (data['LugarFotos'] is List) nuevasFotos = List<String>.from(data['LugarFotos']);
        else if (data['lugarFotos'] is List) nuevasFotos = List<String>.from(data['lugarFotos']);
        else if (data['fotos'] is List) nuevasFotos = List<String>.from(data['fotos']);

        if (nuevasFotos.isNotEmpty && mounted) {
          setState(() { _fotosCarrusel = nuevasFotos; });
        }
        return {'bio': bio};
      }
    } catch (e) {
      debugPrint("Error rescatando datos: $e");
    }
    return {'bio': widget.lugar.bio};
  }

  @override void dispose() { _timer?.cancel(); _pageCtrl.dispose(); super.dispose(); }

  void _openFullscreen(BuildContext context, String imageUrl) {
    showDialog(context: context, builder: (ctx) => Dialog(backgroundColor: Colors.transparent, insetPadding: EdgeInsets.zero, child: Stack(alignment: Alignment.topRight, children: [Container(width: double.infinity, height: double.infinity, decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: kNotifGradient)), child: InteractiveViewer(minScale: 0.5, maxScale: 4.0, child: Center(child: Image.network(imageUrl, fit: BoxFit.contain, loadingBuilder: (_, child, progress) => progress == null ? child : const CircularProgressIndicator(color: Colors.white), errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white54, size: 50))))), Positioned(top: 50, right: 20, child: GestureDetector(onTap: () => Navigator.pop(ctx), child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 28))))])));
  }

  @override
  Widget build(BuildContext context) {
    final lugar = widget.lugar;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        Positioned.fill(child: Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover)),
        Column(children: [
          const SizedBox(height: kLogoTopSpace),
          SizedBox(height: kLogoHeight, child: Image.asset('assets/images/logomatchyplano.png')),
          const SizedBox(height: 16),
          Expanded(child: SingleChildScrollView(physics: const BouncingScrollPhysics(), padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 120), child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
            _buildProGallery(),
            const SizedBox(height: 20),
            FittedBox(fit: BoxFit.scaleDown, child: Text(lugar.nombre.toUpperCase(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: kLugarTituloFontSize, fontWeight: FontWeight.w900, fontFamily: 'Poppins', height: 1.1, shadows: kTextShadow))),
            const SizedBox(height: kLugarGapNombreDireccion),
            FittedBox(fit: BoxFit.scaleDown, child: Text(lugar.direccion, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: kLugarDireccionFontSize, fontFamily: 'Poppins', fontWeight: FontWeight.w500, shadows: kTextShadow))),
            const SizedBox(height: kLugarGapDireccionBio),
            Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)), child: FutureBuilder<Map<String, dynamic>>(future: _firebaseDataFuture, builder: (context, snapshot) {
              String textoMostrar = "Cargando biografía...";
              if (snapshot.connectionState == ConnectionState.done) {
                if (snapshot.hasData && snapshot.data!['bio'] != null && snapshot.data!['bio'].toString().isNotEmpty) {
                  textoMostrar = snapshot.data!['bio'];
                } else {
                  textoMostrar = "Sin descripción disponible.";
                }
              }
              return Text(textoMostrar, textAlign: TextAlign.justify, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5, fontFamily: 'Poppins'));
            })),
            const SizedBox(height: 30),
            if (lugar.hasSitioWeb) _PremiumButton(text: "VISITAR SITIO WEB", gradient: kBtnWebGradient, icon: Icons.public, onTap: () async { final uri = Uri.parse(lugar.sitioWeb); if (await canLaunchUrl(uri)) { launchUrl(uri, mode: LaunchMode.externalApplication); } }),
            const SizedBox(height: 40),
          ]))),
        ]),
        Positioned(bottom: 0, left: 0, right: 0, height: 100, child: IgnorePointer(child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.95)], stops: const [0.0, 1.0]))))),
        Positioned(top: 50, left: 16, child: GestureDetector(onTap: () => Navigator.pop(context), child: Container(width: 42, height: 42, decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), shape: BoxShape.circle, border: Border.all(color: Colors.white24, width: 1)), child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20)))),
      ]),
    );
  }

  Widget _buildProGallery() {
    return Column(children: [
      Container(height: 250, decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 15, offset: Offset(0, 8))]), child: ClipRRect(borderRadius: BorderRadius.circular(24), child: Stack(children: [
        PageView.builder(controller: _pageCtrl, itemCount: _fotosCarrusel.length, onPageChanged: (i) => setState(() => _currentPage = i), itemBuilder: (_, i) {
          final url = _fotosCarrusel[i]; return GestureDetector(onTap: () => _openFullscreen(context, url), child: Image.network(url, fit: BoxFit.cover, loadingBuilder: (_, child, progress) => progress == null ? child : Container(color: Colors.white10, child: const Center(child: CircularProgressIndicator(strokeWidth: 2))), errorBuilder: (_,__,___) => Container(color: Colors.grey[900], child: const Icon(Icons.broken_image, color: Colors.white54))));
        }),
        Positioned(bottom: 0, left: 0, right: 0, height: 60, child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.6)])))),
      ]))),
      const SizedBox(height: 12),
      if (_fotosCarrusel.length > 1) Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(_fotosCarrusel.length, (index) => AnimatedContainer(duration: const Duration(milliseconds: 300), margin: const EdgeInsets.symmetric(horizontal: 4), height: 6, width: index == _currentPage ? 24 : 6, decoration: BoxDecoration(color: index == _currentPage ? const Color(0xFFBEB3FF) : Colors.white24, borderRadius: BorderRadius.circular(3))))),
    ]);
  }
}

class _PremiumButton extends StatelessWidget {
  final String text; final List<Color> gradient; final VoidCallback onTap; final IconData? icon;
  const _PremiumButton({required this.text, required this.gradient, required this.onTap, this.icon});
  @override Widget build(BuildContext context) { return GestureDetector(onTap: onTap, child: Container(width: double.infinity, height: 52, decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradient), borderRadius: BorderRadius.circular(kButtonRadius), boxShadow: kButtonShadow, border: Border.all(color: Colors.white24, width: 1)), padding: const EdgeInsets.symmetric(horizontal: 16), child: FittedBox(fit: BoxFit.scaleDown, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [if (icon != null) ...[Icon(icon, color: Colors.white, size: 20), const SizedBox(width: 10)], Text(text, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900, fontFamily: 'Poppins', letterSpacing: 0.5))])))); }
}