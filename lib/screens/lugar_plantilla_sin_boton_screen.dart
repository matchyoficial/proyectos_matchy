// 📂 lib/screens/lugar_plantilla_sin_boton_screen.dart
// 🔥 PANTALLA SITIO (SOLO LECTURA - DISEÑO PREMIUM PRO)
// 🔥 UI: Galería Pro (Zoom + Dots + Volumen).
// 🔥 UI: Textos centrados con sombra, Bio justificada.
// 🔥 UI: Botón Web Premium + Fade Out inferior + Chevron flotante.
// ✅ LOGIC: Carga datos extra de Firebase (Bio/Fotos) si es necesario.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proyectos_matchy/models/lugar_data.dart';

// =============================================================================
// 🔴🔴 ZONA DE CHINCHES MAESTROS (CONFIGURACIÓN VISUAL) 🔴🔴
// =============================================================================

// 1. LOGO
const double kLogoHeight = 50.0;
const double kLogoTopSpace = 40.0;

// 2. TEXTOS
const double kLugarTituloFontSize = 28;
const double kLugarDireccionFontSize = 16;
const double kLugarGapNombreDireccion = 6;
const double kLugarGapDireccionBio = 20;

const List<Shadow> kTextShadow = [
  Shadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 6),
];

// 3. ESTILOS PREMIUM
const double kButtonRadius = 18.0;
const List<BoxShadow> kButtonShadow = [
  BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 5))
];
const List<Color> kBtnWebGradient = [Color(0xFF007BFF), Color(0xFF0056B3)]; // Azul Web

// =============================================================================

class LugarPlantillaSinBotonScreen extends StatefulWidget {
  final LugarData lugar;

  const LugarPlantillaSinBotonScreen({super.key, required this.lugar});

  @override
  State<LugarPlantillaSinBotonScreen> createState() => _LugarPlantillaSinBotonScreenState();
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
    // Inicializar fotos
    _fotosCarrusel = List.from(widget.lugar.fotos);
    if (_fotosCarrusel.isEmpty && widget.lugar.fotoPortada.isNotEmpty) {
      _fotosCarrusel.add(widget.lugar.fotoPortada);
    }

    _firebaseDataFuture = _fetchDataFromFirebase();

    // Auto-scroll suave
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      if (_fotosCarrusel.length < 2) return;
      final next = ((_pageCtrl.page?.round() ?? 0) + 1) % _fotosCarrusel.length;
      _pageCtrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  Future<Map<String, dynamic>> _fetchDataFromFirebase() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('lugares')
          .where('nombre', isEqualTo: widget.lugar.nombre)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();
        final bio = data['bio']?.toString() ?? '';

        List<String> nuevasFotos = [];
        if (data['LugarFotos'] is List) {
          nuevasFotos = List<String>.from(data['LugarFotos']);
        } else if (data['lugarFotos'] is List) {
          nuevasFotos = List<String>.from(data['lugarFotos']);
        } else if (data['fotos'] is List) {
          nuevasFotos = List<String>.from(data['fotos']);
        }

        if (nuevasFotos.isNotEmpty) {
          if (mounted) {
            setState(() {
              _fotosCarrusel = nuevasFotos;
            });
          }
        }
        return {'bio': bio};
      }
    } catch (e) {
      debugPrint("Error buscando data: $e");
    }
    return {'bio': widget.lugar.bio};
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  // 🔥 Fullscreen con Zoom
  void _openFullscreen(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  child: Image.network(imageUrl, fit: BoxFit.contain),
                ),
              ),
              Positioned(
                top: 50, right: 20,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle, border: Border.all(color: Colors.white24)),
                    child: const Icon(Icons.close, color: Colors.white, size: 24),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lugar = widget.lugar;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. FONDO
          Positioned.fill(
            child: Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover),
          ),

          // 2. CONTENIDO SCROLLABLE
          Column(
            children: [
              SizedBox(height: kLogoTopSpace),
              SizedBox(height: kLogoHeight, child: Image.asset('assets/images/logomatchyplano.png')),
              const SizedBox(height: 16),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center, // Centrado general
                    children: [

                      // 🔥 GALERÍA PRO (Zoom + Volumen + Dots)
                      _buildProGallery(),

                      const SizedBox(height: 20),

                      // NOMBRE (Centrado + Sombra)
                      Text(
                        lugar.nombre.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: kLugarTituloFontSize,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Poppins',
                            height: 1.1,
                            shadows: kTextShadow
                        ),
                      ),

                      const SizedBox(height: kLugarGapNombreDireccion),

                      // DIRECCIÓN (Centrada + Sombra)
                      Text(
                        lugar.direccion,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: kLugarDireccionFontSize,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                          shadows: kTextShadow,
                        ),
                      ),

                      const SizedBox(height: kLugarGapDireccionBio),

                      // BIO (Justificada + Caja Semitransparente)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: FutureBuilder<Map<String, dynamic>>(
                          future: _firebaseDataFuture,
                          builder: (context, snapshot) {
                            String textoMostrar = "Cargando información...";
                            if (snapshot.connectionState == ConnectionState.done) {
                              if (snapshot.hasData && snapshot.data!['bio'] != null && snapshot.data!['bio'].toString().isNotEmpty) {
                                textoMostrar = snapshot.data!['bio'];
                              } else {
                                textoMostrar = lugar.bio.isNotEmpty ? lugar.bio : "Sin descripción disponible.";
                              }
                            }
                            return Text(
                              textoMostrar,
                              textAlign: TextAlign.justify, // Justificado
                              style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5, fontFamily: 'Poppins'),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 30),

                      // BOTÓN SITIO WEB (Premium)
                      if (lugar.hasSitioWeb)
                        _PremiumButton(
                          text: "VISITAR SITIO WEB",
                          gradient: kBtnWebGradient,
                          icon: Icons.public,
                          onTap: () async {
                            final uri = Uri.parse(lugar.sitioWeb);
                            if (await canLaunchUrl(uri)) {
                              launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          },
                        ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 3. FADE OUT INFERIOR
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

          // 4. BOTÓN CHEVRON FLOTANTE
          Positioned(
            top: 50,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6), // Más oscuro para legibilidad
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

  // ===============================================================
  // WIDGET: GALERÍA PRO
  // ===============================================================
  Widget _buildProGallery() {
    return Column(
      children: [
        Container(
          height: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 15, offset: Offset(0, 8))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                PageView.builder(
                    controller: _pageCtrl,
                    itemCount: _fotosCarrusel.length,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemBuilder: (_, i) {
                      final url = _fotosCarrusel[i];
                      return GestureDetector(
                        onTap: () => _openFullscreen(context, url),
                        child: InteractiveViewer(
                          child: Image.network(
                            url,
                            fit: BoxFit.cover,
                            loadingBuilder: (_, child, progress) => progress == null ? child : Container(color: Colors.white10, child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                            errorBuilder: (_,__,___) => Container(color: Colors.grey[800], child: const Icon(Icons.broken_image, color: Colors.white54)),
                          ),
                        ),
                      );
                    }
                ),

                // Gradiente interno para que se vean los dots
                Positioned(
                  bottom: 0, left: 0, right: 0, height: 60,
                  child: Container(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.topCenter, end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black.withOpacity(0.6)]
                        )
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // DOTS INDICATORS
        if (_fotosCarrusel.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_fotosCarrusel.length, (index) {
              final bool isActive = index == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 6,
                width: isActive ? 24 : 6,
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFFBEB3FF) : Colors.white24,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
      ],
    );
  }
}

// 🔥 WIDGET BOTÓN PREMIUM REUTILIZABLE
class _PremiumButton extends StatelessWidget {
  final String text;
  final List<Color> gradient;
  final VoidCallback onTap;
  final IconData? icon;

  const _PremiumButton({
    required this.text,
    required this.gradient,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradient),
          borderRadius: BorderRadius.circular(kButtonRadius),
          boxShadow: kButtonShadow,
          border: Border.all(color: Colors.white24, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[Icon(icon, color: Colors.white, size: 20), const SizedBox(width: 10)],
            Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900, fontFamily: 'Poppins', letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}