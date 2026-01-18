// 📂 lib/screens/citas_pendientes_screen.dart
// ✅ CITAS PUBLICADAS (Pendientes) — diseño Matchy
// ✅ SOLO LECTURA: Firestore REAL (persisten al reiniciar)
// ✅ NO DUPLICA: este screen NO crea docs
// ✅ Solo muestra citas ACTIVAS (status == online) y NO vencidas
// ✅ Cancelar => status = cancelled (NO delete) para que no “reaparezca”
// ✅ Tap tarjeta → abre detalle con docId real (citas_pendientes_detalle.dart)
// ✅ SIN botones de regresar (pedido por ti)

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:proyectos_matchy/screens/citas_pendientes_detalle.dart';

// ================================================================
// 🔴 CHINCHE FIRESTORE 1 — colección citas
// ================================================================
const String kCitasCollection = 'citas';

// Fields base
const String kOwnerUidField = 'ownerUid';
const String kStatusField = 'status';
const String kStatusOnline = 'online';
const String kStatusCancelled = 'cancelled';

// Campos comunes
const String kCodigoField = 'codigo';
const String kFechaField = 'fecha';
const String kHoraField = 'hora';
const String kPreferenciaField = 'preferencia';
const String kIntencionField = 'intencion';
const String kCreatedAtField = 'createdAt';

// Maps
const String kLugarMap = 'lugar';
const String kLugarNombre = 'nombre';
const String kLugarDireccion = 'direccion';
const String kLugarFotoPortada = 'fotoPortada';
const String kLugarFoto = 'foto';

const String kCreadorMap = 'creador';
const String kCreadorNombre = 'nombre';
const String kCreadorEdad = 'edad';
const String kCreadorFoto = 'foto';

// Opcional si lo tienes
const String kScheduledAtField = 'scheduledAt';

// ================================================================
// 🔹 MODELO
// ================================================================
class CitaPendiente {
  final String id; // docId real
  final String codigo;

  final String nombreLugar;
  final String direccionLugar;
  final String fecha;
  final String hora;

  final String fotoLugar; // URL o asset

  final String preferencia;
  final String intencion;

  final String creadorNombre;
  final int creadorEdad;
  final String creadorFoto;

  final DateTime createdAt;

  const CitaPendiente({
    required this.id,
    required this.codigo,
    required this.nombreLugar,
    required this.direccionLugar,
    required this.fecha,
    required this.hora,
    required this.fotoLugar,
    required this.preferencia,
    required this.intencion,
    required this.creadorNombre,
    required this.creadorEdad,
    required this.creadorFoto,
    required this.createdAt,
  });
}

// ================================================================
// 🔹 NOTIFIER (stream Firestore)
// ================================================================
class CitasPendientesNotifier extends StateNotifier<List<CitaPendiente>> {
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  StreamSubscription<User?>? _authSub;

  CitasPendientesNotifier() : super(const []) {
    _authSub = FirebaseAuth.instance.authStateChanges().listen((_) => _bind());
    _bind();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _authSub?.cancel();
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

    // ✅ Importante: filtramos solo ONLINE aquí => canceladas nunca vuelven.
    final q = FirebaseFirestore.instance
        .collection(kCitasCollection)
        .where(kOwnerUidField, isEqualTo: user.uid)
        .where(kStatusField, isEqualTo: kStatusOnline);

    _sub = q.snapshots().listen((snap) {
      final now = DateTime.now();

      final list = snap.docs.map((d) {
        final data = d.data();

        // codigo
        final codigo = (data[kCodigoField] ?? '').toString().trim();

        // lugar map
        final lugar = (data[kLugarMap] is Map)
            ? Map<String, dynamic>.from(data[kLugarMap] as Map)
            : <String, dynamic>{};

        final nombreLugar = (lugar[kLugarNombre] ??
            data['nombreLugar'] ??
            data['nombre'] ??
            '')
            .toString()
            .trim();

        final direccionLugar = (lugar[kLugarDireccion] ??
            data['direccionLugar'] ??
            data['direccion'] ??
            '')
            .toString()
            .trim();

        final fotoLugar = (lugar[kLugarFotoPortada] ??
            lugar[kLugarFoto] ??
            data['fotoPortada'] ??
            data['fotoLugar'] ??
            data['fotoLugarAsset'] ??
            '')
            .toString()
            .trim();

        // creador map
        final creador = (data[kCreadorMap] is Map)
            ? Map<String, dynamic>.from(data[kCreadorMap] as Map)
            : <String, dynamic>{};

        final creadorNombre =
        (creador[kCreadorNombre] ?? data['creadorNombre'] ?? 'Usuario')
            .toString()
            .trim();

        int creadorEdad = 0;
        final ce = (creador[kCreadorEdad] ?? data['creadorEdad']);
        if (ce is int) creadorEdad = ce;
        if (ce is String) creadorEdad = int.tryParse(ce) ?? 0;

        final creadorFoto =
        (creador[kCreadorFoto] ?? data['creadorFoto'] ?? '')
            .toString()
            .trim();

        // fecha/hora
        final fecha = (data[kFechaField] ?? '').toString().trim();
        final hora = (data[kHoraField] ?? '').toString().trim();

        final preferencia =
        (data[kPreferenciaField] ?? 'Ambos').toString().trim();
        final intencion =
        (data[kIntencionField] ?? 'Amistad').toString().trim();

        // createdAt
        DateTime createdAt = DateTime.now();
        final ts = data[kCreatedAtField];
        if (ts is Timestamp) createdAt = ts.toDate();

        return CitaPendiente(
          id: d.id,
          codigo: codigo.isEmpty ? d.id : codigo,
          nombreLugar: nombreLugar.isEmpty ? 'Lugar' : nombreLugar,
          direccionLugar:
          direccionLugar.isEmpty ? 'Sin dirección' : direccionLugar,
          fecha: fecha.isEmpty ? 'Fecha pendiente' : fecha,
          hora: hora.isEmpty ? 'Hora pendiente' : hora,
          fotoLugar: fotoLugar.isEmpty ? 'assets/images/perfil1.jpg' : fotoLugar,
          preferencia: preferencia,
          intencion: intencion,
          creadorNombre: creadorNombre.isEmpty ? 'Usuario' : creadorNombre,
          creadorEdad: creadorEdad,
          creadorFoto: creadorFoto,
          createdAt: createdAt,
        );
      }).toList();

      // ✅ quitar vencidas (solo UI)
      final filtered = list.where((c) {
        final dt = _extractCitaDateTimeFromDocMaybe(dataFromId: c.id);
        // (No podemos leer el doc aquí; entonces parseamos strings)
        final parsed = _parseCitaDateTime(c.fecha, c.hora);
        if (parsed == null) return true;
        return parsed.isAfter(now);
      }).toList();

      // orden UI por createdAt desc
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = filtered;
    });
  }

  // 🔴 CHINCHE VENCIDAS 1 — este helper solo existe por compat (no se usa)
  // (lo dejo para no romper nada si después quieres meter scheduledAt)
  DateTime? _extractCitaDateTimeFromDocMaybe({required String dataFromId}) {
    return null;
  }

  // ✅ Cancelar: NO delete. Marca cancelled.
  Future<void> cancelById(String docId) async {
    try {
      await FirebaseFirestore.instance.collection(kCitasCollection).doc(docId).set({
        kStatusField: kStatusCancelled,
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error cancelando cita: $e');
    }
  }

  // ✅ COMPAT: si algún código viejo llama add(), NO HACEMOS NADA
  // porque la cita YA se crea en CreaCitaScreen (Paso 1).
  Future<void> add(CitaPendiente cita) async {
    // intencionalmente vacío para evitar DUPLICADOS
  }

  DateTime? _parseCitaDateTime(String fecha, String hora) {
    try {
      final f = fecha.trim();
      final h = hora.trim();
      final parts = f.split('/');
      if (parts.length != 3) return null;

      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);

      int hour24 = 0;
      int minute = 0;

      final upper = h.toUpperCase();
      if (upper.contains('AM') || upper.contains('PM')) {
        final isPM = upper.contains('PM');
        final clean = upper.replaceAll('AM', '').replaceAll('PM', '').trim();
        final hm = clean.split(':');
        if (hm.length != 2) return null;

        var hh = int.parse(hm[0].trim());
        minute = int.parse(hm[1].trim());

        if (isPM) {
          if (hh != 12) hh += 12;
        } else {
          if (hh == 12) hh = 0;
        }
        hour24 = hh;
      } else {
        final hm = upper.split(':');
        if (hm.length != 2) return null;
        hour24 = int.parse(hm[0].trim());
        minute = int.parse(hm[1].trim());
      }

      return DateTime(year, month, day, hour24, minute);
    } catch (_) {
      return null;
    }
  }
}

final citasPendientesProvider =
StateNotifierProvider<CitasPendientesNotifier, List<CitaPendiente>>(
      (ref) => CitasPendientesNotifier(),
);

// ================================================================
// 🔹 SCREEN
// ================================================================
class CitasPendientesScreen extends ConsumerWidget {
  const CitasPendientesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const double espacioBarraLogo = 35;
    const double alturaLogo = 50;
    const double espacioLogoTitulo = 15;
    const double paddingBottom = 90;

    final citas = ref.watch(citasPendientesProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover),
          ),

          // ✅ (QUITADO) botón back superior — pedido por ti

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
                    'CITAS PUBLICADAS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: paddingBottom,
                  ),
                  itemCount: citas.isEmpty ? 1 : citas.length,
                  itemBuilder: (context, index) {
                    if (citas.isEmpty) return _EmptyState();
                    final cita = citas[index];
                    return _CitaPendienteCard(cita: cita);
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
// EMPTY STATE
// ================================================================
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0x33FFFFFF),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aún no tienes citas publicadas.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Crea una cita desde el Panel y aparecerá aquí automáticamente.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.3,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// CARD
// ================================================================
class _CitaPendienteCard extends ConsumerWidget {
  final CitaPendiente cita;
  const _CitaPendienteCard({required this.cita});

  bool _isNetwork(String v) => v.startsWith('http://') || v.startsWith('https://');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const Color cardColor = Color(0x996A5ACD);
    const double cardHeight = 140;
    const double fotoWidth = 120;

    Widget fotoWidget;
    final src = cita.fotoLugar.trim();
    if (src.isEmpty) {
      fotoWidget = Image.asset('assets/images/perfil1.jpg', fit: BoxFit.cover);
    } else if (_isNetwork(src)) {
      fotoWidget = Image.network(
        src,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            Image.asset('assets/images/perfil1.jpg', fit: BoxFit.cover),
      );
    } else {
      fotoWidget = Image.asset(
        src,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            Image.asset('assets/images/perfil1.jpg', fit: BoxFit.cover),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Card(
        elevation: 6,
        color: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CitasPendientesDetalleScreen(citaId: cita.id),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: cardHeight,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                  child: SizedBox(
                    width: fotoWidth,
                    height: cardHeight,
                    child: fotoWidget,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cita.nombreLugar,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '📍 ${cita.direccionLugar}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '📅 ${cita.fecha}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '🕒 ${cita.hora}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 34,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'CÓDIGO: ${cita.codigo}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              height: 34,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE53935),
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: () async {
                                  await ref
                                      .read(citasPendientesProvider.notifier)
                                      .cancelById(cita.id);

                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Cita cancelada.')),
                                  );
                                },
                                child: const Text(
                                  'CANCELAR',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: Icon(
                    Icons.chevron_right,
                    color: Colors.white70,
                    size: 26,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
