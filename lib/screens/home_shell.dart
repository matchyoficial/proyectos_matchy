// 📂 lib/screens/home_shell.dart
// ✅ Shell principal con IndexedStack (mantiene estado por tab)
// ✅ BottomNav ÚNICO para toda la app
// ✅ Evita pushAndRemoveUntil en cada tap (adiós resets)

import 'package:flutter/material.dart';

import 'package:proyectos_matchy/screens/perfil_screen.dart';
import 'package:proyectos_matchy/screens/citas_screen.dart';
import 'package:proyectos_matchy/screens/panel_screen.dart';
import 'package:proyectos_matchy/screens/matchys_screen.dart';
import 'package:proyectos_matchy/screens/chat_screen.dart';

class HomeShell extends StatefulWidget {
  // 0 Perfil, 1 Citas, 2 Panel, 3 Matchy, 4 Chat
  final int initialIndex;

  const HomeShell({
    super.key,
    this.initialIndex = 2, // 🔴 CHINCHE SHELL 1 — tab inicial por defecto (Panel)
  });

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, 4);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          // 🔴 IMPORTANTE: estas pantallas deben venir SIN bottom nav interno
          PerfilScreen(showBottomNav: false),
          CitasScreen(showBottomNav: false),
          PanelScreen(showBottomNav: false),
          MatchysScreen(showBottomNav: false),
          ChatScreen(showBottomNav: false),
        ],
      ),
      bottomNavigationBar: _MatchyBottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _MatchyBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _MatchyBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

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
      items: [
        _navItem('assets/images/profile.png', 'PERFIL', currentIndex == 0),
        _navItem('assets/images/citas.png', 'CITAS', currentIndex == 1),
        _navItem('assets/images/panel.png', 'PANEL', currentIndex == 2),
        _navItem('assets/images/matchy.png', 'MATCHY', currentIndex == 3),
        _navItem('assets/images/chat.png', 'CHAT', currentIndex == 4),
      ],
      onTap: (i) {
        if (i == currentIndex) return;
        onTap(i);
      },
    );
  }

  static BottomNavigationBarItem _navItem(String asset, String label, bool sel) {
    const double unselectedSize = 20;
    const double selectedSize = 24;

    final Widget icon = sel
        ? SizedBox(
      height: selectedSize,
      child: Center(
        child: ColorFiltered(
          colorFilter: const ColorFilter.mode(
            Color(0xFFE0D4FF),
            BlendMode.srcIn,
          ),
          child: Image.asset(asset, width: selectedSize, height: selectedSize),
        ),
      ),
    )
        : SizedBox(
      height: selectedSize,
      child: Center(
        child: Image.asset(asset, width: unselectedSize, height: unselectedSize),
      ),
    );

    return BottomNavigationBarItem(icon: icon, label: label);
  }
}
