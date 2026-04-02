// 📂 lib/screens/custom_cropper_screen.dart
// ✅ VERSIÓN FINAL BLINDADA - UX PREMIUM & LIENZO COMPLETO
// 🛡️ FIX UX: Lienzo en BoxFit.contain (Fotos horizontales completas con fondo negro).
// 🚀 FIX PESO: pixelRatio reducido a 1.5 para garantizar peso < 5MB (Para Amazon).
// 🛠️ LÓGICA: Libertad total de paneo y zoom desde la vista original.

import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:typed_data';

class CustomCropperScreen extends StatefulWidget {
  final String imagePath;
  const CustomCropperScreen({super.key, required this.imagePath});

  @override
  State<CustomCropperScreen> createState() => _CustomCropperScreenState();
}

class _CustomCropperScreenState extends State<CustomCropperScreen> {
  final GlobalKey _boundaryKey = GlobalKey();

  // 🛠️ FIX UX: Empezamos en escala 1.0 (Sin zoom forzado) y sin offset.
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  double _baseScale = 1.0;
  Offset _baseOffset = Offset.zero;

  bool _isSaving = false;
  bool _showGrid = true;

  // 💾 LÓGICA DE GUARDADO OPTIMIZADA
  Future<void> _saveImage() async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
      _showGrid = false; // Ocultamos la cuadrícula para la captura limpia
    });

    try {
      await Future.delayed(const Duration(milliseconds: 50));
      RenderRepaintBoundary? boundary =
      _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      // 🚀 FIX PESO: pixelRatio 1.5 genera una imagen HD perfecta para móviles,
      // pero con un peso de ~1MB, evitando que Amazon (límite 5MB) colapse.
      ui.Image image = await boundary.toImage(pixelRatio: 1.5);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final tempDir = Directory.systemTemp;
      // Guardamos como PNG real, el Gestor de Fotos se encargará de subirlo.
      final file = File('${tempDir.path}/matchy_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);

      if (mounted) Navigator.pop(context, file.path);
    } catch (e) {
      debugPrint("Error al guardar: $e");
      setState(() => _showGrid = true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.cyanAccent),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text("ENCUADRA TU FOTO",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // ℹ️ INSTRUCCIONES PREMIUM (Con texto destacado en Naranja/Amarillo)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFBEB3FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFBEB3FF).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.pinch_rounded, color: Color(0xFFBEB3FF), size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: const [
                            TextSpan(
                              text: "Usa tus dedos para hacer zoom y mover la foto. Lo que quede dentro del marco es tu foto final.\n\n",
                              style: TextStyle(color: Colors.white),
                            ),
                            TextSpan(
                              text: "AJUSTA LA FOTO HASTA QUE DESAPAREZCAN LOS BORDES VERDES PARA QUE TU FOTO SE ACOMODE PERFECTO.",
                              style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        style: const TextStyle(fontSize: 10, height: 1.3),
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 📸 ÁREA DE RECORTE (LIENZO COMPLETO)
            Expanded(
              child: Center(
                child: RepaintBoundary(
                  key: _boundaryKey,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    height: (MediaQuery.of(context).size.width * 0.85) * 1.25,
                    decoration: BoxDecoration(
                      color: Colors.black, // Fondo negro puro para las franjas
                      border: Border.all(color: Colors.cyanAccent.withOpacity(0.5), width: 2),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: GestureDetector(
                      onScaleStart: (details) {
                        _baseScale = _scale;
                        _baseOffset = details.focalPoint - _offset;
                      },
                      onScaleUpdate: (details) {
                        setState(() {
                          _scale = (_baseScale * details.scale).clamp(1.0, 5.0);
                          _offset = details.focalPoint - _baseOffset;
                        });
                      },
                      child: Stack(
                        children: [
                          Transform(
                            transform: Matrix4.identity()
                              ..translate(_offset.dx, _offset.dy)
                              ..scale(_scale),
                            // 🛠️ FIX UX: BoxFit.contain garantiza que la foto horizontal llegue completa
                            child: Image.file(
                              File(widget.imagePath),
                              fit: BoxFit.contain,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                          if (_showGrid)
                            IgnorePointer(
                              child: CustomPaint(
                                size: Size.infinite,
                                painter: GridPainter(),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 🎛️ CONTROLES INFERIORES
            Container(
              padding: const EdgeInsets.fromLTRB(25, 20, 25, 40),
              decoration: const BoxDecoration(
                color: Color(0xFF0A0A0A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, -5))],
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    Container(
                      height: 80,
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                          color: const Color(0xFF151515),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.white10)
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "AJUSTAR ZOOM: ${(_scale * 100).toInt()}%",
                            style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1),
                          ),
                          SliderTheme(
                            data: const SliderThemeData(
                              trackHeight: 2,
                              activeTrackColor: Colors.orangeAccent,
                              inactiveTrackColor: Colors.white12,
                              thumbColor: Colors.orangeAccent,
                              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
                            ),
                            child: Slider(
                              value: _scale.clamp(1.0, 5.0),
                              min: 1.0,
                              max: 5.0,
                              onChanged: (v) => setState(() => _scale = v),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),

                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              height: 55,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: Colors.white38),
                              ),
                              alignment: Alignment.center,
                              child: const Text("CANCELAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: GestureDetector(
                            onTap: _saveImage,
                            child: Container(
                              height: 55,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFFBEB3FF)]),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: const [BoxShadow(color: Colors.cyanAccent, blurRadius: 10, spreadRadius: -2)],
                              ),
                              alignment: Alignment.center,
                              child: _isSaving
                                  ? const SizedBox(width: 25, height: 25, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3))
                                  : const Text("CORTAR FOTO", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, letterSpacing: 1)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.3)..strokeWidth = 1.0;
    for (var i = 1; i < 3; i++) {
      canvas.drawLine(Offset(size.width * i / 3, 0), Offset(size.width * i / 3, size.height), paint);
      canvas.drawLine(Offset(0, size.height * i / 3), Offset(size.width, size.height * i / 3), paint);
    }
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}