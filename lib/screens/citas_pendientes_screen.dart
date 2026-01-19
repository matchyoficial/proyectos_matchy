// 📂 lib/screens/citas_pendientes_screen.dart
// ✅ CITAS PUBLICADAS (DISEÑO PREMIUM)
// 🔥 HEADER: Cápsula Premium con botón Chevron integrado.
// 🔥 FOOTER: Degradado negro (Fade Out).
// 🔥 LÓGICA: Riverpod y Firestore intactos.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

// FORMATO NUEVO
const String kLugarMap = "lugar";
const String kLugarNombre = "nombre";
const String kLugarFotoPortada = "fotoPortada";

// FORMATO VIEJO
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

        DateTime fechaHoraCita = DateTime(2100);
        try {
          final f = fecha.split('/');
          final h = hora.split(':');
          if (f.length == 3 && h.length >= 2) {
            fechaHoraCita = DateTime(
              int.parse(f[2]),
              int.parse(f[1]),
              int.parse(f[0]),
              int.parse(h[0]),
              int.parse(h[1]),
            );
          }
        } catch (_) {}

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

      list.sort((a, b) => a.fechaHoraCita.compareTo(b.fechaHoraCita));
      state = list;
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

  // 🔴🔴 CHINCHES MAESTROS (DISEÑO PREMIUM) 🔴🔴
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
          // 1. FONDO
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

              // 2. HEADER CÁPSULA PREMIUM
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
                      // Botón Atrás Integrado
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

                      // Título Centrado
                      const Expanded(
                        child: Text(
                          "CITAS PUBLICADAS",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            fontFamily: "Poppins",
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),

                      // Espacio para equilibrar
                      const SizedBox(width: 40),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // 3. LISTA
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
                    bottom: 120, // Espacio para el fade out
                  ),
                  itemCount: citas.length,
                  itemBuilder: (_, i) => _CitaCard(cita: citas[i]),
                ),
              ),
            ],
          ),

          // 4. DEGRADADO NEGRO INFERIOR (FADE OUT)
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

// ================================================================
// EMPTY — MISMO DISEÑO QUE CITAS_SCREEN
// ================================================================
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
        child: const Text(
          'Aún no tienes citas publicadas.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }
}

// ================================================================
// CARD (INTACTA)
// ================================================================
class _CitaCard extends StatelessWidget {
  final CitaPendiente cita;
  const _CitaCard({required this.cita});

  bool _isNet(String v) => v.startsWith("http");

  @override
  Widget build(BuildContext context) {
    const double h = 130;
    const double w = 120;

    final Widget foto = _isNet(cita.fotoLugar)
        ? Image.network(cita.fotoLugar, fit: BoxFit.cover)
        : Image.asset(
      cita.fotoLugar,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          Image.asset("assets/images/perfil1.jpg", fit: BoxFit.cover),
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
                        Text(
                          cita.nombreLugar,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            fontFamily: "Poppins",
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "📅  ${cita.fecha}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            fontFamily: "Poppins",
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "🕒  ${cita.hora}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            fontFamily: "Poppins",
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