// 📂 lib/screens/chat_screen.dart
// ✅ ChatScreen DATA-DRIVEN con Riverpod (STATEFUL)
// ✅ Muestra último mensaje real (por fecha)
// ✅ Mantiene colores diferentes por conversación (color por chat)
// ✅ No crashea si falta la imagen
// ✅ Ahora permite AGREGAR chats desde MatchScreen (upsertThread)
// ✅ Diseño intacto Matchy

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'chat_detalle_screen.dart';

// 🔴 CHINCHE NAV IMPORTS — mismas pantallas que usan Perfil/Citas/Matchy
import 'package:proyectos_matchy/screens/perfil_screen.dart';
import 'package:proyectos_matchy/screens/citas_screen.dart';
import 'package:proyectos_matchy/screens/panel_screen.dart';
import 'package:proyectos_matchy/screens/matchys_screen.dart';

// ================================================================
// 🔹 MODELOS “LÓGICOS” (threads + mensajes)
// ================================================================
enum ChatSender { ella, yo }

class ChatMessage {
  final String id;
  final String chatId;
  final String text;
  final ChatSender sender;
  final DateTime sentAt;

  const ChatMessage({
    required this.id,
    required this.chatId,
    required this.text,
    required this.sender,
    required this.sentAt,
  });
}

class ChatThread {
  final String id; // coincide con chica1.png etc
  final String nombre;
  final int edad;

  final String fotoAsset;

  // 🔴 CHINCHE CHAT COLOR 1 — color único por conversación
  final Color accent;

  // 🔴 CHINCHE CHAT DATA 1 — mensajes del chat
  final List<ChatMessage> messages;

  ChatThread({
    required this.id,
    required this.nombre,
    required this.edad,
    required this.fotoAsset,
    required this.accent,
    required this.messages,
  });

  ChatMessage? get lastMessage {
    if (messages.isEmpty) return null;
    final sorted = [...messages]..sort((a, b) => b.sentAt.compareTo(a.sentAt));
    return sorted.first;
  }

  ChatThread copyWith({
    String? nombre,
    int? edad,
    String? fotoAsset,
    Color? accent,
    List<ChatMessage>? messages,
  }) {
    return ChatThread(
      id: id,
      nombre: nombre ?? this.nombre,
      edad: edad ?? this.edad,
      fotoAsset: fotoAsset ?? this.fotoAsset,
      accent: accent ?? this.accent,
      messages: messages ?? this.messages,
    );
  }
}

// ================================================================
// 🔹 NOTIFIER (estado real)
// ================================================================
class ChatThreadsNotifier extends StateNotifier<List<ChatThread>> {
  ChatThreadsNotifier() : super(_buildInitialThreads());

  // 🔴 CHINCHE CHAT COLORS 2 — paleta fija
  static const palette = <Color>[
    Color(0x4D6A5ACD),
    Color(0x4D00BCD4),
    Color(0x4D8BC34A),
    Color(0x4DFF9800),
    Color(0x4DE91E63),
    Color(0x4D9C27B0),
    Color(0x4D03A9F4),
    Color(0x4DFFC107),
    Color(0x4D607D8B),
    Color(0x4D795548),
  ];

  static Color pickColor(String id) {
    final h = id.codeUnits.fold<int>(0, (p, c) => (p + c) & 0x7fffffff);
    return palette[h % palette.length];
  }

  // ✅ AGREGA O ACTUALIZA️: se llama desde MatchScreen
  void upsertThread({
    required String id,
    required String nombre,
    required int edad,
    required String fotoAsset,
  }) {
    final idx = state.indexWhere((t) => t.id == id);

    if (idx >= 0) {
      // ya existe → solo actualiza datos por si cambiaron
      final updated = state[idx].copyWith(
        nombre: nombre,
        edad: edad,
        fotoAsset: fotoAsset,
      );
      final next = [...state];
      next[idx] = updated;
      state = _sortedByLastMessage(next);
      return;
    }

    // no existe → crear nuevo chat (sin mensajes por ahora)
    final newThread = ChatThread(
      id: id,
      nombre: nombre,
      edad: edad,
      fotoAsset: fotoAsset,
      accent: pickColor(id),
      messages: <ChatMessage>[],
    );

    state = _sortedByLastMessage([newThread, ...state]);
  }

  static List<ChatThread> _sortedByLastMessage(List<ChatThread> input) {
    final next = [...input];
    next.sort((a, b) {
      final da = a.lastMessage?.sentAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final db = b.lastMessage?.sentAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return db.compareTo(da);
    });
    return next;
  }

  static List<ChatThread> _buildInitialThreads() {
    DateTime d(int day, int hour, int minute) => DateTime(2026, 1, day, hour, minute);

    final threads = <ChatThread>[
      ChatThread(
        id: 'chica1',
        nombre: 'Anita',
        edad: 22,
        fotoAsset: 'assets/images/chica1.png',
        accent: pickColor('chica1'),
        messages: [
          ChatMessage(id: 'm1', chatId: 'chica1', text: 'Holaaa 😊', sender: ChatSender.ella, sentAt: d(2, 18, 20)),
          ChatMessage(id: 'm2', chatId: 'chica1', text: '¿Dónde vives?', sender: ChatSender.ella, sentAt: d(2, 18, 25)),
        ],
      ),
      ChatThread(
        id: 'chica2',
        nombre: 'Carla',
        edad: 24,
        fotoAsset: 'assets/images/chica2.png',
        accent: pickColor('chica2'),
        messages: [
          ChatMessage(id: 'm1', chatId: 'chica2', text: 'Me encanta el café ☕', sender: ChatSender.ella, sentAt: d(3, 10, 10)),
          ChatMessage(id: 'm2', chatId: 'chica2', text: '¿Tú eres más de capuccino o negro?', sender: ChatSender.ella, sentAt: d(3, 10, 12)),
        ],
      ),
      ChatThread(
        id: 'chica3',
        nombre: 'María',
        edad: 25,
        fotoAsset: 'assets/images/chica3.png',
        accent: pickColor('chica3'),
        messages: [
          ChatMessage(id: 'm1', chatId: 'chica3', text: 'Tengo 3 gatos 🐱', sender: ChatSender.yo, sentAt: d(1, 21, 40)),
          ChatMessage(id: 'm2', chatId: 'chica3', text: 'No me digas eso que me enamoro 😅', sender: ChatSender.ella, sentAt: d(1, 21, 42)),
        ],
      ),
      ChatThread(
        id: 'chica4',
        nombre: 'Julia',
        edad: 23,
        fotoAsset: 'assets/images/chica4.png',
        accent: pickColor('chica4'),
        messages: [
          ChatMessage(id: 'm1', chatId: 'chica4', text: 'Nos vemos el viernes', sender: ChatSender.ella, sentAt: d(4, 14, 5)),
        ],
      ),
      ChatThread(
        id: 'chica5',
        nombre: 'Valentina',
        edad: 28,
        fotoAsset: 'assets/images/chica5.png',
        accent: pickColor('chica5'),
        messages: [
          ChatMessage(id: 'm1', chatId: 'chica5', text: 'Jajaja sí, qué divertido 😂', sender: ChatSender.yo, sentAt: d(4, 22, 12)),
        ],
      ),
    ];

    return _sortedByLastMessage(threads);
  }
}

// ================================================================
// 🔹 PROVIDER (estado real)
// ================================================================
final chatThreadsProvider =
StateNotifierProvider<ChatThreadsNotifier, List<ChatThread>>(
      (ref) => ChatThreadsNotifier(),
);

// ================================================================
// 🔹 PANTALLA DE CHATS
// ================================================================
class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🔴 CHINCHE CHAT A — espacio barra de estado → logo
    const double espacioBarraLogo = 35;

    // 🔴 CHINCHE CHAT B — altura del logo
    const double alturaLogo = 50;

    // 🔴 CHINCHE CHAT C — espacio logo → título "CHATS"
    const double espacioLogoTitulo = 15;

    // 🔴 CHINCHE CHAT D — espacio título → primera tarjeta
    const double espacioTituloLista = 8;

    // 🔴 CHINCHE CHAT E — espacio inferior del listado
    const double espacioBottomLista = 80;

    final chats = ref.watch(chatThreadsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      bottomNavigationBar: const _MatchyBottomNav(currentIndex: 4),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover),
          ),
          Column(
            children: [
              const SizedBox(height: espacioBarraLogo),
              SizedBox(
                height: alturaLogo,
                child: Image.asset('assets/images/logomatchyplano.png'),
              ),
              const SizedBox(height: espacioLogoTitulo),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'CHATS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: espacioTituloLista),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: espacioBottomLista,
                  ),
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    return _ChatCard(thread: chat);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ================================================================
// 🔹 TARJETA DE CHAT (usa lastMessage real)
// ================================================================
class _ChatCard extends StatelessWidget {
  final ChatThread thread;

  const _ChatCard({required this.thread});

  @override
  Widget build(BuildContext context) {
    final last = thread.lastMessage;
    final bool ultimoEsElla = last?.sender == ChatSender.ella;
    final String preview = last?.text ?? 'Sin mensajes aún';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 6,
      color: thread.accent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatDetalleScreen(
                nombre: thread.nombre,
                edad: thread.edad.toString(),
                id: thread.id,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: _SafeAssetImage(
                  asset: thread.fotoAsset,
                  width: 60,
                  height: 60,
                  fallback: 'assets/images/perfil1.jpg',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${thread.nombre}, ${thread.edad}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color:
                        ultimoEsElla ? Colors.white : const Color(0xFFB3D9FF),
                        fontSize: 13,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// ✅ Imagen asset segura (no crashea si falta)
// ================================================================
class _SafeAssetImage extends StatelessWidget {
  final String asset;
  final double width;
  final double height;
  final String fallback;

  const _SafeAssetImage({
    required this.asset,
    required this.width,
    required this.height,
    required this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Image.asset(
        fallback,
        width: width,
        height: height,
        fit: BoxFit.cover,
      ),
    );
  }
}

// ================================================================
// 🔹 BARRA DE NAVEGACIÓN INFERIOR — IGUAL A PERFIL/CITAS/MATCHY
// ================================================================
class _MatchyBottomNav extends StatelessWidget {
  final int currentIndex;

  const _MatchyBottomNav({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    const Color navBackground = Color(0xCC000000);
    const Color selectedColor = Color(0xFFE0D4FF);
    final Color unselectedColor = Colors.white70;

    return BottomNavigationBar(
      backgroundColor: navBackground,
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      selectedItemColor: selectedColor,
      unselectedItemColor: unselectedColor,
      items: [
        _navItem('assets/images/profile.png', 'Perfil'),
        _navItem('assets/images/citas.png', 'Citas'),
        _navItem('assets/images/panel.png', 'Panel'),
        _navItem('assets/images/matchy.png', 'Matchy'),
        _navItem('assets/images/chat.png', 'Chat'),
      ],
      onTap: (index) {
        if (index == currentIndex) return;

        Widget destino;
        switch (index) {
          case 0:
            destino = const PerfilScreen();
            break;
          case 1:
            destino = const CitasScreen();
            break;
          case 2:
            destino = const PanelScreen();
            break;
          case 3:
            destino = const MatchysScreen();
            break;
          default:
            destino = const ChatScreen();
        }

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => destino),
              (route) => false,
        );
      },
    );
  }

  static BottomNavigationBarItem _navItem(String asset, String label) {
    return BottomNavigationBarItem(
      icon: SizedBox(
        height: 24,
        child: Image.asset(asset, width: 22, height: 22),
      ),
      label: label,
    );
  }
}
