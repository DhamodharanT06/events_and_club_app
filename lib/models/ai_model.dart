import 'package:event_lister/models/event_model.dart';
import 'package:event_lister/models/club_model.dart';

class AIMessage {
  final String id;
  final String content;
  final String sender; // 'user' or 'agent'
  final DateTime timestamp;
  final String? eventId;
  final String? clubId;

  AIMessage({
    required this.id,
    required this.content,
    required this.sender,
    required this.timestamp,
    this.eventId,
    this.clubId,
  });
}

class AIResponse {
  final String message;
  final List<Event>? suggestedEvents;
  final List<Club>? suggestedClubs;
  final String? action; // 'search', 'recommend', 'info', 'help'

  AIResponse({
    required this.message,
    this.suggestedEvents,
    this.suggestedClubs,
    this.action,
  });
}
