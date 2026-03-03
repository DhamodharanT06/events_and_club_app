import 'package:event_lister/models/message_model.dart';
import 'package:uuid/uuid.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();

  static final Map<String, List<Message>> _clubMessages = {};

  factory ChatService() {
    return _instance;
  }

  ChatService._internal();

  static ChatService get instance => _instance;

  /// Send message to club
  Future<Message> sendMessage({
    required String clubId,
    required String senderId,
    required String senderName,
    required String message,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    if (!_clubMessages.containsKey(clubId)) {
      _clubMessages[clubId] = [];
    }

    final newMessage = Message(
      id: const Uuid().v4(),
      clubId: clubId,
      senderId: senderId,
      senderName: senderName,
      message: message,
      timestamp: DateTime.now(),
    );

    _clubMessages[clubId]!.add(newMessage);
    return newMessage;
  }

  /// Get club messages
  Future<List<Message>> getClubMessages(String clubId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    
    if (!_clubMessages.containsKey(clubId)) {
      return [];
    }

    return List.from(_clubMessages[clubId]!);
  }

  /// Get messages paginated (for scrolling)
  Future<List<Message>> getClubMessagesPaginated(
    String clubId, {
    required int limit,
    required int offset,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    if (!_clubMessages.containsKey(clubId)) {
      return [];
    }

    final messages = _clubMessages[clubId]!;
    final start = messages.length - offset - limit;
    final end = messages.length - offset;

    if (start < 0) {
      return messages.sublist(0, end > 0 ? end : 0);
    }

    return messages.sublist(start, end);
  }

  /// Send notification to club (broadcast message from admin)
  Future<Message> sendNotification({
    required String clubId,
    required String senderName,
    required String message,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    return sendMessage(
      clubId: clubId,
      senderId: 'system',
      senderName: senderName,
      message: '[NOTIFICATION] $message',
    );
  }

  /// Delete message
  Future<void> deleteMessage(String clubId, String messageId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    if (_clubMessages.containsKey(clubId)) {
      _clubMessages[clubId]!.removeWhere((msg) => msg.id == messageId);
    }
  }

  /// Get latest message from club
  Future<Message?> getLatestMessage(String clubId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    if (!_clubMessages.containsKey(clubId) || _clubMessages[clubId]!.isEmpty) {
      return null;
    }

    return _clubMessages[clubId]!.last;
  }

  /// Get unread count (simulated)
  Future<int> getUnreadCount(String clubId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return 0;
  }
}
