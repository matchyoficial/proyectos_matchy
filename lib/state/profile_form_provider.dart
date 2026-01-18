// 📂 lib/state/profile_form_provider.dart
// ✅ Estado + lógica + persistencia local para DatosScreen (cross-platform)
// ✅ EXTRA: dirty-check (GUARDAR se activa solo si hay cambios)
// ✅ EXTRA: flag onboarding_completed para Splash (producción)
// ✅ PASO FOTOS REAL: soporta paths reales + reorder + delete (foto[0] = perfil)
// ✅ NUEVO: publishProfile() -> guarda un perfil "OFICIAL" separado del draft
//
// ✅ FIREBASE: sync a Firestore users/{uid}
// ✅ FIREBASE: hydrate (baja Firestore → llena provider local)
// ✅ FIREBASE: mantiene local como fallback (no rompe UX)
//
// ✅ STORAGE FLOW:
//    - Provider soporta photoUrls + profilePhotoUrl (para cross-device)
//    - Hydrate lee photoUrls desde Firestore
//
// ✅ FIX CRÍTICO (2026):
//    - Si Firestore trae "gs://..." lo convertimos a "https://downloadURL"
//      para que Image.network pueda renderizar SIN fallar.
//
// ✅ FIX CRÍTICO 2 (HOY):
//    - Nunca guardamos paths reales en Firestore (solo assets + urls)
//    - Siempre sincronizamos photoUrls/profilePhotoUrl con fotosCargadas
//    - Si Firestore tiene photoUrls, también los copiamos a fotosCargadas
//      para que el UI NO dependa de paths locales muertos.
//
// ✅ NUEVO (VITAL MATCH REAL):
//    - genero obligatorio: 'hombre' | 'mujer' | 'otro' | 'no_decir'
//    - preferenciaCitas: 'Hombres' | 'Mujeres' | 'Ambos'

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 🔴 CHINCHE FIREBASE PROVIDER 1 — imports Firebase
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 🔴 CHINCHE STORAGE FIX 1 — Firebase Storage (para convertir gs:// → https)
import 'package:firebase_storage/firebase_storage.dart';

// 🔴 CHINCHE PREFS 1 — llave única en almacenamiento local (draft perfil)
const String _kProfileDraftKey = 'matchy_profile_draft_v1';

// 🔴 CHINCHE PREFS 1B — llave perfil publicado (OFICIAL)
const String _kProfilePublishedKey = 'matchy_profile_published_v1';

// 🔴 CHINCHE PREFS 2 — flag onboarding completado (control Splash)
const String _kOnboardingCompletedKey = 'matchy_onboarding_completed_v1';

// 🔴 CHINCHE FOTOS 1 — máximo de fotos
const int kMaxFotos = 5;

// 🔴 CHINCHE FIREBASE PROVIDER 2 — colección users
const String kUsersCollection = 'users';

// 🔴 CHINCHE GENERO 1 — valores canónicos (NO cambiar sin migración)
const String kGeneroHombre = 'hombre';
const String kGeneroMujer = 'mujer';
const String kGeneroOtro = 'otro';
const String kGeneroNoDecir = 'no_decir';

@immutable
class ProfileFormState {
  // Textos
  final String nombre;
  final String edad;
  final String profesion;
  final String biografia;
  final String detalle;
  final String estatura;

  // País / ciudad
  final String? paisSeleccionado;
  final String? ciudadSeleccionada;

  // ✅ NUEVO: Género obligatorio (canónico)
  final String genero; // '' si no seleccionado

  // ✅ NUEVO: Preferencia global de citas
  final String preferenciaCitas; // 'Hombres' | 'Mujeres' | 'Ambos'

  // Chips
  final List<String> sobreMiSeleccion;
  final List<String> buscoSeleccion;
  final List<String> interesesSeleccion;

  // Fotos locales (draft/UI) — puede contener assets, urls o paths reales (temporal)
  final List<String> fotosCargadas;

  // ✅ Cross-device
  final List<String> photoUrls;
  final String? profilePhotoUrl;

  // Estado interno
  final bool isLoading;
  final String? error;

  // ✅ Dirty-check
  final String lastSavedJson;
  final bool hasSavedOnce;

  const ProfileFormState({
    this.nombre = '',
    this.edad = '',
    this.profesion = '',
    this.biografia = '',
    this.detalle = '',
    this.estatura = '',
    this.paisSeleccionado,
    this.ciudadSeleccionada,
    this.genero = '',
    this.preferenciaCitas = 'Ambos',
    this.sobreMiSeleccion = const [],
    this.buscoSeleccion = const [],
    this.interesesSeleccion = const [],
    this.fotosCargadas = const [],
    this.photoUrls = const [],
    this.profilePhotoUrl,
    this.isLoading = false,
    this.error,
    this.lastSavedJson = '',
    this.hasSavedOnce = false,
  });

  ProfileFormState copyWith({
    String? nombre,
    String? edad,
    String? profesion,
    String? biografia,
    String? detalle,
    String? estatura,
    String? paisSeleccionado,
    String? ciudadSeleccionada,
    String? genero,
    String? preferenciaCitas,
    List<String>? sobreMiSeleccion,
    List<String>? buscoSeleccion,
    List<String>? interesesSeleccion,
    List<String>? fotosCargadas,
    List<String>? photoUrls,
    String? profilePhotoUrl,
    bool? isLoading,
    String? error,
    String? lastSavedJson,
    bool? hasSavedOnce,
  }) {
    return ProfileFormState(
      nombre: nombre ?? this.nombre,
      edad: edad ?? this.edad,
      profesion: profesion ?? this.profesion,
      biografia: biografia ?? this.biografia,
      detalle: detalle ?? this.detalle,
      estatura: estatura ?? this.estatura,
      paisSeleccionado: paisSeleccionado ?? this.paisSeleccionado,
      ciudadSeleccionada: ciudadSeleccionada ?? this.ciudadSeleccionada,
      genero: genero ?? this.genero,
      preferenciaCitas: preferenciaCitas ?? this.preferenciaCitas,
      sobreMiSeleccion: sobreMiSeleccion ?? this.sobreMiSeleccion,
      buscoSeleccion: buscoSeleccion ?? this.buscoSeleccion,
      interesesSeleccion: interesesSeleccion ?? this.interesesSeleccion,
      fotosCargadas: fotosCargadas ?? this.fotosCargadas,
      photoUrls: photoUrls ?? this.photoUrls,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastSavedJson: lastSavedJson ?? this.lastSavedJson,
      hasSavedOnce: hasSavedOnce ?? this.hasSavedOnce,
    );
  }

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'edad': edad,
    'profesion': profesion,
    'biografia': biografia,
    'detalle': detalle,
    'estatura': estatura,
    'paisSeleccionado': paisSeleccionado,
    'ciudadSeleccionada': ciudadSeleccionada,
    'genero': genero,
    'preferenciaCitas': preferenciaCitas,
    'sobreMiSeleccion': sobreMiSeleccion,
    'buscoSeleccion': buscoSeleccion,
    'interesesSeleccion': interesesSeleccion,
    'fotosCargadas': fotosCargadas,
    'photoUrls': photoUrls,
    'profilePhotoUrl': profilePhotoUrl,
  };

  factory ProfileFormState.fromJson(Map<String, dynamic> json) {
    List<String> listStr(dynamic v) =>
        (v is List) ? v.map((e) => e.toString()).toList() : <String>[];

    List<String> safeList(dynamic v) {
      try {
        return listStr(v);
      } catch (_) {
        return <String>[];
      }
    }

    final fotos = safeList(json['fotosCargadas']);
    final urls = safeList(json['photoUrls']);
    final profileUrlRaw = (json['profilePhotoUrl'] ?? '').toString().trim();
    final profileUrl = profileUrlRaw.isEmpty ? null : profileUrlRaw;

    final generoRaw = (json['genero'] ?? '').toString().trim();
    final prefRaw = (json['preferenciaCitas'] ?? 'Ambos').toString().trim();

    return ProfileFormState(
      nombre: (json['nombre'] ?? '').toString(),
      edad: (json['edad'] ?? '').toString(),
      profesion: (json['profesion'] ?? '').toString(),
      biografia: (json['biografia'] ?? '').toString(),
      detalle: (json['detalle'] ?? '').toString(),
      estatura: (json['estatura'] ?? '').toString(),
      paisSeleccionado: json['paisSeleccionado'] as String?,
      ciudadSeleccionada: json['ciudadSeleccionada'] as String?,
      genero: generoRaw,
      preferenciaCitas: prefRaw.isEmpty ? 'Ambos' : prefRaw,
      sobreMiSeleccion: safeList(json['sobreMiSeleccion']),
      buscoSeleccion: safeList(json['buscoSeleccion']),
      interesesSeleccion: safeList(json['interesesSeleccion']),
      fotosCargadas: fotos,
      photoUrls: urls,
      profilePhotoUrl: profileUrl,
    );
  }
}

class ProfileFormController extends StateNotifier<ProfileFormState> {
  ProfileFormController() : super(const ProfileFormState());

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  // 🔴 CHINCHE STORAGE FIX 2
  FirebaseStorage get _storage => FirebaseStorage.instance;

  User? get _user => _auth.currentUser;

  DocumentReference<Map<String, dynamic>>? get _userDoc {
    final u = _user;
    if (u == null) return null;
    return _db.collection(kUsersCollection).doc(u.uid);
  }

  // ===========================================================
  // Helpers URL / types
  // ===========================================================

  bool _isGsUrl(String v) => v.trim().startsWith('gs://');
  bool _isHttpUrl(String v) =>
      v.trim().startsWith('http://') || v.trim().startsWith('https://');
  bool _isAssetPath(String v) => v.trim().startsWith('assets/');

  // ===========================================================
  // 🔥 FIX: convertir gs:// → https://downloadURL
  // ===========================================================

  Future<String?> _normalizeOneUrl(String? input) async {
    final raw = (input ?? '').trim();
    if (raw.isEmpty) return null;

    if (_isHttpUrl(raw)) return raw;

    if (_isGsUrl(raw)) {
      try {
        final ref = _storage.refFromURL(raw);
        final downloadUrl = await ref.getDownloadURL();
        return downloadUrl.trim().isEmpty ? null : downloadUrl.trim();
      } catch (_) {
        return null;
      }
    }

    return raw;
  }

  Future<List<String>> _normalizeListUrls(List<String> inputs) async {
    final out = <String>[];

    for (final item in inputs) {
      final norm = await _normalizeOneUrl(item);
      if (norm == null) continue;

      if (_isHttpUrl(norm)) out.add(norm);
    }

    return out;
  }

  // ===========================================================
  // 🔴 CHINCHE FIX URLSYNC 1 — sincroniza photoUrls/profilePhotoUrl con fotosCargadas
  // ===========================================================

  void _syncRemoteFieldsFromFotos(List<String> fotos) {
    final urls = fotos
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && _isHttpUrl(e))
        .toList();

    final profile = urls.isNotEmpty ? urls.first : null;

    state = state.copyWith(
      fotosCargadas: fotos,
      photoUrls: urls,
      profilePhotoUrl: profile,
      error: null,
    );
  }

  // ===========================================================
  // Setters (textos)
  // ===========================================================

  void setNombre(String v) => state = state.copyWith(nombre: v, error: null);
  void setEdad(String v) => state = state.copyWith(edad: v, error: null);
  void setProfesion(String v) => state = state.copyWith(profesion: v, error: null);
  void setBiografia(String v) => state = state.copyWith(biografia: v, error: null);
  void setDetalle(String v) => state = state.copyWith(detalle: v, error: null);
  void setEstatura(String v) => state = state.copyWith(estatura: v, error: null);

  void setPais(String? pais) {
    state = state.copyWith(
      paisSeleccionado: pais,
      ciudadSeleccionada: null,
      error: null,
    );
  }

  void setCiudad(String? ciudad) =>
      state = state.copyWith(ciudadSeleccionada: ciudad, error: null);

  // ===========================================================
  // ✅ NUEVO: género obligatorio + preferencia citas
  // ===========================================================

  void setGenero(String v) => state = state.copyWith(genero: v.trim(), error: null);

  void setPreferenciaCitas(String v) =>
      state = state.copyWith(preferenciaCitas: v.trim().isEmpty ? 'Ambos' : v.trim(), error: null);

  List<String> _toggleInList(List<String> list, String item) {
    final copy = List<String>.from(list);
    if (copy.contains(item)) {
      copy.remove(item);
    } else {
      copy.add(item);
    }
    return copy;
  }

  void toggleSobreMi(String item) => state = state.copyWith(
    sobreMiSeleccion: _toggleInList(state.sobreMiSeleccion, item),
    error: null,
  );

  void toggleBusco(String item) => state = state.copyWith(
    buscoSeleccion: _toggleInList(state.buscoSeleccion, item),
    error: null,
  );

  void toggleInteres(String item) => state = state.copyWith(
    interesesSeleccion: _toggleInList(state.interesesSeleccion, item),
    error: null,
  );

  // ===========================================================
  // Fotos (IMPORTANTES)
  // ===========================================================

  // 🔴 CHINCHE FIX URLSYNC 2 — setFotos ahora sincroniza remote fields
  void setFotos(List<String> fotos) => _syncRemoteFieldsFromFotos(fotos);

  void addFoto(String fotoPathOrAsset) {
    final current = List<String>.from(state.fotosCargadas);
    if (current.contains(fotoPathOrAsset)) return;

    if (current.length >= kMaxFotos) {
      state = state.copyWith(error: 'Máximo $kMaxFotos fotos');
      return;
    }

    current.add(fotoPathOrAsset);
    _syncRemoteFieldsFromFotos(current);
  }

  void removeFotoAt(int index) {
    final current = List<String>.from(state.fotosCargadas);
    if (index < 0 || index >= current.length) return;
    current.removeAt(index);
    _syncRemoteFieldsFromFotos(current);
  }

  void reorderFotos(int oldIndex, int newIndex) {
    final current = List<String>.from(state.fotosCargadas);
    if (oldIndex < 0 || oldIndex >= current.length) return;
    if (newIndex < 0 || newIndex > current.length) return;

    if (newIndex > oldIndex) newIndex -= 1;

    final item = current.removeAt(oldIndex);
    current.insert(newIndex, item);

    _syncRemoteFieldsFromFotos(current);
  }

  // Foto perfil preferida (para UI legacy)
  String? get fotoPerfil =>
      state.fotosCargadas.isNotEmpty ? state.fotosCargadas.first : null;

  bool get puedeGuardar {
    final nombreOk = state.nombre.trim().isNotEmpty;
    final edadInt = int.tryParse(state.edad.trim());
    final edadOk = edadInt != null && edadInt >= 18 && edadInt <= 99;
    final paisOk = (state.paisSeleccionado ?? '').trim().isNotEmpty;
    final ciudadOk = (state.ciudadSeleccionada ?? '').trim().isNotEmpty;

    // ✅ Fotos ok con URLs o fotosCargadas
    final fotosOk = state.photoUrls.isNotEmpty || state.fotosCargadas.isNotEmpty;

    // ✅ NUEVO: género obligatorio (cualquier opción vale, incluso no_decir)
    final generoOk = state.genero.trim().isNotEmpty;

    return nombreOk && edadOk && paisOk && ciudadOk && fotosOk && generoOk;
  }

  bool get isDirty {
    final current = jsonEncode(state.toJson());
    if (state.lastSavedJson.isEmpty) return true;
    return current != state.lastSavedJson;
  }

  // ===========================================================
  // Persistencia local
  // ===========================================================

  Future<void> loadDraft() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kProfileDraftKey);

      if (raw == null || raw.isEmpty) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final map = jsonDecode(raw) as Map<String, dynamic>;
      final loaded = ProfileFormState.fromJson(map);

      // 🔴 CHINCHE FIX URLSYNC 3 — al cargar draft, recalculamos remote fields
      final fotos = List<String>.from(loaded.fotosCargadas);
      final urls = loaded.photoUrls;

      final mergedFotos = urls.isNotEmpty ? urls : fotos;

      state = loaded.copyWith(
        fotosCargadas: mergedFotos,
        photoUrls: urls.isNotEmpty ? urls : mergedFotos.where((e) => _isHttpUrl(e)).toList(),
        profilePhotoUrl: loaded.profilePhotoUrl ?? (urls.isNotEmpty ? urls.first : null),
        isLoading: false,
        lastSavedJson: raw,
        hasSavedOnce: true,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'No se pudo cargar el borrador',
      );
    }
  }

  Future<void> saveDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(state.toJson());
      await prefs.setString(_kProfileDraftKey, raw);

      state = state.copyWith(
        lastSavedJson: raw,
        hasSavedOnce: true,
        error: null,
      );
    } catch (_) {}
  }

  Future<void> clearDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kProfileDraftKey);
      state = const ProfileFormState();
    } catch (_) {}
  }

  Future<void> publishProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(state.toJson());
      await prefs.setString(_kProfilePublishedKey, raw);
    } catch (_) {}
  }

  static Future<ProfileFormState?> loadPublishedProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kProfilePublishedKey);
      if (raw == null || raw.isEmpty) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return ProfileFormState.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> setOnboardingCompleted(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kOnboardingCompletedKey, value);
    } catch (_) {}
  }

  static Future<bool> isOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_kOnboardingCompletedKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  // ===========================================================
  // ✅ NUEVO: bootstrap (usado por Splash blindado)
  // ===========================================================

  Future<void> bootstrapFromFirestore() async {
    // 🔴 CHINCHE BOOTSTRAP 1 — no rompe UX: primero local, luego Firestore
    await loadDraft();
    await hydrateFromFirestore();
  }

  // ===========================================================
  // Firestore payload
  // ===========================================================

  // 🔴 CHINCHE FIX FIRESTORE PATHS 1 — safe local paths: assets + urls, NO file paths reales
  List<String> _safeLocalForFirestore(List<String> fotos) {
    final out = <String>[];
    for (final raw in fotos) {
      final v = raw.trim();
      if (v.isEmpty) continue;
      if (_isAssetPath(v) || _isHttpUrl(v)) out.add(v);
    }
    return out;
  }

  Map<String, dynamic> _toFirestorePayload({required String uid}) {
    final edadInt = int.tryParse(state.edad.trim());

    final safeLocal = _safeLocalForFirestore(state.fotosCargadas);
    final urls = List<String>.from(state.photoUrls);

    return <String, dynamic>{
      'uid': uid,
      'nombre': state.nombre.trim(),
      'edad': edadInt,
      'profesion': state.profesion.trim(),
      'biografia': state.biografia.trim(),
      'detalle': state.detalle.trim(),
      'estatura': state.estatura.trim(),
      'pais': (state.paisSeleccionado ?? '').trim(),
      'ciudad': (state.ciudadSeleccionada ?? '').trim(),

      // ✅ NUEVO: genero + preferenciaCitas
      'genero': state.genero.trim(),
      'preferenciaCitas': state.preferenciaCitas.trim().isEmpty ? 'Ambos' : state.preferenciaCitas.trim(),

      'sobreMiSeleccion': state.sobreMiSeleccion,
      'buscoSeleccion': state.buscoSeleccion,
      'interesesSeleccion': state.interesesSeleccion,

      // ✅ SAFE: no guardamos file paths
      'photosLocalPaths': safeLocal,
      'profilePhotoLocalPath': safeLocal.isNotEmpty ? safeLocal.first : '',

      // ✅ cross-device
      'photoUrls': urls,
      'profilePhotoUrl': state.profilePhotoUrl ?? (urls.isNotEmpty ? urls.first : null),

      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Future<void> syncProfileToFirestore({bool markOnboardingCompleted = false}) async {
    final u = _user;
    final ref = _userDoc;

    if (u == null || ref == null) {
      state = state.copyWith(error: 'No hay sesión activa (Auth).');
      return;
    }

    try {
      final snap = await ref.get();
      final payload = _toFirestorePayload(uid: u.uid);

      if (markOnboardingCompleted) {
        payload['onboarding_completed'] = true;
        payload['onboardingCompletedAt'] = FieldValue.serverTimestamp();
      }

      if (!snap.exists) {
        payload['createdAt'] = FieldValue.serverTimestamp();
      }

      await ref.set(payload, SetOptions(merge: true));
    } catch (e) {
      state = state.copyWith(error: 'No se pudo guardar en Firestore: $e');
    }
  }

  // ===========================================================
  // ✅ Hydrate: Firestore → Provider + Draft local
  // ===========================================================

  Future<void> hydrateFromFirestore() async {
    final u = _user;
    final ref = _userDoc;

    if (u == null || ref == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final snap = await ref.get();
      if (!snap.exists) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final data = snap.data();
      if (data == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      String s(dynamic v) => (v ?? '').toString();
      List<String> listStr(dynamic v) =>
          (v is List) ? v.map((e) => e.toString()).toList() : <String>[];

      final edadVal = data['edad'];
      final edadString = (edadVal is int) ? edadVal.toString() : s(edadVal);

      // 🔴 CHINCHE STORAGE FIX 3 — normalizamos URLs (incluye gs://)
      final rawPhotoUrls = listStr(data['photoUrls']);
      final normalizedPhotoUrls = await _normalizeListUrls(rawPhotoUrls);

      final profileUrlRaw = s(data['profilePhotoUrl']).trim();
      final normalizedProfileUrl = await _normalizeOneUrl(profileUrlRaw);

      // 🔴 CHINCHE FIX FIRESTORE PATHS 2 — solo assets/urls vienen aquí (si quedó legacy, se filtra)
      final fotosLocalSafe = _safeLocalForFirestore(listStr(data['photosLocalPaths']));

      final nombre = s(data['nombre']);
      final pais = s(data['pais']).trim().isEmpty ? null : s(data['pais']).trim();
      final ciudad = s(data['ciudad']).trim().isEmpty ? null : s(data['ciudad']).trim();

      final genero = s(data['genero']).trim();
      final prefCitas = s(data['preferenciaCitas']).trim().isEmpty ? 'Ambos' : s(data['preferenciaCitas']).trim();

      // ✅ PRIORIDAD: si hay photoUrls, también las copiamos a fotosCargadas para que el UI viva
      final fotosParaUI = normalizedPhotoUrls.isNotEmpty ? normalizedPhotoUrls : fotosLocalSafe;

      final loaded = ProfileFormState(
        nombre: nombre,
        edad: edadString,
        profesion: s(data['profesion']),
        biografia: s(data['biografia']),
        detalle: s(data['detalle']),
        estatura: s(data['estatura']),
        paisSeleccionado: pais,
        ciudadSeleccionada: ciudad,

        genero: genero,
        preferenciaCitas: prefCitas,

        sobreMiSeleccion: listStr(data['sobreMiSeleccion']),
        buscoSeleccion: listStr(data['buscoSeleccion']),
        interesesSeleccion: listStr(data['interesesSeleccion']),
        fotosCargadas: fotosParaUI,
        photoUrls: normalizedPhotoUrls,
        profilePhotoUrl:
        normalizedProfileUrl ?? (normalizedPhotoUrls.isNotEmpty ? normalizedPhotoUrls.first : null),
      );

      // Guardamos draft local (fallback)
      final raw = jsonEncode(loaded.toJson());
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kProfileDraftKey, raw);

      state = loaded.copyWith(
        isLoading: false,
        lastSavedJson: raw,
        hasSavedOnce: true,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'No se pudo cargar desde Firestore: $e',
      );
    }
  }
}

final profileFormProvider =
StateNotifierProvider<ProfileFormController, ProfileFormState>((ref) {
  return ProfileFormController();
});
