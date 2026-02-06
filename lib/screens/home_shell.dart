// 📂 lib/screens/home_shell.dart
// ✅ Shell principal (CORREGIDO PARA MATCHY)
// 🔥 FIX: Al detectar un evento entrante, pasamos 'soyElOwner: false' a MatchScreen.
// 🔥 ESTO EVITA QUE EL RECEPTOR CREE UN NUEVO EVENTO Y GENERE EL BUCLE.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:proyectos_matchy/screens/perfil_screen.dart';
import 'package:proyectos_matchy/screens/citas_screen.dart';
import 'package:proyectos_matchy/screens/panel_screen.dart';
import 'package:proyectos_matchy/screens/matchys_screen.dart';
import 'package:proyectos_matchy/screens/chat_screen.dart';
import 'package:proyectos_matchy/screens/match_screen.dart';

class HomeShell extends StatefulWidget {
  final int initialIndex;

  const HomeShell({
    super.key,
    this.initialIndex = 2,
  });

  // ================================================================
  // 🔹 EVENTO GLOBAL ACTIVO (MATCHY)
  // ================================================================
  static final ValueNotifier<Widget?> activeEventOverlay =
  ValueNotifier<Widget?>(null);

  static DocumentReference<Map<String, dynamic>>? _activeEventRef;

  static void showMatchy(
      MatchScreen screen,
      DocumentReference<Map<String, dynamic>> eventRef,
      ) {
    _activeEventRef = eventRef;
    activeEventOverlay.value = screen;
  }

  /// 🔥 Consumir evento (SOLO llamado desde MatchScreen)
  static Future<void> consumeEvent() async {
    try {
      final ref = _activeEventRef;
      if (ref != null) {
        await ref.update({
          'seen': true,
          'seenAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {
      // Silencioso: no bloquea UX
    } finally {
      _activeEventRef = null;
      activeEventOverlay.value = null;
    }
  }

  static void go(BuildContext context, {int index = 2}) {
    final safeIndex = index.clamp(0, 4);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => HomeShell(initialIndex: safeIndex),
      ),
          (route) => false,
    );
  }

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _index;
  late final List<Widget> _screens;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _eventSub;

  bool _overlayActivo = false;
  String? _listeningUid;

  static const String kUsersCollection = 'users';
  static const String kEventsSubcollection = 'events';

  @override
  void initState() {
    super.initState();

    _index = widget.initialIndex.clamp(0, 4);

    _screens = const [
      PerfilScreen(showBottomNav: false),
      CitasScreen(showBottomNav: false),
      PanelScreen(showBottomNav: false),
      MatchysScreen(showBottomNav: false),
      ChatScreen(showBottomNav: false),
    ];

    // 🔥 Cuando el overlay se limpia, liberamos el lock interno
    HomeShell.activeEventOverlay.addListener(() {
      if (HomeShell.activeEventOverlay.value == null) {
        _overlayActivo = false;
      }
    });

    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted || user == null) return;
      if (_listeningUid == user.uid) return;

      _listeningUid = user.uid;
      _eventSub?.cancel();
      _attachEvents(user.uid);
    });
  }

  void _attachEvents(String myUid) {
    final col = FirebaseFirestore.instance
        .collection(kUsersCollection)
        .doc(myUid)
        .collection(kEventsSubcollection);

    _eventSub = col
        .where('type', isEqualTo: 'matchy')
        .where('seen', isEqualTo: false)
        .limit(1)
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      if (_overlayActivo) return;
      if (snap.docs.isEmpty) return;

      final doc = snap.docs.first;
      final data = doc.data();

      final peerUid = data['ownerUid'] == myUid
          ? (data['candidatoUid'] ?? '').toString()
          : (data['ownerUid'] ?? '').toString();

      if (peerUid.isEmpty) return;

      _overlayActivo = true;

      // 🟢 Lectura robusta de datos del evento
      final String nombreLugar = (data['lugarNombre'] ?? '').toString();
      final String fotoLugar = (data['lugarFoto'] ?? '').toString();
      final String citaId = (data['citaId'] ?? '').toString();

      HomeShell.showMatchy(
        MatchScreen(
          candidatoId: peerUid,
          candidatoNombre: (data['ownerNombre'] ?? 'Matchy').toString(),
          candidatoEdad:
          int.tryParse((data['ownerEdad'] ?? '0').toString()) ?? 0,
          candidatoFotoAsset:
          (data['ownerFoto'] ?? 'assets/images/perfil1.jpg').toString(),

          // 🔥 PASAMOS LOS DATOS DEL LUGAR AL MATCHSCREEN
          lugarNombre: nombreLugar,
          lugarFoto: fotoLugar,
          citaId: citaId,

          // 🔥 CALLBACK PARA QUE EL MATCHY CIERRE EL EVENTO VISUALMENTE
          onMatchAnimationFinished: HomeShell.consumeEvent,

          // 🛑🛑🛑 AQUÍ ESTÁ LA SOLUCIÓN DEL BUCLE 🛑🛑🛑
          // Como estoy recibiendo un evento, NO SOY EL OWNER.
          soyElOwner: false,
        ),
        doc.reference,
      );
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _eventSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _index == 2,
      onPopInvoked: (didPop) {
        if (didPop) return;
        setState(() => _index = 2);
      },
      child: ValueListenableBuilder<Widget?>(
        valueListenable: HomeShell.activeEventOverlay,
        builder: (_, overlay, __) {
          return Scaffold(
            body: Stack(
              children: [
                IndexedStack(
                  index: _index,
                  children: _screens,
                ),
                if (overlay != null) Positioned.fill(child: overlay),
              ],
            ),
            bottomNavigationBar: overlay == null
                ? _MatchyBottomNav(
              currentIndex: _index,
              onTap: (i) {
                if (i == _index) return;
                setState(() => _index = i);
              },
            )
                : null,
          );
        },
      ),
    );
  }
}

class _MatchyBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _MatchyBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: Colors.black,
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      selectedItemColor: const Color(0xFFE0D4FF),
      unselectedItemColor: Colors.white54,
      selectedFontSize: 10,
      unselectedFontSize: 10,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'PERFIL'),
        BottomNavigationBarItem(icon: Icon(Icons.event), label: 'CITAS'),
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'PANEL'),
        BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'MATCHY'),
        BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'CHAT'),
      ],
      onTap: onTap,
    );
  }
}