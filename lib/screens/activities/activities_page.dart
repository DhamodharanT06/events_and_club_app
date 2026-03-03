import 'package:flutter/material.dart';
import 'package:event_lister/constants/app_constants.dart';
import 'package:event_lister/models/event_model.dart';
import 'package:event_lister/models/club_model.dart';
import 'package:event_lister/services/registration_service.dart';
import 'package:event_lister/services/event_service.dart';
import 'package:event_lister/services/club_service.dart';
import 'package:event_lister/services/auth_service.dart';
import '../event/event_detail_page.dart';
import '../club/club_detail_page.dart';

class ActivitiesPage extends StatefulWidget {
  const ActivitiesPage({super.key});

  @override
  State<ActivitiesPage> createState() => _ActivitiesPageState();
}

class _ActivitiesPageState extends State<ActivitiesPage> {
  late RegistrationService _registrationService;
  late EventService _eventService;
  late ClubService _clubService;
  late AuthService _authService;
  List<Event> _registeredEvents = [];
  List<Club> _registeredClubs = [];
  bool _isLoading = true;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _registrationService = RegistrationService.instance;
    _eventService = EventService.instance;
    _clubService = ClubService.instance;
    _authService = AuthService.instance;
    _loadActivities();
  }

  void _loadActivities() async {
    try {
      final userId = _authService.getCurrentUser()?.id;
      if (userId != null) {
        // Load registered events
        final registrations =
            await _registrationService.getUserEventRegistrations(userId);
        List<Event> events = [];
        for (var reg in registrations) {
          final event = await _eventService.getEventById(reg.eventId);
          if (event != null) {
            events.add(event);
          }
        }

        // Load registered clubs
        final clubs = await _clubService.getUserClubs(userId);

        if (mounted) {
          setState(() {
            _registeredEvents = events;
            _registeredClubs = clubs;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: _selectedTabIndex,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Activities'),
          centerTitle: true,
          automaticallyImplyLeading: false,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          bottom: TabBar(
            onTap: (index) {
              setState(() {
                _selectedTabIndex = index;
              });
            },
            labelColor: Colors.white,
            indicatorColor: AppColors.secondary,
            tabs: const [
              Tab(child: Text('Registered Events', style: TextStyle(color: Colors.white))),
              Tab(child: Text('My Clubs', style: TextStyle(color: Colors.white))),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Registered Events Tab
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _registeredEvents.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_note,
                              size: 64,
                              color: AppColors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No registered events',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: AppColors.grey,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Register for events to see them here',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.grey,
                                  ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(
                            AppDimensions.paddingMedium),
                        itemCount: _registeredEvents.length,
                        itemBuilder: (context, index) {
                          final event = _registeredEvents[index];
                          return _EventRegistrationCard(
                            event: event,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      EventDetailPage(event: event),
                                ),
                              );
                            },
                          );
                        },
                      ),
            // My Clubs Tab
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _registeredClubs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.groups,
                              size: 64,
                              color: AppColors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Not a member of any club',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: AppColors.grey,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Join clubs to see them here',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.grey,
                                  ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(
                            AppDimensions.paddingMedium),
                        itemCount: _registeredClubs.length,
                        itemBuilder: (context, index) {
                          final club = _registeredClubs[index];
                          return _ClubCard(
                            club: club,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ClubDetailPage(club: club),
                                ),
                              );
                            },
                          );
                        },
                      ),
          ],
        ),
      ),
    );
  }
}

class _EventRegistrationCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;

  const _EventRegistrationCard({
    required this.event,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: AppColors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${event.eventDate.day}/${event.eventDate.month}/${event.eventDate.year}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.grey,
                        ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.access_time_outlined,
                    size: 16,
                    color: AppColors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${event.eventDate.hour.toString().padLeft(2, '0')}:${event.eventDate.minute.toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.grey,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: AppColors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    event.location,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.grey,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClubCard extends StatelessWidget {
  final Club club;
  final VoidCallback onTap;

  const _ClubCard({
    required this.club,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                club.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                club.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.grey,
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 16,
                    color: AppColors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${club.memberCount} members',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.grey,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
