// 📂 lib/screens/zona_de_descuentos_screen.dart
// ✅ ZONA DE DESCUENTOS (DISEÑO PREMIUM FINAL)
// 🔥 UI: Grid de 3 columnas.
// 🔥 INTERACCIÓN: Click expande a Fullscreen con Zoom + Degradado con texto.
// 🔥 UI: Botón Chevron flotante (Atrás).

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proyectos_matchy/widgets/matchy_page_layout.dart';

class ZonaDeDescuentosScreen extends StatelessWidget {
  const ZonaDeDescuentosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Contenido Principal
          MatchyPageLayout(
            backgroundAsset: 'assets/images/fondo.jpg',
            logoAsset: 'assets/images/logomatchyplano.png',
            topSpacing: 35,
            logoHeight: 45,
            spaceLogoToScroll: 20,
            scrollContent: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // TÍTULO ENCABEZADO
                  const Text(
                    "ZONA DE DESCUENTOS",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Poppins',
                      letterSpacing: 1.0,
                      shadows: [Shadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4))],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // SUBTÍTULO
                  const Text(
                    "¡Exclusivo para parejas Matchy! Presenta estos códigos.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 25),

                  // GRID DE 3 COLUMNAS
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('descuentos').snapshots(),
                    builder: (context, snapshot) {
                      final List<dynamic> docs = (snapshot.hasData && snapshot.data!.docs.isNotEmpty)
                          ? snapshot.data!.docs
                          : [];

                      // Si está vacío, mostramos 12 items de ejemplo
                      final itemCount = docs.isEmpty ? 12 : docs.length;

                      return GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        padding: const EdgeInsets.only(bottom: 100), // Espacio para el Fade Out
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.7,
                        ),
                        itemCount: itemCount,
                        itemBuilder: (context, index) {
                          String fotoUrl = '';
                          String titulo = ''; // Se usa solo para la card pequeña si quieres, o se ignora

                          if (docs.isNotEmpty) {
                            final data = docs[index].data() as Map<String, dynamic>;
                            fotoUrl = data['fotoUrl'] ?? '';
                            titulo = data['titulo'] ?? '';
                          }

                          return _DiscountCard(
                            fotoUrl: fotoUrl,
                            titulo: titulo,
                            index: index,
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // 2. 🔥 DEGRADADO INFERIOR (FADE OUT DE LA PANTALLA PRINCIPAL)
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

          // 3. 🔥 BOTÓN CHEVRON (ATRAS)
          Positioned(
            top: 50, left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===============================================================
// 🔹 CARD PEQUEÑA DEL GRID
// ===============================================================
class _DiscountCard extends StatelessWidget {
  final String fotoUrl;
  final String titulo;
  final int index;

  const _DiscountCard({
    required this.fotoUrl,
    this.titulo = '',
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 🔥 NAVEGAR A PANTALLA COMPLETA
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _DiscountDetailScreen(fotoUrl: fotoUrl),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 3))],
          // Borde dorado sutil
          border: Border.all(color: const Color(0xFFFFC107).withOpacity(0.3), width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // FOTO
              fotoUrl.isNotEmpty
                  ? Image.network(fotoUrl, fit: BoxFit.cover)
                  : Container(
                color: Colors.white10,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.local_offer, color: Colors.white24, size: 30),
                    const SizedBox(height: 5),
                    Text(
                      "PROMO ${index + 1}",
                      style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===============================================================
// 🔹 PANTALLA DETALLE FULLSCREEN (NUEVA)
// ===============================================================
class _DiscountDetailScreen extends StatelessWidget {
  final String fotoUrl;

  const _DiscountDetailScreen({required this.fotoUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. FOTO FULLSCREEN CON ZOOM
          Center(
            child: InteractiveViewer(
              minScale: 1.0,
              maxScale: 4.0,
              child: fotoUrl.isNotEmpty
                  ? Image.network(
                fotoUrl,
                fit: BoxFit.contain, // Muestra el cupón entero
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_,__,___) => const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, color: Colors.white54, size: 60),
                    SizedBox(height: 10),
                    Text("Imagen no disponible", style: TextStyle(color: Colors.white54))
                  ],
                ),
              )
                  : const Icon(Icons.local_offer, color: Colors.white24, size: 100),
            ),
          ),

          // 2. 🔥 DEGRADADO INFERIOR NEGRO
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.9), // Negro casi sólido
                    Colors.black, // Negro total al final
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
              child: const Text(
                "Presenta este cupón en el establecimiento para redimir tu beneficio.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                  height: 1.4,
                ),
              ),
            ),
          ),

          // 3. BOTÓN CERRAR (CHEVRON FLOTANTE)
          Positioned(
            top: 50,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}