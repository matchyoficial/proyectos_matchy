// 📂 lib/screens/citas_pendientes_detalle.dart
// ✅ FIX: al tocar la foto del candidato YA NO abre PerfilScreen (tu perfil roto)
// ✅ Ahora abre un perfil “preview” seguro del candidato (sin dependencias externas)
// ✅ Diseño Matchy + botón back + fondo
// ✅ NUEVO: Botón “HACER MATCHY” → abre MatchScreen (match_screen.dart)

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:proyectos_matchy/screens/citas_pendientes_screen.dart';

// ✅ NUEVO: pantalla final de match
import 'package:proyectos_matchy/screens/match_screen.dart';

// ================================================================
// 🔹 PERFIL PREVIEW SEGURO DEL CANDIDATO (FIX DEL CRASH)
// ================================================================
class CandidatoPerfilPreviewScreen extends StatelessWidget {
  final String nombre;
  final int edad;
  final String fotoAsset;

  const CandidatoPerfilPreviewScreen({
    super.key,
    required this.nombre,
    required this.edad,
    required this.fotoAsset,
  });

  @override
  Widget build(BuildContext context) {
    // 🔴 CHINCHE PREVIEW 1 — alto foto
    const double altoFoto = 320;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover),
          ),

          // Back
          Positioned(
            top: 12,
            left: 12,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          Column(
            children: [
              const SizedBox(height: 60),

              // Logo
              SizedBox(
                height: 50,
                child: Image.asset('assets/images/logomatchyplano.png'),
              ),

              const SizedBox(height: 14),

              // Foto grande con degradado
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Stack(
                    children: [
                      SizedBox(
                        height: altoFoto,
                        width: double.infinity,
                        child: Image.asset(
                          fotoAsset,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Image.asset(
                            'assets/images/perfil1.jpg',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 130,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.75),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: Text(
                          '$nombre, $edad',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Bio demo
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0x33FFFFFF),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Text(
                  'Perfil de candidato (preview).\n\nAquí luego conectamos con el perfil real de Matchy cuando esté listo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.3,
                    fontFamily: 'Poppins',
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

// ================================================================
// 🔹 MODELO CANDIDATO (DEMO)
// ================================================================
class _CandidatoMatchy {
  final String id;
  final String nombre;
  final int edad;
  final String fotoAsset;

  const _CandidatoMatchy({
    required this.id,
    required this.nombre,
    required this.edad,
    required this.fotoAsset,
  });
}

class CitasPendientesDetalleScreen extends ConsumerStatefulWidget {
  final String citaId;

  const CitasPendientesDetalleScreen({
    super.key,
    required this.citaId,
  });

  @override
  ConsumerState<CitasPendientesDetalleScreen> createState() =>
      _CitasPendientesDetalleScreenState();
}

class _CitasPendientesDetalleScreenState
    extends ConsumerState<CitasPendientesDetalleScreen> {
  Timer? _timer;

  // 🔴 CHINCHE RELOJ 1 — actualiza cada 1 segundo
  static const Duration _tick = Duration(seconds: 1);

  // 🔴 CHINCHE RELOJ 2 — alerta 1 sola vez cuando falte 1 hora o menos
  bool _alerta1hMostrada = false;

  // 🔴 CHINCHE RELOJ 3 — tiempo restante cacheado
  Duration _restante = Duration.zero;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(_tick, (_) {
      if (!mounted) return;
      _recalcularContadorYAlertar();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _recalcularContadorYAlertar();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _recalcularContadorYAlertar() {
    final citas = ref.read(citasPendientesProvider);

    final existe = citas.any((c) => c.id == widget.citaId);
    if (!existe) return;

    final cita = citas.firstWhere((c) => c.id == widget.citaId);

    final DateTime? citaDateTime = _parseCitaDateTime(cita.fecha, cita.hora);
    if (citaDateTime == null) {
      setState(() => _restante = Duration.zero);
      return;
    }

    final DateTime deadline = citaDateTime.subtract(const Duration(hours: 12));
    final now = DateTime.now();

    final Duration restante = deadline.difference(now);
    final Duration clamped = restante.isNegative ? Duration.zero : restante;

    if (!_alerta1hMostrada &&
        restante <= const Duration(hours: 1) &&
        restante > Duration.zero) {
      _alerta1hMostrada = true;

      final textoCita = '${cita.nombreLugar} • ${cita.fecha} • ${cita.hora}';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Te queda 1 hora para escoger a tu matchy en la cita del $textoCita',
          ),
          duration: const Duration(seconds: 6),
        ),
      );
    }

    setState(() => _restante = clamped);
  }

  DateTime? _parseCitaDateTime(String fecha, String hora) {
    try {
      final f = fecha.trim();
      final h = hora.trim();

      final parts = f.split('/');
      if (parts.length != 3) return null;

      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);

      int hour24 = 0;
      int minute = 0;

      final upper = h.toUpperCase();

      if (upper.contains('AM') || upper.contains('PM')) {
        final isPM = upper.contains('PM');
        final clean = upper.replaceAll('AM', '').replaceAll('PM', '').trim();
        final hm = clean.split(':');
        if (hm.length != 2) return null;

        var hh = int.parse(hm[0].trim());
        minute = int.parse(hm[1].trim());

        if (isPM) {
          if (hh != 12) hh += 12;
        } else {
          if (hh == 12) hh = 0;
        }
        hour24 = hh;
      } else {
        final hm = upper.split(':');
        if (hm.length != 2) return null;
        hour24 = int.parse(hm[0].trim());
        minute = int.parse(hm[1].trim());
      }

      return DateTime(year, month, day, hour24, minute);
    } catch (_) {
      return null;
    }
  }

  String _formatHHMMSS(Duration d) {
    final total = d.inSeconds;
    final hh = (total ~/ 3600).toString().padLeft(2, '0');
    final mm = ((total % 3600) ~/ 60).toString().padLeft(2, '0');
    final ss = (total % 60).toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    const double espacioBarraLogo = 35;
    const double alturaLogo = 50;
    const double espacioLogoTitulo = 12;
    const double paddingBottom = 90;

    final citas = ref.watch(citasPendientesProvider);
    final existe = citas.any((c) => c.id == widget.citaId);

    if (!existe) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover),
            ),
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0x33FFFFFF),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Text(
                  'Esta cita ya no existe (probablemente fue cancelada).',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      );
    }

    final cita = citas.firstWhere((c) => c.id == widget.citaId);

    const candidatos = <_CandidatoMatchy>[
      _CandidatoMatchy(
        id: 'chica1',
        nombre: 'Anita',
        edad: 24,
        fotoAsset: 'assets/images/chica1.png',
      ),
      _CandidatoMatchy(
        id: 'chica4',
        nombre: 'Valentina',
        edad: 27,
        fotoAsset: 'assets/images/chica4.png',
      ),
      _CandidatoMatchy(
        id: 'chica2',
        nombre: 'Carla',
        edad: 23,
        fotoAsset: 'assets/images/chica2.png',
      ),
      _CandidatoMatchy(
        id: 'chica5',
        nombre: 'Laura',
        edad: 29,
        fotoAsset: 'assets/images/chica5.png',
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
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
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: paddingBottom),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // FOTO GRANDE DEL LUGAR
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          height: 190,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.45),
                                blurRadius: 10,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.asset(
                            cita.fotoLugarAsset,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Image.asset(
                              'assets/images/perfil1.jpg',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // INFO
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cita.nombreLugar,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '📍 ${cita.direccionLugar}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '📅 ${cita.fecha}   🕒 ${cita.hora}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),

                      // RELOJ
                      const SizedBox(height: 10),
                      Center(
                        child: Text(
                          _formatHHMMSS(_restante),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFFF5252),
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Center(
                        child: Text(
                          'TIEMPO PARA ELEGIR TU MATCHY',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFFFF5252),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // TITULO
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          '¿CON QUIÉN QUIERES IR A TU CITA?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // GRID 2 POR FILA
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: candidatos.length,
                          gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.86,
                          ),
                          itemBuilder: (_, i) {
                            final c = candidatos[i];
                            return _CandidatoCard(
                              candidato: c,
                              onTapFoto: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => CandidatoPerfilPreviewScreen(
                                      nombre: c.nombre,
                                      edad: c.edad,
                                      fotoAsset: c.fotoAsset,
                                    ),
                                  ),
                                );
                              },
                              onMatchy: () {
                                // ✅ ENGANCHE REAL → MATCH SCREEN FINAL
                                // 🔴 CHINCHE MATCH ENGANCHE 1 — este ID es CLAVE para:
                                //    1) crear/guardar el thread del chat en Riverpod
                                //    2) abrir ChatDetalleScreen con un id estable
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => MatchScreen(
                                      candidatoId: c.id, // 🔴 CHINCHE (ANTES FALTABA)
                                      candidatoNombre: c.nombre,
                                      candidatoEdad: c.edad,
                                      candidatoFotoAsset: c.fotoAsset,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 20),
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

// ================================================================
// 🔹 CARD CANDIDATO (foto + degradado + nombre/edad + botón amarillo)
// ================================================================
class _CandidatoCard extends StatelessWidget {
  final _CandidatoMatchy candidato;
  final VoidCallback onTapFoto;
  final VoidCallback onMatchy;

  const _CandidatoCard({
    required this.candidato,
    required this.onTapFoto,
    required this.onMatchy,
  });

  @override
  Widget build(BuildContext context) {
    const double radio = 18;
    const double altoBoton = 36;

    return Column(
      children: [
        Expanded(
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(radio),
            child: InkWell(
              borderRadius: BorderRadius.circular(radio),
              onTap: onTapFoto,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radio),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        candidato.fotoAsset,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Image.asset(
                          'assets/images/perfil1.jpg',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 70,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.65),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 10,
                      right: 10,
                      bottom: 10,
                      child: Center(
                        child: Text(
                          '${candidato.nombre}, ${candidato.edad}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: altoBoton,
          child: ElevatedButton(
            onPressed: onMatchy,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFC107),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'HACER MATCHY',
              style: TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ),
      ],
    );
  }
}
