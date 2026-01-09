// 📂 lib/home_screen.dart
// ✅ Home con barra inferior ÚNICA usando PNG, pestaña inicial: PANEL

import 'package:flutter/material.dart';

// 🔴 CHINCHE HOME A — pantallas de cada tab (todas dentro de /screens)
import 'screens/panel_screen.dart';
import 'screens/citas_screen.dart';
import 'screens/matchys_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/perfil_screen.dart';

class HomeScreen extends StatefulWidget {
  static const String routeName = '/home'; // 🔴 CHINCHE HOME 0 — ruta de Home

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ===========================================================
  // 🔹 ÍNDICE ACTUAL DE LA BARRA
  // ===========================================================
  // 0: PERFIL, 1: CITAS, 2: PANEL, 3: MATCHY, 4: CHAT
  int _currentIndex = 2; // 🔴 CHINCHE HOME 1 — pestaña inicial: 2 = PANEL

  // ===========================================================
  // 🔹 LISTA DE TABS (CADA PANTALLA)
  // ===========================================================
  // PERFIL usa showBottomNav: false para NO dibujar otra barra.
  final List<Widget> _tabs = const [
    PerfilScreen(showBottomNav: false), // 🔴 CHINCHE HOME 2 — index 0 PERFIL
    CitasScreen(),                      // 🔴 CHINCHE HOME 3 — index 1 CITAS
    PanelScreen(),                      // 🔴 CHINCHE HOME 4 — index 2 PANEL
    MatchysScreen(),                    // 🔴 CHINCHE HOME 5 — index 3 MATCHY
    ChatScreen(),                       // 🔴 CHINCHE HOME 6 — index 4 CHAT
  ];

  @override
  Widget build(BuildContext context) {
    // ===========================================================
    // 🔹 COLORES Y MEDIDAS GLOBALES DE LA BARRA
    // ===========================================================
    const double navElevation = 12; // 🔴 CHINCHE HOME 7 — sombra de la barra
    const double selectedFontSize = 10;   // 🔴 CHINCHE HOME 8 — texto seleccionado
    const double unselectedFontSize = 10; // 🔴 CHINCHE HOME 9 — texto no seleccionado

    const Color navBackground = Color(0xCC000000); // 🔴 CHINCHE HOME 10 — fondo negro
    const Color selectedColor = Color(0xFFE0D4FF); // 🔴 CHINCHE HOME 11 — color icono activo
    final Color unselectedColor =
        Colors.white54; // 🔴 CHINCHE HOME 12 — color icono inactivo

    return Scaffold(
      // =======================================================
      // 🔹 CUERPO — SE MANTIENE EL ÁRBOL DE PANTALLAS VIVO
      // =======================================================
      body: IndexedStack(
        index: _currentIndex, // 🔴 CHINCHE HOME 13 — tab visible
        children: _tabs,
      ),

      // =======================================================
      // 🔹 BARRA DE NAVEGACIÓN INFERIOR ÚNICA
      // =======================================================
      bottomNavigationBar: SafeArea(
        top: false,
        left: false,
        right: false,
        bottom: true,
        child: Container(
          // 🔴 CHINCHE HOME 14 — wrapper por si quieres bordes/sombra extra
          decoration: const BoxDecoration(
            color: Colors.transparent,
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _currentIndex,      // 🔴 CHINCHE HOME 15
            backgroundColor: navBackground,   // 🔴 CHINCHE HOME 16
            elevation: navElevation,          // 🔴 CHINCHE HOME 17
            selectedItemColor: selectedColor, // 🔴 CHINCHE HOME 18
            unselectedItemColor: unselectedColor, // 🔴 CHINCHE HOME 19
            selectedFontSize: selectedFontSize,
            unselectedFontSize: unselectedFontSize,
            showUnselectedLabels: true,

            // 🔴 CHINCHE HOME 20 — estilos de texto en MAYÚSCULAS
            selectedLabelStyle: const TextStyle(
              fontSize: selectedFontSize,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: unselectedFontSize,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w400,
            ),

            items: [
              BottomNavigationBarItem(
                icon: _buildNavIcon(
                  asset: 'assets/images/profile.png', // 🔴 PERFIL PNG
                  isSelected: _currentIndex == 0,
                ),
                label: 'PERFIL', // 🔴 CHINCHE HOME 21 — título en MAYÚSCULAS
              ),
              BottomNavigationBarItem(
                icon: _buildNavIcon(
                  asset: 'assets/images/citas.png', // 🔴 CITAS PNG
                  isSelected: _currentIndex == 1,
                ),
                label: 'CITAS', // 🔴 CHINCHE HOME 22
              ),
              BottomNavigationBarItem(
                icon: _buildNavIcon(
                  asset: 'assets/images/panel.png', // 🔴 PANEL PNG
                  isSelected: _currentIndex == 2,
                ),
                label: 'PANEL', // 🔴 CHINCHE HOME 23
              ),
              BottomNavigationBarItem(
                icon: _buildNavIcon(
                  asset: 'assets/images/matchy.png', // 🔴 MATCHY PNG
                  isSelected: _currentIndex == 3,
                ),
                label: 'MATCHY', // 🔴 CHINCHE HOME 24
              ),
              BottomNavigationBarItem(
                icon: _buildNavIcon(
                  asset: 'assets/images/chat.png', // 🔴 CHAT PNG
                  isSelected: _currentIndex == 4,
                ),
                label: 'CHAT', // 🔴 CHINCHE HOME 25
              ),
            ],

            // 🔴 CHINCHE HOME 26 — cambio de tab con animación del icono
            onTap: (index) {
              if (index == _currentIndex) return; // evita trabajo extra
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        ),
      ),
    );
  }

  // ===========================================================
  // 🔹 CONSTRUCCIÓN DEL ICONO (ANIMACIÓN SELECCIONADO / NO)
  // ===========================================================
  Widget _buildNavIcon({
    required String asset,
    required bool isSelected,
  }) {
    // 🔴 CHINCHE HOME 27 — tamaños del icono
    const double unselectedSize = 20;
    const double selectedSize = 24;

    if (isSelected) {
      // 🔴 CHINCHE HOME 28 — icono ACTIVO: más grande + tint morado
      return SizedBox(
        height: selectedSize,
        child: Center(
          child: ColorFiltered(
            colorFilter: const ColorFilter.mode(
              Color(0xFFE0D4FF), // mismo que selectedItemColor
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
      // 🔴 CHINCHE HOME 29 — icono INACTIVO: tamaño menor, sin tint
      return SizedBox(
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
  }
}
