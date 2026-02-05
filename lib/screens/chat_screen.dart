// 📂 lib/screens/chat_screen.dart
// ✅ LISTA DE CHATS (CORREGIDO CRASH AL ENTRAR)
// 🔥 FIX: Error "path must be non-empty". Ahora se asegura un ID válido antes de navegar.
// 🔥 LOGIC: Si es match nuevo, busca/crea el ID del hilo al vuelo con 'upsertThread'.
// 🔥 UI: Diseño Pro intacto.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proyectos_matchy/services/chat_actions.dart';
import 'package:proyectos_matchy/screens/chat_detalle_screen.dart';
import 'package:proyectos_matchy/widgets/foto_perfil_usuario.dart';

// UI Model
class ChatThreadUI {
  final String id;
  final String otherUid;
  final String nombre;
  final String foto;
  final String lastText;
  final DateTime? lastAt;
  final bool isNew;

  ChatThreadUI({
    required this.id,
    required this.otherUid,
    required this.nombre,
    required this.foto,
    required this.lastText,
    required this.lastAt,
    this.isNew = false,
  });
}

class ChatScreen extends StatefulWidget {
  final bool showBottomNav;
  const ChatScreen({super.key, this.showBottomNav = true});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {

  // ===========================================================================
  // 🔴🔴 CHINCHES MAESTROS 🔴🔴
  // ===========================================================================
  static const double kTopSpacing   = 35.0;
  static const double kLogoHeight   = 45.0;
  static const double kPaddingH     = 20.0;
  static const double kCardHeight   = 85.0;
  static const double kAvatarSize   = 60.0;
  static const double kCardRadius   = 22.0;
  static const double kAvatarRadius = 16.0;

  static const List<Color> kCardGradient = [Color(0xFF7A43BF), Color(0xFF1A1A24)];
  static const BoxShadow kCardShadow = BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 4));
  // ===========================================================================

  Stream<QuerySnapshot> _matchesStream(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('my_matchys')
        .snapshots();
  }

  Stream<QuerySnapshot> _threadsStream(String uid) {
    return FirebaseFirestore.instance
        .collection('chat_threads')
        .where('participantUids', arrayContains: uid)
        .snapshots();
  }

  List<ChatThreadUI> _mergeData(List<QueryDocumentSnapshot> matches, List<QueryDocumentSnapshot> threads, String myUid) {
    final List<ChatThreadUI> result = [];
    final Map<String, QueryDocumentSnapshot> threadMap = {};

    for (var t in threads) {
      final data = t.data() as Map<String, dynamic>;
      final List parts = (data['participantUids'] is List) ? data['participantUids'] : [];
      final otherUid = parts.firstWhere((id) => id != myUid, orElse: () => '').toString();
      if (otherUid.isNotEmpty) threadMap[otherUid] = t;
    }

    for (var m in matches) {
      final mData = m.data() as Map<String, dynamic>;
      final otherUid = m.id;

      String nombre = (mData['nombre'] ?? 'Matchy').toString();
      String foto = (mData['fotoUrl'] ?? mData['foto'] ?? '').toString();
      DateTime? matchDate;

      if (mData['lastInteraction'] is Timestamp) {
        matchDate = (mData['lastInteraction'] as Timestamp).toDate();
      } else if (mData['timestamp'] is Timestamp) {
        matchDate = (mData['timestamp'] as Timestamp).toDate();
      } else {
        matchDate = DateTime.now();
      }

      if (threadMap.containsKey(otherUid)) {
        final tDoc = threadMap[otherUid]!;
        final tData = tDoc.data() as Map<String, dynamic>;
        DateTime? lastAt;
        if (tData['lastAt'] is Timestamp) lastAt = (tData['lastAt'] as Timestamp).toDate();

        final meta = tData['meta'];
        if (meta is Map && meta.containsKey(otherUid)) {
          nombre = meta[otherUid]['nombre'] ?? nombre;
          foto = meta[otherUid]['foto'] ?? foto;
        }

        result.add(ChatThreadUI(
          id: tDoc.id,
          otherUid: otherUid,
          nombre: nombre,
          foto: foto,
          lastText: (tData['lastText'] ?? '').toString(),
          lastAt: lastAt ?? matchDate,
          isNew: false,
        ));
      } else {
        result.add(ChatThreadUI(
          id: '', // Vacío: Indica que hay que buscarlo al hacer click
          otherUid: otherUid,
          nombre: nombre,
          foto: foto,
          lastText: "¡Nuevo Match! 💖",
          lastAt: matchDate,
          isNew: true,
        ));
      }
    }

    result.sort((a, b) {
      final dateA = a.lastAt ?? DateTime(0);
      final dateB = b.lastAt ?? DateTime(0);
      return dateB.compareTo(dateA);
    });

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover)),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: kTopSpacing),
              Center(child: SizedBox(height: kLogoHeight, child: Image.asset('assets/images/logomatchyplano.png'))),
              const SizedBox(height: 20),
              const Center(
                child: Text('CHATS', style: TextStyle(color: Colors.white, fontSize: 24, fontFamily: 'Poppins', fontWeight: FontWeight.w900, letterSpacing: 1.0, shadows: [Shadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4))])),
              ),
              const SizedBox(height: 15),

              Expanded(
                child: user == null
                    ? const Center(child: Text("Inicia sesión", style: TextStyle(color: Colors.white)))
                    : StreamBuilder<QuerySnapshot>(
                  stream: _matchesStream(user.uid),
                  builder: (ctx, matchSnap) {
                    if (matchSnap.hasError) return Center(child: Text("Error: ${matchSnap.error}", style: const TextStyle(color: Colors.white)));
                    if (!matchSnap.hasData) return const Center(child: CircularProgressIndicator(color: Colors.white));

                    return StreamBuilder<QuerySnapshot>(
                      stream: _threadsStream(user.uid),
                      builder: (ctx2, threadSnap) {
                        if (!threadSnap.hasData) return const SizedBox();

                        final matches = matchSnap.data!.docs;
                        final threads = threadSnap.data!.docs;
                        final uiList = _mergeData(matches, threads, user.uid);

                        if (uiList.isEmpty) {
                          return Container(
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.chat_bubble_outline, color: Colors.white.withOpacity(0.5), size: 48),
                                const SizedBox(height: 10),
                                const Text("Aún no tienes chats activos", style: TextStyle(color: Colors.white54, fontFamily: 'Poppins')),
                              ],
                            ),
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.fromLTRB(kPaddingH, 0, kPaddingH, 100),
                          itemCount: uiList.length,
                          separatorBuilder: (_,__) => const SizedBox(height: 14),
                          itemBuilder: (ctx, i) {
                            final t = uiList[i];
                            return GestureDetector(
                              // 🔥 CORRECCIÓN DEL CRASH AQUÍ
                              onTap: () async {
                                String threadId = t.id;

                                // Si no tenemos ID (es nuevo), lo obtenemos primero
                                if (threadId.isEmpty) {
                                  try {
                                    // UpsertThread busca si existe o crea uno nuevo y devuelve el ID
                                    threadId = await ChatActions.upsertThread(
                                        peerUid: t.otherUid,
                                        peerNombre: t.nombre,
                                        peerEdad: 0,
                                        peerFoto: t.foto,
                                        myNombre: 'Yo', // Se actualiza en backend
                                        myEdad: 0,
                                        myFoto: ''
                                    );
                                  } catch (e) {
                                    debugPrint("Error obteniendo thread: $e");
                                    return; // Evita navegar si falló
                                  }
                                }

                                if (context.mounted) {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => ChatDetalleScreen(
                                    id: threadId, // ¡Ahora siempre enviamos un ID válido!
                                    otherUid: t.otherUid,
                                    nombre: t.nombre,
                                    edad: '',
                                    foto: t.foto,
                                  )));
                                }
                              },
                              child: Container(
                                height: kCardHeight,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(kCardRadius),
                                  gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: kCardGradient),
                                  boxShadow: const [kCardShadow],
                                  border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
                                ),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                        borderRadius: BorderRadius.circular(kAvatarRadius),
                                        child: SizedBox(
                                            width: kAvatarSize, height: kAvatarSize,
                                            child: FotoPerfilUsuario(uid: t.otherUid, fit: BoxFit.cover, alignment: Alignment.topCenter)
                                        )
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(t.nombre, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17, fontFamily: 'Poppins')),
                                          const SizedBox(height: 4),
                                          Text(
                                              t.lastText,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  color: t.isNew ? Colors.white : Colors.white.withOpacity(0.7),
                                                  fontWeight: t.isNew ? FontWeight.w600 : FontWeight.normal,
                                                  fontSize: 13,
                                                  fontFamily: 'Poppins'
                                              )
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.4), size: 28)
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              )
            ],
          ),
          Positioned(bottom: 0, left: 0, right: 0, height: 90, child: IgnorePointer(child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.95)], stops: const [0.0, 1.0]))))),
        ],
      ),
      bottomNavigationBar: widget.showBottomNav ? const SizedBox.shrink() : null,
    );
  }
}