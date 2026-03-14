// 📂 lib/screens/chat_detalle_screen.dart
// ✅ CHAT DETALLE BLINDADO (FOTO INTELIGENTE + NAVEGACIÓN FORZADA A CHAT)
// 🔥 BLINDAJE: Nombre en cabecera estandarizado a 16pt y protegido con FittedBox.
// 🔥 LOGIC: El botón atrás y el gesto system SIEMPRE llevan a ChatScreen (Index 4).
// 🚀 FIX UI: Input de texto estilo WhatsApp (Expansión multilínea y visibilidad total).

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proyectos_matchy/screens/home_shell.dart';
import 'package:proyectos_matchy/widgets/foto_perfil_usuario.dart';

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

  // ===========================================================================
  // 🛡️ ZONA DE CHINCHES MAESTROS (DISEÑO CHAT PRO BLINDADO)
  // ===========================================================================

  // Header (Manteniendo tus colores sagrados)
  static const double kHeaderHeight = 85.0;
  static const double kHeaderPaddingH = 16.0;
  static const double kAvatarSize = 59.0;
  static const double kHeaderRadius = 24.0;
  static const List<Color> kHeaderGradient = [Color(0xFF7A43BF), Color(0xFF1A1A24)];
  static const double kTitleSize = 16.0;

  // Burbujas
  static final Color kBubbleMe = const Color(0xFF7E79B6).withOpacity(0.9);
  static final Color kBubbleOther = const Color(0xFF333333).withOpacity(0.85);
  static const double kBubbleRadius = 18.0;

  // Input Area
  static const Color kInputBg = Color(0xFF1A1A1A);
  static const Color kSendButtonColor = Color(0xFFFFC107);
  static const double kInputBottomMargin = 20.0;

  // ===========================================================================

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

  void _irAChatSiempre() {
    HomeShell.go(context, index: 4);
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _irAChatSiempre();
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

                  // HEADER CÁPSULA BLINDADA
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: kHeaderPaddingH),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: kHeaderGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight
                        ),
                        borderRadius: BorderRadius.circular(kHeaderRadius),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 5))
                        ],
                        border: Border.all(color: Colors.white10, width: 1),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: _irAChatSiempre,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(color: Colors.white10, shape: BoxShape.circle),
                              child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                            ),
                          ),

                          const SizedBox(width: 12),

                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: SizedBox(
                              width: kAvatarSize,
                              height: kAvatarSize,
                              child: FotoPerfilUsuario(
                                uid: widget.otherUid,
                                fit: BoxFit.cover,
                                alignment: Alignment.topCenter,
                              ),
                            ),
                          ),

                          const SizedBox(width: 15),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    widget.nombre.toUpperCase(),
                                    maxLines: 1,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: kTitleSize,
                                        fontWeight: FontWeight.w900,
                                        fontFamily: 'Poppins',
                                        letterSpacing: 0.5
                                    ),
                                  ),
                                ),
                                if (widget.edad.isNotEmpty && widget.edad != '—')
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      '${widget.edad} años',
                                      style: const TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'Poppins'),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

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
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          itemCount: docs.length,
                          itemBuilder: (ctx, i) {
                            final data = docs[i].data() as Map<String, dynamic>;
                            final isMe = data['senderUid'] == myUid;

                            return Align(
                              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                constraints: const BoxConstraints(maxWidth: 280),
                                decoration: BoxDecoration(
                                    color: isMe ? kBubbleMe : kBubbleOther,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(kBubbleRadius),
                                      topRight: const Radius.circular(kBubbleRadius),
                                      bottomLeft: isMe ? const Radius.circular(kBubbleRadius) : Radius.zero,
                                      bottomRight: isMe ? Radius.zero : const Radius.circular(kBubbleRadius),
                                    ),
                                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))
                                    ]
                                ),
                                child: Text(
                                    data['text'] ?? '',
                                    style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4, fontFamily: 'Poppins')
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // 🔥 ZONA DE INPUT RECONSTRUIDA (ESTILO WHATSAPP MULTILÍNEA)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 5, 16, kInputBottomMargin),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end, // Para que el botón de enviar se quede abajo al expandir
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                                color: kInputBg.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.white24),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
                                ]
                            ),
                            child: TextField(
                              controller: _ctrl,
                              maxLines: null, // 🔥 Permite expansión infinita vertical
                              minLines: 1,    // 🔥 Empieza con una sola línea
                              keyboardType: TextInputType.multiline, // 🔥 Cambia el botón de acción por un 'Enter'
                              textCapitalization: TextCapitalization.sentences, // 🔥 Estética premium
                              style: const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
                              cursorColor: kSendButtonColor,
                              decoration: const InputDecoration(
                                  hintText: "Escribe un mensaje...",
                                  hintStyle: TextStyle(color: Colors.white38),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12) // Ajustado para multilínea
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        Container(
                          height: 50, width: 50,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: kSendButtonColor,
                              boxShadow: [
                                BoxShadow(color: kSendButtonColor.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))
                              ]
                          ),
                          child: IconButton(
                            onPressed: _sending ? null : _send,
                            icon: _sending
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                                : const Icon(Icons.send_rounded, color: Colors.black, size: 24),
                          ),
                        )
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