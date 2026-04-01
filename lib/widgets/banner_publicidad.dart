// 📂 lib/widgets/banner_publicidad.dart
// ✅ BANNER PUBLICITARIO (MATCHY STYLE + GEOLOCALIZACIÓN)
// 🔥 LÓGICA: Primer impacto 100% Premium. Intercalado inteligente.
// 🔥 TIEMPO: Rotación exacta de 3.5 segundos.
// 🔥 DATOS: Filtro estricto por Ciudad y País inyectado.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 🔥 Import para leer al usuario
import 'package:cached_network_image/cached_network_image.dart';

class BannerPublicidad extends StatefulWidget {
  const BannerPublicidad({super.key});

  @override
  State<BannerPublicidad> createState() => _BannerPublicidadState();
}

class _BannerPublicidadState extends State<BannerPublicidad> {
  PageController? _pageController;
  Timer? _timer;
  List<String> _playlist = [];
  bool _isLoading = true;
  String _userCiudad = 'Cali';
  String _userPais = 'Colombia';

  @override
  void initState() {
    super.initState();
    _fetchUserLocation();
  }

  // 🔥 LECTURA SILENCIOSA DE LA UBICACIÓN
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
            });
            _cargarPublicidad(); // Solo carga cuando tiene el GPS
            return;
          }
        }
      } catch (_) {}
    }
    // Si falla o no hay usuario, intenta cargar con los valores por defecto
    if (mounted) {
      _cargarPublicidad();
    }
  }

  Future<void> _cargarPublicidad() async {
    try {
      // 1. 🔒 CANDADOS INYECTADOS: Activo, País y Ciudad
      final snap = await FirebaseFirestore.instance
          .collection('publicidad_banner')
          .where('activo', isEqualTo: true)
          .where('pais', isEqualTo: _userPais)
          .where('ciudad', isEqualTo: _userCiudad)
          .get();

      if (snap.docs.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      List<String> premiumAds = [];
      List<String> normalAds = [];

      for (var doc in snap.docs) {
        final data = doc.data();
        final fotoUrl = (data['foto'] ?? '').toString();
        final tipo = (data['tipo'] ?? 'normal').toString().toLowerCase();

        if (fotoUrl.isNotEmpty) {
          if (tipo == 'premium') {
            premiumAds.add(fotoUrl);
          } else {
            normalAds.add(fotoUrl);
          }
        }
      }

      _generarPlaylist(premiumAds, normalAds);
    } catch (e) {
      debugPrint("Error cargando publicidad: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _generarPlaylist(List<String> premium, List<String> normal) {
    premium.shuffle();
    normal.shuffle();

    List<String> finalPlaylist = [];

    // 🔥 REGLA DE ORO: El primer anuncio DEBE ser Premium
    if (premium.isNotEmpty) {
      finalPlaylist.add(premium.removeAt(0));
    } else if (normal.isNotEmpty) {
      finalPlaylist.add(normal.removeAt(0));
    }

    // 🧠 ALGORITMO DE INSERCIÓN EQUITATIVA
    int maxIter = premium.length > normal.length ? premium.length : normal.length;
    for (int i = 0; i < maxIter; i++) {
      if (i < normal.length) finalPlaylist.add(normal[i]);
      if (i < premium.length) finalPlaylist.add(premium[i]);
    }

    if (mounted) {
      setState(() {
        _playlist = finalPlaylist;
        _isLoading = false;
        if (_playlist.isNotEmpty) {
          int initial = 10000 - (10000 % _playlist.length);
          _pageController = PageController(initialPage: initial);
          _iniciarTimer();
        }
      });
    }
  }

  void _iniciarTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 3500), (timer) {
      if (_pageController != null && _pageController!.hasClients) {
        _pageController!.nextPage(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator(color: Color(0xFFBEB3FF))),
      );
    }

    if (_playlist.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        // 🔥 GLOW EXTERIOR MATCHY
        boxShadow: [
          BoxShadow(color: const Color(0xFFBEB3FF).withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 5)),
        ],
        border: Border.all(color: const Color(0xFFBEB3FF).withOpacity(0.5), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AspectRatio(
          aspectRatio: 1920 / 1080,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. CARRUSEL CON SMART CACHE
              PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  final adUrl = _playlist[index % _playlist.length];
                  return CachedNetworkImage(
                    key: ValueKey(adUrl),
                    imageUrl: adUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: const Color(0xFF1A1A1A)),
                    errorWidget: (context, url, error) => Container(color: Colors.grey[900], child: const Icon(Icons.broken_image, color: Colors.white24)),
                  );
                },
              ),
              // 2. EFECTO BISEL
              IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.5),
                        Colors.transparent,
                        Colors.black.withOpacity(0.5),
                      ],
                      stops: const [0.0, 0.5, 1.0],
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