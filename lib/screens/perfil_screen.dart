// 📂 lib/screens/perfil_screen.dart
// ✅ PERFIL (FIX: MANEJO DE ERRORES EN CONTACTO)
// 🔥 FIX: Agregado try-catch en el diálogo de contacto para evitar que se congele ("piense") si hay error.
// 🔥 UI: Diseño Premium y lógica intacta.

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
import 'package:proyectos_matchy/widgets/foto_perfil_usuario.dart';
import 'package:proyectos_matchy/widgets/termometro_confiabilidad.dart';

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

  static const String _kProfileDraftKey = 'matchy_profile_draft_v1';
  static const String _kProfilePublishedKey = 'matchy_profile_published_v1';
  static const String _kOnboardingCompletedKey = 'matchy_onboarding_completed_v1';
  static const String _kUsersCollection = 'users';

  // 🛡️ CHINCHES MAESTROS (ESTILO DATOS)
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

  Future<void> _logout() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kProfileDraftKey);
      await prefs.remove(_kProfilePublishedKey);
      await prefs.remove(_kOnboardingCompletedKey);
      await ref.read(profileFormProvider.notifier).clearDraft();
      if (!mounted) return;
      _goSplash();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteProfile() async {
    if (_busy) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) { if (!mounted) return; _goSplash(); return; }
    setState(() => _busy = true);
    _logout();
  }

  // 🔥 DIÁLOGO DE CONTACTO (CON MANEJO DE ERRORES)
  void _mostrarDialogoContacto() {
    showDialog(
      context: context,
      builder: (context) => _ContactDialog(
        onSend: (mensaje) async {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null || mensaje.trim().isEmpty) return;

          try {
            // Guardamos en Firebase (Esto disparará la extensión de email luego)
            await FirebaseFirestore.instance.collection('buzon_soporte').add({
              'uid': user.uid,
              'email_usuario': user.email ?? 'Sin email',
              'mensaje': mensaje,
              'fecha': FieldValue.serverTimestamp(),
              'estado': 'pendiente',
              'to': 'matchyoficial@gmail.com',
            });

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("¡Mensaje enviado! Te responderemos pronto."),
                  backgroundColor: Color(0xFF00E676),
                ),
              );
            }
          } catch (e) {
            // Si falla, mostramos error y relanzamos para que el diálogo sepa
            debugPrint("Error enviando soporte: $e");
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Error al enviar: $e"), backgroundColor: Colors.red),
              );
            }
            rethrow; // Importante para detener el spinner en el diálogo
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
              busy: _busy,
              onLogout: _logout,
              onDeleteProfile: _deleteProfile,
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
  final bool busy;
  final Future<void> Function() onLogout;
  final Future<void> Function() onDeleteProfile;
  final VoidCallback onContact;

  const _PerfilContent({
    required this.textTheme,
    required this.state,
    required this.busy,
    required this.onLogout,
    required this.onDeleteProfile,
    required this.onContact,
  });

  @override
  Widget build(BuildContext context) {
    final sobreMi = [if (state.estatura.trim().isNotEmpty) '📏 ${state.estatura.trim()}', ...state.sobreMiSeleccion];
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

        _CardTexto(titulo: 'Biografía', texto: state.biografia.isEmpty ? 'Aún no has escrito tu biografía.' : state.biografia, textTheme: textTheme),
        if (sobreMi.isNotEmpty) _CardChips(titulo: 'Sobre mí', items: sobreMi, textTheme: textTheme),

        if (state.photoUrls.length >= 2 || state.fotosCargadas.length >= 2)
          _FotoTarjeta(imagePathOrAssetOrUrl: (state.photoUrls.length >= 2) ? state.photoUrls[1] : state.fotosCargadas[1], height: 400),

        if (busco.isNotEmpty) _CardChips(titulo: 'Busco...', items: busco, textTheme: textTheme),

        if (state.photoUrls.length >= 3 || state.fotosCargadas.length >= 3)
          _FotoTarjeta(imagePathOrAssetOrUrl: (state.photoUrls.length >= 3) ? state.photoUrls[2] : state.fotosCargadas[2], height: 400),

        if (intereses.isNotEmpty) _CardChips(titulo: 'Intereses y Hobbies', items: intereses, textTheme: textTheme),

        _CardTexto(titulo: 'Un detalle que me enamora', texto: state.detalle.isEmpty ? 'Aún no has agregado este detalle.' : state.detalle, textTheme: textTheme),

        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _PremiumButton(text: 'CERRAR SESIÓN', gradient: _PerfilScreenState.kBtnLogoutGradient, busy: busy, onTap: onLogout),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _PremiumButton(text: 'BORRAR PERFIL', gradient: _PerfilScreenState.kBtnDeleteGradient, busy: busy, onTap: onDeleteProfile),
        ),
        const SizedBox(height: 12),
        // BOTÓN CONTÁCTANOS
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _PremiumButton(
            text: 'CONTÁCTANOS',
            gradient: _PerfilScreenState.kBtnSoporteGradient,
            busy: busy,
            onTap: () async { await Future.value(); onContact(); },
            icon: Icons.support_agent_rounded,
          ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }
}

// 🔹 DIÁLOGO DE CONTACTO (CON TRY-CATCH INTERNO)
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
                    // 🔥 LÓGICA DE SEGURIDAD PARA QUE NO SE CUELGUE
                    onTap: _sending ? null : () async {
                      if (_ctrl.text.trim().isEmpty) return;
                      setState(() => _sending = true);
                      try {
                        await widget.onSend(_ctrl.text);
                        if (mounted) Navigator.pop(context); // Éxito: Cierra
                      } catch (e) {
                        // Error: Detiene carga y deja intentar de nuevo
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

// 🔹 SUB-WIDGETS Y HELPERS (SIN CAMBIOS)
class _ProfileOverlay extends StatelessWidget {
  final ProfileFormState state;
  final TextTheme textTheme;
  const _ProfileOverlay({required this.state, required this.textTheme});
  @override
  Widget build(BuildContext context) {
    final pais = (state.paisSeleccionado ?? '').trim();
    final ciudad = (state.ciudadSeleccionada ?? '').trim();
    final ubicacion = (ciudad.isEmpty && pais.isEmpty) ? 'Sin ubicación' : '$ciudad - $pais';
    return Stack(children: [
      Positioned.fill(child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.95)])))),
      Positioned(left: 30, bottom: 30, right: 30, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        FittedBox(fit: BoxFit.scaleDown, child: Row(children: [Text(state.nombre, style: textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, shadows: _PerfilScreenState.kTextShadow)), Text(', ${state.edad}', style: textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, shadows: _PerfilScreenState.kTextShadow))])),
        const SizedBox(height: 4),
        FittedBox(fit: BoxFit.scaleDown, child: Text(state.profesion.isEmpty ? '—' : state.profesion, style: textTheme.bodyMedium?.copyWith(color: Colors.white, fontSize: 16, shadows: _PerfilScreenState.kTextShadow))),
        const SizedBox(height: 2),
        Text(ubicacion, style: textTheme.bodyMedium?.copyWith(color: Colors.white, fontSize: 14, shadows: _PerfilScreenState.kTextShadow)),
      ])),
    ]);
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
    if (smartUid != null) { background = FotoPerfilUsuario(uid: smartUid!, fit: BoxFit.cover, alignment: Alignment.topCenter); }
    else if (raw.isNotEmpty) { if (raw.startsWith('http')) { background = Image.network(raw, fit: BoxFit.cover, alignment: Alignment.topCenter); } else if (raw.startsWith('assets/')) { background = Image.asset(raw, fit: BoxFit.cover, alignment: Alignment.topCenter); } else { background = Image.file(File(raw), fit: BoxFit.cover, alignment: Alignment.topCenter); } }
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
  @override Widget build(BuildContext context) { return GestureDetector(onTap: busy ? null : onTap, child: Container(height: 50, decoration: BoxDecoration(gradient: LinearGradient(colors: gradient), borderRadius: BorderRadius.circular(_PerfilScreenState.kButtonRadius), boxShadow: _PerfilScreenState.kButtonShadow, border: Border.all(color: Colors.white24)), alignment: Alignment.center, child: busy ? const CircularProgressIndicator(color: Colors.white) : Row(mainAxisAlignment: MainAxisAlignment.center, children: [if (icon != null) ...[Icon(icon, color: Colors.white, size: 20), const SizedBox(width: 8)], Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))]))); }
}

class _MatchyBottomNav extends StatelessWidget {
  final int currentIndex; const _MatchyBottomNav({required this.currentIndex});
  @override Widget build(BuildContext context) { return BottomNavigationBar(backgroundColor: Colors.black, type: BottomNavigationBarType.fixed, currentIndex: currentIndex, selectedItemColor: const Color(0xFFE0D4FF), unselectedItemColor: Colors.white70, items: [BottomNavigationBarItem(icon: Image.asset('assets/images/profile.png', width: 22), label: 'Perfil'), BottomNavigationBarItem(icon: Image.asset('assets/images/citas.png', width: 22), label: 'Citas'), BottomNavigationBarItem(icon: Image.asset('assets/images/panel.png', width: 22), label: 'Panel'), BottomNavigationBarItem(icon: Image.asset('assets/images/matchy.png', width: 22), label: 'Matchy'), BottomNavigationBarItem(icon: Image.asset('assets/images/chat.png', width: 22), label: 'Chat')], onTap: (i) => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => [const PerfilScreen(), const CitasScreen(), const PanelScreen(), const MatchysScreen(), const ChatScreen()][i]))); }
}