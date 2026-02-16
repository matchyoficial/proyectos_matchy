// 📂 lib/screens/datos_screen.dart
// ✅ DATOSSCREEN BLINDADO (GENERO Y PREFERENCIA OBLIGATORIOS)
// 🔥 FIX: Agregados asteriscos (*) visuales a Género y Preferencia.
// 🔥 LOGIC: El botón GUARDAR bloquea y muestra error si faltan estos datos.
// 🔥 DATA: Estandarización de valores ('Otro', 'NoDecir') para futuro filtro.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';

import 'package:proyectos_matchy/widgets/matchy_back_button.dart';
import 'package:proyectos_matchy/screens/panel_screen.dart';
import 'package:proyectos_matchy/state/profile_form_provider.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class DatosScreen extends ConsumerStatefulWidget {
  static const String routeName = 'datos';
  const DatosScreen({super.key});

  @override
  ConsumerState<DatosScreen> createState() => _DatosScreenState();
}

class _DatosScreenState extends ConsumerState<DatosScreen> {
  // 🛡️ ZONA DE CHINCHES MAESTROS (DISEÑO BLINDADO)
  static const double kChincheTituloSeccion = 18.0;
  static const double kChincheLabelInput = 16.0;
  static const double kChincheTextoInput = 15.0;

  // Sombras y Blindaje
  static const List<Shadow> kTextShadow = [
    Shadow(color: Colors.black, blurRadius: 10, offset: Offset(0, 4))
  ];
  static const List<BoxShadow> kChipShadow = [
    BoxShadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 3))
  ];

  late final TextEditingController _nombreCtrl;
  late final TextEditingController _edadCtrl;
  late final TextEditingController _profesionCtrl;
  late final TextEditingController _biografiaCtrl;
  late final TextEditingController _detalleCtrl;
  late final TextEditingController _estaturaCtrl;

  bool _mostrarErrores = false;
  bool _saving = false;
  bool _isLoadingCloudData = true;

  final ImagePicker _picker = ImagePicker();
  String _preferenciaCitas = 'Ambos';
  String _genero = '';

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
    _preferenciaCitas = s.preferenciaCitas.trim().isEmpty ? 'Ambos' : s.preferenciaCitas.trim();
    _genero = s.genero.trim();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ctrl = ref.read(profileFormProvider.notifier);
      await ctrl.loadDraft();
      final localState = ref.read(profileFormProvider);
      if (localState.nombre.isEmpty) {
        await _hydrateFromFirestore(ctrl);
      } else {
        if (mounted) setState(() => _isLoadingCloudData = false);
      }
      final finalState = ref.read(profileFormProvider);
      _nombreCtrl.text = finalState.nombre;
      _edadCtrl.text = finalState.edad;
      _profesionCtrl.text = finalState.profesion;
      _biografiaCtrl.text = finalState.biografia;
      _detalleCtrl.text = finalState.detalle;
      _estaturaCtrl.text = finalState.estatura;
      if (!mounted) return;
      setState(() {
        _preferenciaCitas = finalState.preferenciaCitas.trim().isEmpty ? 'Ambos' : finalState.preferenciaCitas.trim();
        _genero = finalState.genero.trim();
        _isLoadingCloudData = false;
      });
    });

    _nombreCtrl.addListener(() => ref.read(profileFormProvider.notifier).setNombre(_nombreCtrl.text));
    _edadCtrl.addListener(() => ref.read(profileFormProvider.notifier).setEdad(_edadCtrl.text));
    _profesionCtrl.addListener(() => ref.read(profileFormProvider.notifier).setProfesion(_profesionCtrl.text));
    _biografiaCtrl.addListener(() => ref.read(profileFormProvider.notifier).setBiografia(_biografiaCtrl.text));
    _detalleCtrl.addListener(() => ref.read(profileFormProvider.notifier).setDetalle(_detalleCtrl.text));
    _estaturaCtrl.addListener(() => ref.read(profileFormProvider.notifier).setEstatura(_estaturaCtrl.text));
  }

  Future<void> _hydrateFromFirestore(ProfileFormController ctrl) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        ctrl.setNombre(data['nombre'] ?? '');
        if (data['edad'] != null) ctrl.setEdad(data['edad'].toString());
        ctrl.setProfesion(data['profesion'] ?? '');
        ctrl.setBiografia(data['biografia'] ?? '');
        ctrl.setDetalle(data['detalle'] ?? '');
        ctrl.setEstatura(data['estatura'] ?? '');
        ctrl.setPais(data['pais']);
        ctrl.setCiudad(data['ciudad']);
        ctrl.setGenero(data['genero'] ?? '');
        ctrl.setPreferenciaCitas(data['preferenciaCitas'] ?? 'Ambos');
        if (data['sobreMiSeleccion'] is List) {
          for (var item in data['sobreMiSeleccion']) ctrl.toggleSobreMi(item);
        }
        if (data['buscoSeleccion'] is List) {
          for (var item in data['buscoSeleccion']) ctrl.toggleBusco(item);
        }
        if (data['interesesSeleccion'] is List) {
          for (var item in data['interesesSeleccion']) ctrl.toggleInteres(item);
        }
        if (data['photoUrls'] is List) {
          final urls = List<String>.from(data['photoUrls']);
          ctrl.setFotos(urls);
        }
      }
    } catch (e) { debugPrint("Error: $e"); }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose(); _edadCtrl.dispose(); _profesionCtrl.dispose();
    _biografiaCtrl.dispose(); _detalleCtrl.dispose(); _estaturaCtrl.dispose();
    super.dispose();
  }

  // VALIDACIONES
  bool _nombreOk(ProfileFormState s) => s.nombre.trim().isNotEmpty;
  bool _edadOk(ProfileFormState s) {
    final edadInt = int.tryParse(s.edad.trim());
    return edadInt != null && edadInt >= 18 && edadInt <= 99;
  }
  bool _paisOk(ProfileFormState s) => (s.paisSeleccionado ?? '').trim().isNotEmpty;
  bool _ciudadOk(ProfileFormState s) => (s.ciudadSeleccionada ?? '').trim().isNotEmpty;

  // ✅ NUEVAS VALIDACIONES OBLIGATORIAS
  bool _generoOk() => _genero.trim().isNotEmpty;
  bool _preferenciaOk() => _preferenciaCitas.trim().isNotEmpty; // Aunque tenga default, validamos por seguridad

  bool _fotosOk(ProfileFormState s) => s.photoUrls.isNotEmpty || s.fotosCargadas.isNotEmpty;

  // ✅ VALIDACIÓN MAESTRA
  bool _formularioValido(ProfileFormState s) {
    return _nombreOk(s) && _edadOk(s) && _paisOk(s) && _ciudadOk(s) && _generoOk() && _preferenciaOk() && _fotosOk(s);
  }

  List<String> _buildDisplayFotos(ProfileFormState s) {
    final out = <String>[];
    for (final raw in s.fotosCargadas) {
      final v = raw.trim();
      if (v.isEmpty) continue;
      out.add(v);
    }
    return out;
  }

  Future<List<String>> _uploadRealPhotosToStorage({required String uid, required List<String> fotosCargadas}) async {
    final urls = <String>[];
    final filesToUpload = fotosCargadas.where((p) => p.trim().isNotEmpty && !p.startsWith('assets/') && !p.startsWith('http')).toList();
    if (filesToUpload.isEmpty) return urls;
    final storage = FirebaseStorage.instance;
    for (var i = 0; i < filesToUpload.length; i++) {
      final path = filesToUpload[i];
      final file = File(path);
      if (!file.existsSync()) continue;
      final fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
      final ref = storage.ref().child('users/$uid/photos/$fileName');
      final task = await ref.putFile(file);
      final url = await task.ref.getDownloadURL();
      if (url.trim().isNotEmpty) urls.add(url.trim());
    }
    return urls;
  }

  Future<List<String>> _syncProfileToFirestore(ProfileFormState s) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No hay usuario autenticado.');
    final uid = user.uid;
    final docRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final List<String> localRaw = List<String>.from(s.fotosCargadas);
    final existingUrls = localRaw.where((p) => p.startsWith('http')).toList();
    final uploadedUrls = await _uploadRealPhotosToStorage(uid: uid, fotosCargadas: localRaw);
    final List<String> photoUrls = [...existingUrls, ...uploadedUrls].map((e) => e.trim()).where((e) => e.startsWith('http')).toList();

    final payload = <String, dynamic>{
      'uid': uid,
      'email': user.email,
      'nombre': s.nombre.trim(),
      'edad': int.tryParse(s.edad.trim()),
      'profesion': s.profesion.trim(),
      'biografia': s.biografia.trim(),
      'detalle': s.detalle.trim(),
      'estatura': s.estatura.trim(),
      'pais': (s.paisSeleccionado ?? '').trim(),
      'ciudad': (s.ciudadSeleccionada ?? '').trim(),
      'genero': _genero,
      'preferenciaCitas': _preferenciaCitas,
      'sobreMiSeleccion': List<String>.from(s.sobreMiSeleccion),
      'buscoSeleccion': List<String>.from(s.buscoSeleccion),
      'interesesSeleccion': List<String>.from(s.interesesSeleccion),
      'photoUrls': photoUrls,
      'profilePhotoUrl': photoUrls.isNotEmpty ? photoUrls.first : null,
      'onboarding_completed': true,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await docRef.set(payload, SetOptions(merge: true));
    return photoUrls;
  }

  Future<void> _seleccionarEstatura(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
        context: context, backgroundColor: Colors.black87,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
        builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 10), Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20))),
          const SizedBox(height: 12), const Text('Selecciona tu estatura', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          SizedBox(height: 320, child: ListView.builder(itemCount: _estaturas.length, itemBuilder: (_, i) => ListTile(title: Text(_estaturas[i], style: const TextStyle(color: Colors.white)), onTap: () => Navigator.pop(context, _estaturas[i]))))
        ]))
    );
    if (selected != null) _estaturaCtrl.text = selected;
  }

  Future<void> _mostrarPicker(BuildContext context, ProfileFormController ctrl, ProfileFormState state) async {
    final display = _buildDisplayFotos(state);
    if (display.length >= 5) return;
    await showModalBottomSheet(
        context: context, backgroundColor: Colors.black87,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
        builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 10), Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20))),
          const SizedBox(height: 14), const Text('Cargar foto', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          ListTile(leading: const Icon(Icons.photo_library, color: Colors.white), title: const Text('Galería', style: TextStyle(color: Colors.white)), onTap: () async { Navigator.pop(context); await _pickFrom(ImageSource.gallery, ctrl); }),
          ListTile(leading: const Icon(Icons.photo_camera, color: Colors.white), title: const Text('Cámara', style: TextStyle(color: Colors.white)), onTap: () async { Navigator.pop(context); await _pickFrom(ImageSource.camera, ctrl); }),
        ]))
    );
  }

  Future<void> _pickFrom(ImageSource source, ProfileFormController ctrl) async {
    try {
      final XFile? file = await _picker.pickImage(source: source, imageQuality: 85);
      if (file != null) ctrl.addFoto(file.path);
    } catch (e) { debugPrint("Error: $e"); }
  }

  // 🛡️ UI FOTOS BLINDADA
  Widget _buildFotoReorderArea({required BuildContext context, required ProfileFormState state, required ProfileFormController ctrl}) {
    final displayFotos = _buildDisplayFotos(state);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          // 🛡️ BLINDAJE: Letrero de instrucciones protegido
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.touch_app_rounded, color: Color(0xFFBEB3FF), size: 16),
                  SizedBox(width: 8),
                  Text(
                      "Arrastra para reordenar. Pellizca la principal para ajustar.",
                      style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. FOTO PRINCIPAL (Fix de Pellizco)
              Expanded(
                flex: 1,
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: Stack(
                    children: [
                      _buildDraggablePhotoSlot(index: 0, displayFotos: displayFotos, ctrl: ctrl, isProfile: true),
                      if (displayFotos.isNotEmpty)
                        Positioned(bottom: 8, right: 8, child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.zoom_out_map, color: Colors.white, size: 14))),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // 2. GRID 2x2
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: AspectRatio(aspectRatio: 1.0, child: _buildDraggablePhotoSlot(index: 1, displayFotos: displayFotos, ctrl: ctrl))),
                        const SizedBox(width: 8),
                        Expanded(child: AspectRatio(aspectRatio: 1.0, child: _buildDraggablePhotoSlot(index: 2, displayFotos: displayFotos, ctrl: ctrl))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: AspectRatio(aspectRatio: 1.0, child: _buildDraggablePhotoSlot(index: 3, displayFotos: displayFotos, ctrl: ctrl))),
                        const SizedBox(width: 8),
                        Expanded(child: AspectRatio(aspectRatio: 1.0, child: _buildDraggablePhotoSlot(index: 4, displayFotos: displayFotos, ctrl: ctrl))),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDraggablePhotoSlot({required int index, required List<String> displayFotos, required ProfileFormController ctrl, bool isProfile = false}) {
    if (index >= displayFotos.length) {
      return Container(
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
        child: const Icon(Icons.add_photo_alternate, color: Colors.white12, size: 20),
      );
    }
    final pathOrAsset = displayFotos[index];
    return DragTarget<int>(
      onWillAccept: (from) => from != null && from != index,
      onAccept: (from) {
        final current = List<String>.from(displayFotos);
        final item = current.removeAt(from);
        current.insert(index, item);
        ctrl.setFotos(current);
      },
      builder: (context, _, __) => LongPressDraggable<int>(
        data: index,
        feedback: Opacity(opacity: 0.85, child: SizedBox(width: 80, height: 80, child: _FotoThumb(pathOrAsset: pathOrAsset, size: 80, esPerfil: isProfile, isGhost: true, onRemove: () {}, isInteractive: false))),
        childWhenDragging: Container(decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(16))),
        child: _FotoThumb(pathOrAsset: pathOrAsset, size: double.infinity, esPerfil: isProfile, isGhost: false, isInteractive: isProfile, onRemove: () {
          final current = List<String>.from(displayFotos);
          current.removeAt(index);
          ctrl.setFotos(current);
        }),
      ),
    );
  }

  void _setPreferenciaCitas(ProfileFormController ctrl, String v) { setState(() => _preferenciaCitas = v); ctrl.setPreferenciaCitas(v); }
  void _setGenero(ProfileFormController ctrl, String v) { setState(() => _genero = v); ctrl.setGenero(v); }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileFormProvider);
    final ctrl = ref.read(profileFormProvider.notifier);

    final List<String> paises = const ['Colombia', 'México', 'Argentina', 'Chile', 'Perú', 'España'];
    final Map<String, List<String>> ciudadesPorPais = const {'Colombia': ['Cali', 'Bogotá', 'Medellín', 'Barranquilla', 'Cartagena'], 'México': ['Ciudad de México', 'Guadalajara', 'Monterrey'], 'Argentina': ['Buenos Aires', 'Córdoba', 'Rosario'], 'Chile': ['Santiago', 'Valparaíso', 'Concepción'], 'Perú': ['Lima', 'Cusco', 'Arequipa'], 'España': ['Madrid', 'Barcelona', 'Valencia']};
    final List<String> ciudades = state.paisSeleccionado != null ? (ciudadesPorPais[state.paisSeleccionado!] ?? []) : [];
    final String? paisSafe = paises.contains(state.paisSeleccionado) ? state.paisSeleccionado : null;
    final String? ciudadSafe = ciudades.contains(state.ciudadSeleccionada) ? state.ciudadSeleccionada : null;

    const List<List<String>> sobreMiOpciones = [['💬 Soltero', '❤️ En una relación'], ['👶 Con hijo', '🙅‍♂️ Sin hijo'], ['🚬 Fumo', '🚭 No fumo'], ['🍷 Tomo', '🚫 No tomo'], ['🐶 Perros', '🐱 Gatos']];
    const List<String> buscoOpciones = ['💞 Relación estable', '🎉 Citas divertidas', '💬 Conversación', '👫 Amistad', '🌍 Conocer gente nueva', '🔥 Aventura', '💍 Pareja a largo plazo', '👀 Algo casual', '🎶 Compartir gustos', '✈️ Viajar juntos'];
    const List<String> interesesOpciones = ['🎬 Cine','🎵 Música','✈️ Viajar','📖 Lectura','☕ Café','🏃‍♂️ Running','🏋️ Gimnasio','🌄 Senderismo','🍷 Vino','🎨 Arte','🎮 Videojuegos','📸 Fotografía','🍳 Cocina','🏖️ Playa','🎭 Teatro','💃 Bailar','🎤 Cantar','🧘 Yoga','🧠 Filosofía','💼 Emprender','💻 Tecnología','💅 Moda','📺 Series','🎙️ Podcasts','🌿 Naturaleza','🏕️ Camping','⚽ Fútbol','🏀 Baloncesto','🚴‍♂️ Ciclismo','🏔️ Escalada','🐠 Buceo','🎯 Juegos de mesa','💫 Astrología','🐾 Voluntariado','🧑‍🍳 Comida gourmet','🎲 Rol','🛶 Kayak','💌 Escritura','📷 Selfies','🌙 Noche','☀️ Amaneceres','💃 Salsa','🎧 DJ','🎁 Regalos','🍕 Pizza','🥂 Brindar','📚 Manga','🌌 Meditar','💡 Innovar','🤟 Rock','🎫 Conciertos','⚡ Adrenalina','🏅 Deportes','🎭 Cosplay','🐾 Animalismo','📺 Streaming'];

    if (_isLoadingCloudData) return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(color: Color(0xFFBEB3FF))));

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/images/fondo.jpg', fit: BoxFit.cover)),
          Column(
            children: [
              const SizedBox(height: 35),
              Image.asset('assets/images/logomatchyplano.png', height: 50),
              const SizedBox(height: 15),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      // 🛡️ TÍTULO BLINDADO CORREGIDO
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: const Text(
                            'EDITA TU PERFIL',
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.0, shadows: kTextShadow)
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildTextField(label: 'Nombre *', controller: _nombreCtrl, showError: _mostrarErrores && !_nombreOk(state)),
                      const SizedBox(height: 14),
                      _buildTextField(label: 'Edad * (18-99)', controller: _edadCtrl, keyboardType: TextInputType.number, showError: _mostrarErrores && !_edadOk(state)),
                      const SizedBox(height: 14),
                      _buildTextField(label: 'Profesión', controller: _profesionCtrl),
                      const SizedBox(height: 14),
                      _buildTextField(label: 'Biografía', controller: _biografiaCtrl, maxLines: 4),
                      const SizedBox(height: 14),
                      _buildTextField(label: 'Un detalle que me enamora', controller: _detalleCtrl, maxLines: 3),
                      const SizedBox(height: 14),
                      GestureDetector(onTap: () => _seleccionarEstatura(context), child: AbsorbPointer(child: _buildTextField(label: 'Estatura (selección)', controller: _estaturaCtrl, suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.white)))),
                      const SizedBox(height: 20),
                      _buildPaisCiudadSection(paisSeleccionado: paisSafe, ciudadSeleccionada: ciudadSafe, paises: paises, ciudades: ciudades, showPaisError: _mostrarErrores && !_paisOk(state), showCiudadError: _mostrarErrores && !_ciudadOk(state), onPaisChanged: (v) => ctrl.setPais(v), onCiudadChanged: (v) => ctrl.setCiudad(v)),
                      const SizedBox(height: 25),
                      // ✅ TÍTULO GÉNERO CON * (OBLIGATORIO)
                      Align(alignment: Alignment.centerLeft, child: Text('GÉNERO *', style: TextStyle(color: (_mostrarErrores && !_generoOk()) ? Colors.redAccent : Colors.white70, fontWeight: FontWeight.bold, fontSize: kChincheTituloSeccion))),
                      const SizedBox(height: 10),
                      _GeneroSelector(value: _genero, showError: _mostrarErrores && !_generoOk(), onChanged: _saving ? null : (v) => _setGenero(ctrl, v)),
                      const SizedBox(height: 25),
                      // ✅ TÍTULO PREFERENCIA CON * (OBLIGATORIO)
                      Align(alignment: Alignment.centerLeft, child: Text('PREFERENCIA DE CITAS *', style: TextStyle(color: (_mostrarErrores && !_preferenciaOk()) ? Colors.redAccent : Colors.white70, fontWeight: FontWeight.bold, fontSize: kChincheTituloSeccion))),
                      const SizedBox(height: 10),
                      _PreferenciaCitasSelector(value: _preferenciaCitas, onChanged: _saving ? null : (v) => _setPreferenciaCitas(ctrl, v)),

                      const SizedBox(height: 30),
                      // 🛡️ TÍTULO GALERÍA BLINDADO
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('TUS FOTOS (MÁX 5) *', style: TextStyle(color: _mostrarErrores && !_fotosOk(state) ? Colors.redAccent : Colors.white, fontSize: kChincheTituloSeccion, fontWeight: FontWeight.w900)),
                        ),
                      ),
                      const SizedBox(height: 15),

                      GestureDetector(
                        onTap: _saving ? null : () => _mostrarPicker(context, ctrl, state),
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.6, height: 50,
                          decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFBEB3FF), Color(0xFF8A80CC)]), borderRadius: BorderRadius.circular(25), boxShadow: kChipShadow),
                          alignment: Alignment.center,
                          child: const Text('CARGAR FOTO', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 14)),
                        ),
                      ),
                      _buildFotoReorderArea(context: context, state: state, ctrl: ctrl),
                      const SizedBox(height: 24),
                      Text('SOBRE MÍ', style: TextStyle(color: Color(0xFFBEB3FF), fontSize: kChincheTituloSeccion, fontWeight: FontWeight.w900, shadows: kTextShadow)),
                      const SizedBox(height: 10),
                      // 🛡️ ALINEACIÓN ORIGINAL PRESERVADA
                      Column(
                        children: sobreMiOpciones.map((grupo) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: grupo.map((opcion) {
                                final sel = state.sobreMiSeleccion.contains(opcion);
                                return Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: GestureDetector(onTap: _saving ? null : () => ctrl.toggleSobreMi(opcion), child: Container(padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: sel ? const Color(0xFFBEB3FF) : const Color(0x1FFFFFFF), borderRadius: BorderRadius.circular(20), boxShadow: kChipShadow, border: Border.all(color: sel ? Colors.transparent : Colors.white12)), child: Text(opcion, textAlign: TextAlign.center, style: TextStyle(color: sel ? Colors.black : Colors.white, fontSize: 13, fontWeight: FontWeight.w600))))));
                              }).toList(),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 45),
                      _SeccionBotonesChipsSimetricos(titulo: 'BUSCO...', opciones: buscoOpciones, seleccionActual: state.buscoSeleccion, onToggle: (op) => _saving ? null : ctrl.toggleBusco(op)),
                      const SizedBox(height: 45),
                      _SeccionBotonesChipsSimetricos(titulo: 'INTERESES Y HOBBIES', opciones: interesesOpciones, seleccionActual: state.interesesSeleccion, onToggle: (op) => _saving ? null : ctrl.toggleInteres(op)),
                      const SizedBox(height: 40),
                      GestureDetector(
                        onTap: _saving ? null : () async {
                          // ✅ VALIDACIÓN CENTRALIZADA
                          if (_formularioValido(ref.read(profileFormProvider))) {
                            setState(() => _saving = true);
                            try {
                              await _syncProfileToFirestore(ref.read(profileFormProvider));
                              await ctrl.saveDraft(); await ctrl.publishProfile(); await ctrl.setOnboardingCompleted(true);
                              if (!mounted) return;
                              Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const PanelScreen()), (route) => false);
                            } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
                            finally { if (mounted) setState(() => _saving = false); }
                          } else {
                            setState(() => _mostrarErrores = true);
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(children: const [
                                    Icon(Icons.error_outline, color: Colors.white),
                                    SizedBox(width: 10),
                                    Expanded(child: Text("Faltan datos obligatorios (Nombre, Edad, País, Ciudad, Género, Preferencia o Foto)."))
                                  ]),
                                  backgroundColor: Colors.redAccent,
                                  behavior: SnackBarBehavior.floating,
                                )
                            );
                          }
                        },
                        child: Container(width: MediaQuery.of(context).size.width * 0.7, height: 55, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFBEB3FF), Color(0xFF8A80CC)]), borderRadius: BorderRadius.circular(30), boxShadow: kChipShadow), alignment: Alignment.center, child: _saving ? const CircularProgressIndicator(color: Colors.black) : const Text('GUARDAR PERFIL', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16))),
                      ),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(bottom: 0, left: 0, right: 0, height: 100, child: IgnorePointer(child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.9)]))))),
          const MatchyBackButton(top: 10, left: 16),
        ],
      ),
    );
  }

  Widget _buildTextField({required String label, required TextEditingController controller, int maxLines = 1, TextInputType? keyboardType, bool showError = false, Widget? suffixIcon}) {
    return Container(
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(15), border: Border.all(color: showError ? Colors.redAccent : Colors.white12)),
      child: TextField(
        controller: controller, maxLines: maxLines, keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: kChincheTextoInput),
        decoration: InputDecoration(labelText: label, labelStyle: TextStyle(color: showError ? Colors.redAccent : Colors.white60, fontSize: kChincheLabelInput), contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15), border: InputBorder.none, suffixIcon: suffixIcon),
      ),
    );
  }

  Widget _buildPaisCiudadSection({required String? paisSeleccionado, required String? ciudadSeleccionada, required List<String> paises, required List<String> ciudades, required ValueChanged<String?> onPaisChanged, required ValueChanged<String?> onCiudadChanged, required bool showPaisError, required bool showCiudadError}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('PAÍS *', style: TextStyle(color: showPaisError ? Colors.redAccent : Colors.white70, fontWeight: FontWeight.bold, fontSize: kChincheLabelInput)),
      const SizedBox(height: 8),
      Container(padding: const EdgeInsets.symmetric(horizontal: 15), decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(15), border: Border.all(color: showPaisError ? Colors.redAccent : Colors.white12)), child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: paisSeleccionado, dropdownColor: const Color(0xFF222222), iconEnabledColor: Colors.white, isExpanded: true, style: const TextStyle(color: Colors.white, fontSize: kChincheTextoInput), items: paises.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(), onChanged: onPaisChanged))),
      const SizedBox(height: 20),
      Text('CIUDAD *', style: TextStyle(color: showCiudadError ? Colors.redAccent : Colors.white70, fontWeight: FontWeight.bold, fontSize: kChincheLabelInput)),
      const SizedBox(height: 8),
      Container(padding: const EdgeInsets.symmetric(horizontal: 15), decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(15), border: Border.all(color: showCiudadError ? Colors.redAccent : Colors.white12)), child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: ciudadSeleccionada, dropdownColor: const Color(0xFF222222), iconEnabledColor: Colors.white, isExpanded: true, style: const TextStyle(color: Colors.white, fontSize: kChincheTextoInput), items: ciudades.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: onCiudadChanged))),
    ]);
  }
}

class _GeneroSelector extends StatelessWidget {
  final String value; final ValueChanged<String>? onChanged; final bool showError;
  const _GeneroSelector({required this.value, required this.onChanged, required this.showError});
  @override Widget build(BuildContext context) {
    // ✅ VALORES ESTANDARIZADOS PARA FILTRO FUTURO
    final opciones = [{'label': 'Hombre', 'value': 'Hombre'}, {'label': 'Mujer', 'value': 'Mujer'}, {'label': 'Otro', 'value': 'Otro'}, {'label': 'No decir', 'value': 'NoDecir'}];
    return Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: opciones.map((op) {
      final bool sel = op['value'] == value;
      return GestureDetector(onTap: onChanged == null ? null : () => onChanged!(op['value']!), child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: sel ? const Color(0xFFBEB3FF) : const Color(0x1FFFFFFF), borderRadius: BorderRadius.circular(50), boxShadow: _DatosScreenState.kChipShadow, border: showError && !sel && value.isEmpty ? Border.all(color: Colors.redAccent) : null), child: Text(op['label']!, style: TextStyle(color: sel ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 13))));
    }).toList());
  }
}

class _PreferenciaCitasSelector extends StatelessWidget {
  final String value; final ValueChanged<String>? onChanged;
  const _PreferenciaCitasSelector({required this.value, required this.onChanged});
  @override Widget build(BuildContext context) {
    const opciones = ['Hombres', 'Mujeres', 'Ambos'];
    return Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: opciones.map((op) {
      final bool sel = op == value;
      return GestureDetector(onTap: onChanged == null ? null : () => onChanged!(op), child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), decoration: BoxDecoration(color: sel ? const Color(0xFFBEB3FF) : const Color(0x1FFFFFFF), borderRadius: BorderRadius.circular(50), boxShadow: _DatosScreenState.kChipShadow), child: Text(op, style: TextStyle(color: sel ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 13))));
    }).toList());
  }
}

class _SeccionBotonesChipsSimetricos extends StatelessWidget {
  final String titulo; final List<String> opciones; final List<String> seleccionActual; final ValueChanged<String> onToggle;
  const _SeccionBotonesChipsSimetricos({required this.titulo, required this.opciones, required this.seleccionActual, required this.onToggle});

  List<List<String>> _chunk(List<String> list, int size) {
    final List<List<String>> chunks = [];
    for (var i = 0; i < list.length; i += size) {
      chunks.add(list.sublist(i, i + size > list.length ? list.length : i + size));
    }
    return chunks;
  }

  @override Widget build(BuildContext context) {
    final chunks = _chunk(opciones, 2);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(titulo, style: const TextStyle(color: Color(0xFFBEB3FF), fontSize: 18, fontWeight: FontWeight.w900, shadows: _DatosScreenState.kTextShadow)),
      const SizedBox(height: 12),
      Column(
        children: chunks.map((fila) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: fila.map((opcion) {
                final sel = seleccionActual.contains(opcion);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () => onToggle(opcion),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        decoration: BoxDecoration(
                            color: sel ? const Color(0xFFBEB3FF) : const Color(0x1FFFFFFF),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: _DatosScreenState.kChipShadow,
                            border: Border.all(color: sel ? Colors.transparent : Colors.white12)
                        ),
                        child: Center(
                            child: Text(opcion, textAlign: TextAlign.center, softWrap: true, style: TextStyle(color: sel ? Colors.black : Colors.white, fontSize: 12, fontWeight: FontWeight.w600))
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      )
    ]);
  }
}

class _FotoThumb extends StatelessWidget {
  final String pathOrAsset; final double size; final bool esPerfil; final bool isGhost; final VoidCallback onRemove; final bool isInteractive;
  const _FotoThumb({required this.pathOrAsset, required this.size, required this.esPerfil, required this.isGhost, required this.onRemove, required this.isInteractive});

  @override
  Widget build(BuildContext context) {
    final v = pathOrAsset.trim();
    if (v.isEmpty) return Container(width: size, height: size, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.broken_image, color: Colors.white24));
    ImageProvider provider = v.startsWith('http') ? NetworkImage(v) : (v.startsWith('assets/') ? AssetImage(v) as ImageProvider : FileImage(File(v)));

    return Opacity(
      opacity: isGhost ? 0.4 : 1.0,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: size, height: size, color: Colors.black,
              child: isInteractive
                  ? PhotoView(
                imageProvider: provider,
                initialScale: PhotoViewComputedScale.covered,
                minScale: PhotoViewComputedScale.covered,
                maxScale: PhotoViewComputedScale.covered * 3.0,
                backgroundDecoration: const BoxDecoration(color: Colors.black),
              )
                  : Image(image: provider, fit: BoxFit.cover),
            ),
          ),
          Positioned(top: 5, right: 5, child: GestureDetector(onTap: onRemove, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.close, size: 14, color: Colors.white)))),
          if (esPerfil) Positioned(bottom: 0, left: 0, right: 0, child: Container(padding: const EdgeInsets.symmetric(vertical: 4), decoration: BoxDecoration(color: const Color(0xFFBEB3FF).withOpacity(0.9), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16))), child: const Text('PERFIL', textAlign: TextAlign.center, style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 10)))),
        ],
      ),
    );
  }
}