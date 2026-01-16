// 📂 lib/screens/citas_screen.dart
// ✅ CitasScreen FIRESTORE-DRIVEN con Riverpod
// ✅ 2 carruseles internos: Próximas / Completadas
// ✅ No crashea si falta imagen
// ✅ Respeta MatchyPageLayout
// ✅ FIX ÍNDICE: NO usa orderBy en Firestore (evita FAILED_PRECONDITION) y ordena local
// ✅ SHELL-SAFE: NO usa bottom nav interno (el HomeShell manda)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proyectos_matchy/widgets/matchy_page_layout.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 🔴 CHINCHE FIRESTORE A — misma colección usada en citas_pendientes_detalle
const String kCitasCollection = 'citas';
const String kOwnerUidField = 'ownerUid';

enum CitaStatus { proxima, completada }

class CitaItem {
  final String id;
  final String nombre;
  final int edad;
  final String lugar;
  final String fotoChica;
  final String fotoLugar;
  final DateTime fechaHora;
  final CitaStatus status;

  const CitaItem({
    required this.id,
    required this.nombre,
    required this.edad,
    required this.lugar,
    required this.fotoChica,
    required this.fotoLugar,
    required this.fechaHora,
    required this.status,
  });

  String get nombreEdad => '$nombre, $edad';

  String get fechaUI {
    const meses = [
      'Ene','Feb','Mar','Abr','May','Jun',
      'Jul','Ago','Sep','Oct','Nov','Dic'
    ];
    final d = fechaHora.day.toString().padLeft(2, '0');
    final m = meses[fechaHora.month - 1];
    final y = fechaHora.year;
    return '$d $m $y';
  }

  String get horaUI {
    final h = fechaHora.hour;
    final min = fechaHora.minute.toString().padLeft(2, '0');
    final ampm = h < 12 ? 'a.m.' : 'p.m.';
    final display = (h % 12 == 0) ? 12 : (h % 12);
    return '$display:$min $ampm';
  }
}

// ================================================================
// 🔹 PROVIDER: stream Firestore de mis citas (SIN orderBy para evitar índice)
// ================================================================
final misCitasStreamProvider = StreamProvider<List<CitaItem>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return const Stream<List<CitaItem>>.empty();
  }

  final q = FirebaseFirestore.instance
      .collection(kCitasCollection)
      .where(kOwnerUidField, isEqualTo: user.uid); // 🔴 CHINCHE QUERY 1

  return q.snapshots().map((snap) {
    final now = DateTime.now();

    final list = snap.docs.map((d) {
      final data = d.data();

      final ts = data['fechaHora'];
      final DateTime fechaHora = (ts is Timestamp) ? ts.toDate() : DateTime.now();

      final String nombre = (data['matchNombre'] ?? 'Match').toString();
      final int edad = (data['matchEdad'] is int) ? data['matchEdad'] as int : 0;

      final String fotoChica =
      (data['matchFotoAsset'] ?? 'assets/images/perfil1.jpg').toString();
      final String fotoLugar =
      (data['lugarFotoAsset'] ?? 'assets/images/faro1.jpg').toString();
      final String lugar = (data['lugarNombre'] ?? 'Lugar').toString();

      final status =
      fechaHora.isBefore(now) ? CitaStatus.completada : CitaStatus.proxima;

      return CitaItem(
        id: d.id,
        nombre: nombre,
        edad: edad,
        lugar: lugar,
        fotoChica: fotoChica,
        fotoLugar: fotoLugar,
        fechaHora: fechaHora,
        status: status,
      );
    }).toList();

    // ✅ Orden local (reemplaza orderBy Firestore sin pedir índice)
    list.sort((a, b) => a.fechaHora.compareTo(b.fechaHora));

    return list;
  });
});

class CitasScreen extends ConsumerWidget {
  static const String routeName = 'citas';

  final bool showBottomNav; // 🔴 CHINCHE SHELL CITAS 1 (compatibilidad)

  const CitasScreen({
    super.key,
    this.showBottomNav = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: MatchyPageLayout(
        backgroundAsset: 'assets/images/fondo.jpg',
        logoAsset: 'assets/images/logomatchyplano.png',
        scrollContent: _CitasContent(textTheme: textTheme),
        topSpacing: 35,
        logoHeight: 50,
        logoOffsetY: 0,
        spaceLogoToScroll: 15,
      ),

      // ✅ SHELL manda la barra. Aquí NUNCA.
      bottomNavigationBar: null,
    );
  }
}

class _CitasContent extends ConsumerWidget {
  final TextTheme textTheme;

  const _CitasContent({required this.textTheme});

  static const double _alturaCarrusel = 330;
  static const double _espacioTituloTarjetas = 6;
  static const double _espacioEntreSecciones = 18;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(misCitasStreamProvider);

    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.only(top: 20),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.only(top: 18),
        child: Center(
          child: Text(
            '❌ Error cargando citas: $e',
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (all) {
        final proximas =
        all.where((c) => c.status == CitaStatus.proxima).toList();
        final completadas =
        all.where((c) => c.status == CitaStatus.completada).toList();

        return Column(
          children: [
            Text(
              'PRÓXIMAS CITAS',
              style: textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: _espacioTituloTarjetas),
            SizedBox(
              height: _alturaCarrusel,
              child: proximas.isEmpty
                  ? _EmptyBox(text: 'Aún no tienes próximas citas.')
                  : ListView.builder(
                padding: EdgeInsets.zero,
                physics: const BouncingScrollPhysics(),
                itemCount: proximas.length,
                itemBuilder: (context, index) {
                  return _CitaCard(
                    cita: proximas[index],
                    textTheme: textTheme,
                    isCompleted: false,
                  );
                },
              ),
            ),
            const SizedBox(height: _espacioEntreSecciones),
            Text(
              'CITAS COMPLETADAS',
              style: textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: _espacioTituloTarjetas),
            SizedBox(
              height: _alturaCarrusel,
              child: completadas.isEmpty
                  ? _EmptyBox(text: 'Aún no tienes citas completadas.')
                  : ListView.builder(
                padding: EdgeInsets.zero,
                physics: const BouncingScrollPhysics(),
                itemCount: completadas.length,
                itemBuilder: (context, index) {
                  return _CitaCard(
                    cita: completadas[index],
                    textTheme: textTheme,
                    isCompleted: true,
                  );
                },
              ),
            ),
            const SizedBox(height: 30),
          ],
        );
      },
    );
  }
}

class _EmptyBox extends StatelessWidget {
  final String text;
  const _EmptyBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 18),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0x33FFFFFF),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white70, fontFamily: 'Poppins'),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _CitaCard extends StatelessWidget {
  final CitaItem cita;
  final TextTheme textTheme;
  final bool isCompleted;

  const _CitaCard({
    required this.cita,
    required this.textTheme,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    const Color colorProximas = Color(0x996A5ACD);
    const Color colorCompletadas = Color(0xCC3F2B63);

    final Color cardColor = isCompleted ? colorCompletadas : colorProximas;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Card(
        color: cardColor,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SizedBox(
          height: 115,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: _SafeAssetImage(
                    asset: cita.fotoChica,
                    width: 92,
                    height: 92,
                    fit: BoxFit.cover,
                    fallback: 'assets/images/perfil1.jpg',
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cita.nombreEdad,
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('📍 ${cita.lugar}', style: _infoStyle(textTheme)),
                    Text('📅 ${cita.fechaUI}', style: _infoStyle(textTheme)),
                    Text('🕒 ${cita.horaUI}', style: _infoStyle(textTheme)),
                  ],
                ),
              ),
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                child: _SafeAssetImage(
                  asset: cita.fotoLugar,
                  width: 115,
                  height: 92,
                  fit: BoxFit.cover,
                  fallback: 'assets/images/faro1.jpg',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle _infoStyle(TextTheme t) {
    return t.bodySmall!.copyWith(
      color: Colors.white,
      fontSize: 12,
    );
  }
}

class _SafeAssetImage extends StatelessWidget {
  final String asset;
  final double width;
  final double height;
  final BoxFit fit;
  final String fallback;

  const _SafeAssetImage({
    required this.asset,
    required this.width,
    required this.height,
    required this.fit,
    required this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => Image.asset(
        fallback,
        width: width,
        height: height,
        fit: fit,
      ),
    );
  }
}
