// 📂 lib/state/profile_form_provider.dart
// ✅ Estado + lógica + persistencia local para DatosScreen (cross-platform)
// ✅ EXTRA: dirty-check (GUARDAR se activa solo si hay cambios)
// ✅ EXTRA: flag onboarding_completed para Splash (producción)
// ✅ PASO FOTOS REAL: soporta paths reales + reorder + delete (foto[0] = perfil)
// ✅ NUEVO: publishProfile() -> guarda un perfil "OFICIAL" separado del draft

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 🔴 CHINCHE PREFS 1 — llave única en almacenamiento local (draft perfil)
const String _kProfileDraftKey = 'matchy_profile_draft_v1';

// 🔴 CHINCHE PREFS 1B — llave perfil publicado (OFICIAL)
const String _kProfilePublishedKey = 'matchy_profile_published_v1';

// 🔴 CHINCHE PREFS 2 — flag onboarding completado (control Splash)
const String _kOnboardingCompletedKey = 'matchy_onboarding_completed_v1';

// 🔴 CHINCHE FOTOS 1 — máximo de fotos
const int kMaxFotos = 5;

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

  // Chips
  final List<String> sobreMiSeleccion;
  final List<String> buscoSeleccion;
  final List<String> interesesSeleccion;

  // Fotos:
  // - Assets: "assets/images/perfil1.jpg"
  // - Reales: "/storage/emulated/0/.../IMG_123.jpg"
  // ✅ Foto de perfil = fotosCargadas[0]
  final List<String> fotosCargadas;

  // Estado interno
  final bool isLoading;
  final String? error;

  // ✅ Dirty-check (para activar/desactivar GUARDAR de forma inteligente)
  final String lastSavedJson; // snapshot del último guardado
  final bool hasSavedOnce; // útil para UX futura

  const ProfileFormState({
    this.nombre = '',
    this.edad = '',
    this.profesion = '',
    this.biografia = '',
    this.detalle = '',
    this.estatura = '',
    this.paisSeleccionado,
    this.ciudadSeleccionada,
    this.sobreMiSeleccion = const [],
    this.buscoSeleccion = const [],
    this.interesesSeleccion = const [],
    this.fotosCargadas = const [],
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
    List<String>? sobreMiSeleccion,
    List<String>? buscoSeleccion,
    List<String>? interesesSeleccion,
    List<String>? fotosCargadas,
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
      sobreMiSeleccion: sobreMiSeleccion ?? this.sobreMiSeleccion,
      buscoSeleccion: buscoSeleccion ?? this.buscoSeleccion,
      interesesSeleccion: interesesSeleccion ?? this.interesesSeleccion,
      fotosCargadas: fotosCargadas ?? this.fotosCargadas,
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
    'sobreMiSeleccion': sobreMiSeleccion,
    'buscoSeleccion': buscoSeleccion,
    'interesesSeleccion': interesesSeleccion,
    // 🔴 CHINCHE JSON FOTO 1 — guardamos lista de paths/asset
    'fotosCargadas': fotosCargadas,
  };

  factory ProfileFormState.fromJson(Map<String, dynamic> json) {
    final rawFotos = json['fotosCargadas'];

    List<String> fotos;
    if (rawFotos is List) {
      fotos = List<String>.from(rawFotos);
    } else {
      fotos = const [];
    }

    return ProfileFormState(
      nombre: (json['nombre'] ?? '') as String,
      edad: (json['edad'] ?? '') as String,
      profesion: (json['profesion'] ?? '') as String,
      biografia: (json['biografia'] ?? '') as String,
      detalle: (json['detalle'] ?? '') as String,
      estatura: (json['estatura'] ?? '') as String,
      paisSeleccionado: json['paisSeleccionado'] as String?,
      ciudadSeleccionada: json['ciudadSeleccionada'] as String?,
      sobreMiSeleccion:
      List<String>.from((json['sobreMiSeleccion'] ?? const []) as List),
      buscoSeleccion:
      List<String>.from((json['buscoSeleccion'] ?? const []) as List),
      interesesSeleccion:
      List<String>.from((json['interesesSeleccion'] ?? const []) as List),
      fotosCargadas: fotos,
    );
  }
}

class ProfileFormController extends StateNotifier<ProfileFormState> {
  ProfileFormController() : super(const ProfileFormState());

  // -------------------- Setters básicos --------------------
  void setNombre(String v) => state = state.copyWith(nombre: v, error: null);
  void setEdad(String v) => state = state.copyWith(edad: v, error: null);
  void setProfesion(String v) => state = state.copyWith(profesion: v, error: null);
  void setBiografia(String v) => state = state.copyWith(biografia: v, error: null);
  void setDetalle(String v) => state = state.copyWith(detalle: v, error: null);
  void setEstatura(String v) => state = state.copyWith(estatura: v, error: null);

  void setPais(String? pais) {
    // 🔴 CHINCHE LOGICA PAIS 1 — al cambiar país, resetea ciudad
    state = state.copyWith(
      paisSeleccionado: pais,
      ciudadSeleccionada: null,
      error: null,
    );
  }

  void setCiudad(String? ciudad) => state = state.copyWith(ciudadSeleccionada: ciudad, error: null);

  // -------------------- Chips --------------------
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

  // -------------------- Fotos --------------------
  void setFotos(List<String> fotos) => state = state.copyWith(fotosCargadas: fotos, error: null);

  void addFoto(String fotoPathOrAsset) {
    final current = List<String>.from(state.fotosCargadas);

    // 🔴 CHINCHE FOTO ADD 1 — evita duplicados exactos
    if (current.contains(fotoPathOrAsset)) return;

    if (current.length >= kMaxFotos) {
      state = state.copyWith(error: 'Máximo $kMaxFotos fotos');
      return;
    }

    current.add(fotoPathOrAsset);
    state = state.copyWith(fotosCargadas: current, error: null);
  }

  void removeFotoAt(int index) {
    final current = List<String>.from(state.fotosCargadas);
    if (index < 0 || index >= current.length) return;

    current.removeAt(index);
    state = state.copyWith(fotosCargadas: current, error: null);
  }

  void reorderFotos(int oldIndex, int newIndex) {
    final current = List<String>.from(state.fotosCargadas);
    if (oldIndex < 0 || oldIndex >= current.length) return;
    if (newIndex < 0 || newIndex > current.length) return;

    if (newIndex > oldIndex) newIndex -= 1;

    final item = current.removeAt(oldIndex);
    current.insert(newIndex, item);

    state = state.copyWith(fotosCargadas: current, error: null);
  }

  String? get fotoPerfil => state.fotosCargadas.isNotEmpty ? state.fotosCargadas.first : null;

  // -------------------- Validación mínima segura --------------------
  bool get puedeGuardar {
    final nombreOk = state.nombre.trim().isNotEmpty;
    final edadInt = int.tryParse(state.edad.trim());
    final edadOk = edadInt != null && edadInt >= 18 && edadInt <= 99;
    final paisOk = (state.paisSeleccionado ?? '').trim().isNotEmpty;
    final ciudadOk = (state.ciudadSeleccionada ?? '').trim().isNotEmpty;
    final fotosOk = state.fotosCargadas.isNotEmpty;

    return nombreOk && edadOk && paisOk && ciudadOk && fotosOk;
  }

  bool get isDirty {
    final current = jsonEncode(state.toJson());
    if (state.lastSavedJson.isEmpty) return true;
    return current != state.lastSavedJson;
  }

  // -------------------- Persistencia local (DRAFT) --------------------
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

      state = loaded.copyWith(
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

  // -------------------- Perfil publicado (OFICIAL) --------------------
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

  // -------------------- Onboarding flag (Splash) --------------------
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
}

final profileFormProvider =
StateNotifierProvider<ProfileFormController, ProfileFormState>((ref) {
  return ProfileFormController();
});
