// 📂 lib/state/app_state.dart
// ✅ PASO 4.3A — Estado base global (Riverpod)
// Objetivo: tener un "cerebro" mínimo y sólido, listo para conectar pantallas luego.

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Modelo inmutable del estado global.
/// Regla: aquí NO hacemos UI. Solo datos puros.
class AppState {
  // 🔴 CHINCHE STATE 1 — bandera general (útil para cargas futuras)
  final bool isLoading;

  // 🔴 CHINCHE STATE 2 — contador simple para prueba de Riverpod
  final int counter;

  const AppState({
    this.isLoading = false,
    this.counter = 0,
  });

  AppState copyWith({
    bool? isLoading,
    int? counter,
  }) {
    return AppState(
      isLoading: isLoading ?? this.isLoading,
      counter: counter ?? this.counter,
    );
  }
}

/// Controlador del estado (la parte que cambia variables).
/// Regla: aquí viven las acciones tipo "incrementar", "guardar", "validar", etc.
class AppController extends StateNotifier<AppState> {
  AppController() : super(const AppState());

  // 🔴 CHINCHE CTRL 1 — Acción de prueba (incrementa contador)
  void increment() {
    state = state.copyWith(counter: state.counter + 1);
  }

  // 🔴 CHINCHE CTRL 2 — Acción de prueba (reset)
  void resetCounter() {
    state = state.copyWith(counter: 0);
  }

  // 🔴 CHINCHE CTRL 3 — Simular loading (para flujos futuros)
  void setLoading(bool value) {
    state = state.copyWith(isLoading: value);
  }
}

/// Provider global: la app entera puede leer/escribir este estado.
/// Esto es lo que luego conectaremos a Registro/Datos/Panel/Perfil.
final appControllerProvider =
StateNotifierProvider<AppController, AppState>((ref) {
  return AppController();
});
