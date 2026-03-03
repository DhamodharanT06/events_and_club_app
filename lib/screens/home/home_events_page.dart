import 'package:flutter/material.dart';
import 'package:event_lister/constants/app_constants.dart';
import 'package:event_lister/models/event_model.dart';
import 'package:event_lister/services/event_service.dart';
import 'package:event_lister/services/auth_service.dart';
import 'package:event_lister/services/registration_service.dart';
import 'package:event_lister/widgets/custom_widgets.dart';
import 'package:event_lister/screens/admin/admin_add_event_page.dart';
import 'package:event_lister/screens/auth/login_page.dart';
import '../event/event_detail_page.dart';

class HomeEventsPage extends StatefulWidget {
  const HomeEventsPage({super.key});

  @override
  State<HomeEventsPage> createState() => _HomeEventsPageState();
}

class _HomeEventsPageState extends State<HomeEventsPage> {
  late TextEditingController _searchController;
  late EventService _eventService;
  late AuthService _authService;
  late RegistrationService _registrationService;
  List<Event> _allEvents = [];
  List<Event> _filteredEvents = [];
  bool _isLoading = true;
  Map<String, bool> _registeredEvents = {};

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _registrationService = RegistrationService.instance;
    _eventService = EventService.instance;
    _authService = AuthService.instance;
    _loadEvents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadEvents() async {
    try {
      final events = await _eventService.getEvents();
      final userId = _authService.getCurrentUser()?.id;
      
      // Load registration status for all events
      Map<String, bool> registered = {};
      if (userId != null) {
        for (var event in events) {
          final isReg = await _registrationService.isUserRegistered(
            userId,
            event.id,
          );
          registered[event.id] = isReg;
        }
      }
      
      if (mounted) {
        setState(() {
          _allEvents = events;
          _filteredEvents = events;
          _registeredEvents = registered;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading events: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshEvents() async {
    setState(() {
      _isLoading = true;
      _allEvents = [];
      _filteredEvents = [];
    });
    _loadEvents();
  }

  void _searchEvents(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredEvents = _allEvents;
      });
    } else {
      setState(() {
        _filteredEvents = _allEvents
            .where((event) =>
                event.title.toLowerCase().contains(query.toLowerCase()) ||
                event.description.toLowerCase().contains(query.toLowerCase()) ||
                event.location.toLowerCase().contains(query.toLowerCase()))
            .toList();
      });
    }
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              AuthService.instance.logout();
              Navigator.of(ctx).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (_) => false,
              );
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _authService.isAdmin();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: RefreshIndicator(
      onRefresh: _refreshEvents,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, ${_authService.getCurrentUser()?.name}!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Explore upcoming events and clubs',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.grey,
                    ),
              ),
              const SizedBox(height: 24),
              
              // Admin: Create event button
              if (isAdmin) ...[
                SizedBox(
                  width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final currentUser = _authService.getCurrentUser();
                    if (currentUser != null) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => AdminAddEventPage(
                            adminId: currentUser.id,
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Create New Event'),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Search bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search events...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchEvents('');
                        },
                      )
                    : null,
              ),
              onChanged: _searchEvents,
            ),
            const SizedBox(height: 24),

            // Events section
            Text(
              'Upcoming Events',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_filteredEvents.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.event_note,
                        size: 64,
                        color: AppColors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No events found',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.grey,
                            ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredEvents.length,
                itemBuilder: (context, index) {
                  final event = _filteredEvents[index];
                  return EventCard(
                    title: event.title,
                    clubName: 'Event',
                    startDate: event.eventDate,
                    imageUrl: event.imageUrl ?? 'https://via.placeholder.com/300x200?text=${event.title}',
                    isRegistered: _registeredEvents[event.id] ?? false,
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
            ],
          ),
        ),
      ),
    ),
    );
  }
}