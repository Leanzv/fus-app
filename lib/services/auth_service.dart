import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../models/profile_model.dart';

class AuthService {
  // Register user baru
  Future<AuthResponse> register({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    final response = await supabase.auth.signUp(
      email: email,
      password: password,
      data: {'name': name, 'role': role},
    );

    if (response.user != null) {
      // Buat profil di tabel profiles
      await supabase.from('profiles').upsert({
        'id': response.user!.id,
        'name': name,
        'email': email,
        'role': role,
      });
    }

    return response;
  }

  // Login
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    return await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Logout
  Future<void> logout() async {
    await supabase.auth.signOut();
  }

  // Dapatkan profil user saat ini
  Future<ProfileModel?> getCurrentProfile() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final data = await supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();

    return ProfileModel.fromJson(data);
  }

  // Update profil
  Future<void> updateProfile({
    required String name,
    String? avatarUrl,
  }) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User tidak ditemukan');

    await supabase.from('profiles').update({
      'name': name,
      'avatar_url': ?avatarUrl,
    }).eq('id', userId);
  }

  // Stream auth state
  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;

  // Cek session saat ini
  Session? get currentSession => supabase.auth.currentSession;

  User? get currentUser => supabase.auth.currentUser;
}
