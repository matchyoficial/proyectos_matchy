// 📂 lib/screens/cita_creada_screen.dart
// ✅ CITA CREADA (DISEÑO PREMIUM)
// 🔥 UI: Botón "BORRAR TU CITA" (Rojo suave).
// 🔥 LÓGICA: Borrado físico de la cita (delete) sin penalidad.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proyectos_matchy/models/lugar_data.dart';
import 'package:proyectos_matchy/screens/panel_screen.dart';

class CitaCreadaScreen extends StatelessWidget {
  final String citaId;
  final LugarData lugar;
  final String fecha;
  final String hora;
  final String preferencia;
  final String intencion;

  const CitaCreadaScreen({
    super.key,
    required this.citaId,
    required this.lugar,
    required this.fecha,
    required this.hora,
    required this.preferencia,
    required this.intencion,
  });

  // ===========================================================================
  // 🔴🔴 CHINCHES MAESTROS (DISEÑO PREMIUM) 🔴🔴
  // ===========================================================================

  // Botones Premium (Gradiente + Sombra)
  // 🔥 CAMBIO: Rojo suave para "Borrar" (No penaliza)
  static const List<Color> kButtonGradientDelete = [Color(0xFFEF5350), Color(0xFFE57373)];
  static const List<Color> kButtonGradientBack   = [Color(0xFF393975), Color(0xFF1A1A24)]; // Azul/Negro Premium

  static const double kButtonRadius = 18.0;
  static const BorderSide kButtonBorder = BorderSide(color: Colors.white24, width: 1.0);
  static const List<BoxShadow> kButtonShadow = [
    BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 4)),
  ];

  // ===========================================================================

  // 🔧 FOTO DESDE FIREBASE (fallback seguro)
  String _pickFotoLugar(Map<String, dynamic> data) {
    final portada = (data['lugarFotoPortada'] ?? '').toString();
    if (portada.startsWith('http')) return portada;

    final fotos = (data['lugarFotos'] as List?) ?? [];
    for (final f in fotos) {
      final s = f.toString();
      if (s.startsWith('http')) return s;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    // 1. BLOQUEAR BOTÓN ATRÁS FÍSICO
    return PopScope(
      canPop: false, // Impide volver atrás para evitar duplicados
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // 2. FONDO INFINITO
            Positioned.fill(
              child: Image.asset(
                'assets/images/fondo.jpg',
                fit: BoxFit.cover,
                height: double.infinity,
                width: double.infinity,
              ),
            ),

            SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('citas').doc(citaId).get(),
                  builder: (_, snap) {
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator(color: Colors.white));
                    }

                    final data = snap.data!.data() as Map<String, dynamic>? ?? {};

                    // 3. LEER CÓDIGO OWNER
                    final codigo = (data['codigoOwner'] ?? 'PENDIENTE').toString();

                    final sedeNombre = (data['sedeNombre'] ?? '').toString();
                    final sedeDireccion = (data['sedeDireccion'] ?? '').toString();
                    final fotoUrl = _pickFotoLugar(data);

                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.asset('assets/images/logomatchyplano.png', height: 60),
                          const SizedBox(height: 20),

                          // 4. FOTO ANTI-MOCHAR CABEZAS
                          Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 15, offset: const Offset(0, 8))
                                ]
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: fotoUrl.isNotEmpty
                                  ? Image.network(
                                fotoUrl,
                                height: 200, // Más alto para lucir mejor
                                width: double.infinity,
                                fit: BoxFit.cover,
                                alignment: Alignment.topCenter, // 👈 CLAVE: Alineación Top
                                errorBuilder: (_, __, ___) => Image.asset('assets/images/perfil1.jpg', fit: BoxFit.cover, height: 200),
                              )
                                  : Image.asset('assets/images/perfil1.jpg', height: 200, width: double.infinity, fit: BoxFit.cover),
                            ),
                          ),

                          const SizedBox(height: 25),

                          const Text(
                            "TU CITA ESTÁ CREADA",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 25,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Poppins',
                                shadows: [Shadow(color: Colors.black, blurRadius: 3, offset: Offset(0, 3))]
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 20),

                          // 5. INFO CONTAINER (Glassmorphism)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.white12),
                                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)]
                            ),
                            child: Column(
                              children: [
                                _infoRow("LUGAR", lugar.nombre),
                                if (sedeNombre.isNotEmpty) _infoRow("SEDE", sedeNombre),
                                _infoRow("DIRECCIÓN", sedeDireccion.isNotEmpty ? sedeDireccion : lugar.direccion),
                                const Divider(color: Colors.white12, height: 30, thickness: 1),
                                _infoRow("FECHA", fecha),
                                _infoRow("HORA", hora),
                                _infoRow("PREFERENCIA", preferencia),
                                _infoRow("INTENCIÓN", intencion),
                              ],
                            ),
                          ),

                          const SizedBox(height: 25),

                          // 6. ADVERTENCIAS
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: const Color(0xFF050000).withOpacity(0.3)),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  "NO PUEDES CANCELAR UNA CITA 12 HORAS ANTES DE LA HORA ACORDADA, DEBES REPROGRAMARLA O SERÁS PENALIZADO",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Color(0xFFF80719),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      height: 1.4
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  "RECUERDA QUE EN MATCHY EL QUE INVITA PAGA.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 30),

                          // 7. CÓDIGO
                          const Text("CÓDIGO DE LA CITA:", style: TextStyle(color: Colors.white70, fontSize: 20, letterSpacing: 1)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                                color: const Color(0xFF6B4EE6),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [BoxShadow(color: const Color(0xFF6B4EE6).withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))]
                            ),
                            child: Text(
                              codigo,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 3.0
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),

                          // 8. BOTÓN BORRAR (CAMBIO CLAVE)
                          _PremiumButton(
                            text: "BORRAR TU CITA", // Texto actualizado
                            gradientColors: kButtonGradientDelete, // Color suave
                            onTap: () async {
                              // 🔥 LÓGICA DE BORRADO FÍSICO (DELETE)
                              await FirebaseFirestore.instance.collection('citas').doc(citaId).delete();

                              if (!context.mounted) return;
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (_) => const PanelScreen()),
                                    (r) => false,
                              );
                            },
                          ),

                          const SizedBox(height: 16),

                          // 9. BOTÓN REGRESAR (Premium)
                          _PremiumButton(
                            text: "REGRESAR AL PANEL",
                            gradientColors: kButtonGradientBack,
                            onTap: () {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (_) => const PanelScreen()),
                                    (r) => false,
                              );
                            },
                          ),

                          // Espacio extra para el fade out
                          const SizedBox(height: 100),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            // 10. DEGRADADO INFERIOR (FADE OUT)
            Positioned(
              bottom: 0, left: 0, right: 0, height: 90,
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
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$titulo:", style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.w600, fontSize: 13, letterSpacing: 0.5)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              valor.toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

// 🔥 WIDGET REUTILIZABLE: BOTÓN PREMIUM
class _PremiumButton extends StatelessWidget {
  final String text;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _PremiumButton({
    required this.text,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(CitaCreadaScreen.kButtonRadius),
          border: Border.fromBorderSide(CitaCreadaScreen.kButtonBorder),
          boxShadow: CitaCreadaScreen.kButtonShadow,
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5
          ),
        ),
      ),
    );
  }
}