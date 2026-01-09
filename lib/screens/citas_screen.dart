// 📂 lib/screens/citas_screen.dart
// ✅ CitasScreen DATA-DRIVEN con Riverpod
// ✅ 1 scroll global (MatchyPageLayout)
// ✅ 2 carruseles internos independientes (Próximas / Completadas)
// ✅ Lógica: separa próximas vs completadas (por status + fecha de respaldo)
// ✅ Colores claramente distintos para completadas
// ✅ No crashea si falta imagen (safe asset)
// ✅ Barra inferior igual a Perfil (currentIndex = 1)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proyectos_matchy/widgets/matchy_page_layout.dart';

// 🔴 CHINCHE NAV IMPORTS — mismas pantallas que PerfilScreen
import 'package:proyectos_matchy/screens/perfil_screen.dart';
import 'package:proyectos_matchy/screens/panel_screen.dart';
import 'package:proyectos_matchy/screens/matchys_screen.dart';
import 'package:proyectos_matchy/screens/chat_screen.dart';

// =====================================================================
// 🔹 MODELO LÓGICO DE CITA
// =====================================================================
enum CitaStatus { proxima, completada }

class CitaItem {
  final String id;

  // UI
  final String nombre;
  final int edad;
  final String lugar;
  final String fotoChica; // asset
  final String fotoLugar; // asset

  // Lógica
  final DateTime fechaHora;
  final CitaStatus status;

  const CitaItem({
    required this.id,
    required this.nombre,
    required this.edad,
    required this.lugar,
    required this.fotoChica,
    required this.fotoLugar,
    required this.fechaHora,
    required this.status,
  });

  String get nombreEdad => '$nombre, $edad';

  String get fechaUI {
    // 🔴 CHINCHE FECHA UI — formato simple, sin intl para no meter deps
    const meses = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    final d = fechaHora.day.toString().padLeft(2, '0');
    final m = meses[fechaHora.month - 1];
    final y = fechaHora.year;
    return '$d $m $y';
  }

  String get horaUI {
    // 12h AM/PM como el resto del proyecto
    final h = fechaHora.hour;
    final min = fechaHora.minute.toString().padLeft(2, '0');
    final ampm = h < 12 ? 'a.m.' : 'p.m.';
    final display = (h % 12 == 0) ? 12 : (h % 12);
    return '$display:$min $ampm';
  }
}

// =====================================================================
// 🔹 PROVIDER (demo lógico, pero ya data-driven)
//    Luego se conecta a storage/backend sin tocar UI.
// =====================================================================
final citasProvider = Provider<List<CitaItem>>((ref) {
  DateTime dt(int y, int m, int d, int h, int min) => DateTime(y, m, d, h, min);

  // 🔴 CHINCHE CITAS DEMO — aquí simulas tu data real
  // Regla: status manda. Si algún día llega mal, hacemos respaldo por fecha.
  final data = <CitaItem>[
    // =========================
    // PRÓXIMAS
    // =========================
    CitaItem(
      id: 'c1',
      nombre: 'Anita',
      edad: 22,
      lugar: 'El Faro Pizzería',
      fotoChica: 'assets/images/chica1.png',
      fotoLugar: 'assets/images/faro1.jpg',
      fechaHora: dt(2026, 1, 18, 19, 0),
      status: CitaStatus.proxima,
    ),
    CitaItem(
      id: 'c2',
      nombre: 'Carla',
      edad: 24,
      lugar: 'La Terraza Bar',
      fotoChica: 'assets/images/chica2.png',
      fotoLugar: 'assets/images/bar1.jpg',
      fechaHora: dt(2026, 1, 20, 20, 30),
      status: CitaStatus.proxima,
    ),
    CitaItem(
      id: 'c3',
      nombre: 'María',
      edad: 25,
      lugar: 'Café Aurora',
      fotoChica: 'assets/images/chica3.png',
      fotoLugar: 'assets/images/cafe1.jpg',
      fechaHora: dt(2026, 1, 22, 17, 0),
      status: CitaStatus.proxima,
    ),
    CitaItem(
      id: 'c4',
      nombre: 'Valentina',
      edad: 27,
      lugar: 'Sushi Neko',
      fotoChica: 'assets/images/chica4.png',
      fotoLugar: 'assets/images/restaurante1.jpg',
      fechaHora: dt(2026, 1, 24, 21, 0),
      status: CitaStatus.proxima,
    ),
    CitaItem(
      id: 'c5',
      nombre: 'Laura',
      edad: 29,
      lugar: 'Bodega 66',
      fotoChica: 'assets/images/chica5.png',
      fotoLugar: 'assets/images/bar2.jpg',
      fechaHora: dt(2026, 1, 26, 20, 0),
      status: CitaStatus.proxima,
    ),
    CitaItem(
      id: 'c6',
      nombre: 'Mafe',
      edad: 26,
      lugar: 'Central Café',
      fotoChica: 'assets/images/chica6.png',
      fotoLugar: 'assets/images/cafe2.jpg',
      fechaHora: dt(2026, 1, 30, 18, 30),
      status: CitaStatus.proxima,
    ),

    // =========================
    // COMPLETADAS
    // =========================
    CitaItem(
      id: 'c7',
      nombre: 'Julia',
      edad: 28,
      lugar: 'El Faro Pizzería',
      fotoChica: 'assets/images/chica3.png',
      fotoLugar: 'assets/images/faro2.jpg',
      fechaHora: dt(2025, 10, 2, 19, 30),
      status: CitaStatus.completada,
    ),
    CitaItem(
      id: 'c8',
      nombre: 'Lucía',
      edad: 30,
      lugar: 'La Terraza Bar',
      fotoChica: 'assets/images/chica4.png',
      fotoLugar: 'assets/images/bar1.jpg',
      fechaHora: dt(2025, 9, 28, 21, 0),
      status: CitaStatus.completada,
    ),
    CitaItem(
      id: 'c9',
      nombre: 'Diana',
      edad: 25,
      lugar: 'Trattoria Roma',
      fotoChica: 'assets/images/chica5.png',
      fotoLugar: 'assets/images/restaurante2.jpg',
      fechaHora: dt(2025, 9, 20, 20, 15),
      status: CitaStatus.completada,
    ),
    CitaItem(
      id: 'c10',
      nombre: 'Sara',
      edad: 27,
      lugar: 'Café Aurora',
      fotoChica: 'assets/images/chica6.png',
      fotoLugar: 'assets/images/cafe1.jpg',
      fechaHora: dt(2025, 9, 15, 18, 0),
      status: CitaStatus.completada,
    ),
    CitaItem(
      id: 'c11',
      nombre: 'Paula',
      edad: 29,
      lugar: 'Bodega 66',
      fotoChica: 'assets/images/chica7.png',
      fotoLugar: 'assets/images/bar2.jpg',
      fechaHora: dt(2025, 9, 8, 21, 45),
      status: CitaStatus.completada,
    ),
    CitaItem(
      id: 'c12',
      nombre: 'Nati',
      edad: 24,
      lugar: 'Central Café',
      fotoChica: 'assets/images/chica8.png',
      fotoLugar: 'assets/images/cafe2.jpg',
      fechaHora: dt(2025, 9, 1, 17, 30),
      status: CitaStatus.completada,
    ),
  ];

  return data;
});

// =====================================================================
// 🔹 PANTALLA PRINCIPAL
// =====================================================================
class CitasScreen extends StatelessWidget {
  static const String routeName = 'citas';

  const CitasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: MatchyPageLayout(
        backgroundAsset: 'assets/images/fondo.jpg',
        logoAsset: 'assets/images/logomatchyplano.png',
        scrollContent: _CitasContent(textTheme: textTheme),

        // Distancias de logo (iguales a Panel/Perfil)
        topSpacing: 35,        // 🔴 CHINCHE LOGO 1
        logoHeight: 50,        // 🔴 CHINCHE LOGO 2
        logoOffsetY: 0,        // 🔴 CHINCHE LOGO 3
        spaceLogoToScroll: 15, // 🔴 CHINCHE LOGO 4
      ),

      // 🔴 CHINCHE NAV BAR — currentIndex = 1
      bottomNavigationBar: const _MatchyBottomNav(currentIndex: 1),
    );
  }
}

// =====================================================================
// 🔹 CONTENIDO PRINCIPAL (CONSUMER) — separa próximas vs completadas
// =====================================================================
class _CitasContent extends ConsumerWidget {
  final TextTheme textTheme;

  const _CitasContent({required this.textTheme});

  // 🔴 CHINCHE CITAS B — altura visible de cada carrusel interno
  static const double _alturaCarrusel = 330;

  // 🔴 CHINCHE CITAS C — espacio entre título y tarjetas
  static const double _espacioTituloTarjetas = 6;

  // 🔴 CHINCHE CITAS D — espacio vertical entre secciones
  static const double _espacioEntreSecciones = 18;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(citasProvider);
    final now = DateTime.now();

    // ===========================================================
    // 🔥 REGLA DE ORO (LÓGICA)
    // 1) status manda (proxima/completada)
    // 2) respaldo por fecha por si algún día status llega raro:
    //    - proxima si fechaHora >= ahora
    //    - completada si fechaHora < ahora
    // ===========================================================
    final proximas = all
        .where((c) =>
    c.status == CitaStatus.proxima ||
        (c.status != CitaStatus.completada && !c.fechaHora.isBefore(now)))
        .toList()
      ..sort((a, b) => a.fechaHora.compareTo(b.fechaHora)); // próximas: asc

    final completadas = all
        .where((c) =>
    c.status == CitaStatus.completada ||
        (c.status != CitaStatus.proxima && c.fechaHora.isBefore(now)))
        .toList()
      ..sort((a, b) => b.fechaHora.compareTo(a.fechaHora)); // completadas: desc

    return Column(
      children: [
        // ============================
        // SECCIÓN PRÓXIMAS CITAS
        // ============================
        Text(
          'PRÓXIMAS CITAS',
          style: textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: _espacioTituloTarjetas),

        SizedBox(
          height: _alturaCarrusel,
          child: ListView.builder(
            padding: EdgeInsets.zero,
            physics: const BouncingScrollPhysics(), // 🔴 CHINCHE SCROLL 1
            itemCount: proximas.length,
            itemBuilder: (context, index) {
              return _CitaCard(
                cita: proximas[index],
                textTheme: textTheme,
                isCompleted: false,
              );
            },
          ),
        ),

        const SizedBox(height: _espacioEntreSecciones),

        // ============================
        // SECCIÓN CITAS COMPLETADAS
        // ============================
        Text(
          'CITAS COMPLETADAS',
          style: textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: _espacioTituloTarjetas),

        SizedBox(
          height: _alturaCarrusel,
          child: ListView.builder(
            padding: EdgeInsets.zero,
            physics: const BouncingScrollPhysics(), // 🔴 CHINCHE SCROLL 2
            itemCount: completadas.length,
            itemBuilder: (context, index) {
              return _CitaCard(
                cita: completadas[index],
                textTheme: textTheme,
                isCompleted: true,
              );
            },
          ),
        ),

        const SizedBox(
          height: 30, // 🔴 CHINCHE CITAS E — aire final
        ),
      ],
    );
  }
}

// =====================================================================
// 🔹 TARJETA DE CITA (mismo diseño + colores distintos)
// =====================================================================
class _CitaCard extends StatelessWidget {
  final CitaItem cita;
  final TextTheme textTheme;
  final bool isCompleted;

  const _CitaCard({
    required this.cita,
    required this.textTheme,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    // 🔴 CHINCHE COLOR 1 — próximas
    const Color colorProximas = Color(0x996A5ACD);

    // 🔴 CHINCHE COLOR 2 — completadas
    const Color colorCompletadas = Color(0xCC3F2B63);

    final Color cardColor = isCompleted ? colorCompletadas : colorProximas;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Card(
        color: cardColor,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: SizedBox(
          height: 115,
          child: Row(
            children: [
              // ---------------- FOTO CHICA ----------------
              Padding(
                padding: const EdgeInsets.all(10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: _SafeAssetImage(
                    asset: cita.fotoChica,
                    width: 92,
                    height: 92,
                    fit: BoxFit.cover,
                    fallback: 'assets/images/perfil1.jpg', // 🔴 CHINCHE FALLBACK 1
                  ),
                ),
              ),

              // ---------------- INFORMACIÓN ----------------
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cita.nombreEdad,
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '📍 ${cita.lugar}',
                      style: _infoStyle(textTheme),
                    ),
                    Text(
                      '📅 ${cita.fechaUI}',
                      style: _infoStyle(textTheme),
                    ),
                    Text(
                      '🕒 ${cita.horaUI}',
                      style: _infoStyle(textTheme),
                    ),
                  ],
                ),
              ),

              // ---------------- FOTO LUGAR ----------------
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                child: _SafeAssetImage(
                  asset: cita.fotoLugar,
                  width: 115,
                  height: 92,
                  fit: BoxFit.cover,
                  fallback: 'assets/images/faro1.jpg', // 🔴 CHINCHE FALLBACK 2
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle _infoStyle(TextTheme t) {
    return t.bodySmall!.copyWith(
      color: Colors.white,
      fontSize: 12,
    );
  }
}

// =====================================================================
// ✅ Imagen asset segura (no crashea si falta)
// =====================================================================
class _SafeAssetImage extends StatelessWidget {
  final String asset;
  final double width;
  final double height;
  final BoxFit fit;
  final String fallback;

  const _SafeAssetImage({
    required this.asset,
    required this.width,
    required this.height,
    required this.fit,
    required this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => Image.asset(
        fallback,
        width: width,
        height: height,
        fit: fit,
      ),
    );
  }
}

// =====================================================================
// 🔹 BARRA DE NAVEGACIÓN INFERIOR — IGUAL A PERFIL
// =====================================================================
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
