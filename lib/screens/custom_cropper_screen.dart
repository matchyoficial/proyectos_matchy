// 📂 lib/screens/custom_cropper_screen.dart
// ✅ VERSIÓN FINAL BLINDADA - MATCHY PREMIUM
// 🛠️ FIX: Las líneas guía desaparecen al guardar (Foto limpia).
// 🛠️ FIX: Zoom y Movimiento 100% funcionales.
// 🛠️ FIX TOTAL: Foto cargada con escala 1.05 y CENTRADA matemáticamente para eliminar líneas blancas en los 4 bordes.

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

  double _scale = 1.05; // Sangrado ideal
  Offset _offset = Offset.zero;
  double _baseScale = 1.0;
  Offset _baseOffset = Offset.zero;

  bool _isSaving = false;
  bool _showGrid = true;
  bool _initialized = false; // 🔥 Control para centrado inicial

  // 💾 LÓGICA DE GUARDADO
  Future<void> _saveImage() async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
      _showGrid = false;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 50));
      RenderRepaintBoundary? boundary =
      _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final tempDir = Directory.systemTemp;
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
    // 🛡️ CENTRADO AUTOMÁTICO EN EL PRIMER FRAME
    if (!_initialized) {
      final double width = MediaQuery.of(context).size.width * 0.85;
      final double height = width * 1.25;
      // Calculamos el desfase para centrar el zoom de 1.05
      // Se resta la mitad del excedente en X y Y
      _offset = Offset(
        -(width * (_scale - 1)) / 2,
        -(height * (_scale - 1)) / 2,
      );
      _initialized = true;
    }

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text("ENCUADRA TU FOTO",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFBEB3FF).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFBEB3FF).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.pinch_rounded, color: Color(0xFFBEB3FF), size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "Usa tus dedos o la regla para ajustar. Lo que brille dentro del cuadro es lo que se guardará.",
                        style: TextStyle(color: Colors.white, fontSize: 12, height: 1.3),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: Center(
                child: RepaintBoundary(
                  key: _boundaryKey,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    height: (MediaQuery.of(context).size.width * 0.85) * 1.25,
                    decoration: BoxDecoration(
                      color: const Color(0xFF111111),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: GestureDetector(
                      onScaleStart: (details) {
                        _baseScale = _scale;
                        _baseOffset = details.focalPoint - _offset;
                      },
                      onScaleUpdate: (details) {
                        setState(() {
                          _scale = (_baseScale * details.scale).clamp(1.01, 5.0);
                          _offset = details.focalPoint - _baseOffset;
                        });
                      },
                      child: Stack(
                        children: [
                          Transform(
                            transform: Matrix4.identity()
                              ..translate(_offset.dx, _offset.dy)
                              ..scale(_scale),
                            child: Image.file(
                              File(widget.imagePath),
                              fit: BoxFit.cover,
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

            Container(
              padding: const EdgeInsets.fromLTRB(25, 20, 25, 40),
              decoration: const BoxDecoration(
                color: Color(0xFF111111),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    Container(
                      height: 80,
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "AJUSTAR ZOOM: ${(_scale * 100).toInt()}%",
                            style: const TextStyle(color: Color(0xFFFF9800), fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                          SliderTheme(
                            data: const SliderThemeData(
                              trackHeight: 2,
                              activeTrackColor: Colors.black12,
                              thumbColor: Color(0xFFFF9800),
                              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
                            ),
                            child: Slider(
                              value: _scale.clamp(1.01, 5.0),
                              min: 1.01,
                              max: 5.0,
                              onChanged: (v) => setState(() => _scale = v),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(21, (i) => Container(width: 1, height: i % 5 == 0 ? 10 : 5, color: Colors.black26)),
                          )
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
                                gradient: const LinearGradient(colors: [Color(0xFFBEB3FF), Color(0xFF8A80CC)]),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10)],
                              ),
                              alignment: Alignment.center,
                              child: _isSaving
                                  ? const SizedBox(width: 25, height: 25, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3))
                                  : const Text("ACEPTAR", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
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
    final paint = Paint()..color = Colors.white.withOpacity(0.4)..strokeWidth = 1.0;
    for (var i = 1; i < 3; i++) {
      canvas.drawLine(Offset(size.width * i / 3, 0), Offset(size.width * i / 3, size.height), paint);
      canvas.drawLine(Offset(0, size.height * i / 3), Offset(size.width, size.height * i / 3), paint);
    }
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}