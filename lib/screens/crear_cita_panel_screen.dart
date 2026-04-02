// 📂 lib/screens/crear_cita_panel_screen.dart
// ✅ PANEL CREAR CITA BLINDADO (ESTRATEGIA ADAPTATIVA + GEOLOCALIZACIÓN)
// 🔥 BLINDAJE: Títulos estandarizados a 20pt y textos variables elásticos.
// 🔥 DATOS: Filtro estricto por Ciudad y País en "Lugares Populares".
// 🔥 UI: Diseño Premium original con degradado Fade Out intacto.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 🔥 Import agregado para leer al usuario

import 'package:proyectos_matchy/models/lugar_data.dart';
import 'package:proyectos_matchy/widgets/lugar_card.dart';
import 'package:proyectos_matchy/screens/lugar_plantilla_screen.dart';

import 'package:proyectos_matchy/screens/restaurantes_screen.dart';
import 'package:proyectos_matchy/screens/bares_screen.dart';
import 'package:proyectos_matchy/screens/cafes_screen.dart';
import 'package:proyectos_matchy/screens/actividades_screen.dart';

import 'package:proyectos_matchy/widgets/matchy_back_button.dart';
import 'package:proyectos_matchy/widgets/banner_publicidad.dart';

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
          const MatchyBackButton(top: 1, left: 16),

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
// CONTENIDO BLINDADO CON GEOLOCALIZACIÓN
// ===============================================================
class _CrearCitaContent extends StatefulWidget {
  final String nombreUsuario;

  const _CrearCitaContent({required this.nombreUsuario});

  @override
  State<_CrearCitaContent> createState() => _CrearCitaContentState();
}

class _CrearCitaContentState extends State<_CrearCitaContent> {
  // Estilos de texto premium blindados
  static const TextStyle kTitleStyle = TextStyle(
    color: Colors.white,
    fontSize: 28,
    fontWeight: FontWeight.w900,
    fontFamily: 'Poppins',
    shadows: [Shadow(color: Colors.black, blurRadius: 10, offset: Offset(0, 4))],
  );

  static const TextStyle kSubtitleStyle = TextStyle(
    color: Colors.white70,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    fontFamily: 'Poppins',
    shadows: [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 2))],
  );

  static const TextStyle kSectionTitleStyle = TextStyle(
    color: Colors.white,
    fontSize: 20,
    fontWeight: FontWeight.w900,
    fontFamily: 'Poppins',
    shadows: [Shadow(color: Colors.black, blurRadius: 8, offset: Offset(0, 3))],
  );

  String _userCiudad = 'Cali';
  String _userPais = 'Colombia';
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _fetchUserLocation();
  }

  // 🔥 LECTURA SILENCIOSA DE LA UBICACIÓN DEL USUARIO ACTUAL
  Future<void> _fetchUserLocation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (snap.exists && snap.data() != null) {
          if (mounted) {
            setState(() {
              _userCiudad = (snap.data()!['ciudad'] ?? 'Cali').toString();
              _userPais = (snap.data()!['pais'] ?? 'Colombia').toString();
              _isLoadingLocation = false;
            });
          }
          return;
        }
      } catch (_) {}
    }
    if (mounted) {
      setState(() => _isLoadingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const double radioCategoria = 18;
    const double alturaLugarPopular = 150;

    return Column(
      children: [
        // SALUDO BLINDADO
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('HOLA ${widget.nombreUsuario.toUpperCase()}', style: kTitleStyle),
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

        // 🔥 GRID CATEGORÍAS
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(child: _CategoriaCard(titulo: 'RESTAURANTES', imageAsset: 'assets/images/restaurantes_ico.jpg', radio: radioCategoria, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RestaurantesScreen())))),
              const SizedBox(width: 8),
              Expanded(child: _CategoriaCard(titulo: 'BARES', imageAsset: 'assets/images/bares_ico.jpg', radio: radioCategoria, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BaresScreen())))),
              const SizedBox(width: 8),
              Expanded(child: _CategoriaCard(titulo: 'CAFÉS', imageAsset: 'assets/images/cafes_ico.jpg', radio: radioCategoria, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CafesScreen())))),
              const SizedBox(width: 8),
              Expanded(child: _CategoriaCard(titulo: 'ACTIVIDADES', imageAsset: 'assets/images/actividades_ico.jpg', radio: radioCategoria, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ActividadesScreen())))),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // 🔥 BANNER PUBLICITARIO
        const BannerPublicidad(),

        const SizedBox(height: 20),

        // TÍTULO SECCIÓN POPULARES
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

        // LISTA POPULARES CON CANDADOS
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _isLoadingLocation
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFBEB3FF)))
              : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            // 🔒 CANDADOS INYECTADOS: País, Ciudad y Orden por Popularidad
            stream: FirebaseFirestore.instance
                .collection('lugares')
                .where('pais', isEqualTo: _userPais)
                .where('ciudad', isEqualTo: _userCiudad)
                .where('popular', isGreaterThan: 0)
                .orderBy('popular', descending: true) // Asegura que los más altos salgan primero
                .snapshots(),
            builder: (context, snap) {
              if (snap.hasError) return const Center(child: Text("Error de carga", style: TextStyle(color: Colors.white54)));
              if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: Colors.white));

              final docs = snap.data!.docs;
              if (docs.isEmpty) return const Text("No hay lugares populares en tu ciudad.", style: TextStyle(color: Colors.white54, fontFamily: 'Poppins'));

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
  final double radio;
  final VoidCallback onTap;

  const _CategoriaCard({
    required this.titulo,
    required this.imageAsset,
    required this.radio,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(radio),
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 4))],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                imageAsset,
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                left: 6,
                right: 6,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    titulo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
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
        ),
      ),
    );
  }
}