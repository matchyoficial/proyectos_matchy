// 📂 lib/screens/datos_screen.dart
// ✅ DATOSSCREEN FLUTTER (Conectado a Riverpod + guardado local)
// ✅ GUARDAR: solo se activa si cumple mínimos + hay cambios (dirty)
// ✅ Al guardar: marca onboarding_completed = true
// ✅ Fotos REAL: galería/cámara con image_picker + reorder + delete (X)
// ✅ Foto #1 = foto de perfil

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:proyectos_matchy/widgets/matchy_back_button.dart';
import 'package:proyectos_matchy/screens/panel_screen.dart';
import 'package:proyectos_matchy/state/profile_form_provider.dart';

class DatosScreen extends ConsumerStatefulWidget {
  static const String routeName = 'datos';

  const DatosScreen({super.key});

  @override
  ConsumerState<DatosScreen> createState() => _DatosScreenState();
}

class _DatosScreenState extends ConsumerState<DatosScreen> {
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _edadCtrl;
  late final TextEditingController _profesionCtrl;
  late final TextEditingController _biografiaCtrl;
  late final TextEditingController _detalleCtrl;
  late final TextEditingController _estaturaCtrl;

  // 🔴 CHINCHE VALID UI 1 — al intentar guardar, mostramos obligatorios
  bool _mostrarErrores = false;

  // 🔴 CHINCHE FOTO PICKER 1 — instancia picker
  final ImagePicker _picker = ImagePicker();

  // 🔹 Fotos demo (por si quieres seguir usando assets también)
  final List<String> fotosDisponibles = const [
    'assets/images/perfil1.jpg',
    'assets/images/perfil2.jpg',
    'assets/images/perfil3.jpg',
    'assets/images/perfil4.jpg',
    'assets/images/perfil5.jpg',
  ];

  final List<String> _estaturas = List.generate(76, (i) {
    final v = 1.40 + (i * 0.01);
    return '${v.toStringAsFixed(2)} m';
  });

  @override
  void initState() {
    super.initState();

    final s = ref.read(profileFormProvider);

    _nombreCtrl = TextEditingController(text: s.nombre);
    _edadCtrl = TextEditingController(text: s.edad);
    _profesionCtrl = TextEditingController(text: s.profesion);
    _biografiaCtrl = TextEditingController(text: s.biografia);
    _detalleCtrl = TextEditingController(text: s.detalle);
    _estaturaCtrl = TextEditingController(text: s.estatura);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(profileFormProvider.notifier).loadDraft();

      final loaded = ref.read(profileFormProvider);
      _nombreCtrl.text = loaded.nombre;
      _edadCtrl.text = loaded.edad;
      _profesionCtrl.text = loaded.profesion;
      _biografiaCtrl.text = loaded.biografia;
      _detalleCtrl.text = loaded.detalle;
      _estaturaCtrl.text = loaded.estatura;
    });

    _nombreCtrl.addListener(() {
      ref.read(profileFormProvider.notifier).setNombre(_nombreCtrl.text);
    });
    _edadCtrl.addListener(() {
      ref.read(profileFormProvider.notifier).setEdad(_edadCtrl.text);
    });
    _profesionCtrl.addListener(() {
      ref.read(profileFormProvider.notifier).setProfesion(_profesionCtrl.text);
    });
    _biografiaCtrl.addListener(() {
      ref.read(profileFormProvider.notifier).setBiografia(_biografiaCtrl.text);
    });
    _detalleCtrl.addListener(() {
      ref.read(profileFormProvider.notifier).setDetalle(_detalleCtrl.text);
    });
    _estaturaCtrl.addListener(() {
      ref.read(profileFormProvider.notifier).setEstatura(_estaturaCtrl.text);
    });
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _edadCtrl.dispose();
    _profesionCtrl.dispose();
    _biografiaCtrl.dispose();
    _detalleCtrl.dispose();
    _estaturaCtrl.dispose();
    super.dispose();
  }

  // ===================== VALIDACIONES UI =====================
  bool _nombreOk(ProfileFormState s) => s.nombre.trim().isNotEmpty;

  bool _edadOk(ProfileFormState s) {
    final edadInt = int.tryParse(s.edad.trim());
    return edadInt != null && edadInt >= 18 && edadInt <= 99;
  }

  bool _paisOk(ProfileFormState s) => (s.paisSeleccionado ?? '').trim().isNotEmpty;
  bool _ciudadOk(ProfileFormState s) => (s.ciudadSeleccionada ?? '').trim().isNotEmpty;
  bool _fotosOk(ProfileFormState s) => s.fotosCargadas.isNotEmpty;

  // ===================== ESTATURA SELECTOR =====================
  Future<void> _seleccionarEstatura(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Selecciona tu estatura',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 320, // 🔴 CHINCHE ESTATURA 2
                child: ListView.builder(
                  itemCount: _estaturas.length,
                  itemBuilder: (_, i) {
                    final item = _estaturas[i];
                    return ListTile(
                      title: Text(item, style: const TextStyle(color: Colors.white)),
                      onTap: () => Navigator.pop(context, item),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selected != null) {
      _estaturaCtrl.text = selected;
    }
  }

  // ===================== FOTO PICKER REAL =====================
  Future<void> _mostrarPicker(BuildContext context, ProfileFormController ctrl, ProfileFormState state) async {
    if (state.fotosCargadas.length >= kMaxFotos) {
      // 🔴 CHINCHE FOTO MAX 1
      return;
    }

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Cargar foto',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),

              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.white),
                title: const Text('Galería', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickFrom(ImageSource.gallery, ctrl);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera, color: Colors.white),
                title: const Text('Cámara', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickFrom(ImageSource.camera, ctrl);
                },
              ),

              // 🔴 CHINCHE FOTO DEMO 2 — opcional: seguir agregando assets demo
              ListTile(
                leading: const Icon(Icons.auto_awesome, color: Colors.white70),
                title: const Text('Demo (assets)', style: TextStyle(color: Colors.white70)),
                onTap: () {
                  Navigator.pop(context);
                  final nextIndex = state.fotosCargadas.length;
                  final demo = fotosDisponibles.take(nextIndex + 1).toList();
                  ctrl.setFotos(demo);
                },
              ),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickFrom(ImageSource source, ProfileFormController ctrl) async {
    try {
      // 🔴 CHINCHE FOTO QUALITY 1 — baja/alta calidad (0-100)
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (file == null) return;

      ctrl.addFoto(file.path);
    } catch (_) {
      // si falla, el provider puede mostrar error después si quieres
    }
  }

  // ===================== REORDER + UI =====================
  Widget _buildFotoReorderArea({
    required BuildContext context,
    required ProfileFormState state,
    required ProfileFormController ctrl,
  }) {
    if (state.fotosCargadas.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0x33FFFFFF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          'Aún no has cargado fotos.\nLa primera foto que quede arriba será tu foto de perfil.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13,
            height: 1.3,
            decoration: TextDecoration.none,
          ),
        ),
      );
    }

    const double sizePerfil = 120;
    const double sizeNormal = 70;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.25),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Text(
            'Ordena tus fotos: arrastra para cambiar.\n⭐ La Foto #1 será tu FOTO DE PERFIL',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              height: 1.25,
              decoration: TextDecoration.none,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 14),

        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: List.generate(state.fotosCargadas.length, (index) {
            final pathOrAsset = state.fotosCargadas[index];
            final bool esPerfil = index == 0;
            final double size = esPerfil ? sizePerfil : sizeNormal;

            return DragTarget<int>(
              onWillAccept: (from) => from != null && from != index,
              onAccept: (from) => ctrl.reorderFotos(from, index),
              builder: (context, _, __) {
                return LongPressDraggable<int>(
                  data: index,
                  feedback: Opacity(
                    opacity: 0.85,
                    child: _FotoThumb(
                      pathOrAsset: pathOrAsset,
                      size: size,
                      esPerfil: esPerfil,
                      isGhost: true,
                      onRemove: () => ctrl.removeFotoAt(index),
                    ),
                  ),
                  childWhenDragging: _FotoThumb(
                    pathOrAsset: pathOrAsset,
                    size: size,
                    esPerfil: esPerfil,
                    isGhost: true,
                    onRemove: () => ctrl.removeFotoAt(index),
                  ),
                  child: _FotoThumb(
                    pathOrAsset: pathOrAsset,
                    size: size,
                    esPerfil: esPerfil,
                    isGhost: false,
                    onRemove: () => ctrl.removeFotoAt(index),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const double espacioBarraLogo = 35;
    const double alturaLogo = 50;
    const double espacioLogoScroll = 15;
    const double margenInferiorPantalla = 80;

    final state = ref.watch(profileFormProvider);
    final ctrl = ref.read(profileFormProvider.notifier);

    final List<String> paises = const [
      'Colombia',
      'México',
      'Argentina',
      'Chile',
      'Perú',
      'España',
    ];

    final Map<String, List<String>> ciudadesPorPais = const {
      'Colombia': ['Cali', 'Bogotá', 'Medellín', 'Barranquilla', 'Cartagena'],
      'México': ['Ciudad de México', 'Guadalajara', 'Monterrey'],
      'Argentina': ['Buenos Aires', 'Córdoba', 'Rosario'],
      'Chile': ['Santiago', 'Valparaíso', 'Concepción'],
      'Perú': ['Lima', 'Cusco', 'Arequipa'],
      'España': ['Madrid', 'Barcelona', 'Valencia'],
    };

    final List<String> ciudades = state.paisSeleccionado != null
        ? (ciudadesPorPais[state.paisSeleccionado!] ?? [])
        : [];

    final String? paisSafe = paises.contains(state.paisSeleccionado) ? state.paisSeleccionado : null;
    final String? ciudadSafe = ciudades.contains(state.ciudadSeleccionada) ? state.ciudadSeleccionada : null;

    const List<List<String>> sobreMiOpciones = [
      ['🚹 Hombre', '🚺 Mujer'],
      ['🌈 Otro género', '🤫 Prefiero no decirlo'],
      ['💬 Soltero', '❤️ En una relación'],
      ['👶 Con hijo', '🙅‍♂️ Sin hijo'],
      ['🚬 Fumo', '🚭 No fumo'],
      ['🍷 Tomo', '🚫 No tomo'],
      ['🐶 Perros', '🐱 Gatos'],
    ];

    const List<String> buscoOpciones = [
      '💞 Relación estable',
      '🎉 Citas divertidas',
      '💬 Conversación',
      '👫 Amistad',
      '🌍 Conocer gente nueva',
      '🔥 Aventura',
      '💍 Pareja a largo plazo',
      '👀 Algo casual',
      '🎶 Compartir gustos',
      '✈️ Viajar juntos',
    ];

    const List<String> interesesOpciones = [
      '🎬 Cine', '🎵 Música', '✈️ Viajar', '📖 Lectura', '☕ Café', '🏃‍♂️ Running', '🏋️ Gimnasio',
      '🌄 Senderismo', '🍷 Vino', '🎨 Arte', '🎮 Videojuegos', '📸 Fotografía', '🍳 Cocina',
      '🏖️ Playa', '🎭 Teatro', '💃 Bailar', '🎤 Cantar', '🧘 Yoga', '🧠 Filosofía', '💼 Emprender',
      '💻 Tecnología', '💅 Moda', '📺 Series', '🎙️ Podcasts', '🌿 Naturaleza', '🏕️ Camping', '⚽ Fútbol',
      '🏀 Baloncesto', '🚴‍♂️ Ciclismo', '🏔️ Escalada', '🐠 Buceo', '🎯 Juegos de mesa', '💫 Astrología',
      '🐾 Voluntariado', '🧑‍🍳 Comida gourmet', '🎲 Rol', '🛶 Kayak', '💌 Escritura', '📷 Selfies',
      '🌙 Noche', '☀️ Amaneceres', '💃 Salsa', '🎧 DJ', '🎁 Regalos', '🍕 Pizza', '🥂 Brindar',
      '📚 Manga', '🌌 Meditar', '💡 Innovar', '🤟 Rock', '🎫 Conciertos', '⚡ Adrenalina',
      '🏅 Deportes', '🎭 Cosplay', '🐾 Animalismo', '📺 Streaming',
    ];

    final textTheme = Theme.of(context).textTheme;

    final bool puedeContinuar = ctrl.puedeGuardar && ctrl.isDirty;
    final bool showErrors = _mostrarErrores;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover),
          ),

          const MatchyBackButton(top: 10, left: 16),

          Column(
            children: [
              const SizedBox(height: espacioBarraLogo),
              Image.asset('assets/images/logomatchyplano.png', height: alturaLogo),
              const SizedBox(height: espacioLogoScroll),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(left: 24, right: 24, bottom: margenInferiorPantalla),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'EDITA TU PERFIL',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.none,
                        ),
                      ),

                      if (state.error != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          state.error!,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      _buildTextField(
                        label: 'Nombre *',
                        controller: _nombreCtrl,
                        showError: showErrors && !_nombreOk(state),
                        errorText: 'Campo obligatorio',
                      ),
                      const SizedBox(height: 14),

                      _buildTextField(
                        label: 'Edad * (18-99)',
                        controller: _edadCtrl,
                        keyboardType: TextInputType.number,
                        showError: showErrors && !_edadOk(state),
                        errorText: 'Edad inválida (18 a 99)',
                      ),
                      const SizedBox(height: 14),

                      _buildTextField(label: 'Profesión', controller: _profesionCtrl),
                      const SizedBox(height: 14),

                      _buildTextField(label: 'Biografía', controller: _biografiaCtrl, maxLines: 4),
                      const SizedBox(height: 14),

                      _buildTextField(
                        label: 'Un detalle que me enamora',
                        controller: _detalleCtrl,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 14),

                      GestureDetector(
                        onTap: () => _seleccionarEstatura(context),
                        child: AbsorbPointer(
                          child: _buildTextField(
                            label: 'Estatura (selección)',
                            controller: _estaturaCtrl,
                            suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      _buildPaisCiudadSection(
                        paisSeleccionado: paisSafe,
                        ciudadSeleccionada: ciudadSafe,
                        paises: paises,
                        ciudades: ciudades,
                        showPaisError: showErrors && !_paisOk(state),
                        showCiudadError: showErrors && !_ciudadOk(state),
                        onPaisChanged: (value) => ctrl.setPais(value),
                        onCiudadChanged: (value) => ctrl.setCiudad(value),
                      ),

                      const SizedBox(height: 24),

                      Text(
                        'Agrega tus fotos (mínimo 1, máximo 5) *',
                        style: TextStyle(
                          color: showErrors && !_fotosOk(state) ? Colors.redAccent : Colors.white,
                          fontSize: 16,
                          decoration: TextDecoration.none,
                          fontWeight: showErrors && !_fotosOk(state) ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 10),

                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.6,
                        height: 45,
                        child: ElevatedButton(
                          onPressed: () => _mostrarPicker(context, ctrl, state),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB3D9FF),
                            shape: const StadiumBorder(),
                          ),
                          child: const Text(
                            'CARGAR FOTO',
                            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),

                      _buildFotoReorderArea(context: context, state: state, ctrl: ctrl),

                      const SizedBox(height: 24),

                      Text(
                        'Sobre mí',
                        style: textTheme.titleMedium?.copyWith(
                          color: const Color(0xFFB3D9FF),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 10),

                      Column(
                        children: sobreMiOpciones.map((grupo) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: grupo.map((opcion) {
                                final seleccionado = state.sobreMiSeleccion.contains(opcion);

                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: GestureDetector(
                                      onTap: () => ctrl.toggleSobreMi(opcion),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                        decoration: BoxDecoration(
                                          color: seleccionado ? const Color(0xFFB3D9FF) : const Color(0x33FFFFFF),
                                          borderRadius: BorderRadius.circular(50),
                                        ),
                                        child: Center(
                                          child: Text(
                                            opcion,
                                            textAlign: TextAlign.center,
                                            softWrap: true,
                                            style: TextStyle(
                                              color: seleccionado ? Colors.black : Colors.white,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 20),

                      _SeccionBotonesChipsRiverpod(
                        titulo: 'Busco...',
                        opciones: buscoOpciones,
                        seleccionActual: state.buscoSeleccion,
                        onToggle: (op) => ctrl.toggleBusco(op),
                      ),

                      _SeccionBotonesChipsRiverpod(
                        titulo: 'Intereses y Hobbies',
                        opciones: interesesOpciones,
                        seleccionActual: state.interesesSeleccion,
                        onToggle: (op) => ctrl.toggleInteres(op),
                      ),

                      const SizedBox(height: 10),

                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.6,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: puedeContinuar
                              ? () async {
                            await ctrl.saveDraft();
                            await ctrl.publishProfile(); // ✅ perfil oficial
                            await ctrl.setOnboardingCompleted(true);

                            if (!mounted) return;
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const PanelScreen()),
                                  (route) => false,
                            );
                          }
                              : () => setState(() => _mostrarErrores = true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: puedeContinuar ? const Color(0xFFB3D9FF) : const Color(0x66B3D9FF),
                            shape: const StadiumBorder(),
                          ),
                          child: Text(
                            'GUARDAR',
                            style: TextStyle(
                              color: puedeContinuar ? Colors.black : Colors.black54,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===================== HELPERS UI =====================

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool showError = false,
    String? errorText,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: showError ? Colors.redAccent : Colors.white70,
          fontWeight: showError ? FontWeight.bold : FontWeight.normal,
        ),
        errorText: showError ? (errorText ?? 'Campo obligatorio') : null,
        errorStyle: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
        suffixIcon: suffixIcon,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: showError ? Colors.redAccent : Colors.white),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFB3D9FF)),
        ),
      ),
    );
  }

  Widget _buildPaisCiudadSection({
    required String? paisSeleccionado,
    required String? ciudadSeleccionada,
    required List<String> paises,
    required List<String> ciudades,
    required ValueChanged<String?> onPaisChanged,
    required ValueChanged<String?> onCiudadChanged,
    required bool showPaisError,
    required bool showCiudadError,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'País *',
          style: TextStyle(
            color: showPaisError ? Colors.redAccent : Colors.white,
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.none,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: paisSeleccionado,
          dropdownColor: Colors.black87,
          decoration: InputDecoration(
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: showPaisError ? Colors.redAccent : Colors.white),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFB3D9FF)),
            ),
            errorText: showPaisError ? 'Campo obligatorio' : null,
            errorStyle: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
          ),
          iconEnabledColor: Colors.white,
          style: const TextStyle(color: Colors.white),
          items: paises.map((p) => DropdownMenuItem<String>(value: p, child: Text(p))).toList(),
          onChanged: onPaisChanged,
        ),
        const SizedBox(height: 12),
        Text(
          'Ciudad *',
          style: TextStyle(
            color: showCiudadError ? Colors.redAccent : Colors.white,
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.none,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: ciudadSeleccionada,
          dropdownColor: Colors.black87,
          decoration: InputDecoration(
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: showCiudadError ? Colors.redAccent : Colors.white),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFB3D9FF)),
            ),
            errorText: showCiudadError ? 'Campo obligatorio' : null,
            errorStyle: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
          ),
          iconEnabledColor: Colors.white,
          style: const TextStyle(color: Colors.white),
          items: ciudades.map((c) => DropdownMenuItem<String>(value: c, child: Text(c))).toList(),
          onChanged: ciudades.isEmpty ? null : onCiudadChanged,
        ),
      ],
    );
  }
}

// =====================================================
// ✅ Thumbnail fotos (assets o file) + ❌ X delete + badge PERFIL
// =====================================================
class _FotoThumb extends StatelessWidget {
  final String pathOrAsset;
  final double size;
  final bool esPerfil;
  final bool isGhost;
  final VoidCallback onRemove;

  const _FotoThumb({
    required this.pathOrAsset,
    required this.size,
    required this.esPerfil,
    required this.isGhost,
    required this.onRemove,
  });

  bool _isAssetPath(String v) => v.startsWith('assets/');

  @override
  Widget build(BuildContext context) {
    final Widget img = _isAssetPath(pathOrAsset)
        ? Image.asset(pathOrAsset, fit: BoxFit.cover, alignment: Alignment.topCenter)
        : Image.file(File(pathOrAsset), fit: BoxFit.cover, alignment: Alignment.topCenter);

    return Opacity(
      opacity: isGhost ? 0.35 : 1.0,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: size,
              height: size,
              color: Colors.white24,
              child: img,
            ),
          ),

          // ❌ X eliminar
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.85),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),

          if (esPerfil)
            Positioned(
              left: 6,
              top: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFBEB3FF),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  'PERFIL',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// =====================================================
// ✅ Sección chips conectada a Riverpod (sin setState)
// =====================================================
class _SeccionBotonesChipsRiverpod extends StatelessWidget {
  final String titulo;
  final List<String> opciones;
  final List<String> seleccionActual;
  final ValueChanged<String> onToggle;

  const _SeccionBotonesChipsRiverpod({
    required this.titulo,
    required this.opciones,
    required this.seleccionActual,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: textTheme.titleMedium?.copyWith(
            color: const Color(0xFFB3D9FF),
            fontSize: 18,
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.none,
          ),
        ),
        const SizedBox(height: 8),
        Column(
          children: _chunk(opciones, 2).map((fila) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: fila.map((opcion) {
                  final seleccionado = seleccionActual.contains(opcion);
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () => onToggle(opcion),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                          decoration: BoxDecoration(
                            color: seleccionado ? const Color(0xFFB3D9FF) : const Color(0x33FFFFFF),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Center(
                            child: Text(
                              opcion,
                              textAlign: TextAlign.center,
                              softWrap: true,
                              style: TextStyle(
                                color: seleccionado ? Colors.black : Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  List<List<String>> _chunk(List<String> list, int size) {
    final List<List<String>> chunks = [];
    for (var i = 0; i < list.length; i += size) {
      chunks.add(list.sublist(i, i + size > list.length ? list.length : i + size));
    }
    return chunks;
  }
}
