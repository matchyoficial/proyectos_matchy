// 📂 lib/screens/citas_screen.dart
// ✅ PANTALLA CITAS FINAL (JUEZ SUPREMO 3 MINUTOS)
// 🔥 FIX LOGIC: El Reloj ahora espera al segundo usuario para cerrar la cita (Doble check).
// 🔥 FIX UI: Layout 60/40, Letreros arriba-izq, Textos ajustados.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:proyectos_matchy/widgets/matchy_page_layout.dart';
import 'package:proyectos_matchy/screens/cita_detalle_screen.dart';
import 'package:proyectos_matchy/screens/reprogramar_cita_aceptar_screen.dart';
import 'package:proyectos_matchy/screens/nueva_cita_solicitud_screen.dart';
import 'package:proyectos_matchy/widgets/foto_perfil_usuario.dart';
import 'package:proyectos_matchy/screens/reporte_inasistencia_screen.dart';

const String kCitasCollection = 'citas';

// --- MODELO ---
class CitaItem {
  final String id;
  final String lugarId;
  final String nombreMostrar;
  final String fotoMostrar;
  final String matchyUid;
  final int matchyEdad;
  final String lugarNombre;
  final String lugarDireccion;
  final String fotoLugar;
  final DateTime fechaSort;
  final String fechaTextoOriginal;
  final String horaTexto;
  final String intencion;
  final String preferencia;
  final String codigoOwner;
  final String codigoMatchy;
  final bool isOwner;
  final String status;
  final String reproByUid;
  final bool esUrgente;
  final bool tengoPropuestaAcuerdo;
  final bool tengoSolicitudAcuerdo;
  final bool isPrivate;
  final DateTime? deadline;
  final bool amISafeGPS;
  final bool amIPunished;

  const CitaItem({
    required this.id,
    required this.lugarId,
    required this.nombreMostrar,
    required this.fotoMostrar,
    required this.matchyUid,
    required this.matchyEdad,
    required this.lugarNombre,
    required this.lugarDireccion,
    required this.fotoLugar,
    required this.fechaSort,
    required this.fechaTextoOriginal,
    required this.horaTexto,
    required this.intencion,
    required this.preferencia,
    required this.codigoOwner,
    required this.codigoMatchy,
    required this.isOwner,
    required this.status,
    required this.reproByUid,
    required this.esUrgente,
    required this.tengoPropuestaAcuerdo,
    required this.tengoSolicitudAcuerdo,
    required this.isPrivate,
    required this.deadline,
    required this.amISafeGPS,
    required this.amIPunished,
  });
}

// --- FUNCIÓN DE CONVERSIÓN (GLOBAL) ---
CitaItem? _convertirDoc(DocumentSnapshot doc, bool soyOwner, DateTime ahora) {
  try {
    final data = doc.data() as Map<String, dynamic>;
    if (data['status'] == 'finished') return null;

    // Filtro personal de castigo
    bool yaPague = soyOwner ? (data['ownerCastigado'] == true) : (data['matchyCastigado'] == true);
    if (yaPague) return null;

    final nombreUI = soyOwner ? (data['matchyNombre'] ?? 'Usuario') : (data['ownerNombre'] ?? 'Usuario');
    final fotoUI = soyOwner ? (data['matchyFoto'] ?? '') : (data['ownerFoto'] ?? '');
    final uidUI = soyOwner ? (data['matchyUid'] ?? '') : (data['ownerUid'] ?? '');
    final edadRaw = soyOwner ? (data['matchyEdad']) : (data['ownerEdad']);
    final int edadUI = (edadRaw is int) ? edadRaw : int.tryParse(edadRaw.toString()) ?? 0;

    final lNombre = data['lugarNombre'] ?? 'Lugar';
    final lDir = data['lugarDireccion'] ?? '';
    final lFoto = data['lugarFotoPortada'] ?? '';
    final lId = (data['lugarId'] ?? '').toString();

    final fTexto = (data['fecha'] ?? '').toString();
    final hTexto = (data['hora'] ?? '').toString();

    DateTime fechaReal = DateTime(2099);
    try {
      final parts = fTexto.trim().split(RegExp(r'[/ -]'));
      int d = int.parse(parts[0]), m = int.parse(parts[1]), y = int.parse(parts[2]);
      String rawHora = hTexto.toUpperCase().replaceAll('.', '').trim();
      bool esPM = rawHora.contains("PM");
      final tP = rawHora.replaceAll(RegExp(r'[^0-9:]'), '').split(':');
      int hh = int.parse(tP[0]), mm = int.parse(tP[1]);
      if (esPM && hh != 12) hh += 12; else if (!esPM && hh == 12) hh = 0;
      fechaReal = DateTime(y, m, d, hh, mm);
    } catch (_) {}

    // 🔥 JUEZ: 3 MINUTOS
    final deadline = fechaReal.add(const Duration(minutes: 3));
    final diferencia = ahora.difference(fechaReal);
    // Urgente si ya pasó la hora o estamos en los 3 minutos de gracia
    final urgente = diferencia.inMinutes > 0 && (data['status'] == 'matched' || data['status'] == 'mutual_agreement_pending');

    return CitaItem(
      id: doc.id,
      lugarId: lId,
      nombreMostrar: nombreUI.toString(),
      fotoMostrar: fotoUI.toString(),
      matchyUid: uidUI.toString(),
      matchyEdad: edadUI,
      lugarNombre: lNombre.toString(),
      lugarDireccion: lDir.toString(),
      fotoLugar: lFoto.toString(),
      fechaSort: fechaReal,
      fechaTextoOriginal: fTexto,
      horaTexto: hTexto,
      intencion: (data['intencion'] ?? '').toString(),
      preferencia: (data['preferencia'] ?? '').toString(),
      codigoOwner: (data['codigoOwner'] ?? '').toString(),
      codigoMatchy: (data['codigoMatchy'] ?? '').toString(),
      isOwner: soyOwner,
      status: (data['status'] ?? 'matched').toString(),
      reproByUid: (data['repro_by_uid'] ?? '').toString(),
      esUrgente: urgente,
      tengoPropuestaAcuerdo: soyOwner ? data['ownerPropusoAcuerdo'] == true : data['matchyPropusoAcuerdo'] == true,
      tengoSolicitudAcuerdo: soyOwner ? data['matchyPropusoAcuerdo'] == true : data['ownerPropusoAcuerdo'] == true,
      isPrivate: data['isPrivate'] == true,
      deadline: deadline,
      amISafeGPS: soyOwner ? data['gpsCheckOwner'] == true : data['gpsCheckMatchy'] == true,
      amIPunished: yaPague,
    );
  } catch (e) { return null; }
}

// --- PROVIDERS ---
final relojProvider = StreamProvider.autoDispose<int>((ref) {
  return Stream.periodic(const Duration(seconds: 10), (i) => i);
});

final citasRawOwnerProvider = StreamProvider.autoDispose<List<DocumentSnapshot>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return const Stream.empty();
  return FirebaseFirestore.instance.collection(kCitasCollection)
      .where('ownerUid', isEqualTo: user.uid)
      .where('status', whereIn: ['matched', 'reprogramming', 'pending_approval', 'mutual_agreement_pending', 'mutual_agreement_finish'])
      .snapshots().map((s) => s.docs);
});

final citasRawMatchyProvider = StreamProvider.autoDispose<List<DocumentSnapshot>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return const Stream.empty();
  return FirebaseFirestore.instance.collection(kCitasCollection)
      .where('matchyUid', isEqualTo: user.uid)
      .where('status', whereIn: ['matched', 'reprogramming', 'pending_approval', 'mutual_agreement_pending', 'mutual_agreement_finish'])
      .snapshots().map((s) => s.docs);
});

final misCitasMezcladasProvider = Provider.autoDispose<AsyncValue<List<CitaItem>>>((ref) {
  final ownerRaw = ref.watch(citasRawOwnerProvider);
  final matchyRaw = ref.watch(citasRawMatchyProvider);
  ref.watch(relojProvider);
  final ahoraMismo = DateTime.now();

  if (ownerRaw.isLoading || matchyRaw.isLoading) return const AsyncValue.loading();

  final docsOwner = ownerRaw.value ?? [];
  final docsMatchy = matchyRaw.value ?? [];
  List<CitaItem> listaFinal = [];

  for (var doc in docsOwner) {
    final item = _convertirDoc(doc, true, ahoraMismo);
    if (item != null) listaFinal.add(item);
  }
  for (var doc in docsMatchy) {
    final item = _convertirDoc(doc, false, ahoraMismo);
    if (item != null) listaFinal.add(item);
  }

  listaFinal.sort((a, b) => a.fechaSort.compareTo(b.fechaSort));
  return AsyncValue.data(listaFinal);
});

// --- PANTALLA ---
class CitasScreen extends ConsumerWidget {
  final bool showBottomNav;
  const CitasScreen({super.key, this.showBottomNav = true});

  // ⚖️ EL JUEZ SUPREMO
  void _ejecutarLogicaJuez(List<CitaItem> citas, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final now = DateTime.now();

    for (var cita in citas) {
      if (cita.amIPunished) continue;

      if (cita.status == 'mutual_agreement_finish') {
        _sentenciaFinal(cita, user, -10, 'Acuerdo de Cancelación', 'Se restaron -10 pts por acuerdo mutuo.', 'info', 'mutual_agreement');
      }
      else if (cita.deadline != null && now.isAfter(cita.deadline!)) {
        if (cita.amISafeGPS) {
          _marcarRecibo(cita);
        } else {
          _sentenciaFinal(cita, user, -20, 'Sanción Inasistencia', 'Se restaron -20 pts por no asistir.', 'danger', 'timeout_punished');
        }
      }
    }
  }

  Future<void> _sentenciaFinal(CitaItem cita, User user, int puntos, String title, String body, String type, String resultado) async {
    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
        final citaRef = FirebaseFirestore.instance.collection('citas').doc(cita.id);

        final uSnap = await tx.get(userRef);
        final cSnap = await tx.get(citaRef); // Leemos el estado fresco de la cita

        int score = (uSnap.data()?['confiabilidad'] as num?)?.toInt() ?? 100;

        // 1. Cobro al Usuario
        Map<String, dynamic> userUpdates = {'confiabilidad': (score + puntos).clamp(0, 100)};
        if (puntos <= -20) {
          int strikes = (uSnap.data()?['strikes'] as num?)?.toInt() ?? 0;
          int newS = strikes + 1;
          userUpdates['strikes'] = newS;
          userUpdates['citas_consecutivas_exitosas'] = 0;
          userUpdates['userStatus'] = newS >= 5 ? 'blocked_permanent' : 'blocked';
          userUpdates['bloqueadoHasta'] = Timestamp.fromDate(DateTime.now().add(Duration(days: newS * 5)));
        }
        tx.update(userRef, userUpdates);

        // 2. Notificación
        tx.set(userRef.collection('notifications').doc(), {
          'title': title, 'body': body, 'type': type, 'read': false, 'createdAt': FieldValue.serverTimestamp()
        });

        // 3. Cierre de Cita (LÓGICA BLINDADA DE RELOJ)
        String myField = cita.isOwner ? 'ownerCastigado' : 'matchyCastigado';
        String otherField = cita.isOwner ? 'matchyCastigado' : 'ownerCastigado';
        bool elOtroYaEstaCastigado = cSnap.data()?[otherField] == true;

        if (resultado == 'timeout_punished') {
          // Si es Timeout, SOLO cierro si el otro ya cayó.
          if (elOtroYaEstaCastigado) {
            tx.update(citaRef, { myField: true, 'status': 'finished', 'resultado': 'timeout_punished' });
          } else {
            tx.update(citaRef, { myField: true }); // Solo me marco yo, espero al otro
          }
        } else {
          // Si es Acuerdo Mutuo, cerramos normal (ya hay estado finish)
          tx.update(citaRef, { myField: true, 'status': 'finished', 'resultado': resultado });
        }
      });
    } catch (e) { debugPrint("Juez Error: $e"); }
  }

  Future<void> _marcarRecibo(CitaItem cita) async {
    try {
      String myField = cita.isOwner ? 'ownerCastigado' : 'matchyCastigado';
      await FirebaseFirestore.instance.collection('citas').doc(cita.id).update({myField: true});
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<List<CitaItem>>>(misCitasMezcladasProvider, (prev, next) {
      next.whenData((list) => _ejecutarLogicaJuez(list, ref));
    });

    return Scaffold(
      body: Stack(
        children: [
          MatchyPageLayout(
            backgroundAsset: 'assets/images/fondo.jpg',
            logoAsset: 'assets/images/logomatchyplano.png',
            topSpacing: 35,
            logoHeight: 45,
            scrollContent: const _CitasSplitLayout(),
          ),
          Positioned(bottom: 0, left: 0, right: 0, height: 90, child: IgnorePointer(child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.95)], stops: const [0.0, 1.0]))))),
        ],
      ),
    );
  }
}

class _CitasSplitLayout extends ConsumerWidget {
  const _CitasSplitLayout();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCitas = ref.watch(misCitasMezcladasProvider);
    final size = MediaQuery.of(context).size;

    // Altura calculada para "Próximas" (55% aprox de la pantalla)
    final double heightProximas = size.height * 0.55;
    // Altura fija para "Pendientes"
    final double heightPendientes = 500.0;

    return asyncCitas.when(
      loading: () => SizedBox(height: size.height, child: const Center(child: CircularProgressIndicator(color: Colors.white))),
      error: (_, __) => SizedBox(height: size.height, child: const Center(child: Text("Error cargando citas", style: TextStyle(color: Colors.white)))),
      data: (list) {
        final proximas = list.where((c) => !c.esUrgente && !c.tengoSolicitudAcuerdo && !c.tengoPropuestaAcuerdo && c.status == 'matched').toList();
        final pendientes = list.where((c) => c.esUrgente || c.tengoSolicitudAcuerdo || c.tengoPropuestaAcuerdo || c.status != 'matched').toList();

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. PRÓXIMAS
            SizedBox(
                height: heightProximas,
                child: _Seccion(titulo: "PRÓXIMAS CITAS", citas: proximas, color: const Color(0x40FFFFFF), esPendiente: false)
            ),
            const SizedBox(height: 15),
            // 2. PENDIENTES
            SizedBox(
                height: heightPendientes,
                child: _Seccion(titulo: "PENDIENTES Y POR ACEPTAR", citas: pendientes, color: const Color(0x506B4EE6), esPendiente: true)
            ),
            const SizedBox(height: 120),
          ],
        );
      },
    );
  }
}

class _Seccion extends StatelessWidget {
  final String titulo; final List<CitaItem> citas; final Color color; final bool esPendiente;
  const _Seccion({required this.titulo, required this.citas, required this.color, required this.esPendiente});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white10)),
      child: Column(children: [
        FittedBox(fit: BoxFit.scaleDown, child: Text(titulo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, fontFamily: 'Poppins', shadows: [Shadow(color: Colors.black, blurRadius: 4)]))),
        const SizedBox(height: 12),
        Expanded(
            child: citas.isEmpty
                ? _EmptyState(esPendiente: esPendiente)
                : ListView.builder(
                padding: EdgeInsets.zero,
                physics: const BouncingScrollPhysics(),
                itemCount: citas.length,
                itemBuilder: (_, i) => _CitaCard(item: citas[i])
            )
        ),
      ]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool esPendiente;
  const _EmptyState({required this.esPendiente});
  @override
  Widget build(BuildContext context) {
    if (esPendiente) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(color: const Color(0xFF4527A0).withOpacity(0.5), borderRadius: BorderRadius.circular(20)),
        alignment: Alignment.center,
        child: const Text("No hay solicitudes pendientes.", style: TextStyle(color: Colors.white54, fontSize: 13, fontFamily: 'Poppins')),
      );
    }
    return const Center(child: Text("No tienes citas próximas.", style: TextStyle(color: Colors.white54, fontSize: 13, fontFamily: 'Poppins')));
  }
}

class _CitaCard extends StatelessWidget {
  final CitaItem item;
  const _CitaCard({required this.item});

  String _fechaAmigable(DateTime d) {
    const List<String> dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    const List<String> meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return "${dias[d.weekday - 1]} ${d.day} de ${meses[d.month - 1]}";
  }

  void _handleTap(BuildContext context) {
    if (item.esUrgente || item.tengoPropuestaAcuerdo || item.tengoSolicitudAcuerdo) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ReporteInasistenciaScreen(citaId: item.id)));
      return;
    }
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (item.status == 'matched') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => CitaDetalleScreen(
        citaId: item.id, lugarId: item.lugarId, lugarNombre: item.lugarNombre, lugarDireccion: item.lugarDireccion, lugarFotoPortada: item.fotoLugar, matchyNombre: item.nombreMostrar, matchyFoto: item.fotoMostrar, matchyUid: item.matchyUid, matchyEdad: item.matchyEdad, fecha: item.fechaTextoOriginal, hora: item.horaTexto, intencion: item.intencion, preferencia: item.preferencia, miCodigoCita: item.isOwner ? item.codigoOwner : item.codigoMatchy, codigoDelOtro: item.isOwner ? item.codigoMatchy : item.codigoOwner, isOwner: item.isOwner, citaDateTime: item.fechaSort,
      )));
      return;
    }
    if (item.status == 'pending_approval') {
      if (item.isOwner) {
        _mostrarDialogoEspera(context, "INVITACIÓN ENVIADA", "Esperando que ${item.nombreMostrar} acepte tu invitación.");
      } else {
        Navigator.push(context, MaterialPageRoute(builder: (_) => NuevaCitaSolicitudScreen(citaId: item.id)));
      }
      return;
    }
    if (item.reproByUid == myUid) {
      _mostrarDialogoEspera(context, "ESPERANDO RESPUESTA", "Le enviaste una solicitud a ${item.nombreMostrar}.");
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ReprogramarCitaAceptarScreen(citaId: item.id)));
    }
  }

  void _mostrarDialogoEspera(BuildContext context, String titulo, String msg) {
    showDialog(context: context, builder: (_) => AlertDialog(backgroundColor: const Color(0xFF1A1A1A), title: Text(titulo, style: const TextStyle(color: Color(0xFFE0D4FF))), content: Text(msg, style: const TextStyle(color: Colors.white70)), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))]));
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    String textoBoton = "";
    Color colorEtiqueta = Colors.white;
    Color colorFondoEtiqueta = Colors.black54;
    Color bordeCard = Colors.transparent;
    bool mostrarOverlay = false;

    bool esAcuerdo = item.tengoPropuestaAcuerdo || item.tengoSolicitudAcuerdo;

    if (item.esUrgente && !esAcuerdo) {
      mostrarOverlay = true; textoBoton = "SIN CONFIRMAR";
      colorFondoEtiqueta = const Color(0xFFFF5252); bordeCard = const Color(0xFFFF5252);
    } else if (esAcuerdo) {
      mostrarOverlay = true;
      textoBoton = item.tengoPropuestaAcuerdo ? "ESPERANDO ACUERDO" : "PROPUESTA DE ACUERDO";
      colorFondoEtiqueta = const Color(0xFF448AFF); bordeCard = const Color(0xFF448AFF);
    } else if (item.status == 'reprogramming') {
      mostrarOverlay = true; textoBoton = "REPROGRAMACIÓN";
      colorFondoEtiqueta = Colors.purpleAccent; bordeCard = Colors.purpleAccent;
    } else if (item.status == 'pending_approval') {
      mostrarOverlay = true;
      if (item.isOwner) { textoBoton = "ENVIADA"; colorFondoEtiqueta = Colors.grey; }
      else { textoBoton = "POR ACEPTAR"; colorFondoEtiqueta = const Color(0xFF00E676); }
    } else if (item.reproByUid == myUid && !item.isOwner) {
      mostrarOverlay = true; textoBoton = "ENVIADA"; colorFondoEtiqueta = Colors.grey;
    } else if (item.status == 'reprogramming' && item.reproByUid != myUid) {
      mostrarOverlay = true; textoBoton = "RESPONDER"; colorFondoEtiqueta = const Color(0xFF00E676);
    }

    return GestureDetector(
      onTap: () => _handleTap(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        height: 105, // 🔥 COMPACTO
        decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(20), boxShadow: [const BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 3))], border: mostrarOverlay ? Border.all(color: bordeCard, width: 1.5) : null),
        child: Row(children: [
          // FOTO LUGAR
          Expanded(child: Stack(fit: StackFit.expand, children: [
            ClipRRect(borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)), child: ColorFiltered(colorFilter: mostrarOverlay ? ColorFilter.mode(bordeCard.withOpacity(0.2), BlendMode.srcATop) : const ColorFilter.mode(Colors.transparent, BlendMode.dst), child: item.fotoLugar.isNotEmpty ? Image.network(item.fotoLugar, fit: BoxFit.cover) : Container(color: Colors.grey[900]))),
            Container(decoration: BoxDecoration(borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)), gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black12, Colors.black.withOpacity(0.9)], stops: const [0.4, 1.0]))),

            // 🔥 TEXTO FIX (Sin espacio muerto)
            Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
              FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(item.lugarNombre.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, fontFamily: 'Poppins', height: 1.0, shadows: [Shadow(color: Colors.black, blurRadius: 4)]))),
              Text("${_fechaAmigable(item.fechaSort)} - ${item.horaTexto}", style: const TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'Poppins')),
            ])),

            // 🔥 LETRERO IZQUIERDA ARRIBA
            if (mostrarOverlay) Positioned(top: 8, left: 8, child: _EtiquetaPulsante(texto: textoBoton, bg: colorFondoEtiqueta, color: colorEtiqueta))
          ])),

          // FOTO MATCHY
          SizedBox(width: 105, child: ClipRRect(borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)), child: FotoPerfilUsuario(uid: item.matchyUid, fit: BoxFit.cover)))
        ]),
      ),
    );
  }
}

class _EtiquetaPulsante extends StatefulWidget {
  final String texto; final Color color; final Color bg;
  const _EtiquetaPulsante({required this.texto, required this.color, required this.bg});
  @override State<_EtiquetaPulsante> createState() => _EtiquetaPulsanteState();
}
class _EtiquetaPulsanteState extends State<_EtiquetaPulsante> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true); }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    return FadeTransition(opacity: _c, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: widget.bg, borderRadius: BorderRadius.circular(8)), child: Text(widget.texto, style: TextStyle(color: widget.color, fontWeight: FontWeight.bold, fontSize: 9, fontFamily: 'Poppins'))));
  }
}