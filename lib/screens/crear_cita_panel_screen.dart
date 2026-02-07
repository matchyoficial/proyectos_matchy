// 📂 lib/screens/crear_cita_panel_screen.dart
// ✅ PANEL CREAR CITA BLINDADO (ESTRATEGIA ADAPTATIVA)
// 🔥 BLINDAJE: Títulos estandarizados a 20pt y textos variables elásticos.
// 🔥 UI: Diseño Premium original con degradado Fade Out intacto.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:proyectos_matchy/models/lugar_data.dart';
import 'package:proyectos_matchy/widgets/lugar_card.dart';
import 'package:proyectos_matchy/screens/lugar_plantilla_screen.dart';

import 'package:proyectos_matchy/screens/restaurantes_screen.dart';
import 'package:proyectos_matchy/screens/bares_screen.dart';
import 'package:proyectos_matchy/screens/cafes_screen.dart';
import 'package:proyectos_matchy/screens/actividades_screen.dart';

import 'package:proyectos_matchy/widgets/matchy_back_button.dart';

class CrearCitaPanelScreen extends StatelessWidget {
  static const String routeName = 'crear_cita_panel';

  final String nombreUsuario;

  const CrearCitaPanelScreen({
    super.key,
    this.nombreUsuario = 'AMIGO',
  });

  @override
  Widget build(BuildContext context) {
    const double espacioBarraLogo = 35;
    const double alturaLogo = 50;
    const double espacioLogoScroll = 15;
    const double margenInferiorPantalla = 120;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Fondo
          Positioned.fill(
            child: Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover),
          ),

          // 2. Botón Atrás
          const MatchyBackButton(top: 10, left: 16),

          // 3. Contenido
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
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: margenInferiorPantalla),
                  child: _CrearCitaContent(nombreUsuario: nombreUsuario),
                ),
              ),
            ],
          ),

          // 4. 🔥 DEGRADADO INFERIOR (FADE OUT)
          Positioned(
            bottom: 0, left: 0, right: 0, height: 90,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.95)],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===============================================================
// CONTENIDO BLINDADO
// ===============================================================
class _CrearCitaContent extends StatelessWidget {
  final String nombreUsuario;

  const _CrearCitaContent({required this.nombreUsuario});

  // Estilos de texto premium blindados
  static const TextStyle kTitleStyle = TextStyle(
    color: Colors.white,
    fontSize: 28, // Tamaño original para el saludo grande
    fontWeight: FontWeight.w900,
    fontFamily: 'Poppins',
    shadows: [Shadow(color: Colors.black, blurRadius: 10, offset: Offset(0, 4))],
  );

  static const TextStyle kSubtitleStyle = TextStyle(
    color: Colors.white70,
    fontSize: 15, // Ajustado levemente para consistencia
    fontWeight: FontWeight.w600,
    fontFamily: 'Poppins',
    shadows: [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 2))],
  );

  // Regla de Oro: Títulos de sección a 20pt
  static const TextStyle kSectionTitleStyle = TextStyle(
    color: Colors.white,
    fontSize: 20,
    fontWeight: FontWeight.w900,
    fontFamily: 'Poppins',
    shadows: [Shadow(color: Colors.black, blurRadius: 8, offset: Offset(0, 3))],
  );

  @override
  Widget build(BuildContext context) {
    const double alturaCategoria = 112;
    const double radioCategoria = 18;
    const double alturaLugarPopular = 150;

    return Column(
      children: [
        // SALUDO BLINDADO
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('HOLA ${nombreUsuario.toUpperCase()}', style: kTitleStyle),
          ),
        ),
        const SizedBox(height: 4),
        // SUBTÍTULO BLINDADO
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: const Text('¿A DÓNDE QUIERES IR CON TU CITA?', style: kSubtitleStyle),
          ),
        ),
        const SizedBox(height: 17),

        // GRID CATEGORÍAS
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _CategoriaCard(titulo: 'RESTAURANTES', imageAsset: 'assets/images/iconorestaurante.png', altura: alturaCategoria, radio: radioCategoria, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RestaurantesScreen())))),
                  const SizedBox(width: 12),
                  Expanded(child: _CategoriaCard(titulo: 'BARES', imageAsset: 'assets/images/iconobares.png', altura: alturaCategoria, radio: radioCategoria, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BaresScreen())))),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _CategoriaCard(titulo: 'CAFÉS', imageAsset: 'assets/images/iconocafeteria.png', altura: alturaCategoria, radio: radioCategoria, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CafesScreen())))),
                  const SizedBox(width: 12),
                  Expanded(child: _CategoriaCard(titulo: 'ACTIVIDADES', imageAsset: 'assets/images/iconoactividades.png', altura: alturaCategoria, radio: radioCategoria, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ActividadesScreen())))),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 30),

        // TÍTULO SECCIÓN POPULARES (Regla de Oro: 20pt)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: const Text(
              "LUGARES MÁS POPULARES",
              style: kSectionTitleStyle,
            ),
          ),
        ),

        const SizedBox(height: 15),

        // LISTA POPULARES (STREAM)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('lugares')
                .where('popular', isGreaterThan: 0)
                .orderBy('popular')
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: Colors.white));

              final docs = snap.data!.docs;
              if (docs.isEmpty) return const Text("No hay lugares populares aún.", style: TextStyle(color: Colors.white54));

              return Column(
                children: List.generate(docs.length, (index) {
                  final lugar = LugarData.fromMap(id: docs[index].id, data: docs[index].data());
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: LugarCard(
                      lugar: lugar,
                      altoTarjeta: alturaLugarPopular,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LugarPlantillaScreen(lugar: lugar))),
                    ),
                  );
                }),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ===============================================================
// CATEGORÍA CARD BLINDADA
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
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            height: altura,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radio),
              boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 4))],
              image: DecorationImage(
                image: AssetImage(imageAsset),
                fit: BoxFit.cover,
              ),
            ),
          ),

          Container(
            height: altura,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radio),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                stops: const [0.5, 1.0],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                titulo,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Poppins',
                  letterSpacing: 0.5,
                  shadows: [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 2))],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}