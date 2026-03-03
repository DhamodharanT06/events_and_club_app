import 'package:event_lister/models/event_model.dart';
import 'package:event_lister/services/supabase_service.dart';
import 'package:uuid/uuid.dart';

/// EventService 
class EventService {
  static final EventService _instance = EventService._internal();

  late SupabaseService _supabaseService;

  factory EventService() => _instance;

  EventService._internal() {
    _supabaseService = SupabaseService.instance;
  }

  static EventService get instance => _instance;

  /// Get all active events ordered by event_date ascending.
  Future<List<Event>> getEvents() async {
    try {
      final response = await _supabaseService.client!
          .from('events')
          .select()
          .eq('is_active', true)
          .order('event_date', ascending: true);
      return (response as List).map((e) => Event.fromJson(e)).toList();
    } catch (e) {
      print('⚠️ EventService.getEvents error: $e');
      return [];
    }
  }

  /// Get events belonging to a specific club.
  Future<List<Event>> getEventsByClub(String clubId) async {
    try {
      final response = await _supabaseService.client!
          .from('events')
          .select()
          .eq('club_id', clubId)
          .eq('is_active', true)
          .order('event_date', ascending: true);
      return (response as List).map((e) => Event.fromJson(e)).toList();
    } catch (e) {
      print('⚠️ EventService.getEventsByClub error: $e');
      return [];
    }
  }

  /// Get a single event by its ID.
  Future<Event?> getEventById(String id) async {
    try {
      final response = await _supabaseService.client!
          .from('events')
          .select()
          .eq('id', id)
          .maybeSingle();
      return response != null ? Event.fromJson(response) : null;
    } catch (e) {
      print('⚠️ EventService.getEventById error: $e');
      return null;
    }
  }

  /// Create a new event and persist it to Supabase.
  Future<Event> createEvent({
    required String title,
    required String description,
    required String location,
    required DateTime eventDate,
    required String clubId,
    required String createdBy,
    String? imageUrl,
    String? googleFormLink,
    required int capacity,
  }) async {
    final id = const Uuid().v4();
    final now = DateTime.now();
    final payload = {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'event_date': '${eventDate.year.toString().padLeft(4, '0')}-'
          '${eventDate.month.toString().padLeft(2, '0')}-'
          '${eventDate.day.toString().padLeft(2, '0')}',
      'event_time':
          '${eventDate.hour.toString().padLeft(2, '0')}:${eventDate.minute.toString().padLeft(2, '0')}:00',
      'club_id': clubId,
      'created_by': createdBy,
      'image_url': imageUrl,
      'google_form_link': googleFormLink,
      'capacity': capacity,
      'registration_count': 0,
      'created_at': now.toIso8601String(),
      'is_active': true,
    };
    final response = await _supabaseService.client!
        .from('events')
        .insert(payload)
        .select()
        .single();
    print('✅ Event created in Supabase: $id');
    return Event.fromJson(response);
  }

  /// Update an existing event.
  Future<Event> updateEvent(String id, {
    String? title,
    String? description,
    String? location,
    DateTime? eventDate,
    String? imageUrl,
    String? googleFormLink,
    int? capacity,
  }) async {
    final updateData = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (title != null) updateData['title'] = title;
    if (description != null) updateData['description'] = description;
    if (location != null) updateData['location'] = location;
    if (eventDate != null) {
      updateData['event_date'] = '${eventDate.year.toString().padLeft(4, '0')}-'
          '${eventDate.month.toString().padLeft(2, '0')}-'
          '${eventDate.day.toString().padLeft(2, '0')}';
      updateData['event_time'] =
          '${eventDate.hour.toString().padLeft(2, '0')}:${eventDate.minute.toString().padLeft(2, '0')}:00';
    }
    if (imageUrl != null) updateData['image_url'] = imageUrl;
    if (googleFormLink != null) updateData['google_form_link'] = googleFormLink;
    if (capacity != null) updateData['capacity'] = capacity;
    final response = await _supabaseService.client!
        .from('events')
        .update(updateData)
        .eq('id', id)
        .select()
        .single();
    print('✅ Event updated in Supabase: $id');
    return Event.fromJson(response);
  }

  /// Soft-delete an event (set is_active = false).
  Future<void> deleteEvent(String id) async {
    await _supabaseService.client!
        .from('events')
        .update({'is_active': false, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', id);
    print('✅ Event deleted (soft) in Supabase: $id');
  }

  /// Search events by title (case-insensitive).
  Future<List<Event>> searchEvents(String query) async {
    try {
      final response = await _supabaseService.client!
          .from('events')
          .select()
          .ilike('title', '%$query%')
          .eq('is_active', true)
          .order('event_date', ascending: true);
      return (response as List).map((e) => Event.fromJson(e)).toList();
    } catch (e) {
      print('⚠️ EventService.searchEvents error: $e');
      return [];
    }
  }

  /// Increment/decrement the cached registration_count on the event row.
  Future<void> updateRegistrationCount(String eventId, int delta) async {
    try {
      final event = await getEventById(eventId);
      if (event == null) return;
      final newCount = (event.registrationCount + delta).clamp(0, event.capacity);
      await _supabaseService.client!
          .from('events')
          .update({'registration_count': newCount})
          .eq('id', eventId);
    } catch (e) {
      print('⚠️ EventService.updateRegistrationCount error: $e');
    }
  }

  /// Get the live registration count for an event from the registrations table.
  Future<int> getRealRegistrationCount(String eventId) async {
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
}