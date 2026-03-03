import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase Service for backend integration
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  
  late SupabaseClient _client;
  late bool _isInitialized;
  late String? _initError;

  factory SupabaseService() {
    return _instance;
  }

  SupabaseService._internal() {
    _isInitialized = false;
    _initError = null;
  }

  static SupabaseService get instance => _instance;

  /// Initialize Supabase with your credentials
  Future<void> initialize({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) async {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
      _client = Supabase.instance.client;
      _isInitialized = true;
      _initError = null;
      print('✅ Supabase initialized successfully');
    } catch (e) {
      _isInitialized = false;
      _initError = e.toString();
      print('⚠️ Supabase initialization error: $e');
      print('📌 Will use fallback hardcoded data');
    }
  }

  /// Get Supabase client instance (may be null if not initialized)
  SupabaseClient? get client => _isInitialized ? _client : null;

  bool get isInitialized => _isInitialized;

  String? get initError => _initError;

  User? get currentUser => _isInitialized ? _client.auth.currentUser : null;

  Future<void> signOut() async {
    if (_isInitialized) {
      await _client.auth.signOut();
    }
  }

  /// Check connection to Supabase
  Future<bool> checkConnection() async {
    try {
      if (!_isInitialized) return false;
      
      await _client.from('events').select().limit(1);
      return true;
    } catch (e) {
      print('❌ Supabase connection check failed: $e');
      return false;
    }
  }
}
