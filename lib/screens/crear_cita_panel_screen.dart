// 📂 lib/screens/crear_cita_panel_screen.dart
// ✅ Pantalla "CREAR UNA CITA" con:
//    - Fondo y logo Matchy
//    - Grid 2x2 (Restaurantes / Bares / Cafés / Actividades)
//    - Lista de lugares populares
//    - Botón global de regreso (pantalla secundaria)

import 'package:flutter/material.dart';

// 🔴 CHINCHE CREA A — imports de las 4 pantallas destino
import 'package:proyectos_matchy/screens/restaurantes_screen.dart';
import 'package:proyectos_matchy/screens/bares_screen.dart';
import 'package:proyectos_matchy/screens/cafes_screen.dart';
import 'package:proyectos_matchy/screens/actividades_screen.dart';

// 🔴 CHINCHE CREA BACK 0 — botón global de regreso para pantallas secundarias
import 'package:proyectos_matchy/widgets/matchy_back_button.dart';

class CrearCitaPanelScreen extends StatelessWidget {
  // 🔴 CHINCHE CREA C — nombre de ruta
  static const String routeName = 'crear_cita_panel';

  // 🔴 CHINCHE CREA D — nombre dinámico del usuario (NO hardcode)
  // Valor recomendado: pásalo desde Panel (ej: nombre seguro ya calculado).
  final String nombreUsuario;

  const CrearCitaPanelScreen({
    super.key,
    this.nombreUsuario = 'AMIGO', // 🔴 CHINCHE CREA D1 — fallback si no llega nada
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // mismos parámetros que usamos en las demás pantallas
    const double espacioBarraLogo = 35; // 🔴 CHINCHE CREA LAYOUT 1
    const double alturaLogo = 50; // 🔴 CHINCHE CREA LAYOUT 2
    const double espacioLogoScroll = 15; // 🔴 CHINCHE CREA LAYOUT 3
    const double margenInferiorPantalla = 80; // 🔴 CHINCHE CREA LAYOUT 4 — respiro final scroll

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

          // 🔹 BOTÓN GLOBAL DE REGRESO (esta pantalla es secundaria)
          const MatchyBackButton(
            top: 10, // 🔴 CHINCHE CREA BACK A — sube/baja el botón
            left: 16, // 🔴 CHINCHE CREA BACK B — mueve horizontal
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
                  child: _CrearCitaContent(
                    textTheme: textTheme,
                    nombreUsuario: nombreUsuario, // 🔴 CHINCHE CREA D2 — inyección del nombre
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
// 🔹 MODELO: Lugar popular (equivalente a data class Lugar)
// ===============================================================
class _LugarPopular {
  final String nombre;
  final String direccion;
  final String imageAsset;

  // 🔴 CHINCHE CREA POP 1 — categoría del lugar popular
  // Valor: usa 4 strings simples para MVP.
  final String categoria; // 'restaurante' | 'bar' | 'cafe' | 'actividad'

  final bool clickable;

  const _LugarPopular({
    required this.nombre,
    required this.direccion,
    required this.imageAsset,
    required this.categoria, // 🔴 CHINCHE CREA POP 1A
    required this.clickable,
  });
}

// ===============================================================
// 🔹 CONTENIDO PRINCIPAL DE LA PANTALLA
// ===============================================================
class _CrearCitaContent extends StatelessWidget {
  final TextTheme textTheme;

  // 🔴 CHINCHE CREA D3 — nombre recibido desde arriba
  final String nombreUsuario;

  const _CrearCitaContent({
    required this.textTheme,
    required this.nombreUsuario,
  });

  @override
  Widget build(BuildContext context) {
    // 🔴 CHINCHE CREA E — alto del grid de categorías
    const double alturaCategoria = 112;

    // 🔴 CHINCHE CREA F — radio de esquinas de cada foto del grid
    const double radioCategoria = 12;

    // 🔴 CHINCHE CREA G — alto de cada tarjeta de "lugar popular"
    const double alturaLugarPopular = 150;

    // 🔴 CHINCHE CREA H — lista de lugares populares
    const List<_LugarPopular> lugaresPopulares = [
      _LugarPopular(
        nombre: 'EL FARO PIZZERIA',
        direccion: 'Carrera 66 #5-152',
        imageAsset: 'assets/images/faro1.jpg',
        categoria: 'restaurante', // 🔴 CHINCHE CREA POP 2
        clickable: true,
      ),
      _LugarPopular(
        nombre: 'BAR LA NOCHE',
        direccion: 'Calle 5 #10-23',
        imageAsset: 'assets/images/barlanoche.jpg',
        categoria: 'bar', // 🔴 CHINCHE CREA POP 3
        clickable: true, // 🔴 CHINCHE CREA POP 3A — si quieres que también navegue
      ),
      _LugarPopular(
        nombre: 'CAFÉ CENTRAL',
        direccion: 'Av. 4N #12-50',
        imageAsset: 'assets/images/cafe1.jpg',
        categoria: 'cafe', // 🔴 CHINCHE CREA POP 4
        clickable: true,
      ),
      _LugarPopular(
        nombre: 'RESTAURANTE ANDES',
        direccion: 'Cra 34 #7-89',
        imageAsset: 'assets/images/restaurante1.jpg',
        categoria: 'restaurante', // 🔴 CHINCHE CREA POP 5
        clickable: true,
      ),
      _LugarPopular(
        nombre: 'BODEGA 66',
        direccion: 'Calle 9 #66-10',
        imageAsset: 'assets/images/bar1.jpg',
        categoria: 'bar', // 🔴 CHINCHE CREA POP 6
        clickable: true,
      ),
      _LugarPopular(
        nombre: 'CAFÉ AMOR',
        direccion: 'Calle 10 #15-60',
        imageAsset: 'assets/images/cafe2.jpg',
        categoria: 'cafe', // 🔴 CHINCHE CREA POP 7
        clickable: true,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ---------------------------------------------------------
        // TÍTULOS
        // ---------------------------------------------------------
        Text(
          'HOLA ${nombreUsuario.toUpperCase()}', // 🔴 CHINCHE CREA D4 — normalización
          style: textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontSize: 28, // 🔴 CHINCHE CREA I — tamaño texto principal
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.none,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '¿A DÓNDE QUIERES IR CON TU CITA?',
          style: textTheme.bodyMedium?.copyWith(
            color: Colors.white,
            fontSize: 16, // 🔴 CHINCHE CREA J — tamaño subtítulo
            decoration: TextDecoration.none,
          ),
        ),
        const SizedBox(height: 12),

        // ---------------------------------------------------------
        // GRID 2x2 — RESTAURANTES / BARES / CAFÉS / ACTIVIDADES
        // ---------------------------------------------------------
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
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
                      onTap: () {
                        // 🔴 CHINCHE CREA K — navegación a RestaurantesScreen
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const RestaurantesScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CategoriaCard(
                      titulo: 'BARES',
                      imageAsset: 'assets/images/iconobares.png',
                      altura: alturaCategoria,
                      radio: radioCategoria,
                      onTap: () {
                        // 🔴 CHINCHE CREA L — navegación a BaresScreen
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const BaresScreen(),
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
                    child: _CategoriaCard(
                      titulo: 'CAFÉS',
                      imageAsset: 'assets/images/iconocafeteria.png',
                      altura: alturaCategoria,
                      radio: radioCategoria,
                      onTap: () {
                        // 🔴 CHINCHE CREA M — navegación a CafesScreen
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const CafesScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CategoriaCard(
                      titulo: 'ACTIVIDADES',
                      imageAsset: 'assets/images/iconoactividades.png',
                      altura: alturaCategoria,
                      radio: radioCategoria,
                      onTap: () {
                        // 🔴 CHINCHE CREA N — navegación a ActividadesScreen
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ActividadesScreen(),
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

        const SizedBox(height: 22),

        // ---------------------------------------------------------
        // TÍTULO "LUGARES MÁS POPULARES"
        // ---------------------------------------------------------
        Text(
          'LUGARES MÁS POPULARES',
          style: textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontSize: 22, // 🔴 CHINCHE CREA O
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.none,
          ),
        ),
        const SizedBox(height: 8),

        // ---------------------------------------------------------
        // LISTA DE LUGARES POPULARES (VERTICAL)
        // ---------------------------------------------------------
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
                    // 🔴 CHINCHE CREA P — navegación real por categoría (MVP)
                    final cat = lugaresPopulares[i].categoria;

                    if (cat == 'restaurante') {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RestaurantesScreen()),
                      );
                      return;
                    }
                    if (cat == 'bar') {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const BaresScreen()),
                      );
                      return;
                    }
                    if (cat == 'cafe') {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CafesScreen()),
                      );
                      return;
                    }
                    if (cat == 'actividad') {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ActividadesScreen()),
                      );
                      return;
                    }
                  },
                ),
                if (i != lugaresPopulares.length - 1) const SizedBox(height: 16),
              ],
            ],
          ),
        ),

        const SizedBox(
          height: 16, // 🔴 CHINCHE CREA Q — espacio final del scroll
        ),
      ],
    );
  }
}

// ===============================================================
// 🔹 TARJETA DEL GRID (RESTAURANTES / BARES / CAFÉS / ACTIVIDADES)
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
      onTap: onTap, // 🔴 CHINCHE CREA R — acción al pulsar categoría
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
// 🔹 TARJETA INDIVIDUAL DE "LUGAR POPULAR"
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
      // 🔴 CHINCHE CREA CLICK 1 — si no es clickable, NO captura taps
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
