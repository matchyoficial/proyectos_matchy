// 📂 lib/screens/perfil_usuariox_screen.dart
// -----------------------------------------------------------
// PERFIL PÚBLICO DEL USUARIO (DISEÑO PREMIUM + FOTO INTELIGENTE + PUNTUALIDAD)
// ✅ UI: Botón Atrás (Chevron) arriba a la izquierda.
// ✅ UI: Estilo de chips y sombras replicado de "Datos".
// 🔥 BLINDAJE: Títulos a 20pt, Profesión y Ciudad adaptativos.
// -----------------------------------------------------------

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proyectos_matchy/widgets/foto_perfil_usuario.dart';
import 'package:proyectos_matchy/widgets/termometro_confiabilidad.dart';

class PerfilUsuarioXScreen extends StatefulWidget {
  final String uid;

  const PerfilUsuarioXScreen({super.key, required this.uid});

  @override
  State<PerfilUsuarioXScreen> createState() => _PerfilUsuarioXScreenState();
}

class _PerfilUsuarioXScreenState extends State<PerfilUsuarioXScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  // 🛡️ ZONA DE CHINCHES MAESTROS (DISEÑO PREMIUM)
  static const String kUsersCollection = 'users';
  static const double altoFotoPrincipal = 450;

  // Sombras Estilo Datos
  static const List<Shadow> kTextShadow = [
    Shadow(color: Colors.black, blurRadius: 10, offset: Offset(0, 4))
  ];
  static const List<BoxShadow> kChipShadow = [
    BoxShadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 3))
  ];

  // Configuración Tags
  static const int maxShortLength = 14;
  static const double gapX = 10;
  static const double chipPadV = 10;
  static const double chipPadH = 10;
  static const double chipFont = 13;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection(kUsersCollection)
          .doc(widget.uid)
          .get();

      if (!snap.exists) {
        if (mounted) setState(() { _data = null; _loading = false; });
        return;
      }

      if (mounted) setState(() { _data = snap.data(); _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _data = null; _loading = false; });
    }
  }

  // -------------------------------------------------------------
  // Helpers UI
  // -------------------------------------------------------------

  Widget _fallback() {
    return Container(
      color: const Color(0x33FFFFFF),
      child: const Center(
        child: Icon(Icons.person, color: Colors.white70, size: 70),
      ),
    );
  }

  Widget _buildImage(String? raw) {
    if (raw == null || raw.trim().isEmpty) return _fallback();
    final v = raw.trim();
    if (v.startsWith('http')) {
      return Image.network(v, fit: BoxFit.cover, alignment: Alignment.topCenter, errorBuilder: (_, __, ___) => _fallback());
    }
    if (v.startsWith('assets/')) {
      return Image.asset(v, fit: BoxFit.cover, alignment: Alignment.topCenter, errorBuilder: (_, __, ___) => _fallback());
    }
    return Image.file(File(v), fit: BoxFit.cover, alignment: Alignment.topCenter, errorBuilder: (_, __, ___) => _fallback());
  }

  Widget _cardTexto(String titulo, String texto) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x33FFFFFF),
        borderRadius: BorderRadius.circular(20),
        boxShadow: kChipShadow, // Aplicada sombra a la cápsula
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              titulo,
              style: const TextStyle(
                color: Color(0xFFB3D9FF),
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
                shadows: kTextShadow, // Sombra en título
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            texto,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Poppins'),
          ),
        ],
      ),
    );
  }

  List<List<String>> _buildRows(List<String> all) {
    final cleaned = all.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    final rows = <List<String>>[];
    int i = 0;
    while (i < cleaned.length) {
      final cur = cleaned[i];
      if (cur.length > maxShortLength) { rows.add([cur]); i += 1; continue; }
      if (i + 1 < cleaned.length && cleaned[i + 1].length <= maxShortLength) {
        rows.add([cur, cleaned[i + 1]]); i += 2;
      } else { rows.add([cur]); i += 1; }
    }
    return rows;
  }

  Widget _chip(String txt) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: chipPadV, horizontal: chipPadH),
      decoration: BoxDecoration(
        color: const Color(0x66FFFFFF),
        borderRadius: BorderRadius.circular(50),
        boxShadow: kChipShadow, // Sombra en cada chip estilo Datos
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              txt,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: chipFont, fontFamily: 'Poppins', fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardChips(String titulo, List<String> items) {
    if (items.isEmpty) return const SizedBox();
    final rows = _buildRows(items);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x33FFFFFF),
        borderRadius: BorderRadius.circular(20),
        boxShadow: kChipShadow,
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              titulo,
              style: const TextStyle(
                color: Color(0xFFB3D9FF),
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
                shadows: kTextShadow,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Column(
            children: rows.map((fila) {
              if (fila.length == 1) return Row(children: [Expanded(child: _chip(fila[0]))]);
              return Row(
                children: [
                  Expanded(child: _chip(fila[0])),
                  const SizedBox(width: gapX),
                  Expanded(child: _chip(fila[1])),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(color: Colors.white)));

    if (_data == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(child: Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover)),
            const Center(child: Text('No pude cargar el perfil', style: TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'Poppins'))),
            Positioned(
              top: 50, left: 20,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 45, height: 45,
                  decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle, border: Border.all(color: Colors.white24)),
                  child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                ),
              ),
            )
          ],
        ),
      );
    }

    final nombre = (_data!['nombre'] ?? '').toString().trim();
    final edad = (_data!['edad'] ?? '').toString().trim();
    final profesion = (_data!['profesion'] ?? '').toString().trim();
    final ciudad = (_data!['ciudad'] ?? '').toString().trim();
    final pais = (_data!['pais'] ?? '').toString().trim();
    final bio = (_data!['biografia'] ?? '').toString().trim();
    final detalle = (_data!['detalle'] ?? '').toString().trim();

    final sobreMi = (_data!['sobreMiSeleccion'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
    final busco = (_data!['buscoSeleccion'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
    final intereses = (_data!['interesesSeleccion'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
    final galeriaRaw = (_data!['photoUrls'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();

    final puntaje = (_data!['confiabilidad'] as num?)?.toInt() ?? 100;
    final userStatus = (_data!['userStatus'] ?? 'active').toString();
    final strikes = (_data!['strikes'] as num?)?.toInt() ?? 0;
    final bloqueadoTimestamp = _data!['bloqueadoHasta'] as Timestamp?;

    bool estaBloqueado = false;
    DateTime? fechaTermometro;
    if (userStatus == 'blocked' || (bloqueadoTimestamp != null && bloqueadoTimestamp.toDate().isAfter(DateTime.now()))) estaBloqueado = true;
    if (estaBloqueado) {
      fechaTermometro = bloqueadoTimestamp?.toDate() ?? DateTime.now().add(Duration(days: strikes * 5 > 0 ? strikes * 5 : 1));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover)),
          Column(
            children: [
              const SizedBox(height: 45),
              SizedBox(height: 45, child: Image.asset('assets/images/logomatchyplano.png')),
              const SizedBox(height: 14),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        height: altoFotoPrincipal,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.45), blurRadius: 10, offset: const Offset(0, 6))],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            Positioned.fill(child: FotoPerfilUsuario(uid: widget.uid, fit: BoxFit.cover, alignment: Alignment.topCenter)),
                            Positioned(
                              left: 0, right: 0, bottom: 0,
                              child: Container(
                                height: 180,
                                decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.95)])),
                              ),
                            ),
                            Positioned(
                              left: 30, bottom: 30, right: 30,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Row(
                                      children: [
                                        Text(nombre, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'Poppins', shadows: kTextShadow)),
                                        if (edad.isNotEmpty) Text(', $edad', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'Poppins', shadows: kTextShadow)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(profesion.isEmpty ? '—' : profesion, style: const TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Poppins', shadows: kTextShadow)),
                                  ),
                                  const SizedBox(height: 2),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      ciudad.isEmpty && pais.isEmpty ? 'Sin ubicación' : (ciudad.isNotEmpty && pais.isNotEmpty ? '$ciudad - $pais' : (ciudad.isNotEmpty ? ciudad : pais)),
                                      style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Poppins', shadows: kTextShadow),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),
                      TermometroConfiabilidad(puntaje: puntaje, fechaDesbloqueo: fechaTermometro, mostrarReloj: false),
                      const SizedBox(height: 6),

                      _cardTexto('Biografía', bio.isEmpty ? '—' : bio),
                      if (sobreMi.isNotEmpty) _cardChips('Sobre mí', sobreMi),
                      if (galeriaRaw.length >= 2) Container(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), height: 400, clipBehavior: Clip.antiAlias, decoration: BoxDecoration(borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))]), child: _buildImage(galeriaRaw[1])),
                      if (busco.isNotEmpty) _cardChips('Busco...', busco),
                      if (galeriaRaw.length >= 3) Container(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), height: 400, clipBehavior: Clip.antiAlias, decoration: BoxDecoration(borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))]), child: _buildImage(galeriaRaw[2])),
                      if (intereses.isNotEmpty) _cardChips('Intereses y Hobbies', intereses),
                      if (galeriaRaw.length >= 4) Container(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), height: 400, clipBehavior: Clip.antiAlias, decoration: BoxDecoration(borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))]), child: _buildImage(galeriaRaw[3])),
                      _cardTexto('Un detalle que me enamora', detalle.isEmpty ? '—' : detalle),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 0, left: 0, right: 0, height: 80,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.95)])),
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