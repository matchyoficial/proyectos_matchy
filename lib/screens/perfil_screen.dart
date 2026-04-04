// 📂 lib/screens/perfil_screen.dart
// ✅ PERFIL BLINDADO (DOBLE CONFIRMACIÓN + BURBUJAS MATCHY)
// 🔥 FIX CRÍTICO UX: Diálogo de doble confirmación antes de destruir el perfil.
// 🔥 FIX CRÍTICO UI: Reemplazo total de Snackbars por Burbujas Flotantes Matchy.
// 🔥 FIX: Spinners de carga aislados (Solo gira el botón que presionas).
// 🔥 CACHÉ PRO: CachedNetworkImage aplicado a las fotos 2, 3, 4 y 5 de la galería.
// 🛡️ FIX CORREOS: Texto plano simple con datos clave del usuario.
// 💎 NUEVO: Inyección del Check Azul y Tarjeta de Biometría (Seguridad Anti-Fakes)
// 📐 FIX UI: Etiqueta "PERFIL VERIFICADO" blindada contra desbordamiento (Overflow).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proyectos_matchy/widgets/matchy_page_layout.dart';

import 'package:proyectos_matchy/screens/panel_screen.dart';
import 'package:proyectos_matchy/screens/citas_screen.dart';
import 'package:proyectos_matchy/screens/matchys_screen.dart';
import 'package:proyectos_matchy/screens/chat_screen.dart';
import 'package:proyectos_matchy/screens/datos_screen.dart';

import 'package:proyectos_matchy/state/profile_form_provider.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:proyectos_matchy/screens/splash_screen.dart';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:proyectos_matchy/widgets/foto_perfil_usuario.dart';
import 'package:proyectos_matchy/widgets/termometro_confiabilidad.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
  String? _activeAction;

  static const String _kProfileDraftKey = 'matchy_profile_draft_v1';
  static const String _kProfilePublishedKey = 'matchy_profile_published_v1';
  static const String _kOnboardingCompletedKey = 'matchy_onboarding_completed_v1';
  static const String _kUsersCollection = 'users';

  // 🛡️ CHINCHES MAESTROS
  static const List<Color> kBtnEditProfileGradient = [Color(0xFF00B4DB), Color(0xFF0083B0)];
  static const List<Color> kBtnLogoutGradient = [Color(0xFF0B1F3A), Color(0xFF050F1E)];
  static const List<Color> kBtnDeleteGradient = [Color(0xFFB00020), Color(0xFF600010)];
  static const List<Color> kBtnSoporteGradient = [Color(0xFF6B4EE6), Color(0xFF4527A0)];

  static const List<Shadow> kTextShadow = [
    Shadow(color: Colors.black, blurRadius: 10, offset: Offset(0, 4))
  ];
  static const List<BoxShadow> kChipShadow = [
    BoxShadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 3))
  ];

  static const double kButtonRadius = 25.0;
  static const List<BoxShadow> kButtonShadow = [
    BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 4))
  ];

  void _goSplash() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
          (route) => false,
    );
  }

  // 🔥 SISTEMA DE BURBUJAS FLOTANTES MATCHY STYLE INYECTADO
  void _mostrarBurbuja(String mensaje, Color color, IconData icono) {
    if (!mounted) return;
    final overlayState = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => SafeArea(
        child: Align(
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Material(
              color: Colors.transparent,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 500),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E2C).withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.7), width: 2),
                    boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 5))],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
                        child: Icon(icono, color: color, size: 28),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                          child: Text(
                            mensaje,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Poppins'),
                          )
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlayState.insert(entry);
    Future.delayed(const Duration(seconds: 4), () {
      if (entry.mounted) entry.remove();
    });
  }

  // 🚪 FUNCIÓN CERRAR SESIÓN
  Future<void> _logout() async {
    if (_activeAction != null) return;
    setState(() => _activeAction = 'logout');
    try {
      ref.invalidate(profileFormProvider);
      try { await GoogleSignIn().disconnect(); } catch (_) { await GoogleSignIn().signOut(); }
      await FirebaseAuth.instance.signOut();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kProfileDraftKey);
      await prefs.remove(_kProfilePublishedKey);
      await prefs.remove(_kOnboardingCompletedKey);

      await ref.read(profileFormProvider.notifier).clearDraft();

      if (!mounted) return;
      _goSplash();
    } catch (e) {
      if (mounted) _mostrarBurbuja('Error al cerrar sesión: $e', const Color(0xFFFF5252), Icons.error_outline_rounded);
    } finally {
      if (mounted) setState(() => _activeAction = null);
    }
  }

  // 🛡️ DOBLE CONFIRMACIÓN PARA BORRAR PERFIL
  void _confirmarBorrarPerfil() {
    if (_activeAction != null) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: const Color(0xFFB00020), width: 2),
            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, 10))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_rounded, color: Color(0xFFB00020), size: 50),
              const SizedBox(height: 15),
              const Text(
                "¿ELIMINAR TU CUENTA?",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, fontFamily: 'Poppins'),
              ),
              const SizedBox(height: 15),
              const Text(
                "Esta acción es irreversible. Perderás todos tus matches, mensajes y configuración de perfil para siempre.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("CANCELAR", style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _deleteProfile();
                      },
                      child: Container(
                        height: 45,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: kBtnDeleteGradient),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Text("SÍ, BORRAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  // 💀 FUNCIÓN DESTRUIR PERFIL
  Future<void> _deleteProfile() async {
    if (_activeAction != null) return;
    setState(() => _activeAction = 'delete');
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection(_kUsersCollection).doc(user.uid).delete();
        await user.delete();
      }

      ref.invalidate(profileFormProvider);
      try { await GoogleSignIn().disconnect(); } catch (_) { await GoogleSignIn().signOut(); }
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (!mounted) return;
      _goSplash();
    } catch (e) {
      if (mounted) {
        _mostrarBurbuja('Por tu seguridad, debes cerrar sesión y volver a entrar antes de borrar tu cuenta.', const Color(0xFFB00020), Icons.security_rounded);
      }
    } finally {
      if (mounted) setState(() => _activeAction = null);
    }
  }

  // ✉️ DIÁLOGO DE CONTACTO (TEXTO PLANO)
  void _mostrarDialogoContacto() {
    if (_activeAction != null) return;

    // Obtenemos los datos de Riverpod
    final perfilData = ref.read(profileFormProvider);

    showDialog(
      context: context,
      builder: (context) => _ContactDialog(
        onSend: (mensaje) async {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null || mensaje.trim().isEmpty) return;

          try {
            await FirebaseFirestore.instance.collection('buzon_soporte').add({
              'uid': user.uid,
              'email_usuario': user.email ?? 'Sin email',
              'mensaje': mensaje,
              'fecha': FieldValue.serverTimestamp(),
              'estado': 'pendiente',
              'to': 'matchyoficial@gmail.com',

              // 🔥 CAJA MESSAGE EN TEXTO PLANO
              'message': {
                'subject': 'SOPORTE MATCHY - Nuevo mensaje de ${perfilData.nombre}',
                'text': 'DATOS DEL USUARIO:\nNombre: ${perfilData.nombre}\nEmail: ${user.email ?? 'Sin correo'}\nUID: ${user.uid}\n\nMENSAJE ENVIADO:\n$mensaje',
              }
            });

            if (mounted) {
              _mostrarBurbuja("¡Mensaje enviado! Te responderemos pronto.", const Color(0xFF00E676), Icons.check_circle_outline_rounded);
            }
          } catch (e) {
            if (mounted) _mostrarBurbuja("Error al enviar: $e", const Color(0xFFFF5252), Icons.error_outline_rounded);
            rethrow;
          }
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_bootstrapped) return;
      _bootstrapped = true;
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await ref.read(profileFormProvider.notifier).loadDraft();
      await ref.read(profileFormProvider.notifier).bootstrapFromFirestore();
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final state = ref.watch(profileFormProvider);

    return Scaffold(
      body: Stack(
        children: [
          MatchyPageLayout(
            backgroundAsset: 'assets/images/fondo.jpg',
            logoAsset: 'assets/images/logomatchyplano.png',
            scrollContent: _PerfilContent(
              textTheme: textTheme,
              state: state,
              activeAction: _activeAction,
              onLogout: _logout,
              onDeleteProfile: _confirmarBorrarPerfil,
              onContact: _mostrarDialogoContacto,
            ),
            topSpacing: 35,
            logoHeight: 45,
            spaceLogoToScroll: 15,
          ),
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
  final String? activeAction;
  final Future<void> Function() onLogout;
  final VoidCallback onDeleteProfile;
  final VoidCallback onContact;

  const _PerfilContent({
    required this.textTheme,
    required this.state,
    required this.activeAction,
    required this.onLogout,
    required this.onDeleteProfile,
    required this.onContact,
  });

  @override
  Widget build(BuildContext context) {
    final paisOrigen = (state.paisOrigen ?? '').trim();
    final ciudadOrigen = (state.ciudadOrigen ?? '').trim();

    final sobreMi = [
      if (state.estatura.trim().isNotEmpty) '📏 ${state.estatura.trim()}',
      if (paisOrigen.isNotEmpty) '🌍 País de origen: $paisOrigen',
      if (ciudadOrigen.isNotEmpty) '🏙️ Ciudad de origen: $ciudadOrigen',
      ...state.sobreMiSeleccion
    ];

    final busco = List<String>.from(state.buscoSeleccion);
    final intereses = List<String>.from(state.interesesSeleccion);
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FotoTarjeta(
          imagePathOrAssetOrUrl: state.profilePhotoUrl ?? state.photoUrls.firstOrNull ?? state.fotosCargadas.firstOrNull,
          smartUid: myUid,
          height: 450,
          overlay: (context) => _ProfileOverlay(state: state, textTheme: textTheme),
        ),

        const SizedBox(height: 16),
        if (myUid != null) _BarraPuntualidadLive(uid: myUid),
        const SizedBox(height: 6),

        // 🔥 INYECCIÓN: Tarjeta de Biometría Anti-Falsificación
        if (state.isVerified)
          _CardVerificacionBiometrica(textTheme: textTheme),

        _CardTexto(titulo: 'Biografía', texto: state.biografia.isEmpty ? 'Aún no has escrito tu biografía.' : state.biografia, textTheme: textTheme),

        if (sobreMi.isNotEmpty) _CardChips(titulo: 'Sobre mí', items: sobreMi, textTheme: textTheme),

        if (state.photoUrls.length >= 2 || state.fotosCargadas.length >= 2)
          _FotoTarjeta(imagePathOrAssetOrUrl: (state.photoUrls.length >= 2) ? state.photoUrls[1] : state.fotosCargadas[1], height: 400),

        if (busco.isNotEmpty) _CardChips(titulo: 'Busco...', items: busco, textTheme: textTheme),

        if (state.photoUrls.length >= 3 || state.fotosCargadas.length >= 3)
          _FotoTarjeta(imagePathOrAssetOrUrl: (state.photoUrls.length >= 3) ? state.photoUrls[2] : state.fotosCargadas[2], height: 400),

        if (intereses.isNotEmpty) _CardChips(titulo: 'Intereses y Hobbies', items: intereses, textTheme: textTheme),

        _CardTexto(titulo: 'Un detalle que me enamora', texto: state.detalle.isEmpty ? 'Aún no has agregado este detalle.' : state.detalle, textTheme: textTheme),

        if (state.photoUrls.length >= 4 || state.fotosCargadas.length >= 4)
          _FotoTarjeta(imagePathOrAssetOrUrl: (state.photoUrls.length >= 4) ? state.photoUrls[3] : state.fotosCargadas[3], height: 400),

        if (state.photoUrls.length >= 5 || state.fotosCargadas.length >= 5)
          _FotoTarjeta(imagePathOrAssetOrUrl: (state.photoUrls.length >= 5) ? state.photoUrls[4] : state.fotosCargadas[4], height: 400),

        const SizedBox(height: 25),

        // 🔥 BOTONES CON SPINNERS INDEPENDIENTES
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _PremiumButton(
            text: 'EDITAR PERFIL',
            gradient: _PerfilScreenState.kBtnEditProfileGradient,
            busy: activeAction == 'edit',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DatosScreen())),
            icon: Icons.edit_rounded,
          ),
        ),
        const SizedBox(height: 35),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _PremiumButton(
            text: 'CERRAR SESIÓN',
            gradient: _PerfilScreenState.kBtnLogoutGradient,
            busy: activeAction == 'logout',
            onTap: onLogout,
            icon: Icons.logout_rounded,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _PremiumButton(
            text: 'BORRAR PERFIL',
            gradient: _PerfilScreenState.kBtnDeleteGradient,
            busy: activeAction == 'delete',
            onTap: onDeleteProfile,
            icon: Icons.delete_forever_rounded,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _PremiumButton(
            text: 'CONTÁCTANOS',
            gradient: _PerfilScreenState.kBtnSoporteGradient,
            busy: false,
            onTap: onContact,
            icon: Icons.support_agent_rounded,
          ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }
}

// 🔹 DIÁLOGO DE CONTACTO
class _ContactDialog extends StatefulWidget {
  final Function(String) onSend;
  const _ContactDialog({required this.onSend});

  @override
  State<_ContactDialog> createState() => _ContactDialogState();
}

class _ContactDialogState extends State<_ContactDialog> {
  final TextEditingController _ctrl = TextEditingController();
  bool _sending = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white24, width: 1),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, 10))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.help_outline_rounded, color: Color(0xFFBEB3FF), size: 40),
            const SizedBox(height: 15),
            const Text(
              "¿CÓMO PODEMOS AYUDARTE?",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, fontFamily: 'Poppins'),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _ctrl,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Escribe tu pregunta o comentario...",
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.all(15),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("CANCELAR", style: TextStyle(color: Colors.white54)),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: _sending ? null : () async {
                      if (_ctrl.text.trim().isEmpty) return;
                      setState(() => _sending = true);
                      try {
                        await widget.onSend(_ctrl.text);
                        if (mounted) Navigator.pop(context);
                      } catch (e) {
                        if (mounted) setState(() => _sending = false);
                      }
                    },
                    child: Container(
                      height: 45,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF6B4EE6), Color(0xFF4527A0)]),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: _sending
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("ENVIAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

// 🔹 SUB-WIDGETS Y HELPERS
class _ProfileOverlay extends StatelessWidget {
  final ProfileFormState state;
  final TextTheme textTheme;
  const _ProfileOverlay({required this.state, required this.textTheme});

  @override
  Widget build(BuildContext context) {
    final pais = (state.paisSeleccionado ?? '').trim();
    final ciudad = (state.ciudadSeleccionada ?? '').trim();
    final paisOrigen = (state.paisOrigen ?? '').trim();
    final ciudadOrigen = (state.ciudadOrigen ?? '').trim();

    String stringUbicacion = '';

    if (ciudad.isEmpty && pais.isEmpty) {
      stringUbicacion = 'Sin ubicación';
    } else {
      if (paisOrigen.isNotEmpty && pais.isNotEmpty && paisOrigen != pais) {
        stringUbicacion = '🌍 De $paisOrigen, ahora en $ciudad - $pais';
      } else if (ciudadOrigen.isNotEmpty && ciudad.isNotEmpty && ciudadOrigen != ciudad) {
        stringUbicacion = '🏙️ De $ciudadOrigen, ahora en $ciudad - $pais';
      } else {
        stringUbicacion = '📍 $ciudad - $pais';
      }
    }

    return Stack(children: [
      Positioned.fill(child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.95)])))),
      Positioned(left: 30, bottom: 30, right: 30, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // 🔥 FIX UI: Etiqueta "PERFIL VERIFICADO" blindada con FittedBox
        if (state.isVerified)
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF00B4DB).withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF00B4DB), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified, color: Color(0xFF00B4DB), size: 14),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      "PERFIL VERIFICADO",
                      style: textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF00B4DB),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        FittedBox(fit: BoxFit.scaleDown, child: Row(children: [Text(state.nombre, style: textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, shadows: _PerfilScreenState.kTextShadow)), Text(', ${state.edad}', style: textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, shadows: _PerfilScreenState.kTextShadow))])),
        const SizedBox(height: 4),
        FittedBox(fit: BoxFit.scaleDown, child: Text(state.profesion.isEmpty ? '—' : state.profesion, style: textTheme.bodyMedium?.copyWith(color: Colors.white, fontSize: 16, shadows: _PerfilScreenState.kTextShadow))),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            stringUbicacion,
            maxLines: 1,
            style: textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontSize: 14,
                shadows: _PerfilScreenState.kTextShadow
            ),
          ),
        ),
      ])),
    ]);
  }
}

// 🔥 INYECCIÓN: Tarjeta exclusiva para Biometría Facial
class _CardVerificacionBiometrica extends StatelessWidget {
  final TextTheme textTheme;
  const _CardVerificacionBiometrica({required this.textTheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x33FFFFFF), // Mismo fondo gris translúcido de las otras tarjetas
        borderRadius: BorderRadius.circular(20),
        boxShadow: _PerfilScreenState.kChipShadow,
        border: Border.all(color: const Color(0xFF00B4DB).withOpacity(0.5), width: 1.5), // Borde neón sutil
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF00B4DB).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified, color: Color(0xFF00B4DB), size: 28),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              "Este perfil fue verificado con biometría facial ✔️",
              style: textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardTexto extends StatelessWidget {
  final String titulo; final String texto; final TextTheme textTheme;
  const _CardTexto({required this.titulo, required this.texto, required this.textTheme});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0x33FFFFFF), borderRadius: BorderRadius.circular(20), boxShadow: _PerfilScreenState.kChipShadow, border: Border.all(color: Colors.white12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [FittedBox(fit: BoxFit.scaleDown, child: Text(titulo, style: textTheme.titleSmall?.copyWith(color: const Color(0xFFB3D9FF), fontSize: 18, fontWeight: FontWeight.bold, shadows: _PerfilScreenState.kTextShadow))), const SizedBox(height: 8), Text(texto, style: textTheme.bodyMedium?.copyWith(color: Colors.white, fontSize: 14))]),
    );
  }
}

class _CardChips extends StatelessWidget {
  final String titulo; final List<String> items; final TextTheme textTheme;
  const _CardChips({required this.titulo, required this.items, required this.textTheme});

  List<List<String>> _buildRows(List<String> all) {
    const int maxShortLength = 14; final rows = <List<String>>[]; int i = 0;
    while (i < all.length) {
      final current = all[i];
      if (current.length > maxShortLength) { rows.add([current]); i++; }
      else if (i + 1 < all.length && all[i+1].length <= maxShortLength) { rows.add([current, all[i+1]]); i += 2; }
      else { rows.add([current]); i++; }
    }
    return rows;
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0x33FFFFFF), borderRadius: BorderRadius.circular(20), boxShadow: _PerfilScreenState.kChipShadow, border: Border.all(color: Colors.white12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [FittedBox(fit: BoxFit.scaleDown, child: Text(titulo, style: textTheme.titleSmall?.copyWith(color: const Color(0xFFB3D9FF), fontSize: 18, fontWeight: FontWeight.bold, shadows: _PerfilScreenState.kTextShadow))), const SizedBox(height: 10), Column(children: _buildRows(items).map((fila) => Row(children: fila.map((item) => Expanded(child: Container(margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4), padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10), decoration: BoxDecoration(color: const Color(0x66FFFFFF), borderRadius: BorderRadius.circular(50), boxShadow: _PerfilScreenState.kChipShadow), child: Text(item, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))))).toList())).toList())]),
    );
  }
}

class _FotoTarjeta extends StatelessWidget {
  final String? imagePathOrAssetOrUrl; final double height; final Widget Function(BuildContext context)? overlay; final String? smartUid;
  const _FotoTarjeta({required this.imagePathOrAssetOrUrl, required this.height, this.overlay, this.smartUid});

  @override
  Widget build(BuildContext context) {
    Widget background = Container(color: Colors.white10, child: const Center(child: Icon(Icons.person, color: Colors.white24, size: 80)));
    final raw = (imagePathOrAssetOrUrl ?? '').trim();

    if (smartUid != null) {
      background = FotoPerfilUsuario(uid: smartUid!, fit: BoxFit.cover, alignment: Alignment.topCenter);
    } else if (raw.isNotEmpty) {
      if (raw.startsWith('http')) {
        background = CachedNetworkImage(
          key: ValueKey(raw),
          imageUrl: raw,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          placeholder: (context, url) => Container(
              color: const Color(0xFF1A1A1A),
              child: const Center(child: CircularProgressIndicator(color: Color(0xFFBEB3FF), strokeWidth: 2))
          ),
          errorWidget: (context, url, error) => Container(
              color: Colors.white10,
              child: const Center(child: Icon(Icons.broken_image, color: Colors.white24, size: 80))
          ),
        );
      } else if (raw.startsWith('assets/')) {
        background = Image.asset(raw, fit: BoxFit.cover, alignment: Alignment.topCenter);
      } else {
        background = Image.file(File(raw), fit: BoxFit.cover, alignment: Alignment.topCenter);
      }
    }

    return Container(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), height: height, decoration: BoxDecoration(borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.45), blurRadius: 10, offset: const Offset(0, 6))]), clipBehavior: Clip.antiAlias, child: Stack(fit: StackFit.expand, children: [background, if (overlay != null) overlay!(context)]));
  }
}

class _BarraPuntualidadLive extends StatelessWidget {
  final String uid; const _BarraPuntualidadLive({required this.uid});
  @override Widget build(BuildContext context) { return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(), builder: (context, snapshot) { if (!snapshot.hasData) return const SizedBox(); final data = snapshot.data!.data() ?? {}; return TermometroConfiabilidad(puntaje: (data['confiabilidad'] as num?)?.toInt() ?? 100, mostrarReloj: false); }); }
}

class _PremiumButton extends StatelessWidget {
  final String text; final List<Color> gradient; final bool busy; final VoidCallback onTap; final IconData? icon;
  const _PremiumButton({required this.text, required this.gradient, required this.busy, required this.onTap, this.icon});
  @override Widget build(BuildContext context) { return GestureDetector(onTap: busy ? null : onTap, child: Container(height: 50, decoration: BoxDecoration(gradient: LinearGradient(colors: gradient), borderRadius: BorderRadius.circular(_PerfilScreenState.kButtonRadius), boxShadow: _PerfilScreenState.kButtonShadow, border: Border.all(color: Colors.white24)), alignment: Alignment.center, child: busy ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)) : Row(mainAxisAlignment: MainAxisAlignment.center, children: [if (icon != null) ...[Icon(icon, color: Colors.white, size: 20), const SizedBox(width: 8)], Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))]))); }
}

class _MatchyBottomNav extends StatelessWidget {
  final int currentIndex; const _MatchyBottomNav({required this.currentIndex});
  @override Widget build(BuildContext context) { return BottomNavigationBar(backgroundColor: Colors.black, type: BottomNavigationBarType.fixed, currentIndex: currentIndex, selectedItemColor: const Color(0xFFE0D4FF), unselectedItemColor: Colors.white70, items: [BottomNavigationBarItem(icon: Image.asset('assets/images/profile.png', width: 22), label: 'Perfil'), BottomNavigationBarItem(icon: Image.asset('assets/images/citas.png', width: 22), label: 'Citas'), BottomNavigationBarItem(icon: Image.asset('assets/images/panel.png', width: 22), label: 'Panel'), BottomNavigationBarItem(icon: Image.asset('assets/images/matchy.png', width: 22), label: 'Matchy'), BottomNavigationBarItem(icon: Image.asset('assets/images/chat.png', width: 22), label: 'Chat')], onTap: (i) => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => [const PerfilScreen(), const CitasScreen(), const PanelScreen(), const MatchysScreen(), const ChatScreen()][i]))); }
}