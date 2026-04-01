// 📂 lib/screens/zona_de_descuentos_screen.dart
// ✅ ZONA DE DESCUENTOS BLINDADA (SMART CACHE + GEOLOCALIZACIÓN)
// 🔥 BLINDAJE: Título estandarizado a 20pt y protegido con FittedBox.
// 🔥 DATOS: Filtro estricto por Colección 'descuentos', Ciudad, Activo y Orden.
// 🔥 UI: Proporción 9:16 (0.56) exacta para imágenes 1080x1920 sin deformación.
// 🔥 RENDIMIENTO: Motor CachedNetworkImage inyectado. Cero mockups feos.
// 🔥 FIX DEFINITIVO: Fondo Full Screen garantizado.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ZonaDeDescuentosScreen extends StatefulWidget {
  const ZonaDeDescuentosScreen({super.key});

  @override
  State<ZonaDeDescuentosScreen> createState() => _ZonaDeDescuentosScreenState();
}

class _ZonaDeDescuentosScreenState extends State<ZonaDeDescuentosScreen> {
  String _userCiudad = 'Cali'; // Ciudad por defecto
  bool _isLoadingCity = true;

  @override
  void initState() {
    super.initState();
    _fetchUserCity();
  }

  // 🔥 LECTURA SILENCIOSA DE LA CIUDAD DEL USUARIO ACTUAL
  Future<void> _fetchUserCity() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (snap.exists && snap.data() != null) {
          if (mounted) {
            setState(() {
              _userCiudad = (snap.data()!['ciudad'] ?? 'Cali').toString();
              _isLoadingCity = false;
            });
          }
          return;
        }
      } catch (_) {}
    }
    if (mounted) {
      setState(() => _isLoadingCity = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand, // 🔥 GARANTÍA 1: El stack ocupa todo el espacio
        children: [
          // 1. 🔥 FONDO ABSOLUTO (Cubre toda la pantalla, ignorando márgenes)
          Image.asset(
            'assets/images/fondo.jpg',
            fit: BoxFit.cover, // 🔥 GARANTÍA 2: La imagen se expande sin deformarse
            alignment: Alignment.center,
          ),

          // 2. CONTENIDO PRINCIPAL (Estructura manual limpia)
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 10),
                // LOGO
                Image.asset(
                  'assets/images/logomatchyplano.png',
                  height: 45,
                ),
                const SizedBox(height: 20),

                // SCROLL Y GRID
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 120),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          // 🛡️ BLINDAJE: TÍTULO ESTANDARIZADO A 20pt
                          const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              "ZONA DE DESCUENTOS",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Poppins',
                                letterSpacing: 1.0,
                                shadows: [Shadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4))],
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // 🛡️ TEXTO INFORMATIVO
                          const Text(
                            "PROMOCIONES Y DESCUENTOS PARA NUESTROS MATCHYS, ALGUNAS SON EXCLUSIVAS..",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 25),

                          // 🔥 MOTOR DE GRID INTELIGENTE
                          if (_isLoadingCity)
                            const Padding(
                              padding: EdgeInsets.only(top: 50),
                              child: CircularProgressIndicator(color: Color(0xFFBEB3FF)),
                            )
                          else
                            StreamBuilder<QuerySnapshot>(
                              // 🔒 FIX: APUNTANDO EXACTAMENTE AL ÍNDICE QUE CREASTE ('descuentos')
                              stream: FirebaseFirestore.instance
                                  .collection('descuentos')
                                  .where('activo', isEqualTo: true)
                                  .where('ciudad', isEqualTo: _userCiudad)
                                  .orderBy('orden')
                                  .snapshots(),
                              builder: (context, snapshot) {
                                // 🔥 FIX: Errores silenciosos para no ensuciar la pantalla mientras configuras
                                if (snapshot.hasError || !snapshot.hasData) {
                                  return const SizedBox.shrink();
                                }

                                final validDocs = snapshot.data!.docs.where((doc) {
                                  final data = doc.data() as Map<String, dynamic>;
                                  final foto = data['foto']?.toString() ?? '';
                                  return foto.isNotEmpty;
                                }).toList();

                                if (validDocs.isEmpty) {
                                  return const SizedBox.shrink(); // Pantalla limpia si no hay datos
                                }

                                return GridView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: 0.56,
                                  ),
                                  itemCount: validDocs.length,
                                  itemBuilder: (context, index) {
                                    final data = validDocs[index].data() as Map<String, dynamic>;
                                    final fotoUrl = data['foto']?.toString() ?? '';

                                    return _DiscountCard(
                                      fotoUrl: fotoUrl,
                                    );
                                  },
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. DEGRADADO INFERIOR
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

          // 4. BOTÓN ATRÁS
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
// 🛡️ TARJETA DE DESCUENTO BLINDADA
// ===============================================================
class _DiscountCard extends StatelessWidget {
  final String fotoUrl;

  const _DiscountCard({
    required this.fotoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _DiscountDetailScreen(fotoUrl: fotoUrl),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 3))],
          border: Border.all(color: const Color(0xFFFFC107).withOpacity(0.3), width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: fotoUrl,
            fit: BoxFit.cover,
            memCacheHeight: 600,
            placeholder: (context, url) => Container(
              color: Colors.white10,
              child: const Center(
                child: SizedBox(
                  width: 24, height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFFBEB3FF)),
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.white10,
            ),
          ),
        ),
      ),
    );
  }
}

// ===============================================================
// 🛡️ PANTALLA DETALLE (FULLSCREEN ZOOM)
// ===============================================================
class _DiscountDetailScreen extends StatelessWidget {
  final String fotoUrl;

  const _DiscountDetailScreen({required this.fotoUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. IMAGEN FULLSCREEN CON ZOOM Y CACHÉ
          Center(
            child: InteractiveViewer(
              minScale: 1.0,
              maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: fotoUrl,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(color: Color(0xFFBEB3FF)),
                ),
                errorWidget: (context, url, error) => const SizedBox.shrink(),
              ),
            ),
          ),

          // 2. DEGRADADO INFERIOR
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
                    Colors.black.withOpacity(0.9),
                    Colors.black,
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

          // 3. BOTÓN CERRAR
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