// 📂 lib/screens/perfil_usuariox_screen.dart
// -----------------------------------------------------------
// PERFIL PÚBLICO DEL USUARIO (DISEÑO PREMIUM + FOTO INTELIGENTE + PUNTUALIDAD)
// ✅ UI: Botón Atrás (Chevron) arriba a la izquierda.
// ✅ UI: Degradado negro inferior (Fade Out) para suavizar scroll.
// 🔥 FIX: Foto principal usa 'FotoPerfilUsuario' para actualizarse sola.
// 🔥 ADD: Barra de Puntualidad (Solo barra, sin reloj) entre foto y bio.
// -----------------------------------------------------------

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proyectos_matchy/widgets/foto_perfil_usuario.dart';
import 'package:proyectos_matchy/widgets/termometro_confiabilidad.dart'; // 👈 IMPORTANTE: Widget Nuevo

class PerfilUsuarioXScreen extends StatefulWidget {
  final String uid;

  const PerfilUsuarioXScreen({super.key, required this.uid});

  @override
  State<PerfilUsuarioXScreen> createState() => _PerfilUsuarioXScreenState();
}

class _PerfilUsuarioXScreenState extends State<PerfilUsuarioXScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  // 🔴 CHINCHE FIRESTORE 1 — colección users
  static const String kUsersCollection = 'users';

  // 🔴 CHINCHE FOTO 1 — alto foto principal
  static const double altoFotoPrincipal = 450;

  // 🔴 CHINCHE CAPS (Diseño Tags)
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
        if (mounted) {
          setState(() {
            _data = null;
            _loading = false;
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _data = snap.data();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _data = null;
          _loading = false;
        });
      }
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

    if (v.startsWith('http://') || v.startsWith('https://')) {
      return Image.network(
        v,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }
    if (v.startsWith('assets/')) {
      return Image.asset(
        v,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }
    return Image.file(
      File(v),
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      errorBuilder: (_, __, ___) => _fallback(),
    );
  }

  Widget _cardTexto(String titulo, String texto) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x33FFFFFF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              color: Color(0xFFB3D9FF),
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            texto,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  List<List<String>> _buildRows(List<String> all) {
    final cleaned =
    all.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();

    final rows = <List<String>>[];
    int i = 0;

    while (i < cleaned.length) {
      final cur = cleaned[i];
      final curLong = cur.length > maxShortLength;

      if (curLong) {
        rows.add([cur]);
        i += 1;
        continue;
      }

      if (i + 1 < cleaned.length) {
        final next = cleaned[i + 1];
        final nextLong = next.length > maxShortLength;

        if (nextLong) {
          rows.add([cur]);
          i += 1;
        } else {
          rows.add([cur, next]);
          i += 2;
        }
      } else {
        rows.add([cur]);
        i += 1;
      }
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
              style: const TextStyle(
                color: Colors.white,
                fontSize: chipFont,
                fontFamily: 'Poppins',
              ),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              color: Color(0xFFB3D9FF),
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 10),
          Column(
            children: rows.map((fila) {
              if (fila.length == 1) {
                return Row(children: [Expanded(child: _chip(fila[0]))]);
              }
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
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (_data == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(child: Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover)),
            const Center(
              child: Text(
                'No pude cargar el perfil',
                style: TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'Poppins'),
              ),
            ),
            // Botón cerrar error (Arriba Izquierda)
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

    // -------------------------------------------------------------
    // Datos del usuario
    // -------------------------------------------------------------

    final nombre = (_data!['nombre'] ?? '').toString().trim();
    final edad = (_data!['edad'] ?? '').toString().trim();
    final profesion = (_data!['profesion'] ?? '').toString().trim();
    final ciudad = (_data!['ciudad'] ?? '').toString().trim();
    final pais = (_data!['pais'] ?? '').toString().trim();

    final bio = (_data!['biografia'] ?? '').toString().trim();
    final detalle = (_data!['detalle'] ?? '').toString().trim();

    final sobreMi = (_data!['sobreMiSeleccion'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();

    final busco = (_data!['buscoSeleccion'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();

    final intereses = (_data!['interesesSeleccion'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();

    final galeriaRaw = (_data!['photoUrls'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();

    // 🟢 RECOLECCIÓN DATOS PUNTUALIDAD
    final puntaje = (_data!['confiabilidad'] as num?)?.toInt() ?? 100;
    final userStatus = (_data!['userStatus'] ?? 'active').toString();
    final strikes = (_data!['strikes'] as num?)?.toInt() ?? 0;
    final bloqueadoTimestamp = _data!['bloqueadoHasta'] as Timestamp?;

    // Lógica de cálculo de fecha (igual al Panel)
    bool estaBloqueado = false;
    DateTime? fechaTermometro;

    if (userStatus == 'blocked') estaBloqueado = true;
    if (bloqueadoTimestamp != null && bloqueadoTimestamp.toDate().isAfter(DateTime.now())) estaBloqueado = true;

    if (estaBloqueado) {
      if (bloqueadoTimestamp != null) {
        fechaTermometro = bloqueadoTimestamp.toDate();
      } else {
        // Cálculo teórico basado en strikes si no hay fecha explícita
        final diasCastigo = strikes * 5;
        fechaTermometro = DateTime.now().add(Duration(days: diasCastigo > 0 ? diasCastigo : 1));
      }
    }

    // -------------------------------------------------------------
    // UI
    // -------------------------------------------------------------

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Fondo
          Positioned.fill(
            child: Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover),
          ),

          Column(
            children: [
              const SizedBox(height: 45),
              SizedBox(
                height: 45,
                child: Image.asset('assets/images/logomatchyplano.png'),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 80), // Ajustado para el Fade Out
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Foto Principal
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        height: altoFotoPrincipal,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.45),
                              blurRadius: 10,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            // 🔥 Widget Inteligente
                            Positioned.fill(
                              child: FotoPerfilUsuario(
                                uid: widget.uid,
                                fit: BoxFit.cover,
                                alignment: Alignment.topCenter,
                              ),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: Container(
                                height: 180,
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
                            Positioned(
                              left: 30,
                              bottom: 30,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        nombre,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                      if (edad.isNotEmpty)
                                        Text(
                                          ', $edad',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    profesion.isEmpty ? '—' : profesion,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    ciudad.isEmpty && pais.isEmpty
                                        ? 'Sin ubicación'
                                        : (ciudad.isNotEmpty && pais.isNotEmpty)
                                        ? '$ciudad - $pais'
                                        : (ciudad.isNotEmpty ? ciudad : pais),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // =======================================================
                      // 🔥 BARRA DE PUNTUALIDAD (SOLO BARRA)
                      // =======================================================
                      const SizedBox(height: 16),
                      TermometroConfiabilidad(
                        puntaje: puntaje,
                        fechaDesbloqueo: fechaTermometro,
                        mostrarReloj: false, // 👈 Sin reloj para este perfil
                      ),
                      const SizedBox(height: 6),
                      // =======================================================

                      _cardTexto('Biografía', bio.isEmpty ? '—' : bio),

                      if (sobreMi.isNotEmpty) _cardChips('Sobre mí', sobreMi),

                      if (galeriaRaw.length >= 2)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          height: 400,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: _buildImage(galeriaRaw[1]),
                        ),

                      if (busco.isNotEmpty) _cardChips('Busco...', busco),

                      if (galeriaRaw.length >= 3)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          height: 400,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: _buildImage(galeriaRaw[2]),
                        ),

                      if (intereses.isNotEmpty)
                        _cardChips('Intereses y Hobbies', intereses),

                      if (galeriaRaw.length >= 4)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          height: 400,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: _buildImage(galeriaRaw[3]),
                        ),

                      _cardTexto(
                        'Un detalle que me enamora',
                        detalle.isEmpty ? '—' : detalle,
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 2. 🔥 DEGRADADO INFERIOR (FADE OUT)
          Positioned(
            bottom: 0, left: 0, right: 0, height: 80,
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

          // 3. 🔥 BOTÓN CHEVRON FLOTANTE (ARRIBA IZQUIERDA)
          Positioned(
            top: 50, // SafeArea aprox
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3), // Semitransparente
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}