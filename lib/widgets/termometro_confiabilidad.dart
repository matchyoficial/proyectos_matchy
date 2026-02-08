// 📂 lib/widgets/termometro_confiabilidad.dart
import 'dart:async';
import 'package:flutter/material.dart';

class TermometroConfiabilidad extends StatefulWidget {
  final int puntaje;
  final DateTime? fechaDesbloqueo;
  final bool mostrarReloj;

  const TermometroConfiabilidad({
    super.key,
    this.puntaje = 100,
    this.fechaDesbloqueo,
    this.mostrarReloj = true,
  });

  @override
  State<TermometroConfiabilidad> createState() => _TermometroConfiabilidadState();
}

class _TermometroConfiabilidadState extends State<TermometroConfiabilidad> {
  static const double kAlturaCajasNegras = 85.0;
  static const double kSizeTituloPequeno = 12.0;
  static const double kSizePorcentaje = 16.0;
  static const double kSizeRelojNumeros = 20.0;
  static const double kSizeRelojLabels = 8.0;
  static const double kSizeEstadoAbajo = 10.0;

  late Timer _timer;
  String _d = "00", _h = "00", _m = "00";
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
  void dispose() { _timer.cancel(); super.dispose(); }

  void _calcularTiempo() {
    if (widget.fechaDesbloqueo == null) { _resetReloj(); return; }
    final now = DateTime.now();
    final difference = widget.fechaDesbloqueo!.difference(now);
    if (difference.isNegative) { _resetReloj(); }
    else {
      setState(() {
        _estaRestringido = true;
        _d = difference.inDays.toString().padLeft(2, '0');
        _h = (difference.inHours % 24).toString().padLeft(2, '0');
        _m = (difference.inMinutes % 60).toString().padLeft(2, '0');
      });
    }
  }

  void _resetReloj() {
    if (_estaRestringido || _d != "00") {
      setState(() { _estaRestringido = false; _d = "00"; _h = "00"; _m = "00"; });
    }
  }

  Color _getColor(int score) {
    if (score >= 80) return const Color(0xFF00E676);
    if (score >= 50) return const Color(0xFFFFC107);
    if (score >= 20) return const Color(0xFFFF5722);
    return const Color(0xFFD50000);
  }

  Widget _buildBarraContainer(Color colorEstado, double anchoBarra) {
    return Container(
      height: kAlturaCajasNegras,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.85), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        FittedBox(fit: BoxFit.scaleDown, child: Row(children: [Text("PUNTUALIDAD", style: TextStyle(color: Colors.white70, fontSize: kSizeTituloPequeno, fontWeight: FontWeight.w800, fontFamily: 'Poppins')), const SizedBox(width: 8), Text("${widget.puntaje}%", style: TextStyle(color: colorEstado, fontSize: kSizePorcentaje, fontWeight: FontWeight.w900, fontFamily: 'Poppins'))])),
        const SizedBox(height: 10),
        SizedBox(height: 10, child: Stack(children: [Container(width: double.infinity, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(6))), LayoutBuilder(builder: (context, constraints) { return AnimatedContainer(duration: const Duration(milliseconds: 800), curve: Curves.easeOutQuart, width: constraints.maxWidth * anchoBarra, decoration: BoxDecoration(color: colorEstado, borderRadius: BorderRadius.circular(6), boxShadow: [BoxShadow(color: colorEstado.withOpacity(0.6), blurRadius: 8)])); })])),
      ]),
    );
  }

  Widget _buildRelojContainer(Color colorReloj, String textoEstado) {
    return Container(
      height: kAlturaCajasNegras,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.85), borderRadius: BorderRadius.circular(20), border: Border.all(color: colorReloj.withOpacity(0.2))),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        FittedBox(fit: BoxFit.scaleDown, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _unit(_d, "DÍAS", colorReloj), _sep(colorReloj), _unit(_h, "HORAS", colorReloj), _sep(colorReloj), _unit(_m, "MIN", colorReloj),
        ])),
        const SizedBox(height: 6),
        FittedBox(fit: BoxFit.scaleDown, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)), child: Row(children: [Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: colorReloj, boxShadow: [BoxShadow(color: colorReloj, blurRadius: 4)])), const SizedBox(width: 6), Text(textoEstado, style: TextStyle(color: colorReloj, fontSize: kSizeEstadoAbajo, fontWeight: FontWeight.bold, fontFamily: 'Poppins'))]))),
      ]),
    );
  }

  Widget _unit(String v, String l, Color c) => Column(children: [Text(v, style: TextStyle(color: c, fontSize: kSizeRelojNumeros, fontWeight: FontWeight.w900, fontFamily: 'monospace', height: 1.0)), Text(l, style: TextStyle(color: Colors.white38, fontSize: kSizeRelojLabels, fontWeight: FontWeight.bold, fontFamily: 'Poppins'))]);
  Widget _sep(Color c) => Padding(padding: const EdgeInsets.only(bottom: 10, left: 2, right: 2), child: Text(":", style: TextStyle(color: c.withOpacity(0.5), fontSize: 16, fontWeight: FontWeight.bold)));

  @override
  Widget build(BuildContext context) {
    final colorEstado = _getColor(widget.puntaje);
    final colorReloj = _estaRestringido ? const Color(0xFFFF5252) : const Color(0xFF76FF03);
    final textoEstado = _estaRestringido ? "BLOQUEADO" : "SIN BLOQUEO";
    final double anchoBarra = (widget.puntaje / 100).clamp(0.0, 1.0);
    return Container(width: double.infinity, margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5), padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0x4FFFFFFF), borderRadius: BorderRadius.circular(26), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 5))]), child: widget.mostrarReloj ? Row(children: [Expanded(flex: 52, child: _buildBarraContainer(colorEstado, anchoBarra)), const SizedBox(width: 8), Expanded(flex: 48, child: _buildRelojContainer(colorReloj, textoEstado))]) : _buildBarraContainer(colorEstado, anchoBarra));
  }
}