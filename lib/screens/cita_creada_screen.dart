// 📂 lib/screens/cita_creada_screen.dart
// ✅ CITA CREADA SCREEN — versión Flutter (con lógica real)
// ✅ Muestra datos elegidos en pantallas anteriores
// ✅ Genera código random (LLLNNNNN)
// ✅ Guarda la cita en citas_pendientes_screen.dart (provider)
// ✅ Cancelar borra de inmediato y vuelve al Panel
// ✅ FIX: NO modifica provider en initState directo (evita error Riverpod)
//
// ✅ NUEVO (ENGANCHE CITA_BUSCAR):
// - Guarda preferencia + intencion + datos del creador (nombre/edad/foto) en CitaPendiente

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:proyectos_matchy/widgets/matchy_back_button.dart';
import 'package:proyectos_matchy/screens/panel_screen.dart';

import 'package:proyectos_matchy/models/lugar_data.dart';

// 🔴 CHINCHE STORAGE 1 — aquí vive el provider + modelo
import 'package:proyectos_matchy/screens/citas_pendientes_screen.dart';

// ✅ NUEVO: perfil actual (para tomar nombre/edad/foto creador)
import 'package:proyectos_matchy/state/profile_form_provider.dart';

class CitaCreadaScreen extends ConsumerStatefulWidget {
  final LugarData lugar;
  final String fecha;
  final String hora;
  final String preferencia;
  final String intencion;

  const CitaCreadaScreen({
    super.key,
    required this.lugar,
    required this.fecha,
    required this.hora,
    required this.preferencia,
    required this.intencion,
  });

  @override
  ConsumerState<CitaCreadaScreen> createState() => _CitaCreadaScreenState();
}

class _CitaCreadaScreenState extends ConsumerState<CitaCreadaScreen> {
  // ===========================================================
  // 🔹 CÓDIGO DE CITA AUTOGENERADO (LLLNNNNN)
  // ===========================================================
  late final String _codigoCita;

  // 🔴 CHINCHE GUARD 1 — evita guardar 2 veces por hot reload/rebuild raro
  bool _guardadaEnProvider = false;

  @override
  void initState() {
    super.initState();
    _codigoCita = _generarCodigoCita();

    // ✅ FIX Riverpod:
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _guardarCitaPendienteSiNoExiste();
    });
  }

  void _guardarCitaPendienteSiNoExiste() {
    if (_guardadaEnProvider) return;

    // 🔴 CHINCHE FOTO 1 — para asset usamos la primera foto del lugar si es asset,
    // si viene URL (http) usamos placeholder para que NO reviente Image.asset.
    final String fotoLugar = _pickFotoLugarAsset(widget.lugar);

    // ===========================================================
    // ✅ NUEVO: datos del creador desde profileFormProvider
    // ===========================================================
    final perfil = ref.read(profileFormProvider);

    final String creadorNombre = (perfil.nombre.trim().isEmpty)
        ? 'Sin nombre'
        : perfil.nombre.trim();

    // 🔴 CHINCHE CREADOR EDAD 1 — parse seguro
    final int creadorEdad = int.tryParse(perfil.edad.trim()) ?? 0;

    // 🔴 CHINCHE CREADOR FOTO 1 — SOLO ASSET SEGURO por ahora (evita crash en Image.asset)
    final String creadorFoto = _pickCreadorFotoAssetSafe(perfil);

    // ✅ Provider actual (de citas_pendientes_screen.dart)
    ref.read(citasPendientesProvider.notifier).add(
      CitaPendiente(
        id: _codigoCita, // 🔴 CHINCHE ID 1 — usamos el código como id estable
        codigo: _codigoCita,
        nombreLugar: widget.lugar.nombre,
        direccionLugar: widget.lugar.direccion,
        fecha: widget.fecha,
        hora: widget.hora,
        fotoLugarAsset: fotoLugar,
        createdAt: DateTime.now(),

        // ✅ NUEVO: se guardan para CitaBuscar
        preferencia: widget.preferencia, // 🔴 CHINCHE PREF 1
        intencion: widget.intencion, // 🔴 CHINCHE INT 1
        creadorNombre: creadorNombre, // 🔴 CHINCHE CREADOR 2
        creadorEdad: creadorEdad, // 🔴 CHINCHE CREADOR 3
        creadorFoto: creadorFoto, // 🔴 CHINCHE CREADOR 4
      ),
    );

    _guardadaEnProvider = true;
  }

  // ✅ Solo devuelve un asset válido (evita crash si el modelo trae URL)
  String _pickFotoLugarAsset(LugarData lugar) {
    if (lugar.fotos.isEmpty) return 'assets/images/faro1.jpg'; // 🔴 fallback

    final first = lugar.fotos.first.trim();
    final isNetwork = first.startsWith('http://') || first.startsWith('https://');

    if (isNetwork) {
      // 🔴 CHINCHE FOTO 2 — placeholder si es URL (porque aquí usamos Image.asset)
      return 'assets/images/faro1.jpg';
    }

    return first.isEmpty ? 'assets/images/faro1.jpg' : first;
  }

  // ✅ SOLO ASSET por ahora para evitar reventar en CitaBuscar (que usa Image.asset)
  String _pickCreadorFotoAssetSafe(ProfileFormState perfil) {
    // 🔴 CHINCHE CREADOR FOTO 2 — fallback fijo
    const String fallback = 'assets/images/perfil1.jpg';

    if (perfil.fotosCargadas.isEmpty) return fallback;

    final first = perfil.fotosCargadas.first.trim();
    if (first.isEmpty) return fallback;

    // Si NO es asset, por ahora devolvemos fallback.
    // Cuando conectemos Firebase / FileImage, ahí sí soportamos paths reales.
    if (!first.startsWith('assets/')) return fallback;

    return first;
  }

  String _generarCodigoCita() {
    const letras = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const numeros = '0123456789';
    final random = Random();

    final letrasParte =
    List.generate(3, (_) => letras[random.nextInt(letras.length)]).join();

    final numerosParte =
    List.generate(5, (_) => numeros[random.nextInt(numeros.length)]).join();

    return '$letrasParte$numerosParte';
  }

  @override
  Widget build(BuildContext context) {
    // 🔴 CHINCHE CITA 1 — medidas clave
    const double espacioBarraLogo = 35;
    const double alturaLogo = 50;
    const double espacioLogoScroll = 15;
    const double margenInferiorPantalla = 80;
    const double offsetContenido = 0;
    const double alturaImagenLugar = 155;
    const double alturaBotonCancelar = 50;

    // 🔴 CHINCHE BOTON PANEL 1 — altura botón “REGRESAR AL PANEL”
    const double alturaBotonRegresarPanel = 50;

    final String fotoLugar = _pickFotoLugarAsset(widget.lugar);

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
                  padding: const EdgeInsets.only(bottom: margenInferiorPantalla),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: offsetContenido),
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        child: Text(
                          "TU CITA ESTÁ CREADA Y PUBLICADA",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),

                      // ✅ IMAGEN REAL DEL LUGAR (ASSET SEGURO)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 0),
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.9,
                          height: alturaImagenLugar,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Image.asset(
                            fotoLugar,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Image.asset(
                              'assets/images/perfil1.jpg',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // ✅ INFO REAL
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 0,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "LUGAR: ${widget.lugar.nombre}\n"
                                "DIRECCIÓN: ${widget.lugar.direccion}\n"
                                "FECHA: ${widget.fecha}\n"
                                "HORA: ${widget.hora}\n"
                                "PREFERENCIA: ${widget.preferencia.toUpperCase()}\n"
                                "INTENCIÓN: ${widget.intencion.toUpperCase()}",
                            textAlign: TextAlign.start,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              height: 1.3,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 5),

                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 4,
                        ),
                        child: Text(
                          "RECUERDA QUE SI HACES MATCHY CON ALGUIEN TIENES UN MÁXIMO DE 12 HORAS PARA CANCELAR TU CITA.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFFFFC107),
                            fontSize: 18,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        child: Text(
                          "RECUERDA QUE EN MATCHY EL QUE INVITA PAGA.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFFFF5252),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        "CÓDIGO DE LA CITA:",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _codigoCita,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.none,
                        ),
                      ),

                      const SizedBox(height: 25),

                      // ✅ CANCELAR: borra la cita y vuelve al panel
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.8,
                        height: alturaBotonCancelar,
                        child: ElevatedButton(
                          onPressed: () {
                            ref
                                .read(citasPendientesProvider.notifier)
                                .cancelById(_codigoCita);

                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                  builder: (_) => const PanelScreen()),
                                  (route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE53935),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text(
                            "CANCELAR TU CITA",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ✅ BOTÓN AZUL: REGRESAR AL PANEL
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.8,
                        height: alturaBotonRegresarPanel, // 🔴 CHINCHE BOTON PANEL 1
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                  builder: (_) => const PanelScreen()),
                                  (route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6A5ACD),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text(
                            "REGRESAR AL PANEL",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
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
