// 📂 lib/screens/restaurantes_screen.dart
// ✅ RESTAURANTES — data-driven + LugarCard
// ✅ Diseño INTACTO
// ✅ IMPORTS 100% correctos

import 'package:flutter/material.dart';

import 'package:proyectos_matchy/models/lugar_data.dart';
import 'package:proyectos_matchy/data/lugares_catalogo.dart';
import 'package:proyectos_matchy/widgets/lugar_card.dart';
import 'package:proyectos_matchy/widgets/matchy_back_button.dart';
import 'package:proyectos_matchy/screens/lugar_plantilla_screen.dart';

class RestaurantesScreen extends StatelessWidget {
  const RestaurantesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const double espacioBarraLogo = 35;
    const double alturaLogo = 50;
    const double espacioLogoScroll = 15;
    const double margenInferior = 80;
    const double altoTarjeta = 160;
    const double separacionTarjetas = 20;

    final List<LugarData> restaurantes = LugaresCatalogo.restaurantes;

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
            top: 10,
            left: 16,
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
                  padding: const EdgeInsets.only(bottom: margenInferior),
                  child: Column(
                    children: [
                      const Text(
                        'RESTAURANTES',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.none,
                        ),
                      ),

                      const SizedBox(height: 6),

                      ...List.generate(restaurantes.length, (i) {
                        final lugar = restaurantes[i];

                        return Padding(
                          padding: EdgeInsets.only(
                            left: 16,
                            right: 16,
                            top: i == 0 ? 8 : separacionTarjetas,
                          ),
                          child: LugarCard(
                            lugar: lugar,
                            altoTarjeta: altoTarjeta,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      LugarPlantillaScreen(lugar: lugar),
                                ),
                              );
                            },
                          ),
                        );
                      }),

                      const SizedBox(height: 12),
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
