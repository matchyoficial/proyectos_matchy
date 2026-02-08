// 📂 lib/screens/panel_screen.dart
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
import 'package:proyectos_matchy/screens/restaurantes_screen.dart';
import 'package:proyectos_matchy/screens/bares_screen.dart';
import 'package:proyectos_matchy/screens/cafes_screen.dart';
import 'package:proyectos_matchy/screens/actividades_screen.dart';
import 'package:proyectos_matchy/screens/reprogramar_cita_aceptar_screen.dart';
import 'package:proyectos_matchy/screens/nueva_cita_solicitud_screen.dart';
import 'package:proyectos_matchy/screens/lugar_plantilla_screen.dart';

final unreadNotificationsProvider = StreamProvider<int>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return const Stream.empty();
  return FirebaseFirestore.instance.collection('users').doc(user.uid).collection('notifications').where('read', isEqualTo: false).snapshots().map((snapshot) => snapshot.docs.length);
});

final notificationsListProvider = StreamProvider<List<DocumentSnapshot>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return const Stream.empty();
  return FirebaseFirestore.instance.collection('users').doc(user.uid).collection('notifications').orderBy('createdAt', descending: true).limit(20).snapshots().map((snapshot) => snapshot.docs);
});

class NotificationLogic {
  static Future<void> markAsRead(String id) async { final u = FirebaseAuth.instance.currentUser; if (u != null) await FirebaseFirestore.instance.collection('users').doc(u.uid).collection('notifications').doc(id).update({'read': true}); }
  static Future<void> deleteNotification(String id) async { final u = FirebaseAuth.instance.currentUser; if (u != null) await FirebaseFirestore.instance.collection('users').doc(u.uid).collection('notifications').doc(id).delete(); }
}

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
  static const Color kCardBackground = Color(0x4FFFFFFF);
  static const Color kSheetTopColor = Color(0xFF2E1A47);
  static const Color kSheetBottomColor = Colors.black;
  static const List<Color> kNotifGradient = [Color(0xFF4A3B75), Color(0xFF1F1F1F)];
  static const double kNotifRadius = 22.0; // 🛡️ CONSTANTE RESTAURADA
  static const List<BoxShadow> kNotifShadow = [BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 4))];
  static const List<BoxShadow> kCardShadow = [BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 5))];
  static const List<Color> kPremiumButtonGradient = [Color(0xFF7E208E), Color(0xFC4B3F60)];
  static const List<Color> kDisabledButtonGradient = [Color(0xFF424242), Color(0xFF212121)];
  static const List<Color> kBtnPublishedGradient = [Color(0xFF145977), Color(0xFF0277BD)];
  static const double kPremiumButtonRadius = 18.0;
  static const BorderSide kPremiumButtonBorder = BorderSide(color: Colors.white24, width: 1.0);
  static const List<BoxShadow> kPremiumButtonShadow = [BoxShadow(color: Colors.black54, blurRadius: 2, offset: Offset(0, 4))];

  bool _bootstrapped = false;
  bool _sentToShell = false;

  String _nombreSeguro(String raw) {
    final parts = raw.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    return parts.isEmpty ? 'SIN NOMBRE' : parts.first.toUpperCase();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.showBottomNav && !_sentToShell) { _sentToShell = true; HomeShell.go(context, index: 2); }
      if (!_bootstrapped) { _bootstrapped = true; ref.read(profileFormProvider.notifier).bootstrapFromFirestore(); }
    });
  }

  Widget _buildFotoWidget(String? f) {
    if ((f ?? '').isEmpty) return Image.asset('assets/images/perfil1.jpg', fit: BoxFit.cover, alignment: Alignment.topCenter);
    if (f!.startsWith('http')) return Image.network(f, fit: BoxFit.cover, alignment: Alignment.topCenter);
    return Image.file(File(f), fit: BoxFit.cover, alignment: Alignment.topCenter);
  }

  @override
  Widget build(BuildContext context) {
    final userDocAsync = ref.watch(userDocProvider);
    final unreadCount = ref.watch(unreadNotificationsProvider).value ?? 0;
    return Scaffold(
      body: Stack(children: [
        Positioned.fill(child: Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover)),
        Column(children: [
          SafeArea(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Image.asset('assets/images/logomatchyplano.png', height: 45),
            Row(children: [
              GestureDetector(onTap: () => showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true, builder: (_) => const _InfoSheet()), child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.info_outline, color: Colors.white, size: 28))),
              const SizedBox(width: 12),
              GestureDetector(onTap: () => showSearch(context: context, delegate: _LugarSearchDelegate()), child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.search, color: Colors.white, size: 28))),
              const SizedBox(width: 12),
              GestureDetector(onTap: () => showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true, builder: (_) => const _NotificacionesSheet()), child: Stack(clipBehavior: Clip.none, children: [const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 32), if (unreadCount > 0) Positioned(right: 0, top: 0, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Color(0xFFFF4D6D), shape: BoxShape.circle), child: Text('$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))))]))
            ])
          ]))),
          Expanded(child: SingleChildScrollView(padding: const EdgeInsets.only(bottom: 80), child: userDocAsync.when(loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)), error: (_, __) => const SizedBox(), data: (snap) {
            final data = snap?.data() ?? {};
            if (snap != null && snap.exists && data['onboarding_completed'] != true) { WidgetsBinding.instance.addPostFrameCallback((_) => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const DatosScreen()))); return const SizedBox(); }
            final bHasta = data['bloqueadoHasta'] as Timestamp?;
            return _PanelContent(
              textTheme: Theme.of(context).textTheme,
              nombre: _nombreSeguro((data['nombre'] ?? '').toString()),
              edad: (data['edad']?.toString() ?? '—'),
              ubicacion: "${data['ciudad'] ?? ''} - ${data['pais'] ?? ''}",
              fotoWidget: _buildFotoWidget(data['profilePhotoUrl']),
              puntaje: (data['confiabilidad'] as num?)?.toInt() ?? 100,
              userStatus: (data['userStatus'] ?? 'active').toString(),
              strikes: (data['strikes'] as num?)?.toInt() ?? 0,
              bloqueadoHasta: bHasta?.toDate(),
              racha: (data['citas_consecutivas_exitosas'] as num?)?.toInt() ?? 0,
            );
          })))
        ]),
        Positioned(bottom: 0, left: 0, right: 0, height: 80, child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.95)]))))
      ]),
    );
  }
}

class _PanelContent extends StatelessWidget {
  final TextTheme textTheme; final String nombre; final String edad; final String ubicacion; final Widget fotoWidget; final int puntaje; final String userStatus; final int strikes; final DateTime? bloqueadoHasta; final int racha;
  const _PanelContent({required this.textTheme, required this.nombre, required this.edad, required this.ubicacion, required this.fotoWidget, required this.puntaje, required this.userStatus, required this.strikes, this.bloqueadoHasta, required this.racha});

  bool get _estaBloqueado {
    if (userStatus == 'blocked' || userStatus == 'blocked_permanent') {
      if (bloqueadoHasta != null) return bloqueadoHasta!.isAfter(DateTime.now());
      return true;
    }
    return false;
  }

  void _ejecutarAccion(BuildContext context, VoidCallback accion) {
    if (_estaBloqueado) {
      final dias = strikes * 5;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Row(children: [const Icon(Icons.lock_outline, color: Colors.white), const SizedBox(width: 10), Expanded(child: Text("ACCESO RESTRINGIDO. Tienes $strikes strike(s). Debes esperar $dias días o resolver tus citas pendientes.", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)))]), backgroundColor: const Color(0xFFC62828), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), margin: const EdgeInsets.all(20)));
    } else { accion(); }
  }

  @override
  Widget build(BuildContext context) {
    final bool bloqueado = _estaBloqueado;
    return Column(children: [
      const SizedBox(height: 10),
      Container(margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5), padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: _PanelScreenState.kCardBackground, borderRadius: BorderRadius.circular(30), boxShadow: _PanelScreenState.kCardShadow), child: Row(children: [
        ClipRRect(borderRadius: BorderRadius.circular(20), child: Container(width: 110, height: 110, color: Colors.black26, child: fotoWidget)),
        const SizedBox(width: 18),
        Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Row(children: [Text(nombre, style: textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)), const SizedBox(width: 8), Text(edad, style: textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900))])),
          const SizedBox(height: 12),
          _buildRachaWideBar(racha),
          const SizedBox(height: 8),
          GestureDetector(onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DatosScreen())), child: Container(height: 35, decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: _PanelScreenState.kPremiumButtonGradient), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white24), boxShadow: _PanelScreenState.kPremiumButtonShadow), alignment: Alignment.center, child: const FittedBox(fit: BoxFit.scaleDown, child: Text('EDITAR PERFIL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)))))
        ]))
      ])),
      TermometroConfiabilidad(puntaje: puntaje, fechaDesbloqueo: bloqueado ? bloqueadoHasta : null),
      const SizedBox(height: 10),
      Container(margin: const EdgeInsets.symmetric(horizontal: 20), padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18), decoration: BoxDecoration(color: _PanelScreenState.kCardBackground, borderRadius: BorderRadius.circular(26), boxShadow: _PanelScreenState.kCardShadow), child: Row(children: [
        Image.asset('assets/images/ic_calendar.png', width: 90, height: 90, fit: BoxFit.contain),
        const SizedBox(width: 22),
        Expanded(child: Column(children: [
          _BotonPanelPremium(texto: "CREAR UNA CITA", bloqueado: bloqueado, onTap: () => _ejecutarAccion(context, () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CrearCitaPanelScreen(nombreUsuario: nombre))))),
          const SizedBox(height: 12),
          _BotonPanelPremium(texto: "BUSCAR UNA CITA", bloqueado: bloqueado, onTap: () => _ejecutarAccion(context, () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CitaBuscarScreen())))),
          const SizedBox(height: 12),
          _BotonPanelPremium(texto: "CITAS PUBLICADAS", bloqueado: false, customGradient: _PanelScreenState.kBtnPublishedGradient, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CitasPendientesScreen()))),
        ]))
      ])),
      const SizedBox(height: 26),
      FittedBox(fit: BoxFit.scaleDown, child: Text("SITIOS RECOMENDADOS", style: textTheme.titleMedium?.copyWith(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 0.5))),
      const SizedBox(height: 16),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(children: [
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
      ])),
      const SizedBox(height: 40),
    ]);
  }

  Widget _buildRachaWideBar(int count) {
    return Container(height: 35, decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white10), boxShadow: _PanelScreenState.kPremiumButtonShadow), padding: const EdgeInsets.symmetric(horizontal: 12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: const Text("RACHAS", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)))), Row(children: [for(int i=1; i<=3; i++) _single(count >= i)])]));
  }
  Widget _single(bool a) => ColorFiltered(colorFilter: a ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply) : const ColorFilter.matrix(<double>[0.21,0.71,0.07,0,0, 0.21,0.71,0.07,0,0, 0.21,0.71,0.07,0,0, 0,0,0,1,0]), child: const Text("🔥", style: TextStyle(fontSize: 16)));
}

class _BotonPanelPremium extends StatelessWidget {
  final String texto; final VoidCallback onTap; final bool bloqueado; final List<Color>? customGradient;
  const _BotonPanelPremium({required this.texto, required this.onTap, this.bloqueado = false, this.customGradient});
  @override
  Widget build(BuildContext context) {
    final gradient = bloqueado ? _PanelScreenState.kDisabledButtonGradient : (customGradient ?? _PanelScreenState.kPremiumButtonGradient);
    return GestureDetector(onTap: onTap, child: Container(height: 44, decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradient), borderRadius: BorderRadius.circular(18), border: Border.fromBorderSide(_PanelScreenState.kPremiumButtonBorder), boxShadow: _PanelScreenState.kPremiumButtonShadow), alignment: Alignment.center, padding: const EdgeInsets.symmetric(horizontal: 8), child: FittedBox(fit: BoxFit.scaleDown, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [if (bloqueado) ...[const Icon(Icons.lock, color: Colors.white54, size: 16), const SizedBox(width: 8)], Text(texto, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5))]))));
  }
}

class _CategoriaPanelCard extends StatelessWidget {
  final String label; final String imageAsset; final VoidCallback onTap;
  const _CategoriaPanelCard({required this.label, required this.imageAsset, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: Stack(alignment: Alignment.bottomCenter, children: [Container(height: 110, decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 1, offset: Offset(0, 9))], image: DecorationImage(image: AssetImage(imageAsset), fit: BoxFit.cover))), Container(height: 110, decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.8)], stops: const [0.5, 1.0]))), Padding(padding: const EdgeInsets.only(bottom: 8), child: FittedBox(fit: BoxFit.scaleDown, child: Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800, shadows: [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 2))]))))]));
  }
}

// 🛡️ CONTENIDO DE HOJAS ORIGINALES ÍNTEGRO
class _InfoSheet extends StatelessWidget {
  const _InfoSheet();
  @override
  Widget build(BuildContext context) {
    return Container(height: MediaQuery.of(context).size.height * 0.92, decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_PanelScreenState.kSheetTopColor, _PanelScreenState.kSheetBottomColor]), borderRadius: const BorderRadius.vertical(top: Radius.circular(30)), boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, -5))]), child: Column(children: [
      const SizedBox(height: 15), Container(width: 50, height: 6, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))), const SizedBox(height: 20),
      const FittedBox(fit: BoxFit.scaleDown, child: Text("CÓMO FUNCIONA MATCHY", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, fontFamily: 'Poppins', letterSpacing: 1.0))),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(20), physics: const BouncingScrollPhysics(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _iCard(icon: Icons.local_fire_department, iconColor: Colors.orangeAccent, title: "PRENDE TU RACHA", content: [
          _b("Asiste y Confirma: Completa tus citas y asegúrate de validar el código con tu Matchy."),
          _b("Suma Fuegos:\n   Cita 1: 🔥\n   Cita 2: 🔥🔥\n   Cita 3: 🔥🔥🔥"),
          _b("El Premio: Ganas +20 Puntos de Puntualidad y la racha se reinicia."),
        ]),
        const SizedBox(height: 20),
        _iCard(icon: Icons.block, iconColor: Colors.redAccent, title: "NO TE CONGELES", content: [
          _b("Si cancelas faltando menos de 12h o dejas plantado, recibes Strike ❌."),
          _sRow("1 Strike", "5 Días"), _sRow("2 Strikes", "10 Días"), _sRow("3 Strikes", "15 Días"), _sRow("4 Strikes", "20 Días"),
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.redAccent)), child: const Text("💀 5 STRIKES = BLOQUEO DEFINITIVO", textAlign: TextAlign.center, style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900, fontSize: 13))),
        ]),
        const SizedBox(height: 20),
        _iCard(icon: Icons.security, iconColor: Colors.cyanAccent, title: "TU SEGURIDAD PRIMERO", content: [
          _b("Lugar Público: Mantén tu primera cita siempre en sitios concurridos."),
          _b("El Código: Nunca des tu código por chat."),
        ]),
      ])))
    ]));
  }
  Widget _iCard({required IconData icon, required Color iconColor, required String title, required List<Widget> content}) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: Colors.white.withOpacity(0.05), border: Border.all(color: iconColor.withOpacity(0.3))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, color: iconColor), const SizedBox(width: 10), Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))))]), const SizedBox(height: 12), ...content]));
  Widget _b(String t) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("• ", style: TextStyle(color: Colors.white54)), Expanded(child: Text(t, style: const TextStyle(color: Colors.white70, fontSize: 14)))]));
  Widget _sRow(String s, String p) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Row(children: [Text(s, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), const Text(" = ", style: TextStyle(color: Colors.white54)), Text(p, style: const TextStyle(color: Colors.white70))]));
}

class _NotificacionesSheet extends ConsumerWidget {
  const _NotificacionesSheet();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationsListProvider);
    return Container(height: MediaQuery.of(context).size.height * 0.85, decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_PanelScreenState.kSheetTopColor, _PanelScreenState.kSheetBottomColor]), borderRadius: const BorderRadius.vertical(top: Radius.circular(30))), child: Column(children: [
      const SizedBox(height: 15), Container(width: 50, height: 6, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))), const SizedBox(height: 20), const FittedBox(fit: BoxFit.scaleDown, child: Text("NOTIFICACIONES", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, fontFamily: 'Poppins', letterSpacing: 1.0))),
      Expanded(child: async.when(loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFBEB3FF))), error: (_, __) => const SizedBox(), data: (docs) { if (docs.isEmpty) return const Center(child: Text("No hay notificaciones", style: TextStyle(color: Colors.white38))); return ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: docs.length, itemBuilder: (context, index) { final data = docs[index].data() as Map<String, dynamic>; return Dismissible(key: Key(docs[index].id), onDismissed: (_) => NotificationLogic.deleteNotification(docs[index].id), background: Container(color: Colors.red), child: Container(margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(gradient: LinearGradient(colors: _PanelScreenState.kNotifGradient), borderRadius: BorderRadius.circular(_PanelScreenState.kNotifRadius), boxShadow: _PanelScreenState.kNotifShadow, border: Border.all(color: Colors.white12)), child: ListTile(title: Text(data['title'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), subtitle: Text(data['body'] ?? '', style: const TextStyle(color: Colors.white70)), leading: const Icon(Icons.notifications, color: Color(0xFFBEB3FF))))); }); }))
    ]));
  }
}

class _LugarSearchDelegate extends SearchDelegate {
  @override
  List<Widget>? buildActions(BuildContext context) => [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];
  @override
  Widget buildLeading(BuildContext context) => IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));
  @override
  Widget buildResults(BuildContext context) => Container();
  @override
  Widget buildSuggestions(BuildContext context) => Container();
}