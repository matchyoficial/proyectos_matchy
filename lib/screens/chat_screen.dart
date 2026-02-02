// 📂 lib/screens/chat_screen.dart
// ✅ LISTA DE CHATS (FOTO INTELIGENTE + DISEÑO PRO)
// 🔥 FIX: Implementado 'FotoPerfilUsuario' para actualizar fotos automáticamente.
// 🔥 UI: Diseño Pro, Fade Out, Logo y Sombras intactos.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proyectos_matchy/services/chat_actions.dart';
import 'package:proyectos_matchy/screens/chat_detalle_screen.dart';
import 'package:proyectos_matchy/widgets/foto_perfil_usuario.dart'; // 👈 WIDGET FOTO

// UI Model
class ChatThreadUI {
  final String id;
  final String otherUid;
  final String nombre;
  final String foto; // Solo nombre y foto
  final String lastText;
  final DateTime? lastAt;

  ChatThreadUI({
    required this.id,
    required this.otherUid,
    required this.nombre,
    required this.foto,
    required this.lastText,
    required this.lastAt,
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
  // 🔴🔴 CHINCHES MAESTROS (DISEÑO CHAT PRO) 🔴🔴
  // ===========================================================================
  static const double kTopSpacing   = 35.0;  // Espacio superior
  static const double kLogoHeight   = 45.0;  // 🔥 AJUSTADO A 45
  static const double kPaddingH     = 20.0;  // Padding lateral
  static const double kCardHeight   = 85.0;  // Altura tarjeta chat
  static const double kAvatarSize   = 60.0;  // Tamaño avatar
  static const double kCardRadius   = 22.0;  // Redondeo tarjeta
  static const double kAvatarRadius = 16.0;  // Redondeo foto (Cuadrado rounded)

  // Colores PRO
  static const List<Color> kCardGradient = [Color(0xFF7A43BF), Color(0xFF1A1A24)];
  static const BoxShadow kCardShadow = BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 4));
  // ===========================================================================

  ChatThreadUI _mapData(String myUid, QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Fecha y Texto
    final lastText = (data['lastText'] ?? '').toString();
    DateTime? lastAt;
    if (data['lastAt'] is Timestamp) lastAt = (data['lastAt'] as Timestamp).toDate();

    // Identificar al otro usuario
    final List parts = (data['participantUids'] is List) ? data['participantUids'] : [];
    final otherUid = parts.firstWhere((id) => id != myUid, orElse: () => '').toString();

    // Metadatos visuales
    String nombre = 'Matchy';
    String foto = '';

    final meta = data['meta'];
    if (otherUid.isNotEmpty && meta is Map && meta.containsKey(otherUid)) {
      final info = meta[otherUid];
      nombre = info['nombre'] ?? 'Matchy';
      foto = info['foto'] ?? '';
    }

    return ChatThreadUI(
      id: doc.id,
      otherUid: otherUid,
      nombre: nombre,
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
          // 1. Fondo
          Positioned.fill(child: Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover)),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: kTopSpacing),
              Center(child: SizedBox(height: kLogoHeight, child: Image.asset('assets/images/logomatchyplano.png'))),

              const SizedBox(height: 20),

              // 🔥 TÍTULO CENTRADO Y GRANDE
              const Center(
                child: Text(
                  'CHATS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24, // Más grande
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    shadows: [
                      Shadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4))
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 15),

              Expanded(
                child: user == null
                    ? const Center(child: Text("Inicia sesión", style: TextStyle(color: Colors.white)))
                    : StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('chat_threads')
                      .where('participantUids', arrayContains: user.uid)
                      .snapshots(),
                  builder: (context, snap) {
                    if (snap.hasError) return Center(child: Text("Error: ${snap.error}", style: const TextStyle(color: Colors.white)));
                    if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.white));

                    final docs = snap.data?.docs ?? [];

                    // Estado vacío elegante
                    if (docs.isEmpty) {
                      return Container(
                        width: double.infinity,
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

                    // Mapeo y Ordenamiento
                    final threads = docs.map((d) => _mapData(user.uid, d)).toList();
                    threads.sort((a, b) => (b.lastAt ?? DateTime(0)).compareTo(a.lastAt ?? DateTime(0)));

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(kPaddingH, 0, kPaddingH, 100), // Espacio inferior para el fade
                      itemCount: threads.length,
                      separatorBuilder: (_,__) => const SizedBox(height: 14),
                      itemBuilder: (ctx, i) {
                        final t = threads[i];
                        return GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatDetalleScreen(
                            id: t.id,
                            otherUid: t.otherUid,
                            nombre: t.nombre,
                            edad: '', // Ya no mostramos edad
                            foto: t.foto,
                          ))),
                          child: Container(
                            height: kCardHeight,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(kCardRadius),
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: kCardGradient,
                              ),
                              boxShadow: const [kCardShadow],
                              border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
                            ),
                            child: Row(
                              children: [
                                // FOTO (Widget Inteligente)
                                ClipRRect(
                                    borderRadius: BorderRadius.circular(kAvatarRadius),
                                    child: SizedBox(
                                        width: kAvatarSize,
                                        height: kAvatarSize,
                                        // 🔥 AQUÍ ESTÁ EL CAMBIO
                                        child: FotoPerfilUsuario(
                                          uid: t.otherUid,
                                          fit: BoxFit.cover,
                                          alignment: Alignment.topCenter,
                                        )
                                    )
                                ),

                                const SizedBox(width: 15),

                                // TEXTOS
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                          t.nombre,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17, fontFamily: 'Poppins')
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                          t.lastText.isEmpty ? "Nuevo match 💖" : t.lastText,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, fontFamily: 'Poppins')
                                      ),
                                    ],
                                  ),
                                ),

                                // Flecha
                                Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.4), size: 28)
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              )
            ],
          ),

          // 2. 🔥 DEGRADADO INFERIOR (FADE OUT)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 90, // Altura del fade
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.95), // Negro intenso al final
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: widget.showBottomNav ? const SizedBox.shrink() : null,
    );
  }
}