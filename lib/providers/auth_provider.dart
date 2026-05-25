import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../models/profile_model.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// Stream auth state
final authStateProvider = StreamProvider<AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

// Provider profil user saat ini
final currentProfileProvider = FutureProvider<ProfileModel?>((ref) async {
  final authState = await ref.watch(authStateProvider.future);
  if (authState.session == null) return null;
  final authService = ref.watch(authServiceProvider);
  return authService.getCurrentProfile();
});

// Notifier untuk auth actions
class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  final AuthService _authService;
  final Ref _ref;

  AuthNotifier(this._authService, this._ref) : super(const AsyncData(null));

  Future<void> register({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    state = const AsyncLoading();
    try {
      await _authService.register(
        email: email,
        password: password,
        name: name,
        role: role,
      );
      state = const AsyncData(null);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      await _authService.login(email: email, password: password);
      state = const AsyncData(null);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    try {
      await _authService.logout();
      state = const AsyncData(null);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService, ref);
});
