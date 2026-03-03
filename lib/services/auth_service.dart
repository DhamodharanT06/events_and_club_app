import 'package:event_lister/constants/app_constants.dart';
import 'package:event_lister/models/user_model.dart';
import 'package:event_lister/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  late final SupabaseService _supabaseService;
  final String _usersTableName = 'users';

  static User? _currentUser;

  factory AuthService() => _instance;

  AuthService._internal() {
    _supabaseService = SupabaseService.instance;
  }

  static AuthService get instance => _instance;

  // ─── Session helpers ───────────────────────────────────────────────────────

  User? getCurrentUser() => _currentUser;

  void setCurrentUser(User user) => _currentUser = user;

  void logout() {
    _currentUser = null;
    try {
      _supabaseService.client?.auth.signOut();
    } catch (_) {}
  }

  bool isLoggedIn() => _currentUser != null;

  bool isAdmin() => _currentUser?.role == UserRole.admin;

  // ─── Database helpers ──────────────────────────────────────────────────────

  User _buildUserFromRow(Map<String, dynamic> row) {
    final roleString = (row['role'] as String? ?? 'user').toLowerCase();
    final role = roleString == 'admin' ? UserRole.admin : UserRole.user;
    return User(
      id: row['id'] as String,
      name: row['name'] as String? ?? 'User',
      email: row['email'] as String? ?? '',
      phone: row['phone'] as String? ?? '',
      role: role,
      profileImage: row['profile_image'] as String?,
      bio: row['bio'] as String?,
      points: (row['points'] as int?) ?? 0,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: row['updated_at'] != null
          ? DateTime.parse(row['updated_at'] as String)
          : null,
    );
  }

  Future<User?> getCurrentUserFromDatabase() async {
    try {
      final client = _supabaseService.client;
      if (client == null) return null;
      final authUser = _supabaseService.currentUser;
      if (authUser == null) return null;
      final response = await client
          .from(_usersTableName)
          .select()
          .eq('id', authUser.id)
          .single();
      return _buildUserFromRow(response);
    } catch (e) {
      print('e getCurrentUserFromDatabase: $e');
      return null;
    }
  }

  Future<User?> getUserByEmail(String email) async {
    try {
      final client = _supabaseService.client;
      if (client == null) return null;
      final response = await client
          .from(_usersTableName)
          .select()
          .eq('email', email.toLowerCase())
          .single();
      return _buildUserFromRow(response);
    } catch (e) {
      print('e getUserByEmail: $e');
      return null;
    }
  }

  // ─── Auth operations ───────────────────────────────────────────────────────

  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final client = _supabaseService.client;
      if (client == null) return null;
      final normalizedEmail = email.trim().toLowerCase();
      late Map<String, dynamic> userRecord;
      try {
        userRecord = await client
            .from(_usersTableName)
            .select()
            .eq('email', normalizedEmail)
            .single();
      } catch (_) {
        return null;
      }
      try {
        final response = await client.auth
            .signInWithPassword(email: normalizedEmail, password: password);
        if (response.user != null) return _buildUserFromRow(userRecord);
      } on AuthApiException catch (authError) {
        print('authError signIn: ${authError.message}');
        final storedHash = userRecord['password_hash'] as String?;
        if (storedHash != null && storedHash.isNotEmpty) {
          final providedHash = sha256.convert(utf8.encode(password)).toString();
          if (storedHash == providedHash) return _buildUserFromRow(userRecord);
        }
        return null;
      }
      return null;
    } catch (e) {
      print('e signIn: $e');
      return null;
    }
  }

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
  }) async {
    try {
      final client = _supabaseService.client;
      if (client == null) return false;
      print('Creating auth user in Supabase...');
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: {'name': name, 'role': role, 'phone': phone},
      );
      if (response.user == null) return false;
      final passwordHash = sha256.convert(utf8.encode(password)).toString();
      await client.from(_usersTableName).insert({
        'id': response.user!.id,
        'name': name,
        'email': email.toLowerCase(),
        'phone': phone ?? '',
        'role': role,
        'password_hash': passwordHash,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      return true;
    } on AuthApiException catch (e) {
      if (e.message.contains('already registered') || e.message.contains('already been registered')) {
        throw Exception('This email is already registered. Please log in instead.');
      } else if (e.message.contains('password') || e.message.contains('weak')) {
        throw Exception('Password is too weak. Use at least 6 characters.');
      } else if (e.message.contains('invalid') || e.message.contains('Invalid')) {
        throw Exception('Invalid email address. Please enter a valid email.');
      }
      throw Exception(e.message);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Signup failed: ${e.toString()}');
    }
  }

  Future<bool> updateUserProfile({
    required String userId,
    String? name,
    String? bio,
    String? phone,
    String? profileImage,
    int? points,
  }) async {
    try {
      final client = _supabaseService.client;
      if (client == null) return false;
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (bio != null) updateData['bio'] = bio;
      if (phone != null) updateData['phone'] = phone;
      if (profileImage != null) updateData['profile_image'] = profileImage;
      if (points != null) updateData['points'] = points;
      updateData['updated_at'] = DateTime.now().toIso8601String();
      await client.from(_usersTableName).update(updateData).eq('id', userId);
      return true;
    } catch (e) {
      print('e updateUserProfile: $e');
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      final client = _supabaseService.client;
      if (client == null) return false;
      final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return false;
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      if (googleAuth.idToken == null) return false;
      final response = await client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
      );
      if (response.user == null) return false;
      try {
        await client.from(_usersTableName).select().eq('id', response.user!.id).single();
      } catch (_) {
        await client.from(_usersTableName).insert({
          'id': response.user!.id,
          'name': googleUser.displayName ?? 'User',
          'email': googleUser.email,
          'phone': '',
          'role': 'user',
          'is_active': true,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
      return true;
    } on PlatformException catch (e) {
      print('Google Sign-In error: ${e.code} ${e.message}');
      return false;
    } catch (e) {
      print('e signInWithGoogle: $e');
      return false;
    }
  }
}
