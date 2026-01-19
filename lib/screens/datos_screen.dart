// 📂 lib/screens/datos_screen.dart
// ✅ DATOSSCREEN (DISEÑO FINAL PRO + ZONA SEGURA FOTO PERFIL INTERACTIVA)
// 🔥 REQUIERE PAQUETE: 'photo_view' en pubspec.yaml.
// 🔥 FIX UI FOTO PERFIL: Reemplazado Image estándar por 'PhotoView'.
//    Ahora el usuario puede hacer PAN y ZOOM real sobre su foto completa
//    para elegir el encuadre deseado dentro del marco cuadrado.
// 🔥 UI FOTOS: Layout "Capsula": Izquierda (Perfil Grande) | Derecha (Grid 2x2).
// ✅ DRAG & DROP: Funcional.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
// 🔥 IMPORTANTE: Importar el paquete photo_view
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
  // ==========================================================
  // 🔴🔴 ZONA DE CHINCHES MAESTROS (TAMAÑOS DE TEXTO) 🔴🔴
  // ==========================================================
  static const double kChincheTituloSeccion = 18.0;
  static const double kChincheLabelInput = 16.0;
  static const double kChincheTextoInput = 15.0;
  // ==========================================================

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
    } catch (e) {
      debugPrint("Error recuperando datos: $e");
    }
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

  // ===================== VALIDACIONES =====================
  bool _nombreOk(ProfileFormState s) => s.nombre.trim().isNotEmpty;
  bool _edadOk(ProfileFormState s) {
    final edadInt = int.tryParse(s.edad.trim());
    return edadInt != null && edadInt >= 18 && edadInt <= 99;
  }
  bool _paisOk(ProfileFormState s) => (s.paisSeleccionado ?? '').trim().isNotEmpty;
  bool _ciudadOk(ProfileFormState s) => (s.ciudadSeleccionada ?? '').trim().isNotEmpty;
  bool _generoOk() => _genero.trim().isNotEmpty;
  bool _fotosOk(ProfileFormState s) => s.photoUrls.isNotEmpty || s.fotosCargadas.isNotEmpty;

  bool _isAssetPath(String v) => v.startsWith('assets/');
  bool _isNetworkUrl(String v) => v.startsWith('http://') || v.startsWith('https://');
  bool _isGsUrl(String v) => v.startsWith('gs://');

  List<String> _buildDisplayFotos(ProfileFormState s) {
    final out = <String>[];
    for (final raw in s.fotosCargadas) {
      final v = raw.trim();
      if (v.isEmpty) continue;
      out.add(v);
    }
    return out;
  }

  Future<List<String>> _uploadRealPhotosToStorage({
    required String uid,
    required List<String> fotosCargadas,
  }) async {
    final urls = <String>[];
    final filesToUpload = fotosCargadas.where((p) => p.trim().isNotEmpty && !_isAssetPath(p) && !_isNetworkUrl(p) && !_isGsUrl(p)).toList();

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
    final int? edadInt = int.tryParse(s.edad.trim());
    final List<String> localRaw = List<String>.from(s.fotosCargadas);
    final existingUrls = localRaw.where((p) => _isNetworkUrl(p.trim())).toList();

    final uploadedUrls = await _uploadRealPhotosToStorage(uid: uid, fotosCargadas: localRaw);

    final List<String> photoUrls = [...existingUrls, ...uploadedUrls].map((e) => e.trim()).where((e) => _isNetworkUrl(e)).toList();
    final String? profilePhotoUrl = photoUrls.isNotEmpty ? photoUrls.first : null;
    final List<String> photosAssets = localRaw.where((p) => _isAssetPath(p.trim())).toList();
    final List<String> photosLocalPathsSafe = [...photosAssets, ...existingUrls];

    final payload = <String, dynamic>{
      'uid': uid,
      'email': user.email,
      'provider': user.providerData.isNotEmpty ? user.providerData.first.providerId : null,
      'nombre': s.nombre.trim(),
      'edad': edadInt,
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
      'profilePhotoUrl': profilePhotoUrl,
      'photosAssets': photosAssets,
      'photosLocalPaths': photosLocalPathsSafe,
      'profilePhotoLocalPath': photosLocalPathsSafe.isNotEmpty ? photosLocalPathsSafe.first : null,
      'onboarding_completed': true,
      'updatedAt': FieldValue.serverTimestamp(),
      'lastProfileUpdateAt': FieldValue.serverTimestamp(),
    };

    final snap = await docRef.get();
    if (!snap.exists) payload['createdAt'] = FieldValue.serverTimestamp();
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
      if (file != null) {
        ctrl.addFoto(file.path);
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  // =========================================================================
  // 🔥 UI FOTOS: CÁPSULA 1+4 (Izquierda: Perfil INTERACTIVO, Derecha: Grid 2x2)
  // =========================================================================
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.touch_app_rounded, color: Color(0xFFBEB3FF), size: 16),
              SizedBox(width: 8),
              Text("Arrastra para reordenar. Pellizca la principal para ajustar.", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),

          // Layout dividido en dos mitades
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. MITAD IZQUIERDA: Foto de Perfil (Grande e Interactiva)
              Expanded(
                flex: 1,
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: Stack(
                    children: [
                      _buildDraggablePhotoSlot(
                          index: 0,
                          displayFotos: displayFotos,
                          ctrl: ctrl,
                          isProfile: true // 🔥 Activa el modo interactivo
                      ),
                      if (displayFotos.isNotEmpty)
                        Positioned(
                          bottom: 8, right: 8,
                          child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.zoom_out_map, color: Colors.white, size: 14)
                          ),
                        )
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // 2. MITAD DERECHA: Grid 2x2 (Estáticas)
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

  // Helper para construir cada slot arrastrable
  Widget _buildDraggablePhotoSlot({
    required int index,
    required List<String> displayFotos,
    required ProfileFormController ctrl,
    bool isProfile = false,
  }) {
    if (index >= displayFotos.length) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: const Icon(Icons.add_photo_alternate, color: Colors.white12, size: 20),
      );
    }

    final pathOrAsset = displayFotos[index];

    return DragTarget<int>(
      onWillAccept: (from) => from != null && from != index,
      onAccept: (from) {
        final current = List<String>.from(displayFotos);
        if (from < 0 || from >= current.length) return;
        final item = current.removeAt(from);
        current.insert(index, item);
        ctrl.setFotos(current);
      },
      builder: (context, _, __) => LongPressDraggable<int>(
        data: index,
        feedback: Opacity(
            opacity: 0.85,
            child: SizedBox(
                width: 80, height: 80,
                // Feedback siempre estático (isInteractive: false)
                child: _FotoThumb(pathOrAsset: pathOrAsset, size: 80, esPerfil: isProfile, isGhost: true, onRemove: () {}, isInteractive: false)
            )
        ),
        childWhenDragging: Container(
          decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(16)),
        ),
        child: _FotoThumb(
            pathOrAsset: pathOrAsset,
            size: double.infinity,
            esPerfil: isProfile,
            isGhost: false,
            isInteractive: isProfile, // 🔥 Solo la principal es interactiva
            onRemove: () {
              final current = List<String>.from(displayFotos);
              current.removeAt(index);
              ctrl.setFotos(current);
            }
        ),
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

    final bool puedeContinuar = ctrl.puedeGuardar && ctrl.isDirty;
    final bool showErrors = _mostrarErrores;
    final bool showGeneroError = showErrors && !_generoOk();

    if (_isLoadingCloudData) {
      return Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(color: Color(0xFFBEB3FF))));
    }

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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text('EDITA TU PERFIL', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                      if (state.error != null) ...[const SizedBox(height: 10), Text(state.error!, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))],
                      const SizedBox(height: 24),

                      _buildTextField(label: 'Nombre *', controller: _nombreCtrl, showError: showErrors && !_nombreOk(state), errorText: 'Campo obligatorio'),
                      const SizedBox(height: 14),
                      _buildTextField(label: 'Edad * (18-99)', controller: _edadCtrl, keyboardType: TextInputType.number, showError: showErrors && !_edadOk(state), errorText: 'Edad inválida'),
                      const SizedBox(height: 14),
                      _buildTextField(label: 'Profesión', controller: _profesionCtrl),
                      const SizedBox(height: 14),
                      _buildTextField(label: 'Biografía', controller: _biografiaCtrl, maxLines: 4),
                      const SizedBox(height: 14),
                      _buildTextField(label: 'Un detalle que me enamora', controller: _detalleCtrl, maxLines: 3),
                      const SizedBox(height: 14),
                      GestureDetector(onTap: () => _seleccionarEstatura(context), child: AbsorbPointer(child: _buildTextField(label: 'Estatura (selección)', controller: _estaturaCtrl, suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.white)))),
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
                      const SizedBox(height: 25),

                      Align(alignment: Alignment.centerLeft, child: Text('GÉNERO *', style: TextStyle(color: showGeneroError ? Colors.redAccent : Colors.white70, fontWeight: FontWeight.bold, fontSize: _DatosScreenState.kChincheTituloSeccion, letterSpacing: 1.0))),
                      const SizedBox(height: 10),
                      _GeneroSelector(value: _genero, showError: showGeneroError, onChanged: _saving ? null : (v) => _setGenero(ctrl, v)),

                      const SizedBox(height: 25),
                      Align(alignment: Alignment.centerLeft, child: Text('PREFERENCIA DE CITAS', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: _DatosScreenState.kChincheTituloSeccion, letterSpacing: 1.0))),
                      const SizedBox(height: 10),
                      _PreferenciaCitasSelector(value: _preferenciaCitas, onChanged: _saving ? null : (v) => _setPreferenciaCitas(ctrl, v)),

                      const SizedBox(height: 30),
                      Text('TUS FOTOS (MÁX 5) *', style: TextStyle(color: showErrors && !_fotosOk(state) ? Colors.redAccent : Colors.white, fontSize: _DatosScreenState.kChincheTituloSeccion, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 15),

                      GestureDetector(
                        onTap: _saving ? null : () => _mostrarPicker(context, ctrl, state),
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.6,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFFBEB3FF), Color(0xFF8A80CC)]),
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                          ),
                          alignment: Alignment.center,
                          child: const Text('CARGAR FOTO', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 14)),
                        ),
                      ),

                      _buildFotoReorderArea(context: context, state: state, ctrl: ctrl),

                      const SizedBox(height: 24),
                      Text('SOBRE MÍ', style: TextStyle(color: Color(0xFFBEB3FF), fontSize: _DatosScreenState.kChincheTituloSeccion, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
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
                                      onTap: _saving ? null : () => ctrl.toggleSobreMi(opcion),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                        decoration: BoxDecoration(
                                            color: seleccionado ? const Color(0xFFBEB3FF) : const Color(0x1FFFFFFF),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(color: seleccionado ? Colors.transparent : Colors.white12)
                                        ),
                                        child: Center(
                                            child: Text(opcion, textAlign: TextAlign.center, style: TextStyle(color: seleccionado ? Colors.black : Colors.white, fontSize: 13, fontWeight: FontWeight.w600))
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

                      const SizedBox(height: 45),
                      _SeccionBotonesChipsSimetricos(titulo: 'BUSCO...', opciones: buscoOpciones, seleccionActual: state.buscoSeleccion, onToggle: (op) => _saving ? null : ctrl.toggleBusco(op)),

                      const SizedBox(height: 45),
                      _SeccionBotonesChipsSimetricos(titulo: 'INTERESES Y HOBBIES', opciones: interesesOpciones, seleccionActual: state.interesesSeleccion, onToggle: (op) => _saving ? null : ctrl.toggleInteres(op)),

                      const SizedBox(height: 40),
                      GestureDetector(
                        onTap: (_saving) ? null : (puedeContinuar ? () async {
                          setState(() => _saving = true);
                          try {
                            final urls = await _syncProfileToFirestore(ref.read(profileFormProvider));
                            if (urls.isNotEmpty) ctrl.setFotos(urls);
                            await ctrl.saveDraft();
                            await ctrl.publishProfile();
                            await ctrl.setOnboardingCompleted(true);
                            if (!mounted) return;
                            Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const PanelScreen()), (route) => false);
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
                          } finally {
                            if (mounted) setState(() => _saving = false);
                          }
                        } : () => setState(() => _mostrarErrores = true)),
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.7,
                          height: 55,
                          decoration: BoxDecoration(
                            gradient: puedeContinuar
                                ? const LinearGradient(colors: [Color(0xFFBEB3FF), Color(0xFF8A80CC)])
                                : const LinearGradient(colors: [Colors.grey, Colors.blueGrey]),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 5))],
                          ),
                          alignment: Alignment.center,
                          child: _saving
                              ? const CircularProgressIndicator(color: Colors.black)
                              : const Text('GUARDAR PERFIL', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.0)),
                        ),
                      ),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          ),

          Positioned(
            bottom: 0, left: 0, right: 0, height: 100,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),
          ),

          const MatchyBackButton(top: 10, left: 16),
        ],
      ),
    );
  }

  // HELPERS UI Y WIDGETS INTERNOS
  Widget _buildTextField({required String label, required TextEditingController controller, int maxLines = 1, TextInputType? keyboardType, bool showError = false, String? errorText, Widget? suffixIcon}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: showError ? Colors.redAccent : Colors.white12),
      ),
      child: TextField(
        controller: controller, maxLines: maxLines, keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: _DatosScreenState.kChincheTextoInput),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: showError ? Colors.redAccent : Colors.white60, fontSize: _DatosScreenState.kChincheLabelInput),
          errorText: showError ? (errorText ?? 'Campo obligatorio') : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          border: InputBorder.none,
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  Widget _buildPaisCiudadSection({required String? paisSeleccionado, required String? ciudadSeleccionada, required List<String> paises, required List<String> ciudades, required ValueChanged<String?> onPaisChanged, required ValueChanged<String?> onCiudadChanged, required bool showPaisError, required bool showCiudadError}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('PAÍS *', style: TextStyle(color: showPaisError ? Colors.redAccent : Colors.white70, fontWeight: FontWeight.bold, fontSize: kChincheLabelInput, letterSpacing: 1.0)),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(15), border: Border.all(color: showPaisError ? Colors.redAccent : Colors.white12)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
              value: paisSeleccionado, dropdownColor: const Color(0xFF222222), iconEnabledColor: Colors.white, isExpanded: true, style: const TextStyle(color: Colors.white, fontSize: kChincheTextoInput),
              items: paises.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(), onChanged: onPaisChanged
          ),
        ),
      ),
      const SizedBox(height: 20),
      Text('CIUDAD *', style: TextStyle(color: showCiudadError ? Colors.redAccent : Colors.white70, fontWeight: FontWeight.bold, fontSize: kChincheLabelInput, letterSpacing: 1.0)),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(15), border: Border.all(color: showCiudadError ? Colors.redAccent : Colors.white12)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
              value: ciudadSeleccionada, dropdownColor: const Color(0xFF222222), iconEnabledColor: Colors.white, isExpanded: true, style: const TextStyle(color: Colors.white, fontSize: kChincheTextoInput),
              items: ciudades.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: ciudades.isEmpty ? null : onCiudadChanged
          ),
        ),
      ),
    ]);
  }
}

// Widgets Auxiliares (Género, Preferencia, Chips...)
class _GeneroSelector extends StatelessWidget {
  final String value; final ValueChanged<String>? onChanged; final bool showError;
  const _GeneroSelector({required this.value, required this.onChanged, required this.showError});
  @override Widget build(BuildContext context) {
    final opciones = [{'label': 'Hombre', 'value': kGeneroHombre}, {'label': 'Mujer', 'value': kGeneroMujer}, {'label': 'Otro género', 'value': kGeneroOtro}, {'label': 'Prefiero no decirlo', 'value': kGeneroNoDecir}];
    return Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: opciones.map((op) {
      final bool selected = op['value'] == value;
      return GestureDetector(onTap: onChanged == null ? null : () => onChanged!(op['value']!), child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: selected ? const Color(0xFFBEB3FF) : const Color(0x1FFFFFFF), borderRadius: BorderRadius.circular(50), border: showError && !selected && value.isEmpty ? Border.all(color: Colors.redAccent) : null), child: Text(op['label']!, style: TextStyle(color: selected ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 13))));
    }).toList());
  }
}

class _PreferenciaCitasSelector extends StatelessWidget {
  final String value; final ValueChanged<String>? onChanged;
  const _PreferenciaCitasSelector({required this.value, required this.onChanged});
  @override Widget build(BuildContext context) {
    const opciones = ['Hombres', 'Mujeres', 'Ambos'];
    return Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: opciones.map((op) {
      final bool selected = op == value;
      return GestureDetector(onTap: onChanged == null ? null : () => onChanged!(op), child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), decoration: BoxDecoration(color: selected ? const Color(0xFFBEB3FF) : const Color(0x1FFFFFFF), borderRadius: BorderRadius.circular(50)), child: Text(op, style: TextStyle(color: selected ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 13))));
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
      Text(titulo, style: TextStyle(color: const Color(0xFFBEB3FF), fontSize: _DatosScreenState.kChincheTituloSeccion, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
      const SizedBox(height: 12),
      Column(
        children: chunks.map((fila) {
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
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        decoration: BoxDecoration(
                            color: seleccionado ? const Color(0xFFBEB3FF) : const Color(0x1FFFFFFF),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: seleccionado ? Colors.transparent : Colors.white12)
                        ),
                        child: Center(
                            child: Text(opcion, textAlign: TextAlign.center, softWrap: true, style: TextStyle(color: seleccionado ? Colors.black : Colors.white, fontSize: 12, fontWeight: FontWeight.w600))
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

// =============================================================================
// 🔥 WIDGET FOTO THUMB (CON PHOTO_VIEW INTEGRADO) 🔥
// =============================================================================
// Este widget ahora usa 'PhotoView' cuando 'isInteractive' es true,
// permitiendo pan y zoom fluido para ajustar el encuadre dentro del marco.
class _FotoThumb extends StatelessWidget {
  final String pathOrAsset;
  final double size;
  final bool esPerfil;
  final bool isGhost;
  final VoidCallback onRemove;
  final bool isInteractive; // 🔥 Nueva propiedad

  const _FotoThumb({
    required this.pathOrAsset,
    required this.size,
    required this.esPerfil,
    required this.isGhost,
    required this.onRemove,
    this.isInteractive = false, // Por defecto false (para las fotos pequeñas)
  });

  bool _isAssetPath(String v) => v.startsWith('assets/');
  bool _isNetworkUrl(String v) => v.startsWith('http');

  @override
  Widget build(BuildContext context) {
    final v = pathOrAsset.trim();
    ImageProvider imageProvider;

    // 1. Determinar el proveedor de imagen correcto
    if (v.isEmpty) {
      // Placeholder si no hay imagen
      return _buildPlaceholder();
    } else if (_isAssetPath(v)) {
      imageProvider = AssetImage(v);
    } else if (_isNetworkUrl(v)) {
      imageProvider = NetworkImage(v);
    } else {
      imageProvider = FileImage(File(v));
    }

    Widget content;

    // 2. 🔥 Si es interactiva (Perfil), usar PhotoView para pan/zoom
    if (isInteractive) {
      content = PhotoView(
        imageProvider: imageProvider,
        // 'covered' asegura que la imagen llene el cuadro inicialmente sin bordes negros
        initialScale: PhotoViewComputedScale.covered,
        minScale: PhotoViewComputedScale.covered,
        // Permite hacer zoom hasta 2.5 veces el tamaño inicial
        maxScale: PhotoViewComputedScale.covered * 2.5,
        backgroundDecoration: const BoxDecoration(color: Colors.transparent),
        // Ocultar el indicador de carga nativo de PhotoView, ya que lo manejamos externamente si es necesario
        loadingBuilder: (_, __) => const Center(child: CircularProgressIndicator(color: Color(0xFFBEB3FF), strokeWidth: 2)),
        errorBuilder: (_, __, ___) => const Icon(Icons.error, color: Colors.redAccent),
      );
    } else {
      // 3. Si no es interactiva (las pequeñas), usar Image estándar con cover
      content = Image(image: imageProvider, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.error, color: Colors.white70));
    }

    // 4. Estructura final del thumb (Marco, Botón eliminar, Etiqueta perfil)
    return Opacity(
      opacity: isGhost ? 0.4 : 1.0,
      child: Stack(
        children: [
          // Marco redondeado con la imagen (o PhotoView) dentro
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: size,
              height: size,
              color: Colors.grey[900], // Fondo oscuro mientras carga
              child: content,
            ),
          ),
          // Botón eliminar (X)
          Positioned(
            top: 5, right: 5,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
          // Etiqueta "PERFIL"
          if (esPerfil)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFBEB3FF).withOpacity(0.9),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
                child: const Text('PERFIL', textAlign: TextAlign.center, style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.0)),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Opacity(
      opacity: isGhost ? 0.4 : 1.0,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
        child: const Icon(Icons.broken_image, color: Colors.white24),
      ),
    );
  }
}