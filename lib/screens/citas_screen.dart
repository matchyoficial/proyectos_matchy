// 📂 lib/screens/citas_screen.dart
// ✅ PANTALLA CITAS BLINDADA (JERARQUÍA VISUAL CORREGIDA: AZUL > ROJO)
// 🔥 FIX: Si hay propuesta de acuerdo, la tarjeta es AZUL aunque la hora haya pasado.
// 🔥 Mantiene: Arquitectura Split & Merge + Reloj Automático.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proyectos_matchy/widgets/matchy_page_layout.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ✅ IMPORTS
import 'package:proyectos_matchy/screens/cita_detalle_screen.dart';
import 'package:proyectos_matchy/screens/reprogramar_cita_aceptar_screen.dart';
import 'package:proyectos_matchy/screens/nueva_cita_solicitud_screen.dart';
import 'package:proyectos_matchy/widgets/foto_perfil_usuario.dart';
import 'package:proyectos_matchy/screens/reporte_inasistencia_screen.dart';

// 🔵 SECCIÓN 1: MODELO
const String kCitasCollection = 'citas';

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
  });
}

// ⏱️ RELOJ "MARCAPASOS": Emite una señal cada 30 segundos
final relojProvider = StreamProvider.autoDispose<int>((ref) {
  return Stream.periodic(const Duration(seconds: 30), (i) => i);
});

// 🛠️ HELPER: PARSEO Y CONVERSIÓN
CitaItem? _convertirDoc(DocumentSnapshot doc, bool soyOwner, DateTime ahora) {
  try {
    final data = doc.data() as Map<String, dynamic>;

    bool yoFinalice = soyOwner
        ? (data['ownerFinalized'] == true)
        : (data['matchyFinalized'] == true);
    if (yoFinalice) return null;

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

    DateTime fechaReal = DateTime(2099, 1, 1);
    try {
      final parts = fTexto.trim().split(RegExp(r'[/ -]'));
      if (parts.length >= 3) {
        int d = int.parse(parts[0]), m = int.parse(parts[1]), y = int.parse(parts[2]);
        String rawHora = hTexto.toUpperCase().replaceAll('.', '').trim();
        bool esPM = rawHora.contains("PM");
        String soloNumeros = rawHora.replaceAll(RegExp(r'[^0-9:]'), '');
        final timeParts = soloNumeros.split(':');
        int hora = int.parse(timeParts[0]), min = int.parse(timeParts[1]);
        if (esPM && hora != 12) hora += 12;
        if (!esPM && hora == 12) hora = 0;
        fechaReal = DateTime(y, m, d, hora, min);
      }
    } catch (_) {}

    // CÁLCULO DE URGENCIA
    final diferencia = ahora.difference(fechaReal);
    bool urgente = false;
    if (data['status'] == 'matched') {
      if (diferencia.inMinutes > 0) urgente = true;
    }

    // DETECCIÓN DE PACTO
    bool yoPropuse = soyOwner
        ? (data['ownerPropusoAcuerdo'] == true)
        : (data['matchyPropusoAcuerdo'] == true);

    bool elOtroPropuso = soyOwner
        ? (data['matchyPropusoAcuerdo'] == true)
        : (data['ownerPropusoAcuerdo'] == true);

    return CitaItem(
      id: doc.id,
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
      intencion: (data['intencion'] ?? 'Conocernos').toString(),
      preferencia: (data['preferencia'] ?? 'Ambos').toString(),
      codigoOwner: (data['codigoOwner'] ?? '---').toString(),
      codigoMatchy: (data['codigoMatchy'] ?? '---').toString(),
      isOwner: soyOwner,
      status: (data['status'] ?? 'matched').toString(),
      reproByUid: (data['repro_by_uid'] ?? '').toString(),
      esUrgente: urgente,
      tengoPropuestaAcuerdo: yoPropuse,
      tengoSolicitudAcuerdo: elOtroPropuso,
    );
  } catch (e) {
    return null;
  }
}

// 🔵 SECCIÓN 2: PROVIDERS

final citasRawOwnerProvider = StreamProvider.autoDispose<List<DocumentSnapshot>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return const Stream.empty();
  return FirebaseFirestore.instance
      .collection(kCitasCollection)
      .where('ownerUid', isEqualTo: user.uid)
      .where('status', whereIn: ['matched', 'reprogramming', 'pending_approval'])
      .snapshots()
      .map((s) => s.docs);
});

final citasRawMatchyProvider = StreamProvider.autoDispose<List<DocumentSnapshot>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return const Stream.empty();
  return FirebaseFirestore.instance
      .collection(kCitasCollection)
      .where('matchyUid', isEqualTo: user.uid)
      .where('status', whereIn: ['matched', 'reprogramming', 'pending_approval'])
      .snapshots()
      .map((s) => s.docs);
});

// 🚀 MEZCLADOR INTELIGENTE
final misCitasMezcladasProvider = Provider.autoDispose<AsyncValue<List<CitaItem>>>((ref) {
  final ownerRaw = ref.watch(citasRawOwnerProvider);
  final matchyRaw = ref.watch(citasRawMatchyProvider);

  // ESCUCHAMOS EL RELOJ
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

  // Ordenar
  listaFinal.sort((a, b) {
    if (a.esUrgente && !b.esUrgente) return -1;
    if (!a.esUrgente && b.esUrgente) return 1;
    return a.fechaSort.compareTo(b.fechaSort);
  });

  return AsyncValue.data(listaFinal);
});

// 🔵 SECCIÓN 3: PANTALLA
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
    final asyncCitas = ref.watch(misCitasMezcladasProvider);

    return asyncCitas.when(
      loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
      error: (_, __) => const Center(child: Text("Error cargando citas", style: TextStyle(color: Colors.white))),
      data: (todasLasCitas) {

        final proximas = todasLasCitas.where((c) {
          if (c.esUrgente) return false;
          if (c.tengoPropuestaAcuerdo || c.tengoSolicitudAcuerdo) return false;
          return c.status == 'matched';
        }).toList();

        final pendientes = todasLasCitas.where((c) {
          if (c.esUrgente) return true;
          if (c.tengoPropuestaAcuerdo || c.tengoSolicitudAcuerdo) return true;
          return c.status == 'reprogramming' || c.status == 'pending_approval';
        }).toList();

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
          FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(titulo, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, fontFamily: 'Poppins', letterSpacing: 0.5, shadows: [Shadow(color: Colors.black, blurRadius: 10, offset: Offset(0, 4))]))
          ),
          const SizedBox(height: 12),
          Expanded(
            child: citas.isEmpty
                ? Center(
                child: Text(
                    esPendiente ? "No hay solicitudes pendientes." : "No tienes citas próximas.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white54, fontFamily: 'Poppins', fontSize: 14)
                )
            )
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

  String _fechaAmigable(DateTime d) {
    const List<String> dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    const List<String> meses = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
    return "${dias[d.weekday - 1]} ${d.day} de ${meses[d.month - 1]}";
  }

  void _handleTap(BuildContext context) {
    if (item.esUrgente || item.tengoPropuestaAcuerdo || item.tengoSolicitudAcuerdo) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ReporteInasistenciaScreen(citaId: item.id)));
      return;
    }
    if (!esPendiente) {
      final codigoParaMostrar = item.isOwner ? item.codigoOwner : item.codigoMatchy;
      final codigoParaValidar = item.isOwner ? item.codigoMatchy : item.codigoOwner;
      Navigator.push(context, MaterialPageRoute(builder: (_) => CitaDetalleScreen(
        citaId: item.id, lugarNombre: item.lugarNombre, lugarDireccion: item.lugarDireccion, lugarFotoPortada: item.fotoLugar, matchyNombre: item.nombreMostrar, matchyFoto: item.fotoMostrar, matchyUid: item.matchyUid, matchyEdad: item.matchyEdad, fecha: item.fechaTextoOriginal, hora: item.horaTexto, intencion: item.intencion, preferencia: item.preferencia, miCodigoCita: codigoParaMostrar, codigoDelOtro: codigoParaValidar, isOwner: item.isOwner,
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

    // DETECCIÓN DE ACUERDO
    bool esAcuerdo = item.tengoPropuestaAcuerdo || item.tengoSolicitudAcuerdo;
    const double cardHeight = 125.0;

    // Colores base (Normal)
    Color bgColor = const Color(0xFF1A1A1A);
    Color borderColor = Colors.transparent;
    ColorFilter? imgFilter;

    // 🔥 JERARQUÍA INVERTIDA: PRIMERO VALIDAMOS EL ACUERDO (AZUL)
    if (esAcuerdo) {
      // 🔵 MODO AZUL (PRIORIDAD ALTA)
      bgColor = const Color(0xFF0D47A1).withOpacity(0.3);
      borderColor = const Color(0xFF448AFF);
      imgFilter = ColorFilter.mode(const Color(0xFF448AFF).withOpacity(0.5), BlendMode.srcATop);
    } else if (item.esUrgente) {
      // 🔴 MODO ROJO (Solo si no hay acuerdo)
      bgColor = const Color(0xFFB71C1C).withOpacity(0.3);
      borderColor = const Color(0xFFFF5252);
      imgFilter = ColorFilter.mode(const Color(0xFFFF5252).withOpacity(0.6), BlendMode.srcATop);
    }

    if (esPendiente) {
      if (esAcuerdo) {
        // PRIORIDAD 1: Mostrar etiqueta de Acuerdo
        mostrarOverlay = true;
        if (item.tengoPropuestaAcuerdo) {
          textoBoton = "ESPERANDO ACUERDO"; colorBoton = Colors.white;
        } else {
          textoBoton = "PROPUESTA DE ACUERDO"; colorBoton = Colors.white;
        }
      } else if (item.esUrgente) {
        // PRIORIDAD 2: Urgente (No lleva pulsing text porque tiene la etiqueta roja fija)
      } else {
        // PRIORIDAD 3: Reprogramación Normal
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
    }

    return GestureDetector(
      onTap: () => _handleTap(context),
      child: Container(
        height: cardHeight,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
          border: (item.esUrgente || esAcuerdo)
              ? Border.all(color: borderColor, width: 2)
              : (textoBoton == "POR ACEPTAR" || textoBoton == "RESPONDER") ? Border.all(color: Colors.black, width: 1) : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)),
                      child: item.fotoLugar.isNotEmpty && _isNet(item.fotoLugar)
                          ? ColorFiltered(
                          colorFilter: imgFilter ?? const ColorFilter.mode(Colors.transparent, BlendMode.dst),
                          child: Image.network(item.fotoLugar, fit: BoxFit.cover)
                      )
                          : Container(color: Colors.grey[900], child: const Icon(Icons.store, color: Colors.white24))
                  ),
                  Container(decoration: BoxDecoration(borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)), gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.9)], stops: const [0.5, 1.0]))),

                  Positioned(
                    bottom: 10, left: 10, right: 5,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                              item.lugarNombre.toUpperCase(),
                              maxLines: 1,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, fontFamily: 'Poppins')
                          ),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _fechaAmigable(item.fechaSort),
                            style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: cardHeight,
              height: cardHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(topRight: Radius.circular(20), bottomRight: Radius.circular(20)),
                    child: ColorFiltered(
                      colorFilter: imgFilter ?? const ColorFilter.mode(Colors.transparent, BlendMode.dst),
                      child: FotoPerfilUsuario(
                        uid: item.matchyUid,
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                      ),
                    ),
                  ),

                  // 🔥 LOGICA DE ETIQUETAS: AZUL MATA ROJO

                  // ETIQUETA AZUL (ACUERDO)
                  if (esAcuerdo)
                    Container(
                      decoration: BoxDecoration(borderRadius: const BorderRadius.only(topRight: Radius.circular(20), bottomRight: Radius.circular(20)), color: const Color(0xFF1565C0).withOpacity(0.3)),
                      child: Center(
                        child: Transform.rotate(
                          angle: -0.2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                border: Border.all(color: Colors.white, width: 2),
                                borderRadius: BorderRadius.circular(8),
                                color: const Color(0xFF1565C0).withOpacity(0.9)
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                item.tengoPropuestaAcuerdo ? "ESPERANDO..." : "PROPUESTA",
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.0),
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  // ETIQUETA ROJA (SIN CONFIRMAR) - Solo si NO es acuerdo
                  else if (item.esUrgente)
                    Container(
                      decoration: BoxDecoration(borderRadius: const BorderRadius.only(topRight: Radius.circular(20), bottomRight: Radius.circular(20)), color: Colors.red.withOpacity(0.3)),
                      child: Center(
                        child: Transform.rotate(
                          angle: -0.2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                border: Border.all(color: Colors.white, width: 2),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.red.withOpacity(0.8)
                            ),
                            child: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                "SIN CONFIRMAR",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.0),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // OVERLAY CON TEXTO PULSANTE (Solo si no es urgente "puro")
                  if (mostrarOverlay && !(item.esUrgente && !esAcuerdo)) Container(
                    decoration: BoxDecoration(borderRadius: const BorderRadius.only(topRight: Radius.circular(20), bottomRight: Radius.circular(20)), color: Colors.black.withOpacity(0.6)),
                    child: Center(
                        child: _PulsingText(text: textoBoton, color: colorBoton)
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            widget.text,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: widget.color,
                fontWeight: FontWeight.w900,
                fontSize: 12,
                shadows: [
                  Shadow(color: widget.color.withOpacity(0.6), blurRadius: 10, offset: Offset(0, 0))
                ]
            ),
          ),
        ),
      ),
    );
  }
}