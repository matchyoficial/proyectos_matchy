// 📂 lib/screens/panel_screen.dart
// ✅ PANEL CENTRAL (DISEÑO FINAL)
// 🔥 FIX: Notificaciones se ELIMINAN al hacer click para evitar dobles activaciones.
// 🔥 UI: Diseño Intacto (Categorías con título dentro + Degradado + Sombra).

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proyectos_matchy/screens/home_shell.dart';
import 'package:proyectos_matchy/screens/splash_screen.dart';
import 'package:proyectos_matchy/screens/datos_screen.dart';
import 'package:proyectos_matchy/state/profile_form_provider.dart';

// PANTALLAS DE NAVEGACIÓN
import 'package:proyectos_matchy/screens/crear_cita_panel_screen.dart';
import 'package:proyectos_matchy/screens/cita_buscar.dart';
import 'package:proyectos_matchy/screens/citas_pendientes_screen.dart';
import 'package:proyectos_matchy/screens/restaurantes_screen.dart';
import 'package:proyectos_matchy/screens/bares_screen.dart';
import 'package:proyectos_matchy/screens/cafes_screen.dart';
import 'package:proyectos_matchy/screens/actividades_screen.dart';
import 'package:proyectos_matchy/screens/reprogramar_cita_aceptar_screen.dart';
import 'package:proyectos_matchy/screens/nueva_cita_solicitud_screen.dart';

// =============================================================================
// 🔔 LÓGICA DE NOTIFICACIONES (RIVERPOD)
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
  // 🔴🔴 ZONA DE CHINCHES MAESTROS (CONTROL DE DISEÑO) 🔴🔴
  // ===========================================================================

  static const Color kCardBackground   = Color(0x4FFFFFFF);
  static const Color kSheetTopColor    = Color(0xFF2E1A47);
  static const Color kSheetBottomColor = Colors.black;

  static const List<Color> kNotifGradient = [Color(0xFF4A3B75), Color(0xFF1F1F1F)];
  static const double kNotifRadius = 22.0;
  static const List<BoxShadow> kNotifShadow = [BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 4))];

  static const List<BoxShadow> kCardShadow = [BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 5))];

  static const List<Color> kPremiumButtonGradient = [
    Color(0xFF7E208E),
    Color(0xFC4B3F60),
  ];
  static const double kPremiumButtonRadius = 18.0;
  static const BorderSide kPremiumButtonBorder = BorderSide(color: Colors.white24, width: 1.0);
  static const List<BoxShadow> kPremiumButtonShadow = [
    BoxShadow(color: Colors.black54, blurRadius: 2, offset: Offset(0, 4)),
  ];

  bool _bootstrapped = false;
  bool _sentToShell = false;

  String _nombreSeguro(String raw) {
    final clean = raw.trim();
    if (clean.isEmpty) return 'SIN NOMBRE';
    final parts = clean.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'SIN NOMBRE';
    final first = parts.first;
    final two = parts.length >= 2 ? '${parts[0]} ${parts[1]}' : first;
    return (clean.length <= 12 && parts.length <= 2) ? clean.toUpperCase() : (first.length <= 5 && parts.length >= 2 ? (two.length > 12 ? first.toUpperCase() : two.toUpperCase()) : first.toUpperCase());
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
              // HEADER
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 40),
                      Image.asset('assets/images/logomatchyplano.png', height: 45),

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
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 80),
                  child: userDocAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
                    error: (_, __) => const SizedBox(),
                    data: (snap) {
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

                      return _PanelContent(
                        textTheme: textTheme,
                        nombre: nombre,
                        edad: edad,
                        ubicacion: ubicacion,
                        fotoWidget: _buildFotoWidget(fotoFinal),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),

          // 🔥 DEGRADADO INFERIOR
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 80,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.95)],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: null,
    );
  }
}

// ... _NotificacionesSheet (Lógica ajustada) ...
class _NotificacionesSheet extends ConsumerWidget {
  const _NotificacionesSheet();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificacionesAsync = ref.watch(notificationsListProvider);
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_PanelScreenState.kSheetTopColor, _PanelScreenState.kSheetBottomColor]), borderRadius: const BorderRadius.vertical(top: Radius.circular(30)), boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, -5))]),
      child: Column(
        children: [
          const SizedBox(height: 15), Container(width: 50, height: 6, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))), const SizedBox(height: 20), const Text("NOTIFICACIONES", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, fontFamily: 'Poppins', letterSpacing: 1.0)), const SizedBox(height: 15),
          Expanded(child: notificacionesAsync.when(loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFBEB3FF))), error: (_, __) => const Center(child: Text("Error cargando notificaciones", style: TextStyle(color: Colors.white54))), data: (docs) { if (docs.isEmpty) return const Center(child: Text("No tienes notificaciones nuevas.", style: TextStyle(color: Colors.white38, fontFamily: 'Poppins'))); return ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: docs.length, itemBuilder: (context, index) { final data = docs[index].data() as Map<String, dynamic>; final docId = docs[index].id; final leido = data['read'] == true; final titulo = data['title'] ?? 'Notificación'; final cuerpo = data['body'] ?? ''; final type = data['type'] ?? ''; final citaId = data['citaId']; IconData icono = Icons.notifications_rounded; if (type == 'repro_request' || type == 'invitacion_cita') icono = Icons.calendar_month_rounded; if (type == 'repro_accepted' || type == 'cita_aceptada') icono = Icons.check_circle_rounded; return Dismissible(key: Key(docId), direction: DismissDirection.endToStart, background: Container(margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Colors.red.withOpacity(0.8), borderRadius: BorderRadius.circular(_PanelScreenState.kNotifRadius)), alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete_outline, color: Colors.white)), onDismissed: (_) => NotificationLogic.deleteNotification(docId), child: Container(margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: _PanelScreenState.kNotifGradient), borderRadius: BorderRadius.circular(_PanelScreenState.kNotifRadius), border: leido ? Border.all(color: Colors.white.withOpacity(0.05)) : Border.all(color: const Color(0xFFBEB3FF).withOpacity(0.5), width: 1.5), boxShadow: _PanelScreenState.kNotifShadow), child: ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), leading: CircleAvatar(backgroundColor: leido ? Colors.white10 : const Color(0xFF6B4EE6), child: Icon(icono, color: Colors.white)), title: Text(titulo, style: TextStyle(color: Colors.white, fontWeight: leido ? FontWeight.normal : FontWeight.bold, fontSize: 15)), subtitle: Padding(padding: const EdgeInsets.only(top: 4), child: Text(cuerpo, style: const TextStyle(color: Colors.white70, fontSize: 13))), trailing: const Icon(Icons.chevron_right, color: Colors.white38), onTap: () {
            // 🔥 AQUÍ ESTÁ EL CAMBIO: Eliminamos la notificación para que desaparezca inmediatamente
            NotificationLogic.deleteNotification(docId);
            Navigator.pop(context);
            if (type == 'repro_request' && citaId != null) Navigator.push(context, MaterialPageRoute(builder: (_) => ReprogramarCitaAceptarScreen(citaId: citaId)));
            if (type == 'invitacion_cita' && citaId != null) Navigator.push(context, MaterialPageRoute(builder: (_) => NuevaCitaSolicitudScreen(citaId: citaId)));
            if (type == 'cita_aceptada' || type == 'repro_accepted') HomeShell.go(context, index: 1);
          }))); }); })),
        ],
      ),
    );
  }
}

class _PanelContent extends StatelessWidget {
  final TextTheme textTheme;
  final String nombre;
  final String edad;
  final String ubicacion;
  final Widget fotoWidget;

  const _PanelContent({required this.textTheme, required this.nombre, required this.edad, required this.ubicacion, required this.fotoWidget});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
        // PERFIL
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: _PanelScreenState.kCardBackground, borderRadius: BorderRadius.circular(30), boxShadow: _PanelScreenState.kCardShadow),
          child: Row(children: [
            ClipRRect(borderRadius: BorderRadius.circular(20), child: Container(width: 110, height: 110, color: Colors.black26, child: fotoWidget)),
            const SizedBox(width: 18),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Row(children: [Text(nombre, style: textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)), const SizedBox(width: 8), Text(edad, style: textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900))])),
              const SizedBox(height: 6),
              Row(children: [const Icon(Icons.location_on, color: Colors.white70, size: 16), const SizedBox(width: 4), Expanded(child: Text(ubicacion, overflow: TextOverflow.ellipsis, style: textTheme.bodyMedium?.copyWith(color: Colors.white70, fontSize: 14)))]),
              const SizedBox(height: 12),
              GestureDetector(onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DatosScreen())), child: Container(height: 36, width: 140, decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: _PanelScreenState.kPremiumButtonGradient), borderRadius: BorderRadius.circular(_PanelScreenState.kPremiumButtonRadius), border: Border.fromBorderSide(_PanelScreenState.kPremiumButtonBorder), boxShadow: _PanelScreenState.kPremiumButtonShadow), alignment: Alignment.center, child: const Text('EDITAR PERFIL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5))))
            ]))
          ]),
        ),
        const SizedBox(height: 20),
        // ACCIONES
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(color: _PanelScreenState.kCardBackground, borderRadius: BorderRadius.circular(26), boxShadow: _PanelScreenState.kCardShadow),
          child: Row(children: [
            Image.asset('assets/images/ic_calendar.png', width: 90, height: 90, fit: BoxFit.contain),
            const SizedBox(width: 22),
            Expanded(child: Column(children: [
              _BotonPanelPremium(texto: "CREAR UNA CITA", onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CrearCitaPanelScreen(nombreUsuario: nombre)))),
              const SizedBox(height: 12),
              _BotonPanelPremium(texto: "BUSCAR UNA CITA", onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CitaBuscarScreen()))),
              const SizedBox(height: 12),
              _BotonPanelPremium(texto: "CITAS PUBLICADAS", onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CitasPendientesScreen()))),
            ]))
          ]),
        ),
        const SizedBox(height: 26),
        Text("SITIOS RECOMENDADOS", style: textTheme.titleMedium?.copyWith(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        const SizedBox(height: 16),

        // 3. SITIOS RECOMENDADOS (🔥 GRID MEJORADO)
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
}

class _BotonPanelPremium extends StatelessWidget {
  final String texto;
  final VoidCallback onTap;
  const _BotonPanelPremium({required this.texto, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: Container(height: 44, decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: _PanelScreenState.kPremiumButtonGradient), borderRadius: BorderRadius.circular(_PanelScreenState.kPremiumButtonRadius), border: Border.fromBorderSide(_PanelScreenState.kPremiumButtonBorder), boxShadow: _PanelScreenState.kPremiumButtonShadow), alignment: Alignment.center, child: Text(texto, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5))));
  }
}

// 🔥 WIDGET CATEGORÍA MEJORADO (TEXTO ADENTRO + DEGRADADO + SOMBRA)
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
          // Imagen Fondo
          Container(
            height: 110,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 1, offset: Offset(0, 9))],
              image: DecorationImage(image: AssetImage(imageAsset), fit: BoxFit.cover),
            ),
          ),

          // Degradado Negro Inferior (Para leer el texto)
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

          // Texto Encima
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                // Sombreado al texto
                shadows: [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 2))],
              ),
            ),
          ),
        ],
      ),
    );
  }
}