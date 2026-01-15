// 📂 lib/screens/perfil_screen.dart
// ✅ PERFIL conectado a ProfileFormProvider (DatosScreen)
// ✅ FIX: carga draft automáticamente al entrar a Perfil
// ✅ Cache-safe: bootstrap/hydrate desde Firestore
// ✅ Soporta fotos real (File) + assets + URLs (Firebase Storage)
// ✅ BOTONES AL FINAL:
//    - CERRAR SESIÓN (azul oscuro, letras blancas)
//    - BORRAR PERFIL (rojo) -> borra Firestore + Storage fotos + local prefs + intenta borrar Auth user

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

  // 🔴 CHINCHE LOADING 1 — bloquea taps durante logout/delete
  bool _busy = false;

  // 🔴 CHINCHE PREFS 1 — llaves Matchy a limpiar
  static const String _kProfileDraftKey = 'matchy_profile_draft_v1';
  static const String _kProfilePublishedKey = 'matchy_profile_published_v1';
  static const String _kOnboardingCompletedKey = 'matchy_onboarding_completed_v1';

  // 🔴 CHINCHE FIRESTORE 1 — colección users
  static const String _kUsersCollection = 'users';

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
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  // ✅ Borra por carpeta estándar (si existe)
  Future<void> _deleteUserPhotosFromStorageFolder(String uid) async {
    try {
      final root = FirebaseStorage.instance.ref().child('users/$uid/photos');
      final list = await root.listAll();

      for (final item in list.items) {
        try {
          await item.delete();
        } catch (_) {}
      }

      for (final prefix in list.prefixes) {
        try {
          final sub = await prefix.listAll();
          for (final item in sub.items) {
            try {
              await item.delete();
            } catch (_) {}
          }
        } catch (_) {}
      }
    } catch (_) {
      // no rompe el borrado
    }
  }

  // ✅ Borra URLs explícitas (más confiable si cambiaste rutas en Storage)
  Future<void> _deleteStorageUrls(List<String> urls) async {
    for (final u in urls) {
      final url = u.trim();
      if (url.isEmpty) continue;
      if (!(url.startsWith('http://') || url.startsWith('https://'))) continue;

      try {
        final ref = FirebaseStorage.instance.refFromURL(url);
        await ref.delete();
      } catch (_) {
        // no rompe
      }
    }
  }

  Future<void> _deleteProfile() async {
    if (_busy) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      _goSplash();
      return;
    }

    final first = await _confirmDialog(
      title: 'Borrar perfil',
      message:
      'Esto eliminará tu perfil de Matchy (datos y fotos). Esta acción no se puede deshacer.',
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

      // 0) Lee el doc para capturar URLs (si existen)
      final docRef =
      FirebaseFirestore.instance.collection(_kUsersCollection).doc(uid);
      final snap = await docRef.get();

      final urlsToDelete = <String>[];
      if (snap.exists) {
        final data = snap.data();
        if (data != null) {
          final profilePhotoUrl = (data['profilePhotoUrl'] ?? '').toString();
          if (profilePhotoUrl.trim().isNotEmpty) {
            urlsToDelete.add(profilePhotoUrl);
          }

          final raw = data['photoUrls'];
          if (raw is List) {
            for (final e in raw) {
              final s = e.toString();
              if (s.trim().isNotEmpty) urlsToDelete.add(s);
            }
          }
        }
      }

      // 1) Borra fotos por URLs (si existen)
      await _deleteStorageUrls(urlsToDelete);

      // 2) Borra carpeta estándar (por si hay fotos ahí)
      await _deleteUserPhotosFromStorageFolder(uid);

      // 3) Borra doc Firestore
      await docRef.delete();

      // 4) Limpia local
      await _clearMatchyLocal();

      // 5) Intenta borrar cuenta Auth (puede fallar si no hay recent login)
      try {
        await user.delete();
      } catch (e) {
        // Si falla por recent login, igual nos vamos a Splash ya sin perfil
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '⚠️ Perfil borrado, pero no se pudo borrar la cuenta automáticamente (puede requerir re-login).',
              ),
            ),
          );
        }
      }

      // 6) Cierra sesión siempre (por seguridad)
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Perfil borrado.')),
      );
      _goSplash();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error borrando perfil: $e')),
      );
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
      if (user == null) {
        if (!mounted) return;
        _goSplash();
        return;
      }

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
      body: MatchyPageLayout(
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
        logoHeight: 50,
        logoOffsetY: 0,
        spaceLogoToScroll: 15,
      ),
      bottomNavigationBar:
      widget.showBottomNav ? const _MatchyBottomNav(currentIndex: 0) : null,
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

    final parts =
    clean.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
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
        : (ciudad.isNotEmpty && pais.isNotEmpty)
        ? '$ciudad - $pais'
        : (ciudad.isNotEmpty ? ciudad : pais);

    final profesion =
    state.profesion.trim().isEmpty ? '—' : state.profesion.trim();

    final biografia = state.biografia.trim().isEmpty
        ? 'Aún no has escrito tu biografía.'
        : state.biografia.trim();

    final detalle = state.detalle.trim().isEmpty
        ? 'Aún no has agregado este detalle.'
        : state.detalle.trim();

    final sobreMi = [
      if (state.estatura.trim().isNotEmpty) '📏 ${state.estatura.trim()}',
      ...state.sobreMiSeleccion,
    ];

    final busco = List<String>.from(state.buscoSeleccion);
    final intereses = List<String>.from(state.interesesSeleccion);

    final galeria = _resolveGaleria();
    final principal = _resolveFotoPrincipal();
    final bool tieneFotos = principal != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FotoTarjeta(
            imagePathOrAssetOrUrl: principal,
            height: 450, // 🔴 CHINCHE J
            overlay: (context) {
              return Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      height: 180, // 🔴 CHINCHE K
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.95),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 30, // 🔴 CHINCHE L
                    bottom: 30, // 🔴 CHINCHE M
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              nombre,
                              style: textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontSize: 28, // 🔴 CHINCHE N
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              ', $edad',
                              style: textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontSize: 28, // 🔴 CHINCHE N
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profesion,
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontSize: 16, // 🔴 CHINCHE O
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ciudadPais,
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontSize: 14, // 🔴 CHINCHE P
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!tieneFotos)
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.50),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            'Agrega al menos 1 foto en “Datos”',
                            style: textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),

          const SizedBox(height: 16),

          _CardTexto(titulo: 'Biografía', texto: biografia, textTheme: textTheme),

          if (sobreMi.isNotEmpty)
            _CardChips(titulo: 'Sobre mí', items: sobreMi, textTheme: textTheme),

          if (galeria.length >= 2)
            _FotoTarjeta(
              imagePathOrAssetOrUrl: galeria[1],
              height: 400, // 🔴 CHINCHE Q
            ),

          if (busco.isNotEmpty)
            _CardChips(titulo: 'Busco...', items: busco, textTheme: textTheme),

          if (galeria.length >= 3)
            _FotoTarjeta(
              imagePathOrAssetOrUrl: galeria[2],
              height: 400, // 🔴 CHINCHE R
            ),

          if (intereses.isNotEmpty)
            _CardChips(
              titulo: 'Intereses y Hobbies',
              items: intereses,
              textTheme: textTheme,
            ),

          if (galeria.length >= 4)
            _FotoTarjeta(
              imagePathOrAssetOrUrl: galeria[3],
              height: 400,
            ),

          _CardTexto(
            titulo: 'Un detalle que me enamora',
            texto: detalle,
            textTheme: textTheme,
          ),

          if (galeria.length >= 5)
            _FotoTarjeta(
              imagePathOrAssetOrUrl: galeria[4],
              height: 400,
            ),

          const SizedBox(height: 20),

          // =========================================================
          // ✅ BOTONES AL FINAL
          // =========================================================

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20), // 🔴 CHINCHE BTN 1
            child: SizedBox(
              height: 50, // 🔴 CHINCHE BTN 2
              child: ElevatedButton(
                onPressed: busy ? null : () async => await onLogout(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B1F3A), // 🔴 CHINCHE AZUL OSCURO
                  shape: const StadiumBorder(),
                ),
                child: busy
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text(
                  'CERRAR SESIÓN',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: busy ? null : () async => await onDeleteProfile(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB00020), // 🔴 CHINCHE ROJO
                  shape: const StadiumBorder(),
                ),
                child: busy
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text(
                  'BORRAR PERFIL',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 40), // 🔴 CHINCHE S
        ],
      ),
    );
  }
}

// ================================================================
// 🔹 COMPONENTES
// ================================================================

class _FotoTarjeta extends StatelessWidget {
  final String? imagePathOrAssetOrUrl;
  final double height;
  final Widget Function(BuildContext context)? overlay;

  const _FotoTarjeta({
    required this.imagePathOrAssetOrUrl,
    required this.height,
    this.overlay,
  });

  bool _isAsset(String v) => v.startsWith('assets/');
  bool _isUrl(String v) => v.startsWith('http://') || v.startsWith('https://');

  Widget _fallback() {
    return Container(
      color: const Color(0x33FFFFFF),
      child: const Center(
        child: Icon(Icons.person, color: Colors.white70, size: 70),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget background = _fallback();

    final raw = (imagePathOrAssetOrUrl ?? '').trim();
    if (raw.isNotEmpty) {
      if (_isUrl(raw)) {
        background = Image.network(
          raw,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            );
          },
          errorBuilder: (_, __, ___) => _fallback(),
        );
      } else if (_isAsset(raw)) {
        background = Image.asset(
          raw,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          errorBuilder: (_, __, ___) => _fallback(),
        );
      } else {
        background = Image.file(
          File(raw),
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          errorBuilder: (_, __, ___) => _fallback(),
        );
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16), // 🔴 CHINCHE T
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25), // 🔴 CHINCHE U
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          background,
          if (overlay != null) overlay!(context),
        ],
      ),
    );
  }
}

class _CardTexto extends StatelessWidget {
  final String titulo;
  final String texto;
  final TextTheme textTheme;

  const _CardTexto({
    required this.titulo,
    required this.texto,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), // 🔴 CHINCHE V/W
      padding: const EdgeInsets.all(16), // 🔴 CHINCHE X
      decoration: BoxDecoration(
        color: const Color(0x33FFFFFF),
        borderRadius: BorderRadius.circular(20), // 🔴 CHINCHE Y
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: textTheme.titleSmall?.copyWith(
              color: const Color(0xFFB3D9FF),
              fontSize: 18, // 🔴 CHINCHE Z
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            texto,
            style: textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontSize: 14, // 🔴 CHINCHE AA
            ),
          ),
        ],
      ),
    );
  }
}

class _CardChips extends StatelessWidget {
  final String titulo;
  final List<String> items;
  final TextTheme textTheme;

  const _CardChips({
    required this.titulo,
    required this.items,
    required this.textTheme,
  });

  List<List<String>> _buildRows(List<String> all) {
    const int maxShortLength = 14; // 🔴 CHINCHE AB
    final rows = <List<String>>[];
    int i = 0;

    while (i < all.length) {
      final current = all[i];
      final isCurrentLong = current.length > maxShortLength;

      if (isCurrentLong) {
        rows.add([current]);
        i += 1;
      } else if (i + 1 < all.length) {
        final next = all[i + 1];
        final isNextLong = next.length > maxShortLength;

        if (isNextLong) {
          rows.add([current]);
          i += 1;
        } else {
          rows.add([current, next]);
          i += 2;
        }
      } else {
        rows.add([current]);
        i += 1;
      }
    }
    return rows;
  }

  Widget _buildChip(String text) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4), // 🔴 CHINCHE AC
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10), // 🔴 CHINCHE AD
      decoration: BoxDecoration(
        color: const Color(0x66FFFFFF),
        borderRadius: BorderRadius.circular(50), // 🔴 CHINCHE AE
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              softWrap: false, // 🔴 CHINCHE AF
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontSize: 13, // 🔴 CHINCHE AG
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = _buildRows(items);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), // 🔴 CHINCHE AH/AI
      padding: const EdgeInsets.all(16), // 🔴 CHINCHE AJ
      decoration: BoxDecoration(
        color: const Color(0x33FFFFFF),
        borderRadius: BorderRadius.circular(20), // 🔴 CHINCHE AK
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: textTheme.titleSmall?.copyWith(
              color: const Color(0xFFB3D9FF),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Column(
            children: rows.map((fila) {
              if (fila.length == 1) {
                return Row(children: [Expanded(child: _buildChip(fila[0]))]);
              } else {
                return Row(
                  children: [
                    Expanded(child: _buildChip(fila[0])),
                    const SizedBox(width: 10), // 🔴 CHINCHE AL
                    Expanded(child: _buildChip(fila[1])),
                  ],
                );
              }
            }).toList(),
          ),
        ],
      ),
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
    const Color navBackground = Color(0xCC000000);
    const Color selectedColor = Color(0xFFE0D4FF);
    final Color unselectedColor = Colors.white70;

    return BottomNavigationBar(
      backgroundColor: navBackground,
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      selectedItemColor: selectedColor,
      unselectedItemColor: unselectedColor,
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
          case 0:
            destino = const PerfilScreen();
            break;
          case 1:
            destino = const CitasScreen();
            break;
          case 2:
            destino = const PanelScreen();
            break;
          case 3:
            destino = const MatchysScreen();
            break;
          default:
            destino = const ChatScreen();
        }

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => destino),
              (route) => false,
        );
      },
    );
  }

  static BottomNavigationBarItem _navItem(String asset, String label) {
    return BottomNavigationBarItem(
      icon: SizedBox(
        height: 24,
        child: Image.asset(asset, width: 22, height: 22),
      ),
      label: label,
    );
  }
}
