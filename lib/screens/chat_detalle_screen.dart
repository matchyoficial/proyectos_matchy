// 📂 lib/screens/chat_detalle_screen.dart
// ✅ Chat detalle (mensajes) usando SOLO constantes desde chat_actions.dart
// ✅ Guarda mensajes en: chat_threads/{threadId}/messages
// ✅ Actualiza lastText/lastAt en el thread (para la lista)
// ✅ Diseño Matchy: fondo + logo + header + burbujas

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:proyectos_matchy/services/chat_actions.dart';

class ChatDetalleScreen extends StatefulWidget {
  final String id; // threadId
  final String nombre;
  final String edad;
  final String foto;

  const ChatDetalleScreen({
    super.key,
    required this.id,
    required this.nombre,
    required this.edad,
    required this.foto,
  });

  @override
  State<ChatDetalleScreen> createState() => _ChatDetalleScreenState();
}

class _ChatDetalleScreenState extends State<ChatDetalleScreen> {
  final TextEditingController _ctrl = TextEditingController();
  bool _sending = false;

  bool _isUrl(String v) => v.startsWith('http://') || v.startsWith('https://');
  bool _isAsset(String v) => v.startsWith('assets/');
  bool _looksLikeFilePath(String v) =>
      v.startsWith('/') || v.contains(r':\') || v.startsWith('file:');

  Widget _safeAvatar(String value) {
    final v = value.trim();
    const fallback = 'assets/images/perfil1.jpg';

    if (v.isEmpty) return Image.asset(fallback, fit: BoxFit.cover);

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

  Stream<QuerySnapshot<Map<String, dynamic>>> _messagesStream() {
    return FirebaseFirestore.instance
        .collection(kChatThreadsCollection)
        .doc(widget.id)
        .collection(kChatMessagesSubcollection)
        .orderBy(kMsgSentAt, descending: false)
        .snapshots();
  }

  Future<void> _send() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ No hay sesión iniciada')),
      );
      return;
    }

    final text = _ctrl.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);

    try {
      final threadRef =
      FirebaseFirestore.instance.collection(kChatThreadsCollection).doc(widget.id);

      final msgRef = threadRef.collection(kChatMessagesSubcollection).doc();

      await msgRef.set({
        kMsgText: text,
        kMsgSenderUid: user.uid,
        kMsgSentAt: FieldValue.serverTimestamp(),
      });

      // ✅ actualiza preview en lista
      await threadRef.set({
        kThreadLastText: text,
        kThreadLastAt: FieldValue.serverTimestamp(),
        kThreadUpdatedAt: FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _ctrl.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ No se pudo enviar: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover),
          ),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          width: 42,
                          height: 42,
                          child: _safeAvatar(widget.foto),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${widget.nombre}, ${widget.edad}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 26,
                        child: Image.asset('assets/images/logomatchyplano.png'),
                      ),
                    ],
                  ),
                ),

                // Mensajes
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _messagesStream(),
                    builder: (context, snap) {
                      if (snap.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: Text(
                              '❌ Error cargando mensajes: ${snap.error}',
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
                      if (docs.isEmpty) {
                        return const Center(
                          child: Text(
                            'Aún no hay mensajes 🙂',
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                        itemCount: docs.length,
                        itemBuilder: (context, i) {
                          final data = docs[i].data();
                          final text = (data[kMsgText] ?? '').toString();
                          final senderUid = (data[kMsgSenderUid] ?? '').toString();

                          final isMe = senderUid == myUid;

                          return Align(
                            alignment:
                            isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              constraints: const BoxConstraints(maxWidth: 290),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? const Color(0xFF7E79B6).withOpacity(0.85)
                                    : Colors.black.withOpacity(0.40),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.10),
                                ),
                              ),
                              child: Text(
                                text,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                // Input
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.10),
                            ),
                          ),
                          child: TextField(
                            controller: _ctrl,
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                            ),
                            cursorColor: Colors.white,
                            decoration: const InputDecoration(
                              hintText: 'Escribe un mensaje…',
                              hintStyle: TextStyle(color: Colors.white54),
                              border: InputBorder.none,
                              contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            onSubmitted: (_) => _send(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 46,
                        width: 46,
                        child: ElevatedButton(
                          onPressed: _sending ? null : _send,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFC107),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: _sending
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : const Icon(Icons.send, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
