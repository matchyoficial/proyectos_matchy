// 📂 lib/screens/citas_pendientes_screen.dart
// ✅ CITAS PUBLICADAS (Pendientes) — diseño Matchy
// ✅ Muestra: foto del sitio + nombre + dirección + fecha + hora
// ✅ Riverpod: lista dinámica + cancelar elimina de inmediato (sin crashear)
// ✅ Fondo + logo + scroll perfecto
// ✅ Tap en la tarjeta → abre detalle (citas_pendientes_detalle.dart)
// ✅ FIX CRÍTICO: Screen "shell-safe" (NO trae bottom nav interno)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 🔴 CHINCHE DETALLE IMPORT 1 — pantalla detalle de cita publicada
import 'package:proyectos_matchy/screens/citas_pendientes_detalle.dart';

// ================================================================
// 🔹 MODELO: CITA PUBLICADA (PENDIENTE) — (ACTUALIZADO)
// ================================================================
class CitaPendiente {
  final String id; // 🔴 CHINCHE CITA ID — interno (puede ser el código)
  final String codigo; // código visible (ej AVX72025)

  // ✅ Datos lugar
  final String nombreLugar;
  final String direccionLugar;
  final String fecha; // texto ya listo (ej 05/10/2025)
  final String hora; // texto ya listo (ej 8:30 PM)
  final String fotoLugarAsset; // asset principal del sitio

  // ✅ NUEVO: Preferencia / Intención (para mostrar en CitaBuscar + detalle)
  final String preferencia; // 🔴 CHINCHE PREF 1
  final String intencion; // 🔴 CHINCHE INT 1

  // ✅ NUEVO: Datos del creador (para CitaBuscar)
  final String creadorNombre; // 🔴 CHINCHE CREADOR 1
  final int creadorEdad; // 🔴 CHINCHE CREADOR 2
  final String creadorFoto; // 🔴 CHINCHE CREADOR 3 (asset SAFE por ahora)

  final DateTime createdAt; // para ordenar

  const CitaPendiente({
    required this.id,
    required this.codigo,
    required this.nombreLugar,
    required this.direccionLugar,
    required this.fecha,
    required this.hora,
    required this.fotoLugarAsset,

    // ✅ NUEVO
    required this.preferencia, // 🔴 CHINCHE PREF 2
    required this.intencion, // 🔴 CHINCHE INT 2
    required this.creadorNombre, // 🔴 CHINCHE CREADOR 4
    required this.creadorEdad, // 🔴 CHINCHE CREADOR 5
    required this.creadorFoto, // 🔴 CHINCHE CREADOR 6

    required this.createdAt,
  });
}

// ================================================================
// 🔹 STATE: CITAS PENDIENTES (Riverpod)
// ================================================================
class CitasPendientesNotifier extends StateNotifier<List<CitaPendiente>> {
  CitasPendientesNotifier() : super(const []) {
    // 🔴 CHINCHE DEMO 1 — demo inicial (puedes borrar cuando ya guardes real)
    state = [
      CitaPendiente(
        id: 'AVX72025',
        codigo: 'AVX72025',
        nombreLugar: 'EL FARO PIZZERÍA',
        direccionLugar: 'Carrera 66#5-152',
        fecha: '05/10/2025',
        hora: '8:30 PM',
        fotoLugarAsset: 'assets/images/faro1.jpg',

        // 🔴 CHINCHE DEMO 2 — nuevos campos requeridos
        preferencia: 'Mujeres',
        intencion: 'Amistad',
        creadorNombre: 'Anita',
        creadorEdad: 24,
        creadorFoto: 'assets/images/chica1.png',

        createdAt: DateTime(2026, 1, 6, 10, 30),
      ),
    ];
  }

  // ✅ Agregar cita
  void add(CitaPendiente cita) {
    final next = [...state, cita]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    state = next;
  }

  // ✅ Cancelar (elimina de inmediato)
  void cancelById(String id) {
    state = state.where((c) => c.id != id).toList();
  }

  void clearAll() => state = const [];
}

final citasPendientesProvider =
StateNotifierProvider<CitasPendientesNotifier, List<CitaPendiente>>(
      (ref) => CitasPendientesNotifier(),
);

// ================================================================
// 🔹 PANTALLA: CITAS PUBLICADAS
// ================================================================
class CitasPendientesScreen extends ConsumerWidget {
  const CitasPendientesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🔴 CHINCHE UI 1 — mismas medidas base Matchy
    const double espacioBarraLogo = 35;
    const double alturaLogo = 50;
    const double espacioLogoTitulo = 15;

    // 🔴 CHINCHE UI 2 — padding inferior para no chocar con barra del shell
    const double paddingBottom = 90;

    final citas = ref.watch(citasPendientesProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/fondo.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Column(
            children: [
              const SizedBox(height: espacioBarraLogo),
              SizedBox(
                height: alturaLogo,
                child: Image.asset('assets/images/logomatchyplano.png'),
              ),
              const SizedBox(height: espacioLogoTitulo),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'CITAS PUBLICADAS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: paddingBottom,
                  ),
                  itemCount: citas.isEmpty ? 1 : citas.length,
                  itemBuilder: (context, index) {
                    if (citas.isEmpty) return _EmptyState();
                    final cita = citas[index];
                    return _CitaPendienteCard(cita: cita);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ================================================================
// 🔹 EMPTY STATE (Matchy)
// ================================================================
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0x33FFFFFF),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aún no tienes citas publicadas.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Crea una cita desde el Panel y aparecerá aquí automáticamente.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.3,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// 🔹 CARD: CITA PUBLICADA (foto + info + cancelar)
// ✅ Tap card → Detalle
// ================================================================
class _CitaPendienteCard extends ConsumerWidget {
  final CitaPendiente cita;

  const _CitaPendienteCard({required this.cita});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🔴 CHINCHE CARD 1 — color tarjeta (Matchy)
    const Color cardColor = Color(0x996A5ACD);

    // 🔴 CHINCHE CARD 2 — alturas
    const double cardHeight = 140;
    const double fotoWidth = 120;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Card(
        elevation: 6,
        color: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CitasPendientesDetalleScreen(citaId: cita.id),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: cardHeight,
            child: Row(
              children: [
                // FOTO LUGAR
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                  child: _SafeAssetImage(
                    asset: cita.fotoLugarAsset,
                    width: fotoWidth,
                    height: cardHeight,
                    fallback: 'assets/images/perfil1.jpg',
                  ),
                ),

                // INFO
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cita.nombreLugar,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '📍 ${cita.direccionLugar}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '📅 ${cita.fecha}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '🕒 ${cita.hora}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const Spacer(),

                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 34,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'CÓDIGO: ${cita.codigo}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              height: 34,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE53935),
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: () {
                                  ref.read(citasPendientesProvider.notifier).cancelById(cita.id);

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Cita cancelada.')),
                                  );
                                },
                                child: const Text(
                                  'CANCELAR',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 6),
                const Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: Icon(
                    Icons.chevron_right,
                    color: Colors.white70,
                    size: 26,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ================================================================
// ✅ Imagen asset segura (no crashea si falta)
// ================================================================
class _SafeAssetImage extends StatelessWidget {
  final String asset;
  final double width;
  final double height;
  final String fallback;

  const _SafeAssetImage({
    required this.asset,
    required this.width,
    required this.height,
    required this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Image.asset(
        fallback,
        width: width,
        height: height,
        fit: BoxFit.cover,
      ),
    );
  }
}
