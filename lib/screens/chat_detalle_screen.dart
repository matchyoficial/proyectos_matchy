// 📂 lib/screens/chat_detalle_screen.dart
// ✅ CHAT DETALLE BLINDADO (REACCIONES EXTENDIDAS + LISTA COMPLETA FIX)
// 🔥 FIX CRÍTICO: Vacuna Anti-Nulos inyectada en el 'status' de los mensajes (Adiós pantalla roja).
// 🔥 FIX LISTA LARGAAA: Nuevos emojis inyectados, incluyendo 😈 y 👿.
// 🔥 UI FIX: Scrollbar y física de rebote en la lista de emojis para que no se pierdan.
// 🔥 MODO FANTASMA: Rompe-hechizos funcional al enviar mensaje.
// 🔥 CACHÉ: Fotos perfectas sin deformación.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:proyectos_matchy/screens/home_shell.dart';
import 'package:proyectos_matchy/widgets/foto_perfil_usuario.dart';
import 'package:intl/intl.dart';

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

  // 🔥 LISTA MAESTRA (DIABLITOS AÑADIDOS JUNTO AL FANTASMA)
  final List<String> kAllEmojis = [
    '🍑', '🍆', '🍌', '💋', '💔', '😘', '🥰', '😍', '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍', '🤎',
    '😂', '🔥', '👍', '😮', '😢', '💯', '😎', '🤩', '👏', '🙌', '🎉', '🥳', '🤔', '🤫', '🤭', '🥱', '🥺',
    '😭', '🤬', '🙄', '💀', '👽', '👾', '🤖', '🎃', '👻', '😈', '👿', '🙏', '🤝', '💪', '👀', '👅', '✨'
  ];

  List<String> _recentEmojis = ['❤️', '😂', '🔥', '👍', '😮', '😢'];

  @override
  void initState() {
    super.initState();
    _marcarComoLeidos();
    _loadRecentEmojis();
  }

  Future<void> _loadRecentEmojis() async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(myUid).get();
      if (doc.exists && doc.data()!.containsKey('recent_emojis')) {
        final List<dynamic> saved = doc.data()!['recent_emojis'];
        if (saved.isNotEmpty && mounted) {
          setState(() { _recentEmojis = saved.map((e) => e.toString()).toList(); });
        }
      }
    } catch (_) {}
  }

  String _formatLastSeen(dynamic lastSeen) {
    if (lastSeen is Timestamp) {
      final date = lastSeen.toDate();
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inMinutes < 1) return "hace un momento";
      if (diff.inMinutes < 60) return "hace ${diff.inMinutes} min";
      return "hoy a las ${DateFormat('hh:mm a').format(date)}";
    }
    return "Desconectado";
  }

  Future<void> _marcarComoLeidos() async {
    try {
      final messagesRef = FirebaseFirestore.instance.collection('chat_threads').doc(widget.id).collection('messages');
      final unreadSnap = await messagesRef.where('senderUid', isEqualTo: widget.otherUid).where('status', isLessThan: 2).get();
      if (unreadSnap.docs.isNotEmpty) {
        final batch = FirebaseFirestore.instance.batch();
        for (var doc in unreadSnap.docs) { batch.update(doc.reference, {'status': 2}); }
        await batch.commit();
      }
    } catch (_) {}
  }

  Future<void> _reaccionar(String messageId, String emoji) async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;
    try {
      await FirebaseFirestore.instance.collection('chat_threads').doc(widget.id).collection('messages').doc(messageId).update({'reactions.$myUid': emoji});
    } catch (_) {}
  }

  void _onEmojiSelected(String messageId, String emoji, BuildContext ctx) {
    _reaccionar(messageId, emoji);
    Navigator.pop(ctx);
    setState(() {
      _recentEmojis.remove(emoji);
      _recentEmojis.insert(0, emoji);
      if (_recentEmojis.length > 6) _recentEmojis = _recentEmojis.sublist(0, 6);
    });
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid != null) {
      FirebaseFirestore.instance.collection('users').doc(myUid).update({'recent_emojis': _recentEmojis});
    }
  }

  void _showReactionPicker(String messageId) {
    bool showAll = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
              content: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: showAll
                    ? SizedBox(
                  key: const ValueKey('all'),
                  width: double.maxFinite, height: 350,
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: GridView.builder(
                      padding: const EdgeInsets.only(right: 10),
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6, mainAxisSpacing: 20, crossAxisSpacing: 10
                      ),
                      itemCount: kAllEmojis.length,
                      itemBuilder: (c, i) => GestureDetector(
                        onTap: () => _onEmojiSelected(messageId, kAllEmojis[i], ctx),
                        child: Center(child: Text(kAllEmojis[i], style: const TextStyle(fontSize: 28))),
                      ),
                    ),
                  ),
                )
                    : Row(
                  key: const ValueKey('recent'),
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ..._recentEmojis.take(6).map((emoji) => GestureDetector(
                      onTap: () => _onEmojiSelected(messageId, emoji, ctx),
                      child: Text(emoji, style: const TextStyle(fontSize: 30)),
                    )),
                    GestureDetector(
                      onTap: () => setStateDialog(() => showAll = true),
                      child: Container(
                        width: 35, height: 35,
                        decoration: const BoxDecoration(color: Colors.white10, shape: BoxShape.circle),
                        child: const Icon(Icons.add, color: Colors.white, size: 22),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
      ),
    );
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
      await threadRef.collection('messages').add({'text': text, 'senderUid': user.uid, 'sentAt': now, 'status': 0, 'reactions': {}});
      await threadRef.set({
        'lastText': text, 'lastAt': now,
        'participantUids': FieldValue.arrayUnion([user.uid, widget.otherUid]),
        'cleared_by': FieldValue.delete(),
      }, SetOptions(merge: true));
      _ctrl.clear();
      if (_scroll.hasClients) _scroll.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } catch (_) {} finally { if (mounted) setState(() => _sending = false); }
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) { if (didPop) return; HomeShell.go(context, index: 4); },
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
                  // HEADER
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(gradient: const LinearGradient(colors: kHeaderGradient), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white10)),
                      child: Row(
                        children: [
                          IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20), onPressed: () => HomeShell.go(context, index: 4)),
                          ClipRRect(borderRadius: BorderRadius.circular(15), child: SizedBox(width: kAvatarSize, height: kAvatarSize, child: CachedNetworkImage(key: ValueKey(widget.otherUid + widget.foto), imageUrl: widget.foto, fit: BoxFit.cover, alignment: Alignment.topCenter, memCacheHeight: (kAvatarSize * 3).toInt(), placeholder: (_, __) => Container(color: Colors.white10), errorWidget: (_, __, ___) => FotoPerfilUsuario(uid: widget.otherUid, fit: BoxFit.cover, alignment: Alignment.topCenter)))),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FittedBox(fit: BoxFit.scaleDown, child: Text(widget.nombre.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
                                StreamBuilder<DocumentSnapshot>(
                                    stream: FirebaseFirestore.instance.collection('users').doc(widget.otherUid).snapshots(),
                                    builder: (context, snapshot) {
                                      if (!snapshot.hasData) return const SizedBox();
                                      final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                                      return Text(userData['isOnline'] == true ? 'En línea' : 'Últ. vez: ${_formatLastSeen(userData['lastSeen'])}', style: TextStyle(color: userData['isOnline'] == true ? Colors.greenAccent : Colors.white54, fontSize: 12, fontWeight: userData['isOnline'] == true ? FontWeight.bold : FontWeight.normal));
                                    }
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // MENSAJES
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('chat_threads').doc(widget.id).collection('messages').orderBy('sentAt', descending: true).snapshots(),
                      builder: (context, snap) {
                        if (snap.hasError) return Center(child: Text("Cargando...", style: const TextStyle(color: Colors.white54)));
                        if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: Colors.white));
                        final docs = snap.data!.docs;
                        return ListView.builder(
                          controller: _scroll, reverse: true, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          itemCount: docs.length,
                          itemBuilder: (ctx, i) {
                            final d = docs[i].data() as Map<String, dynamic>;
                            final isMe = d['senderUid'] == myUid;
                            final reactions = d['reactions'] as Map<String, dynamic>? ?? {};
                            return Align(
                              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 22),
                                child: Column(
                                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                  children: [
                                    GestureDetector(
                                      onLongPress: () => _showReactionPicker(docs[i].id),
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), constraints: const BoxConstraints(maxWidth: 260), decoration: BoxDecoration(color: isMe ? kBubbleMe : kBubbleOther, borderRadius: BorderRadius.circular(18)), child: Text(d['text'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 15))),
                                          Positioned(
                                            bottom: -11, right: isMe ? -2 : null, left: isMe ? null : -2,
                                            child: GestureDetector(
                                              onTap: () => _showReactionPicker(docs[i].id),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                                decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white24, width: 1), boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2))]),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    if (reactions.isNotEmpty) Text(reactions.values.toSet().join(''), style: const TextStyle(fontSize: 11)),
                                                    if (reactions.isNotEmpty) const SizedBox(width: 3),
                                                    Icon(Icons.add_reaction_outlined, size: 12, color: reactions.isNotEmpty ? const Color(0xFFE0D4FF) : Colors.white54),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // 🔥 LA VACUNA ESTÁ AQUÍ ( ?? 0)
                                    if (isMe) Padding(padding: const EdgeInsets.only(right: 5, top: 15), child: Icon((d['status'] ?? 0) >= 2 ? Icons.done_all : Icons.done, size: 14, color: (d['status'] ?? 0) >= 2 ? Colors.blueAccent : Colors.white38)),
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
                        Expanded(child: Container(decoration: BoxDecoration(color: const Color(0xFF1A1A1A).withOpacity(0.8), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white24)), child: TextField(controller: _ctrl, maxLines: null, minLines: 1, keyboardType: TextInputType.multiline, textCapitalization: TextCapitalization.sentences, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: "Escribe un mensaje...", hintStyle: TextStyle(color: Colors.white38), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12))))),
                        const SizedBox(width: 10),
                        CircleAvatar(backgroundColor: kSendButtonColor, radius: 25, child: IconButton(icon: _sending ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) : const Icon(Icons.send, color: Colors.black), onPressed: _sending ? null : _send)),
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