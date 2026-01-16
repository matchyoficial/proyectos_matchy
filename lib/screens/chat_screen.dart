// 📂 lib/screens/chat_screen.dart
// ✅ LISTA DE CHATS (threads) — filtrado por participantUids (evita permission-denied)
// ✅ Usa SOLO constantes desde lib/services/chat_actions.dart
// ✅ Mantiene diseño Matchy (fondo, logo, título)
// ✅ Shell-safe: NO dibuja bottom nav interno (HomeShell lo pone)

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:proyectos_matchy/services/chat_actions.dart';
import 'package:proyectos_matchy/screens/chat_detalle_screen.dart';

class ChatThreadUI {
  final String id;
  final String nombre;
  final String edad;
  final String foto;
  final String lastText;
  final DateTime? lastAt;

  ChatThreadUI({
    required this.id,
    required this.nombre,
    required this.edad,
    required this.foto,
    required this.lastText,
    required this.lastAt,
  });
}

class ChatScreen extends StatefulWidget {
  final bool showBottomNav; // 🔴 CHINCHE SHELL CHAT 1 — en HomeShell debe ir false

  const ChatScreen({
    super.key,
    this.showBottomNav = true,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // 🔴 CHINCHE UI CHAT A — separación superior antes del logo
  static const double espacioBarraLogo = 35;

  // 🔴 CHINCHE UI CHAT B — altura logo
  static const double alturaLogo = 50;

  // 🔴 CHINCHE UI CHAT C — padding horizontal lista
  static const double padH = 18;

  // 🔴 CHINCHE UI CHAT D — alto de cada item
  static const double itemHeight = 78;

  bool _isUrl(String v) => v.startsWith('http://') || v.startsWith('https://');
  bool _isAsset(String v) => v.startsWith('assets/');
  bool _looksLikeFilePath(String v) =>
      v.startsWith('/') || v.contains(r':\') || v.startsWith('file:');

  Widget _safeAvatar(String value) {
    final v = value.trim();
    const fallback = 'assets/images/perfil1.jpg';

    if (v.isEmpty) {
      return Image.asset(fallback, fit: BoxFit.cover);
    }

    if (_isUrl(v)) {
      return Image.network(
        v,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset(fallback, fit: BoxFit.cover),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            color: Colors.black26,
            alignment: Alignment.center,
            child: const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
      );
    }

    if (_isAsset(v)) {
      return Image.asset(
        v,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset(fallback, fit: BoxFit.cover),
      );
    }

    if (_looksLikeFilePath(v)) {
      return Image.file(
        File(v.replaceFirst('file://', '')),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset(fallback, fit: BoxFit.cover),
      );
    }

    return Image.asset(fallback, fit: BoxFit.cover);
  }

  ChatThreadUI _mapThreadDocToUI({
    required String myUid,
    required QueryDocumentSnapshot<Map<String, dynamic>> d,
  }) {
    final data = d.data();

    // lastText/lastAt
    final lastText = (data[kThreadLastText] ?? '').toString();
    DateTime? lastAt;
    final rawAt = data[kThreadLastAt];
    if (rawAt is Timestamp) lastAt = rawAt.toDate();

    // Esquema nuevo: participantUids + meta
    String nombre = 'Matchy';
    String edad = '—';
    String foto = '';

    final puidsRaw = data[kThreadParticipantUids];
    final List<String> puids = (puidsRaw is List)
        ? puidsRaw.map((e) => e.toString()).toList()
        : <String>[];

    final otherUid = puids.firstWhere(
          (u) => u != myUid,
      orElse: () => '',
    );

    final metaRaw = data[kThreadMeta];
    if (otherUid.isNotEmpty && metaRaw is Map) {
      final otherMeta = metaRaw[otherUid];
      if (otherMeta is Map) {
        nombre = (otherMeta['nombre'] ?? nombre).toString().trim();
        edad = (otherMeta['edad'] ?? edad).toString().trim();
        foto = (otherMeta['foto'] ?? foto).toString().trim();
        if (edad.isEmpty) edad = '—';
      }
    }

    if (nombre.trim().isEmpty) nombre = 'Matchy';
    if (edad.trim().isEmpty) edad = '—';

    return ChatThreadUI(
      id: d.id,
      nombre: nombre,
      edad: edad,
      foto: foto,
      lastText: lastText,
      lastAt: lastAt,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: espacioBarraLogo),
              Center(
                child: SizedBox(
                  height: alturaLogo,
                  child: Image.asset('assets/images/logomatchyplano.png'),
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.only(left: padH),
                child: Text(
                  'CHATS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: (user == null)
                    ? const Center(
                  child: Text(
                    '⚠️ No hay sesión iniciada',
                    style: TextStyle(color: Colors.white),
                  ),
                )
                    : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  // ✅ SOLO threads donde yo soy participante
                  stream: FirebaseFirestore.instance
                      .collection(kChatThreadsCollection)
                      .where(kThreadParticipantUids, arrayContains: user.uid)
                      .snapshots(),
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: Text(
                            '❌ Error cargando chats: ${snap.error}',
                            style: const TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    }

                    final docs = snap.data?.docs ?? [];

                    final threads = docs
                        .map((d) => _mapThreadDocToUI(
                      myUid: user.uid,
                      d: d,
                    ))
                        .toList()
                      ..sort((a, b) {
                        final da = a.lastAt;
                        final db = b.lastAt;
                        if (da == null && db == null) return 0;
                        if (da == null) return 1;
                        if (db == null) return -1;
                        return db.compareTo(da);
                      });

                    if (threads.isEmpty) {
                      return const Center(
                        child: Text(
                          'Aún no tienes chats 🙂',
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(padH, 0, padH, 16),
                      itemCount: threads.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final t = threads[i];

                        return GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ChatDetalleScreen(
                                  id: t.id,
                                  nombre: t.nombre,
                                  edad: t.edad,
                                  foto: t.foto,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            height: itemHeight,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.35),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.10),
                              ),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: SizedBox(
                                    width: 56,
                                    height: 56,
                                    child: _safeAvatar(t.foto),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${t.nombre}, ${t.edad}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        t.lastText.isEmpty
                                            ? 'Sin mensajes aún'
                                            : t.lastText,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.75),
                                          fontSize: 13,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: Colors.white.withOpacity(0.6),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),

      // ✅ En HomeShell esto NO se usa; el shell pone la barra.
      bottomNavigationBar: widget.showBottomNav ? const SizedBox.shrink() : null,
    );
  }
}
