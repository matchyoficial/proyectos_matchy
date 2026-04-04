// 📂 lib/screens/citas_pendientes_screen.dart
// ✅ CITAS PUBLICADAS BLINDADA (SMART CACHE PRO + NUBE INFORMATIVA)
// 🔥 FIX: Tractor Matemático Agresivo para citas viejas sin scheduledAt.
// 🔥 FIX: Ordenamiento cronológico perfecto y renderizado forzado (state = [...list]).
// 🔥 ADD: Nube informativa debajo del título para explicar la función de la pantalla.
// 🔥 CACHÉ PRO: Renderizado inteligente en ListView para scroll fluido.
// 🔥 BLINDAJE: Textos protegidos con FittedBox manteniendo tamaños originales.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart'; // 🔥 Motor de caché
import 'package:proyectos_matchy/screens/citas_pendientes_detalle.dart';

// ================================================================
// CONSTANTES FIRESTORE
// ================================================================
const String kCitasCollection = 'citas';
const String kOwnerUidField = 'ownerUid';
const String kStatusField = 'status';
const String kStatusOnline = 'online';
const String kStatusCancelled = 'cancelled';

const String kCancelReasonField = 'cancelReason';
const String kCancelReasonTime = 'Cancelled for time limit';

const String kFechaField = 'fecha';
const String kHoraField = 'hora';
const String kUpdatedAtField = 'updatedAt';

const String kLugarMap = "lugar";
const String kLugarNombre = "nombre";
const String kLugarFotoPortada = "fotoPortada";

const String kLugarNombreOld = "lugarNombre";
const String kLugarFotoPortadaOld = "lugarFotoPortada";
const String kLugarFotosOld = "lugarFotos";

// ================================================================
// MODELO
// ================================================================
class CitaPendiente {
  final String id;
  final String nombreLugar;
  final String fecha;
  final String hora;
  final String fotoLugar;
  final DateTime fechaHoraCita;

  const CitaPendiente({
    required this.id,
    required this.nombreLugar,
    required this.fecha,
    required this.hora,
    required this.fotoLugar,
    required this.fechaHoraCita,
  });
}

// ================================================================
// NOTIFIER
// ================================================================
class CitasPendientesNotifier extends StateNotifier<List<CitaPendiente>> {
  StreamSubscription? _subAuth;
  StreamSubscription? _sub;

  CitasPendientesNotifier() : super(const []) {
    _subAuth = FirebaseAuth.instance.authStateChanges().listen((_) => _bind());
    _bind();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _subAuth?.cancel();
    super.dispose();
  }

  void _bind() async {
    await _sub?.cancel();
    _sub = null;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      state = const [];
      return;
    }

    final q = FirebaseFirestore.instance
        .collection(kCitasCollection)
        .where(kOwnerUidField, isEqualTo: user.uid)
        .where(kStatusField, isEqualTo: kStatusOnline);

    _sub = q.snapshots().listen((snap) async {
      final List<CitaPendiente> list = [];
      final now = DateTime.now();

      for (final d in snap.docs) {
        final data = d.data();

        Map<String, dynamic> lugarNew = {};
        if (data[kLugarMap] is Map) {
          lugarNew = Map<String, dynamic>.from(data[kLugarMap]);
        }

        String nombreLugar = lugarNew[kLugarNombre]?.toString() ?? '';
        if (nombreLugar.isEmpty) {
          nombreLugar = data[kLugarNombreOld]?.toString() ?? 'Lugar sin nombre';
        }

        String fotoLugar = lugarNew[kLugarFotoPortada]?.toString() ?? '';
        if (fotoLugar.isEmpty) {
          fotoLugar = data[kLugarFotoPortadaOld]?.toString() ?? '';
        }
        if (fotoLugar.isEmpty) {
          final fotosOld = data[kLugarFotosOld];
          if (fotosOld is List && fotosOld.isNotEmpty) {
            fotoLugar = fotosOld.first.toString();
          }
        }
        if (fotoLugar.isEmpty) {
          fotoLugar = 'assets/images/perfil1.jpg';
        }

        final fecha = (data[kFechaField] ?? '').toString();
        final hora = (data[kHoraField] ?? '').toString();

        DateTime fechaHoraCita;

        // 🔥 TRACTOR MATEMÁTICO AGRESIVO
        if (data['scheduledAt'] != null) {
          fechaHoraCita = (data['scheduledAt'] as Timestamp).toDate();
        } else {
          // Salvavidas matemático forzado para citas viejas/sucias
          fechaHoraCita = DateTime(2100); // Valor por defecto si todo falla
          try {
            // 1. Limpiar fecha quitando todos los espacios
            final cleanFecha = fecha.replaceAll(' ', '').trim();
            final f = cleanFecha.split(RegExp(r'[/ -]'));

            // 2. Extraer AM/PM antes de limpiar los números
            String upperHora = hora.toUpperCase();
            bool isPM = upperHora.contains('PM');
            bool isAM = upperHora.contains('AM');

            // 3. Destruir cualquier letra o símbolo que no sea número o dos puntos
            String cleanHora = hora.replaceAll(RegExp(r'[^0-9:]'), '').trim();
            final h = cleanHora.split(':');

            if (f.length >= 3 && h.isNotEmpty) {
              int day = int.parse(f[0]);
              int month = int.parse(f[1]);
              int year = int.parse(f[2]);
              if (year < 100) year += 2000; // Por si guardaron '26' en vez de '2026'

              int hour = int.parse(h[0]);
              int minute = h.length > 1 ? int.parse(h[1]) : 0;

              if (isPM && hour != 12) hour += 12;
              if (isAM && hour == 12) hour = 0;

              fechaHoraCita = DateTime(year, month, day, hour, minute);
            }
          } catch (e) {
            debugPrint("Matchy OS - Error forzando fecha en cita ${d.id}: $e");
          }
        }

        if (fechaHoraCita.isBefore(now)) {
          FirebaseFirestore.instance
              .collection(kCitasCollection)
              .doc(d.id)
              .set({
            kStatusField: kStatusCancelled,
            kCancelReasonField: kCancelReasonTime,
            kUpdatedAtField: FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          continue;
        }

        list.add(
          CitaPendiente(
            id: d.id,
            nombreLugar: nombreLugar,
            fecha: fecha,
            hora: hora,
            fotoLugar: fotoLugar,
            fechaHoraCita: fechaHoraCita,
          ),
        );
      }

      // 🔥 ORDENAMIENTO CRONOLÓGICO Y RENDERIZADO FORZADO
      list.sort((a, b) => a.fechaHoraCita.compareTo(b.fechaHoraCita));
      state = [...list]; // El spread operator [...] obliga a Riverpod a repintar la UI
    });
  }
}

final citasPendientesProvider =
StateNotifierProvider<CitasPendientesNotifier, List<CitaPendiente>>(
        (_) => CitasPendientesNotifier());

// ================================================================
// SCREEN
// ================================================================
class CitasPendientesScreen extends ConsumerWidget {
  const CitasPendientesScreen({super.key});

  static const List<Color> kCapsulaGradient = [Color(0xFF2E2E4D), Color(0xFF1A1A24)];
  static const Color kBorderColor = Colors.white12;
  static const double kCapsulaRadius = 24.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final citas = ref.watch(citasPendientesProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset("assets/images/fondo.jpg", fit: BoxFit.cover),
          ),

          Column(
            children: [
              const SizedBox(height: 35),
              SizedBox(
                height: 50,
                child: Image.asset('assets/images/logomatchyplano.png'),
              ),
              const SizedBox(height: 15),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: kCapsulaGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(kCapsulaRadius),
                    border: Border.all(color: kBorderColor, width: 1),
                    boxShadow: const [
                      BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 5))
                    ],
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40, height: 40,
                          decoration: const BoxDecoration(
                            color: Colors.white10,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                        ),
                      ),

                      // BLINDAJE: Título estandarizado
                      const Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              "CITAS PUBLICADAS",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16, // Tamaño original
                                fontWeight: FontWeight.w900,
                                fontFamily: "Poppins",
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 40),
                    ],
                  ),
                ),
              ),

              // 🔥 NUBE INFORMATIVA AÑADIDA AQUÍ
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Icon(Icons.info_outline_rounded, color: Color(0xFFBEB3FF), size: 22),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Estas son tus citas públicas. Los demás usuarios las verán en su radar y podrán postularse para acompañarte.",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontFamily: 'Poppins',
                            height: 1.3,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: citas.isEmpty
                    ? const SizedBox(
                  width: double.infinity,
                  child: _EmptyState(),
                )
                    : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: 120,
                  ),
                  itemCount: citas.length,
                  itemBuilder: (_, i) => _CitaCard(cita: citas[i]),
                ),
              ),
            ],
          ),

          Positioned(
            bottom: 0, left: 0, right: 0,
            height: 80,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.95),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0x33FFFFFF),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Container(
        width: double.infinity,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0x22FFFFFF),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Aún no tienes citas publicadas.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16, // Tamaño original
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ),
    );
  }
}

class _CitaCard extends StatelessWidget {
  final CitaPendiente cita;
  const _CitaCard({required this.cita});

  bool _isNet(String v) => v.startsWith("http");

  @override
  Widget build(BuildContext context) {
    const double h = 130;
    const double w = 120;

    // 🔥 SMART CACHE INYECTADO
    final Widget foto = _isNet(cita.fotoLugar)
        ? CachedNetworkImage(
      key: ValueKey(cita.fotoLugar),
      imageUrl: cita.fotoLugar,
      fit: BoxFit.cover,
      memCacheHeight: (h * 3).toInt(), // Limitador RAM para ListViews
      placeholder: (context, url) => Container(color: Colors.black26, child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Color(0xFFBEB3FF), strokeWidth: 2)))),
      errorWidget: (context, url, error) => Image.asset("assets/images/perfil1.jpg", fit: BoxFit.cover),
    )
        : Image.asset(
      cita.fotoLugar,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Image.asset("assets/images/perfil1.jpg", fit: BoxFit.cover),
    );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Card(
        color: const Color(0x886A5ACD),
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    CitasPendientesDetalleScreen(citaId: cita.id),
              ),
            );
          },
          child: SizedBox(
            height: h,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(22),
                    bottomLeft: Radius.circular(22),
                  ),
                  child: SizedBox(width: w, height: h, child: foto),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // BLINDAJE: Nombre del lugar
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            cita.nombreLugar.toUpperCase(),
                            maxLines: 1,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20, // Tamaño original
                              fontWeight: FontWeight.w900,
                              fontFamily: "Poppins",
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // BLINDAJE: Fecha
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "📅  ${cita.fecha}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18, // Tamaño original
                              fontWeight: FontWeight.w600,
                              fontFamily: "Poppins",
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // BLINDAJE: Hora
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "🕒  ${cita.hora}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18, // Tamaño original
                              fontWeight: FontWeight.w600,
                              fontFamily: "Poppins",
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(Icons.chevron_right,
                      color: Colors.white70, size: 26),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}