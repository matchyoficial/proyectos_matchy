// 📂 lib/screens/lugar_plantilla_screen.dart
// ✅ LUGAR PLANTILLA BLINDADA (SMART CACHE PRO INYECTADO)
// 🔥 CACHÉ PRO: CachedNetworkImage aplicado en Carrusel y Zoom.
// 🔥 RENDIMIENTO: memCacheHeight dinámico para proteger la RAM con galerías de hasta +12 fotos.
// 🔥 FIX: Tamaños unificados (Nombre 30 / Dirección 18).
// 🔥 ADD: Texto informativo de sedes múltiples debajo del botón.
// 🛠️ FIX OVERFLOW FOTO: Carrusel ajustado a proporción 16:9.
// 🎯 NEW: modoSeleccionCita — cuando viene true, el botón cambia a "ESCOGER SITIO" (cian),
//    no valida bloqueo de usuario (aquí solo se elige un candidato, no se crea cita real),
//    y al tocarlo hace Navigator.pop(context, widget.lugar) para devolver el lugar elegido
//    hacia intereses_citas_screen.dart. Se oculta el texto de "sedes múltiples" en este modo.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart'; // 🔥 Motor de caché
import 'package:proyectos_matchy/models/lugar_data.dart';
import 'package:proyectos_matchy/screens/creacita_screen.dart';
import 'package:proyectos_matchy/screens/crea_cita_matchy_screen.dart';

class LugarPlantillaScreen extends StatefulWidget {
  final LugarData lugar;
  final String? matchyUidInvitado;
  final bool modoSeleccionCita; // 🎯 NUEVO

  const LugarPlantillaScreen({
    super.key,
    required this.lugar,
    this.matchyUidInvitado,
    this.modoSeleccionCita = false, // 🎯 NUEVO — default false, no rompe usos existentes
  });

  @override
  State<LugarPlantillaScreen> createState() => _LugarPlantillaScreenState();
}

class _LugarPlantillaScreenState extends State<LugarPlantillaScreen> {
  // ===========================================================================
  // 🛡️ ZONA DE CHINCHES MAESTROS (UNIFICADOS)
  // ===========================================================================

  static const double kLogoHeight = 50.0;
  static const double kLogoTopSpace = 40.0;

  static const List<Shadow> kTextShadow = [
    Shadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 6),
  ];

  // Tallas unificadas para que se vean IGUALES a la versión sin botón
  static const double kFontSizeNombre = 30.0;
  static const double kFontSizeDireccion = 18.0;

  static const List<Color> kGradientAction = [Color(0xFF6B4EE6), Color(0xFF4527A0)];
  static const List<Color> kGradientBlocked = [Color(0xFF424242), Color(0xFF212121)];
  static const List<Color> kGradientWeb = [Color(0xFF007BFF), Color(0xFF0056B3)];
  static const List<Color> kGradientSeleccion = [Color(0xFF00B4DB), Color(0xFF0083B0)]; // 🎯 NUEVO

  // Colores de fondo para el Zoom (Notificaciones)
  static const List<Color> kNotifGradient = [Color(0xFF4A3B75), Color(0xFF1F1F1F)];

  // ===========================================================================

  final PageController _pageCtrl = PageController();
  int _currentPage = 0;
  Timer? _timer;

  bool _isUserBlocked = false;
  int _userStrikes = 0;
  bool _isLoadingStatus = true;

  @override
  void initState() {
    super.initState();
    _verificarEstadoUsuario();

    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      if (widget.lugar.fotos.length < 2) return;
      final next = ((_pageCtrl.page?.round() ?? 0) + 1) % widget.lugar.fotos.length;
      _pageCtrl.animateToPage(next, duration: const Duration(milliseconds: 800), curve: Curves.easeInOutCubic);
    });
  }

  Future<void> _verificarEstadoUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        final status = (data['userStatus'] ?? 'active').toString();
        final strikes = (data['strikes'] as num?)?.toInt() ?? 0;
        final bloqueadoHasta = data['bloqueadoHasta'] as Timestamp?;
        bool bloqueado = false;
        if (status == 'blocked') bloqueado = true;
        if (bloqueadoHasta != null && bloqueadoHasta.toDate().isAfter(DateTime.now())) bloqueado = true;

        if (mounted) {
          setState(() {
            _isUserBlocked = bloqueado;
            _userStrikes = strikes;
            _isLoadingStatus = false;
          });
        }
      }
    } catch (e) { debugPrint("Error: $e"); }
  }

  void _manejarClickCrearCita() {
    if (_isUserBlocked) {
      final dias = _userStrikes * 5;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("BLOQUEADO. Strikes: $_userStrikes. Espera $dias días."),
        backgroundColor: const Color(0xFFC62828),
        behavior: SnackBarBehavior.floating,
      ));
    } else {
      if (widget.matchyUidInvitado != null) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => CreaCitaMatchyScreen(lugar: widget.lugar, matchyUidInvitado: widget.matchyUidInvitado!)));
      } else {
        Navigator.push(context, MaterialPageRoute(builder: (_) => CreaCitaScreen(lugar: widget.lugar)));
      }
    }
  }

  // 🎯 NUEVO: Manejador único del botón principal, decide entre modo selección y modo normal
  void _handleBotonPrincipalTap() {
    if (widget.modoSeleccionCita) {
      Navigator.pop(context, widget.lugar);
      return;
    }
    _manejarClickCrearCita();
  }

  // 🔥 ZOOM BLINDADO CON SMART CACHE
  void _mostrarFotoZoom(String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              width: double.infinity, height: double.infinity,
              decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: kNotifGradient)),
              child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Center(
                      child: CachedNetworkImage(
                        key: ValueKey("zoom_$url"),
                        imageUrl: url,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => const CircularProgressIndicator(color: Color(0xFFBEB3FF)),
                        errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.white54, size: 50),
                      )
                  )
              ),
            ),
            Positioned(top: 50, right: 20, child: GestureDetector(onTap: () => Navigator.pop(ctx), child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 28)))),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() { _timer?.cancel(); _pageCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final lugar = widget.lugar;
    final bool esCitaPrivada = widget.matchyUidInvitado != null;

    // 🎯 NUEVO: texto, gradiente e ícono del botón, con el modo selección como prioridad
    String textoBoton;
    List<Color> gradientBoton;
    IconData iconBoton;

    if (widget.modoSeleccionCita) {
      textoBoton = "ESCOGER SITIO";
      gradientBoton = kGradientSeleccion;
      iconBoton = Icons.check_circle_outline_rounded;
    } else if (_isUserBlocked) {
      textoBoton = "CUENTA BLOQUEADA";
      gradientBoton = kGradientBlocked;
      iconBoton = Icons.lock;
    } else {
      textoBoton = esCitaPrivada ? "INVITAR A TU MATCHY" : "CREAR CITA AQUÍ";
      gradientBoton = kGradientAction;
      iconBoton = Icons.calendar_month_rounded;
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover)),
          Column(
            children: [
              SizedBox(height: kLogoTopSpace),
              SizedBox(height: kLogoHeight, child: Image.asset('assets/images/logomatchyplano.png')),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 120),
                  child: Column(
                    children: [
                      _buildProGallery(lugar.fotos, context),
                      const SizedBox(height: 20),
                      // NOMBRE UNIFICADO (30.0)
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(lugar.nombre.toUpperCase(), textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: kFontSizeNombre, fontWeight: FontWeight.w900, fontFamily: 'Poppins', height: 1.1, shadows: kTextShadow)),
                      ),
                      const SizedBox(height: 6),
                      // DIRECCIÓN UNIFICADA (18.0)
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(lugar.direccion, textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70, fontSize: kFontSizeDireccion, fontFamily: 'Poppins', fontWeight: FontWeight.w500, shadows: kTextShadow)),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
                        child: Text(lugar.bio, textAlign: TextAlign.justify, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5, fontFamily: 'Poppins')),
                      ),
                      const SizedBox(height: 30),
                      if (lugar.hasSitioWeb) ...[
                        _PremiumButton(text: "VISITAR SITIO WEB", gradient: kGradientWeb, icon: Icons.public, onTap: () async => launchUrl(Uri.parse(lugar.sitioWeb))),
                        const SizedBox(height: 16)
                      ],
                      // 🎯 En modo selección no esperamos el estado de bloqueo (es irrelevante aquí)
                      if (_isLoadingStatus && !widget.modoSeleccionCita) const CircularProgressIndicator(color: Colors.white)
                      else ...[
                        _PremiumButton(text: textoBoton, gradient: gradientBoton, icon: iconBoton, onTap: _handleBotonPrincipalTap),

                        // 🔥 TEXTO INFORMATIVO DE SEDES (Solo si existen 2 o más, y NO en modo selección)
                        if (!widget.modoSeleccionCita && lugar.sedes.length >= 2) ...[
                          const SizedBox(height: 12),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              "Si el sitio tiene varias sedes puedes seleccionar la que gustes en el botón de crear cita",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(bottom: 0, left: 0, right: 0, height: 100, child: IgnorePointer(child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.95)], stops: const [0.0, 1.0]))))),
          Positioned(top: 50, left: 16, child: GestureDetector(onTap: () => Navigator.pop(context), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), shape: BoxShape.circle, border: Border.all(color: Colors.white12)), child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20)))),
        ],
      ),
    );
  }

  // 🔥 GALERÍA BLINDADA CON SMART CACHE Y CARGA EN CASCADA
  Widget _buildProGallery(List<String> fotos, BuildContext context) {
    // Calculamos el caché en base a la pantalla (16:9 * ratio x 2 para asegurar nitidez HD sin romper RAM)
    final int dynamicCacheHeight = (MediaQuery.of(context).size.width * (9 / 16) * 2.5).toInt();

    return Column(
      children: [
        Stack(
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 15, offset: Offset(0, 8))]),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: PageView.builder(
                    controller: _pageCtrl,
                    itemCount: fotos.length, // Soporta infinitas fotos, el PageView las descarga 1 a 1.
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemBuilder: (_, i) => GestureDetector(
                        onTap: () => _mostrarFotoZoom(fotos[i]),
                        child: CachedNetworkImage(
                            key: ValueKey(fotos[i]),
                            imageUrl: fotos[i],
                            fit: BoxFit.cover,
                            memCacheHeight: dynamicCacheHeight, // Supercargador de Memoria
                            placeholder: (context, url) => Container(
                                color: const Color(0xFF1A1A1A),
                                child: const Center(
                                    child: SizedBox(
                                        width: 30, height: 30,
                                        child: CircularProgressIndicator(color: Color(0xFFBEB3FF), strokeWidth: 2)
                                    )
                                )
                            ),
                            errorWidget: (_,__,___) => Container(color: Colors.grey[900], child: const Icon(Icons.broken_image, color: Colors.white54))
                        )
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
                  child: const Icon(Icons.zoom_in, color: Colors.white, size: 22),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (fotos.length > 1) Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(fotos.length, (index) => AnimatedContainer(duration: const Duration(milliseconds: 300), margin: const EdgeInsets.symmetric(horizontal: 4), height: 6, width: index == _currentPage ? 24 : 6, decoration: BoxDecoration(color: index == _currentPage ? const Color(0xFFBEB3FF) : Colors.white24, borderRadius: BorderRadius.circular(3))))),
      ],
    );
  }
}

class _PremiumButton extends StatelessWidget {
  final String text; final List<Color> gradient; final VoidCallback onTap; final IconData? icon;
  const _PremiumButton({required this.text, required this.gradient, required this.onTap, this.icon});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity, height: 52,
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradient), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white24)),
        child: FittedBox(fit: BoxFit.scaleDown, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [if(icon != null)...[Icon(icon, color: Colors.white, size: 20), const SizedBox(width: 10)], Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, fontFamily: 'Poppins', letterSpacing: 1.0))]))),
      ),
    );
  }
}