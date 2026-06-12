import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../models/profile_model.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final currentProfileProvider = FutureProvider<ProfileModel?>((ref) async {
  final authState = await ref.watch(authStateProvider.future);
  if (authState.session == null) return null;
  return ref.watch(authServiceProvider).getCurrentProfile();
});

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  final AuthService _auth;
  AuthNotifier(this._auth) : super(const AsyncData(null));

  Future<void> register({required String email, required String password,
      required String name, required String role}) async {
    state = const AsyncLoading();
    try {
      await _auth.register(email: email, password: password, name: name, role: role);
      state = const AsyncData(null);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncLoading();
    try {
      await _auth.login(email: email, password: password);
      state = const AsyncData(null);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    try {
      await _auth.logout();
      state = const AsyncData(null);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) =>
    AuthNotifier(ref.watch(authServiceProvider)));
