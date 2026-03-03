import 'package:event_lister/models/club_model.dart';
import 'package:event_lister/services/supabase_service.dart';
import 'package:uuid/uuid.dart';

class ClubService {
  static final ClubService _instance = ClubService._internal();

  late SupabaseService _supabaseService;

  factory ClubService() => _instance;

  ClubService._internal() {
    _supabaseService = SupabaseService.instance;
  }

  static ClubService get instance => _instance;

  /// Get all active clubs ordered by created_at descending.
  Future<List<Club>> getClubs() async {
    try {
      final response = await _supabaseService.client!
          .from('clubs')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);
      return (response as List).map((c) => Club.fromJson(c)).toList();
    } catch (e) {
      print('⚠️ ClubService.getClubs error: $e');
      return [];
    }
  }

  /// Get club by its ID.
  Future<Club?> getClubById(String id) async {
    try {
      final response = await _supabaseService.client!
          .from('clubs')
          .select()
          .eq('id', id)
          .maybeSingle();
      return response != null ? Club.fromJson(response) : null;
    } catch (e) {
      print('⚠️ ClubService.getClubById error: $e');
      return null;
    }
  }

  /// Create a new club and persist it to Supabase.
  Future<Club> createClub({
    required String name,
    required String description,
    required String createdBy,
    String? imageUrl,
    String? formLink,
  }) async {
    final id = const Uuid().v4();
    final now = DateTime.now();
    final response = await _supabaseService.client!
        .from('clubs')
        .insert({
          'id': id,
          'name': name,
          'description': description,
          'image_url': imageUrl,
          'form_link': formLink,
          'created_by': createdBy,
          'member_count': 0,
          'created_at': now.toIso8601String(),
          'is_active': true,
        })
        .select()
        .single();
    print('✅ Club created in Supabase: $id');
    return Club.fromJson(response);
  }

  /// Update an existing club.
  Future<Club> updateClub(String id, {
    String? name,
    String? description,
    String? imageUrl,
    String? formLink,
  }) async {
    final updateData = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (name != null) updateData['name'] = name;
    if (description != null) updateData['description'] = description;
    if (imageUrl != null) updateData['image_url'] = imageUrl;
    if (formLink != null) updateData['form_link'] = formLink;
    final response = await _supabaseService.client!
        .from('clubs')
        .update(updateData)
        .eq('id', id)
        .select()
        .single();
    print('✅ Club updated in Supabase: $id');
    return Club.fromJson(response);
  }

  /// Soft-delete a club (set is_active = false).
  Future<void> deleteClub(String id) async {
    await _supabaseService.client!
        .from('clubs')
        .update({'is_active': false, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', id);
    print('✅ Club deleted (soft) in Supabase: $id');
  }

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

  /// Awards +20 points for joining a club.
  Future<void> joinClub(String clubId, String userId) async {
    try {
      // Insert into club_members
      await _supabaseService.client!
          .from('club_members')
          .upsert({'club_id': clubId, 'user_id': userId, 'joined_at': DateTime.now().toIso8601String()});
      // Update member_count
      final club = await getClubById(clubId);
      if (club != null) {
        await _supabaseService.client!
            .from('clubs')
            .update({'member_count': club.memberCount + 1})
            .eq('id', clubId);
      }
      // Award +20 points for joining a club
      await _addPoints(userId, 20);
      print('✅ User $userId joined club $clubId');
    } catch (e) {
      print('⚠️ ClubService.joinClub error: $e');
      rethrow;
    }
  }

  /// Decrement member_count by 1 in Supabase and remove from club_members.
  Future<void> leaveClub(String clubId, String userId) async {
    try {
      // Remove from club_members
      await _supabaseService.client!
          .from('club_members')
          .delete()
          .eq('club_id', clubId)
          .eq('user_id', userId);
      // Update member_count
      final club = await getClubById(clubId);
      if (club != null) {
        final newCount = (club.memberCount - 1).clamp(0, club.memberCount);
        await _supabaseService.client!
            .from('clubs')
            .update({'member_count': newCount})
            .eq('id', clubId);
      }
      print('✅ User $userId left club $clubId');
    } catch (e) {
      print('⚠️ ClubService.leaveClub error: $e');
      rethrow;
    }
  }

  /// Check if a user is a member of a club via the club_members table.
  Future<bool> isMemberAsync(String clubId, String userId) async {
    try {
      final response = await _supabaseService.client!
          .from('club_members')
          .select()
          .eq('club_id', clubId)
          .eq('user_id', userId);
      return (response as List).isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Backward-compat sync stub (always returns false; use isMemberAsync).
  bool isMember(String clubId, String userId) => false;

  /// Get clubs the user has joined via club_members table.
  Future<List<Club>> getUserClubs(String userId) async {
    try {
      final response = await _supabaseService.client!
          .from('club_members')
          .select('club_id')
          .eq('user_id', userId);
      final clubIds = (response as List).map((r) => r['club_id'] as String).toList();
      if (clubIds.isEmpty) return [];
      final clubs = await _supabaseService.client!
          .from('clubs')
          .select()
          .inFilter('id', clubIds)
          .eq('is_active', true);
      return (clubs as List).map((c) => Club.fromJson(c)).toList();
    } catch (e) {
      print('⚠️ ClubService.getUserClubs error: $e');
      return [];
    }
  }

  /// Search clubs by name (case-insensitive).
  Future<List<Club>> searchClubs(String query) async {
    try {
      final response = await _supabaseService.client!
          .from('clubs')
          .select()
          .ilike('name', '%$query%')
          .eq('is_active', true)
          .order('created_at', ascending: false);
      return (response as List).map((c) => Club.fromJson(c)).toList();
    } catch (e) {
      print('⚠️ ClubService.searchClubs error: $e');
      return [];
    }
  }
}
