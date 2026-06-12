import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../models/profile_model.dart';

class AuthService {
  Future<AuthResponse> register({required String email, required String password,
      required String name, required String role}) async {
    final response = await supabase.auth.signUp(
      email: email, password: password, data: {'name': name, 'role': role},
    );
    if (response.user != null) {
      await supabase.from('profiles').upsert({
        'id': response.user!.id, 'name': name, 'email': email, 'role': role,
      });
    }
    return response;
  }

  Future<AuthResponse> login({required String email, required String password}) async =>
      await supabase.auth.signInWithPassword(email: email, password: password);

  Future<void> logout() async => await supabase.auth.signOut();

  Future<ProfileModel?> getCurrentProfile() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return null;
    final data = await supabase.from('profiles').select().eq('id', userId).single();
    return ProfileModel.fromJson(data);
  }

  Future<void> updateProfile({required String name, String? avatarUrl}) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User tidak ditemukan');
    await supabase.from('profiles').update({
      'name': name, if (avatarUrl != null) 'avatar_url': avatarUrl,
    }).eq('id', userId);
  }

  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;
  Session? get currentSession => supabase.auth.currentSession;
  User? get currentUser => supabase.auth.currentUser;
}
