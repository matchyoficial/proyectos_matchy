// 📂 lib/widgets/publicidad_swap_card.dart
// ✅ TARJETA DE PUBLICIDAD SWAP INTELIGENTE (MATCHY STYLE)
// 🔥 LÓGICA: Timer de 5s con "Sensor de Frente" (isFrontCard).

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PublicidadSwapCard extends StatefulWidget {
  final String imageUrl;
  final double width;
  final double totalHeight;
  final VoidCallback onAutoDismiss;
  final bool isFrontCard; // 🔥 EL SENSOR: ¿Estoy de primera en la pantalla?

  const PublicidadSwapCard({
    super.key,
    required this.imageUrl,
    required this.width,
    required this.totalHeight,
    required this.onAutoDismiss,
    required this.isFrontCard,
  });

  @override
  State<PublicidadSwapCard> createState() => _PublicidadSwapCardState();
}

class _PublicidadSwapCardState extends State<PublicidadSwapCard> with SingleTickerProviderStateMixin {
  late AnimationController _timerController;

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener((status) {
        // 🔥 Solo dispara el swipe si el tiempo se acaba Y la carta está al frente
        if (status == AnimationStatus.completed && widget.isFrontCard) {
          widget.onAutoDismiss();
        }
      });

    // Si por casualidad la carta nace estando ya de primera, arranca el timer
    if (widget.isFrontCard) {
      _timerController.forward();
    }
  }

  // 🔥 EL DESPERTADOR: Si estaba escondida y el usuario deslizó, ahora quedó de primera.
  @override
  void didUpdateWidget(PublicidadSwapCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isFrontCard && widget.isFrontCard) {
      // Pasó del fondo al frente: ¡Arranca los 5 segundos!
      _timerController.forward();
    }
  }

  @override
  void dispose() {
    _timerController.dispose();
    super.dispose();
  }

  void _cerrarManualmente() {
    if (!widget.isFrontCard) return; // Si está escondida, no se puede tocar
    if (_timerController.isAnimating) {
      _timerController.stop();
    }
    widget.onAutoDismiss();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.totalHeight,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(24.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 12,
            offset: Offset(0, 6),
          )
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: widget.imageUrl,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            memCacheHeight: 800,
            placeholder: (context, url) => Container(
              color: const Color(0xFF1A1A1A),
              alignment: Alignment.center,
              child: const SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Color(0xFFBEB3FF),
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: const Color(0xFF1A1A1A),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, color: Colors.white24, size: 50),
                  SizedBox(height: 10),
                  Text("Anuncio no disponible", style: TextStyle(color: Colors.white24, fontFamily: 'Poppins')),
                ],
              ),
            ),
          ),

          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white12, width: 1),
                borderRadius: BorderRadius.circular(24.0),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                    Colors.black.withOpacity(0.5),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),

          // 🔥 BOTÓN X Y TIMER VISUAL
          Positioned(
            top: 16,
            right: 16,
            child: GestureDetector(
              onTap: _cerrarManualmente,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 42,
                      height: 42,
                      child: CircularProgressIndicator(
                        value: 1.0 - _timerController.value,
                        strokeWidth: 2.5,
                        backgroundColor: Colors.transparent,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFBEB3FF)),
                      ),
                    ),
                    const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
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