// 📂 lib/screens/lugar_plantilla_screen.dart
// ✅ Plantilla única para cualquier lugar (restaurante/bar/café/actividad)
// ✅ Carrusel máx 8 fotos + autoplay + punticos
// ✅ Nombre / dirección / bio variables
// ✅ Botón CREAR CITA fijo (✅ ahora pasa LugarData seleccionado)
// ✅ Botón MENÚ (PDF) listo para conectar
// ✅ Maps REAL: abre Google Maps con dirección/consulta (usa mapsQueryFinal del modelo)
// ✅ MAPA PREVIEW GENÉRICO: ya no depende de maps_faro.png

import 'dart:async'; // 🔴 CHINCHE PLANTILLA TIMER 1 — autoplay

import 'package:flutter/material.dart';
import 'package:proyectos_matchy/widgets/matchy_page_layout.dart';
import 'package:proyectos_matchy/models/lugar_data.dart';

// 🔴 CHINCHE PLANTILLA CITA 1 — destino botón CREAR CITA
import 'package:proyectos_matchy/screens/creacita_screen.dart';

// 🔴 CHINCHE PLANTILLA MAPS 0 — launcher
import 'package:url_launcher/url_launcher.dart';

// 🔴 CHINCHE PLANTILLA NAV 1 — bottom nav (igual estilo)
import 'package:proyectos_matchy/screens/panel_screen.dart';
import 'package:proyectos_matchy/screens/citas_screen.dart';
import 'package:proyectos_matchy/screens/perfil_screen.dart';
import 'package:proyectos_matchy/screens/matchys_screen.dart';
import 'package:proyectos_matchy/screens/chat_screen.dart';

class LugarPlantillaScreen extends StatefulWidget {
  final LugarData lugar;

  const LugarPlantillaScreen({
    super.key,
    required this.lugar,
  });

  @override
  State<LugarPlantillaScreen> createState() => _LugarPlantillaScreenState();
}

class _LugarPlantillaScreenState extends State<LugarPlantillaScreen> {
  late final PageController _pageController;
  int _currentIndex = 0;
  Timer? _autoPlayTimer;

  // 🔴 CHINCHE PLANTILLA AUTOPLAY 1 — segundos del autoplay (3)
  static const int _autoPlaySeconds = 3;

  // 🔴 CHINCHE PLANTILLA AUTOPLAY 2 — duración animación (400ms)
  static const int _animMs = 400;

  // 🔴 CHINCHE PLANTILLA FOTOS 1 — máximo de fotos visibles en carrusel (8)
  static const int _maxFotos = 8;

  // 🔴 CHINCHE MAP PREVIEW 1 — placeholder genérico para todos los lugares
  static const String _mapsPlaceholderAsset =
      'assets/images/maps_placeholder.png'; // 🔴 CHINCHE MAP PREVIEW 1

  List<String> get _fotosLimitadas {
    final fotos = widget.lugar.fotos;
    if (fotos.isEmpty) return const [];
    return fotos.take(_maxFotos).toList();
  }

  bool _isNetwork(String v) =>
      v.startsWith('http://') || v.startsWith('https://');

  // ===========================================================
  // ✅ MAPS REAL: abrir Google Maps con query (robusto Android/iOS)
  // ===========================================================
  Future<void> _abrirEnGoogleMaps(String query) async {
    final q = query.trim();

    if (q.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay dirección para abrir en Google Maps.'),
        ),
      );
      return;
    }

    // 🔴 CHINCHE MAPS URL 1 — universal: maps search por query
    final Uri uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(q)}',
    );

    // 🔴 CHINCHE MAPS MODE 1 — intenta abrir app externa
    final bool okExternal = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    // 🔴 CHINCHE MAPS FALLBACK 1 — si no hay app, abre navegador
    if (!okExternal) {
      final bool okWeb = await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
      );

      if (!okWeb && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir Google Maps.')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    final fotos = _fotosLimitadas;

    // ✅ Solo activamos autoplay si hay 2+ fotos
    if (fotos.length >= 2) {
      _autoPlayTimer = Timer.periodic(Duration(seconds: _autoPlaySeconds), (_) {
        if (!mounted) return;

        final nextPage = (_currentIndex + 1) % fotos.length;
        _pageController.animateToPage(
          nextPage,
          duration: Duration(milliseconds: _animMs),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final fotos = _fotosLimitadas;

    return Scaffold(
      body: MatchyPageLayout(
        backgroundAsset: 'assets/images/fondo.jpg',
        logoAsset: 'assets/images/logomatchyplano.png',
        scrollContent: _buildScrollContent(textTheme, fotos),
      ),
      bottomNavigationBar: const _MatchyBottomNav(currentIndex: 2),
    );
  }

  Widget _buildScrollContent(TextTheme textTheme, List<String> fotos) {
    // 🔴 CHINCHE PLANTILLA UI 1 — alto carrusel (220)
    const double alturaCarrusel = 220;

    // 🔴 CHINCHE PLANTILLA UI 2 — radio carrusel (20)
    const double radioCarrusel = 20;

    // 🔴 CHINCHE PLANTILLA UI 3 — alto “mapa” (140)
    const double alturaMapa = 140;

    final lugar = widget.lugar;

    // ✅ AHORA: la única fuente de verdad viene del modelo
    // 🔴 CHINCHE MAPS FINAL 1 — mapsQueryFinal (ya completa dirección por defecto)
    final String mapsQuery = lugar.mapsQueryFinal; // 🔴 CHINCHE MAPS FINAL 1

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 0),

        // =========================================================
        // 📌 CARRUSEL
        // =========================================================
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          height: alturaCarrusel,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radioCarrusel),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.45),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: fotos.isEmpty
              ? Image.asset(
            // 🔴 CHINCHE PLANTILLA FALLBACK 1 — imagen si no hay fotos
            'assets/images/perfil1.jpg',
            fit: BoxFit.cover,
          )
              : PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemCount: fotos.length,
            itemBuilder: (_, index) {
              final src = fotos[index];

              if (_isNetwork(src)) {
                return Image.network(
                  src,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: (_, __, ___) => Image.asset(
                    'assets/images/perfil1.jpg',
                    fit: BoxFit.cover,
                  ),
                );
              }

              return Image.asset(
                src,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        // 🔹 Indicadores (solo si hay 2+)
        if (fotos.length >= 2)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(fotos.length, (i) {
              final isActive = i == _currentIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 10 : 6,
                height: isActive ? 10 : 6,
                decoration: BoxDecoration(
                  color: isActive ? Colors.white : Colors.white.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),

        const SizedBox(height: 12),

        // =========================================================
        // 📌 INFO
        // =========================================================
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lugar.nombre, // 🔴 CHINCHE PLANTILLA VAR 1
                style: textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontSize: 22, // 🔴 CHINCHE PLANTILLA TEXT 1
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                lugar.direccion, // 🔴 CHINCHE PLANTILLA VAR 2
                style: textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontSize: 16, // 🔴 CHINCHE PLANTILLA TEXT 2
                ),
              ),
              const SizedBox(height: 10),
              Text(
                lugar.bio, // 🔴 CHINCHE PLANTILLA VAR 3
                style: textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontSize: 14, // 🔴 CHINCHE PLANTILLA TEXT 3
                  height: 1.4,
                ),
                textAlign: TextAlign.justify,
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // =========================================================
        // 📌 BOTONES
        // =========================================================
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  // ✅ FIX CLAVE: pasar el LugarData seleccionado
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CreaCitaScreen(
                        lugar: widget.lugar, // 🔴 CHINCHE PLANTILLA CITA FIX 1
                      ),
                    ),
                  );
                },
                icon: Image.asset(
                  'assets/images/ic_calendar.png',
                  width: 22,
                  height: 22,
                  color: Colors.white,
                ),
                label: const Text(
                  "CREAR UNA CITA",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A5ACD),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  // 🔴 CHINCHE PLANTILLA PDF 1 — pendiente (lo dejamos para después)
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  "DESCARGAR MENÚ",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // =========================================================
        // 📌 MAPS REAL (click) + PREVIEW GENÉRICO
        // =========================================================
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GestureDetector(
            // 🔴 CHINCHE MAPS TAP 1 — tap en el título también abre Maps
            onTap: () => _abrirEnGoogleMaps(mapsQuery),
            child: Text(
              "Ubicación en Google Maps:",
              style: textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        GestureDetector(
          // 🔴 CHINCHE MAPS TAP 2 — tap en la imagen abre Maps
          onTap: () => _abrirEnGoogleMaps(mapsQuery),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: alturaMapa,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.45),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              // ✅ CAMBIO CLAVE: ya no es maps_faro.png, es genérico para todos
              _mapsPlaceholderAsset, // 🔴 CHINCHE MAP PREVIEW 1
              fit: BoxFit.cover,
            ),
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }
}

// ===========================================================
// 🔹 BARRA NAV INFERIOR (igual estilo)
// ===========================================================
class _MatchyBottomNav extends StatelessWidget {
  final int currentIndex;

  const _MatchyBottomNav({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    const Color navBackground = Color(0xCC000000);
    const Color selectedColor = Color(0xFFE0D4FF);
    final Color unselectedColor = Colors.white.withOpacity(0.65);

    return BottomNavigationBar(
      backgroundColor: navBackground,
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      selectedItemColor: selectedColor,
      unselectedItemColor: unselectedColor,
      selectedFontSize: 10,
      unselectedFontSize: 10,
      selectedLabelStyle:
      const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
      unselectedLabelStyle:
      const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
      items: [
        _navItem('assets/images/profile.png', 'Perfil'),
        _navItem('assets/images/citas.png', 'Citas'),
        _navItem('assets/images/panel.png', 'Panel'),
        _navItem('assets/images/matchy.png', 'Matchy'),
        _navItem('assets/images/chat.png', 'Chat'),
      ],
      onTap: (index) {
        if (index == currentIndex) return;

        Widget dest;
        switch (index) {
          case 0:
            dest = const PerfilScreen();
            break;
          case 1:
            dest = const CitasScreen();
            break;
          case 2:
            dest = const PanelScreen();
            break;
          case 3:
            dest = const MatchysScreen();
            break;
          default:
            dest = const ChatScreen();
        }

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => dest),
              (route) => false,
        );
      },
    );
  }

  static BottomNavigationBarItem _navItem(String asset, String label) {
    const double size = 22;

    return BottomNavigationBarItem(
      icon: SizedBox(
        height: 24,
        child: Center(
          child: Image.asset(asset, width: size, height: size),
        ),
      ),
      label: label,
    );
  }
}
