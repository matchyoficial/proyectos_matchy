// 📂 lib/widgets/animacion_comunidad_ico.dart
// ✨ WIDGET DECORATIVO: mini-simulación en bucle del swipe de Comunidad, usada en panel_screen.dart
//    en reemplazo del ícono estático 'comunidad.png'. Cicla 8 fotos fijas (assets locales,
//    736x736), cada una con una dirección FIJA asignada (NO alterna): ico3 e ico5 siempre se
//    deslizan a la izquierda (rojo + ❌), las demás siempre a la derecha (verde + 💚). Orden del
//    ciclo confirmado: 8, 5, 6, 7, 4, 3, 2, 1 (vuelve a empezar al llegar al final).
// 🔒 Marco exterior: ÓVALO FIJO de tamaño exacto (widget.size), recortado con ClipOval.
// 🔍 Zoom/offset de encuadre (kZoomFoto=1.10, kOffsetVerticalFoto=0.0): SIN TOCAR, quedaron
//    exactamente como el usuario los ajustó.
// 🆕 V5 — 3 cambios:
//    1) TIMING DE INSIGNIAS CORREGIDO: antes el corazón/X aparecía recién cuando empezaba el
//       swipe y se quedaba fijo hasta el final. Ahora aparece EN SINCRONÍA con el destello de
//       color (sube junto con el borde encendiéndose) y se DESVANECE durante el swipe,
//       llegando a invisible justo cuando la foto termina de salir — forma de "campana", no de
//       "sube y se queda". Fórmula: badge = flashT * (1 - swipeT).
//    2) NUEVA "ZONA DE EDICIÓN — CORAZÓN / X": 4 constantes editables para tamaño, distancia al
//       borde, grosor de borde y relleno de la insignia, con el mismo estilo de comentarios que
//       la zona de zoom/offset ya existente.
//    3) CACHÉ INTELIGENTE: Image.asset ahora usa cacheWidth/cacheHeight calculados a partir del
//       tamaño real en pantalla (widget.size × densidad de píxeles del dispositivo × zoom), en
//       vez de decodificar los 8 PNGs a su resolución nativa completa (736x736) cada vez. Mismo
//       principio que memCacheHeight en las imágenes de red del resto de la app.
// 🎬 Secuencia de 3 fases por foto: NORMAL (~1.1s quieta) -> DESTELLO (~0.3s, borde y tinte de
//    color, sin moverse) -> SWIPE (~0.6s, se desliza en su dirección fija). Insignias en esquina
//    fija: corazón 💚 siempre arriba-derecha, X ❌ siempre arriba-izquierda. "Siguiente foto"
//    queda quieta detrás para que nunca se vea un hueco vacío.
// 🚫 Puramente decorativo: no escribe nada en Firestore, no depende de sesión ni de red.

import 'package:flutter/material.dart';

class _FotoCiclo {
  final String asset;
  final bool esPositivo; // true = derecha/verde/corazón arriba-derecha, false = izquierda/rojo/X arriba-izquierda
  const _FotoCiclo(this.asset, this.esPositivo);
}

class AnimacionComunidadIco extends StatefulWidget {
  final double size;
  const AnimacionComunidadIco({super.key, this.size = 130});

  @override
  State<AnimacionComunidadIco> createState() => _AnimacionComunidadIcoState();
}

class _AnimacionComunidadIcoState extends State<AnimacionComunidadIco> with SingleTickerProviderStateMixin {

  // ===========================================================================
  // 🎛️ ZONA DE AJUSTE — ENCUADRE DE LA FOTO (sin tocar, valores ya confirmados)
  // ===========================================================================

  // 🔍 kZoomFoto: qué tanto se acerca la imagen antes de recortarla en círculo.
  static const double kZoomFoto = 1.10;

  // ↕️ kOffsetVerticalFoto: sube o baja la foto dentro del marco circular.
  static const double kOffsetVerticalFoto = 0.0;

  // ===========================================================================
  // 🎛️ ZONA DE EDICIÓN — CORAZÓN / X
  // Toca estos 4 números para ajustar tamaño y posición de la insignia sin tocar el
  // resto del código. Guarda y haz HOT RESTART completo (no hot reload).
  // ===========================================================================

  // 💚❌ kTamanoIconoReaccion: qué tan grande se ve el corazón/X en sí (el ícono, no el círculo negro detrás).
  static const double kTamanoIconoReaccion = 15.0;

  // 📍 kDistanciaBordeInsignia: qué tan pegada está la insignia a la orilla del ícono.
  //    0 = tocando el borde exterior. Sube el número para alejarla más hacia el centro.
  static const double kDistanciaBordeInsignia = 15.5;

  // ⭕ kGrosorBordeInsignia: grosor del anillo de color alrededor del círculo negro de la insignia.
  static const double kGrosorBordeInsignia = 1.5;

  // 🔵 kRellenoInsignia: qué tan grande es el círculo negro detrás del corazón/X (espacio entre
  //    el ícono y su propio borde).
  static const double kRellenoInsignia = 5.0;

  // ===========================================================================

  // 🎯 Orden y dirección fija por foto (confirmado): 8,5,6,7,4,3,2,1
  static const List<_FotoCiclo> _fotos = [
    _FotoCiclo('assets/images/comunidad_ico8.png', true),
    _FotoCiclo('assets/images/comunidad_ico5.png', false),
    _FotoCiclo('assets/images/comunidad_ico6.png', true),
    _FotoCiclo('assets/images/comunidad_ico7.png', true),
    _FotoCiclo('assets/images/comunidad_ico4.png', true),
    _FotoCiclo('assets/images/comunidad_ico3.png', false),
    _FotoCiclo('assets/images/comunidad_ico2.png', true),
    _FotoCiclo('assets/images/comunidad_ico1.png', true),
  ];

  // ⏱️ Ritmo total ~2s por foto: 1.1s quieta + 0.9s de "destello + swipe"
  static const Duration kPausaNormal = Duration(milliseconds: 1100);
  static const Duration kDuracionActiva = Duration(milliseconds: 900);
  // 🔥 De esos 900ms, el destello ocupa el primer tercio (~300ms) y el swipe el resto (~600ms)
  static const double kCorteDestello = 1 / 3;

  late final AnimationController _controller;
  late final Animation<double> _flash; // 0->1 durante el destello, se QUEDA en 1 durante el swipe
  late final Animation<double> _swipe; // 0 durante el destello, 0->1 durante el swipe
  int _index = 0;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: kDuracionActiva);
    _flash = CurvedAnimation(parent: _controller, curve: const Interval(0.0, kCorteDestello, curve: Curves.easeOut));
    _swipe = CurvedAnimation(parent: _controller, curve: const Interval(kCorteDestello, 1.0, curve: Curves.easeOutCubic));
    _iniciarCiclo();
  }

  Future<void> _iniciarCiclo() async {
    while (!_disposed) {
      // FASE 1: NORMAL — quieta, sin color
      await Future.delayed(kPausaNormal);
      if (_disposed || !mounted) return;

      // FASE 2 + 3: DESTELLO -> SWIPE, en una sola pasada continua del controlador
      await _controller.forward(from: 0);
      if (_disposed || !mounted) return;

      // 🔒 Reseteamos y avanzamos el índice en el mismo instante, sin await entre medio,
      // para que la siguiente foto aparezca ya centrada y neutra, sin parpadeo visible.
      _controller.value = 0;
      setState(() {
        _index = (_index + 1) % _fotos.length;
      });
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _controller.dispose();
    super.dispose();
  }

  // 🆕 CACHÉ INTELIGENTE: tamaño de decodificación en píxeles físicos, calculado a partir del
  // tamaño real en pantalla (con margen por el zoom aplicado), en vez de decodificar los PNGs
  // a su resolución nativa completa (736x736).
  int _calcularCacheSizePx(BuildContext context) {
    final double dpr = MediaQuery.of(context).devicePixelRatio;
    return (widget.size * dpr * kZoomFoto).ceil();
  }

  // 🔍 FIX DE ENCUADRE: la imagen se escala (kZoomFoto) y se desplaza verticalmente
  // (kOffsetVerticalFoto) ANTES de recortarla en círculo.
  Widget _fotoBase(String asset, int cacheSizePx) {
    return Transform.translate(
      offset: const Offset(0, kOffsetVerticalFoto),
      child: Transform.scale(
        scale: kZoomFoto,
        child: Image.asset(
          asset,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          cacheWidth: cacheSizePx,
          cacheHeight: cacheSizePx,
          errorBuilder: (_, __, ___) => Container(color: Colors.black26, child: const Icon(Icons.person, color: Colors.white38)),
        ),
      ),
    );
  }

  Widget _capaFoto({required String asset, required Color colorBorde, required double anchoBorde, required int cacheSizePx}) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: colorBorde, width: anchoBorde),
      ),
      child: ClipOval(child: _fotoBase(asset, cacheSizePx)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final actual = _fotos[_index];
    final siguiente = _fotos[(_index + 1) % _fotos.length];
    final double signo = actual.esPositivo ? 1 : -1;
    final Color colorReaccion = actual.esPositivo ? const Color(0xFF63FF68) : const Color(0xFFFF6E63);
    final IconData iconoReaccion = actual.esPositivo ? Icons.favorite_rounded : Icons.close_rounded;
    final int cacheSizePx = _calcularCacheSizePx(context);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      // 🔒 Ventana sellada: nada de lo que pase adentro puede pintarse fuera de este óvalo.
      child: ClipOval(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Capa de fondo: siguiente foto del ciclo, quieta, en reposo.
            _capaFoto(asset: siguiente.asset, colorBorde: Colors.white24, anchoBorde: 2, cacheSizePx: cacheSizePx),

            // Capa animada: foto actual, pasando por sus 3 fases.
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final double flashT = _flash.value;
                final double swipeT = _swipe.value;

                final double dx = signo * widget.size * swipeT;
                final double angulo = signo * 0.22 * swipeT;
                final double anchoBorde = 2 + (3 * flashT);
                final Color colorBorde = Color.lerp(Colors.white24, colorReaccion, flashT) ?? Colors.white24;
                final double overlayDestello = flashT * (1 - swipeT) * 0.5;
                // 🆕 FIX: la insignia ahora sube EN SINCRONÍA con el destello y se desvanece
                // durante el swipe — misma fórmula "campana" que el tinte de color, sin el
                // amortiguador *0.5 (para que se vea con opacidad completa en su punto máximo).
                final double badge = flashT * (1 - swipeT);

                return Transform.translate(
                  offset: Offset(dx, 0),
                  child: Transform.rotate(
                    angle: angulo,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _capaFoto(asset: actual.asset, colorBorde: colorBorde, anchoBorde: anchoBorde, cacheSizePx: cacheSizePx),

                        if (overlayDestello > 0)
                          IgnorePointer(
                            child: ClipOval(child: Container(color: colorReaccion.withOpacity(overlayDestello))),
                          ),

                        // Insignia en esquina FIJA por tipo de reacción:
                        // corazón siempre arriba-DERECHA, X siempre arriba-IZQUIERDA.
                        if (badge > 0)
                          Positioned(
                            top: kDistanciaBordeInsignia,
                            right: actual.esPositivo ? kDistanciaBordeInsignia : null,
                            left: actual.esPositivo ? null : kDistanciaBordeInsignia,
                            child: Opacity(
                              opacity: badge.clamp(0.0, 1.0),
                              child: Transform.scale(
                                scale: 0.6 + 0.4 * badge,
                                child: Container(
                                  padding: EdgeInsets.all(kRellenoInsignia),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.65),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: colorReaccion, width: kGrosorBordeInsignia),
                                  ),
                                  child: Icon(iconoReaccion, color: colorReaccion, size: kTamanoIconoReaccion),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}