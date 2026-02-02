// 📂 lib/screens/perfil_screen.dart
// ✅ PERFIL (DISEÑO PREMIUM FINAL + FOTO INTELIGENTE)
// 🔥 FIX: Implementado 'FotoPerfilUsuario' en la tarjeta principal.
// 🔥 LOGIC: Prioriza fotos locales (drafts) y usa el widget inteligente para la URL remota.
// 🔥 UI: Botones Premium y degradados intactos.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proyectos_matchy/widgets/matchy_page_layout.dart';

import 'package:proyectos_matchy/screens/panel_screen.dart';
import 'package:proyectos_matchy/screens/citas_screen.dart';
import 'package:proyectos_matchy/screens/matchys_screen.dart';
import 'package:proyectos_matchy/screens/chat_screen.dart';

import 'package:proyectos_matchy/state/profile_form_provider.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:proyectos_matchy/screens/splash_screen.dart';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:proyectos_matchy/widgets/foto_perfil_usuario.dart'; // 👈 IMPORTANTE: Widget Nuevo

class PerfilScreen extends ConsumerStatefulWidget {
  static const String routeName = 'perfil';

  final bool showBottomNav;

  const PerfilScreen({
    super.key,
    this.showBottomNav = true,
  });

  @override
  ConsumerState<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends ConsumerState<PerfilScreen> {
  bool _bootstrapped = false;
  bool _busy = false;

  // 🔴 CHINCHE PREFS
  static const String _kProfileDraftKey = 'matchy_profile_draft_v1';
  static const String _kProfilePublishedKey = 'matchy_profile_published_v1';
  static const String _kOnboardingCompletedKey = 'matchy_onboarding_completed_v1';
  static const String _kUsersCollection = 'users';

  // ===========================================================================
  // 🔴🔴 CHINCHES MAESTROS (DISEÑO PREMIUM) 🔴🔴
  // ===========================================================================
  // Gradientes Botones
  static const List<Color> kBtnLogoutGradient = [Color(0xFF0B1F3A), Color(0xFF050F1E)]; // Azul Oscuro Profundo
  static const List<Color> kBtnDeleteGradient = [Color(0xFFB00020), Color(0xFF600010)]; // Rojo Intenso

  static const double kButtonRadius = 25.0; // Redondeo Premium
  static const List<BoxShadow> kButtonShadow = [
    BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 4))
  ];
  // ===========================================================================

  void _goSplash() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
          (route) => false,
    );
  }

  Future<void> _clearMatchyLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kProfileDraftKey);
    await prefs.remove(_kProfilePublishedKey);
    await prefs.remove(_kOnboardingCompletedKey);

    await ref.read(profileFormProvider.notifier).clearDraft();
  }

  // ✅ Logout blindado
  Future<void> _logout() async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
      await _clearMatchyLocal();

      if (!mounted) return;
      _goSplash();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error cerrando sesión: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool?> _confirmDialog({
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
            child: Text(confirmText, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ✅ Borra por carpeta estándar
  Future<void> _deleteUserPhotosFromStorageFolder(String uid) async {
    try {
      final root = FirebaseStorage.instance.ref().child('users/$uid/photos');
      final list = await root.listAll();
      for (final item in list.items) { try { await item.delete(); } catch (_) {} }
      for (final prefix in list.prefixes) {
        try {
          final sub = await prefix.listAll();
          for (final item in sub.items) { try { await item.delete(); } catch (_) {} }
        } catch (_) {}
      }
    } catch (_) {}
  }

  // ✅ Borra URLs explícitas
  Future<void> _deleteStorageUrls(List<String> urls) async {
    for (final u in urls) {
      final url = u.trim();
      if (url.isEmpty || !(url.startsWith('http://') || url.startsWith('https://'))) continue;
      try {
        final ref = FirebaseStorage.instance.refFromURL(url);
        await ref.delete();
      } catch (_) {}
    }
  }

  Future<void> _deleteProfile() async {
    if (_busy) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) { if (!mounted) return; _goSplash(); return; }

    final first = await _confirmDialog(
      title: 'Borrar perfil',
      message: 'Esto eliminará tu perfil de Matchy (datos y fotos). Esta acción no se puede deshacer.',
      confirmText: 'Continuar',
      confirmColor: Colors.red,
    );
    if (first != true) return;

    final second = await _confirmDialog(
      title: 'Confirmación final',
      message: '¿Seguro seguro? Si borras el perfil, desaparecerás de Matchy.',
      confirmText: 'BORRAR',
      confirmColor: Colors.redAccent,
    );
    if (second != true) return;

    setState(() => _busy = true);

    try {
      final uid = user.uid;
      final docRef = FirebaseFirestore.instance.collection(_kUsersCollection).doc(uid);
      final snap = await docRef.get();

      final urlsToDelete = <String>[];
      if (snap.exists) {
        final data = snap.data();
        if (data != null) {
          final profilePhotoUrl = (data['profilePhotoUrl'] ?? '').toString();
          if (profilePhotoUrl.trim().isNotEmpty) urlsToDelete.add(profilePhotoUrl);
          final raw = data['photoUrls'];
          if (raw is List) {
            for (final e in raw) {
              final s = e.toString();
              if (s.trim().isNotEmpty) urlsToDelete.add(s);
            }
          }
        }
      }

      await _deleteStorageUrls(urlsToDelete);
      await _deleteUserPhotosFromStorageFolder(uid);
      await docRef.delete();
      await _clearMatchyLocal();

      try { await user.delete(); } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Perfil borrado, re-login requerido.')));
      }

      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Perfil borrado.')));
      _goSplash();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_bootstrapped) return;
      _bootstrapped = true;
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) { if (!mounted) return; _goSplash(); return; }
      await ref.read(profileFormProvider.notifier).loadDraft();
      if (!mounted) return;
      await ref.read(profileFormProvider.notifier).bootstrapFromFirestore();
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final state = ref.watch(profileFormProvider);

    return Scaffold(
      // Usamos Stack para poner el gradiente inferior SOBRE el layout
      body: Stack(
        children: [
          // 1. Contenido
          MatchyPageLayout(
            backgroundAsset: 'assets/images/fondo.jpg',
            logoAsset: 'assets/images/logomatchyplano.png',
            scrollContent: _PerfilContent(
              textTheme: textTheme,
              state: state,
              busy: _busy,
              onLogout: _logout,
              onDeleteProfile: _deleteProfile,
            ),
            topSpacing: 35,
            logoHeight: 45,
            logoOffsetY: 0,
            spaceLogoToScroll: 15,
          ),

          // 2. 🔥 DEGRADADO INFERIOR (FADE OUT)
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
        ],
      ),
      bottomNavigationBar: widget.showBottomNav ? const _MatchyBottomNav(currentIndex: 0) : null,
    );
  }
}

class _PerfilContent extends StatelessWidget {
  final TextTheme textTheme;
  final ProfileFormState state;
  final bool busy;
  final Future<void> Function() onLogout;
  final Future<void> Function() onDeleteProfile;

  const _PerfilContent({
    required this.textTheme,
    required this.state,
    required this.busy,
    required this.onLogout,
    required this.onDeleteProfile,
  });

  String _nombrePanelSeguro(String raw) {
    final clean = raw.trim();
    if (clean.isEmpty) return 'Sin nombre';
    final parts = clean.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'Sin nombre';
    final first = parts.first;
    final twoWords = parts.length >= 2 ? '${parts[0]} ${parts[1]}' : first;
    const int largoTotal = 12;
    const int firstShort = 5;
    if (clean.length <= largoTotal && parts.length <= 2) return clean;
    if (first.length <= firstShort && parts.length >= 2) {
      if (twoWords.length > 12) return first;
      return twoWords;
    }
    return first;
  }

  String? _resolveFotoPrincipal() {
    final url = (state.profilePhotoUrl ?? '').trim();
    if (url.isNotEmpty) return url;
    if (state.photoUrls.isNotEmpty) {
      final u = state.photoUrls.first.trim();
      if (u.isNotEmpty) return u;
    }
    if (state.fotosCargadas.isNotEmpty) {
      final v = state.fotosCargadas.first.trim();
      if (v.isNotEmpty) return v;
    }
    return null;
  }

  List<String> _resolveGaleria() {
    final urls = state.photoUrls.where((e) => e.trim().isNotEmpty).toList();
    if (urls.isNotEmpty) return urls;
    return List<String>.from(state.fotosCargadas);
  }

  @override
  Widget build(BuildContext context) {
    final nombre = _nombrePanelSeguro(state.nombre);
    final edad = state.edad.trim().isEmpty ? '—' : state.edad.trim();
    final pais = (state.paisSeleccionado ?? '').trim();
    final ciudad = (state.ciudadSeleccionada ?? '').trim();
    final ciudadPais = (ciudad.isEmpty && pais.isEmpty)
        ? 'Sin ubicación'
        : (ciudad.isNotEmpty && pais.isNotEmpty) ? '$ciudad - $pais' : (ciudad.isNotEmpty ? ciudad : pais);
    final profesion = state.profesion.trim().isEmpty ? '—' : state.profesion.trim();
    final biografia = state.biografia.trim().isEmpty ? 'Aún no has escrito tu biografía.' : state.biografia.trim();
    final detalle = state.detalle.trim().isEmpty ? 'Aún no has agregado este detalle.' : state.detalle.trim();
    final sobreMi = [if (state.estatura.trim().isNotEmpty) '📏 ${state.estatura.trim()}', ...state.sobreMiSeleccion];
    final busco = List<String>.from(state.buscoSeleccion);
    final intereses = List<String>.from(state.interesesSeleccion);
    final galeria = _resolveGaleria();
    final principal = _resolveFotoPrincipal();
    final bool tieneFotos = principal != null;

    // Obtenemos UID para el widget inteligente
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 🔥 FOTO PRINCIPAL CON WIDGET INTELIGENTE (Pasamos smartUid)
          _FotoTarjeta(
            imagePathOrAssetOrUrl: principal,
            smartUid: myUid, // 👈 Pasamos el UID para que active el modo "FotoPerfilUsuario" si es URL
            height: 450,
            overlay: (context) {
              return Stack(
                children: [
                  Positioned(
                    left: 0, right: 0, bottom: 0,
                    child: Container(
                      height: 180,
                      decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.95)])),
                    ),
                  ),
                  Positioned(
                    left: 30, bottom: 30,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(mainAxisSize: MainAxisSize.min, children: [Text(nombre, style: textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)), Text(', $edad', style: textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold))]),
                        const SizedBox(height: 4),
                        Text(profesion, style: textTheme.bodyMedium?.copyWith(color: Colors.white, fontSize: 16)),
                        const SizedBox(height: 2),
                        Text(ciudadPais, style: textTheme.bodyMedium?.copyWith(color: Colors.white, fontSize: 14)),
                      ],
                    ),
                  ),
                  if (!tieneFotos)
                    Positioned.fill(child: Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(color: Colors.black.withOpacity(0.50), borderRadius: BorderRadius.circular(14)), child: Text('Agrega al menos 1 foto en “Datos”', style: textTheme.bodyMedium?.copyWith(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold))))),
                ],
              );
            },
          ),

          const SizedBox(height: 16),
          _CardTexto(titulo: 'Biografía', texto: biografia, textTheme: textTheme),
          if (sobreMi.isNotEmpty) _CardChips(titulo: 'Sobre mí', items: sobreMi, textTheme: textTheme),
          if (galeria.length >= 2) _FotoTarjeta(imagePathOrAssetOrUrl: galeria[1], height: 400),
          if (busco.isNotEmpty) _CardChips(titulo: 'Busco...', items: busco, textTheme: textTheme),
          if (galeria.length >= 3) _FotoTarjeta(imagePathOrAssetOrUrl: galeria[2], height: 400),
          if (intereses.isNotEmpty) _CardChips(titulo: 'Intereses y Hobbies', items: intereses, textTheme: textTheme),
          if (galeria.length >= 4) _FotoTarjeta(imagePathOrAssetOrUrl: galeria[3], height: 400),
          _CardTexto(titulo: 'Un detalle que me enamora', texto: detalle, textTheme: textTheme),
          if (galeria.length >= 5) _FotoTarjeta(imagePathOrAssetOrUrl: galeria[4], height: 400),

          const SizedBox(height: 20),

          // ✅ BOTONES PREMIUM AL FINAL
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _PremiumButton(
              text: 'CERRAR SESIÓN',
              gradient: _PerfilScreenState.kBtnLogoutGradient,
              busy: busy,
              onTap: onLogout,
            ),
          ),

          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _PremiumButton(
              text: 'BORRAR PERFIL',
              gradient: _PerfilScreenState.kBtnDeleteGradient,
              busy: busy,
              onTap: onDeleteProfile,
            ),
          ),

          const SizedBox(height: 100), // Espacio para el Fade Out
        ],
      ),
    );
  }
}

// 🔥 WIDGET BOTÓN PREMIUM 🔥
class _PremiumButton extends StatelessWidget {
  final String text;
  final List<Color> gradient;
  final bool busy;
  final VoidCallback onTap;

  const _PremiumButton({
    required this.text,
    required this.gradient,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(_PerfilScreenState.kButtonRadius),
          boxShadow: _PerfilScreenState.kButtonShadow,
          border: Border.all(color: Colors.white24, width: 1),
        ),
        alignment: Alignment.center,
        child: busy
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(
          text,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5),
        ),
      ),
    );
  }
}

// ================================================================
// 🔹 COMPONENTES EXISTENTES (Con soporte para Foto Inteligente)
// ================================================================

class _FotoTarjeta extends StatelessWidget {
  final String? imagePathOrAssetOrUrl;
  final double height;
  final Widget Function(BuildContext context)? overlay;
  final String? smartUid; // 👈 NUEVO: Parámetro para activar el widget inteligente

  const _FotoTarjeta({
    required this.imagePathOrAssetOrUrl,
    required this.height,
    this.overlay,
    this.smartUid, // 👈
  });

  bool _isAsset(String v) => v.startsWith('assets/');
  bool _isUrl(String v) => v.startsWith('http://') || v.startsWith('https://');

  Widget _fallback() => Container(color: const Color(0x33FFFFFF), child: const Center(child: Icon(Icons.person, color: Colors.white70, size: 70)));

  @override
  Widget build(BuildContext context) {
    Widget background = _fallback();
    final raw = (imagePathOrAssetOrUrl ?? '').trim();

    // Lógica para priorizar:
    // 1. Si es archivo local (Borrador editando), lo mostramos.
    // 2. Si no es archivo local Y tenemos smartUid, usamos FotoPerfilUsuario (Firebase actualizado).
    // 3. Fallback normal.

    bool isFile = raw.isNotEmpty && !_isUrl(raw) && !_isAsset(raw);

    if (isFile) {
      // Es borrador local, mostrar el archivo
      background = Image.file(File(raw), fit: BoxFit.cover, alignment: Alignment.topCenter, errorBuilder: (_,__,___) => _fallback());
    } else if (smartUid != null) {
      // 🔥 ES URL REMOTA: Usamos el WIDGET INTELIGENTE
      background = FotoPerfilUsuario(
        uid: smartUid!,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
      );
    } else if (raw.isNotEmpty) {
      if (_isUrl(raw)) {
        // Para galerías secundarias que no tienen smartUid
        background = Image.network(raw, fit: BoxFit.cover, alignment: Alignment.topCenter, loadingBuilder: (_, c, p) => p == null ? c : Container(color: Colors.black26, child: const Center(child: CircularProgressIndicator())), errorBuilder: (_,__,___) => _fallback());
      } else if (_isAsset(raw)) {
        background = Image.asset(raw, fit: BoxFit.cover, alignment: Alignment.topCenter, errorBuilder: (_,__,___) => _fallback());
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: height,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.45), blurRadius: 10, offset: const Offset(0, 6))]),
      clipBehavior: Clip.antiAlias,
      child: Stack(fit: StackFit.expand, children: [background, if (overlay != null) overlay!(context)]),
    );
  }
}

class _CardTexto extends StatelessWidget {
  final String titulo;
  final String texto;
  final TextTheme textTheme;
  const _CardTexto({required this.titulo, required this.texto, required this.textTheme});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0x33FFFFFF), borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(titulo, style: textTheme.titleSmall?.copyWith(color: const Color(0xFFB3D9FF), fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 8), Text(texto, style: textTheme.bodyMedium?.copyWith(color: Colors.white, fontSize: 14))]),
    );
  }
}

class _CardChips extends StatelessWidget {
  final String titulo;
  final List<String> items;
  final TextTheme textTheme;
  const _CardChips({required this.titulo, required this.items, required this.textTheme});
  List<List<String>> _buildRows(List<String> all) {
    const int maxShortLength = 14;
    final rows = <List<String>>[];
    int i = 0;
    while (i < all.length) {
      final current = all[i];
      final isCurrentLong = current.length > maxShortLength;
      if (isCurrentLong) { rows.add([current]); i += 1; }
      else if (i + 1 < all.length) {
        final next = all[i + 1];
        if (next.length > maxShortLength) { rows.add([current]); i += 1; }
        else { rows.add([current, next]); i += 2; }
      } else { rows.add([current]); i += 1; }
    }
    return rows;
  }
  Widget _buildChip(String text) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(color: const Color(0x66FFFFFF), borderRadius: BorderRadius.circular(50)),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Flexible(child: Text(text, textAlign: TextAlign.center, softWrap: false, overflow: TextOverflow.ellipsis, style: textTheme.bodyMedium?.copyWith(color: Colors.white, fontSize: 13)))]),
    );
  }
  @override
  Widget build(BuildContext context) {
    final rows = _buildRows(items);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0x33FFFFFF), borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(titulo, style: textTheme.titleSmall?.copyWith(color: const Color(0xFFB3D9FF), fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 10), Column(children: rows.map((fila) { if (fila.length == 1) { return Row(children: [Expanded(child: _buildChip(fila[0]))]); } else { return Row(children: [Expanded(child: _buildChip(fila[0])), const SizedBox(width: 10), Expanded(child: _buildChip(fila[1]))]); } }).toList())]),
    );
  }
}

// ================================================================
// 🔹 BARRA DE NAVEGACIÓN INFERIOR
// ================================================================
class _MatchyBottomNav extends StatelessWidget {
  final int currentIndex;
  const _MatchyBottomNav({required this.currentIndex});
  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: const Color(0xCC000000),
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      selectedItemColor: const Color(0xFFE0D4FF),
      unselectedItemColor: Colors.white70,
      items: [
        _navItem('assets/images/profile.png', 'Perfil'),
        _navItem('assets/images/citas.png', 'Citas'),
        _navItem('assets/images/panel.png', 'Panel'),
        _navItem('assets/images/matchy.png', 'Matchy'),
        _navItem('assets/images/chat.png', 'Chat'),
      ],
      onTap: (index) {
        if (index == currentIndex) return;
        Widget destino;
        switch (index) {
          case 0: destino = const PerfilScreen(); break;
          case 1: destino = const CitasScreen(); break;
          case 2: destino = const PanelScreen(); break;
          case 3: destino = const MatchysScreen(); break;
          default: destino = const ChatScreen();
        }
        Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => destino), (route) => false);
      },
    );
  }
  static BottomNavigationBarItem _navItem(String asset, String label) => BottomNavigationBarItem(icon: SizedBox(height: 24, child: Image.asset(asset, width: 22, height: 22)), label: label);
}