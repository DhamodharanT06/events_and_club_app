import 'dart:convert';
import 'dart:math' show min;
import 'package:http/http.dart' as http;
import 'package:event_lister/models/ai_model.dart';
import 'package:event_lister/models/event_model.dart';
import 'package:event_lister/models/club_model.dart';
import 'package:event_lister/services/event_service.dart';
import 'package:event_lister/services/club_service.dart';
import 'package:event_lister/services/registration_service.dart';
import 'package:event_lister/parameters.dart';
import 'package:uuid/uuid.dart';

class AIAgentService {
  static final AIAgentService _instance = AIAgentService._internal();

  late EventService _eventService;
  late ClubService _clubService;
  late RegistrationService _registrationService;

  List<AIMessage> _conversationHistory = [];

  factory AIAgentService() {
    return _instance;
  }

  AIAgentService._internal() {
    _eventService = EventService.instance;
    _clubService = ClubService.instance;
    _registrationService = RegistrationService.instance;
  }

  static AIAgentService get instance => _instance;

  // ──────────────────────────────────────────────────────────────────────────
  // PUBLIC ENTRY POINT
  // ──────────────────────────────────────────────────────────────────────────

  /// Send message – tries Gemini LLM first, falls back to rich local processing
  Future<AIResponse> sendMessage(String userMessage) async {
    try {
      _conversationHistory.add(AIMessage(
        id: const Uuid().v4(),
        content: userMessage,
        sender: 'user',
        timestamp: DateTime.now(),
      ));

      final events = await _eventService.getEvents();
      final clubs = await _clubService.getClubs();

      AIResponse response;

      // Try Gemini LLM
      final geminiText = await _callGeminiApi(userMessage, events, clubs);
      if (geminiText != null && geminiText.isNotEmpty) {
        response = _buildResponseFromLLM(geminiText, userMessage, events, clubs);
      } else {
        // Rich local fallback
        response = await _processQueryLocally(userMessage, events, clubs);
      }

      _conversationHistory.add(AIMessage(
        id: const Uuid().v4(),
        content: response.message,
        sender: 'agent',
        timestamp: DateTime.now(),
      ));

      return response;
    } catch (e) {
      print('Error in sendMessage: $e');
      return AIResponse(
        message: 'Sorry, I encountered an error. Please try again.',
        suggestedEvents: null,
        suggestedClubs: null,
        action: 'error',
      );
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // GEMINI LLM INTEGRATION
  // ──────────────────────────────────────────────────────────────────────────

  /// Build a complete data-context string containing every event and club
  Future<String> _buildDataContext(List<Event> events, List<Club> clubs) async {
    final buf = StringBuffer();

    buf.writeln('=== EVENTS (${events.length} total) ===');
    for (var i = 0; i < events.length; i++) {
      final e = events[i];
      final regCount = await _registrationService.getEventRegistrationsCount(e.id);
      buf.writeln(
        '${i + 1}. Title: ${e.title}\n'
        '   Description: ${e.description}\n'
        '   Location: ${e.location}\n'
        '   Date: ${_fmt(e.eventDate)}\n'
        '   Capacity: $regCount / ${e.capacity} registered\n'
        '   Club ID: ${e.clubId}'
        '${e.googleFormLink != null && e.googleFormLink!.isNotEmpty ? "\n   Form: ${e.googleFormLink}" : ""}\n',
      );
    }

    buf.writeln('=== CLUBS (${clubs.length} total) ===');
    for (var i = 0; i < clubs.length; i++) {
      final c = clubs[i];
      buf.writeln(
        '${i + 1}. Name: ${c.name}\n'
        '   Description: ${c.description}\n'
        '   Members: ${c.memberCount}\n',
      );
    }

    return buf.toString();
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';

  /// Call OpenRouter API with Gemini model; returns response text or null on any failure
  Future<String?> _callGeminiApi(
      String userMessage, List<Event> events, List<Club> clubs) async {
    try {
      final context = await _buildDataContext(events, clubs);

      final systemPrompt =
          'You are an AI assistant for an Event Lister app. '
          'Answer ONLY using the real-time data below. '
          'For ALL EVENTS requests: list every event with title, location, date, and registrations/capacity. '
          'For ALL CLUBS requests: list every club with name, description, and member count. '
          'For a specific event/club: give ALL its details. '
          'Use emojis: 🎉 events, 👥 clubs/people, 📍 location, 📅 date. '
          'Today is ${_fmt(DateTime.now())}.\n\n$context';

      final url = Uri.parse(geminiApiUrl);

      final body = jsonEncode({
        'model': geminiModel,
        'messages': [
          {
            'role': 'system',
            'content': systemPrompt,
          },
          {
            'role': 'user',
            'content': userMessage,
          },
        ],
        'temperature': 0.5,
        'max_tokens': 1024,
      });

      final resp = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $openRouterApiKey',
          'X-Title': 'Event Lister AI',
        },
        body: body,
      ).timeout(const Duration(seconds: 15));

      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body);
        return json['choices']?[0]?['message']?['content'] as String?;
      }
      print('OpenRouter ${resp.statusCode}: ${resp.body}');
      return null;
    } catch (e) {
      print('OpenRouter call failed: $e');
      return null;
    }
  }

  /// Wrap LLM text into AIResponse, attaching relevant suggestions
  AIResponse _buildResponseFromLLM(
      String text, String query, List<Event> events, List<Club> clubs) {
    final q = query.toLowerCase();
    List<Event>? suggestedEvents;
    List<Club>? suggestedClubs;
    String action = 'llm_response';

    if (q.contains('club')) {
      suggestedClubs = _matchClubs(q, clubs).take(3).toList();
      if (suggestedClubs.isEmpty) suggestedClubs = clubs.take(3).toList();
      action = 'show_clubs';
    } else {
      suggestedEvents = _matchEvents(q, events).take(3).toList();
      if (suggestedEvents.isEmpty) suggestedEvents = events.take(3).toList();
      action = 'show_events';
    }

    return AIResponse(
      message: text,
      suggestedEvents: suggestedEvents,
      suggestedClubs: suggestedClubs,
      action: action,
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // RICH LOCAL FALLBACK
  // ──────────────────────────────────────────────────────────────────────────

  Future<AIResponse> _processQueryLocally(
      String userMessage, List<Event> events, List<Club> clubs) async {
    final q = userMessage.toLowerCase().trim();

    // ALL EVENTS
    if (_isAllQuery(q, 'event')) {
      return AIResponse(
        message: await _allEventsMsg(events),
        suggestedEvents: events.take(3).toList(),
        suggestedClubs: null,
        action: 'show_events',
      );
    }

    // ALL CLUBS
    if (_isAllQuery(q, 'club')) {
      return AIResponse(
        message: _allClubsMsg(clubs),
        suggestedEvents: null,
        suggestedClubs: clubs.take(3).toList(),
        action: 'show_clubs',
      );
    }

    // SPECIFIC EVENT BY NAME (highest priority)
    final specificEvent = _findExactEvent(q, events);
    if (specificEvent != null) {
      return AIResponse(
        message: await _detailedEventMsg(specificEvent),
        suggestedEvents: [specificEvent],
        suggestedClubs: null,
        action: 'show_event_detail',
      );
    }

    // SPECIFIC CLUB BY NAME (highest priority)
    final specificClub = _findExactClub(q, clubs);
    if (specificClub != null) {
      return AIResponse(
        message: _detailedClubMsg(specificClub),
        suggestedEvents: null,
        suggestedClubs: [specificClub],
        action: 'show_club_detail',
      );
    }

    // EVENT SEARCH
    if (q.contains('event') || q.contains('find event') ||
        q.contains('show event') || q.contains('search')) {
      final matched = _matchEvents(q, events);
      final list = matched.isEmpty ? events : matched;
      return AIResponse(
        message: await _eventListMsg(list, matched.isEmpty),
        suggestedEvents: list.take(3).toList(),
        suggestedClubs: null,
        action: 'show_events',
      );
    }

    // CLUB SEARCH
    if (q.contains('club') || q.contains('find club') ||
        q.contains('join') || q.contains('recommend')) {
      final matched = _matchClubs(q, clubs);
      final list = matched.isEmpty ? clubs : matched;
      return AIResponse(
        message: _clubListMsg(list, matched.isEmpty),
        suggestedEvents: null,
        suggestedClubs: list.take(3).toList(),
        action: 'show_clubs',
      );
    }

    // LOCATION
    if (q.contains('location') || q.contains('where') || q.contains(' in ')) {
      final loc = _matchByLocation(q, events);
      final list = loc.isEmpty ? events : loc;
      return AIResponse(
        message: await _locationMsg(list, loc.isEmpty),
        suggestedEvents: list.take(3).toList(),
        suggestedClubs: null,
        action: 'show_events',
      );
    }

    // POPULAR / TRENDING
    if (q.contains('popular') || q.contains('trending') ||
        q.contains('best') || q.contains('top')) {
      final topEvt = await _topEvents(events);
      final topClb = _topClubs(clubs);
      final buf = StringBuffer('🔥 Most Popular:\n\n📌 Top Events:\n');
      for (var i = 0; i < min(5, topEvt.length); i++) {
        final e = topEvt[i];
        final n = await _registrationService.getEventRegistrationsCount(e.id);
        buf.writeln('${i + 1}. ${e.title}\n   📍 ${e.location} | 📅 ${_fmt(e.eventDate)} | 👥 $n/${e.capacity}');
      }
      buf.writeln('\n👥 Top Clubs:');
      for (var i = 0; i < min(5, topClb.length); i++) {
        final c = topClb[i];
        buf.writeln('${i + 1}. ${c.name}\n   ${c.description}\n   👥 ${c.memberCount} members');
      }
      return AIResponse(
        message: buf.toString(),
        suggestedEvents: topEvt.take(3).toList(),
        suggestedClubs: topClb.take(3).toList(),
        action: 'show_trending',
      );
    }

    // HELP / GREETING
    if (q.contains('help') || q.contains('how') ||
        q == 'hi' || q == 'hello' || q == 'hey') {
      return AIResponse(
        message: '👋 Hi! I\'m your Event Lister AI.\n\n'
            'I can help you with:\n'
            '🎉 Events – "Show all events" | "Find Flutter events" | "Tell me about Flutter Workshop"\n'
            '👥 Clubs  – "Show all clubs" | "Find tech clubs" | "What is Tech Club"\n'
            '📍 Location – "Events in Auditorium"\n'
            '🔥 Trending – "Popular events" | "Top clubs"\n\n'
            'Try a suggestion below or type your question!',
        suggestedEvents: null,
        suggestedClubs: null,
        action: 'help',
      );
    }

    // DEFAULT OVERVIEW
    final buf = StringBuffer('👋 Here\'s a quick overview:\n\n'
        '🎉 Events (${events.length} total):\n');
    for (var i = 0; i < min(5, events.length); i++) {
      final e = events[i];
      final n = await _registrationService.getEventRegistrationsCount(e.id);
      buf.writeln('  ${i + 1}. ${e.title} – 📍 ${e.location} | 👥 $n/${e.capacity}');
    }
    if (events.length > 5) buf.writeln('  ...and ${events.length - 5} more');
    buf.writeln('\n👥 Clubs (${clubs.length} total):');
    for (var i = 0; i < min(5, clubs.length); i++) {
      final c = clubs[i];
      buf.writeln('  ${i + 1}. ${c.name} | 👥 ${c.memberCount} members');
    }
    if (clubs.length > 5) buf.writeln('  ...and ${clubs.length - 5} more');
    buf.writeln('\n💡 Ask "Show all events" or "Show all clubs" for full details!');

    return AIResponse(
      message: buf.toString(),
      suggestedEvents: events.take(3).toList(),
      suggestedClubs: clubs.take(3).toList(),
      action: 'show_all',
    );
  }

  // MESSAGE 
  /// Find event by exact or close name match
  Event? _findExactEvent(String q, List<Event> events) {
    final cleaned = q
        .replaceAll(RegExp(r'tell me about|what is|about|show me|find|search for|get me'), '')
        .trim();
    
    if (cleaned.isEmpty) return null;
    
    // First try exact match
    for (final event in events) {
      if (event.title.toLowerCase() == cleaned) {
        return event;
      }
    }
    
    // Then try partial/contains match
    for (final event in events) {
      if (event.title.toLowerCase().contains(cleaned) ||
          cleaned.contains(event.title.toLowerCase())) {
        return event;
      }
    }
    
    return null;
  }

  /// Find club by exact or close name match
  Club? _findExactClub(String q, List<Club> clubs) {
    final cleaned = q
        .replaceAll(RegExp(r'tell me about|what is|about|show me|find|search for|get me|join'), '')
        .trim();
    
    if (cleaned.isEmpty) return null;
    
    for (final club in clubs) {
      if (club.name.toLowerCase() == cleaned) {
        return club;
      }
    }
    
    for (final club in clubs) {
      if (club.name.toLowerCase().contains(cleaned) ||
          cleaned.contains(club.name.toLowerCase())) {
        return club;
      }
    }
    
    return null;
  }

  /// Detailed message for a specific event
  Future<String> _detailedEventMsg(Event event) async {
    final regCount = await _registrationService.getEventRegistrationsCount(event.id);
    final available = event.capacity - regCount;
    final remainingSpots = available > 0 ? '\n   ✅ $available spots available' : '\n   ❌ Event is full';
    
    return '''🎉 ${event.title}
   
📍 Location: ${event.location}
📅 Date: ${_fmt(event.eventDate)}

📝 Description:
${event.description}

👥 Registrations: $regCount / ${event.capacity}$remainingSpots

${event.googleFormLink != null && event.googleFormLink!.isNotEmpty ? '📋 Google Form: ${event.googleFormLink}' : ''}

💡 Tap the event to register or view more details!''';
  }

  /// Detailed message for a specific club
  String _detailedClubMsg(Club club) {
    return '''👥 ${club.name}

📝 Description:
${club.description}

👨‍👩‍👧‍👦 Members: ${club.memberCount}

💡 Tap the club to view all members, events, or join!''';
  }

  Future<String> _allEventsMsg(List<Event> events) async {
    if (events.isEmpty) return '❌ No events available right now.';
    final buf = StringBuffer('🎉 All Events (${events.length}):\n\n');
    for (var i = 0; i < events.length; i++) {
      final e = events[i];
      final n = await _registrationService.getEventRegistrationsCount(e.id);
      buf.writeln('${i + 1}. ${e.title}');
      buf.writeln('   📍 ${e.location}');
      buf.writeln('   📅 ${_fmt(e.eventDate)}');
      buf.writeln('   👥 $n / ${e.capacity} registered');
      buf.writeln('   ${e.description}');
      buf.writeln();
    }
    buf.writeln('Tap any event to view full details & register!');
    return buf.toString();
  }

  String _allClubsMsg(List<Club> clubs) {
    if (clubs.isEmpty) return '❌ No clubs available right now.';
    final buf = StringBuffer('👥 All Clubs (${clubs.length}):\n\n');
    for (var i = 0; i < clubs.length; i++) {
      final c = clubs[i];
      buf.writeln('${i + 1}. ${c.name}');
      buf.writeln('   ${c.description}');
      buf.writeln('   👥 ${c.memberCount} members');
      buf.writeln();
    }
    buf.writeln('Tap any club to view details & join!');
    return buf.toString();
  }

  Future<String> _eventListMsg(List<Event> events, bool showAll) async {
    if (events.isEmpty) return '❌ No events found. Try "show all events"!';
    final label = showAll ? 'All Events (${events.length})' : 'Found ${events.length} event(s)';
    final buf = StringBuffer('🎉 $label:\n\n');
    for (var i = 0; i < min(10, events.length); i++) {
      final e = events[i];
      final n = await _registrationService.getEventRegistrationsCount(e.id);
      buf.writeln('${i + 1}. ${e.title}');
      buf.writeln('   📍 ${e.location}');
      buf.writeln('   📅 ${_fmt(e.eventDate)}');
      buf.writeln('   👥 $n / ${e.capacity} registered');
      buf.writeln('   ${e.description}');
      buf.writeln();
    }
    if (events.length > 10) buf.writeln('...and ${events.length - 10} more');
    buf.writeln('Tap any event to register!');
    return buf.toString();
  }

  String _clubListMsg(List<Club> clubs, bool showAll) {
    if (clubs.isEmpty) return '❌ No clubs found. Try "show all clubs"!';
    final label = showAll ? 'All Clubs (${clubs.length})' : 'Found ${clubs.length} club(s)';
    final buf = StringBuffer('👥 $label:\n\n');
    for (var i = 0; i < min(10, clubs.length); i++) {
      final c = clubs[i];
      buf.writeln('${i + 1}. ${c.name}');
      buf.writeln('   ${c.description}');
      buf.writeln('   👥 ${c.memberCount} members');
      buf.writeln();
    }
    if (clubs.length > 10) buf.writeln('...and ${clubs.length - 10} more');
    buf.writeln('Tap any club to join!');
    return buf.toString();
  }

  Future<String> _locationMsg(List<Event> events, bool noMatch) async {
    final buf = StringBuffer();
    if (noMatch) {
      buf.writeln('📍 No events found for that location. Showing all:\n');
    } else {
      buf.writeln('📍 Events at this location (${events.length}):\n');
    }
    for (var i = 0; i < min(10, events.length); i++) {
      final e = events[i];
      final n = await _registrationService.getEventRegistrationsCount(e.id);
      buf.writeln('${i + 1}. ${e.title}');
      buf.writeln('   📍 ${e.location}');
      buf.writeln('   📅 ${_fmt(e.eventDate)}');
      buf.writeln('   👥 $n / ${e.capacity} registered');
      buf.writeln();
    }
    return buf.toString();
  }

  // SEARCH / SORT HELPERS
  bool _isAllQuery(String q, String type) =>
      q == 'all ${type}s' ||
      q == 'all $type' ||
      q.contains('all ${type}s') ||
      q.contains('list all ${type}s') ||
      q.contains('show all ${type}s') ||
      q.contains('list all $type') ||
      q.contains('show all $type') ||
      q.contains('every $type');

  List<Event> _matchEvents(String q, List<Event> events) {
    final kw = q
        .replaceAll(RegExp(r'show|find|get|list|search|me|all|events?'), '')
        .trim();
    if (kw.isEmpty) return [];
    return events
        .where((e) =>
            e.title.toLowerCase().contains(kw) ||
            e.description.toLowerCase().contains(kw) ||
            e.location.toLowerCase().contains(kw))
        .toList();
  }

  List<Club> _matchClubs(String q, List<Club> clubs) {
    final kw = q
        .replaceAll(RegExp(r'show|find|get|list|search|me|all|clubs?|recommend|join'), '')
        .trim();
    if (kw.isEmpty) return [];
    return clubs
        .where((c) =>
            c.name.toLowerCase().contains(kw) ||
            c.description.toLowerCase().contains(kw))
        .toList();
  }

  List<Event> _matchByLocation(String q, List<Event> events) =>
      events.where((e) => e.location.toLowerCase().contains(q)).toList();

  Future<List<Event>> _topEvents(List<Event> events) async {
    final list = <Event>[];
    for (final e in events) {
      final n = await _registrationService.getEventRegistrationsCount(e.id);
      list.add(e.copyWith(registrationCount: n));
    }
    list.sort((a, b) => b.registrationCount.compareTo(a.registrationCount));
    return list;
  }

  List<Club> _topClubs(List<Club> clubs) {
    final s = List<Club>.from(clubs);
    s.sort((a, b) => b.memberCount.compareTo(a.memberCount));
    return s;
  }

  // HISTORY
  List<AIMessage> getConversationHistory() => _conversationHistory;

  void clearHistory() => _conversationHistory.clear();
}
