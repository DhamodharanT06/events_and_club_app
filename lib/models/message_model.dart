class Message {
  final String id;
  final String clubId;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;

  Message({
    required this.id,
    required this.clubId,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      clubId: json['clubId'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'clubId': clubId,
        'senderId': senderId,
        'senderName': senderName,
        'message': message,
        'timestamp': timestamp.toIso8601String(),
      };
}
