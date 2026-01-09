// 📂 lib/screens/perfil_screen.dart
// ✅ PERFIL conectado a ProfileFormProvider (DatosScreen)
// ✅ FIX: carga el draft automáticamente al entrar a Perfil
// ✅ Mantiene diseño EXACTO: chips centrados, filas inteligentes, overlays, etc.
// ✅ NUEVO:
//    - Nombre y edad SIEMPRE en una misma fila
//    - Si el nombre es muy largo → usa 2 palabras cuando el primer nombre es corto (ej: “María José”)
//      si aún queda largo → usa solo primer nombre

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proyectos_matchy/widgets/matchy_page_layout.dart';

// 🔴 CHINCHE PERFIL 0 — imports para la barra de navegación inferior
import 'package:proyectos_matchy/screens/panel_screen.dart';
import 'package:proyectos_matchy/screens/citas_screen.dart';
import 'package:proyectos_matchy/screens/matchys_screen.dart';
import 'package:proyectos_matchy/screens/chat_screen.dart';

// ✅ Provider del perfil (la fuente de verdad)
import 'package:proyectos_matchy/state/profile_form_provider.dart';

class PerfilScreen extends ConsumerStatefulWidget {
  static const String routeName = 'perfil'; // 🔴 CHINCHE A — nombre de ruta

  // 🔴 CHINCHE NAV FLAG — ¿muestro barra propia o no?
  final bool showBottomNav;

  const PerfilScreen({
    super.key,
    this.showBottomNav = true, // por defecto SÍ muestra barra
  });

  @override
  ConsumerState<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends ConsumerState<PerfilScreen> {
  bool _draftLoaded = false; // 🔴 CHINCHE PERFIL LOAD 1 — evita cargar 2 veces

  @override
  void initState() {
    super.initState();

    // ✅ Cargar draft guardado apenas entra a Perfil
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_draftLoaded) return;
      _draftLoaded = true;

      await ref.read(profileFormProvider.notifier).loadDraft();
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // ✅ Leemos estado real del formulario
    final state = ref.watch(profileFormProvider);

    return Scaffold(
      body: MatchyPageLayout(
        backgroundAsset: 'assets/images/fondo.jpg',
        logoAsset: 'assets/images/logomatchyplano.png',
        scrollContent: _PerfilContent(
          textTheme: textTheme,
          state: state,
        ),
        topSpacing: 35, // 🔴 CHINCHE E
        logoHeight: 50, // 🔴 CHINCHE F
        logoOffsetY: 0, // 🔴 CHINCHE G
        spaceLogoToScroll: 15, // 🔴 CHINCHE H
      ),
      bottomNavigationBar:
      widget.showBottomNav ? const _MatchyBottomNav(currentIndex: 0) : null,
    );
  }
}

class _PerfilContent extends StatelessWidget {
  final TextTheme textTheme;
  final ProfileFormState state;

  const _PerfilContent({
    required this.textTheme,
    required this.state,
  });

  // 🔴 CHINCHE PERFIL NAME 1 — recorte inteligente:
  // - si nombre “largo” → 2 palabras cuando la primera es corta (ej: “María José”)
  // - si aún queda largo → solo primer nombre
  String _nombrePanelSeguro(String raw) {
    final clean = raw.trim();
    if (clean.isEmpty) return 'Sin nombre';

    final parts =
    clean.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'Sin nombre';

    final first = parts.first;
    final twoWords = parts.length >= 2 ? '${parts[0]} ${parts[1]}' : first;

    // 🔴 CHINCHE PERFIL NAME 2 — umbrales (ajustables)
    const int largoTotal = 12; // si supera esto, consideramos “largo”
    const int firstShort = 5; // “María”(5) → permite 2 palabras

    // si NO es largo, lo dejamos tal cual
    if (clean.length <= largoTotal && parts.length <= 2) return clean;

    // si es largo:
    // - si el primer nombre es corto → intentamos 2 palabras
    if (first.length <= firstShort && parts.length >= 2) {
      // si aún queda larguísimo, cae a 1 palabra
      if (twoWords.length > 12) return first;
      return twoWords;
    }

    // fallback: solo primer nombre
    return first;
  }

  @override
  Widget build(BuildContext context) {
    final nombre = _nombrePanelSeguro(state.nombre);
    final edad = state.edad.trim().isEmpty ? '—' : state.edad.trim();

    final pais = (state.paisSeleccionado ?? '').trim();
    final ciudad = (state.ciudadSeleccionada ?? '').trim();

    final ciudadPais = (ciudad.isEmpty && pais.isEmpty)
        ? 'Sin ubicación'
        : (ciudad.isNotEmpty && pais.isNotEmpty)
        ? '$ciudad - $pais'
        : (ciudad.isNotEmpty ? ciudad : pais);

    final profesion =
    state.profesion.trim().isEmpty ? '—' : state.profesion.trim();

    final biografia = state.biografia.trim().isEmpty
        ? 'Aún no has escrito tu biografía.'
        : state.biografia.trim();

    final detalle = state.detalle.trim().isEmpty
        ? 'Aún no has agregado este detalle.'
        : state.detalle.trim();

    final fotos = List<String>.from(state.fotosCargadas);
    final bool tieneFotos = fotos.isNotEmpty;

    // ✅ Estatura: se muestra tal cual (ej: “1.80 m”)
    final List<String> sobreMi = [
      if (state.estatura.trim().isNotEmpty) '📏 ${state.estatura.trim()}',
      ...state.sobreMiSeleccion,
    ];

    final List<String> busco = List<String>.from(state.buscoSeleccion);
    final List<String> intereses = List<String>.from(state.interesesSeleccion);

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 0),

          _FotoTarjeta(
            imageAsset: tieneFotos ? fotos[0] : null,
            height: 450, // 🔴 CHINCHE J
            overlay: (context) {
              return Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      height: 180, // 🔴 CHINCHE K
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.95),
                          ],
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    left: 30, // 🔴 CHINCHE L
                    bottom: 30, // 🔴 CHINCHE M
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ✅ Nombre + edad SIEMPRE en misma fila
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              nombre,
                              style: textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontSize: 28, // 🔴 CHINCHE N
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              ', $edad',
                              style: textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontSize: 28, // 🔴 CHINCHE N
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profesion,
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontSize: 16, // 🔴 CHINCHE O
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ciudadPais,
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontSize: 14, // 🔴 CHINCHE P
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (!tieneFotos)
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.50),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            'Agrega al menos 1 foto en “Datos”',
                            style: textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),

          const SizedBox(height: 16),

          _CardTexto(
            titulo: 'Biografía',
            texto: biografia,
            textTheme: textTheme,
          ),

          if (sobreMi.isNotEmpty)
            _CardChips(
              titulo: 'Sobre mí',
              items: sobreMi,
              textTheme: textTheme,
            ),

          if (fotos.length >= 2)
            _FotoTarjeta(
              imageAsset: fotos[1],
              height: 400, // 🔴 CHINCHE Q
            ),

          if (busco.isNotEmpty)
            _CardChips(
              titulo: 'Busco...',
              items: busco,
              textTheme: textTheme,
            ),

          if (fotos.length >= 3)
            _FotoTarjeta(
              imageAsset: fotos[2],
              height: 400, // 🔴 CHINCHE R
            ),

          if (intereses.isNotEmpty)
            _CardChips(
              titulo: 'Intereses y Hobbies',
              items: intereses,
              textTheme: textTheme,
            ),

          if (fotos.length >= 4)
            _FotoTarjeta(
              imageAsset: fotos[3],
              height: 400,
            ),

          _CardTexto(
            titulo: 'Un detalle que me enamora',
            texto: detalle,
            textTheme: textTheme,
          ),

          if (fotos.length >= 5)
            _FotoTarjeta(
              imageAsset: fotos[4],
              height: 400,
            ),

          const SizedBox(height: 40), // 🔴 CHINCHE S
        ],
      ),
    );
  }
}

// ================================================================
// 🔹 COMPONENTES REUTILIZABLES
// ================================================================

class _FotoTarjeta extends StatelessWidget {
  final String? imageAsset;
  final double height;
  final Widget Function(BuildContext context)? overlay;

  const _FotoTarjeta({
    required this.imageAsset,
    required this.height,
    this.overlay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 16, // 🔴 CHINCHE T
      ),
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          25, // 🔴 CHINCHE U
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageAsset != null)
            Image.asset(
              imageAsset!,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            )
          else
            Container(
              color: const Color(0x33FFFFFF),
              child: const Center(
                child: Icon(
                  Icons.person,
                  color: Colors.white70,
                  size: 70,
                ),
              ),
            ),
          if (overlay != null) overlay!(context),
        ],
      ),
    );
  }
}

class _CardTexto extends StatelessWidget {
  final String titulo;
  final String texto;
  final TextTheme textTheme;

  const _CardTexto({
    required this.titulo,
    required this.texto,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 20, // 🔴 CHINCHE V
        vertical: 10, // 🔴 CHINCHE W
      ),
      padding: const EdgeInsets.all(
        16, // 🔴 CHINCHE X
      ),
      decoration: BoxDecoration(
        color: const Color(0x33FFFFFF),
        borderRadius: BorderRadius.circular(
          20, // 🔴 CHINCHE Y
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: textTheme.titleSmall?.copyWith(
              color: const Color(0xFFB3D9FF),
              fontSize: 18, // 🔴 CHINCHE Z
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            texto,
            style: textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontSize: 14, // 🔴 CHINCHE AA
            ),
          ),
        ],
      ),
    );
  }
}

class _CardChips extends StatelessWidget {
  final String titulo;
  final List<String> items;
  final TextTheme textTheme;

  const _CardChips({
    required this.titulo,
    required this.items,
    required this.textTheme,
  });

  List<List<String>> _buildRows(List<String> all) {
    const int maxShortLength = 14; // 🔴 CHINCHE AB
    final rows = <List<String>>[];
    int i = 0;

    while (i < all.length) {
      final current = all[i];
      final isCurrentLong = current.length > maxShortLength;

      if (isCurrentLong) {
        rows.add([current]);
        i += 1;
      } else if (i + 1 < all.length) {
        final next = all[i + 1];
        final isNextLong = next.length > maxShortLength;

        if (isNextLong) {
          rows.add([current]);
          i += 1;
        } else {
          rows.add([current, next]);
          i += 2;
        }
      } else {
        rows.add([current]);
        i += 1;
      }
    }
    return rows;
  }

  Widget _buildChip(String text) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4), // 🔴 CHINCHE AC
      padding: const EdgeInsets.symmetric(
        vertical: 10, // 🔴 CHINCHE AD
        horizontal: 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0x66FFFFFF),
        borderRadius: BorderRadius.circular(50), // 🔴 CHINCHE AE
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              softWrap: false, // 🔴 CHINCHE AF
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontSize: 13, // 🔴 CHINCHE AG
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = _buildRows(items);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 20, // 🔴 CHINCHE AH
        vertical: 10, // 🔴 CHINCHE AI
      ),
      padding: const EdgeInsets.all(16), // 🔴 CHINCHE AJ
      decoration: BoxDecoration(
        color: const Color(0x33FFFFFF),
        borderRadius: BorderRadius.circular(20), // 🔴 CHINCHE AK
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: textTheme.titleSmall?.copyWith(
              color: const Color(0xFFB3D9FF),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Column(
            children: rows.map((fila) {
              if (fila.length == 1) {
                return Row(children: [Expanded(child: _buildChip(fila[0]))]);
              } else {
                return Row(
                  children: [
                    Expanded(child: _buildChip(fila[0])),
                    const SizedBox(width: 10), // 🔴 CHINCHE AL
                    Expanded(child: _buildChip(fila[1])),
                  ],
                );
              }
            }).toList(),
          ),
        ],
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
