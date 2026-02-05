// 📂 lib/widgets/termometro_confiabilidad.dart
import 'dart:async';
import 'package:flutter/material.dart';

class TermometroConfiabilidad extends StatefulWidget {
  final int puntaje; // 0 a 100
  final DateTime? fechaDesbloqueo; // Fecha exacta donde termina el castigo
  final bool mostrarReloj; // 🔥 NUEVO: Controla si se ve el reloj o solo la barra

  const TermometroConfiabilidad({
    super.key,
    this.puntaje = 100,
    this.fechaDesbloqueo,
    this.mostrarReloj = true, // Por defecto TRUE (para el Panel)
  });

  @override
  State<TermometroConfiabilidad> createState() => _TermometroConfiabilidadState();
}

class _TermometroConfiabilidadState extends State<TermometroConfiabilidad> {
  // -------------------------------------------------------------------------
  // 🔴🔴 ZONA DE CHINCHES MAESTROS (CONTROL TOTAL DE TAMAÑOS) 🔴🔴
  // -------------------------------------------------------------------------

  // 1. DIMENSIONES GENERALES
  static const double kAlturaCajasNegras = 85.0; // Altura de las cajas

  // 2. TAMAÑOS DE FUENTE (FONT SIZE)
  static const double kSizeTituloPequeno = 14.0; // "PUNTUALIDAD"
  static const double kSizePorcentaje = 16.0;    // El número "100%"
  static const double kSizeReloj = 20.0;         // Los números del reloj "00:00:00"
  static const double kSizeEstadoAbajo = 11.0;   // Texto "SIN BLOQUEO" / "BLOQUEADO"

  // 3. ESPACIADO ENTRE LETRAS (LETTER SPACING)
  static const double kEspacioLetrasReloj = 1.5;
  static const double kEspacioLetrasTitulos = 0.5;

  // -------------------------------------------------------------------------

  late Timer _timer;
  String _tiempoRestante = "00:00:00";
  bool _estaRestringido = false;

  @override
  void initState() {
    super.initState();
    _calcularTiempo();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) _calcularTiempo();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _calcularTiempo() {
    if (widget.fechaDesbloqueo == null) {
      _resetReloj();
      return;
    }

    final now = DateTime.now();
    final difference = widget.fechaDesbloqueo!.difference(now);

    if (difference.isNegative) {
      _resetReloj();
    } else {
      setState(() {
        _estaRestringido = true;
        // Si falta más de 1 día: DD:HH:MM
        if (difference.inDays > 0) {
          final d = difference.inDays.toString().padLeft(2, '0');
          final h = (difference.inHours % 24).toString().padLeft(2, '0');
          final m = (difference.inMinutes % 60).toString().padLeft(2, '0');
          _tiempoRestante = "$d:$h:$m";
        } else {
          // Si falta menos de 1 día: HH:MM:SS
          final h = difference.inHours.toString().padLeft(2, '0');
          final m = (difference.inMinutes % 60).toString().padLeft(2, '0');
          final s = (difference.inSeconds % 60).toString().padLeft(2, '0');
          _tiempoRestante = "$h:$m:$s";
        }
      });
    }
  }

  void _resetReloj() {
    if (_estaRestringido || _tiempoRestante != "00:00:00") {
      setState(() {
        _estaRestringido = false;
        _tiempoRestante = "00:00:00";
      });
    }
  }

  Color _getColor(int score) {
    if (score >= 80) return const Color(0xFF00E676); // Verde
    if (score >= 50) return const Color(0xFFFFC107); // Amarillo
    if (score >= 20) return const Color(0xFFFF5722); // Naranja
    return const Color(0xFFD50000); // Rojo
  }

  // 🔹 WIDGET INTERNO: LA BARRA DE PUNTUALIDAD
  Widget _buildBarraContainer(Color colorEstado, double anchoBarra) {
    return Container(
      height: kAlturaCajasNegras,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "PUNTUALIDAD",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: kSizeTituloPequeno,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Poppins',
                  letterSpacing: kEspacioLetrasTitulos,
                ),
              ),
              Text(
                "${widget.puntaje}%",
                style: TextStyle(
                  color: colorEstado,
                  fontSize: kSizePorcentaje,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // BARRA DE PROGRESO
          SizedBox(
            height: 12,
            child: Stack(
              children: [
                // Fondo Gris
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                // Líquido de Color
                LayoutBuilder(
                  builder: (context, constraints) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutQuart,
                      width: constraints.maxWidth * anchoBarra,
                      decoration: BoxDecoration(
                        color: colorEstado,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: colorEstado.withOpacity(0.6),
                            blurRadius: 8,
                            spreadRadius: 1,
                          )
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 WIDGET INTERNO: EL RELOJ
  Widget _buildRelojContainer(Color colorReloj, String textoEstado) {
    return Container(
      height: kAlturaCajasNegras,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _tiempoRestante,
              style: TextStyle(
                  color: colorReloj,
                  fontSize: kSizeReloj,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                  letterSpacing: kEspacioLetrasReloj,
                  shadows: [
                    BoxShadow(color: colorReloj.withOpacity(0.5), blurRadius: 10)
                  ]
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorReloj,
                      boxShadow: [BoxShadow(color: colorReloj, blurRadius: 4)]
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  textoEstado,
                  style: TextStyle(
                    color: colorReloj,
                    fontSize: kSizeEstadoAbajo,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorEstado = _getColor(widget.puntaje);
    final colorReloj = _estaRestringido ? const Color(0xFFFF5252) : const Color(0xFF76FF03);
    final textoEstado = _estaRestringido ? "BLOQUEADO" : "SIN BLOQUEO";
    final double anchoBarra = (widget.puntaje / 100).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0x4FFFFFFF),
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 5))
        ],
      ),
      // 🔥 LÓGICA DE VISUALIZACIÓN
      child: widget.mostrarReloj
      // MODO 1: BARRA + RELOJ (Estilo Panel)
          ? Row(
        children: [
          Expanded(flex: 6, child: _buildBarraContainer(colorEstado, anchoBarra)),
          const SizedBox(width: 8),
          Expanded(flex: 4, child: _buildRelojContainer(colorReloj, textoEstado)),
        ],
      )
      // MODO 2: SOLO BARRA (Estilo Perfil)
          : _buildBarraContainer(colorEstado, anchoBarra),
    );
  }
}