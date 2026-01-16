// 📂 lib/services/chat_actions.dart
// ✅ ÚNICA fuente de verdad para ChatActions + constantes de chat
// ✅ ThreadId determinístico uidA__uidB
// ✅ Esquema: chat_threads/{threadId} con participantUids + meta
// ✅ Mensajes: chat_threads/{threadId}/messages/{messageId}
// ✅ Incluye constantes usadas por chat_screen y chat_detalle_screen

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 🔴 CHINCHE CHAT CONST 1 — colección threads
const String kChatThreadsCollection = 'chat_threads';

/// 🔴 CHINCHE CHAT CONST 2 — subcolección mensajes
const String kChatMessagesSubcollection = 'messages';

/// 🔴 CHINCHE CHAT CONST 3 — fields mensajes
const String kMsgText = 'text';
const String kMsgSenderUid = 'senderUid';
const String kMsgSentAt = 'sentAt';

/// 🔴 CHINCHE CHAT CONST 4 — fields thread (lista)
const String kThreadParticipantUids = 'participantUids';
const String kThreadMeta = 'meta';

/// 🔴 CHINCHE CHAT CONST 5 — fields thread (fechas)
const String kThreadCreatedAt = 'createdAt';
const String kThreadUpdatedAt = 'updatedAt';

/// 🔴 CHINCHE CHAT CONST 6 — fields thread (último mensaje para lista)
const String kThreadLastText = 'lastText';
const String kThreadLastAt = 'lastAt';

class ChatActions {
  /// Construye ID determinístico: uidA__uidB (ordenado)
  static String buildThreadId(String uidA, String uidB) {
    final a = uidA.trim();
    final b = uidB.trim();
    if (a.isEmpty || b.isEmpty) return '';
    final pair = [a, b]..sort();
    return '${pair[0]}__${pair[1]}';
  }

  /// ✅ Crea/actualiza el thread y guarda meta para ambos usuarios.
  /// Retorna threadId real.
  static Future<String> upsertThread({
    required String peerUid,
    required String peerNombre,
    required int peerEdad,
    required String peerFoto,
    required String myNombre,
    required int myEdad,
    required String myFoto,
  }) async {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) {
      throw Exception('No hay sesión (FirebaseAuth.currentUser es null)');
    }

    final myUid = me.uid;

    // 🔴 CHINCHE CHAT ACTIONS 3 — BLOQUEO SELF-CHAT
    if (peerUid.trim().isEmpty || peerUid.trim() == myUid.trim()) {
      throw Exception('peerUid inválido (vacío o igual a mi uid)');
    }

    final threadId = buildThreadId(myUid, peerUid);
    if (threadId.isEmpty) {
      throw Exception('threadId inválido (uids vacíos)');
    }

    final ref =
    FirebaseFirestore.instance.collection(kChatThreadsCollection).doc(threadId);

    final snap = await ref.get();
    final now = FieldValue.serverTimestamp();

    final data = <String, dynamic>{
      kThreadParticipantUids: [myUid, peerUid],
      kThreadMeta: {
        myUid: {'nombre': myNombre, 'edad': myEdad, 'foto': myFoto},
        peerUid: {'nombre': peerNombre, 'edad': peerEdad, 'foto': peerFoto},
      },
      kThreadUpdatedAt: now,
      if (!snap.exists) kThreadCreatedAt: now,
      // Inicializamos por si quieres ver algo en la lista
      if (!snap.exists) kThreadLastText: '',
      if (!snap.exists) kThreadLastAt: now,
    };

    await ref.set(data, SetOptions(merge: true));
    return threadId;
  }
}
