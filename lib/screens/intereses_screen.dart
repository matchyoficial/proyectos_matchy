// 📂 lib/screens/intereses_screen.dart
// ✅ PANTALLA "MIS INTERESES" (INVITACIONES DE COMUNIDAD ENVIADAS POR MÍ)
// 🎯 Diseño basado en matchys_screen.dart: grid 2 columnas, foto de perfil + overlay de
//    nombre/edad, un botón único debajo.
// 📸 Nombre y edad se leen DIRECTO del documento de la invitación (invitadoNombre/invitadoEdad),
//    sin chequeo "anti-fantasmas" — ya no hace falta porque esos datos viajan con la invitación.
// 🗺️ Botón "LUGARES" abre un modal mediano con los 3 sitios sugeridos (foto horizontal +
//    nombre con degradado, clickeables -> LugarPlantillaSinBotonScreen). Cierra con ❌ o
//    tocando afuera (barrierDismissible).
// ⏳ Chip inferior: cuenta regresiva de 30 días con color interpolado verde -> rojo. Si el
//    invitado ya eligió sitio (status == 'elegido'), se reemplaza por un badge verde fijo.
// 📡 Fuente de datos: invitaciones_citas donde inviterUid == miUid, status == 'pending',
//    createdAt < 30 días, ordenado por createdAt descendente (más nuevas primero).
// 🆕 FIX: agregado filtro status == 'pending' — una vez el invitado elige sitio (status pasa a
//    'elegido'), la tarjeta desaparece de aquí sola (ya vive como "PROGRAMAR" en citas_screen.dart).
//    Requiere su PROPIO índice compuesto nuevo (inviterUid + status + createdAt) — Firebase
//    dará el link la primera vez que se pida.
// 👤 Foto de perfil clickeable -> PerfilUsuarioXScreen (sin modificar esa pantalla).
// 🆕 FIX: agregado botón de regreso (chevron) — mismo patrón que comunidad.dart,
//    intereses_citas_screen.dart e intereses_invitacion_screen.dart. matchys_screen.dart (la
//    plantilla base) no lo tenía porque es una pestaña del bottom nav; esta pantalla se navega
//    con push, así que sí lo necesita.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:proyectos_matchy/widgets/matchy_page_layout.dart';
import 'package:proyectos_matchy/widgets/foto_perfil_usuario.dart';
import 'package:proyectos_matchy/screens/perfil_usuariox_screen.dart';
import 'package:proyectos_matchy/models/lugar_data.dart';
import 'package:proyectos_matchy/screens/lugar_plantilla_sin_boton_screen.dart';

// ============================================================================
// 📦 MODELO
// ============================================================================
class InteresEnviadoData {
  final String id;
  final String invitadoUid;
  final String invitadoNombre;
  final int invitadoEdad;
  final String status;
  final String? sitioElegidoNombre;
  final List<Map<String, dynamic>> sitios;
  final DateTime? createdAt;

  const InteresEnviadoData({
    required this.id,
    required this.invitadoUid,
    required this.invitadoNombre,
    required this.invitadoEdad,
    required this.status,
    required this.sitioElegidoNombre,
    required this.sitios,
    required this.createdAt,
  });

  factory InteresEnviadoData.fromDoc(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final sitiosRaw = (data['sitios'] as List<dynamic>? ?? []);
    final edadRaw = data['invitadoEdad'];
    return InteresEnviadoData(
      id: doc.id,
      invitadoUid: (data['invitadoUid'] ?? '').toString(),
      invitadoNombre: (data['invitadoNombre'] ?? 'Usuario').toString(),
      invitadoEdad: edadRaw is int ? edadRaw : int.tryParse(edadRaw?.toString() ?? '') ?? 0,
      status: (data['status'] ?? 'pending').toString(),
      sitioElegidoNombre: data['sitioElegidoNombre'] as String?,
      sitios: sitiosRaw.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

// ============================================================================
// 📡 PROVIDER
// ============================================================================
final misInteresesEnviadosProvider = StreamProvider.autoDispose<List<InteresEnviadoData>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return const Stream.empty();
  final hace30Dias = Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 30)));
  return FirebaseFirestore.instance
      .collection('invitaciones_citas')
      .where('inviterUid', isEqualTo: user.uid)
      .where('status', isEqualTo: 'pending') // 🆕 NUEVO: desaparece sola al ser respondida
      .where('createdAt', isGreaterThan: hace30Dias)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => InteresEnviadoData.fromDoc(d)).toList());
});

// ============================================================================
// 🖼️ PANTALLA
// ============================================================================
class InteresesScreen extends ConsumerWidget {
  static const String routeName = 'intereses';
  const InteresesScreen({super.key});

  // 🛡️ CHINCHES MAESTROS (mismos valores base que matchys_screen.dart)
  static const double kSpacePhotoToButtons = 8.0;
  static const double kSpaceBetweenButtons = 6.0;
  static const double kButtonHeight = 34.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncIntereses = ref.watch(misInteresesEnviadosProvider);

    return Scaffold(
      body: Stack(
        children: [
          MatchyPageLayout(
            backgroundAsset: 'assets/images/fondo.jpg',
            logoAsset: 'assets/images/logomatchyplano.png',
            topSpacing: 35,
            logoHeight: 45,
            spaceLogoToScroll: 15,
            scrollContent: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: const Text(
                      'MIS INTERESES',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Poppins',
                        letterSpacing: 1.0,
                        shadows: [Shadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4))],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Text(
                      'AQUÍ ESTÁN TUS INVITACIONES ENVIADAS. TIENEN 30 DÍAS PARA RESPONDER — SI EL TIEMPO SE AGOTA, LA INVITACIÓN EXPIRARÁ.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        height: 1.3,
                        shadows: [Shadow(color: Colors.black, blurRadius: 2, offset: Offset(0, 1))],
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  asyncIntereses.when(
                    loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
                    error: (e, __) => Center(child: Text("Error: $e", style: const TextStyle(color: Colors.white))),
                    data: (intereses) {
                      if (intereses.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.only(top: 50),
                          child: Text(
                            "Aún no has enviado ninguna invitación.\n¡Ve a Comunidad y desliza a la derecha!",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white54, fontSize: 16),
                          ),
                        );
                      }

                      return GridView.builder(
                        padding: const EdgeInsets.only(bottom: 120),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 20,
                          childAspectRatio: 0.52,
                        ),
                        itemCount: intereses.length,
                        itemBuilder: (context, index) => _InteresCard(data: intereses[index]),
                      );
                    },
                  ),
                ],
              ),
            ),
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

          // 🆕 BOTÓN DE REGRESO (mismo patrón que comunidad.dart / intereses_citas_screen.dart)
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

// ============================================================================
// 🃏 TARJETA INDIVIDUAL
// ============================================================================
class _InteresCard extends StatelessWidget {
  final InteresEnviadoData data;
  const _InteresCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PerfilUsuarioXScreen(uid: data.invitadoUid))),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 4))],
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: FotoPerfilUsuario(uid: data.invitadoUid, fit: BoxFit.cover, alignment: Alignment.topCenter),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
                        stops: const [0.5, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12, left: 8, right: 8,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            data.invitadoNombre.toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, fontFamily: 'Poppins'),
                          ),
                        ),
                        if (data.invitadoEdad > 0)
                          Text(
                            "${data.invitadoEdad} AÑOS",
                            style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: InteresesScreen.kSpacePhotoToButtons),

        _BotonLugares(data: data),

        const SizedBox(height: InteresesScreen.kSpaceBetweenButtons),

        _EstadoChip(data: data),
      ],
    );
  }
}

// ============================================================================
// 🗺️ BOTÓN "LUGARES" (abre el modal)
// ============================================================================
class _BotonLugares extends StatelessWidget {
  final InteresEnviadoData data;
  const _BotonLugares({required this.data});

  void _mostrarModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 100),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white24, width: 1),
            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, 10))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "SITIOS SUGERIDOS A ${data.invitadoNombre.toUpperCase()}",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, fontFamily: 'Poppins'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: Colors.white12, shape: BoxShape.circle),
                      child: const Icon(Icons.close, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < 3; i++) ...[
                    if (i > 0) const SizedBox(width: 10),
                    Expanded(child: _SitioModalItem(sitio: i < data.sitios.length ? data.sitios[i] : const {})),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _mostrarModal(context),
      child: Container(
        width: double.infinity,
        height: InteresesScreen.kButtonHeight,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFBEB3FF), Color(0xFF8A80CC)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2))],
          border: Border.all(color: Colors.white24, width: 0.5),
        ),
        alignment: Alignment.center,
        child: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map_rounded, color: Colors.black, size: 14),
              SizedBox(width: 4),
              Text("LUGARES", style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 🖼️ ITEM DE SITIO DENTRO DEL MODAL
// ============================================================================
class _SitioModalItem extends StatelessWidget {
  final Map<String, dynamic> sitio;
  const _SitioModalItem({required this.sitio});

  LugarData _toLugar() {
    final foto = (sitio['fotoPortada'] ?? '').toString();
    return LugarData(
      id: (sitio['id'] ?? '').toString(),
      nombre: (sitio['nombre'] ?? '').toString(),
      direccion: (sitio['direccion'] ?? '').toString(),
      bio: '',
      fotos: foto.isNotEmpty ? [foto] : const [],
      fotoPortada: foto,
      sitioWeb: '',
      orden: 9999,
      sedes: const [],
    );
  }

  @override
  Widget build(BuildContext context) {
    final nombre = (sitio['nombre'] ?? '').toString();
    final foto = (sitio['fotoPortada'] ?? '').toString();

    return GestureDetector(
      onTap: nombre.isEmpty ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => LugarPlantillaSinBotonScreen(lugar: _toLugar()))),
      child: AspectRatio(
        aspectRatio: 1.25,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 3))],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _SafeImgInteres(url: foto),
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
                left: 5, right: 5, bottom: 5,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.bottomCenter,
                  child: Text(
                    nombre.isEmpty ? '—' : nombre.toUpperCase(),
                    maxLines: 1,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Poppins',
                        shadows: [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 2))]),
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

class _SafeImgInteres extends StatelessWidget {
  final String url;
  const _SafeImgInteres({required this.url});

  @override
  Widget build(BuildContext context) {
    final v = url.trim();
    if (v.startsWith('http')) {
      return CachedNetworkImage(
        key: ValueKey(v),
        imageUrl: v,
        fit: BoxFit.cover,
        memCacheHeight: 250,
        placeholder: (context, url) => Container(color: Colors.black26, child: const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFBEB3FF))))),
        errorWidget: (_, __, ___) => Container(color: Colors.grey[900], child: const Icon(Icons.broken_image, color: Colors.white24, size: 18)),
      );
    }
    return Container(color: Colors.grey[900], child: const Icon(Icons.image_not_supported, color: Colors.white24, size: 18));
  }
}

// ============================================================================
// ⏳ CHIP DE ESTADO: cuenta regresiva verde->rojo, o badge de "elegido"
// (la rama 'elegido' queda como fallback defensivo — con el nuevo filtro de la query,
// esta pantalla ya nunca debería recibir un documento en ese estado)
// ============================================================================
class _EstadoChip extends StatelessWidget {
  final InteresEnviadoData data;
  const _EstadoChip({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.status == 'elegido') {
      final nombreElegido = (data.sitioElegidoNombre ?? '').toUpperCase();
      return Container(
        width: double.infinity,
        height: InteresesScreen.kButtonHeight,
        decoration: BoxDecoration(color: const Color(0xFF00E676), borderRadius: BorderRadius.circular(18)),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              nombreElegido.isEmpty ? "ELIGIÓ SITIO ✓" : "ELIGIÓ: $nombreElegido",
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 11, fontFamily: 'Poppins'),
            ),
          ),
        ),
      );
    }

    final createdAt = data.createdAt;
    if (createdAt == null) {
      return Container(
        width: double.infinity,
        height: InteresesScreen.kButtonHeight,
        decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(18)),
        alignment: Alignment.center,
        child: const Text("PENDIENTE", style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
      );
    }

    final vence = createdAt.add(const Duration(days: 30));
    final restante = vence.difference(DateTime.now());
    final diasRestantes = restante.inDays;
    final fraccion = (restante.inHours / (30 * 24)).clamp(0.0, 1.0);
    final color = Color.lerp(Colors.redAccent, const Color(0xFF00E676), fraccion) ?? Colors.redAccent;
    final texto = diasRestantes <= 0
        ? "EXPIRADO"
        : "$diasRestantes DÍA${diasRestantes == 1 ? '' : 'S'} RESTANTE${diasRestantes == 1 ? '' : 'S'}";

    return Container(
      width: double.infinity,
      height: InteresesScreen.kButtonHeight,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6)]),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timer_outlined, color: Colors.black, size: 14),
            const SizedBox(width: 4),
            Text(texto, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 11, fontFamily: 'Poppins')),
          ],
        ),
      ),
    );
  }
}