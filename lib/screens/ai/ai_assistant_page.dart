import 'package:flutter/material.dart';
import 'package:event_lister/constants/app_constants.dart';
import 'package:event_lister/services/ai_agent_service.dart';
import 'package:event_lister/services/event_service.dart';
import 'package:event_lister/services/club_service.dart';
import 'package:event_lister/models/ai_model.dart';
import 'package:event_lister/widgets/custom_widgets.dart';

class AIAssistantPage extends StatefulWidget {
  const AIAssistantPage({super.key});

  @override
  State<AIAssistantPage> createState() => _AIAssistantPageState();
}

class _AIAssistantPageState extends State<AIAssistantPage> {
  late TextEditingController _messageController;
  late AIAgentService _aiService;
  late EventService _eventService;
  late ClubService _clubService;
  bool _isLoading = false;
  List<AIMessage> _messages = [];
  List<dynamic> _recommendedEvents = [];
  List<dynamic> _recommendedClubs = [];

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _aiService = AIAgentService.instance;
    _eventService = EventService.instance;
    _clubService = ClubService.instance;
    _messages = _aiService.getConversationHistory();

    // Load recommended events and clubs
    _loadRecommendations();

    // Show welcome message if no messages
    if (_messages.isEmpty) {
      _showWelcomeMessage();
    }
  }

  void _loadRecommendations() async {
    try {
      final events = await _eventService.getEvents();
      final clubs = await _clubService.getClubs();
      
      if (mounted) {
        setState(() {
          _recommendedEvents = events.take(3).toList();
          _recommendedClubs = clubs.take(3).toList();
        });
      }
    } catch (e) {
      print('Error loading recommendations: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _showWelcomeMessage() {
    final welcomeMsg = AIMessage(
      id: 'welcome',
      content:
          'Hi! 👋 I\'m your Event Lister AI Assistant. I can help you find events, recommend clubs, and answer questions about our platform. Try asking me something like:\n\n• Find events in [location]\n• Recommend clubs for [topic]\n• Tell me about [event name]\n• What are popular events?',
      sender: 'agent',
      timestamp: DateTime.now(),
    );
    setState(() {
      _messages.insert(0, welcomeMsg);
    });
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _messageController.clear();

    setState(() {
      _isLoading = true;
      _messages.insert(
        0,
        AIMessage(
          id: DateTime.now().toString(),
          content: message,
          sender: 'user',
          timestamp: DateTime.now(),
        ),
      );
    });

    try {
      // Send message and get response
      final response = await _aiService.sendMessage(message);

      if (mounted) {
        setState(() {
          _messages.insert(
            0,
            AIMessage(
              id: DateTime.now().toString(),
              content: response.message.replaceAll("**", ""),
              sender: 'agent',
              timestamp: DateTime.now(),
            ),
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error: $e');
      if (mounted) {
        setState(() {
          _messages.insert(
            0,
            AIMessage(
              id: DateTime.now().toString(),
              content: 'Sorry, I encountered an error. Please try again.',
              sender: 'agent',
              timestamp: DateTime.now(),
            ),
          );
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Chat'),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Clear chat',
            onPressed: () {
              setState(() {
                _aiService.clearHistory();
                _messages.clear();
                _showWelcomeMessage();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? SingleChildScrollView(
                    child: Column(
                      children: [
                        // Welcome Section
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Icon(
                                Icons.smart_toy,
                                size: 64,
                                color: AppColors.primary.withOpacity(0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Welcome to Event Lister AI',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      color: AppColors.dark,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Ask me about events, clubs, or get personalized recommendations!',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: AppColors.grey,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),

                        // Quick Suggestion Buttons
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 16),
                              const Text(
                                '💡 Quick Suggestions',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.dark,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildSuggestionButton(
                                    '🎉 All Events',
                                    'Show all events',
                                  ),
                                  _buildSuggestionButton(
                                    '👥 All Clubs',
                                    'Show all clubs',
                                  ),
                                  _buildSuggestionButton(
                                    '🔥 Trending',
                                    'Popular events',
                                  ),
                                  _buildSuggestionButton(
                                    '📍 By Location',
                                    'Events in auditorium',
                                  ),
                                  _buildSuggestionButton(
                                    '💻 Tech',
                                    'Find tech events',
                                  ),
                                  _buildSuggestionButton(
                                    '🔱 Top Clubs',
                                    'Top clubs',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),

                        // Recommended For You Section
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    '✨ Recommended For You',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.dark,
                                    ),
                                  ),
                                  Text(
                                    'Trending',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Events Section
                              _buildRecommendedSection(
                                title: '🎉 Popular Events',
                                items: _recommendedEvents,
                                isEvent: true,
                              ),

                              const SizedBox(height: 20),

                              // Clubs Section
                              _buildRecommendedSection(
                                title: '👥 Trending Clubs',
                                items: _recommendedClubs,
                                isEvent: false,
                              ),

                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isUser = message.sender == 'user';

                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          constraints: BoxConstraints(
                            maxWidth:
                                MediaQuery.of(context).size.width * 0.8,
                          ),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isUser
                                ? AppColors.primary
                                : AppColors.lightGrey,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SelectableText(
                                message.content,
                                style: TextStyle(
                                  color: isUser
                                      ? Colors.white
                                      : Colors.black,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatTime(message.timestamp),
                                style: TextStyle(
                                  color: isUser
                                      ? Colors.white70
                                      : AppColors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AI is thinking...',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingSmall),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: AppColors.lightGrey),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Ask me anything about events...',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    enabled: !_isLoading,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  color: AppColors.primary,
                  onPressed: _isLoading ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedSection({
    required String title,
    required List items,
    required bool isEvent,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.dark,
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...items.map((item) {
                if (isEvent) {
                  final event = item;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: RecommendedCard(
                      title: event.title,
                      subtitle: event.location,
                      imageUrl: event.imageUrl,
                      stats:
                          '${event.currentRegistrations} going',
                      statsIcon: Icons.people,
                      accentColor: AppColors.primary,
                      onTap: () {
                        // Navigate to event detail
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Event: ${event.title}',
                            ),
                          ),
                        );
                      },
                    ),
                  );
                } else {
                  final club = item;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: RecommendedCard(
                      title: club.name,
                      subtitle: '${club.memberCount} members',
                      imageUrl: club.imageUrl,
                      stats: 'Active',
                      statsIcon: Icons.verified,
                      accentColor: Colors.green,
                      onTap: () {
                        // Navigate to club detail
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Club: ${club.name}',
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }
              }).toList(),
              // View All Card
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'View all ${isEvent ? 'events' : 'clubs'}',
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 160,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.arrow_forward,
                        color: AppColors.primary,
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'View All',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionButton(String label, String query) {
    return Material(
      child: InkWell(
        onTap: () {
          _messageController.text = query;
          _sendMessage();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.3),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}
