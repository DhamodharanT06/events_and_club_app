import 'package:event_lister/models/registration_model.dart';
import 'package:event_lister/services/supabase_service.dart';
import 'package:uuid/uuid.dart';

/// RegistrationService — all data is fetched directly from the Supabase `registrations` table.
class RegistrationService {
  static final RegistrationService _instance = RegistrationService._internal();

  late SupabaseService _supabaseService;

  factory RegistrationService() => _instance;

  RegistrationService._internal() {
    _supabaseService = SupabaseService.instance;
  }

  static RegistrationService get instance => _instance;

  /// Award points to a user by incrementing their points in the users table.
  Future<void> _addPoints(String userId, int points) async {
    try {
      final userData = await _supabaseService.client!
          .from('users')
          .select('points')
          .eq('id', userId)
          .single();
      final currentPoints = (userData['points'] as int?) ?? 0;
      await _supabaseService.client!
          .from('users')
          .update({'points': currentPoints + points})
          .eq('id', userId);
      print('✅ Added $points points to user $userId (total: ${currentPoints + points})');
    } catch (e) {
      print('⚠️ Could not award points: $e');
    }
  }

  /// Awards +10 points to the user.
  Future<Registration> registerForEvent({
    required String userId,
    required String eventId,
    String? clubId,
  }) async {
    final existing = await _supabaseService.client!
        .from('registrations')
        .select()
        .eq('user_id', userId)
        .eq('event_id', eventId)
        .eq('status', 'registered');

    if ((existing as List).isNotEmpty) {
      throw Exception('Already registered for this event');
    }

    final id = const Uuid().v4();
    final now = DateTime.now();
    final response = await _supabaseService.client!
        .from('registrations')
        .insert({
          'id': id,
          'user_id': userId,
          'event_id': eventId,
          'registration_date': now.toIso8601String(),
          'status': 'registered',
          'google_form_submitted': false,
          'is_active': true,
        })
        .select()
        .single();
    print('✅ Registered for event: user=$userId, event=$eventId');

    // Award +10 points for event registration
    await _addPoints(userId, 10);

    return Registration.fromJson(response);
  }

  /// Cancel a registration.
  Future<void> unregisterFromEvent(String userId, String eventId) async {
    await _supabaseService.client!
        .from('registrations')
        .update({'status': 'cancelled', 'is_active': false})
        .eq('user_id', userId)
        .eq('event_id', eventId)
        .eq('status', 'registered');
    print('✅ Unregistered: user=$userId, event=$eventId');
  }

  /// Get all active registrations for a user.
  Future<List<Registration>> getUserEventRegistrations(String userId) async {
    try {
      final response = await _supabaseService.client!
          .from('registrations')
          .select()
          .eq('user_id', userId)
          .eq('status', 'registered');
      return (response as List).map((r) => Registration.fromJson(r)).toList();
    } catch (e) {
      print('⚠️ RegistrationService.getUserEventRegistrations error: $e');
      return [];
    }
  }

  /// Club memberships are in club_members table — not in registrations.
  Future<List<Registration>> getClubMemberships(String clubId) async => [];

  /// Check if a user is registered for an event.
  Future<bool> isUserRegistered(String userId, String eventId) async {
    try {
      final response = await _supabaseService.client!
          .from('registrations')
          .select()
          .eq('user_id', userId)
          .eq('event_id', eventId)
          .eq('status', 'registered');
      return (response as List).isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get the count of active registrations for an event.
  Future<int> getEventRegistrationsCount(String eventId) async {
    try {
      final response = await _supabaseService.client!
          .from('registrations')
          .select()
          .eq('event_id', eventId)
          .eq('status', 'registered');
      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  /// Get a registration by its ID.
  Future<Registration?> getRegistrationById(String id) async {
    try {
      final response = await _supabaseService.client!
          .from('registrations')
          .select()
          .eq('id', id)
          .maybeSingle();
      return response != null ? Registration.fromJson(response) : null;
    } catch (e) {
      return null;
    }
  }
}
