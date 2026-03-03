import 'package:event_lister/models/event_model.dart';
import 'package:event_lister/models/user_model.dart';
import 'package:event_lister/services/event_service.dart';
import 'package:event_lister/services/registration_service.dart';

class EventRecommendationService {
  static final EventRecommendationService _instance =
      EventRecommendationService._internal();

  late EventService _eventService;
  late RegistrationService _registrationService;

  factory EventRecommendationService() {
    return _instance;
  }

  EventRecommendationService._internal() {
    _eventService = EventService.instance;
    _registrationService = RegistrationService.instance;
  }

  static EventRecommendationService get instance => _instance;

  /// Get personalized event recommendations for a user
  Future<List<Event>> getRecommendedEvents({
    required User user,
    int limit = 10,
  }) async {
    try {
      final allEvents = await _eventService.getEvents();
      final registrations = await _registrationService.getUserEventRegistrations(user.id);

      // Get registered event IDs
      final registeredEventIds =
          registrations.map((r) => r.eventId).toSet();

      // Filter out registered events
      final availableEvents = allEvents
          .where((e) => !registeredEventIds.contains(e.id))
          .toList();

      // Score events based on multiple factors
      final scoredEvents = availableEvents.map((event) {
        double score = 0;

        // Recency (upcoming soon = higher score)
        final daysUntilEvent =
            event.eventDate.difference(DateTime.now()).inDays;
        if (daysUntilEvent >= 0 && daysUntilEvent <= 7) {
          score += 30;
        } else if (daysUntilEvent > 7 && daysUntilEvent <= 30) {
          score += 20;
        } else if (daysUntilEvent > 30) {
          score += 10;
        }

        // Popularity (registration count)
        score += (event.registrationCount * 2).toDouble();

        // Availability (spots still available)
        final spotsAvailable =
            event.capacity - event.registrationCount;
        if (spotsAvailable > 0) {
          score +=
              (spotsAvailable / event.capacity * 20);
        }

        // Description relevance (simple keyword matching)
        final keywords = [
          'workshop',
          'seminar',
          'networking',
          'social',
          'tech',
          'sports',
          'arts'
        ];
        for (var keyword in keywords) {
          if (event.description.toLowerCase().contains(keyword)) {
            score += 5;
          }
        }

        return {'event': event, 'score': score};
      }).toList();

      // Sort by score
      scoredEvents.sort((a, b) =>
          (b['score'] as double).compareTo(a['score'] as double));

      // Return top recommendations
      return scoredEvents
          .take(limit)
          .map((item) => item['event'] as Event)
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get trending events (most popular)
  Future<List<Event>> getTrendingEvents({int limit = 5}) async {
    try {
      final allEvents = await _eventService.getEvents();

      // Sort by registration count
      allEvents.sort((a, b) =>
          b.registrationCount.compareTo(a.registrationCount));

      return allEvents.take(limit).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get events by category/keyword
  Future<List<Event>> getEventsByCategory({
    required String category,
    int limit = 10,
  }) async {
    try {
      final allEvents = await _eventService.getEvents();

      final filtered = allEvents
          .where((event) =>
              event.title.toLowerCase().contains(category.toLowerCase()) ||
              event.description
                  .toLowerCase()
                  .contains(category.toLowerCase()))
          .toList();

      return filtered.take(limit).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get events happening today or tomorrow
  Future<List<Event>> getUpcomingEvents({int limit = 10}) async {
    try {
      final allEvents = await _eventService.getEvents();
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));

      final upcoming = allEvents
          .where((event) =>
              event.eventDate.isAfter(now) &&
              event.eventDate.isBefore(tomorrow.add(const Duration(days: 1))))
          .toList();

      // Sort by start date
      upcoming.sort((a, b) => a.eventDate.compareTo(b.eventDate));

      return upcoming.take(limit).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get similar events based on a given event
  Future<List<Event>> getSimilarEvents({
    required Event event,
    int limit = 5,
  }) async {
    try {
      final allEvents = await _eventService.getEvents();

      // Find events with similar keywords
      final keywords = event.title.split(' ')
          ..addAll(event.description.split(' '));

      final similar = allEvents
          .where((e) =>
              e.id != event.id &&
              keywords.any((keyword) =>
                  e.title.toLowerCase().contains(keyword.toLowerCase()) ||
                  e.description
                      .toLowerCase()
                      .contains(keyword.toLowerCase())))
          .toList();

      return similar.take(limit).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get event insights
  Future<Map<String, dynamic>> getEventInsights() async {
    try {
      final events = await _eventService.getEvents();

      if (events.isEmpty) {
        return {
          'total_events': 0,
          'average_registration': 0,
          'most_popular': null,
          'upcoming_count': 0,
        };
      }

      final now = DateTime.now();
      final upcoming =
          events.where((e) => e.eventDate.isAfter(now)).toList();
      final totalRegistrations =
          events.fold<int>(0, (sum, e) => sum + e.registrationCount);
      final avgRegistration = (totalRegistrations / events.length).round();

      final mostPopular = events.isEmpty
          ? null
          : events.reduce((a, b) => a.registrationCount > b.registrationCount
              ? a
              : b);

      return {
        'total_events': events.length,
        'average_registration': avgRegistration,
        'most_popular': mostPopular,
        'upcoming_count': upcoming.length,
        'total_registrations': totalRegistrations,
      };
    } catch (e) {
      return {};
    }
  }
}
