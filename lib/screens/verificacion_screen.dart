// 📂 lib/screens/verificacion_screen.dart
// ✅ ESCÁNER BIOMÉTRICO BLINDADO (MATCHY OS)
// 🔥 UI: Diseño FaceID con máscara circular y fondo oscuro.
// 🔥 LÓGICA: Captura en Base64 sin saturar almacenamiento.
// 🔥 CONEXIÓN: Apunta a southamerica-east1 (Brasil) para baja latencia.

import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:proyectos_matchy/widgets/matchy_back_button.dart';

class VerificacionScreen extends StatefulWidget {
  const VerificacionScreen({super.key});

  @override
  State<VerificacionScreen> createState() => _VerificacionScreenState();
}

class _VerificacionScreenState extends State<VerificacionScreen> with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;

  // Animación del escáner láser
  late AnimationController _animationController;
  late Animation<double> _laserAnimation;

  @override
  void initState() {
    super.initState();
    _initCamera();

    _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _laserAnimation = Tween<double>(begin: -150, end: 150).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOutSine)
    );
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      // Buscar la cámara frontal
      final frontCamera = cameras.firstWhere(
            (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first, // Fallback si no hay frontal
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium, // Resolución media para que el Base64 no pese demasiado
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();
      if (mounted) setState(() => _isCameraInitialized = true);
    } catch (e) {
      _showMatchyBubble("Error al iniciar la cámara. Verifica los permisos.", isError: true);
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _showMatchyBubble(String mensaje, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 4),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isError
                  ? [const Color(0xFFFF4D6D), const Color(0xFFB71C1C)]
                  : [const Color(0xFF00B4DB), const Color(0xFF0083B0)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 5))],
            border: Border.all(color: Colors.white24, width: 1),
          ),
          child: Row(
            children: [
              Icon(isError ? Icons.warning_amber_rounded : Icons.check_circle_outline, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  mensaje,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Poppins'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _capturarYVerificar() async {
    if (!_isCameraInitialized || _cameraController == null || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _animationController.repeat(reverse: true); // Iniciar láser
    });

    try {
      // 1. Tomar foto
      final XFile imageFile = await _cameraController!.takePicture();

      // 2. Convertir a Base64
      final bytes = await File(imageFile.path).readAsBytes();
      final base64Image = base64Encode(bytes);

      // 3. Llamar a la Cloud Function en BRASIL
      final HttpsCallable callable = FirebaseFunctions.instanceFor(region: 'southamerica-east1').httpsCallable('verificarIdentidad');

      final response = await callable.call({
        'selfieBase64': base64Image,
      });

      final result = response.data as Map<dynamic, dynamic>;

      if (result['success'] == true) {
        // 🔥 MATCH BIOMÉTRICO EXITOSO
        if (!mounted) return;
        _animationController.stop();
        _showMatchyBubble(result['message'] ?? "¡Identidad Verificada!", isError: false);

        // Retraso para que el usuario lea la burbuja y luego lo devolvemos
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.pop(context, true); // Devuelve true para avisarle a la pantalla anterior

      } else {
        // 🔴 FALLO DE RECONOCIMIENTO
        if (!mounted) return;
        setState(() {
          _isProcessing = false;
          _animationController.stop();
        });
        _showMatchyBubble(result['message'] ?? "No coincidimos. Intenta de nuevo.", isError: true);
      }

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _animationController.stop();
      });
      _showMatchyBubble("Error en el escáner. Asegúrate de tener buena luz.", isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. CÁMARA DE FONDO
          if (_isCameraInitialized)
            SizedBox(
              width: size.width,
              height: size.height,
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _cameraController!.value.previewSize?.height ?? size.width,
                  height: _cameraController!.value.previewSize?.width ?? size.height,
                  child: CameraPreview(_cameraController!),
                ),
              ),
            )
          else
            const Center(child: CircularProgressIndicator(color: Color(0xFFBEB3FF))),

          // 2. OVERLAY OSCURO CON HUECO CIRCULAR
          ColorFiltered(
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.85), BlendMode.srcOut),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    height: 300,
                    width: 300,
                    decoration: BoxDecoration(
                      color: Colors.red, // Este color se vuelve transparente por el BlendMode
                      borderRadius: BorderRadius.circular(150),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. ANILLO Y LÁSER
          Align(
            alignment: Alignment.center,
            child: Container(
              height: 300,
              width: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(150),
                border: Border.all(color: const Color(0xFFBEB3FF).withOpacity(0.5), width: 3),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(150),
                child: Stack(
                  children: [
                    if (_isProcessing)
                      AnimatedBuilder(
                        animation: _laserAnimation,
                        builder: (context, child) {
                          return Positioned(
                            top: 150 + _laserAnimation.value,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00B4DB),
                                boxShadow: [
                                  BoxShadow(color: const Color(0xFF00B4DB).withOpacity(0.8), blurRadius: 15, spreadRadius: 5)
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),

          // 4. TEXTOS Y BOTONES
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                Image.asset('assets/images/logomatchyplano.png', height: 40),
                const SizedBox(height: 30),
                const Text(
                  "VERIFICACIÓN BIOMÉTRICA",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5, fontFamily: 'Poppins'),
                ),
                const SizedBox(height: 10),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    "Encuadra tu rostro en el círculo. Asegúrate de tener buena luz y quítate las gafas o accesorios.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
                  ),
                ),
                const Spacer(),

                // BOTÓN DE CAPTURA
                Padding(
                  padding: const EdgeInsets.only(bottom: 50),
                  child: GestureDetector(
                    onTap: _capturarYVerificar,
                    child: Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        color: _isProcessing ? Colors.white24 : Colors.transparent,
                      ),
                      child: Center(
                        child: Container(
                          height: _isProcessing ? 30 : 60,
                          width: _isProcessing ? 30 : 60,
                          decoration: BoxDecoration(
                            shape: _isProcessing ? BoxShape.rectangle : BoxShape.circle,
                            borderRadius: _isProcessing ? BorderRadius.circular(5) : null,
                            color: _isProcessing ? const Color(0xFFBEB3FF) : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const MatchyBackButton(top: 10, left: 16),
        ],
      ),
    );
  }
}