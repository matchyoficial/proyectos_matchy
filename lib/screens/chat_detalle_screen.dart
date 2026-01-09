// 📂 lib/screens/chat_detalle_screen.dart
// ✅ ChatDetalleScreen DATA-DRIVEN con Riverpod
// ✅ Usa los mensajes reales del ChatThread
// ✅ Respeta remitente (yo / ella) y fechas
// ✅ Diseño intacto Matchy

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:proyectos_matchy/widgets/matchy_back_button.dart';
import 'package:proyectos_matchy/screens/chat_screen.dart'; // 🔴 acceso a modelos y provider

class ChatDetalleScreen extends ConsumerStatefulWidget {
  final String nombre;
  final String edad;
  final String id; // 🔴 coincide con chicaX

  const ChatDetalleScreen({
    super.key,
    required this.nombre,
    required this.edad,
    required this.id,
  });

  @override
  ConsumerState<ChatDetalleScreen> createState() => _ChatDetalleScreenState();
}

class _ChatDetalleScreenState extends ConsumerState<ChatDetalleScreen> {
  String input = "";

  @override
  Widget build(BuildContext context) {
    const double espacioBarraLogo = 35;
    const double alturaLogo = 50;
    const double espacioLogoHeader = 15;
    const double espacioBottomMensajes = 70;

    // =======================================================
    // 🔹 OBTENER THREAD DESDE RIVERPOD
    // =======================================================
    final threads = ref.watch(chatThreadsProvider);

    final thread = threads.firstWhere(
          (t) => t.id == widget.id,
      orElse: () => ChatThread(
        id: widget.id,
        nombre: widget.nombre,
        edad: int.tryParse(widget.edad) ?? 0,
        fotoAsset: 'assets/images/perfil1.jpg',
        accent: const Color(0x4D6A5ACD),
        messages: <ChatMessage>[],
      ),
    );

    final messages = thread.messages;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover),
          ),
          const MatchyBackButton(
            top: 10,
            left: 16,
          ),
          Column(
            children: [
              const SizedBox(height: espacioBarraLogo),
              SizedBox(
                height: alturaLogo,
                child: Image.asset('assets/images/logomatchyplano.png'),
              ),
              const SizedBox(height: espacioLogoHeader),

              // HEADER
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.asset(
                        thread.fotoAsset,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Image.asset(
                          'assets/images/perfil1.jpg',
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${widget.nombre}, ${widget.edad}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // MENSAJES
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      for (final m in messages) ...[
                        _MensajeBubble(texto: m.text, sender: m.sender),
                      ],
                      const SizedBox(height: espacioBottomMensajes),
                    ],
                  ),
                ),
              ),

              // INPUT (UI)
              Container(
                color: Colors.black.withOpacity(0.6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Poppins',
                        ),
                        decoration: InputDecoration(
                          hintText: 'Escribe un mensaje...',
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontFamily: 'Poppins',
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white54),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                        ),
                        onChanged: (t) => setState(() => input = t),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB3D9FF),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                      onPressed: () {
                        // 🔴 SOLO UI — backend luego
                        setState(() => input = '');
                      },
                      child: const Text(
                        'Enviar',
                        style: TextStyle(
                          color: Colors.black,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MensajeBubble extends StatelessWidget {
  final String texto;
  final ChatSender sender;

  const _MensajeBubble({
    required this.texto,
    required this.sender,
  });

  @override
  Widget build(BuildContext context) {
    final bool esYo = sender == ChatSender.yo;

    return Align(
      alignment: esYo ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: esYo ? const Color(0xFFB3D9FF) : Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          texto,
          style: const TextStyle(
            color: Colors.black,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }
}
