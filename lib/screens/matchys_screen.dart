// 📂 lib/screens/matchys_screen.dart
// ✅ MATCHYS — Grid 2xN con fotos completas, nombre grande y botón "CREAR NUEVA CITA"
//    + Barra de navegación inferior EXACTAMENTE igual que en Perfil/Citas (currentIndex = 3)
// ✅ FIX HOME_SHELL:
//    - agrega showBottomNav para que HomeShell pueda ocultar la barra interna

import 'package:flutter/material.dart';
import 'package:proyectos_matchy/widgets/matchy_page_layout.dart';

// 🔴 CHINCHE MATCHY 0 — import real
import 'package:proyectos_matchy/screens/cita_nueva_screen.dart';

// 🔴 CHINCHE NAV IMPORTS
import 'package:proyectos_matchy/screens/perfil_screen.dart';
import 'package:proyectos_matchy/screens/citas_screen.dart';
import 'package:proyectos_matchy/screens/panel_screen.dart';
import 'package:proyectos_matchy/screens/chat_screen.dart';

class MatchysScreen extends StatelessWidget {
  // 🔴 CHINCHE HOME_SHELL 1 — permite que HomeShell controle si hay barra interna
  final bool showBottomNav;

  const MatchysScreen({
    super.key,
    this.showBottomNav = true, // ✅ por defecto, igual que antes
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: MatchyPageLayout(
        backgroundAsset: 'assets/images/fondo.jpg',
        logoAsset: 'assets/images/logomatchyplano.png',
        scrollContent: _MatchysContent(textTheme: textTheme),
        topSpacing: 35,        // 🔴 35
        logoHeight: 50,        // 🔴 50
        logoOffsetY: 0,        // 🔴 0
        spaceLogoToScroll: 15, // 🔴 15
      ),

      // ✅ Si HomeShell maneja la barra, aquí debe ser null
      bottomNavigationBar: showBottomNav ? const _MatchyBottomNav(currentIndex: 3) : null,
    );
  }
}

// ================================================================
// 🔹 DATA MOCK
// ================================================================
class _MatchyPerson {
  final String nombre;
  final int edad;
  final String fotoAsset;
  final String matchId;

  const _MatchyPerson({
    required this.nombre,
    required this.edad,
    required this.fotoAsset,
    required this.matchId,
  });
}

const List<_MatchyPerson> _mockMatchys = [
  _MatchyPerson(nombre: 'Anita',     edad: 24, fotoAsset: 'assets/images/chica1.png', matchId: 'match_001'),
  _MatchyPerson(nombre: 'Valentina', edad: 27, fotoAsset: 'assets/images/chica2.png', matchId: 'match_002'),
  _MatchyPerson(nombre: 'Carla',     edad: 23, fotoAsset: 'assets/images/chica3.png', matchId: 'match_003'),
  _MatchyPerson(nombre: 'Laura',     edad: 29, fotoAsset: 'assets/images/chica4.png', matchId: 'match_004'),
  _MatchyPerson(nombre: 'Mafe',      edad: 26, fotoAsset: 'assets/images/chica5.png', matchId: 'match_005'),
  _MatchyPerson(nombre: 'Julia',     edad: 25, fotoAsset: 'assets/images/chica6.png', matchId: 'match_006'),
  _MatchyPerson(nombre: 'Nadia',     edad: 30, fotoAsset: 'assets/images/chica7.png', matchId: 'match_007'),
  _MatchyPerson(nombre: 'Lucía',     edad: 28, fotoAsset: 'assets/images/chica8.png', matchId: 'match_008'),
];

// ================================================================
// 🔹 CONTENIDO PRINCIPAL
// ================================================================
class _MatchysContent extends StatelessWidget {
  final TextTheme textTheme;

  const _MatchysContent({required this.textTheme});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double cardWidth = (size.width - 16 - 16 - 12) / 2; // 🔴

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 40), // 🔴 40
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'MIS MATCHYS',
            style: textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontSize: 20, // 🔴 20
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Aquí verás las personas con las que hiciste match.',
            style: textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
              fontSize: 13, // 🔴 13
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          Wrap(
            spacing: 12,
            runSpacing: 26, // 🔴 26
            children: _mockMatchys
                .map((p) => _MatchyTile(person: p, width: cardWidth, textTheme: textTheme))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// 🔹 TARJETA MATCHY
// ================================================================
class _MatchyTile extends StatelessWidget {
  final _MatchyPerson person;
  final double width;
  final TextTheme textTheme;

  const _MatchyTile({
    required this.person,
    required this.width,
    required this.textTheme,
  });

  void _abrirPerfilDelMatch(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MatchyPerfilPlaceholderScreen(
          nombre: person.nombre,
          edad: person.edad,
          fotoAsset: person.fotoAsset,
          matchId: person.matchId,
        ),
      ),
    );
  }

  void _crearNuevaCita(BuildContext context) {
    // 🔴 CHINCHE MATCHY USER 1 — FOTO PRINCIPAL (elige 1-5)
    const String fotoUsuarioPrincipal = 'assets/images/perfil1.png'; // 🔴 EDITA (perfil1..perfil5)

    // 🔴 CHINCHE MATCHY USER 2 — nombre usuario (mock por ahora)
    const String nombreUsuarioPrincipal = 'JORGE'; // 🔴 EDITA

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CitaNuevaScreen(
          nombreUsuario: nombreUsuarioPrincipal,
          nombreMatch: person.nombre,
          fotoUsuario: fotoUsuarioPrincipal,
          fotoMatch: person.fotoAsset,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _abrirPerfilDelMatch(context),
              child: Container(
                height: 175, // 🔴 175
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF5B3C9B), Color(0xFF7C3AED)],
                  ),
                  boxShadow: const [
                    BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 5)),
                  ],
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      person.fotoAsset,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter, // 🔴
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: 48, // 🔴 48
                        color: Colors.black.withOpacity(0.55),
                        child: Center(
                          child: Text(
                            '${person.nombre}, ${person.edad}',
                            style: textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16, // 🔴 16
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 38, // 🔴 38
            width: width,
            child: ElevatedButton(
              onPressed: () => _crearNuevaCita(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB3D9FF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: EdgeInsets.zero,
              ),
              child: Text(
                'CREAR NUEVA CITA',
                style: textTheme.labelMedium?.copyWith(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 11, // 🔴 11
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// 🔹 PLACEHOLDER PERFIL DEL MATCH
// ================================================================
class MatchyPerfilPlaceholderScreen extends StatelessWidget {
  final String nombre;
  final int edad;
  final String fotoAsset;
  final String matchId;

  const MatchyPerfilPlaceholderScreen({
    super.key,
    required this.nombre,
    required this.edad,
    required this.fotoAsset,
    required this.matchId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$nombre, $edad')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16), // 🔴 16
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18), // 🔴 18
                child: Image.asset(
                  fotoAsset,
                  width: 240,  // 🔴 240
                  height: 320, // 🔴 320
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 14),
              Text('Perfil del match (placeholder)', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text('matchId: $matchId', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// 🔹 BARRA DE NAVEGACIÓN INFERIOR
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
