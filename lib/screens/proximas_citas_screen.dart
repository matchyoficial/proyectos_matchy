// 📂 lib/screens/proximas_citas_screen.dart
// ✅ PRÓXIMAS CITAS — estilo Matchy (fondo + logo + cards translúcidas)
// ✅ Incluye: título "TU CITA CON X", label "EMPIEZA EN:", countdown real,
//            fotos 2 usuarios, foto del sitio + nombre/dirección (más grande),
//            datos: Día / Hora / Intención (más grande),
//            código de tu cita, input para código del otro usuario,
//            botón Confirmar (valida placeholder).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:proyectos_matchy/widgets/matchy_page_layout.dart';

// 🔴 CHINCHE NAV IMPORTS — mismas pantallas (si usas HomeShell, pasa showBottomNav=false)
import 'package:proyectos_matchy/screens/perfil_screen.dart';
import 'package:proyectos_matchy/screens/citas_screen.dart';
import 'package:proyectos_matchy/screens/panel_screen.dart';
import 'package:proyectos_matchy/screens/matchys_screen.dart';
import 'package:proyectos_matchy/screens/chat_screen.dart';

class ProximasCitasScreen extends StatefulWidget {
  // 🔴 CHINCHE DATA A — nombre del match
  final String nombreMatch;

  // 🔴 CHINCHE DATA B — foto del usuario (asset; por ahora soporte asset)
  final String fotoUsuarioAsset;

  // 🔴 CHINCHE DATA C — foto del match (asset)
  final String fotoMatchAsset;

  // 🔴 CHINCHE DATA D — fecha/hora REAL de la cita (para countdown)
  final DateTime citaDateTime;

  // 🔴 CHINCHE DATA E — foto sitio (asset)
  final String fotoSitioAsset;

  // 🔴 CHINCHE DATA F — nombre + dirección sitio
  final String nombreSitio;
  final String direccionSitio;

  // 🔴 CHINCHE DATA G — datos visibles
  final String diaTexto; // ej: "Sábado 25 de Enero"
  final String horaTexto; // ej: "7:30 PM"
  final String intencionTexto; // ej: "Cena romántica"

  // 🔴 CHINCHE DATA H — código cita (TU código)
  final String codigoCita;

  // 🔴 CHINCHE NAV A — mostrar bottom nav (si estás dentro de HomeShell: false)
  final bool showBottomNav;

  const ProximasCitasScreen({
    super.key,
    required this.nombreMatch,
    required this.fotoUsuarioAsset,
    required this.fotoMatchAsset,
    required this.citaDateTime,
    required this.fotoSitioAsset,
    required this.nombreSitio,
    required this.direccionSitio,
    required this.diaTexto,
    required this.horaTexto,
    required this.intencionTexto,
    required this.codigoCita,
    this.showBottomNav = true,
  });

  @override
  State<ProximasCitasScreen> createState() => _ProximasCitasScreenState();
}

class _ProximasCitasScreenState extends State<ProximasCitasScreen> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  // 🔴 CHINCHE INPUT 1 — controller para el código del otro usuario
  final TextEditingController _codigoOtroCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _recalcRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _recalcRemaining();
    });
  }

  void _recalcRemaining() {
    final now = DateTime.now();
    final diff = widget.citaDateTime.difference(now);
    final next = diff.isNegative ? Duration.zero : diff;
    if (mounted) setState(() => _remaining = next);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codigoOtroCtrl.dispose(); // 🔴 CHINCHE INPUT 2 — dispose controller
    super.dispose();
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  String _formatCountdown(Duration d) {
    final totalSeconds = d.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    return '${_two(hours)}:${_two(minutes)}:${_two(seconds)}';
  }

  void _confirmarCita(String codigoOtro) {
    // 🔴 CHINCHE ACTION 1 — lógica placeholder (aquí conectamos Firestore luego)
    // ✅ Reglas mínimas por ahora: no vacío y longitud mínima
    final clean = codigoOtro.trim().toUpperCase();

    // 🔴 CHINCHE VALID 1 — mínimo de caracteres requerido
    const int minLen = 4; // 🔴 4

    if (clean.isEmpty || clean.length < minLen) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Escribe el código que te dio tu matchy.'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Código recibido: $clean (placeholder).'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // 🔴 CHINCHE UI 1 — espacios y tamaños (TODOS numéricos)
    const double topSpacing = 35; // 🔴 35
    const double logoHeight = 50; // 🔴 50
    const double logoOffsetY = 0; // 🔴 0
    const double spaceLogoToScroll = 15; // 🔴 15

    return Scaffold(
      body: MatchyPageLayout(
        backgroundAsset: 'assets/images/fondo.jpg',
        logoAsset: 'assets/images/logomatchyplano.png',
        topSpacing: topSpacing,
        logoHeight: logoHeight,
        logoOffsetY: logoOffsetY,
        spaceLogoToScroll: spaceLogoToScroll,
        scrollContent: _Content(
          textTheme: textTheme,
          nombreMatch: widget.nombreMatch,
          fotoUsuarioAsset: widget.fotoUsuarioAsset,
          fotoMatchAsset: widget.fotoMatchAsset,
          countdownText: _formatCountdown(_remaining),
          citaIniciada: _remaining == Duration.zero,
          fotoSitioAsset: widget.fotoSitioAsset,
          nombreSitio: widget.nombreSitio,
          direccionSitio: widget.direccionSitio,
          diaTexto: widget.diaTexto,
          horaTexto: widget.horaTexto,
          intencionTexto: widget.intencionTexto,
          codigoCita: widget.codigoCita,
          codigoOtroCtrl: _codigoOtroCtrl,
          onConfirmar: _confirmarCita,
        ),
      ),
      bottomNavigationBar:
      widget.showBottomNav ? const _MatchyBottomNav(currentIndex: 1) : null,
    );
  }
}

// ================================================================
// 🔹 CONTENIDO (UI)
// ================================================================
class _Content extends StatelessWidget {
  final TextTheme textTheme;

  final String nombreMatch;
  final String fotoUsuarioAsset;
  final String fotoMatchAsset;

  final String countdownText;
  final bool citaIniciada;

  final String fotoSitioAsset;
  final String nombreSitio;
  final String direccionSitio;

  final String diaTexto;
  final String horaTexto;
  final String intencionTexto;

  final String codigoCita;

  // 🔴 CHINCHE INPUT A — controller (código del otro usuario)
  final TextEditingController codigoOtroCtrl;

  // 🔴 CHINCHE ACTION A — confirmar (recibe el código del otro usuario)
  final void Function(String codigoOtro) onConfirmar;

  const _Content({
    required this.textTheme,
    required this.nombreMatch,
    required this.fotoUsuarioAsset,
    required this.fotoMatchAsset,
    required this.countdownText,
    required this.citaIniciada,
    required this.fotoSitioAsset,
    required this.nombreSitio,
    required this.direccionSitio,
    required this.diaTexto,
    required this.horaTexto,
    required this.intencionTexto,
    required this.codigoCita,
    required this.codigoOtroCtrl,
    required this.onConfirmar,
  });

  @override
  Widget build(BuildContext context) {
    // 🔴 CHINCHE LAYOUT 1 — paddings y espacios
    const double padH = 16; // 🔴 16
    const double padBottom = 28; // 🔴 28
    const double gapTitle = 10; // 🔴 10
    const double gapSection = 16; // 🔴 16
    const double gapSmall = 8; // 🔴 8

    // 🔴 CHINCHE CARD 1 — estilo general de tarjetas
    const double cardRadius = 20; // 🔴 20
    const double cardPad = 14; // 🔴 14
    const Color glass = Color(0x33FFFFFF);

    // 🔴 CHINCHE PHOTO 1 — tamaño cuadros fotos usuarios
    const double userPhotoSize = 120; // 🔴 120
    const double userPhotoRadius = 18; // 🔴 18
    const double userPhotoBorder = 2; // 🔴 2

    // 🔴 CHINCHE SITE 1 — foto del sitio
    const double sitePhotoHeight = 210; // 🔴 210
    const double sitePhotoRadius = 22; // 🔴 22

    // 🔴 CHINCHE BTN 1 — botón confirmar
    const double btnHeight = 52; // 🔴 52
    const double btnRadius = 999; // 🔴 999 (Stadium look)
    const Color btnColor = Color(0xFFB3D9FF); // 🔴 Azul claro Matchy

    // =========================================================
    // 🔴 CHINCHE VISUAL 1 — subir tamaños “visibles” según tu pedido
    // =========================================================
    const double siteNameSize = 22; // 🔴 antes 18 -> ahora 22
    const double siteAddressSize = 15; // 🔴 antes 13 -> ahora 15
    const double kvLabelSize = 16; // 🔴 antes 14 -> ahora 16
    const double kvValueSize = 16; // 🔴 antes 14 -> ahora 16

    // 🔴 CHINCHE INPUT UI 1 — input height y radius
    const double inputHeight = 54; // 🔴 54
    const double inputRadius = 16; // 🔴 16

    return Padding(
      padding: const EdgeInsets.fromLTRB(padH, 0, padH, padBottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // =========================================================
          // ✅ TITULO (MAYÚSCULAS)
          // =========================================================
          Text(
            'TU CITA CON ${nombreMatch.toUpperCase()}',
            textAlign: TextAlign.center,
            style: textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontSize: 22, // 🔴 CHINCHE TXT 1 — 22
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: gapTitle),

          // =========================================================
          // ✅ CUENTA REGRESIVA (CARD)
          // =========================================================
          Container(
            padding: const EdgeInsets.all(cardPad),
            decoration: BoxDecoration(
              color: glass,
              borderRadius: BorderRadius.circular(cardRadius),
            ),
            child: Column(
              children: [
                Text(
                  'EMPIEZA EN:',
                  style: textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontSize: 16, // 🔴 CHINCHE TXT 2 — 16
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6, // 🔴 CHINCHE TXT 2B — 0.6
                  ),
                ),
                const SizedBox(height: gapSmall),
                Text(
                  citaIniciada ? '¡YA EMPEZÓ!' : countdownText,
                  style: textTheme.displaySmall?.copyWith(
                    color: citaIniciada ? const Color(0xFFB3D9FF) : Colors.white,
                    fontSize: 34, // 🔴 CHINCHE TXT 3 — 34
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2, // 🔴 CHINCHE TXT 4 — 1.2
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: gapSection),

          // =========================================================
          // ✅ FOTOS USUARIOS
          // =========================================================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _PhotoBox(
                label: 'Tú',
                asset: fotoUsuarioAsset,
                size: userPhotoSize,
                radius: userPhotoRadius,
                borderW: userPhotoBorder,
              ),
              _PhotoBox(
                label: nombreMatch,
                asset: fotoMatchAsset,
                size: userPhotoSize,
                radius: userPhotoRadius,
                borderW: userPhotoBorder,
              ),
            ],
          ),

          const SizedBox(height: gapSection),

          // =========================================================
          // ✅ SITIO (foto + nombre + dirección) MÁS GRANDE
          // =========================================================
          Container(
            decoration: BoxDecoration(
              color: glass,
              borderRadius: BorderRadius.circular(cardRadius),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(sitePhotoRadius),
                  child: Image.asset(
                    fotoSitioAsset,
                    height: sitePhotoHeight,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: sitePhotoHeight,
                      color: Colors.black26,
                      child: const Center(
                        child: Icon(Icons.image_not_supported,
                            color: Colors.white70, size: 48),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      14, 12, 14, 14), // 🔴 CHINCHE SITE PAD — 14/12/14/14
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombreSitio,
                        style: textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontSize: siteNameSize, // 🔴 CHINCHE TXT SITE 1 — 22
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.2, // 🔴 CHINCHE TXT SITE 2 — 0.2
                        ),
                      ),
                      const SizedBox(height: 6), // 🔴 CHINCHE GAP SITE — 6
                      Text(
                        direccionSitio,
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                          fontSize:
                          siteAddressSize, // 🔴 CHINCHE TXT SITE 3 — 15
                          fontWeight: FontWeight.w700, // 🔴 CHINCHE SITE WEIGHT — 700
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: gapSection),

          // =========================================================
          // ✅ DATOS CITA MÁS GRANDE (Día / Hora / Intención)
          // =========================================================
          Container(
            padding: const EdgeInsets.all(cardPad),
            decoration: BoxDecoration(
              color: glass,
              borderRadius: BorderRadius.circular(cardRadius),
            ),
            child: Column(
              children: [
                _KeyValueRow(
                  k: 'Día',
                  v: diaTexto,
                  labelSize: kvLabelSize,
                  valueSize: kvValueSize,
                ),
                const SizedBox(height: 12), // 🔴 CHINCHE GAP KV — 12
                _KeyValueRow(
                  k: 'Hora',
                  v: horaTexto,
                  labelSize: kvLabelSize,
                  valueSize: kvValueSize,
                ),
                const SizedBox(height: 12),
                _KeyValueRow(
                  k: 'Intención',
                  v: intencionTexto,
                  labelSize: kvLabelSize,
                  valueSize: kvValueSize,
                ),
              ],
            ),
          ),

          const SizedBox(height: gapSection),

          // =========================================================
          // ✅ CÓDIGO (TU CÓDIGO) — sin el texto “mismo en ambos”
          // =========================================================
          Container(
            padding: const EdgeInsets.all(cardPad),
            decoration: BoxDecoration(
              color: glass,
              borderRadius: BorderRadius.circular(cardRadius),
              border: Border.all(
                color: const Color(0xFFB3D9FF),
                width: 1.2, // 🔴 CHINCHE CODE BORDER — 1.2
              ),
            ),
            child: Column(
              children: [
                Text(
                  'TU CÓDIGO DE CITA',
                  style: textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontSize: 18, // 🔴 CHINCHE TXT 7 — 18 (más visible)
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6, // 🔴 CHINCHE TXT 7B — 0.6
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  codigoCita,
                  style: textTheme.headlineSmall?.copyWith(
                    color: const Color(0xFFB3D9FF),
                    fontSize: 28, // 🔴 CHINCHE TXT 8 — 28 (más visible)
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.2, // 🔴 CHINCHE TXT 9 — 2.2
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: gapSection),

          // =========================================================
          // ✅ CÓDIGO DEL OTRO USUARIO (INPUT)
          // =========================================================
          Container(
            padding: const EdgeInsets.all(cardPad),
            decoration: BoxDecoration(
              color: glass,
              borderRadius: BorderRadius.circular(cardRadius),
              border: Border.all(
                color: Colors.white70,
                width: 1.1, // 🔴 CHINCHE OTHER BORDER — 1.1
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'CÓDIGO QUE TE DIO TU MATCHY',
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontSize: 16, // 🔴 CHINCHE OTHER TXT 1 — 16
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6, // 🔴 CHINCHE OTHER TXT 2 — 0.6
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: inputHeight, // 🔴 CHINCHE INPUT H — 54
                  child: TextField(
                    controller: codigoOtroCtrl,
                    textAlign: TextAlign.center,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18, // 🔴 CHINCHE INPUT TXT — 18
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0, // 🔴 CHINCHE INPUT SPACE — 2.0
                      fontFamily: 'Poppins',
                    ),
                    decoration: InputDecoration(
                      hintText: 'ESCRIBE EL CÓDIGO AQUÍ',
                      hintStyle: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12, // 🔴 CHINCHE HINT — 12
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        fontFamily: 'Poppins',
                      ),
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.25),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, // 🔴 CHINCHE INPUT PAD H — 12
                        vertical: 12, // 🔴 CHINCHE INPUT PAD V — 12
                      ),
                      border: OutlineInputBorder(
                        borderRadius:
                        BorderRadius.circular(inputRadius), // 🔴 16
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(inputRadius),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(inputRadius),
                        borderSide: const BorderSide(color: Color(0xFFB3D9FF), width: 1.4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Escribe el código que te dicta tu matchy para confirmar.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                    fontSize: 12, // 🔴 CHINCHE OTHER TXT 3 — 12
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: gapSection),

          // =========================================================
          // ✅ BOTÓN CONFIRMAR (usa el input)
          // =========================================================
          SizedBox(
            height: btnHeight,
            child: ElevatedButton(
              onPressed: () => onConfirmar(codigoOtroCtrl.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: btnColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(btnRadius),
                ),
              ),
              child: Text(
                'CONFIRMAR CITA',
                style: textTheme.titleSmall?.copyWith(
                  color: Colors.black87,
                  fontSize: 14, // 🔴 CHINCHE TXT 11 — 14
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8, // 🔴 CHINCHE TXT 12 — 0.8
                ),
              ),
            ),
          ),

          const SizedBox(height: 14), // 🔴 CHINCHE END GAP — 14
        ],
      ),
    );
  }
}

// ================================================================
// 🔹 MINI COMPONENTES
// ================================================================
class _PhotoBox extends StatelessWidget {
  final String label;
  final String asset;
  final double size;
  final double radius;
  final double borderW;

  const _PhotoBox({
    required this.label,
    required this.asset,
    required this.size,
    required this.radius,
    required this.borderW,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(
            color: Colors.white70,
            fontSize: 12, // 🔴 CHINCHE TXT P1 — 12
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white, width: borderW),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 8,
                offset: Offset(0, 5),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            asset,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0x33FFFFFF),
              child: const Center(
                child: Icon(Icons.person, color: Colors.white70, size: 40),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  final String k;
  final String v;

  // 🔴 CHINCHE KV SIZE — tamaños dinámicos
  final double labelSize;
  final double valueSize;

  const _KeyValueRow({
    required this.k,
    required this.v,
    required this.labelSize,
    required this.valueSize,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 4, // 🔴 CHINCHE KV FLEX 1 — 4
          child: Text(
            k,
            style: TextStyle(
              color: const Color(0xFFB3D9FF),
              fontSize: labelSize, // 🔴 CHINCHE TXT KV 1 — 16
              fontWeight: FontWeight.w900,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        Expanded(
          flex: 7, // 🔴 CHINCHE KV FLEX 2 — 7
          child: Text(
            v,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: Colors.white,
              fontSize: valueSize, // 🔴 CHINCHE TXT KV 2 — 16
              fontWeight: FontWeight.w800,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ],
    );
  }
}

// ================================================================
// 🔹 BARRA DE NAVEGACIÓN (solo si showBottomNav=true)
// ================================================================
class _MatchyBottomNav extends StatelessWidget {
  final int currentIndex;

  const _MatchyBottomNav({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    const Color navBackground = Color(0xCC000000);
    const Color selectedColor = Color(0xFFE0D4FF);
    final Color unselectedColor = Colors.white70;

    return BottomNavigationBar(
      backgroundColor: navBackground,
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      selectedItemColor: selectedColor,
      unselectedItemColor: unselectedColor,
      items: [
        _navItem('assets/images/profile.png', 'Perfil'),
        _navItem('assets/images/citas.png', 'Citas'),
        _navItem('assets/images/panel.png', 'Panel'),
        _navItem('assets/images/matchy.png', 'Matchy'),
        _navItem('assets/images/chat.png', 'Chat'),
      ],
      onTap: (index) {
        if (index == currentIndex) return;

        Widget destino;
        switch (index) {
          case 0:
            destino = const PerfilScreen();
            break;
          case 1:
            destino = const CitasScreen();
            break;
          case 2:
            destino = const PanelScreen();
            break;
          case 3:
            destino = const MatchysScreen();
            break;
          default:
            destino = const ChatScreen();
        }

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => destino),
              (route) => false,
        );
      },
    );
  }

  static BottomNavigationBarItem _navItem(String asset, String label) {
    return BottomNavigationBarItem(
      icon: SizedBox(
        height: 24,
        child: Image.asset(asset, width: 22, height: 22),
      ),
      label: label,
    );
  }
}
