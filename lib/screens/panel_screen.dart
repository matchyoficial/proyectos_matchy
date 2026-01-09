// 📂 lib/screens/panel_screen.dart
// ✅ PANEL PERFECTO con lógica Riverpod (sin cambiar diseño)
// ✅ Nombre + edad SIEMPRE en una fila (sin RenderFlex overflow)
// ✅ Foto perfil real o asset (foto #1)
// ✅ Botón "Editar Perfil" → DatosScreen
// ✅ FIX: elimina dependencia de published_profile_provider.dart (NO existe)
// ✅ FIX: incluye _MatchyBottomNav completo (antes faltaba y rompía todo)
// ✅ NUEVO: Botón "CITAS PUBLICADAS" debajo de "BUSCAR UNA CITA" (color distinto + conectado)

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:proyectos_matchy/screens/crear_cita_panel_screen.dart';

// 🔴 CHINCHE PANEL NAV A — imports de las 4 pantallas destino del grid
import 'package:proyectos_matchy/screens/restaurantes_screen.dart';
import 'package:proyectos_matchy/screens/bares_screen.dart';
import 'package:proyectos_matchy/screens/cafes_screen.dart';
import 'package:proyectos_matchy/screens/actividades_screen.dart';

// 🔴 CHINCHE PANEL NAV B — imports de las 5 pantallas principales
import 'package:proyectos_matchy/screens/perfil_screen.dart';
import 'package:proyectos_matchy/screens/citas_screen.dart';
import 'package:proyectos_matchy/screens/matchys_screen.dart';
import 'package:proyectos_matchy/screens/chat_screen.dart';

// ✅ Ir a editar datos
import 'package:proyectos_matchy/screens/datos_screen.dart';

// ✅ Provider de perfil (REAL)
import 'package:proyectos_matchy/state/profile_form_provider.dart';

// 🔴 CHINCHE PANEL CITAS PUB 0 — pantalla de “citas publicadas”
import 'package:proyectos_matchy/screens/citas_pendientes_screen.dart';

// 🔴 CHINCHE PANEL BUSCAR 0 — pantalla “Buscar una cita” (Swipe deck)
import 'package:proyectos_matchy/screens/cita_buscar.dart';

class PanelScreen extends ConsumerWidget {
  static const String routeName = 'panel';

  const PanelScreen({super.key});

  // 🔴 CHINCHE PANEL NAME 1 — lógica inteligente de nombre
  String _nombreSeguro(String raw) {
    final clean = raw.trim();
    if (clean.isEmpty) return 'SIN NOMBRE';

    final parts = clean.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'SIN NOMBRE';

    final first = parts.first;
    final two = parts.length >= 2 ? '${parts[0]} ${parts[1]}' : first;

    const int largoTotal = 12;
    const int primerCorto = 5;

    if (clean.length <= largoTotal && parts.length <= 2) {
      return clean.toUpperCase();
    }

    if (first.length <= primerCorto && parts.length >= 2) {
      if (two.length > largoTotal) return first.toUpperCase();
      return two.toUpperCase();
    }

    return first.toUpperCase();
  }

  bool _isAsset(String v) => v.startsWith('assets/');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    // mismas medidas que en el resto de pantallas principales
    const double espacioBarraLogo = 35;
    const double alturaLogo = 50;
    const double espacioLogoScroll = 15;
    const double margenInferiorPantalla = 80;

    // ✅ Estado perfil (draft actual)
    final state = ref.watch(profileFormProvider);

    final String nombre = _nombreSeguro(state.nombre);
    final String edad = state.edad.trim().isEmpty ? '—' : state.edad.trim();

    final String pais = (state.paisSeleccionado ?? '').trim();
    final String ciudad = (state.ciudadSeleccionada ?? '').trim();

    final String ubicacion = (ciudad.isEmpty && pais.isEmpty)
        ? 'Sin ubicación'
        : (ciudad.isNotEmpty && pais.isNotEmpty)
        ? '$ciudad - $pais'
        : (ciudad.isNotEmpty ? ciudad : pais);

    // ✅ Foto de perfil = foto #1 (posición 0)
    final String? fotoPerfil = state.fotosCargadas.isNotEmpty ? state.fotosCargadas.first : null;

    // ✅ Soporta asset o path real
    final Widget fotoWidget = (fotoPerfil == null || fotoPerfil.trim().isEmpty)
        ? Image.asset(
      'assets/images/perfil1.jpg',
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
    )
        : _isAsset(fotoPerfil)
        ? Image.asset(
      fotoPerfil,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
    )
        : Image.file(
      File(fotoPerfil),
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      errorBuilder: (_, __, ___) {
        // 🔴 CHINCHE FOTO SAFE 1 — si el path falla, no colapsa
        return Image.asset(
          'assets/images/perfil1.jpg',
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        );
      },
    );

    return Scaffold(
      body: Stack(
        children: [
          // 🔹 Fondo global
          Positioned.fill(
            child: Image.asset(
              'assets/images/fondo.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // 🔹 Logo + contenido scrolleable
          Column(
            children: [
              const SizedBox(height: espacioBarraLogo),
              Image.asset(
                'assets/images/logomatchyplano.png',
                height: alturaLogo,
              ),
              const SizedBox(height: espacioLogoScroll),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(
                    bottom: margenInferiorPantalla,
                  ),
                  child: _PanelContent(
                    textTheme: textTheme,
                    nombre: nombre,
                    edad: edad,
                    ubicacion: ubicacion,
                    fotoWidget: fotoWidget,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),

      // 🔹 Barra de navegación INFERIOR (PANEL = índice 2)
      bottomNavigationBar: const _MatchyBottomNav(currentIndex: 2),
    );
  }
}

// ===============================================================
// 🔹 CONTENIDO INTERNO DEL PANEL (DISEÑO INTACTO)
// ===============================================================
class _PanelContent extends StatelessWidget {
  final TextTheme textTheme;
  final String nombre;
  final String edad;
  final String ubicacion;
  final Widget fotoWidget;

  const _PanelContent({
    required this.textTheme,
    required this.nombre,
    required this.edad,
    required this.ubicacion,
    required this.fotoWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),

        // =========================================================
        // TARJETA PERFIL — PANEL FLUTTER PERFECTO
        // =========================================================
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          padding: const EdgeInsets.all(
            18, // 🔴 CHINCHE PANEL D — padding interno tarjeta perfil
          ),
          decoration: BoxDecoration(
            color: const Color(0x33FFFFFF),
            borderRadius: BorderRadius.circular(
              30, // 🔴 CHINCHE PANEL E — radio esquinas tarjeta perfil
            ),
          ),
          child: Row(
            children: [
              // FOTO PERFIL — cuadrada, bordes redondos, sin espacios y sin cortar cabeza
              ClipRRect(
                borderRadius: BorderRadius.circular(
                  20, // 🔴 CHINCHE PANEL F — radio de la foto
                ),
                child: Container(
                  width: 110, // 🔴 CHINCHE PANEL G2 — ancho foto perfil (cuadrada)
                  height: 110, // 🔴 CHINCHE PANEL H2 — alto foto perfil (cuadrada)
                  color: Colors.black26,
                  child: fotoWidget,
                ),
              ),

              const SizedBox(width: 18),

              // NOMBRE + EDAD + CIUDAD + BOTÓN EDITAR PERFIL
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ FIX RenderFlex: si no cabe, escala hacia abajo automáticamente
                    FittedBox(
                      fit: BoxFit.scaleDown, // 🔴 CHINCHE PANEL FIX 1
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            nombre,
                            style: textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontSize: 34, // 🔴 CHINCHE PANEL J
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            edad,
                            style: textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontSize: 34, // 🔴 CHINCHE PANEL J
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 6),

                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            ubicacion,
                            overflow: TextOverflow.ellipsis, // 🔴 CHINCHE PANEL FIX 2
                            style: textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontSize: 20, // 🔴 CHINCHE PANEL K
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // ✅ Editar Perfil (colores Matchy)
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const DatosScreen(),
                          ),
                        );
                      },
                      child: Container(
                        height: 36, // 🔴 CHINCHE PANEL EDIT 2 — (36)
                        decoration: BoxDecoration(
                          color: const Color(0xFFBEB3FF), // Matchy morado
                          borderRadius: BorderRadius.circular(
                            16, // 🔴 CHINCHE PANEL EDIT 3 — (16)
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Editar Perfil',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w700,
                            fontSize: 14, // 🔴 CHINCHE PANEL EDIT 4 — (14)
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // =========================================================
        // SECCIÓN MORADA: ICONO CALENDARIO + DOS BOTONES (+ NUEVO BOTÓN)
        // =========================================================
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 14, // 🔴 CHINCHE PANEL L
          ),
          decoration: BoxDecoration(
            color: const Color(0x33FFFFFF),
            borderRadius: BorderRadius.circular(
              26, // 🔴 CHINCHE PANEL M
            ),
          ),
          child: Row(
            children: [
              Image.asset(
                'assets/images/ic_calendar.png', // 🔴 CHINCHE PANEL N
                width: 90,
                height: 90,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 22),
              Expanded(
                child: Column(
                  children: [
                    _BotonPanel(
                      texto: "CREAR UNA CITA",
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            // 🔴 CHINCHE PANEL CREA 1 — ENVÍO DEL NOMBRE REAL
                            builder: (_) => CrearCitaPanelScreen(nombreUsuario: nombre),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _BotonPanel(
                      texto: "BUSCAR UNA CITA",
                      onTap: () {
                        // ✅ LINK A CitaBuscarScreen (Swipe deck)
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CitaBuscarScreen(),
                          ),
                        );
                      },
                    ),

                    // ✅ NUEVO BOTÓN (debajo de buscar cita)
                    const SizedBox(height: 12), // 🔴 CHINCHE PANEL BTN PUB SPACE 1
                    _BotonPanel(
                      texto: "CITAS PUBLICADAS",
                      // 🔴 CHINCHE PANEL BTN PUB COLOR 1 — color diferente para resaltar
                      backgroundColor: const Color(0xFFFFC107), // amarillo Matchy
                      textColor: Colors.black,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CitasPendientesScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 26),

        Text(
          "SITIOS RECOMENDADOS",
          style: textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 16),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _CategoriaPanelCard(
                      label: "RESTAURANTES",
                      imageAsset: 'assets/images/iconorestaurante.png',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const RestaurantesScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CategoriaPanelCard(
                      label: "BARES",
                      imageAsset: 'assets/images/iconobares.png',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const BaresScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _CategoriaPanelCard(
                      label: "CAFÉS",
                      imageAsset: 'assets/images/iconocafeteria.png',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CafesScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CategoriaPanelCard(
                      label: "ACTIVIDADES",
                      imageAsset: 'assets/images/iconoactividades.png',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ActividadesScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 80),
      ],
    );
  }
}

// ===========================================================
// 🔹 BOTÓN PANEL (CREAR / BUSCAR / CITAS PUBLICADAS)
// ===========================================================
class _BotonPanel extends StatelessWidget {
  final String texto;
  final VoidCallback onTap;

  // 🔴 CHINCHE PANEL BTN CUSTOM 1 — opcionales para resaltar
  final Color? backgroundColor;
  final Color? textColor;

  const _BotonPanel({
    required this.texto,
    required this.onTap,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44, // 🔴 CHINCHE PANEL U
        decoration: BoxDecoration(
          color: backgroundColor ?? const Color(0xFFBEB3FF),
          borderRadius: BorderRadius.circular(
            18, // 🔴 CHINCHE PANEL V
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textColor ?? Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

// ===========================================================
// 🔹 TARJETA INDIVIDUAL DEL GRID
// ===========================================================
class _CategoriaPanelCard extends StatelessWidget {
  final String label;
  final String imageAsset;
  final VoidCallback onTap;

  const _CategoriaPanelCard({
    required this.label,
    required this.imageAsset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 120, // 🔴 CHINCHE PANEL W
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                20, // 🔴 CHINCHE PANEL X
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.45),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
              image: DecorationImage(
                image: AssetImage(imageAsset),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================
// 🔹 BARRA DE NAVEGACIÓN INFERIOR LOCAL PARA PANEL
// ===========================================================
class _MatchyBottomNav extends StatelessWidget {
  final int currentIndex; // 0 Perfil, 1 Citas, 2 Panel, 3 Matchy, 4 Chat

  const _MatchyBottomNav({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    const Color navBackground = Color(0xFF000000);
    const Color selectedColor = Color(0xFFE0D4FF);
    final Color unselectedColor = Colors.white54;

    return BottomNavigationBar(
      backgroundColor: navBackground,
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      selectedItemColor: selectedColor,
      unselectedItemColor: unselectedColor,
      selectedFontSize: 10,
      unselectedFontSize: 10,
      showUnselectedLabels: true,
      selectedLabelStyle: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
      ),
      items: [
        _navItem(
          asset: 'assets/images/profile.png',
          label: 'PERFIL',
          isSelected: currentIndex == 0,
        ),
        _navItem(
          asset: 'assets/images/citas.png',
          label: 'CITAS',
          isSelected: currentIndex == 1,
        ),
        _navItem(
          asset: 'assets/images/panel.png',
          label: 'PANEL',
          isSelected: currentIndex == 2,
        ),
        _navItem(
          asset: 'assets/images/matchy.png',
          label: 'MATCHY',
          isSelected: currentIndex == 3,
        ),
        _navItem(
          asset: 'assets/images/chat.png',
          label: 'CHAT',
          isSelected: currentIndex == 4,
        ),
      ],
      onTap: (index) {
        if (index == currentIndex) return;

        Widget dest;
        switch (index) {
          case 0:
            dest = const PerfilScreen(showBottomNav: true);
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

  static BottomNavigationBarItem _navItem({
    required String asset,
    required String label,
    required bool isSelected,
  }) {
    const double unselectedSize = 20;
    const double selectedSize = 24;

    Widget icon;
    if (isSelected) {
      icon = SizedBox(
        height: selectedSize,
        child: Center(
          child: ColorFiltered(
            colorFilter: const ColorFilter.mode(
              Color(0xFFE0D4FF),
              BlendMode.srcIn,
            ),
            child: Image.asset(
              asset,
              width: selectedSize,
              height: selectedSize,
            ),
          ),
        ),
      );
    } else {
      icon = SizedBox(
        height: selectedSize,
        child: Center(
          child: Image.asset(
            asset,
            width: unselectedSize,
            height: unselectedSize,
          ),
        ),
      );
    }

    return BottomNavigationBarItem(
      icon: icon,
      label: label,
    );
  }
}
