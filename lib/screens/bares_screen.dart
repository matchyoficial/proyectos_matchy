// 📂 lib/screens/bares_screen.dart
// ✅ BARES → data-driven con LugarData (desde catálogo central)
// ✅ Diseño intacto
// ✅ Sin barra inferior (pantalla secundaria)

import 'package:flutter/material.dart';

import 'package:proyectos_matchy/widgets/matchy_back_button.dart';
import 'package:proyectos_matchy/models/lugar_data.dart';
import 'package:proyectos_matchy/screens/lugar_plantilla_screen.dart';
import 'package:proyectos_matchy/data/lugares_catalogo.dart'; // 🔴 CHINCHE BARES DATA 0

class BaresScreen extends StatelessWidget {
  static const String routeName = 'bares';

  const BaresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const double espacioBarraLogo = 35;
    const double alturaLogo = 50;
    const double espacioLogoScroll = 15;
    const double margenInferiorPantalla = 80;
    const double altoTarjeta = 160;
    const double espacioEntreTarjetas = 20;

    final scrollController = ScrollController();

    final List<LugarData> bares = LugaresCatalogo.bares; // 🔴 CHINCHE BARES DATA 1

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
            top: 10,   // 🔴 CHINCHE BARES B
            left: 16,  // 🔴 CHINCHE BARES C
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
                  controller: scrollController,
                  padding: const EdgeInsets.only(bottom: margenInferiorPantalla),
                  child: Column(
                    children: [
                      const Text(
                        'BARES',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 6),

                      ...List.generate(bares.length, (index) {
                        final lugar = bares[index];

                        return Padding(
                          padding: EdgeInsets.only(
                            left: 16,
                            right: 16,
                            top: index == 0 ? 8 : espacioEntreTarjetas,
                          ),
                          child: _LugarCard(
                            lugar: lugar,
                            altoTarjeta: altoTarjeta,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => LugarPlantillaScreen(lugar: lugar),
                                ),
                              );
                            },
                          ),
                        );
                      }),

                      const SizedBox(height: 8),
                    ],
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

class _LugarCard extends StatelessWidget {
  final LugarData lugar;
  final double altoTarjeta;
  final VoidCallback onTap;

  const _LugarCard({
    required this.lugar,
    required this.altoTarjeta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String image = lugar.fotos.isNotEmpty
        ? lugar.fotos.first
        : 'assets/images/perfil1.jpg';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: altoTarjeta,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.45),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
          image: DecorationImage(
            image: AssetImage(image),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          alignment: Alignment.bottomLeft,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.8),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lugar.nombre,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
                ),
              ),
              Text(
                lugar.direccion,
                style: const TextStyle(
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
