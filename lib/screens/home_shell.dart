// 📂 lib/screens/home_shell.dart
// ✅ Shell principal con IndexedStack (mantiene estado por tab)
// ✅ BottomNav ÚNICO para toda la app
// ✅ FIX: la barra NO desaparece al volver al Panel
// ✅ NUEVO: controlador interno para cambiar tabs desde cualquier pantalla
// ✅ NUEVO: HomeShell.go(...) para volver al shell si te sales por error (pushReplacement a Panel, etc.)

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

  /// ✅ Obtener controlador del shell desde cualquier widget debajo del HomeShell
  static _HomeShellController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_HomeShellScope>();
    if (scope == null) {
      throw FlutterError(
        'HomeShell.of(context) llamado fuera del árbol de HomeShell.\n'
            'Usa HomeShell.go(context, index: X) si estás fuera del shell.',
      );
    }
    return scope.controller;
  }

  /// ✅ Teletransporte seguro al shell (cuando te saliste por pushReplacement a PanelScreen, etc.)
  static void go(BuildContext context, {int index = 2}) {
    final safeIndex = index.clamp(0, 4);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => HomeShell(initialIndex: safeIndex)),
          (route) => false,
    );
  }

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _index;

  late final _HomeShellController _controller = _HomeShellController(
    getIndex: () => _index,
    setIndex: (i) {
      final next = i.clamp(0, 4);
      if (next == _index) return;
      setState(() => _index = next);
    },
  );

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, 4);
  }

  @override
  void didUpdateWidget(covariant HomeShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 🔴 CHINCHE SHELL 2 — si alguien recrea HomeShell con otro initialIndex, lo respetamos
    final next = widget.initialIndex.clamp(0, 4);
    if (next != _index) {
      setState(() => _index = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _HomeShellScope(
      controller: _controller,
      child: Scaffold(
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
          onTap: (i) => _controller.setIndex(i),
        ),
      ),
    );
  }
}

// ================================================================
// 🔹 CONTROLLER + SCOPE (SIN Riverpod, SIN archivos extra)
// ================================================================

class _HomeShellController {
  final int Function() getIndex;
  final void Function(int) setIndex;

  _HomeShellController({
    required this.getIndex,
    required this.setIndex,
  });
}

class _HomeShellScope extends InheritedWidget {
  final _HomeShellController controller;

  const _HomeShellScope({
    required this.controller,
    required super.child,
  });

  @override
  bool updateShouldNotify(covariant _HomeShellScope oldWidget) {
    // El controller es el mismo objeto, no necesitamos notificar por cambios.
    return false;
  }
}

// ================================================================
// 🔹 BOTTOM NAV
// ================================================================

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
