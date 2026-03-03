import 'package:flutter/material.dart';
import 'package:event_lister/models/event_model.dart';
import 'package:event_lister/models/user_model.dart';
import 'package:event_lister/services/event_recommendation_service.dart';

class RecommendedEventsWidget extends StatefulWidget {
  final User user;
  final Function(Event) onEventTap;

  const RecommendedEventsWidget({
    Key? key,
    required this.user,
    required this.onEventTap,
  }) : super(key: key);

  @override
  State<RecommendedEventsWidget> createState() =>
      _RecommendedEventsWidgetState();
}

class _RecommendedEventsWidgetState extends State<RecommendedEventsWidget> {
  late Future<List<Event>> _recommendedEvents;
  final _recommendationService = EventRecommendationService.instance;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  void _loadRecommendations() {
    _recommendedEvents = _recommendationService.getRecommendedEvents(
      user: widget.user,
      limit: 10,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recommended For You',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _loadRecommendations();
                  });
                },
                child: Icon(
                  Icons.refresh,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ),
        FutureBuilder<List<Event>>(
          future: _recommendedEvents,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  height: 200,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error loading recommendations'),
              );
            }

            final events = snapshot.data ?? [];

            if (events.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No recommendations available yet',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              );
            }

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  ...events.take(5).map((event) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () => widget.onEventTap(event),
                        child: _RecommendedEventCard(event: event),
                      ),
                    );
                  }).toList(),
                  // Add "View All" card
                  GestureDetector(
                    onTap: () => widget.onEventTap(events[0]),
                    child: Container(
                      width: 150,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .primaryColor
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_forward,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'View All',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _RecommendedEventCard extends StatelessWidget {
  final Event event;

  const _RecommendedEventCard({
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    final daysUntil =
        event.eventDate.difference(DateTime.now()).inDays;
    final dateStr = daysUntil == 0
        ? 'Today'
        : daysUntil == 1
            ? 'Tomorrow'
            : '$daysUntil days away';

    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event Image
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              color: Colors.grey[300],
            ),
            child: event.imageUrl != null
                ? Image.network(
                    event.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.event),
                      );
                    },
                  )
                : Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.event),
                  ),
          ),
          // Event Details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateStr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Registration count
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        size: 10,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${event.registrationCount} going',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
