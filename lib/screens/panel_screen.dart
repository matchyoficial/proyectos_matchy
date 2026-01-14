// 📂 lib/screens/panel_screen.dart
// ✅ PANEL PERFECTO con lógica Riverpod (sin cambiar diseño)
// ✅ Nombre + edad SIEMPRE en una fila (sin RenderFlex overflow)
// ✅ Foto perfil: URL (Storage) > asset > File path (cross-device)
// ✅ Botón "Editar Perfil" → DatosScreen
// ✅ Incluye _MatchyBottomNav completo
// ✅ Botón "CITAS PUBLICADAS" conectado
//
// ✅ FIREBASE: Panel lee users/{uid} desde Firestore
// ✅ Si onboarding_completed != true → redirige a DatosScreen
// ✅ Fallback: si Firestore no está listo, usa profileFormProvider
//
// ✅ FIX CACHE/LOGOUT:
//    - userDocProvider ahora es nullable. Si no hay sesión, emite null (no se queda loading infinito).
//    - Si no hay sesión: redirige a Splash (tu flujo decide login/registro).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 🔴 CHINCHE FIREBASE PANEL 1 — Auth + Firestore
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:proyectos_matchy/screens/crear_cita_panel_screen.dart';

// 🔴 CHINCHE PANEL NAV A — imports de las 4 pantallas destino del grid
import 'package:proyectos_matchy/screens/restaurantes_screen.dart';
import 'package:proyectos_matchy/screens/bares_screen.dart';
import 'package:proyectos_matchy/screens/cafes_screen.dart';
import 'package:proyectos_matchy/screens/actividades_screen.dart';

// 🔴 CHINCHE PANEL NAV B — imports de las 5 pantallas principales
import 'package:proyectos_matchy/screens/perfil_screen.dart';
import 'package:proyectos_matchy/screens/citas_screen.dart';
import 'package:proyectos_matchy/screens/matchys_screen.dart';
import 'package:proyectos_matchy/screens/chat_screen.dart';

// ✅ Ir a editar datos
import 'package:proyectos_matchy/screens/datos_screen.dart';

// ✅ Provider de perfil (REAL) — fallback local
import 'package:proyectos_matchy/state/profile_form_provider.dart';

// 🔴 CHINCHE PANEL CITAS PUB 0 — pantalla de “citas publicadas”
import 'package:proyectos_matchy/screens/citas_pendientes_screen.dart';

// 🔴 CHINCHE PANEL BUSCAR 0 — pantalla “Buscar una cita” (Swipe deck)
import 'package:proyectos_matchy/screens/cita_buscar.dart';

// 🔴 CHINCHE PANEL NAV SPLASH 1 — si no hay sesión, volvemos a Splash
import 'package:proyectos_matchy/screens/splash_screen.dart';

// ===========================================================
// 🔥 Provider: documento de usuario Firestore users/{uid}
// ===========================================================

// 🔴 CHINCHE FIREBASE PANEL 2 — nombre de colección users
const String kUsersCollection = 'users';

// 🔴 CHINCHE FIREBASE PANEL FIX 1 — Provider nullable (evita loading infinito con Stream.empty)
final userDocProvider = StreamProvider<DocumentSnapshot<Map<String, dynamic>>?>(
      (ref) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value(null);
    }
    return FirebaseFirestore.instance
        .collection(kUsersCollection)
        .doc(user.uid)
        .snapshots();
  },
);

class PanelScreen extends ConsumerStatefulWidget {
  static const String routeName = 'panel';

  const PanelScreen({super.key});

  @override
  ConsumerState<PanelScreen> createState() => _PanelScreenState();
}

class _PanelScreenState extends ConsumerState<PanelScreen> {
  bool _redirected = false; // evita loops
  bool _bootstrapped = false; // evita bootstrap repetido

  // 🔴 CHINCHE PANEL NAME 1 — lógica inteligente de nombre
  String _nombreSeguro(String raw) {
    final clean = raw.trim();
    if (clean.isEmpty) return 'SIN NOMBRE';

    final parts =
    clean.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'SIN NOMBRE';

    final first = parts.first;
    final two = parts.length >= 2 ? '${parts[0]} ${parts[1]}' : first;

    const int largoTotal = 12;
    const int primerCorto = 5;

    if (clean.length <= largoTotal && parts.length <= 2) {
      return clean.toUpperCase();
    }

    if (first.length <= primerCorto && parts.length >= 2) {
      if (two.length > largoTotal) return first.toUpperCase();
      return two.toUpperCase();
    }

    return first.toUpperCase();
  }

  bool _isAsset(String v) => v.startsWith('assets/');
  bool _isUrl(String v) => v.startsWith('http://') || v.startsWith('https://');

  void _redirectToDatos() {
    if (_redirected) return;
    _redirected = true;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const DatosScreen()),
          (route) => false,
    );
  }

  void _redirectToSplash() {
    if (_redirected) return;
    _redirected = true;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
          (route) => false,
    );
  }

  // ✅ Resuelve foto con prioridad: URL > asset > file path
  Widget _buildFotoWidget(String? fotoValue) {
    final v = (fotoValue ?? '').trim();

    if (v.isEmpty) {
      return Image.asset(
        'assets/images/perfil1.jpg',
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
      );
    }

    if (_isUrl(v)) {
      return Image.network(
        v,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            color: Colors.black26,
            child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2)),
          );
        },
        errorBuilder: (_, __, ___) {
          return Image.asset(
            'assets/images/perfil1.jpg',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          );
        },
      );
    }

    if (_isAsset(v)) {
      return Image.asset(
        v,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
      );
    }

    return Image.file(
      File(v),
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      errorBuilder: (_, __, ___) {
        return Image.asset(
          'assets/images/perfil1.jpg',
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_bootstrapped) return;
      _bootstrapped = true;

      // ✅ Si no hay sesión, volvemos a Splash (ahí decides login/registro)
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (!mounted) return;
        _redirectToSplash();
        return;
      }

      // ✅ Bootstrap: reconstruye el provider desde Firestore tras limpiar cache
      await ref.read(profileFormProvider.notifier).bootstrapFromFirestore();
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // mismas medidas que en el resto de pantallas principales
    const double espacioBarraLogo = 35;
    const double alturaLogo = 50;
    const double espacioLogoScroll = 15;
    const double margenInferiorPantalla = 80;

    // ✅ Fallback local (por si Firestore demora / offline)
    final local = ref.watch(profileFormProvider);

    // ✅ Firestore doc del usuario (nullable)
    final userDocAsync = ref.watch(userDocProvider);

    Widget contenido = userDocAsync.when(
      data: (snap) {
        // ✅ Si snap == null => no hay sesión
        if (snap == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _redirectToSplash();
          });

          // mostramos un fallback mínimo para evitar pantalla negra 1 frame
          final fotoFallback = local.profilePhotoUrl ??
              (local.photoUrls.isNotEmpty ? local.photoUrls.first : null) ??
              (local.fotosCargadas.isNotEmpty ? local.fotosCargadas.first : null);

          return _panelScaffold(
            context: context,
            textTheme: textTheme,
            espacioBarraLogo: espacioBarraLogo,
            alturaLogo: alturaLogo,
            espacioLogoScroll: espacioLogoScroll,
            margenInferiorPantalla: margenInferiorPantalla,
            nombre: _nombreSeguro(local.nombre),
            edad: local.edad.trim().isEmpty ? '—' : local.edad.trim(),
            ubicacion: 'Sin sesión',
            fotoWidget: _buildFotoWidget(fotoFallback),
            showLoader: true,
          );
        }

        // Si no hay doc aún, usamos local sin romper UX
        if (!snap.exists) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final localOk = (local.nombre.trim().isNotEmpty &&
                local.edad.trim().isNotEmpty &&
                (local.paisSeleccionado ?? '').trim().isNotEmpty &&
                (local.ciudadSeleccionada ?? '').trim().isNotEmpty &&
                (local.fotosCargadas.isNotEmpty || local.photoUrls.isNotEmpty));
            if (!localOk) _redirectToDatos();
          });

          final fotoFallback = local.profilePhotoUrl ??
              (local.photoUrls.isNotEmpty ? local.photoUrls.first : null) ??
              (local.fotosCargadas.isNotEmpty ? local.fotosCargadas.first : null);

          final nombre = _nombreSeguro(local.nombre);
          final edad = local.edad.trim().isEmpty ? '—' : local.edad.trim();
          final pais = (local.paisSeleccionado ?? '').trim();
          final ciudad = (local.ciudadSeleccionada ?? '').trim();
          final ubicacion = (ciudad.isEmpty && pais.isEmpty)
              ? 'Sin ubicación'
              : (ciudad.isNotEmpty && pais.isNotEmpty)
              ? '$ciudad - $pais'
              : (ciudad.isNotEmpty ? ciudad : pais);

          return _panelScaffold(
            context: context,
            textTheme: textTheme,
            espacioBarraLogo: espacioBarraLogo,
            alturaLogo: alturaLogo,
            espacioLogoScroll: espacioLogoScroll,
            margenInferiorPantalla: margenInferiorPantalla,
            nombre: nombre,
            edad: edad,
            ubicacion: ubicacion,
            fotoWidget: _buildFotoWidget(fotoFallback),
            showLoader: false,
          );
        }

        final data = snap.data();

        // Si data es null, fallback local
        if (data == null) {
          final fotoFallback = local.profilePhotoUrl ??
              (local.photoUrls.isNotEmpty ? local.photoUrls.first : null) ??
              (local.fotosCargadas.isNotEmpty ? local.fotosCargadas.first : null);

          final nombre = _nombreSeguro(local.nombre);
          final edad = local.edad.trim().isEmpty ? '—' : local.edad.trim();
          final pais = (local.paisSeleccionado ?? '').trim();
          final ciudad = (local.ciudadSeleccionada ?? '').trim();
          final ubicacion = (ciudad.isEmpty && pais.isEmpty)
              ? 'Sin ubicación'
              : (ciudad.isNotEmpty && pais.isNotEmpty)
              ? '$ciudad - $pais'
              : (ciudad.isNotEmpty ? ciudad : pais);

          return _panelScaffold(
            context: context,
            textTheme: textTheme,
            espacioBarraLogo: espacioBarraLogo,
            alturaLogo: alturaLogo,
            espacioLogoScroll: espacioLogoScroll,
            margenInferiorPantalla: margenInferiorPantalla,
            nombre: nombre,
            edad: edad,
            ubicacion: ubicacion,
            fotoWidget: _buildFotoWidget(fotoFallback),
            showLoader: false,
          );
        }

        // ✅ onboarding gate
        final completed = (data['onboarding_completed'] == true);
        if (!completed) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _redirectToDatos();
          });
        }

        // ✅ Construcción sólida de datos Firestore
        final n = (data['nombre'] ?? '').toString();
        final e = data['edad'];
        final p = (data['pais'] ?? '').toString();
        final c = (data['ciudad'] ?? '').toString();

        final nombre = _nombreSeguro(n.isNotEmpty ? n : local.nombre);
        final edad = (e is int)
            ? e.toString()
            : (e?.toString().trim().isNotEmpty == true
            ? e.toString()
            : (local.edad.trim().isEmpty ? '—' : local.edad.trim()));

        final ubicacion = (c.trim().isEmpty && p.trim().isEmpty)
            ? ((local.ciudadSeleccionada ?? '').trim().isEmpty &&
            (local.paisSeleccionado ?? '').trim().isEmpty
            ? 'Sin ubicación'
            : '${(local.ciudadSeleccionada ?? '').trim()} - ${(local.paisSeleccionado ?? '').trim()}'
            .replaceAll(' - ', ' - '))
            : (c.trim().isNotEmpty && p.trim().isNotEmpty)
            ? '${c.trim()} - ${p.trim()}'
            : (c.trim().isNotEmpty ? c.trim() : p.trim());

        // ✅ FOTO: prioridad URL > local path
        final profilePhotoUrl = (data['profilePhotoUrl'] ?? '').toString().trim();
        final List<dynamic> photoUrlsDyn =
        (data['photoUrls'] is List) ? (data['photoUrls'] as List) : <dynamic>[];
        final photoUrls = photoUrlsDyn
            .map((e) => e.toString())
            .where((s) => s.trim().isNotEmpty)
            .toList();

        final profileLocal = (data['profilePhotoLocalPath'] ?? '').toString().trim();

        final fotoFinal = profilePhotoUrl.isNotEmpty
            ? profilePhotoUrl
            : (photoUrls.isNotEmpty
            ? photoUrls.first
            : (profileLocal.isNotEmpty
            ? profileLocal
            : (local.profilePhotoUrl ??
            (local.photoUrls.isNotEmpty ? local.photoUrls.first : null) ??
            (local.fotosCargadas.isNotEmpty ? local.fotosCargadas.first : null))));

        return _panelScaffold(
          context: context,
          textTheme: textTheme,
          espacioBarraLogo: espacioBarraLogo,
          alturaLogo: alturaLogo,
          espacioLogoScroll: espacioLogoScroll,
          margenInferiorPantalla: margenInferiorPantalla,
          nombre: nombre,
          edad: edad,
          ubicacion: ubicacion,
          fotoWidget: _buildFotoWidget(fotoFinal),
          showLoader: false,
        );
      },
      loading: () {
        final fotoFallback = local.profilePhotoUrl ??
            (local.photoUrls.isNotEmpty ? local.photoUrls.first : null) ??
            (local.fotosCargadas.isNotEmpty ? local.fotosCargadas.first : null);

        final nombre = _nombreSeguro(local.nombre);
        final edad = local.edad.trim().isEmpty ? '—' : local.edad.trim();
        final pais = (local.paisSeleccionado ?? '').trim();
        final ciudad = (local.ciudadSeleccionada ?? '').trim();
        final ubicacion = (ciudad.isEmpty && pais.isEmpty)
            ? 'Sin ubicación'
            : (ciudad.isNotEmpty && pais.isNotEmpty)
            ? '$ciudad - $pais'
            : (ciudad.isNotEmpty ? ciudad : pais);

        return _panelScaffold(
          context: context,
          textTheme: textTheme,
          espacioBarraLogo: espacioBarraLogo,
          alturaLogo: alturaLogo,
          espacioLogoScroll: espacioLogoScroll,
          margenInferiorPantalla: margenInferiorPantalla,
          nombre: nombre,
          edad: edad,
          ubicacion: ubicacion,
          fotoWidget: _buildFotoWidget(fotoFallback),
          showLoader: true,
        );
      },
      error: (e, _) {
        final fotoFallback = local.profilePhotoUrl ??
            (local.photoUrls.isNotEmpty ? local.photoUrls.first : null) ??
            (local.fotosCargadas.isNotEmpty ? local.fotosCargadas.first : null);

        final nombre = _nombreSeguro(local.nombre);
        final edad = local.edad.trim().isEmpty ? '—' : local.edad.trim();
        final pais = (local.paisSeleccionado ?? '').trim();
        final ciudad = (local.ciudadSeleccionada ?? '').trim();
        final ubicacion = (ciudad.isEmpty && pais.isEmpty)
            ? 'Sin ubicación'
            : (ciudad.isNotEmpty && pais.isNotEmpty)
            ? '$ciudad - $pais'
            : (ciudad.isNotEmpty ? ciudad : pais);

        return _panelScaffold(
          context: context,
          textTheme: textTheme,
          espacioBarraLogo: espacioBarraLogo,
          alturaLogo: alturaLogo,
          espacioLogoScroll: espacioLogoScroll,
          margenInferiorPantalla: margenInferiorPantalla,
          nombre: nombre,
          edad: edad,
          ubicacion: ubicacion,
          fotoWidget: _buildFotoWidget(fotoFallback),
          showLoader: false,
        );
      },
    );

    return contenido;
  }

  // ✅ Scaffold del panel (mantiene tu diseño intacto)
  Widget _panelScaffold({
    required BuildContext context,
    required TextTheme textTheme,
    required double espacioBarraLogo,
    required double alturaLogo,
    required double espacioLogoScroll,
    required double margenInferiorPantalla,
    required String nombre,
    required String edad,
    required String ubicacion,
    required Widget fotoWidget,
    required bool showLoader,
  }) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover),
          ),
          Column(
            children: [
              SizedBox(height: espacioBarraLogo),
              Image.asset('assets/images/logomatchyplano.png', height: alturaLogo),
              SizedBox(height: espacioLogoScroll),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(bottom: margenInferiorPantalla),
                  child: _PanelContent(
                    textTheme: textTheme,
                    nombre: nombre,
                    edad: edad,
                    ubicacion: ubicacion,
                    fotoWidget: fotoWidget,
                  ),
                ),
              ),
            ],
          ),
          if (showLoader)
            const Positioned(
              top: 12,
              right: 12,
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      bottomNavigationBar: const _MatchyBottomNav(currentIndex: 2),
    );
  }
}

// ===============================================================
// 🔹 CONTENIDO INTERNO DEL PANEL (DISEÑO INTACTO)
// ===============================================================
class _PanelContent extends StatelessWidget {
  final TextTheme textTheme;
  final String nombre;
  final String edad;
  final String ubicacion;
  final Widget fotoWidget;

  const _PanelContent({
    required this.textTheme,
    required this.nombre,
    required this.edad,
    required this.ubicacion,
    required this.fotoWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),

        // =========================================================
        // TARJETA PERFIL — PANEL FLUTTER PERFECTO
        // =========================================================
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          padding: const EdgeInsets.all(
            18, // 🔴 CHINCHE PANEL D — padding interno tarjeta perfil
          ),
          decoration: BoxDecoration(
            color: const Color(0x33FFFFFF),
            borderRadius: BorderRadius.circular(
              30, // 🔴 CHINCHE PANEL E — radio esquinas tarjeta perfil
            ),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(
                  20, // 🔴 CHINCHE PANEL F — radio de la foto
                ),
                child: Container(
                  width: 110, // 🔴 CHINCHE PANEL G2 — ancho foto perfil (cuadrada)
                  height: 110, // 🔴 CHINCHE PANEL H2 — alto foto perfil (cuadrada)
                  color: Colors.black26,
                  child: fotoWidget,
                ),
              ),

              const SizedBox(width: 18),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            nombre,
                            style: textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontSize: 34, // 🔴 CHINCHE PANEL J
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            edad,
                            style: textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 6),

                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.white, size: 18),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            ubicacion,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontSize: 20, // 🔴 CHINCHE PANEL K
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const DatosScreen()),
                        );
                      },
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFBEB3FF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Editar Perfil',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // =========================================================
        // SECCIÓN MORADA: ICONO CALENDARIO + 3 BOTONES
        // =========================================================
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 14, // 🔴 CHINCHE PANEL L
          ),
          decoration: BoxDecoration(
            color: const Color(0x33FFFFFF),
            borderRadius: BorderRadius.circular(
              26, // 🔴 CHINCHE PANEL M
            ),
          ),
          child: Row(
            children: [
              Image.asset(
                'assets/images/ic_calendar.png',
                width: 90,
                height: 90,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 22),
              Expanded(
                child: Column(
                  children: [
                    _BotonPanel(
                      texto: "CREAR UNA CITA",
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CrearCitaPanelScreen(nombreUsuario: nombre),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _BotonPanel(
                      texto: "BUSCAR UNA CITA",
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CitaBuscarScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _BotonPanel(
                      texto: "CITAS PUBLICADAS",
                      backgroundColor: const Color(0xFFFFC107),
                      textColor: Colors.black,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CitasPendientesScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 26),

        Text(
          "SITIOS RECOMENDADOS",
          style: textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 16),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _CategoriaPanelCard(
                      label: "RESTAURANTES",
                      imageAsset: 'assets/images/iconorestaurante.png',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const RestaurantesScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CategoriaPanelCard(
                      label: "BARES",
                      imageAsset: 'assets/images/iconobares.png',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const BaresScreen()),
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
                    child: _CategoriaPanelCard(
                      label: "CAFÉS",
                      imageAsset: 'assets/images/iconocafeteria.png',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CafesScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CategoriaPanelCard(
                      label: "ACTIVIDADES",
                      imageAsset: 'assets/images/iconoactividades.png',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ActividadesScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 80),
      ],
    );
  }
}

// ===========================================================
// 🔹 BOTÓN PANEL
// ===========================================================
class _BotonPanel extends StatelessWidget {
  final String texto;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? textColor;

  const _BotonPanel({
    required this.texto,
    required this.onTap,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: backgroundColor ?? const Color(0xFFBEB3FF),
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.center,
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textColor ?? Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

// ===========================================================
// 🔹 TARJETA INDIVIDUAL DEL GRID
// ===========================================================
class _CategoriaPanelCard extends StatelessWidget {
  final String label;
  final String imageAsset;
  final VoidCallback onTap;

  const _CategoriaPanelCard({
    required this.label,
    required this.imageAsset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 120,
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
                image: AssetImage(imageAsset),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================
// 🔹 BARRA DE NAVEGACIÓN INFERIOR LOCAL PARA PANEL
// ===========================================================
class _MatchyBottomNav extends StatelessWidget {
  final int currentIndex; // 0 Perfil, 1 Citas, 2 Panel, 3 Matchy, 4 Chat

  const _MatchyBottomNav({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    const Color navBackground = Color(0xFF000000);
    const Color selectedColor = Color(0xFFE0D4FF);
    final Color unselectedColor = Colors.white54;

    return BottomNavigationBar(
      backgroundColor: navBackground,
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      selectedItemColor: selectedColor,
      unselectedItemColor: unselectedColor,
      selectedFontSize: 10,
      unselectedFontSize: 10,
      showUnselectedLabels: true,
      selectedLabelStyle: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
      ),
      items: [
        _navItem(
          asset: 'assets/images/profile.png',
          label: 'PERFIL',
          isSelected: currentIndex == 0,
        ),
        _navItem(
          asset: 'assets/images/citas.png',
          label: 'CITAS',
          isSelected: currentIndex == 1,
        ),
        _navItem(
          asset: 'assets/images/panel.png',
          label: 'PANEL',
          isSelected: currentIndex == 2,
        ),
        _navItem(
          asset: 'assets/images/matchy.png',
          label: 'MATCHY',
          isSelected: currentIndex == 3,
        ),
        _navItem(
          asset: 'assets/images/chat.png',
          label: 'CHAT',
          isSelected: currentIndex == 4,
        ),
      ],
      onTap: (index) {
        if (index == currentIndex) return;

        Widget dest;
        switch (index) {
          case 0:
            dest = const PerfilScreen(showBottomNav: true);
            break;
          case 1:
            dest = const CitasScreen();
            break;
          case 2:
            dest = const PanelScreen();
            break;
          case 3:
            dest = const MatchysScreen();
            break;
          default:
            dest = const ChatScreen();
        }

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => dest),
              (route) => false,
        );
      },
    );
  }

  static BottomNavigationBarItem _navItem({
    required String asset,
    required String label,
    required bool isSelected,
  }) {
    const double unselectedSize = 20;
    const double selectedSize = 24;

    Widget icon;
    if (isSelected) {
      icon = SizedBox(
        height: selectedSize,
        child: Center(
          child: ColorFiltered(
            colorFilter: const ColorFilter.mode(
              Color(0xFFE0D4FF),
              BlendMode.srcIn,
            ),
            child: Image.asset(
              asset,
              width: selectedSize,
              height: selectedSize,
            ),
          ),
        ),
      );
    } else {
      icon = SizedBox(
        height: selectedSize,
        child: Center(
          child: Image.asset(
            asset,
            width: unselectedSize,
            height: unselectedSize,
          ),
        ),
      );
    }

    return BottomNavigationBarItem(
      icon: icon,
      label: label,
    );
  }
}
