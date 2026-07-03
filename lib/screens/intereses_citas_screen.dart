// 📂 lib/screens/intereses_citas_screen.dart
// ✅ PANTALLA INTERESES-CITAS (ESCOGER 3 SITIOS PARA INVITAR A UN MATCH DE COMUNIDAD)
// 🎯 Estructura calcada de cita_nueva_screen.dart: header de 2 fotos, grid de categorías,
//    banner, zona de descuentos y lugares populares — todo intacto en su diseño.
// 🆕 AGREGADO: texto "Escoge tres posibles sitios...", 3 casillas horizontales con ❌ para
//    deseleccionar, botón "ENVIAR INVITACIÓN" (desactivado hasta llenar las 3 casillas).
// 🔥 MODO SELECCIÓN: tanto el grid de categorías como "Lugares Populares" navegan con
//    modoSeleccionCita:true, esperan (await) el resultado y llenan la primera casilla vacía.
// 📝 SIN CAMPO "nombre de la cita" — confirmado que no existe en el original.
// 🗄️ Al enviar, escribe en Firestore la colección 'invitaciones_citas' (ver esquema abajo).
// 🆕 FIX: se agrega edadInteres (requerido) y se guarda como 'invitadoEdad' en el documento,
//    para que intereses_screen.dart pueda mostrar la edad sin fetches adicionales.
// 🔔 NUEVO: al enviar la invitación, se notifica al invitado en users/{uid}/notifications.
// 🆕 NUEVO: sección "INTENCIÓN" con las 6 opciones (mismo patrón visual que creacita_screen.dart),
//    ubicada después de las 3 casillas y antes del grid de categorías. Valor por defecto
//    'Conocernos' — no bloquea el envío. Se guarda como 'intencion' en el documento.
// 🐛 FIX CRÍTICO: el registro de "perfil_intereses" (que oculta un perfil para siempre en
//    Comunidad) se movió AQUÍ, al momento real de enviar la invitación con éxito — antes vivía
//    en comunidad.dart y se disparaba con el simple swipe derecha, escondiendo perfiles para
//    siempre aunque el usuario nunca completara este formulario (le diera "atrás" a mitad de
//    camino). Además, al terminar con éxito se hace pop(true) en vez de pop() — así
//    comunidad.dart sabe distinguir "se completó" de "se canceló" y decide si avanza el mazo
//    o le devuelve la tarjeta al usuario.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:proyectos_matchy/state/profile_form_provider.dart';
import 'package:proyectos_matchy/models/lugar_data.dart';
import 'package:proyectos_matchy/widgets/lugar_card.dart';
import 'package:proyectos_matchy/widgets/foto_perfil_usuario.dart';
import 'package:proyectos_matchy/widgets/banner_publicidad.dart';

import 'package:proyectos_matchy/screens/restaurantes_screen.dart';
import 'package:proyectos_matchy/screens/bares_screen.dart';
import 'package:proyectos_matchy/screens/cafes_screen.dart';
import 'package:proyectos_matchy/screens/actividades_screen.dart';
import 'package:proyectos_matchy/screens/zona_de_descuentos_screen.dart';
import 'package:proyectos_matchy/screens/lugar_plantilla_screen.dart';

class InteresesCitasScreen extends ConsumerStatefulWidget {
  static const String routeName = 'intereses_citas';
  final String uidInteres;
  final String nombreInteres;
  final int edadInteres;

  const InteresesCitasScreen({
    super.key,
    required this.uidInteres,
    required this.nombreInteres,
    required this.edadInteres,
  });

  @override
  ConsumerState<InteresesCitasScreen> createState() => _InteresesCitasScreenState();
}

class _InteresesCitasScreenState extends ConsumerState<InteresesCitasScreen> {
  LugarData? _slot1;
  LugarData? _slot2;
  LugarData? _slot3;
  bool _enviando = false;

  // Intención de la cita, con default 'Conocernos' (mismo patrón que creacita_screen.dart)
  String _intencion = 'Conocernos';

  bool get _completoLas3 => _slot1 != null && _slot2 != null && _slot3 != null;

  String _nombreSeguro(String raw) {
    final clean = raw.trim();
    if (clean.isEmpty) return 'TU';
    final parts = clean.split(RegExp(r'\s+'));
    return parts.isNotEmpty ? parts.first.toUpperCase() : 'TU';
  }

  // ===========================================================================
  // 🔔 BURBUJA FLOTANTE (mismo patrón usado en todo el proyecto)
  // ===========================================================================
  void _mostrarBurbuja(String mensaje, Color color, IconData icono) {
    if (!mounted) return;
    final overlayState = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => SafeArea(
        child: Align(
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Material(
              color: Colors.transparent,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 500),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E2C).withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.7), width: 2),
                    boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 5))],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
                        child: Icon(icono, color: color, size: 28),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                          child: Text(
                            mensaje,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Poppins'),
                          )
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlayState.insert(entry);
    Future.delayed(const Duration(seconds: 3), () {
      if (entry.mounted) entry.remove();
    });
  }

  // ===========================================================================
  // 🎯 LLENADO DE CASILLAS
  // ===========================================================================
  void _fillFirstEmptySlot(LugarData lugar) {
    if (_completoLas3) {
      _mostrarBurbuja("Ya tienes tus 3 sitios elegidos. Quita uno (❌) para cambiarlo.", Colors.orangeAccent, Icons.info_outline_rounded);
      return;
    }
    final yaExiste = [_slot1, _slot2, _slot3].any((s) => s?.id == lugar.id);
    if (yaExiste) {
      _mostrarBurbuja("Ya elegiste ese sitio, prueba con otro.", Colors.orangeAccent, Icons.info_outline_rounded);
      return;
    }
    setState(() {
      if (_slot1 == null) { _slot1 = lugar; }
      else if (_slot2 == null) { _slot2 = lugar; }
      else if (_slot3 == null) { _slot3 = lugar; }
    });
  }

  Future<void> _abrirCategoria(Widget screen) async {
    final resultado = await Navigator.of(context).push<LugarData>(MaterialPageRoute(builder: (_) => screen));
    if (resultado != null) _fillFirstEmptySlot(resultado);
  }

  // ===========================================================================
  // ✍️ ENVÍO DE LA INVITACIÓN (real, no placeholder) + NOTIFICACIÓN AL INVITADO
  // ===========================================================================
  Future<void> _enviarInvitacion() async {
    if (!_completoLas3 || _enviando) return;
    setState(() => _enviando = true);

    try {
      final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final profile = ref.read(profileFormProvider);
      final inviterNombre = profile.nombre.trim().isNotEmpty ? profile.nombre.trim() : 'Alguien';

      final docRef = await FirebaseFirestore.instance.collection('invitaciones_citas').add({
        'inviterUid': myUid,
        'inviterNombre': inviterNombre,
        'invitadoUid': widget.uidInteres,
        'invitadoNombre': widget.nombreInteres,
        'invitadoEdad': widget.edadInteres,
        'intencion': _intencion,
        'sitios': [_slot1, _slot2, _slot3].map((l) => {
          'id': l!.id,
          'nombre': l.nombre,
          'fotoPortada': l.fotoPortada,
          'direccion': l.direccion,
        }).toList(),
        'sitioElegidoId': null,
        'sitioElegidoNombre': null,
        'status': 'pending',
        'rechazadoPorInvitado': false,
        'createdAt': FieldValue.serverTimestamp(),
        'respondedAt': null,
      });

      // 🐛 FIX: se registra "me interesa" SOLO ahora que la invitación real se envió con éxito.
      // Antes esto se escribía prematuramente en comunidad.dart, al simple swipe derecha —
      // eso escondía el perfil para siempre en el mazo, aunque el usuario nunca terminara
      // de llenar este formulario.
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(myUid)
            .collection('perfil_intereses')
            .doc(widget.uidInteres)
            .set({
          'uid': widget.uidInteres,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}

      // 🔔 notificamos al invitado
      try {
        await FirebaseFirestore.instance.collection('users').doc(widget.uidInteres).collection('notifications').add({
          'type': 'interes_cita',
          'title': '¡NUEVO INTERÉS!',
          'body': '$inviterNombre está interesado en invitarte a una cita. Puedes revisar los lugares a los que te quiere invitar.',
          'invitacionId': docRef.id,
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}

      if (!mounted) return;
      _mostrarBurbuja("¡Invitación enviada! Le avisaremos a ${widget.nombreInteres}.", const Color(0xFF00E676), Icons.send_rounded);
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      // 🐛 FIX: pop(true) en vez de pop() — le confirma a comunidad.dart que SÍ se completó
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        _mostrarBurbuja("Error al enviar: $e", const Color(0xFFFF5252), Icons.error_outline_rounded);
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context, [WidgetRef? _]) {
    final profile = ref.watch(profileFormProvider);
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    final String? fotoProvider = profile.fotosCargadas.isNotEmpty ? profile.fotosCargadas.first : null;
    final String fotoUserFinal = fotoProvider ?? 'assets/images/perfil1.jpg';
    final String nombreUserFinal = _nombreSeguro(profile.nombre);
    final String nombreMatchFinal = _nombreSeguro(widget.nombreInteres);

    final double width = MediaQuery.of(context).size.width;
    final double itemWidthIntencion = (width - 40 - 24) / 3;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover)),

          Column(
            children: [
              const SizedBox(height: 35),
              Image.asset('assets/images/logomatchyplano.png', height: 45),
              const SizedBox(height: 23),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 120),
                  child: Column(
                    children: [
                      _HeaderFotosInteres(
                        fotoUser: fotoUserFinal,
                        nombreUser: nombreUserFinal,
                        userUid: myUid,
                        nombreMatch: nombreMatchFinal,
                        matchUid: widget.uidInteres,
                      ),

                      const SizedBox(height: 20),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              children: [
                                const TextSpan(
                                  text: "¿A DÓNDE QUIERES TU CITA CON\n",
                                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600, fontFamily: 'Poppins', height: 1.2),
                                ),
                                TextSpan(
                                  text: widget.nombreInteres.toUpperCase(),
                                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, fontFamily: 'Poppins', letterSpacing: 1.0, height: 1.2),
                                ),
                                const TextSpan(text: "?", style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 🆕 TEXTO NUEVO
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "ESCOGE TRES POSIBLES SITIOS A DONDE\nTE GUSTARÍA IR CON TU CITA",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'Poppins', height: 1.3),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 🆕 LAS 3 CASILLAS
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            _SlotSitio(lugar: _slot1, onClear: () => setState(() => _slot1 = null)),
                            const SizedBox(width: 10),
                            _SlotSitio(lugar: _slot2, onClear: () => setState(() => _slot2 = null)),
                            const SizedBox(width: 10),
                            _SlotSitio(lugar: _slot3, onClear: () => setState(() => _slot3 = null)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 🆕 SECCIÓN INTENCIÓN (mismo patrón visual que creacita_screen.dart)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "INTENCIÓN",
                            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Poppins'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 10,
                          children: [
                            SizedBox(width: itemWidthIntencion, child: _RadioOpcionInteres(label: 'Solo hablar', groupValue: _intencion, onChanged: (v) => setState(() => _intencion = v))),
                            SizedBox(width: itemWidthIntencion, child: _RadioOpcionInteres(label: 'Conocernos', groupValue: _intencion, onChanged: (v) => setState(() => _intencion = v))),
                            SizedBox(width: itemWidthIntencion, child: _RadioOpcionInteres(label: 'Algo casual', groupValue: _intencion, onChanged: (v) => setState(() => _intencion = v))),
                            SizedBox(width: itemWidthIntencion, child: _RadioOpcionInteres(label: 'Amistad', groupValue: _intencion, onChanged: (v) => setState(() => _intencion = v))),
                            SizedBox(width: itemWidthIntencion, child: _RadioOpcionInteres(label: 'Una relación', groupValue: _intencion, onChanged: (v) => setState(() => _intencion = v))),
                            SizedBox(width: itemWidthIntencion, child: _RadioOpcionInteres(label: 'Algo serio', groupValue: _intencion, onChanged: (v) => setState(() => _intencion = v))),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),

                      // Grid Categorías (idéntico visualmente, modo selección activado)
                      _GridCategoriasSeleccion(
                        onRestaurantes: () => _abrirCategoria(const RestaurantesScreen(modoSeleccionCita: true)),
                        onBares: () => _abrirCategoria(const BaresScreen(modoSeleccionCita: true)),
                        onCafes: () => _abrirCategoria(const CafesScreen(modoSeleccionCita: true)),
                        onActividades: () => _abrirCategoria(const ActividadesScreen(modoSeleccionCita: true)),
                      ),

                      const SizedBox(height: 14),

                      // 🆕 BOTÓN ENVIAR INVITACIÓN
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _BotonEnviarInvitacion(
                          activo: _completoLas3,
                          enviando: _enviando,
                          onTap: _enviarInvitacion,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 🔥 BANNER PUBLICITARIO
                      const BannerPublicidad(),

                      const SizedBox(height: 20),

                      // Botón Descuentos
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: _BotonDescuentosAnimadoInteres(),
                      ),

                      const SizedBox(height: 30),

                      // Lugares Populares — AHORA TAMBIÉN SELECCIONABLE
                      _LugaresPopularesSeleccion(onLugarElegido: _fillFirstEmptySlot),
                    ],
                  ),
                ),
              ),
            ],
          ),

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
}

// ===============================================================
// 🛡️ HEADER FOTOS (copiado exacto de cita_nueva_screen.dart, adaptado sin foto de match propia)
// ===============================================================
class _HeaderFotosInteres extends StatelessWidget {
  final String fotoUser, nombreUser;
  final String nombreMatch;
  final String? userUid, matchUid;

  const _HeaderFotosInteres({
    required this.fotoUser, required this.nombreUser, this.userUid,
    required this.nombreMatch, this.matchUid,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildCapsula(fotoUser, nombreUser, uid: userUid),
        const SizedBox(width: 20),
        _buildCapsula(fotoUser, nombreMatch, uid: matchUid),
      ],
    );
  }

  Widget _buildCapsula(String pathFallback, String nombre, {String? uid}) {
    return Container(
      width: 110, height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 5))],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: uid != null
                  ? FotoPerfilUsuario(uid: uid, fit: BoxFit.cover, alignment: Alignment.topCenter)
                  : Image.asset(pathFallback, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.black26))
          ),
          Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.9)], stops: const [0.6, 1.0]))),
          Positioned(
              bottom: 12, left: 8, right: 8,
              child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(nombre, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800, fontFamily: 'Poppins'))
              )
          ),
        ],
      ),
    );
  }
}

// ===============================================================
// 🆕 CASILLA INDIVIDUAL (vacía o con sitio elegido)
// ===============================================================
class _SlotSitio extends StatelessWidget {
  final LugarData? lugar;
  final VoidCallback onClear;
  const _SlotSitio({required this.lugar, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AspectRatio(
        aspectRatio: 1.35, // un poco más horizontal que cuadrado
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: const Color(0x1FFFFFFF),
            border: Border.all(color: Colors.white12),
          ),
          clipBehavior: Clip.antiAlias,
          child: lugar == null
              ? const Center(
            child: Text(
              'VACÍO',
              style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w800, fontFamily: 'Poppins', letterSpacing: 0.5),
            ),
          )
              : Stack(
            fit: StackFit.expand,
            children: [
              _SafeSlotImage(url: lugar!.fotoPortada),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),
              Positioned(
                left: 6, right: 6, bottom: 6,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.bottomCenter,
                  child: Text(
                    lugar!.nombre.toUpperCase(),
                    maxLines: 1,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Poppins',
                        shadows: [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 2))]),
                  ),
                ),
              ),
              Positioned(
                top: 4, right: 4,
                child: GestureDetector(
                  onTap: onClear,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), shape: BoxShape.circle),
                    child: const Icon(Icons.close, color: Colors.white, size: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SafeSlotImage extends StatelessWidget {
  final String url;
  const _SafeSlotImage({required this.url});

  @override
  Widget build(BuildContext context) {
    final v = url.trim();
    if (v.startsWith('http')) {
      return CachedNetworkImage(
        key: ValueKey(v),
        imageUrl: v,
        fit: BoxFit.cover,
        memCacheHeight: 300,
        placeholder: (context, url) => Container(color: Colors.black26, child: const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFBEB3FF))))),
        errorWidget: (_, __, ___) => Container(color: Colors.grey[900], child: const Icon(Icons.broken_image, color: Colors.white24, size: 18)),
      );
    }
    if (v.startsWith('assets/')) {
      return Image.asset(v, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey[900]));
    }
    return Container(color: Colors.grey[900], child: const Icon(Icons.image_not_supported, color: Colors.white24, size: 18));
  }
}

// ===============================================================
// 🆕 RADIO DE INTENCIÓN (copia fiel de _RadioOpcion en creacita_screen.dart —
//    esa clase es privada de aquel archivo, no se puede reutilizar directamente)
// ===============================================================
class _RadioOpcionInteres extends StatelessWidget {
  final String label;
  final String groupValue;
  final double fontSize;
  final ValueChanged<String> onChanged;
  const _RadioOpcionInteres({required this.label, required this.groupValue, required this.onChanged, this.fontSize = 13});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Radio<String>(
        value: label,
        groupValue: groupValue,
        onChanged: (v) => onChanged(v!),
        activeColor: Colors.white,
        fillColor: WidgetStateProperty.all(Colors.white),
        visualDensity: VisualDensity.compact,
      ),
      Flexible(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label, softWrap: false, style: TextStyle(color: Colors.white, fontSize: fontSize, fontFamily: 'Poppins')),
        ),
      ),
    ]);
  }
}

// ===============================================================
// 🛡️ GRID CATEGORÍAS (visual idéntico a cita_nueva_screen.dart, wiring de selección nuevo)
// ===============================================================
class _GridCategoriasSeleccion extends StatelessWidget {
  final VoidCallback onRestaurantes;
  final VoidCallback onBares;
  final VoidCallback onCafes;
  final VoidCallback onActividades;

  const _GridCategoriasSeleccion({
    required this.onRestaurantes,
    required this.onBares,
    required this.onCafes,
    required this.onActividades,
  });

  @override
  Widget build(BuildContext context) {
    const double radioCategoria = 18;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(child: _CatCard("RESTAURANTES", "assets/images/restaurantes_ico.jpg", radioCategoria, onRestaurantes)),
          const SizedBox(width: 8),
          Expanded(child: _CatCard("BARES", "assets/images/bares_ico.jpg", radioCategoria, onBares)),
          const SizedBox(width: 8),
          Expanded(child: _CatCard("CAFÉS", "assets/images/cafes_ico.jpg", radioCategoria, onCafes)),
          const SizedBox(width: 8),
          Expanded(child: _CatCard("ACTIVIDADES", "assets/images/actividades_ico.jpg", radioCategoria, onActividades)),
        ],
      ),
    );
  }

  Widget _CatCard(String title, String asset, double radio, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(radio),
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 4))],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                asset,
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(7.5, 0, 7, 8),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.bottomCenter,
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Poppins',
                      letterSpacing: 0.5,
                      shadows: [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 2))],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===============================================================
// 🆕 BOTÓN "ENVIAR INVITACIÓN"
// ===============================================================
class _BotonEnviarInvitacion extends StatelessWidget {
  final bool activo;
  final bool enviando;
  final VoidCallback onTap;

  const _BotonEnviarInvitacion({required this.activo, required this.enviando, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final puedeTocar = activo && !enviando;
    return GestureDetector(
      onTap: puedeTocar ? onTap : null,
      child: Container(
        width: double.infinity,
        height: 55,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: activo ? const [Color(0xFF7E208E), Color(0xFC4B3F60)] : const [Color(0xFF424242), Color(0xFF212121)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 2, offset: Offset(0, 4))],
        ),
        alignment: Alignment.center,
        child: enviando
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
            : FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(activo ? Icons.send_rounded : Icons.lock_outline, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              const Text("ENVIAR INVITACIÓN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, fontFamily: 'Poppins', letterSpacing: 1.0)),
            ],
          ),
        ),
      ),
    );
  }
}

// ===============================================================
// 🛡️ BOTÓN DESCUENTOS BLINDADO (copia exacta de cita_nueva_screen.dart)
// ===============================================================
class _BotonDescuentosAnimadoInteres extends StatefulWidget {
  const _BotonDescuentosAnimadoInteres();
  @override
  State<_BotonDescuentosAnimadoInteres> createState() => _BotonDescuentosAnimadoInteresState();
}

class _BotonDescuentosAnimadoInteresState extends State<_BotonDescuentosAnimadoInteres> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800), lowerBound: 0.96, upperBound: 1.04)..repeat(reverse: true);
    _scaleAnimation = _controller;
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: double.infinity, height: 55,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFF8C00)], begin: Alignment.topLeft, end: Alignment.bottomRight), boxShadow: [BoxShadow(color: const Color(0xFFFFC107).withOpacity(0.6), blurRadius: 15, spreadRadius: 2)]),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ZonaDeDescuentosScreen())),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.stars_rounded, color: Colors.black, size: 28),
                      SizedBox(width: 10),
                      Text("ZONA DE DESCUENTOS", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 18, fontFamily: 'Poppins')),
                      SizedBox(width: 10),
                      Icon(Icons.stars_rounded, color: Colors.black, size: 28)
                    ]
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ===============================================================
// 🛡️ LUGARES POPULARES — AHORA SELECCIONABLE (basado en cita_nueva_screen.dart)
// ===============================================================
class _LugaresPopularesSeleccion extends StatefulWidget {
  final void Function(LugarData) onLugarElegido;
  const _LugaresPopularesSeleccion({required this.onLugarElegido});

  @override
  State<_LugaresPopularesSeleccion> createState() => _LugaresPopularesSeleccionState();
}

class _LugaresPopularesSeleccionState extends State<_LugaresPopularesSeleccion> {
  String _userCiudad = 'Cali';
  String _userPais = 'Colombia';
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _fetchUserLocation();
  }

  Future<void> _fetchUserLocation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (snap.exists && snap.data() != null) {
          if (mounted) {
            setState(() {
              _userCiudad = (snap.data()!['ciudad'] ?? 'Cali').toString();
              _userPais = (snap.data()!['pais'] ?? 'Colombia').toString();
              _isLoadingLocation = false;
            });
          }
          return;
        }
      } catch (_) {}
    }
    if (mounted) {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _onLugarTap(LugarData lugar) async {
    final resultado = await Navigator.of(context).push<LugarData>(
      MaterialPageRoute(
        builder: (_) => LugarPlantillaScreen(lugar: lugar, modoSeleccionCita: true),
      ),
    );
    if (resultado != null) widget.onLugarElegido(resultado);
  }

  @override
  Widget build(BuildContext context) {
    const double alturaLugarPopular = 150;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: const Text(
                "LUGARES MÁS POPULARES",
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Poppins')
            ),
          ),
        ),
        const SizedBox(height: 14),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _isLoadingLocation
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFBEB3FF)))
              : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('lugares')
                .where('pais', isEqualTo: _userPais)
                .where('ciudad', isEqualTo: _userCiudad)
                .where('popular', isGreaterThan: 0)
                .orderBy('popular', descending: false)
                .snapshots(),
            builder: (context, snap) {
              if (snap.hasError) return const Text("Error cargando populares", style: TextStyle(color: Colors.white54));
              if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: Colors.white));

              final docs = snap.data!.docs;
              if (docs.isEmpty) return const Text("No hay lugares populares activos en tu ciudad.", style: TextStyle(color: Colors.white54, fontFamily: 'Poppins'));

              return Column(
                children: List.generate(docs.length, (index) {
                  final lugar = LugarData.fromMap(id: docs[index].id, data: docs[index].data());
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: LugarCard(
                      lugar: lugar,
                      altoTarjeta: alturaLugarPopular,
                      onTap: () => _onLugarTap(lugar),
                    ),
                  );
                }),
              );
            },
          ),
        ),
      ],
    );
  }
}