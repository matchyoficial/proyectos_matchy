// 📂 lib/screens/cita_nueva_screen.dart
// ✅ Pantalla "CITA NUEVA" (basada en CrearCitaPanelScreen) + HEADER NUEVO
// ✅ FIX: Foto de perfil SIEMPRE desde Riverpod (Foto #1 del usuario)
// - Foto usuario (izquierda) + Foto match (derecha)
// - "HOLA {USUARIO} Y {MATCH}"
// - "¿A DÓNDE QUIEREN IR?"
// - Grid 2x2 + Lugares populares completos

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 🔴 CHINCHE CITA RIVERPOD 1

// ✅ Provider perfil (REAL)
import 'package:proyectos_matchy/state/profile_form_provider.dart'; // 🔴 CHINCHE CITA RIVERPOD 2

// 🔴 CHINCHE CITA A — pantallas destino
import 'package:proyectos_matchy/screens/restaurantes_screen.dart';
import 'package:proyectos_matchy/screens/bares_screen.dart';
import 'package:proyectos_matchy/screens/cafes_screen.dart';
import 'package:proyectos_matchy/screens/actividades_screen.dart';

// 🔴 CHINCHE CITA BACK — botón global de regreso
import 'package:proyectos_matchy/widgets/matchy_back_button.dart';

class CitaNuevaScreen extends ConsumerWidget {
  static const String routeName = 'cita_nueva';

  // ✅ NOMBRES DE PARÁMETROS (IMPORTANTE)
  // OJO: nombreUsuario/fotoUsuario quedan como FALLBACK para no romper llamadas viejas.
  final String nombreUsuario;
  final String nombreMatch;

  // Puede ser asset / file path / url
  final String fotoUsuario; // 🔴 CHINCHE CITA FIX 0 — ahora es fallback
  final String fotoMatch;

  const CitaNuevaScreen({
    super.key,
    required this.nombreUsuario,
    required this.nombreMatch,
    required this.fotoUsuario,
    required this.fotoMatch,
  });

  // 🔴 CHINCHE CITA NAME SAFE 1 — normaliza nombre como ya haces en Panel
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    // 🔴 CHINCHE CITA LAYOUT
    const double espacioBarraLogo = 35; // 🔴 35
    const double alturaLogo = 50; // 🔴 50
    const double espacioLogoScroll = 15; // 🔴 15
    const double margenInferiorPantalla = 80; // 🔴 80

    // =========================================================
    // ✅ FOTO PERFIL REAL (Riverpod) = Foto #1
    // =========================================================
    final profile = ref.watch(profileFormProvider);

    // 🔴 CHINCHE CITA FIX 1 — foto del usuario SIEMPRE desde provider si existe
    final String? fotoUsuarioProvider = profile.fotosCargadas.isNotEmpty
        ? profile.fotosCargadas.first
        : null;

    // 🔴 CHINCHE CITA FIX 2 — fallbacks robustos (provider > param > default asset)
    final String fotoUsuarioFinal = (fotoUsuarioProvider != null && fotoUsuarioProvider.trim().isNotEmpty)
        ? fotoUsuarioProvider
        : (fotoUsuario.trim().isNotEmpty ? fotoUsuario : 'assets/images/perfil1.jpg');

    // 🔴 CHINCHE CITA FIX 3 — nombre del usuario preferido desde provider (si ya lo tienes)
    final String nombreUsuarioFinal = profile.nombre.trim().isNotEmpty
        ? _nombreSeguro(profile.nombre)
        : _nombreSeguro(nombreUsuario);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/fondo.jpg',
              fit: BoxFit.cover,
            ),
          ),
          const MatchyBackButton(
            top: 10, // 🔴 10
            left: 16, // 🔴 16
          ),
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
                  padding: const EdgeInsets.only(bottom: margenInferiorPantalla),
                  child: _CitaNuevaContent(
                    textTheme: textTheme,
                    nombreUsuario: nombreUsuarioFinal,
                    nombreMatch: nombreMatch,
                    fotoUsuario: fotoUsuarioFinal,
                    fotoMatch: fotoMatch,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ===============================================================
// 🔹 MODELO: Lugar popular
// ===============================================================
class _LugarPopular {
  final String nombre;
  final String direccion;
  final String imageAsset;

  // 🔴 CHINCHE CITA POP 1 — categoría MVP
  final String categoria; // 'restaurante' | 'bar' | 'cafe' | 'actividad'
  final bool clickable;

  const _LugarPopular({
    required this.nombre,
    required this.direccion,
    required this.imageAsset,
    required this.categoria,
    required this.clickable,
  });
}

// ===============================================================
// 🔹 CONTENIDO PRINCIPAL
// ===============================================================
class _CitaNuevaContent extends StatelessWidget {
  final TextTheme textTheme;
  final String nombreUsuario;
  final String nombreMatch;
  final String fotoUsuario;
  final String fotoMatch;

  const _CitaNuevaContent({
    required this.textTheme,
    required this.nombreUsuario,
    required this.nombreMatch,
    required this.fotoUsuario,
    required this.fotoMatch,
  });

  @override
  Widget build(BuildContext context) {
    // 🔴 CHINCHE CITA GRID
    const double alturaCategoria = 112; // 🔴 112
    const double radioCategoria = 12; // 🔴 12
    const double alturaLugarPopular = 150; // 🔴 150

    // 🔴 CHINCHE CITA POP LIST — lugares populares (los mismos que tú diste)
    const List<_LugarPopular> lugaresPopulares = [
      _LugarPopular(
        nombre: 'EL FARO PIZZERIA',
        direccion: 'Carrera 66 #5-152',
        imageAsset: 'assets/images/faro1.jpg',
        categoria: 'restaurante',
        clickable: true,
      ),
      _LugarPopular(
        nombre: 'BAR LA NOCHE',
        direccion: 'Calle 5 #10-23',
        imageAsset: 'assets/images/barlanoche.jpg',
        categoria: 'bar',
        clickable: true,
      ),
      _LugarPopular(
        nombre: 'CAFÉ CENTRAL',
        direccion: 'Av. 4N #12-50',
        imageAsset: 'assets/images/cafe1.jpg',
        categoria: 'cafe',
        clickable: true,
      ),
      _LugarPopular(
        nombre: 'RESTAURANTE ANDES',
        direccion: 'Cra 34 #7-89',
        imageAsset: 'assets/images/restaurante1.jpg',
        categoria: 'restaurante',
        clickable: true,
      ),
      _LugarPopular(
        nombre: 'BODEGA 66',
        direccion: 'Calle 9 #66-10',
        imageAsset: 'assets/images/bar1.jpg',
        categoria: 'bar',
        clickable: true,
      ),
      _LugarPopular(
        nombre: 'CAFÉ AMOR',
        direccion: 'Calle 10 #15-60',
        imageAsset: 'assets/images/cafe2.jpg',
        categoria: 'cafe',
        clickable: true,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // =========================================================
        // 🔥 HEADER NUEVO
        // =========================================================
        _CitaHeaderMatch(
          textTheme: textTheme,
          nombreUsuario: nombreUsuario,
          nombreMatch: nombreMatch,
          fotoUsuario: fotoUsuario,
          fotoMatch: fotoMatch,
        ),

        const SizedBox(height: 16), // 🔴 CHINCHE CITA HEADER SPACE 16

        // =========================================================
        // GRID 2x2
        // =========================================================
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20), // 🔴 20
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _CategoriaCard(
                      titulo: 'RESTAURANTES',
                      imageAsset: 'assets/images/iconorestaurante.png',
                      altura: alturaCategoria,
                      radio: radioCategoria,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RestaurantesScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12), // 🔴 12
                  Expanded(
                    child: _CategoriaCard(
                      titulo: 'BARES',
                      imageAsset: 'assets/images/iconobares.png',
                      altura: alturaCategoria,
                      radio: radioCategoria,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const BaresScreen()),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14), // 🔴 14
              Row(
                children: [
                  Expanded(
                    child: _CategoriaCard(
                      titulo: 'CAFÉS',
                      imageAsset: 'assets/images/iconocafeteria.png',
                      altura: alturaCategoria,
                      radio: radioCategoria,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CafesScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CategoriaCard(
                      titulo: 'ACTIVIDADES',
                      imageAsset: 'assets/images/iconoactividades.png',
                      altura: alturaCategoria,
                      radio: radioCategoria,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ActividadesScreen()),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 22),

        // =========================================================
        // LUGARES POPULARES
        // =========================================================
        Text(
          'LUGARES MÁS POPULARES',
          style: textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.none,
          ),
        ),
        const SizedBox(height: 8),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              for (int i = 0; i < lugaresPopulares.length; i++) ...[
                _LugarPopularCard(
                  lugar: lugaresPopulares[i],
                  textTheme: textTheme,
                  altura: alturaLugarPopular,
                  onTap: () {
                    final cat = lugaresPopulares[i].categoria;

                    if (cat == 'restaurante') {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RestaurantesScreen()));
                      return;
                    }
                    if (cat == 'bar') {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BaresScreen()));
                      return;
                    }
                    if (cat == 'cafe') {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CafesScreen()));
                      return;
                    }
                    if (cat == 'actividad') {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ActividadesScreen()));
                      return;
                    }
                  },
                ),
                if (i != lugaresPopulares.length - 1) const SizedBox(height: 16),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }
}

// ===============================================================
// 🔥 HEADER: fotos + nombres + frase
// ===============================================================
class _CitaHeaderMatch extends StatelessWidget {
  final TextTheme textTheme;
  final String nombreUsuario;
  final String nombreMatch;
  final String fotoUsuario;
  final String fotoMatch;

  const _CitaHeaderMatch({
    required this.textTheme,
    required this.nombreUsuario,
    required this.nombreMatch,
    required this.fotoUsuario,
    required this.fotoMatch,
  });

  @override
  Widget build(BuildContext context) {
    // 🔴 CHINCHE HEADER MEDIDAS
    const double fotoSize = 58; // 🔴 58
    const double radioFoto = 12; // 🔴 12
    const double espacioFotos = 10; // 🔴 10
    const double espacioTexto = 10; // 🔴 10
    const double paddingHorizontal = 16; // 🔴 16

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: paddingHorizontal),
      child: Row(
        children: [
          _SafeProfileImage(
            path: fotoUsuario,
            size: fotoSize,
            radius: radioFoto,
            // 🔴 CHINCHE CITA FALLBACK IMG 1
            fallbackAsset: 'assets/images/perfil1.jpg',
          ),
          const SizedBox(width: espacioFotos),

          Expanded(
            child: Column(
              children: [
                Text(
                  'HOLA ${nombreUsuario.toUpperCase()} Y ${nombreMatch.toUpperCase()}',
                  style: textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontSize: 20, // 🔴 20
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.none,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: espacioTexto),
                Text(
                  '¿A DÓNDE QUIEREN IR?',
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                    fontSize: 13, // 🔴 13
                    decoration: TextDecoration.none,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(width: espacioFotos),
          _SafeProfileImage(
            path: fotoMatch,
            size: fotoSize,
            radius: radioFoto,
            // 🔴 CHINCHE CITA FALLBACK IMG 2
            fallbackAsset: 'assets/images/perfil2.jpg',
          ),
        ],
      ),
    );
  }
}

// ===============================================================
// ✅ Imagen segura: no crashea si falta asset o falla url/file
// ===============================================================
class _SafeProfileImage extends StatelessWidget {
  final String path;
  final double size;
  final double radius;
  final String fallbackAsset;

  const _SafeProfileImage({
    required this.path,
    required this.size,
    required this.radius,
    required this.fallbackAsset,
  });

  bool _isNetwork(String v) => v.startsWith('http://') || v.startsWith('https://');
  bool _isAsset(String v) => v.startsWith('assets/');
  bool _isFilePath(String v) => v.startsWith('/') || v.contains(r':\');

  @override
  Widget build(BuildContext context) {
    Widget img;

    final p = path.trim();

    if (p.isEmpty) {
      img = Image.asset(fallbackAsset, width: size, height: size, fit: BoxFit.cover);
    } else if (_isNetwork(p)) {
      img = Image.network(
        p,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset(
          fallbackAsset,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    } else if (_isFilePath(p) && !_isAsset(p)) {
      img = Image.file(
        File(p),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset(
          fallbackAsset,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    } else {
      img = Image.asset(
        p,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset(
          fallbackAsset,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: img,
    );
  }
}

// ===============================================================
// 🔹 TARJETA CATEGORÍA
// ===============================================================
class _CategoriaCard extends StatelessWidget {
  final String titulo;
  final String imageAsset;
  final double altura;
  final double radio;
  final VoidCallback onTap;

  const _CategoriaCard({
    required this.titulo,
    required this.imageAsset,
    required this.altura,
    required this.radio,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: altura,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radio),
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
          const SizedBox(height: 8),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}

// ===============================================================
// 🔹 TARJETA LUGAR POPULAR
// ===============================================================
class _LugarPopularCard extends StatelessWidget {
  final _LugarPopular lugar;
  final TextTheme textTheme;
  final double altura;
  final VoidCallback onTap;

  const _LugarPopularCard({
    required this.lugar,
    required this.textTheme,
    required this.altura,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool clickable = lugar.clickable;

    return GestureDetector(
      onTap: clickable ? onTap : null,
      child: Container(
        height: altura,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.45),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
          image: DecorationImage(
            image: AssetImage(lugar.imageAsset),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.75),
              ],
            ),
          ),
          padding: const EdgeInsets.all(10),
          alignment: Alignment.bottomLeft,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lugar.nombre,
                style: textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                lugar.direccion,
                style: textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontSize: 13,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
