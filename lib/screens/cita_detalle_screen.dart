// 📂 lib/screens/cita_detalle_screen.dart
// ✅ DETALLE DE CITA (CORREGIDO ERROR DE TIPOS DART)
// 🔥 FIX: Casting explícito en el resultado de la transacción (Object? -> Map).
// 🔥 LOGIC: El status 'finished' solo se activa cuando AMBOS han confirmado.
// 🔥 UI: Pop-up invita al otro usuario por nombre si falta su código.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proyectos_matchy/widgets/matchy_page_layout.dart';
import 'package:proyectos_matchy/screens/panel_screen.dart';
import 'package:proyectos_matchy/screens/perfil_usuariox_screen.dart';
import 'package:proyectos_matchy/screens/reprogramar_cita_screen.dart';
import 'package:proyectos_matchy/screens/confirmar_cita.dart';
import 'package:proyectos_matchy/screens/lugar_plantilla_sin_boton_screen.dart';
import 'package:proyectos_matchy/models/lugar_data.dart';
import 'package:firebase_auth/firebase_auth.dart';

// =============================================================================
// 🔴🔴 CHINCHES MAESTROS (CONFIGURACIÓN VISUAL) 🔴🔴
// =============================================================================

// 1. TEXTOS LUGAR
const double kLugarTitleSize     = 28.0;
const double kLugarAddressSize   = 20.0;
const double kLugarTextGap       = 2.0;

// 2. TARJETAS
const double kCardLugarHeight    = 180.0;
const double kCardMatchyHeight   = 280.0;
const double kCardBorderRadius   = 25.0;

// 3. CÓDIGO
const double kCodeFontSize       = 24.0;
const double kCapsulaRadius      = 25.0;

// 4. BOTONES PREMIUM
const double kButtonRadius = 18.0;
const List<BoxShadow> kButtonShadow = [BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 4))];
const List<Color> kBtnConfirmGradient   = [Color(0xFF00C853), Color(0xFF007E33)]; // Verde
const List<Color> kBtnReproGradient     = [Color(0xFF4FC3F7), Color(0xFF0288D1)]; // Azul
const List<Color> kBtnCancelGradient    = [Color(0xFFFF4B4B), Color(0xFFB71C1C)]; // Rojo

// =============================================================================

class CitaDetalleScreen extends StatefulWidget {
  final String citaId;
  final String lugarNombre;
  final String lugarDireccion;
  final String lugarFotoPortada;
  final String matchyNombre;
  final String matchyFoto;
  final String matchyUid;
  final int matchyEdad;
  final String fecha;
  final String hora;
  final String intencion;
  final String preferencia;
  final String miCodigoCita;
  final String codigoDelOtro;
  final DateTime? citaDateTime;
  final bool isOwner;

  const CitaDetalleScreen({
    super.key,
    required this.citaId,
    required this.lugarNombre,
    required this.lugarDireccion,
    required this.lugarFotoPortada,
    required this.matchyNombre,
    required this.matchyFoto,
    required this.matchyUid,
    required this.matchyEdad,
    required this.fecha,
    required this.hora,
    required this.intencion,
    required this.preferencia,
    required this.miCodigoCita,
    this.codigoDelOtro = '',
    this.citaDateTime,
    this.isOwner = true,
  });

  @override
  State<CitaDetalleScreen> createState() => _CitaDetalleScreenState();
}

class _CitaDetalleScreenState extends State<CitaDetalleScreen> {
  final TextEditingController _codigoMatchyController = TextEditingController();
  bool _procesandoValidacion = false;

  // 🔥 VARIABLES NUEVAS PARA SINCRONIZACIÓN AUTOMÁTICA
  bool _navegandoExito = false;
  StreamSubscription<DocumentSnapshot>? _citaSubscription;

  @override
  void initState() {
    super.initState();
    // 🔥 LISTENER: Escucha en tiempo real si la cita cambia a 'finished'
    _citaSubscription = FirebaseFirestore.instance
        .collection('citas')
        .doc(widget.citaId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        // Si el status cambia a 'finished' y yo aún estoy aquí, navego automáticamente
        if (data['status'] == 'finished' && !_navegandoExito && mounted) {
          // Si tengo el diálogo abierto, verifico si puedo cerrarlo
          if (Navigator.canPop(context)) {
            // Opcional: Cerrar diálogo si está visible
          }
          _procesarExito();
        }
      }
    });
  }

  @override
  void dispose() {
    _codigoMatchyController.dispose();
    _citaSubscription?.cancel();
    super.dispose();
  }

  bool get _esCancelable {
    if (widget.citaDateTime == null) return true;
    final ahora = DateTime.now();
    final diferencia = widget.citaDateTime!.difference(ahora);
    return diferencia.inHours >= 12;
  }

  // 🔥 HELPER: Navegación centralizada al éxito
  Future<void> _procesarExito() async {
    if (_navegandoExito) return;
    setState(() => _navegandoExito = true);

    // OBTENER MIS DATOS ACTUALES
    final user = FirebaseAuth.instance.currentUser;
    String myName = "Tú";
    String myPhoto = "";

    if (user != null) {
      final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final d = snap.data() ?? {};
      myName = d['nombre'] ?? 'Tú';
      myPhoto = d['profilePhotoUrl'] ?? '';
    }

    if (!mounted) return;

    // IR A PANTALLA DE ÉXITO
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => ConfirmarCitaScreen(
              ownerNombre: myName,
              ownerFoto: myPhoto,
              matchyNombre: widget.matchyNombre,
              matchyFoto: widget.matchyFoto,
            )
        )
    );
  }

  // -------------------------------------------------------------------------
  // 🔥 LÓGICA DE VALIDACIÓN DOBLE + POP-UP (FIXED TYPES)
  // -------------------------------------------------------------------------
  Future<void> _validarYConfirmar() async {
    if (_procesandoValidacion || _navegandoExito) return;

    final codigoIngresado = _codigoMatchyController.text.trim().toUpperCase();
    final codigoCorrecto = widget.codigoDelOtro.trim().toUpperCase();

    if (codigoIngresado.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Por favor ingresa el código de tu Matchy"), backgroundColor: Colors.orange));
      return;
    }

    if (codigoIngresado == codigoCorrecto) {
      setState(() => _procesandoValidacion = true);

      try {
        // TRANSACCIÓN DE VERIFICACIÓN DOBLE
        final result = await FirebaseFirestore.instance.runTransaction((transaction) async {
          DocumentSnapshot snapshot = await transaction.get(FirebaseFirestore.instance.collection('citas').doc(widget.citaId));

          if (!snapshot.exists) throw Exception("Error: Cita no encontrada");
          final data = snapshot.data() as Map<String, dynamic>;

          // Identificar campos según quién soy
          String miCampo = widget.isOwner ? 'ownerConfirmado' : 'matchyConfirmado';
          String otroCampo = widget.isOwner ? 'matchyConfirmado' : 'ownerConfirmado';

          // Obtener nombre del otro para el mensaje
          String nombreOtro = widget.isOwner
              ? (data['matchyNombre'] ?? 'tu matchy')
              : (data['ownerNombre'] ?? 'tu matchy');

          bool elOtroYaConfirmo = data[otroCampo] == true;

          Map<String, dynamic> updates = {
            miCampo: true,
            'updatedAt': FieldValue.serverTimestamp(),
          };

          // 🔥 CONDICIÓN CRUCIAL: SOLO si ambos confirmaron, cerramos la cita
          if (elOtroYaConfirmo) {
            updates['status'] = 'finished';
            updates['citaExitosa'] = true;
            updates['finalizedAt'] = FieldValue.serverTimestamp();
          }

          transaction.update(snapshot.reference, updates);

          // Retornamos el estado para saber qué mostrar en la UI
          return {'finished': elOtroYaConfirmo, 'otherName': nombreOtro};
        });

        // 🔥 FIX AQUÍ: Casting explícito para evitar error "Object?"
        final Map<String, dynamic> resultMap = result as Map<String, dynamic>;
        bool isFinished = resultMap['finished'] as bool;
        String otherName = resultMap['otherName'] as String;

        if (isFinished) {
          // Si fuimos los segundos en confirmar, la cita terminó. Vamos al éxito.
          _procesarExito();
        } else {
          // 🔥 SI SOMOS LOS PRIMEROS: MOSTRAR POP-UP DE ESPERA
          setState(() => _procesandoValidacion = false);
          if (!mounted) return;

          showDialog(
            context: context,
            barrierDismissible: false, // Obliga a esperar o cerrar manual
            builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.white24)),
              title: const Icon(Icons.check_circle_outline, color: Color(0xFF00C853), size: 48),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("¡TU CÓDIGO ES CORRECTO!", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 20),
                  Text(
                    "DILE A ${otherName.toUpperCase()} QUE PONGA SU CÓDIGO PARA COMPLETAR LA CITA.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  const LinearProgressIndicator(color: Color(0xFFBEB3FF), backgroundColor: Colors.white10),
                  const SizedBox(height: 10),
                  const Text("Esperando confirmación del otro...", style: TextStyle(color: Colors.white38, fontSize: 12, fontStyle: FontStyle.italic)),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("ENTENDIDO", style: TextStyle(color: Colors.white))
                )
              ],
            ),
          );
        }

      } catch (e) {
        if (mounted) {
          setState(() => _procesandoValidacion = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
        }
      }
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text("CÓDIGO INCORRECTO", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          content: const Text("El código ingresado no coincide con el de tu cita. Verifícalo e intenta de nuevo.", style: TextStyle(color: Colors.white70)),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("INTENTAR DE NUEVO", style: TextStyle(color: Colors.white)))],
        ),
      );
    }
  }

  void _gestionarCancelacion() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text("¿CANCELAR CITA?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text("¿Estás seguro de que quieres cancelar tu cita?.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("NO", style: TextStyle(color: Colors.white))),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('citas').doc(widget.citaId).update({'status': 'canceled'});
              if (mounted) {
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const PanelScreen()), (route) => false);
              }
            },
            child: const Text("SÍ, CANCELAR", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double lugarFotoY = -0.5;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Contenido
          MatchyPageLayout(
            backgroundAsset: 'assets/images/fondo.jpg',
            logoAsset: 'assets/images/logomatchyplano.png',
            topSpacing: 35,
            logoHeight: 45,
            spaceLogoToScroll: 15,
            scrollContent: SizedBox(
              width: double.infinity,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 120), // 🔥 Espacio para Fade Out
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 🔵 1. TARJETA LUGAR
                      GestureDetector(
                        onTap: () {
                          final lugarTemp = LugarData(
                            id: widget.citaId,
                            nombre: widget.lugarNombre,
                            direccion: widget.lugarDireccion,
                            fotoPortada: widget.lugarFotoPortada,
                            fotos: [widget.lugarFotoPortada],
                            bio: '',
                            sitioWeb: '',
                            sedes: [],
                            orden: 0,
                          );
                          Navigator.push(context, MaterialPageRoute(builder: (_) => LugarPlantillaSinBotonScreen(lugar: lugarTemp)));
                        },
                        child: Container(
                          height: kCardLugarHeight,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(kCardBorderRadius), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 5))]),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(kCardBorderRadius),
                                child: widget.lugarFotoPortada.isNotEmpty
                                    ? Image.network(widget.lugarFotoPortada, fit: BoxFit.cover, alignment: const Alignment(0.0, lugarFotoY))
                                    : Container(color: Colors.white10),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(kCardBorderRadius),
                                  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.95)], stops: const [0.4, 1.0]),
                                ),
                              ),
                              Positioned(
                                bottom: 15, left: 15, right: 15,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    FittedBox(
                                      fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
                                      child: Text(widget.lugarNombre.toUpperCase(), maxLines: 1, style: const TextStyle(color: Colors.white, fontSize: kLugarTitleSize, fontWeight: FontWeight.w900, fontFamily: 'Poppins', height: 1.0, shadows: [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 2))])),
                                    ),
                                    const SizedBox(height: kLugarTextGap),
                                    Text(widget.lugarDireccion, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: kLugarAddressSize, fontWeight: FontWeight.bold, height: 1.0, shadows: [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 2))])),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 🔵 2. TARJETA CANDIDATO (FIX DE FOTO)
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PerfilUsuarioXScreen(uid: widget.matchyUid))),
                        child: Container(
                          height: kCardMatchyHeight,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(kCardBorderRadius), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 8, offset: const Offset(0, 4))]),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(kCardBorderRadius),
                                // 🔥 FIX FOTO HUMANO: alignment.topCenter para priorizar cabezas
                                child: Image.network(
                                    widget.matchyFoto,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    alignment: Alignment.topCenter, // 🔥 Prelación al TOP
                                    errorBuilder: (_,__,___) => Container(color: Colors.grey)
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(kCardBorderRadius),
                                  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.8)], stops: const [0.4, 1.0]),
                                ),
                              ),
                              Positioned(
                                bottom: 12, left: 15, right: 15,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(widget.matchyNombre.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900, shadows: [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 2))])),
                                    const SizedBox(width: 8),
                                    Text("${widget.matchyEdad}", style: const TextStyle(color: Colors.white70, fontSize: 25, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 2))])),
                                    const Spacer(),
                                    const Text("Ver perfil >", style: TextStyle(color: Colors.white70, fontSize: 0))
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 🔵 3. GRILLA DATOS
                      Column(
                        children: [
                          Row(children: [Expanded(child: _buildVividCapsule(Icons.calendar_month, widget.fecha)), const SizedBox(width: 12), Expanded(child: _buildVividCapsule(Icons.access_time_filled, widget.hora))]),
                          const SizedBox(height: 12),
                          Row(children: [Expanded(child: _buildVividCapsule(Icons.star, widget.intencion)), const SizedBox(width: 12), Expanded(child: _buildVividCapsule(Icons.favorite, widget.preferencia))]),
                        ],
                      ),

                      const SizedBox(height: 25),

                      // 🔵 4. CÁPSULA SEGURIDAD
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: const Color(0xFF1A1A1A).withOpacity(0.95), borderRadius: BorderRadius.circular(kCapsulaRadius), border: Border.all(color: Colors.white10)),
                        child: Column(
                          children: [
                            _buildDisplayCode(widget.miCodigoCita),
                            const SizedBox(height: 15),
                            _buildInputCode(),
                            const SizedBox(height: 20),

                            // 🔥 BOTÓN CONFIRMAR
                            _PremiumButton(
                              text: _procesandoValidacion ? "VALIDANDO..." : "CONFIRMA TU CITA",
                              gradient: kBtnConfirmGradient,
                              onTap: _validarYConfirmar,
                            ),

                            const SizedBox(height: 12),
                            const Text("POR TU SEGURIDAD SOLO DALE A TU MATCHY TU CÓDIGO EN EL LUGAR DE LA CITA", textAlign: TextAlign.center, style: TextStyle(color: Colors.orangeAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 🔵 5. BOTONES ACCIÓN
                      _PremiumButton(
                        text: "REPROGRAMAR CITA",
                        gradient: kBtnReproGradient,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReprogramarCitaScreen(citaId: widget.citaId))),
                      ),

                      const SizedBox(height: 15),

                      if (widget.isOwner) ...[
                        Opacity(
                          opacity: _esCancelable ? 1.0 : 0.5,
                          child: _PremiumButton(
                            text: "CANCELAR CITA",
                            gradient: kBtnCancelGradient,
                            onTap: _esCancelable ? _gestionarCancelacion : () {},
                          ),
                        ),
                        if (!_esCancelable)
                          const Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: Text("Faltan menos de 12 horas. Solo puedes reprogramar.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 19)),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 2. 🔥 DEGRADADO INFERIOR (FADE OUT)
          Positioned(
            bottom: 0, left: 0, right: 0, height: 90,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.95)],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // 3. 🔥 BOTÓN ATRÁS
          Positioned(
            top: 50, left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 42, height: 42,
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), shape: BoxShape.circle, border: Border.all(color: Colors.white24, width: 1)),
                child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVividCapsule(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withOpacity(0.1))),
      child: Column(children: [Icon(icon, color: Colors.white, size: 28), const SizedBox(height: 8), Text(text.toUpperCase(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, overflow: TextOverflow.ellipsis))]),
    );
  }

  Widget _buildDisplayCode(String code) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(color: const Color(0xFF6B4EE6), borderRadius: BorderRadius.circular(15)),
      child: Column(children: [const Text("MI CÓDIGO", style: TextStyle(color: Colors.white70, fontSize: 15, letterSpacing: 1.5)), Text(code.isEmpty ? "---" : code, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: kCodeFontSize, letterSpacing: 2.0))]),
    );
  }

  Widget _buildInputCode() {
    return Container(
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white24)),
      child: TextField(
        controller: _codigoMatchyController, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 2.0), textCapitalization: TextCapitalization.characters,
        decoration: const InputDecoration(hintText: "CÓDIGO DE TU MATCHY", hintStyle: TextStyle(color: Colors.white24, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 18)),
      ),
    );
  }
}

// 🔥 WIDGET BOTÓN PREMIUM
class _PremiumButton extends StatelessWidget {
  final String text;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _PremiumButton({required this.text, required this.gradient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 55,
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradient),
          borderRadius: BorderRadius.circular(kButtonRadius),
          boxShadow: kButtonShadow,
          border: Border.all(color: Colors.white24, width: 1),
        ),
        alignment: Alignment.center,
        child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5)),
      ),
    );
  }
}