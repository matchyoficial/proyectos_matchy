// 📂 lib/screens/citas_screen.dart
// ✅ PANTALLA CITAS (FINAL)
// 🔥 UI: Nombres de sitios ajustados (1 línea, FittedBox).
// 🔥 UI: Botones 'POR ACEPTAR/RESPONDER' con animación de LATIDO (Pulso).

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proyectos_matchy/widgets/matchy_page_layout.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// ✅ IMPORTS CRÍTICOS
import 'package:proyectos_matchy/screens/cita_detalle_screen.dart';
import 'package:proyectos_matchy/screens/reprogramar_cita_aceptar_screen.dart';
import 'package:proyectos_matchy/screens/nueva_cita_solicitud_screen.dart';

// 🔵 SECCIÓN 1: CONFIGURACIÓN
const String kCitasCollection = 'citas';

// 🔵 SECCIÓN 2: MODELO DE DATOS
class CitaItem {
  final String id;
  final String nombreMostrar;
  final String fotoMostrar;
  final String matchyUid;
  final int matchyEdad;
  final String lugarNombre;
  final String lugarDireccion;
  final String fotoLugar;
  final DateTime fechaSort;
  final String fechaTexto;
  final String horaTexto;
  final String intencion;
  final String preferencia;
  final String codigoOwner;
  final String codigoMatchy;
  final DateTime? scheduledAt;
  final bool isOwner;
  final String status;
  final String reproByUid;
  final bool isPrivate;

  const CitaItem({
    required this.id,
    required this.nombreMostrar,
    required this.fotoMostrar,
    required this.matchyUid,
    required this.matchyEdad,
    required this.lugarNombre,
    required this.lugarDireccion,
    required this.fotoLugar,
    required this.fechaSort,
    required this.fechaTexto,
    required this.horaTexto,
    required this.intencion,
    required this.preferencia,
    required this.codigoOwner,
    required this.codigoMatchy,
    this.scheduledAt,
    required this.isOwner,
    required this.status,
    required this.reproByUid,
    required this.isPrivate,
  });
}

// 🔵 SECCIÓN 3: PROVIDER
final misCitasStreamProvider = StreamProvider<List<CitaItem>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return const Stream.empty();

  final controller = StreamController<List<CitaItem>>();
  List<CitaItem> listaOwner = [];
  List<CitaItem> listaMatchy = [];

  DateTime parsearFechaYHora(String fechaStr, String horaStr) {
    try {
      String cleanHora = horaStr.replaceAll('.', '').toUpperCase().trim();
      DateFormat format = DateFormat("d/M/yyyy h:mm a");
      return format.parse("$fechaStr $cleanHora");
    } catch (e) {
      return DateTime.now().add(const Duration(days: 365));
    }
  }

  List<CitaItem> procesarSnapshot(QuerySnapshot snap, bool soyOwner) {
    final lista = <CitaItem>[];
    for (final doc in snap.docs) {
      try {
        final data = doc.data() as Map<String, dynamic>;

        final nombreUI = soyOwner ? (data['matchyNombre'] ?? 'Usuario') : (data['ownerNombre'] ?? 'Usuario');
        final fotoUI = soyOwner ? (data['matchyFoto'] ?? '') : (data['ownerFoto'] ?? '');
        final uidUI = soyOwner ? (data['matchyUid'] ?? '') : (data['ownerUid'] ?? '');
        final edadRaw = soyOwner ? (data['matchyEdad']) : (data['ownerEdad']);
        final int edadUI = (edadRaw is int) ? edadRaw : int.tryParse(edadRaw.toString()) ?? 0;

        final lNombre = data['LugarNombre'] ?? data['lugarNombre'] ?? 'Lugar';
        final lDir = data['LugarDireccion'] ?? data['lugarDireccion'] ?? '';
        final lFoto = data['LugarFotoPortada'] ?? data['lugarFotoPortada'] ?? '';
        final String fTexto = (data['fecha'] ?? '').toString();
        final String hTexto = (data['hora'] ?? '').toString();

        lista.add(CitaItem(
          id: doc.id,
          nombreMostrar: nombreUI.toString(),
          fotoMostrar: fotoUI.toString(),
          matchyUid: uidUI.toString(),
          matchyEdad: edadUI,
          lugarNombre: lNombre.toString(),
          lugarDireccion: lDir.toString(),
          fotoLugar: lFoto.toString(),
          fechaTexto: fTexto,
          horaTexto: hTexto,
          intencion: (data['intencion'] ?? 'Conocernos').toString(),
          preferencia: (data['preferencia'] ?? 'Ambos').toString(),
          codigoOwner: (data['codigoOwner'] ?? '---').toString(),
          codigoMatchy: (data['codigoMatchy'] ?? '---').toString(),
          fechaSort: parsearFechaYHora(fTexto, hTexto),
          scheduledAt: (data['scheduledAt'] is Timestamp) ? (data['scheduledAt'] as Timestamp).toDate() : null,
          isOwner: soyOwner,
          status: (data['status'] ?? 'matched').toString(),
          reproByUid: (data['repro_by_uid'] ?? '').toString(),
          isPrivate: data['isPrivate'] == true,
        ));
      } catch (e) {
        debugPrint("Error procesando cita: $e");
      }
    }
    return lista;
  }

  void emitir() {
    final map = {for (var e in [...listaOwner, ...listaMatchy]) e.id: e};
    final listaFinal = map.values.toList();
    listaFinal.sort((a, b) => a.fechaSort.compareTo(b.fechaSort));
    if (!controller.isClosed) controller.add(listaFinal);
  }

  final subOwner = FirebaseFirestore.instance
      .collection(kCitasCollection)
      .where('ownerUid', isEqualTo: user.uid)
      .where('status', whereIn: ['matched', 'reprogramming', 'pending_approval'])
      .snapshots()
      .listen((snap) {
    listaOwner = procesarSnapshot(snap, true);
    emitir();
  });

  final subMatchy = FirebaseFirestore.instance
      .collection(kCitasCollection)
      .where('matchyUid', isEqualTo: user.uid)
      .where('status', whereIn: ['matched', 'reprogramming', 'pending_approval'])
      .snapshots()
      .listen((snap) {
    listaMatchy = procesarSnapshot(snap, false);
    emitir();
  });

  ref.onDispose(() {
    subOwner.cancel();
    subMatchy.cancel();
    controller.close();
  });

  return controller.stream;
});

// 🔵 SECCIÓN 4: PANTALLA PRINCIPAL
class CitasScreen extends ConsumerWidget {
  final bool showBottomNav;
  const CitasScreen({super.key, this.showBottomNav = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Stack(
        children: [
          MatchyPageLayout(
            backgroundAsset: 'assets/images/fondo.jpg',
            logoAsset: 'assets/images/logomatchyplano.png',
            scrollContent: SizedBox(
              height: MediaQuery.of(context).size.height - 100,
              child: const _CitasSplitLayout(),
            ),
            topSpacing: 35,
            logoHeight: 45,
            spaceLogoToScroll: 10,
          ),
          Positioned(
            bottom: 0, left: 0, right: 0, height: 90,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.95)],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CitasSplitLayout extends ConsumerWidget {
  const _CitasSplitLayout();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCitas = ref.watch(misCitasStreamProvider);

    return asyncCitas.when(
      loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
      error: (_, __) => const Center(child: Text("Error cargando citas", style: TextStyle(color: Colors.white))),
      data: (todasLasCitas) {
        final proximas = todasLasCitas.where((c) => c.status == 'matched').toList();
        final pendientes = todasLasCitas.where((c) =>
        c.status == 'reprogramming' || c.status == 'pending_approval'
        ).toList();

        return Column(
          children: [
            Expanded(flex: 6, child: _SeccionCitas(titulo: "PRÓXIMAS CITAS", citas: proximas, colorFondo: const Color(0x40FFFFFF), esPendiente: false)),
            const SizedBox(height: 15),
            Expanded(flex: 4, child: _SeccionCitas(titulo: "CITAS PENDIENTES Y POR ACEPTAR", citas: pendientes, colorFondo: const Color(0x506B4EE6), esPendiente: true)),
            const SizedBox(height: 40),
          ],
        );
      },
    );
  }
}

class _SeccionCitas extends StatelessWidget {
  final String titulo;
  final List<CitaItem> citas;
  final Color colorFondo;
  final bool esPendiente;

  const _SeccionCitas({required this.titulo, required this.citas, required this.colorFondo, required this.esPendiente});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(color: colorFondo, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white10)),
      child: Column(
        children: [
          Text(titulo, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'Poppins', letterSpacing: 0.5, shadows: [Shadow(color: Colors.black, blurRadius: 10, offset: Offset(0, 4))])),
          const SizedBox(height: 12),
          Expanded(
            child: citas.isEmpty
                ? Center(child: Text(esPendiente ? "No hay solicitudes pendientes." : "No tienes citas próximas.", style: const TextStyle(color: Colors.white54, fontFamily: 'Poppins')))
                : ListView.builder(padding: const EdgeInsets.only(bottom: 20), physics: const BouncingScrollPhysics(), itemCount: citas.length, itemBuilder: (ctx, i) => _CitaCard(item: citas[i], esPendiente: esPendiente)),
          ),
        ],
      ),
    );
  }
}

class _CitaCard extends StatelessWidget {
  final CitaItem item;
  final bool esPendiente;
  const _CitaCard({required this.item, required this.esPendiente});

  bool _isNet(String url) => url.startsWith('http');

  void _handleTap(BuildContext context) {
    if (!esPendiente) {
      final codigoParaMostrar = item.isOwner ? item.codigoOwner : item.codigoMatchy;
      final codigoParaValidar = item.isOwner ? item.codigoMatchy : item.codigoOwner;
      Navigator.push(context, MaterialPageRoute(builder: (_) => CitaDetalleScreen(
        citaId: item.id, lugarNombre: item.lugarNombre, lugarDireccion: item.lugarDireccion, lugarFotoPortada: item.fotoLugar, matchyNombre: item.nombreMostrar, matchyFoto: item.fotoMostrar, matchyUid: item.matchyUid, matchyEdad: item.matchyEdad, fecha: item.fechaTexto, hora: item.horaTexto, intencion: item.intencion, preferencia: item.preferencia, miCodigoCita: codigoParaMostrar, codigoDelOtro: codigoParaValidar, citaDateTime: item.scheduledAt, isOwner: item.isOwner,
      )));
      return;
    }
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (item.status == 'pending_approval') {
      if (item.isOwner) {
        _mostrarDialogoEspera(context, "INVITACIÓN ENVIADA", "Esperando que ${item.nombreMostrar} acepte tu invitación.");
      } else {
        Navigator.push(context, MaterialPageRoute(builder: (_) => NuevaCitaSolicitudScreen(citaId: item.id)));
      }
      return;
    }
    if (item.reproByUid == myUid) {
      _mostrarDialogoEspera(context, "ESPERANDO RESPUESTA", "Le enviaste una solicitud a ${item.nombreMostrar}.\nTe avisaremos cuando confirme.");
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
    Color colorBoton = Colors.white;
    bool mostrarOverlay = false;

    if (esPendiente) {
      mostrarOverlay = true;
      if (item.status == 'pending_approval') {
        if (item.isOwner) {
          textoBoton = "ENVIADA"; colorBoton = Colors.white70;
        } else {
          textoBoton = "POR ACEPTAR"; colorBoton = Colors.greenAccent;
        }
      } else {
        if (item.reproByUid == myUid) {
          textoBoton = "ENVIADA"; colorBoton = Colors.white70;
        } else {
          textoBoton = "RESPONDER"; colorBoton = Colors.greenAccent;
        }
      }
    }

    return GestureDetector(
      onTap: () => _handleTap(context),
      child: Container(
        height: 120, margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
          border: (textoBoton == "POR ACEPTAR" || textoBoton == "RESPONDER") ? Border.all(color: Colors.black, width: 1) : null,
        ),
        child: Row(
          children: [
            Expanded(flex: 5, child: Stack(fit: StackFit.expand, children: [
              ClipRRect(borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)), child: item.fotoLugar.isNotEmpty && _isNet(item.fotoLugar) ? Image.network(item.fotoLugar, fit: BoxFit.cover) : Container(color: Colors.grey[900], child: const Icon(Icons.store, color: Colors.white24))),
              Container(decoration: BoxDecoration(borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)), gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.9)], stops: const [0.5, 1.0]))),

              // 🔥 FIX NOMBRE: FittedBox para ajuste automático y 1 sola línea
              Positioned(
                bottom: 10, left: 10, right: 5,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                      item.lugarNombre.toUpperCase(),
                      maxLines: 1,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, fontFamily: 'Poppins')
                  ),
                ),
              ),
            ])),
            Expanded(flex: 4, child: Stack(fit: StackFit.expand, children: [
              ClipRRect(borderRadius: const BorderRadius.only(topRight: Radius.circular(20), bottomRight: Radius.circular(20)), child: item.fotoMostrar.isNotEmpty && _isNet(item.fotoMostrar) ? Image.network(item.fotoMostrar, fit: BoxFit.cover, alignment: Alignment.topCenter) : Container(color: Colors.grey[800], child: const Icon(Icons.person, color: Colors.white24))),

              // 🔥 FIX OVERLAY: Animación de Latido (Pulsing)
              if (mostrarOverlay) Container(
                decoration: BoxDecoration(borderRadius: const BorderRadius.only(topRight: Radius.circular(20), bottomRight: Radius.circular(20)), color: Colors.black.withOpacity(0.6)),
                child: Center(
                    child: _PulsingText(text: textoBoton, color: colorBoton)
                ),
              )
            ])),
          ],
        ),
      ),
    );
  }
}

// 🔥 WIDGET NUEVO: TEXTO QUE LATE PARA LLAMAR LA ATENCIÓN
class _PulsingText extends StatefulWidget {
  final String text;
  final Color color;
  const _PulsingText({required this.text, required this.color});

  @override
  State<_PulsingText> createState() => _PulsingTextState();
}

class _PulsingTextState extends State<_PulsingText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Text(
        widget.text,
        textAlign: TextAlign.center,
        style: TextStyle(
            color: widget.color,
            fontWeight: FontWeight.w900, // Negrilla
            fontSize: 12,
            shadows: [
              Shadow(color: widget.color.withOpacity(0.6), blurRadius: 10, offset: Offset(0, 0)) // Glow
            ]
        ),
      ),
    );
  }
}