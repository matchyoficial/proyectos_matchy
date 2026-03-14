// 📂 lib/screens/chat_detalle_screen.dart
// ✅ CHAT DETALLE BLINDADO (VERSIÓN PRESENCIA REAL)
// 🔥 PRESENCIA: Estado "En línea" o "Últ. vez" dinámico desde Firestore.
// 🔥 CACHÉ: Foto de perfil blindada.
// 🔥 UX: Reacciones y Doble Chulo funcional.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:proyectos_matchy/screens/home_shell.dart';
import 'package:proyectos_matchy/widgets/foto_perfil_usuario.dart';
import 'package:intl/intl.dart'; // ✅ Necesario para formatear la hora

class ChatDetalleScreen extends StatefulWidget {
  final String id;
  final String otherUid;
  final String nombre;
  final String edad;
  final String foto;

  const ChatDetalleScreen({
    super.key,
    required this.id,
    required this.otherUid,
    required this.nombre,
    required this.edad,
    required this.foto,
  });

  @override
  State<ChatDetalleScreen> createState() => _ChatDetalleScreenState();
}

class _ChatDetalleScreenState extends State<ChatDetalleScreen> {
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _sending = false;

  static const double kAvatarSize = 55.0;
  static const List<Color> kHeaderGradient = [Color(0xFF7A43BF), Color(0xFF1A1A24)];
  static final Color kBubbleMe = const Color(0xFF7E79B6).withOpacity(0.9);
  static final Color kBubbleOther = const Color(0xFF333333).withOpacity(0.85);
  static const Color kSendButtonColor = Color(0xFFFFC107);

  @override
  void initState() {
    super.initState();
    _marcarComoLeidos();
  }

  // 🔥 FORMATEADOR DE ÚLTIMA VEZ
  String _formatLastSeen(dynamic lastSeen) {
    if (lastSeen == null) return "Desconectado";
    DateTime date;
    if (lastSeen is Timestamp) {
      date = lastSeen.toDate();
    } else {
      return "Desconectado";
    }

    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return "hace un momento";
    if (diff.inMinutes < 60) return "hace ${diff.inMinutes} min";
    if (diff.inDays == 0) return "hoy a las ${DateFormat('hh:mm a').format(date)}";
    return DateFormat('dd/MM/yy').format(date);
  }

  Future<void> _marcarComoLeidos() async {
    try {
      final messagesRef = FirebaseFirestore.instance
          .collection('chat_threads')
          .doc(widget.id)
          .collection('messages');

      final unreadSnap = await messagesRef
          .where('senderUid', isEqualTo: widget.otherUid)
          .where('status', isLessThan: 2)
          .get();

      if (unreadSnap.docs.isNotEmpty) {
        final batch = FirebaseFirestore.instance.batch();
        for (var doc in unreadSnap.docs) {
          batch.update(doc.reference, {'status': 2});
        }
        await batch.commit();
      }
    } catch (e) {
      debugPrint("Error marcando vistos: $e");
    }
  }

  Future<void> _reaccionar(String messageId, String emoji) async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;
    try {
      final docRef = FirebaseFirestore.instance
          .collection('chat_threads')
          .doc(widget.id)
          .collection('messages')
          .doc(messageId);
      await docRef.update({'reactions.$myUid': emoji});
    } catch (e) {
      debugPrint("Error al reaccionar: $e");
    }
  }

  Future<void> _send() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);
    try {
      final threadRef = FirebaseFirestore.instance.collection('chat_threads').doc(widget.id);
      final now = FieldValue.serverTimestamp();

      await threadRef.collection('messages').add({
        'text': text,
        'senderUid': user.uid,
        'sentAt': now,
        'status': 0,
        'reactions': {},
      });

      await threadRef.set({
        'lastText': text,
        'lastAt': now,
        'participantUids': FieldValue.arrayUnion([user.uid, widget.otherUid]),
      }, SetOptions(merge: true));

      _ctrl.clear();
      if (_scroll.hasClients) {
        _scroll.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    } catch (e) {
      debugPrint("Error enviando: $e");
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showReactionPicker(String messageId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['❤️', '😂', '🔥', '👍', '😮', '😢'].map((emoji) {
            return GestureDetector(
              onTap: () {
                _reaccionar(messageId, emoji);
                Navigator.pop(ctx);
              },
              child: Text(emoji, style: const TextStyle(fontSize: 30)),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        HomeShell.go(context, index: 4);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(child: Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover)),
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Image.asset('assets/images/logomatchyplano.png', height: 45),
                  const SizedBox(height: 15),

                  // HEADER CON PRESENCIA REAL
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: kHeaderGradient),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                            onPressed: () => HomeShell.go(context, index: 4),
                          ),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: SizedBox(
                              width: kAvatarSize, height: kAvatarSize,
                              child: CachedNetworkImage(
                                key: ValueKey(widget.otherUid + widget.foto),
                                imageUrl: widget.foto,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(color: Colors.white10),
                                errorWidget: (_, __, ___) => FotoPerfilUsuario(uid: widget.otherUid, fit: BoxFit.cover),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FittedBox(fit: BoxFit.scaleDown, child: Text(widget.nombre.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),

                                // 🔥 STREAM DE PRESENCIA
                                StreamBuilder<DocumentSnapshot>(
                                    stream: FirebaseFirestore.instance.collection('users').doc(widget.otherUid).snapshots(),
                                    builder: (context, snapshot) {
                                      if (!snapshot.hasData) return const SizedBox();
                                      final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                                      final bool isOnline = userData['isOnline'] ?? false;
                                      final lastSeen = userData['lastSeen'];

                                      return Text(
                                        isOnline ? 'En línea' : 'Últ. vez: ${_formatLastSeen(lastSeen)}',
                                        style: TextStyle(
                                            color: isOnline ? Colors.greenAccent : Colors.white54,
                                            fontSize: 12,
                                            fontWeight: isOnline ? FontWeight.bold : FontWeight.normal
                                        ),
                                      );
                                    }
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('chat_threads')
                          .doc(widget.id)
                          .collection('messages')
                          .orderBy('sentAt', descending: true)
                          .snapshots(),
                      builder: (context, snap) {
                        if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: Colors.white));
                        final docs = snap.data!.docs;

                        return ListView.builder(
                          controller: _scroll,
                          reverse: true,
                          padding: const EdgeInsets.all(16),
                          itemCount: docs.length,
                          itemBuilder: (ctx, i) {
                            final d = docs[i].data() as Map<String, dynamic>;
                            final isMe = d['senderUid'] == myUid;
                            final status = d['status'] ?? 0;
                            final reactions = d['reactions'] as Map<String, dynamic>? ?? {};

                            return Align(
                              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                              child: GestureDetector(
                                onLongPress: () => _showReactionPicker(docs[i].id),
                                child: Column(
                                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                  children: [
                                    Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Container(
                                          margin: const EdgeInsets.only(bottom: 12),
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                          constraints: const BoxConstraints(maxWidth: 260),
                                          decoration: BoxDecoration(
                                            color: isMe ? kBubbleMe : kBubbleOther,
                                            borderRadius: BorderRadius.circular(18),
                                          ),
                                          child: Text(d['text'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 15)),
                                        ),
                                        if (reactions.isNotEmpty)
                                          Positioned(
                                            bottom: 0,
                                            right: isMe ? 5 : null,
                                            left: isMe ? null : 5,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                  color: const Color(0xFF2A2A2A),
                                                  borderRadius: BorderRadius.circular(15),
                                                  border: Border.all(color: Colors.white10, width: 1),
                                                  boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 4)]
                                              ),
                                              child: Text(
                                                  reactions.values.toSet().join(' '),
                                                  style: const TextStyle(fontSize: 13)
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    if (isMe) Padding(
                                      padding: const EdgeInsets.only(right: 5, bottom: 8),
                                      child: Icon(
                                        status >= 2 ? Icons.done_all : Icons.done,
                                        size: 14, color: status >= 2 ? Colors.blueAccent : Colors.white38,
                                      ),
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

                  // INPUT
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 5, 16, 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(color: const Color(0xFF1A1A1A).withOpacity(0.8), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white24)),
                            child: TextField(
                              controller: _ctrl,
                              maxLines: null, minLines: 1,
                              keyboardType: TextInputType.multiline,
                              textCapitalization: TextCapitalization.sentences,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(hintText: "Escribe un mensaje...", hintStyle: TextStyle(color: Colors.white38), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        CircleAvatar(
                          backgroundColor: kSendButtonColor,
                          radius: 25,
                          child: IconButton(
                            icon: _sending
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                                : const Icon(Icons.send, color: Colors.black),
                            onPressed: _sending ? null : _send,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}