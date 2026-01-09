// 📂 lib/screens/creacita_screen.dart
// ✅ CREA CITA SCREEN (con lógica real)
// ✅ Recibe LugarData seleccionado y muestra foto/info real
// ✅ Botones con texto BLANCO garantizado
// ✅ Al crear → navega a CitaCreadaScreen pasando todo

import 'package:flutter/material.dart';
import 'package:proyectos_matchy/models/lugar_data.dart';

// 🔴 CHINCHE CREA 0 — imports para navegación inferior
import 'package:proyectos_matchy/screens/panel_screen.dart';
import 'package:proyectos_matchy/screens/citas_screen.dart';
import 'package:proyectos_matchy/screens/perfil_screen.dart';
import 'package:proyectos_matchy/screens/matchys_screen.dart';
import 'package:proyectos_matchy/screens/chat_screen.dart';

// 🔴 CHINCHE CREA X — import de la pantalla de confirmación de cita
import 'package:proyectos_matchy/screens/cita_creada_screen.dart';

class CreaCitaScreen extends StatefulWidget {
  static const String routeName = 'creacita';

  // ✅ Lugar seleccionado desde LugarPlantillaScreen
  final LugarData lugar;

  const CreaCitaScreen({
    super.key,
    required this.lugar,
  });

  @override
  State<CreaCitaScreen> createState() => _CreaCitaScreenState();
}

class _CreaCitaScreenState extends State<CreaCitaScreen> {
  // ===========================================================
  // 🔹 ESTADOS DEL FORMULARIO
  // ===========================================================
  String _fecha = '';
  String _hora = '';
  String _preferencia = 'Hombres';
  String _intencion = 'Conocernos';

  // ===========================================================
  // 🔹 SELECTOR DE FECHA – 100% ESPAÑOL
  // ===========================================================
  Future<void> _seleccionarFecha() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      locale: const Locale('es', 'ES'),
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      builder: (context, child) {
        return Localizations.override(
          context: context,
          locale: const Locale('es', 'ES'),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _fecha = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  // ===========================================================
  // 🔹 SELECTOR DE HORA — ESPAÑOL
  // ===========================================================
  Future<void> _seleccionarHora() async {
    final now = TimeOfDay.now();

    final picked = await showTimePicker(
      context: context,
      initialTime: now,
      builder: (context, child) {
        return Localizations.override(
          context: context,
          locale: const Locale('es', 'ES'),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final hour = picked.hour;
      final minute = picked.minute.toString().padLeft(2, '0');
      final amPm = hour < 12 ? 'AM' : 'PM';
      final displayHour = hour % 12 == 0 ? 12 : hour % 12;

      setState(() {
        _hora = '$displayHour:$minute $amPm';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔴 CHINCHE CREA 3 — medidas clave
    const double espacioBarraLogo = 35;
    const double alturaLogo = 50;
    const double espacioLogoScroll = 15;
    const double margenInferiorPantalla = 80;
    const double alturaFotoLugar = 160;
    const double alturaBotonFecha = 45;
    const double alturaBotonHora = 45;
    const double alturaBotonCrear = 50;

    final lugar = widget.lugar;
    final String fotoLugar = (lugar.fotos.isNotEmpty)
        ? lugar.fotos.first
        : 'assets/images/faro1.jpg'; // 🔴 CHINCHE FALLBACK FOTO

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/fondo.jpg',
              fit: BoxFit.cover,
            ),
          ),

          Column(
            children: [
              const SizedBox(height: espacioBarraLogo),

              Image.asset(
                'assets/images/logomatchyplano.png',
                height: alturaLogo,
              ),

              const SizedBox(height: espacioLogoScroll),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: margenInferiorPantalla),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        "VAMOS A CREAR TU CITA PERFECTA",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.none,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 12),

                      // ✅ FOTO REAL DEL LUGAR SELECCIONADO
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          height: alturaFotoLugar,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.45),
                                blurRadius: 10,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.asset(
                            fotoLugar,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Image.asset(
                              'assets/images/perfil1.jpg',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ✅ INFO REAL DEL LUGAR SELECCIONADO
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "LUGAR: ${lugar.nombre.toUpperCase()}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.none,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "DIRECCIÓN: ${lugar.direccion}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ✅ BOTÓN FECHA (texto blanco garantizado)
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.8,
                        height: alturaBotonFecha,
                        child: ElevatedButton(
                          onPressed: _seleccionarFecha,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6A5ACD),
                            foregroundColor: Colors.white, // ✅ FIX
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Text(
                            _fecha.isEmpty ? "SELECCIONAR FECHA" : "FECHA: $_fecha",
                            style: const TextStyle(
                              color: Colors.white,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ✅ BOTÓN HORA (texto blanco garantizado)
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.8,
                        height: alturaBotonHora,
                        child: ElevatedButton(
                          onPressed: _seleccionarHora,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6A5ACD),
                            foregroundColor: Colors.white, // ✅ FIX
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Text(
                            _hora.isEmpty ? "SELECCIONAR HORA" : "HORA: $_hora",
                            style: const TextStyle(
                              color: Colors.white,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "PREFERENCIA:",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            _RadioOpcion(
                              label: 'Hombres',
                              groupValue: _preferencia,
                              onChanged: (v) => setState(() => _preferencia = v),
                            ),
                            _RadioOpcion(
                              label: 'Mujeres',
                              groupValue: _preferencia,
                              onChanged: (v) => setState(() => _preferencia = v),
                            ),
                            _RadioOpcion(
                              label: 'Ambos',
                              groupValue: _preferencia,
                              onChanged: (v) => setState(() => _preferencia = v),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "INTENCIÓN:",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            _RadioOpcion(
                              label: 'Solo hablar',
                              groupValue: _intencion,
                              onChanged: (v) => setState(() => _intencion = v),
                            ),
                            _RadioOpcion(
                              label: 'Conocernos',
                              groupValue: _intencion,
                              onChanged: (v) => setState(() => _intencion = v),
                            ),
                            _RadioOpcion(
                              label: 'Algo casual',
                              groupValue: _intencion,
                              onChanged: (v) => setState(() => _intencion = v),
                            ),
                            _RadioOpcion(
                              label: 'Amistad',
                              groupValue: _intencion,
                              onChanged: (v) => setState(() => _intencion = v),
                            ),
                            _RadioOpcion(
                              label: 'Una relación',
                              groupValue: _intencion,
                              onChanged: (v) => setState(() => _intencion = v),
                            ),
                            _RadioOpcion(
                              label: 'Algo serio',
                              groupValue: _intencion,
                              onChanged: (v) => setState(() => _intencion = v),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ✅ BOTÓN CREAR CITA → pasa todo a CitaCreadaScreen
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.8,
                        height: alturaBotonCrear,
                        child: ElevatedButton(
                          onPressed: () {
                            // 🔴 CHINCHE VALIDACIÓN 1 — (mínimo) exige fecha/hora
                            if (_fecha.isEmpty || _hora.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Selecciona fecha y hora antes de crear la cita.'),
                                ),
                              );
                              return;
                            }

                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CitaCreadaScreen(
                                  lugar: lugar,
                                  fecha: _fecha,
                                  hora: _hora,
                                  preferencia: _preferencia,
                                  intencion: _intencion,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6A5ACD),
                            foregroundColor: Colors.white, // ✅ FIX
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text(
                            "CREAR TU CITA",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),

      // ===========================================================
      // 🔹 BARRA NAV INFERIOR
      // ===========================================================
      bottomNavigationBar: const _MatchyBottomNav(currentIndex: 1),
    );
  }
}

// ===========================================================
// 🔹 RADIO PERSONALIZADO (SIN EXPANDED)
// ===========================================================
class _RadioOpcion extends StatelessWidget {
  final String label;
  final String groupValue;
  final ValueChanged<String> onChanged;

  const _RadioOpcion({
    required this.label,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<String>(
          value: label,
          groupValue: groupValue,
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
          activeColor: Colors.white,
          fillColor: MaterialStateProperty.all(Colors.white),
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }
}

// ===========================================================
// 🔹 BARRA NAV — igual que en otras pantallas
// ===========================================================
class _MatchyBottomNav extends StatelessWidget {
  final int currentIndex;

  const _MatchyBottomNav({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    const Color navBackground = Color(0xCC000000);
    const Color selectedColor = Color(0xFFE0D4FF);
    final Color unselectedColor = Colors.white70;

    return BottomNavigationBar(
      backgroundColor: navBackground,
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      selectedItemColor: selectedColor,
      unselectedItemColor: unselectedColor,
      items: [
        _navItem('assets/images/profile.png', 'Perfil'),
        _navItem('assets/images/citas.png', 'Citas'),
        _navItem('assets/images/panel.png', 'Panel'),
        _navItem('assets/images/matchy.png', 'Matchy'),
        _navItem('assets/images/chat.png', 'Chat'),
      ],
      onTap: (index) {
        if (index == currentIndex) return;

        Widget destino;
        switch (index) {
          case 0:
            destino = const PerfilScreen();
            break;
          case 1:
            destino = const CitasScreen();
            break;
          case 2:
            destino = const PanelScreen();
            break;
          case 3:
            destino = const MatchysScreen();
            break;
          default:
            destino = const ChatScreen();
        }

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => destino),
              (route) => false,
        );
      },
    );
  }

  static BottomNavigationBarItem _navItem(String asset, String label) {
    return BottomNavigationBarItem(
      icon: SizedBox(
        height: 24,
        child: Image.asset(
          asset,
          width: 22,
          height: 22,
        ),
      ),
      label: label,
    );
  }
}
