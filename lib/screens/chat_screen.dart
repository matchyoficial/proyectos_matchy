// 📂 lib/screens/chat_screen.dart
// ✅ LISTA DE CHATS DEFINITIVA (MODO FANTASMA "ESPEJO" + FIX ASPECT RATIO)
// 🔥 MODO FANTASMA PRO: Actualización silenciosa (cleared_by) para no dejar mensajes huérfanos.
// 🔥 FILTRO ZOMBIE: Si tú borraste el chat, no reaparece disfrazado de "Nuevo Match".
// 🔥 FIX FOTOS: memCacheWidth eliminado. Proporción original restaurada sin deformar.
// 🔥 UI MODO FANTASMA: La tarjeta se tiñe de rojo oscuro al presionar. Diálogo Matchy Style.
// 🔥 CACHÉ: CachedNetworkImage con ValueKey inyectado para carga instantánea.
// 🛠️ FIX OVERFLOW: Texto de último mensaje con puntos suspensivos (...) tipo WhatsApp.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart'; // ✅ Motor de caché
import 'package:proyectos_matchy/services/chat_actions.dart';
import 'package:proyectos_matchy/screens/chat_detalle_screen.dart';
import 'package:proyectos_matchy/widgets/foto_perfil_usuario.dart';
import 'package:proyectos_matchy/state/profile_form_provider.dart';

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

class ChatScreen extends ConsumerStatefulWidget {
  final bool showBottomNav;
  const ChatScreen({super.key, this.showBottomNav = true});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {

  static const double kTopSpacing   = 35.0;
  static const double kLogoHeight   = 45.0;
  static const double kPaddingH     = 20.0;
  static const double kCardHeight   = 85.0;
  static const double kAvatarSize   = 60.0;
  static const double kCardRadius   = 22.0;
  static const double kAvatarRadius = 16.0;

  static const List<Color> kCardGradient = [Color(0xFF7A43BF), Color(0xFF1A1A24)];
  static const BoxShadow kCardShadow = BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 4));

  // Variable de estado para el Modo Fantasma (Resalta de rojo la tarjeta al mantener presionada)
  String? _highlightedThreadId;

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

    // 🔥 ESPEJO ESPEJISMO: Lista para guardar a los que tú decidiste ocultar
    final Set<String> hiddenOtherUids = {};

    for (var t in threads) {
      final data = t.data() as Map<String, dynamic>;
      final List parts = (data['participantUids'] is List) ? data['participantUids'] : [];
      final otherUid = parts.firstWhere((id) => id != myUid, orElse: () => '').toString();

      if (otherUid.isEmpty) continue;

      // 🔥 LECTURA DEL MODO FANTASMA: ¿Yo lo borré?
      final List clearedBy = (data['cleared_by'] is List) ? data['cleared_by'] : [];
      if (clearedBy.contains(myUid)) {
        // Lo anoto en la lista negra para no mostrarlo como "Nuevo Match" tampoco
        hiddenOtherUids.add(otherUid);
        continue; // Salto este chat, no lo agrego al mapa de hilos activos
      }

      threadMap[otherUid] = t;
    }

    for (var m in matches) {
      final otherUid = m.id;

      // 🔥 FILTRO ZOMBIE: Si este match está en mi lista de ocultos, lo ignoro por completo.
      if (hiddenOtherUids.contains(otherUid)) {
        continue;
      }

      final mData = m.data() as Map<String, dynamic>;
      String nombreMatch = (mData['nombre'] ?? 'Matchy').toString();
      String foto = (mData['fotoUrl'] ?? mData['foto'] ?? '').toString();
      DateTime? matchDate;

      if (mData['lastInteraction'] is Timestamp) {
        matchDate = (mData['lastInteraction'] as Timestamp).toDate();
      } else if (mData['timestamp'] is Timestamp) {
        matchDate = (mData['timestamp'] as Timestamp).toDate();
      } else {
        matchDate = DateTime.now();
      }

      String nombreFinal = nombreMatch;

      if (threadMap.containsKey(otherUid)) {
        final tDoc = threadMap[otherUid]!;
        final tData = tDoc.data() as Map<String, dynamic>;
        DateTime? lastAt;
        if (tData['lastAt'] is Timestamp) lastAt = (tData['lastAt'] as Timestamp).toDate();

        final meta = tData['meta'];
        if (meta is Map && meta.containsKey(otherUid)) {
          final String metaNombre = (meta[otherUid]['nombre'] ?? '').toString();
          nombreFinal = (metaNombre.isEmpty || metaNombre == 'Yo') ? nombreMatch : metaNombre;
          foto = meta[otherUid]['foto'] ?? foto;
        }

        result.add(ChatThreadUI(
          id: tDoc.id,
          otherUid: otherUid,
          nombre: nombreFinal,
          foto: foto,
          lastText: (tData['lastText'] ?? '').toString(),
          lastAt: lastAt ?? matchDate,
          isNew: false,
        ));
      } else {
        result.add(ChatThreadUI(
          id: '',
          otherUid: otherUid,
          nombre: nombreFinal,
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

  // 🔥 FUNCIÓN: MODO FANTASMA (ESPEJO ESPEJISMO)
  void _confirmDeleteChat(String threadId, String nombre, String myUid) {
    if (threadId.isEmpty) return;

    setState(() => _highlightedThreadId = threadId);

    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFFFF5252), width: 1.5)),
            title: const Text("ELIMINAR CHAT", style: TextStyle(color: Color(0xFFFF5252), fontWeight: FontWeight.w900, fontFamily: 'Poppins')),
            content: Text("¿Deseas eliminar tu conversación con $nombre?\n\nSe borrarán los mensajes de tu historial, pero la conexión no se romperá. Si te vuelve a escribir, el chat aparecerá de nuevo.", style: const TextStyle(color: Colors.white70, fontSize: 14)),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    if (mounted) setState(() => _highlightedThreadId = null);
                  },
                  child: const Text("CANCELAR", style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold))
              ),
              TextButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    try {
                      // 🔥 ACTUALIZACIÓN SILENCIOSA: Añadimos mi UID a la lista negra del chat
                      await FirebaseFirestore.instance.collection('chat_threads').doc(threadId).update({
                        'cleared_by': FieldValue.arrayUnion([myUid])
                      });
                    } catch (e) {
                      debugPrint("Error ocultando chat: $e");
                    } finally {
                      if (mounted) setState(() => _highlightedThreadId = null);
                    }
                  },
                  child: const Text("ELIMINAR", style: TextStyle(color: Color(0xFFFF5252), fontWeight: FontWeight.bold))
              )
            ]
        )
    ).then((_) {
      if (mounted) setState(() => _highlightedThreadId = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final profile = ref.watch(profileFormProvider);
    final String miNombreReal = profile.nombre.isNotEmpty ? profile.nombre : 'Yo';

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

              Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: const Text(
                      'CHATS',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          shadows: [Shadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4))]
                      )
                  ),
                ),
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
                            final bool isHighlighted = _highlightedThreadId == t.id;

                            return GestureDetector(
                              // 🔥 ACTIVADOR DE MODO FANTASMA
                              onLongPress: () {
                                if (t.id.isNotEmpty) {
                                  _confirmDeleteChat(t.id, t.nombre, user.uid);
                                }
                              },
                              onTap: () async {
                                String threadId = t.id;
                                if (threadId.isEmpty) {
                                  try {
                                    threadId = await ChatActions.upsertThread(
                                        peerUid: t.otherUid,
                                        peerNombre: t.nombre,
                                        peerEdad: 0,
                                        peerFoto: t.foto,
                                        myNombre: miNombreReal,
                                        myEdad: 0,
                                        myFoto: profile.profilePhotoUrl ?? ''
                                    );
                                  } catch (e) {
                                    debugPrint("Error obteniendo thread: $e");
                                    return;
                                  }
                                }

                                if (context.mounted) {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => ChatDetalleScreen(
                                    id: threadId,
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
                                  // 🔥 CAMBIO DE COLOR DINÁMICO AL DEJAR PRESIONADO (ALERTA ROJA)
                                  gradient: isHighlighted
                                      ? const LinearGradient(colors: [Color(0xFF8B0000), Color(0xFF4A0000)]) // Sangre oscuro
                                      : const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: kCardGradient),
                                  boxShadow: const [kCardShadow],
                                  border: Border.all(color: isHighlighted ? const Color(0xFFFF5252) : Colors.white.withOpacity(0.08), width: 1),
                                ),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                        borderRadius: BorderRadius.circular(kAvatarRadius),
                                        child: SizedBox(
                                            width: kAvatarSize, height: kAvatarSize,
                                            // 🔥 BLINDAJE FIX ASPECT RATIO (memCacheWidth ELIMINADO, SOLO HEIGHT)
                                            child: CachedNetworkImage(
                                              key: ValueKey(t.otherUid + t.foto),
                                              imageUrl: t.foto,
                                              fit: BoxFit.cover, // Mantiene la proporción llenando el espacio cuadrado
                                              alignment: Alignment.topCenter, // Prioriza el rostro
                                              memCacheHeight: (kAvatarSize * 3).toInt(), // Liberador de RAM seguro (180px)
                                              placeholder: (context, url) => Container(color: Colors.white.withOpacity(0.05)),
                                              errorWidget: (context, url, error) => FotoPerfilUsuario(
                                                  uid: t.otherUid,
                                                  fit: BoxFit.cover,
                                                  alignment: Alignment.topCenter
                                              ),
                                            )
                                        )
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                                t.nombre,
                                                maxLines: 1,
                                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17, fontFamily: 'Poppins')
                                            ),
                                          ),
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