import 'package:flutter/material.dart';
import 'package:event_lister/constants/app_constants.dart';
import 'package:event_lister/models/message_model.dart';
import 'package:event_lister/services/chat_service.dart';
import 'package:event_lister/services/auth_service.dart';

class ChatPanel extends StatefulWidget {
  final String clubId;

  const ChatPanel({
    super.key,
    required this.clubId,
  });

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  late TextEditingController _messageController;
  late ChatService _chatService;
  late AuthService _authService;
  List<Message> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _chatService = ChatService.instance;
    _authService = AuthService.instance;
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _loadMessages() async {
    try {
      final messages = await _chatService.getClubMessages(widget.clubId);
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final currentUser = _authService.getCurrentUser();
    if (currentUser == null) return;

    try {
      await _chatService.sendMessage(
        clubId: widget.clubId,
        senderId: currentUser.id,
        senderName: currentUser.name,
        message: _messageController.text.trim(),
      );

      _messageController.clear();
      _loadMessages();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _messages.isEmpty
                  ? Center(
                      child: Text(
                        'No messages yet. Start the conversation!',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.grey,
                            ),
                      ),
                    )
                  : ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(
                          AppDimensions.paddingMedium),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message =
                            _messages[_messages.length - 1 - index];
                        return _MessageBubble(message: message);
                      },
                    ),
        ),
        Container(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                          AppDimensions.borderRadiusMedium),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  maxLines: null,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(
                    Icons.send,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final currentUserId = AuthService.instance.getCurrentUser()?.id;
    final isCurrentUser = message.senderId == currentUserId;

    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isCurrentUser ? AppColors.primary : AppColors.lightGrey,
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment:
              isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isCurrentUser)
              Text(
                message.senderName,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isCurrentUser ? Colors.white : AppColors.darkGrey,
                    ),
              ),
            if (!isCurrentUser) const SizedBox(height: 4),
            Text(
              message.message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isCurrentUser ? Colors.white : AppColors.darkGrey,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: isCurrentUser
                        ? Colors.white70
                        : AppColors.grey,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
