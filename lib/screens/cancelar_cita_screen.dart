// 📂 lib/screens/cancelar_cita_screen.dart
// ✅ PANTALLA DE CANCELACIÓN (DISEÑO FINAL)
// 🔥 UI: Logo Matchy, Botón Rojo de Castigo y Mini-Termómetro en tiempo real.
// 🔥 CONTROL: Zona de Chinches Maestros para ajustar tamaños y espacios.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:proyectos_matchy/screens/home_shell.dart';
import 'package:proyectos_matchy/screens/reprogramar_cita_screen.dart'; // Asegúrate de tener este import o ajustarlo

class CancelarCitaScreen extends StatefulWidget {
  final String citaId;
  final String otherUserId;

  const CancelarCitaScreen({
    super.key,
    required this.citaId,
    required this.otherUserId
  });

  @override
  State<CancelarCitaScreen> createState() => _CancelarCitaScreenState();
}

class _CancelarCitaScreenState extends State<CancelarCitaScreen> {
  // ===========================================================================
  // 🔴🔴 ZONA DE CHINCHES MAESTROS (AJUSTA TU DISEÑO AQUÍ) 🔴🔴
  // ===========================================================================

  // 1. LOGO MATCHY
  static const double kLogoTopMargin        = 6.0; // Distancia del techo al logo
  static const double kLogoHeight           = 40.0; // Tamaño del logo Matchy

  // 2. ICONO DE ADVERTENCIA (TRIÁNGULO)
  static const double kIconoWarningTopGap   = 30.0; // Espacio entre Logo y Triángulo
  static const double kIconoWarningSize     = 75.0; // Tamaño del icono (triángulo)
  static const double kCirculoWarningSize   = 20.0; // Padding del circulo rojo alrededor

  // 3. TEXTOS PRINCIPALES
  static const double kTituloFontSize       = 36.0; // "¿ESTÁS SEGURO?"
  static const double kTituloTopGap         = 25.0; // Espacio arriba del título
  static const double kDescripcionFontSize  = 18.0; // Texto explicativo
  static const double kDescripcionTopGap    = 15.0; // Espacio arriba de descripción

  // 4. CÁPSULA NEGRA (PENALIDAD + TERMÓMETRO)
  static const double kCapsulaTopGap        = 35.0; // Separación de la cápsula
  static const double kCapsulaPadding       = 16.0; // Relleno interno
  static const double kMiniTermoHeight      = 8.0;  // Grosor de la barrita del mini termómetro

  // 5. BOTÓN REPROGRAMAR (VERDE)
  static const double kBotonReproTopGap     = 27.0; // Subir o bajar el botón verde
  static const double kBotonReproHeight     = 55.0; // Altura del botón
  static const double kBotonReproFontSize   = 16.0; // Tamaño letra

  // 6. TEXTO INFERIOR ("Si reprogramas...")
  static const double kTextoInfoFontSize    = 19.0;
  static const double kTextoInfoTopGap      = 12.0;

  // 7. BOTÓN PENALIDAD (ROJO)
  static const double kBotonRojoTopGap      = 43.0; // Separación del botón rojo
  static const double kBotonRojoHeight      = 50.0; // Altura botón rojo
  static const double kBotonRojoFontSize    = 14.0; // Tamaño letra botón rojo

  // ===========================================================================

  bool _isLoading = false;

  // Lógica de Castigo (-10%)
  Future<void> _ejecutarCancelacion() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final citaRef = FirebaseFirestore.instance.collection('citas').doc(widget.citaId);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userSnapshot = await transaction.get(userRef);

        int currentScore = (userSnapshot.data()?['confiabilidad'] as num?)?.toInt() ?? 100;
        int newScore = (currentScore - 10).clamp(0, 100);

        transaction.update(userRef, {
          'confiabilidad': newScore,
        });

        transaction.update(citaRef, {
          'status': 'cancelled',
          'canceladoPor': user.uid,
          'canceladoAt': FieldValue.serverTimestamp(),
        });
      });

      if (mounted) {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeShell(initialIndex: 0)),
                (route) => false
        );
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Cita cancelada. Tu confiabilidad ha disminuido."),
              backgroundColor: Color(0xFFD50000),
            )
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
        setState(() => _isLoading = false);
      }
    }
  }

  // Helper para color del termómetro
  Color _getScoreColor(int score) {
    if (score >= 80) return const Color(0xFF00E676);
    if (score >= 50) return const Color(0xFFFFC107);
    if (score >= 20) return const Color(0xFFFF5722);
    return const Color(0xFFD50000);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Fondo sutil
          Positioned.fill(
            child: Opacity(
              opacity: 0.3,
              child: Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover),
            ),
          ),

          SafeArea(
            child: StreamBuilder<DocumentSnapshot>(
                stream: user != null
                    ? FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots()
                    : null,
                builder: (context, snapshot) {
                  // Obtener puntaje en tiempo real
                  int myScore = 100;
                  if (snapshot.hasData && snapshot.data != null) {
                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                    myScore = (data?['confiabilidad'] as num?)?.toInt() ?? 100;
                  }

                  return Column(
                    children: [
                      // 1. HEADER (Botón X y Logo Matchy)
                      Padding(
                        padding: const EdgeInsets.only(top: kLogoTopMargin, left: 10, right: 10),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Botón Atrás
                            Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                            // Logo Matchy
                            Image.asset('assets/images/logomatchyplano.png', height: kLogoHeight),
                          ],
                        ),
                      ),

                      // CONTENIDO SCROLLEABLE (Para pantallas pequeñas)
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            children: [
                              SizedBox(height: kIconoWarningTopGap),

                              // 2. ICONO ADVERTENCIA
                              Container(
                                padding: const EdgeInsets.all(kCirculoWarningSize),
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFFD50000).withOpacity(0.1),
                                    border: Border.all(color: const Color(0xFFD50000), width: 2),
                                    boxShadow: [BoxShadow(color: const Color(0xFFD50000).withOpacity(0.2), blurRadius: 15)]
                                ),
                                child: Icon(
                                  Icons.warning_amber_rounded,
                                  color: const Color(0xFFD50000),
                                  size: kIconoWarningSize,
                                ),
                              ),

                              SizedBox(height: kTituloTopGap),

                              // 3. TEXTOS
                              Text(
                                "¿ESTÁS SEGURO?",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: kTituloFontSize,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Poppins',
                                  letterSpacing: 1.0,
                                ),
                              ),
                              SizedBox(height: kDescripcionTopGap),
                              Text(
                                "Cancelar esta cita afectará negativamente tu reputación en la comunidad Matchy.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: kDescripcionFontSize,
                                  height: 1.5,
                                ),
                              ),

                              SizedBox(height: kCapsulaTopGap),

                              // 4. CÁPSULA NEGRA + MINI TERMÓMETRO
                              Container(
                                padding: const EdgeInsets.all(kCapsulaPadding),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1F1F1F),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white12),
                                  boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4))],
                                ),
                                child: Column(
                                  children: [
                                    // Fila Superior: Icono y Texto Penalidad
                                    Row(
                                      children: [
                                        const Icon(Icons.trending_down, color: Color(0xFFFF5252), size: 32),
                                        const SizedBox(width: 15),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: const [
                                              Text(
                                                "PENALIDAD AUTOMÁTICA",
                                                style: TextStyle(color: Color(0xFFFF5252), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                              ),
                                              SizedBox(height: 2),
                                              Text(
                                                "-10% de Confiabilidad",
                                                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 15),
                                    Divider(color: Colors.white.withOpacity(0.1), height: 1),
                                    const SizedBox(height: 15),

                                    // Sección Mini Termómetro
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text("Tu nivel actual:", style: TextStyle(color: Colors.white54, fontSize: 12)),
                                        Text("$myScore%", style: TextStyle(color: _getScoreColor(myScore), fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    // Barrita Visual
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(5),
                                      child: SizedBox(
                                        height: kMiniTermoHeight,
                                        child: LinearProgressIndicator(
                                          value: myScore / 100,
                                          backgroundColor: Colors.white10,
                                          valueColor: AlwaysStoppedAnimation<Color>(_getScoreColor(myScore)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: kBotonReproTopGap),

                              // 5. BOTÓN REPROGRAMAR (VERDE)
                              SizedBox(
                                width: double.infinity,
                                height: kBotonReproHeight,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00E676),
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                    elevation: 8,
                                    shadowColor: const Color(0xFF00E676).withOpacity(0.4),
                                  ),
                                  onPressed: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => ReprogramarCitaScreen(citaId: widget.citaId)));
                                  },
                                  child: Text(
                                    "REPROGRAMAR CITA",
                                    style: TextStyle(fontSize: kBotonReproFontSize, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                                  ),
                                ),
                              ),

                              SizedBox(height: kTextoInfoTopGap),
                              Text(
                                "Si reprogramas, no perderás puntos.",
                                style: TextStyle(color: Colors.white54, fontSize: kTextoInfoFontSize),
                              ),

                              SizedBox(height: kBotonRojoTopGap),

                              // 6. BOTÓN PENALIDAD (ROJO)
                              if (_isLoading)
                                const CircularProgressIndicator(color: Color(0xFFFF5252))
                              else
                                SizedBox(
                                  width: double.infinity,
                                  height: kBotonRojoHeight,
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFFFF5252),
                                      side: const BorderSide(color: Color(0xFFFF5252), width: 1.5),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                      backgroundColor: const Color(0xFFFF5252).withOpacity(0.05),
                                    ),
                                    onPressed: _ejecutarCancelacion,
                                    child: Text(
                                      "ASUMIR PENALIDAD Y CANCELAR",
                                      style: TextStyle(
                                          fontSize: kBotonRojoFontSize,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5
                                      ),
                                    ),
                                  ),
                                ),

                              const SizedBox(height: 40), // Espacio final para scroll
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }
            ),
          ),
        ],
      ),
    );
  }
}