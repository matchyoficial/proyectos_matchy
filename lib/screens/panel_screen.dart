// 📂 lib/screens/panel_screen.dart
// ✅ PANEL CENTRAL BLINDADO (SMART LOADING ACTIVADO)
// 🔥 FIX: Implementada "Carga Inteligente". Muestra datos inmediatos si existen, spinner solo si está vacío.
// 🔥 ADD: Nueva tarjeta "GUÍA RÁPIDA DE REPORTE" con iconos personalizados.
// 🔥 UI: Diseño original intacto.
// 🔥 INTEGRACIÓN: Diseño Golden Ticket y navegación a CitasPendientesDetalle.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proyectos_matchy/screens/home_shell.dart';
import 'package:proyectos_matchy/screens/splash_screen.dart';
import 'package:proyectos_matchy/screens/datos_screen.dart';
import 'package:proyectos_matchy/state/profile_form_provider.dart';
import 'package:proyectos_matchy/models/lugar_data.dart';
import 'package:proyectos_matchy/widgets/termometro_confiabilidad.dart';

import 'package:proyectos_matchy/screens/crear_cita_panel_screen.dart';
import 'package:proyectos_matchy/screens/cita_buscar.dart';
import 'package:proyectos_matchy/screens/citas_pendientes_screen.dart';
import 'package:proyectos_matchy/screens/citas_pendientes_detalle.dart'; // 🔥 Import para Golden Ticket
import 'package:proyectos_matchy/screens/restaurantes_screen.dart';
import 'package:proyectos_matchy/screens/bares_screen.dart';
import 'package:proyectos_matchy/screens/cafes_screen.dart';
import 'package:proyectos_matchy/screens/actividades_screen.dart';
import 'package:proyectos_matchy/screens/reprogramar_cita_aceptar_screen.dart';
import 'package:proyectos_matchy/screens/nueva_cita_solicitud_screen.dart';
import 'package:proyectos_matchy/screens/lugar_plantilla_screen.dart';

// =============================================================================
// 🔔 LÓGICA DE NOTIFICACIONES
// =============================================================================

final unreadNotificationsProvider = StreamProvider<int>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return const Stream.empty();
  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('notifications')
      .where('read', isEqualTo: false)
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
});

final notificationsListProvider = StreamProvider<List<DocumentSnapshot>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return const Stream.empty();
  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('notifications')
      .orderBy('createdAt', descending: true)
      .limit(20)
      .snapshots()
      .map((snapshot) => snapshot.docs);
});

class NotificationLogic {
  static Future<void> markAsRead(String notificationId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('notifications').doc(notificationId).update({'read': true});
  }

  static Future<void> deleteNotification(String notificationId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('notifications').doc(notificationId).delete();
  }

  // 🔥 CHECK INTELIGENTE: Verifica estado de la cita antes de navegar
  static Future<void> handleTap(BuildContext context, String docId, String type, String? citaId) async {
    // 1. Borrar notificación visualmente para que no estorbe (AUTODESTRUCCIÓN)
    deleteNotification(docId);
    Navigator.pop(context); // Cerrar sheet

    if (citaId == null) return;

    // 🔥 CASO GOLDEN TICKET: Navegación directa al detalle
    if (type == 'golden_ticket') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => CitasPendientesDetalleScreen(citaId: citaId)));
      return;
    }

    // 2. Casos Informativos (Solo ir a la pestaña Citas)
    if (type == 'cita_aceptada' || type == 'repro_accepted') {
      HomeShell.go(context, index: 1); // Ir a Mis Citas
      return;
    }

    // 3. Casos de Acción (Invitación o Reprogramación)
    if (type == 'invitacion_cita' || type == 'repro_request') {
      try {
        // ⏳ Check de Estado en Firestore
        final doc = await FirebaseFirestore.instance.collection('citas').doc(citaId).get();
        if (!doc.exists) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Esta cita ya no existe.")));
          return;
        }

        final data = doc.data()!;
        final status = data['status'];

        // LÓGICA DE DESVÍO
        if (status == 'scheduled') {
          // Ya fue aceptada -> Ir a Mis Citas
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Ya aceptaste esta cita!")));
          HomeShell.go(context, index: 1);
        } else if (status == 'cancelled' || status == 'rechazada') {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Esta cita fue cancelada.")));
        } else {
          // Sigue pendiente -> Navegar a la pantalla de decisión
          if (type == 'invitacion_cita') {
            Navigator.push(context, MaterialPageRoute(builder: (_) => NuevaCitaSolicitudScreen(citaId: citaId)));
          } else if (type == 'repro_request') {
            Navigator.push(context, MaterialPageRoute(builder: (_) => ReprogramarCitaAceptarScreen(citaId: citaId)));
          }
        }
      } catch (e) {
        // Error silencioso, solo ir a citas
        HomeShell.go(context, index: 1);
      }
    }
  }
}

// =============================================================================
// PANEL SCREEN
// =============================================================================

const String kUsersCollection = 'users';

final userDocProvider = StreamProvider<DocumentSnapshot<Map<String, dynamic>>?>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(null);
  return FirebaseFirestore.instance.collection(kUsersCollection).doc(user.uid).snapshots();
});

class PanelScreen extends ConsumerStatefulWidget {
  static const String routeName = 'panel';
  final bool showBottomNav;

  const PanelScreen({super.key, this.showBottomNav = true});

  @override
  ConsumerState<PanelScreen> createState() => _PanelScreenState();
}

class _PanelScreenState extends ConsumerState<PanelScreen> {
  // ===========================================================================
  // 🛡️ CONSTANTES DE DISEÑO (NO TOCAR)
  // ===========================================================================

  static const Color kCardBackground   = Color(0x4FFFFFFF);
  static const Color kSheetTopColor    = Color(0xFF2E1A47);
  static const Color kSheetBottomColor = Colors.black;

  static const List<Color> kNotifGradient = [Color(0xFF4A3B75), Color(0xFF1F1F1F)];

  // 🔥 GRADIENTE GOLDEN TICKET
  static const List<Color> kGoldenGradient = [Color(0xFFFFC107), Color(0xFFFFD54F)];

  static const double kNotifRadius = 22.0;
  static const List<BoxShadow> kNotifShadow = [BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 4))];

  static const List<BoxShadow> kCardShadow = [BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 5))];

  static const List<Color> kPremiumButtonGradient = [Color(0xFF7E208E), Color(0xFC4B3F60)];
  static const List<Color> kDisabledButtonGradient = [Color(0xFF424242), Color(0xFF212121)];
  static const List<Color> kBtnPublishedGradient = [Color(0xFF145977), Color(0xFF0277BD)];

  static const double kPremiumButtonRadius = 18.0;
  static const BorderSide kPremiumButtonBorder = BorderSide(color: Colors.white24, width: 1.0);
  static const List<BoxShadow> kPremiumButtonShadow = [BoxShadow(color: Colors.black54, blurRadius: 2, offset: Offset(0, 4))];

  static const List<Shadow> kTextShadow = [
    Shadow(color: Colors.black, blurRadius: 10, offset: Offset(0, 4))
  ];

  bool _bootstrapped = false;
  bool _sentToShell = false;

  String _nombreSeguro(String raw) {
    final clean = raw.trim();
    if (clean.isEmpty) return 'SIN NOMBRE';
    final parts = clean.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'SIN NOMBRE';
    return parts.first.toUpperCase();
  }

  bool _isAsset(String v) => v.startsWith('assets/');
  bool _isUrl(String v) => v.startsWith('http://') || v.startsWith('https://');

  void _redirectToDatos() => Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const DatosScreen()), (route) => false);
  void _redirectToSplash() => Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const SplashScreen()), (route) => false);

  Widget _buildFotoWidget(String? fotoValue) {
    final v = (fotoValue ?? '').trim();
    if (v.isEmpty) return Image.asset('assets/images/perfil1.jpg', fit: BoxFit.cover, alignment: Alignment.topCenter);
    if (_isUrl(v)) return Image.network(v, fit: BoxFit.cover, alignment: Alignment.topCenter, errorBuilder: (_, __, ___) => Image.asset('assets/images/perfil1.jpg', fit: BoxFit.cover));
    if (_isAsset(v)) return Image.asset(v, fit: BoxFit.cover, alignment: Alignment.topCenter);
    return Image.file(File(v), fit: BoxFit.cover, alignment: Alignment.topCenter, errorBuilder: (_, __, ___) => Image.asset('assets/images/perfil1.jpg', fit: BoxFit.cover));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.showBottomNav == true && _sentToShell == false) {
        _sentToShell = true;
        if (!mounted) return;
        HomeShell.go(context, index: 2);
        return;
      }
      if (_bootstrapped) return;
      _bootstrapped = true;
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) { if (!mounted) return; _redirectToSplash(); return; }
      await ref.read(profileFormProvider.notifier).bootstrapFromFirestore();
    });
  }

  void _mostrarNotificaciones(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _NotificacionesSheet(),
    );
  }

  void _mostrarInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _InfoSheet(),
    );
  }

  void _abrirBuscador() {
    showSearch(
      context: context,
      delegate: _LugarSearchDelegate(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final local = ref.watch(profileFormProvider);
    final userDocAsync = ref.watch(userDocProvider);
    final unreadCount = ref.watch(unreadNotificationsProvider).value ?? 0;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover)),

          Column(
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Image.asset('assets/images/logomatchyplano.png', height: 45),

                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => _mostrarInfo(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                              child: const Icon(Icons.info_outline, color: Colors.white, size: 28),
                            ),
                          ),
                          const SizedBox(width: 12),

                          GestureDetector(
                            onTap: _abrirBuscador,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                              child: const Icon(Icons.search, color: Colors.white, size: 28),
                            ),
                          ),
                          const SizedBox(width: 12),

                          GestureDetector(
                            onTap: () => _mostrarNotificaciones(context),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 32),
                                if (unreadCount > 0)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(color: Color(0xFFFF4D6D), shape: BoxShape.circle),
                                      child: Text(
                                        unreadCount > 9 ? '9+' : '$unreadCount',
                                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 80),
                  child: Builder(
                    builder: (context) {
                      // 🔥 SMART LOADING: Estrategia "Datos Primero"
                      // 1. Si está cargando y NO hay datos en memoria -> Spinner
                      if (userDocAsync.isLoading && !userDocAsync.hasValue) {
                        return const Center(child: CircularProgressIndicator(color: Colors.white));
                      }

                      // 2. Si hay error y no hay datos -> Nada
                      if (userDocAsync.hasError && !userDocAsync.hasValue) {
                        return const SizedBox();
                      }

                      // 3. Si llegamos aquí, usamos los datos (frescos o en caché)
                      final snap = userDocAsync.value;

                      // --- LÓGICA DE RENDERIZADO ORIGINAL ---
                      final data = snap?.data();
                      final completed = (data?['onboarding_completed'] == true);
                      if (snap != null && snap.exists && !completed) {
                        WidgetsBinding.instance.addPostFrameCallback((_) => _redirectToDatos());
                        return const SizedBox();
                      }

                      final n = (data?['nombre'] ?? '').toString();
                      final nombre = _nombreSeguro(n.isNotEmpty ? n : local.nombre);
                      final edad = (data?['edad']?.toString() ?? (local.edad.isNotEmpty ? local.edad : '—'));
                      final ciudad = (data?['ciudad'] ?? local.ciudadSeleccionada ?? '').toString();
                      final pais = (data?['pais'] ?? local.paisSeleccionado ?? '').toString();
                      final ubicacion = ciudad.isNotEmpty ? "$ciudad - $pais" : "Ubicación pendiente";

                      final profilePhotoUrl = (data?['profilePhotoUrl'] ?? '').toString();
                      final localPhoto = (data?['profilePhotoLocalPath'] ?? '').toString();
                      final fotoFinal = profilePhotoUrl.isNotEmpty ? profilePhotoUrl : (localPhoto.isNotEmpty ? localPhoto : 'assets/images/perfil1.jpg');

                      final puntaje = (data?['confiabilidad'] as num?)?.toInt() ?? 100;
                      final userStatus = (data?['userStatus'] ?? 'active').toString();
                      final strikes = (data?['strikes'] as num?)?.toInt() ?? 0;
                      final bloqueadoHastaTimestamp = data?['bloqueadoHasta'] as Timestamp?;
                      final racha = (data?['citas_consecutivas_exitosas'] as num?)?.toInt() ?? 0;

                      return _PanelContent(
                        textTheme: textTheme,
                        nombre: nombre,
                        edad: edad,
                        ubicacion: ubicacion,
                        fotoWidget: _buildFotoWidget(fotoFinal),
                        puntaje: puntaje,
                        userStatus: userStatus,
                        strikes: strikes,
                        bloqueadoHasta: bloqueadoHastaTimestamp?.toDate(),
                        racha: racha,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),

          Positioned(
            bottom: 0, left: 0, right: 0, height: 80,
            child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.95)]))),
          ),
        ],
      ),
      bottomNavigationBar: null,
    );
  }
}

class _PanelContent extends StatelessWidget {
  final TextTheme textTheme;
  final String nombre;
  final String edad;
  final String ubicacion;
  final Widget fotoWidget;
  final int puntaje;
  final String userStatus;
  final int strikes;
  final DateTime? bloqueadoHasta;
  final int racha;

  const _PanelContent({
    required this.textTheme,
    required this.nombre,
    required this.edad,
    required this.ubicacion,
    required this.fotoWidget,
    required this.puntaje,
    required this.userStatus,
    required this.strikes,
    this.bloqueadoHasta,
    required this.racha,
  });

  bool get _estaBloqueado {
    if (userStatus == 'blocked' || userStatus == 'blocked_permanent') {
      if (bloqueadoHasta != null) return bloqueadoHasta!.isAfter(DateTime.now());
      return true;
    }
    return false;
  }

  DateTime? get _fechaParaTermometro {
    if (!_estaBloqueado) return null;
    return bloqueadoHasta;
  }

  void _ejecutarAccion(BuildContext context, VoidCallback accion) {
    if (_estaBloqueado) {
      final dias = strikes * 5;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.lock_outline, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(child: Text(
                    "ACCESO RESTRINGIDO. Tienes $strikes strike(s). Debes esperar $dias días o resolver tus citas pendientes.",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)
                )),
              ],
            ),
            backgroundColor: const Color(0xFFC62828),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(20),
            duration: const Duration(seconds: 4),
          )
      );
    } else {
      accion();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool bloqueado = _estaBloqueado;

    return Column(
      children: [
        const SizedBox(height: 10),
        // PERFIL
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: _PanelScreenState.kCardBackground, borderRadius: BorderRadius.circular(30), boxShadow: _PanelScreenState.kCardShadow),
          child: Row(children: [
            // FOTO IZQUIERDA
            ClipRRect(borderRadius: BorderRadius.circular(20), child: Container(width: 110, height: 110, color: Colors.black26, child: fotoWidget)),
            const SizedBox(width: 18),

            // COLUMNA DERECHA
            Expanded(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // NOMBRE Y EDAD BLINDADOS
                    FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Row(children: [Text(nombre, style: textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, shadows: _PanelScreenState.kTextShadow)), const SizedBox(width: 8), Text(edad, style: textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, shadows: _PanelScreenState.kTextShadow))])),

                    const SizedBox(height: 12),

                    // 🔥 BARRA RACHAS
                    _buildRachaWideBar(racha),

                    const SizedBox(height: 8),

                    // 🔥 BOTÓN EDITAR PERFIL
                    GestureDetector(
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DatosScreen())),
                        child: Container(
                            height: 35,
                            decoration: BoxDecoration(
                                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: _PanelScreenState.kPremiumButtonGradient),
                                borderRadius: BorderRadius.circular(_PanelScreenState.kPremiumButtonRadius),
                                border: Border.fromBorderSide(_PanelScreenState.kPremiumButtonBorder),
                                boxShadow: _PanelScreenState.kPremiumButtonShadow
                            ),
                            alignment: Alignment.center,
                            child: const FittedBox(fit: BoxFit.scaleDown, child: Text('EDITAR PERFIL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)))
                        )
                    ),
                  ]
              ),
            )
          ]),
        ),

        // TERMÓMETRO
        TermometroConfiabilidad(
          puntaje: puntaje,
          fechaDesbloqueo: _fechaParaTermometro,
        ),

        const SizedBox(height: 10),

        // ACCIONES
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(color: _PanelScreenState.kCardBackground, borderRadius: BorderRadius.circular(26), boxShadow: _PanelScreenState.kCardShadow),
          child: Row(children: [
            Image.asset('assets/images/ic_calendar.png', width: 90, height: 90, fit: BoxFit.contain),
            const SizedBox(width: 22),
            Expanded(child: Column(children: [

              _BotonPanelPremium(
                  texto: "CREAR UNA CITA",
                  bloqueado: bloqueado,
                  onTap: () => _ejecutarAccion(context, () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => CrearCitaPanelScreen(nombreUsuario: nombre)));
                  })
              ),
              const SizedBox(height: 12),

              _BotonPanelPremium(
                  texto: "BUSCAR UNA CITA",
                  bloqueado: bloqueado,
                  onTap: () => _ejecutarAccion(context, () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CitaBuscarScreen()));
                  })
              ),
              const SizedBox(height: 12),

              _BotonPanelPremium(
                  texto: "CITAS PUBLICADAS",
                  bloqueado: false,
                  customGradient: _PanelScreenState.kBtnPublishedGradient,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CitasPendientesScreen()))
              ),
            ]))
          ]),
        ),
        const SizedBox(height: 26),
        FittedBox(fit: BoxFit.scaleDown, child: Text("SITIOS RECOMENDADOS", style: textTheme.titleMedium?.copyWith(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 0.5, shadows: _PanelScreenState.kTextShadow))),
        const SizedBox(height: 16),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(children: [
            Row(children: [
              Expanded(child: _CategoriaPanelCard(label: "RESTAURANTES", imageAsset: 'assets/images/iconorestaurante.png', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RestaurantesScreen())))),
              const SizedBox(width: 12),
              Expanded(child: _CategoriaPanelCard(label: "BARES", imageAsset: 'assets/images/iconobares.png', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BaresScreen())))),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _CategoriaPanelCard(label: "CAFÉS", imageAsset: 'assets/images/iconocafeteria.png', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CafesScreen())))),
              const SizedBox(width: 12),
              Expanded(child: _CategoriaPanelCard(label: "ACTIVIDADES", imageAsset: 'assets/images/iconoactividades.png', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ActividadesScreen())))),
            ]),
          ]),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildRachaWideBar(int count) {
    return Container(
      height: 35,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(_PanelScreenState.kPremiumButtonRadius),
        border: Border.all(color: Colors.white10),
        boxShadow: _PanelScreenState.kPremiumButtonShadow,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: const Text("RACHAS", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)))),

          Row(
            children: [
              _buildSingleFire(count >= 1),
              const SizedBox(width: 2),
              _buildSingleFire(count >= 2),
              const SizedBox(width: 2),
              _buildSingleFire(count >= 3),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSingleFire(bool active) {
    return ColorFiltered(
      colorFilter: active
          ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
          : const ColorFilter.matrix(<double>[
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0,      0,      0,      1, 0,
      ]),
      child: const Text("🔥", style: TextStyle(fontSize: 16)),
    );
  }
}

class _BotonPanelPremium extends StatelessWidget {
  final String texto;
  final VoidCallback onTap;
  final bool bloqueado;
  final List<Color>? customGradient;

  const _BotonPanelPremium({
    required this.texto,
    required this.onTap,
    this.bloqueado = false,
    this.customGradient,
  });

  @override
  Widget build(BuildContext context) {
    List<Color> gradientColors;
    if (bloqueado) {
      gradientColors = _PanelScreenState.kDisabledButtonGradient;
    } else {
      gradientColors = customGradient ?? _PanelScreenState.kPremiumButtonGradient;
    }

    return GestureDetector(
        onTap: onTap,
        child: Container(
            height: 44,
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColors
                ),
                borderRadius: BorderRadius.circular(_PanelScreenState.kPremiumButtonRadius),
                border: Border.fromBorderSide(_PanelScreenState.kPremiumButtonBorder),
                boxShadow: _PanelScreenState.kPremiumButtonShadow
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (bloqueado) ...[
                    const Icon(Icons.lock, color: Colors.white54, size: 16),
                    const SizedBox(width: 8),
                  ],
                  Text(
                      texto,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          letterSpacing: 0.5
                      )
                  ),
                ],
              ),
            )
        )
    );
  }
}

class _CategoriaPanelCard extends StatelessWidget {
  final String label;
  final String imageAsset;
  final VoidCallback onTap;

  const _CategoriaPanelCard({required this.label, required this.imageAsset, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            height: 110,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 1, offset: Offset(0, 9))],
              image: DecorationImage(image: AssetImage(imageAsset), fit: BoxFit.cover),
            ),
          ),
          Container(
            height: 110,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                stops: const [0.5, 1.0],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
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

class _InfoSheet extends StatelessWidget {
  const _InfoSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_PanelScreenState.kSheetTopColor, _PanelScreenState.kSheetBottomColor]),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, -5))]
      ),
      child: Column(
        children: [
          const SizedBox(height: 15),
          Container(width: 50, height: 6, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 20),
          const FittedBox(fit: BoxFit.scaleDown, child: Text("CÓMO FUNCIONA MATCHY", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, fontFamily: 'Poppins', letterSpacing: 1.0))),
          const SizedBox(height: 15),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  _buildInfoCard(
                      icon: Icons.local_fire_department,
                      iconColor: Colors.orangeAccent,
                      title: "PRENDE TU RACHA",
                      gradient: [const Color(0xFFEF6C00).withOpacity(0.2), Colors.black45],
                      borderColor: Colors.orangeAccent,
                      content: [
                        _buildBullet("Asiste y Confirma: Completa tus citas y asegúrate de validar el código con tu Matchy."),
                        _buildBullet("Suma Fuegos:\n   Cita 1: 🔥 (Vas bien)\n   Cita 2: 🔥🔥 (¡Casi lo tienes!)\n   Cita 3: 🔥🔥🔥 (¡VICTORIA!)"),
                        _buildBullet("El Premio: Al completar la 3ra cita consecutiva, ganas automáticamente +20 Puntos de Puntualidad y tu racha se reinicia."),
                      ]
                  ),
                  const SizedBox(height: 20),

                  // 🔥 NUEVA TARJETA: GUÍA RÁPIDA DE REPORTE (AÑADIDA AQUÍ)
                  _buildInfoCard(
                      icon: Icons.assignment, // Icono genérico de reporte/reglas
                      iconColor: const Color(0xFFB39DDB), // Lila claro
                      title: "GUÍA RÁPIDA DE REPORTE",
                      gradient: [const Color(0xFF673AB7).withOpacity(0.2), Colors.black45], // Degradado morado oscuro
                      borderColor: const Color(0xFFB39DDB),
                      content: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Icon(Icons.location_on, color: Color(0xFF00E676), size: 20), // Verde
                            const SizedBox(width: 10),
                            Expanded(child: RichText(text: const TextSpan(style: TextStyle(fontFamily: 'Poppins', fontSize: 13, height: 1.3), children: [
                              TextSpan(text: "VALIDACIÓN POR GPS: ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                              TextSpan(text: "Protege tus puntos al 100%.", style: TextStyle(color: Colors.white70)),
                            ]))),
                          ]),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Icon(Icons.handshake, color: Color(0xFF29B6F6), size: 20), // Azul
                            const SizedBox(width: 10),
                            Expanded(child: RichText(text: const TextSpan(style: TextStyle(fontFamily: 'Poppins', fontSize: 13, height: 1.3), children: [
                              TextSpan(text: "ACUERDO MUTUO: ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                              TextSpan(text: "Salida negociada. -10 Pts c/u. Sin bloqueos.", style: TextStyle(color: Colors.white70)),
                            ]))),
                          ]),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 0),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Icon(Icons.cancel, color: Color(0xFFFF5252), size: 20), // Rojo
                            const SizedBox(width: 10),
                            Expanded(child: RichText(text: const TextSpan(style: TextStyle(fontFamily: 'Poppins', fontSize: 13, height: 1.3), children: [
                              TextSpan(text: "ASUMO MI FALTA: ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                              TextSpan(text: "Cancelación unilateral. -20 Pts + Strike (Genera BLOQUEO TEMPORAL).", style: TextStyle(color: Colors.white70)),
                            ]))),
                          ]),
                        ),
                      ]
                  ),
                  const SizedBox(height: 20),

                  _buildInfoCard(
                      icon: Icons.block,
                      iconColor: Colors.redAccent,
                      title: "NO TE CONGELES",
                      gradient: [const Color(0xFFB71C1C).withOpacity(0.2), Colors.black45],
                      borderColor: Colors.redAccent,
                      content: [
                        _buildBullet("Si cancelas una cita o dejas plantado a tu Matchy, recibes un Strike ❌."),
                        const SizedBox(height: 10),
                        _buildStrikeRow("1 Strike", "5 Días de Bloqueo"),
                        _buildStrikeRow("2 Strikes", "10 Días de Bloqueo"),
                        _buildStrikeRow("3 Strikes", "15 Días de Bloqueo"),
                        _buildStrikeRow("4 Strikes", "20 Días de Bloqueo"),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                          decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.redAccent)),
                          child: const Text("💀 5 STRIKES = BLOQUEO DEFINITIVO DE LA APP", textAlign: TextAlign.center, style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900, fontSize: 13)),
                        ),
                      ]
                  ),
                  const SizedBox(height: 20),

                  _buildInfoCard(
                      icon: Icons.security,
                      iconColor: Colors.cyanAccent,
                      title: "TU SEGURIDAD PRIMERO",
                      gradient: [const Color(0xFF0097A7).withOpacity(0.2), Colors.black45],
                      borderColor: Colors.cyanAccent,
                      content: [
                        _buildBullet("Lugar Público: Mantén tu primera cita siempre en sitios concurridos."),
                        _buildBullet("Comparte: Avísale a un amigo o familiar dónde estarás."),
                        _buildBullet("El Código: Nunca des tu 'Código de Cita' por chat. Solo entrégalo en persona."),
                        _buildBullet("Instinto: Si algo no se siente bien, puedes irte, ponerte en contacto con el personal de seguridad del sitio o comunicarte a la linea de emergencia #123. No estás obligado a quedarte."),
                      ]
                  ),

                  const SizedBox(height: 30),

                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        "RECUERDA QUE EN MATCHY,\nEL QUE INVITA PAGA",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Color(0xFFBEB3FF),
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: 1.0,
                            fontFamily: 'Poppins'
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required Color iconColor, required String title, required List<Color> gradient, required Color borderColor, required List<Widget> content}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradient),
          border: Border.all(color: borderColor.withOpacity(0.5), width: 1.5)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 28),
              const SizedBox(width: 10),
              Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5)))),
            ],
          ),
          const SizedBox(height: 12),
          ...content,
        ],
      ),
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• ", style: TextStyle(color: Colors.white54, fontSize: 16)),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4))),
        ],
      ),
    );
  }

  Widget _buildStrikeRow(String strike, String penalty) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0, left: 10),
      child: Row(
        children: [
          Text(strike, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          const Text(" = ", style: TextStyle(color: Colors.white54)),
          Text(penalty, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }
}

// ... _NotificacionesSheet (BLINDADA)
class _NotificacionesSheet extends ConsumerWidget {
  const _NotificacionesSheet();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificacionesAsync = ref.watch(notificationsListProvider);
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_PanelScreenState.kSheetTopColor, _PanelScreenState.kSheetBottomColor]), borderRadius: const BorderRadius.vertical(top: Radius.circular(30)), boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, -5))]),
      child: Column(
        children: [
          const SizedBox(height: 15), Container(width: 50, height: 6, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))), const SizedBox(height: 20), const FittedBox(fit: BoxFit.scaleDown, child: Text("NOTIFICACIONES", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, fontFamily: 'Poppins', letterSpacing: 1.0))), const SizedBox(height: 15),
          Expanded(child: notificacionesAsync.when(loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFBEB3FF))), error: (_, __) => const Center(child: Text("Error cargando notificaciones", style: TextStyle(color: Colors.white54))), data: (docs) { if (docs.isEmpty) return const Center(child: Text("No tienes notificaciones nuevas.", style: TextStyle(color: Colors.white38, fontFamily: 'Poppins'))); return ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: docs.length, itemBuilder: (context, index) { final data = docs[index].data() as Map<String, dynamic>; final docId = docs[index].id; final leido = data['read'] == true; final titulo = data['title'] ?? 'Notificación'; final cuerpo = data['body'] ?? ''; final type = data['type'] ?? ''; final citaId = data['citaId'];

          // 🔥 DISEÑO GOLDEN TICKET
          if (type == 'golden_ticket') {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: _PanelScreenState.kGoldenGradient),
                borderRadius: BorderRadius.circular(_PanelScreenState.kNotifRadius),
                boxShadow: _PanelScreenState.kNotifShadow,
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                leading: const CircleAvatar(backgroundColor: Colors.black, child: Icon(Icons.star, color: Color(0xFFFFC107))),
                title: Text(titulo, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 15)),
                subtitle: Text(cuerpo, style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.chevron_right, color: Colors.black45),
                onTap: () => NotificationLogic.handleTap(context, docId, type, citaId),
              ),
            );
          }

          IconData icono = Icons.notifications_rounded; if (type == 'repro_request' || type == 'invitacion_cita') icono = Icons.calendar_month_rounded; if (type == 'repro_accepted' || type == 'cita_aceptada') icono = Icons.check_circle_rounded; return Dismissible(key: Key(docId), direction: DismissDirection.endToStart, background: Container(margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Colors.red.withOpacity(0.8), borderRadius: BorderRadius.circular(_PanelScreenState.kNotifRadius)), alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete_outline, color: Colors.white)), onDismissed: (_) => NotificationLogic.deleteNotification(docId), child: Container(margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: _PanelScreenState.kNotifGradient), borderRadius: BorderRadius.circular(_PanelScreenState.kNotifRadius), border: leido ? Border.all(color: Colors.white.withOpacity(0.05)) : Border.all(color: const Color(0xFFBEB3FF).withOpacity(0.5), width: 1.5), boxShadow: _PanelScreenState.kNotifShadow), child: ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), leading: CircleAvatar(backgroundColor: leido ? Colors.white10 : const Color(0xFF6B4EE6), child: Icon(icono, color: Colors.white)), title: Text(titulo, style: TextStyle(color: Colors.white, fontWeight: leido ? FontWeight.normal : FontWeight.bold, fontSize: 15)), subtitle: Padding(padding: const EdgeInsets.only(top: 4), child: Text(cuerpo, style: const TextStyle(color: Colors.white70, fontSize: 13))), trailing: const Icon(Icons.chevron_right, color: Colors.white38),
              onTap: () => NotificationLogic.handleTap(context, docId, type, citaId) // 🔥 USO DEL MANEJADOR INTELIGENTE
          ))); }); })),
        ],
      ),
    );
  }
}

class _LugarSearchDelegate extends SearchDelegate {
  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white54),
        border: InputBorder.none,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: Colors.white, fontSize: 18),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: Color(0xFF00B0FF),
        selectionColor: Color(0xFF7E208E),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        )
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildResultsList(context, query);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.length < 3) {
      return Container(
        color: const Color(0xFF2E1A47),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search, size: 60, color: Colors.white24),
              SizedBox(height: 10),
              Text("Busca tus lugares favoritos...", style: TextStyle(color: Colors.white54)),
            ],
          ),
        ),
      );
    }
    return _buildResultsList(context, query);
  }

  Widget _buildResultsList(BuildContext context, String searchQuery) {
    final term = searchQuery.toLowerCase().trim();

    return Container(
      color: const Color(0xFF2E1A47),
      child: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance.collection('lugares').get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.white));

          final docs = snapshot.data!.docs;

          final exactos = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final nombre = (data['nombre'] ?? '').toString().toLowerCase();
            return nombre.contains(term);
          }).toList();

          List<QueryDocumentSnapshot> similares = [];
          if (exactos.isEmpty) {
            similares = docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final tipos = List.from(data['tipos'] ?? []);
              return tipos.any((t) => t.toString().toLowerCase().contains(term));
            }).toList();
          }

          final resultados = exactos.isNotEmpty ? exactos : similares;
          final esRecomendacion = exactos.isEmpty && similares.isNotEmpty;

          if (resultados.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.sentiment_dissatisfied, size: 60, color: Colors.white24),
                  const SizedBox(height: 10),
                  Text('No encontramos "$searchQuery"', style: const TextStyle(color: Colors.white)),
                ],
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (esRecomendacion)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "No encontramos '$searchQuery', pero mira estos similares:",
                    style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold),
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: resultados.length,
                  itemBuilder: (context, index) {
                    final doc = resultados[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final lugar = LugarData.fromMap(id: doc.id, data: data);

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          lugar.fotoPortada,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (_,__,___) => Container(width: 60, height: 60, color: Colors.grey),
                        ),
                      ),
                      title: Text(
                          lugar.nombre,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                      ),
                      subtitle: Text(
                          lugar.direccion,
                          style: const TextStyle(color: Colors.white54, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis
                      ),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => LugarPlantillaScreen(lugar: lugar)));
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}