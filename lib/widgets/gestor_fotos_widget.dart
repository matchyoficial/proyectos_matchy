// 📂 lib/widgets/gestor_fotos_widget.dart
// ✅ GESTOR DE FOTOS - SALA DE ESPERA BLINDADA Y FONDO NEGRO PURO
// ⏳ SALA DE ESPERA: La foto no se guarda hasta que Amazon responda.
// 🛡️ RADAR ACTIVADO: Sincronización perfecta anti-retrasos.
// 🚫 ESCUDO ANTI-X ROJA: Manejo nativo de errores 404 de Flutter.
// ⚖️ LEGAL UX: Advertencia preventiva con estilo premium neón.
// 🆕 FIX: no se puede borrar la última foto restante (evita perfiles sin foto).
// 🆕 FIX: _updatePhotosInFirestore ahora usa set(merge:true) en vez de update(),
//    para que nunca falle en silencio si el documento del usuario aún no existe.
// 🆕 FIX: _mostrarBurbujaRechazo ahora acepta un título opcional, para poder
//    reusar la misma burbuja visual en el aviso de "no se puede borrar".

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:proyectos_matchy/screens/custom_cropper_screen.dart';
import 'package:proyectos_matchy/state/profile_form_provider.dart';

class GestorFotosWidget extends ConsumerStatefulWidget {
  const GestorFotosWidget({super.key});

  @override
  ConsumerState<GestorFotosWidget> createState() => _GestorFotosWidgetState();
}

class _GestorFotosWidgetState extends ConsumerState<GestorFotosWidget> {
  final ImagePicker _picker = ImagePicker();

  // 🚦 Variables de la Sala de Espera
  bool _isWaitingForAmazon = false;
  String? _pendingUrl;

  StreamSubscription<DocumentSnapshot>? _radarSubscription;

  // 🎨 Estilos Neón / Premium
  static const List<BoxShadow> kNeonShadowCyan = [
    BoxShadow(color: Colors.cyanAccent, blurRadius: 10, offset: Offset(0, 0), spreadRadius: -2)
  ];
  static const List<BoxShadow> kNeonShadowOrange = [
    BoxShadow(color: Colors.orangeAccent, blurRadius: 15, offset: Offset(0, 0), spreadRadius: -2)
  ];
  static const List<BoxShadow> kNeonShadowMagenta = [
    BoxShadow(color: Colors.purpleAccent, blurRadius: 10, offset: Offset(0, 0), spreadRadius: -2)
  ];

  @override
  void initState() {
    super.initState();
    _activarRadarModeracion();
  }

  // 📡 EL RADAR: Escucha las decisiones del Robot de Amazon en tiempo real
  void _activarRadarModeracion() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _radarSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;

        // ❌ CASO RECHAZO
        if (data['foto_estado'] == 'rechazada') {
          final motivo = data['foto_motivo'] ?? 'Contenido no permitido';

          // 1. Mostrar Burbuja Neón
          _mostrarBurbujaRechazo(motivo);

          // 2. Apagar el spinner y limpiar la sala de espera inmediatamente
          if (mounted) {
            setState(() {
              _isWaitingForAmazon = false;
              _pendingUrl = null;
            });
          }

          // 3. Limpiar el billete de infracción en BD para no hacer spam
          try {
            snapshot.reference.update({
              'foto_estado': FieldValue.delete(),
              'foto_motivo': FieldValue.delete(),
            });
          } catch (e) {
            debugPrint("Info: Limpieza de BD interceptada o en proceso.");
          }
        }
        // ✅ CASO APROBADA
        else if (data['foto_estado'] == 'aprobada') {

          // Si teníamos una foto esperando, la guardamos oficialmente
          if (_pendingUrl != null) {
            final ctrl = ref.read(profileFormProvider.notifier);
            ctrl.addFoto(_pendingUrl!);
            final updatedList = _buildDisplayFotos(ref.read(profileFormProvider));
            _updatePhotosInFirestore(updatedList);
          }

          // Apagar el spinner y limpiar la sala de espera
          if (mounted) {
            setState(() {
              _isWaitingForAmazon = false;
              _pendingUrl = null;
            });
          }

          // Limpiar el sello de aprobación de la BD
          try {
            snapshot.reference.update({'foto_estado': FieldValue.delete()});
          } catch (e) {
            debugPrint("Info: Limpieza de BD interceptada.");
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _radarSubscription?.cancel();
    super.dispose();
  }

  // 🔥 SISTEMA DE BURBUJAS DE RECHAZO (NEÓN MAGENTA/ROJO)
  // 🆕 FIX: parámetro 'titulo' opcional (por defecto "FOTO RECHAZADA", igual que antes)
  // para poder reusar esta misma burbuja en el aviso de "no se puede borrar".
  void _mostrarBurbujaRechazo(String motivo, {String titulo = "FOTO RECHAZADA"}) {
    if (!mounted) return;
    final overlayState = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 80, left: 25, right: 25),
            child: Material(
              color: Colors.transparent,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF151515).withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.pinkAccent.withOpacity(0.8), width: 1.5),
                    boxShadow: kNeonShadowMagenta,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.pinkAccent.withOpacity(0.2), shape: BoxShape.circle),
                        child: const Icon(Icons.warning_rounded, color: Colors.pinkAccent, size: 28),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(titulo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, fontFamily: 'Poppins')),
                            Text(motivo, style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Poppins')),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlayState.insert(entry);
    Future.delayed(const Duration(seconds: 4), () {
      if (entry.mounted) entry.remove();
    });
  }

  // 🗑️ DESTRUCTOR FÍSICO: Borra la foto de Firebase Storage
  Future<void> _deletePhotoFromStorage(String url) async {
    try {
      if (url.startsWith('http') && url.contains('firebasestorage')) {
        final ref = FirebaseStorage.instance.refFromURL(url);
        await ref.delete();
        debugPrint('🗑️ Foto eliminada físicamente del Storage (Cero Basura).');
      }
    } catch (e) {
      debugPrint('⚠️ Error al borrar foto física: $e');
    }
  }

  // 🔥 SUBIDA UNITARIA A FIREBASE
  Future<String?> _uploadSinglePhotoToStorage(String path) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    try {
      final file = File(path);
      if (!file.existsSync()) return null;
      final fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}.png';
      final ref = FirebaseStorage.instance.ref().child('users/${user.uid}/photos/$fileName');
      final task = await ref.putFile(file);
      return await task.ref.getDownloadURL();
    } catch (e) {
      debugPrint("Error subiendo foto unitaria: $e");
      return null;
    }
  }

  // 🔥 ACTUALIZACIÓN ATÓMICA EN FIRESTORE
  // 🆕 FIX: se cambió update() por set(merge:true) — update() lanzaba una excepción
  // silenciosa (atrapada en el catch de abajo) cuando el documento del usuario todavía
  // no existía, como pasa con la primera foto de un usuario recién registrado.
  Future<void> _updatePhotosInFirestore(List<String> urls) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'photoUrls': urls,
        'profilePhotoUrl': urls.isNotEmpty ? urls.first : null,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error actualizando Firestore: $e");
    }
  }

  // 🛠️ FLUJO DE IMPORTACIÓN -> SALA DE ESPERA
  Future<void> _pickAndCropImage(ImageSource source, ProfileFormController ctrl, ProfileFormState state) async {
    final display = _buildDisplayFotos(state);
    if (display.length >= 5) {
      _mostrarBurbujaRechazo("Ya has alcanzado el límite de 5 fotos.");
      return;
    }

    try {
      final XFile? file = await _picker.pickImage(source: source);
      if (file != null) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CustomCropperScreen(imagePath: file.path)),
        );

        if (result != null && result is String) {
          // ⏳ Activamos la Sala de Espera (Spinner ON)
          setState(() => _isWaitingForAmazon = true);

          // Failsafe: Si ocurre un error de red y el radar no responde en 15 segundos, apagamos el spinner.
          Timer(const Duration(seconds: 15), () {
            if (_isWaitingForAmazon && mounted) {
              setState(() { _isWaitingForAmazon = false; _pendingUrl = null; });
            }
          });

          final fireUrl = await _uploadSinglePhotoToStorage(result);
          if (fireUrl != null) {
            // Solo lo guardamos si el radar no nos ha cancelado ya la espera
            if (_isWaitingForAmazon) {
              _pendingUrl = fireUrl;
            }
          } else {
            // Fallo de subida
            if (mounted) setState(() => _isWaitingForAmazon = false);
          }
        }
      }
    } catch (e) {
      debugPrint("Error al seleccionar foto: $e");
      if (mounted) setState(() => _isWaitingForAmazon = false);
    }
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

  Future<void> _mostrarSelectorOrigen(BuildContext context, ProfileFormController ctrl, ProfileFormState state) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20))),
            const SizedBox(height: 14),
            const Text('ORIGEN DE LA FOTO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.cyanAccent),
              title: const Text('Galería de Imágenes', style: TextStyle(color: Colors.white)),
              onTap: () { Navigator.pop(context); _pickAndCropImage(ImageSource.gallery, ctrl, state); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera, color: Colors.orangeAccent),
              title: const Text('Tomar Foto Ahora', style: TextStyle(color: Colors.white)),
              onTap: () { Navigator.pop(context); _pickAndCropImage(ImageSource.camera, ctrl, state); },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileFormProvider);
    final ctrl = ref.read(profileFormProvider.notifier);
    final displayFotos = _buildDisplayFotos(state);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ⚖️ AVISO LEGAL PREVENTIVO (Infografía Neón)
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0A),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.orangeAccent.withOpacity(0.4), width: 1),
            boxShadow: kNeonShadowOrange,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.gavel_rounded, color: Colors.orangeAccent, size: 18),
                  SizedBox(width: 8),
                  Text("NORMAS DE COMUNIDAD", style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.2)),
                ],
              ),
              const SizedBox(height: 10),
              _buildReglaItem(Icons.child_care, "Prohibido fotos de o con menores de edad."),
              const SizedBox(height: 6),
              _buildReglaItem(Icons.no_photography, "Prohibido desnudez o contenido sexual."),
              const SizedBox(height: 6),
              _buildReglaItem(Icons.dangerous, "Prohibido exhibir armas (reales o utilería) y violencia."),
              const SizedBox(height: 10),
              const Text(
                "Nuestro sistema de Inteligencia Artificial borrará automáticamente cualquier foto infractora.",
                style: TextStyle(color: Colors.white54, fontSize: 12, fontStyle: FontStyle.italic),
              )
            ],
          ),
        ),

        // 🔘 BOTÓN CARGAR FOTO
        GestureDetector(
          onTap: _isWaitingForAmazon ? null : () => _mostrarSelectorOrigen(context, ctrl, state),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.6,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFFBEB3FF)]), // Cyan to Matchy Purple
              borderRadius: BorderRadius.circular(25),
              boxShadow: kNeonShadowCyan,
            ),
            alignment: Alignment.center,
            child: const Text('SUBIR FOTO', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1)),
          ),
        ),
        const SizedBox(height: 20),

        // 📸 CUADRÍCULA DE FOTOS
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white10),
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 15, offset: Offset(0, 5))],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.touch_app_rounded, color: Color(0xFFBEB3FF), size: 16),
                    SizedBox(width: 8),
                    Text("Mantén presionado y arrastra para ordenar.", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                      flex: 1,
                      child: AspectRatio(aspectRatio: 1.0, child: _buildDraggablePhotoSlot(index: 0, displayFotos: displayFotos, ctrl: ctrl, isProfile: true))
                  ),
                  const SizedBox(width: 10),
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
        ),
      ],
    );
  }

  Widget _buildReglaItem(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white70, size: 14),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500))),
      ],
    );
  }

  Widget _buildDraggablePhotoSlot({required int index, required List<String> displayFotos, required ProfileFormController ctrl, bool isProfile = false}) {
    // 🚦 LÓGICA SALA DE ESPERA: Muestra el spinner (FONDO NEGRO)
    if (index == displayFotos.length && _isWaitingForAmazon) {
      return Container(
        decoration: BoxDecoration(
            color: Colors.black, // Fondo negro puro garantizado
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.cyanAccent, width: 1.5)
        ),
        child: const Center(child: CircularProgressIndicator(color: Colors.cyanAccent, strokeWidth: 2)),
      );
    }

    // 🔲 SLOT VACÍO NORMAL (FONDO NEGRO)
    if (index >= displayFotos.length) {
      return Container(
        decoration: BoxDecoration(
            color: Colors.black, // Fondo negro puro garantizado
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10, style: BorderStyle.solid)
        ),
        child: const Icon(Icons.add, color: Colors.white24, size: 30),
      );
    }

    final pathOrAsset = displayFotos[index];

    return DragTarget<int>(
      onWillAccept: (from) => from != null && from != index && !_isWaitingForAmazon,
      onAccept: (from) async {
        final current = List<String>.from(displayFotos);
        final item = current.removeAt(from);
        current.insert(index, item);
        ctrl.setFotos(current);
        if (index == 0 || from == 0) await _updatePhotosInFirestore(current);
      },
      builder: (context, _, __) => LongPressDraggable<int>(
        data: index,
        feedback: Opacity(
            opacity: 0.85,
            child: SizedBox(
                width: 80, height: 80,
                child: _FotoThumb(pathOrAsset: pathOrAsset, esPerfil: isProfile, isGhost: true, onRemove: () {})
            )
        ),
        childWhenDragging: Container(decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16))),
        child: _FotoThumb(
            pathOrAsset: pathOrAsset,
            esPerfil: isProfile,
            isGhost: false,
            onRemove: () async {
              if (_isWaitingForAmazon) return;
              // 🆕 FIX: no se permite borrar la última foto restante — antes esto dejaba
              // el perfil sin ninguna foto sin ningún aviso ni candado.
              if (displayFotos.length <= 1) {
                _mostrarBurbujaRechazo(
                  "Debes tener al menos 1 foto de perfil. Sube una nueva antes de borrar esta.",
                  titulo: "NO SE PUEDE BORRAR",
                );
                return;
              }
              final current = List<String>.from(displayFotos);
              final urlToDelete = current.removeAt(index);

              ctrl.setFotos(current);
              await _updatePhotosInFirestore(current);
              _deletePhotoFromStorage(urlToDelete);
            }
        ),
      ),
    );
  }
}

// 📸 WIDGET DE MINIATURA BLINDADO CONTRO ERRORES DE FLUTTER
class _FotoThumb extends StatelessWidget {
  final String pathOrAsset;
  final bool esPerfil;
  final bool isGhost;
  final VoidCallback onRemove;

  const _FotoThumb({required this.pathOrAsset, required this.esPerfil, required this.isGhost, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final v = pathOrAsset.trim();
    if (v.isEmpty) {
      return Container(
          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.broken_image, color: Colors.white24)
      );
    }

    ImageProvider provider = v.startsWith('http')
        ? NetworkImage(v)
        : (v.startsWith('assets/') ? AssetImage(v) as ImageProvider : FileImage(File(v)));

    return Opacity(
      opacity: isGhost ? 0.4 : 1.0,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                  color: Colors.black, // Fondo negro puro debajo de la imagen
                  child: Image(
                    image: provider,
                    fit: BoxFit.cover,
                    // 🛡️ ESCUDO ANTI-X ROJA: Si Flutter intenta cargar una foto borrada
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.black,
                        child: const Center(
                          child: Icon(Icons.image_not_supported, color: Colors.white24, size: 30),
                        ),
                      );
                    },
                  )
              )
          ),

          Positioned(
              top: 4, right: 4,
              child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), shape: BoxShape.circle, border: Border.all(color: Colors.white38)),
                      child: const Icon(Icons.close, size: 14, color: Colors.white)
                  )
              )
          ),

          if (esPerfil)
            Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                        color: const Color(0xFFBEB3FF).withOpacity(0.95),
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16))
                    ),
                    child: const Text('PERFIL', textAlign: TextAlign.center, style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1))
                )
            ),
        ],
      ),
    );
  }
}