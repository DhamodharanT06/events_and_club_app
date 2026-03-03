import 'package:flutter/material.dart';
import 'package:event_lister/constants/app_constants.dart';
import 'package:event_lister/models/event_model.dart';
import 'package:event_lister/services/event_service.dart';
import 'package:event_lister/services/registration_service.dart';
import 'package:event_lister/services/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';

class EventDetailPage extends StatefulWidget {
  final Event event;

  const EventDetailPage({
    super.key,
    required this.event,
  });

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  late EventService _eventService;
  late RegistrationService _registrationService;
  late AuthService _authService;
  bool _isRegistered = false;
  bool _isLoading = false;
  int _realRegistrationCount = 0;

  @override
  void initState() {
    super.initState();
    _eventService = EventService.instance;
    _registrationService = RegistrationService.instance;
    _authService = AuthService.instance;
    _checkRegistration();
    _loadRealRegistrationCount();
  }

  void _loadRealRegistrationCount() async {
    try {
      final count = await _registrationService.getEventRegistrationsCount(widget.event.id);
      if (mounted) {
        setState(() {
          _realRegistrationCount = count;
        });
      }
    } catch (e) {
      print('Error loading registration count: $e');
      // Fall back to the static count if there's an error
      if (mounted) {
        setState(() {
          _realRegistrationCount = widget.event.registrationCount;
        });
      }
    }
  }

  void _checkRegistration() async {
    final userId = _authService.getCurrentUser()?.id;
    if (userId != null) {
      final registered = await _registrationService.isUserRegistered(
        userId,
        widget.event.id,
      );
      setState(() {
        _isRegistered = registered;
      });
    }
  }

  void _toggleRegistration() async {
    final userId = _authService.getCurrentUser()?.id;
    if (userId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isRegistered) {
        // Unregister
        await _registrationService.unregisterFromEvent(userId, widget.event.id);
        await _eventService.updateRegistrationCount(widget.event.id, -1);
      } else {
        // Register
        if (widget.event.googleFormLink != null && widget.event.googleFormLink!.isNotEmpty) {
          // Show dialog asking to open form
          _showRegistrationDialog(userId);
        } else {
          // Direct registration
          if (widget.event.clubId != null) {
            await _registrationService.registerForEvent(
              userId: userId,
              eventId: widget.event.id,
              clubId: widget.event.clubId!,
            );
          }
          await _eventService.updateRegistrationCount(widget.event.id, 1);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Successfully registered!')),
            );
          }
        }
      }

      setState(() {
        _isRegistered = !_isRegistered;
        _isLoading = false;
      });
      
      // Reload the real registration count
      _loadRealRegistrationCount();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void _showRegistrationDialog(String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registration'),
        content: const Text(
          'This event requires Google Form registration. A form link is provided.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // Open the form
              if (await canLaunchUrl(Uri.parse(widget.event.googleFormLink!))) {
                await launchUrl(Uri.parse(widget.event.googleFormLink!));
                
                // After user submits form, ask for confirmation
                if (mounted) {
                  _showFormSubmitDialog(userId);
                }
              }
            },
            child: const Text('Open Form'),
          ),
        ],
      ),
    );
  }

  void _showFormSubmitDialog(String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Registration'),
        content: const Text('Did you submit the form?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isLoading = false;
              });
            },
            child: const Text('Not Yet'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _registrationService.registerForEvent(
                  userId: userId,
                  eventId: widget.event.id,
                  clubId: widget.event.clubId ?? '',
                );
                await _eventService.updateRegistrationCount(widget.event.id, 1);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Registration confirmed!')),
                  );
                  setState(() {
                    _isRegistered = true;
                    _isLoading = false;
                  });
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                  setState(() {
                    _isLoading = false;
                  });
                }
              }
            },
            child: const Text('Yes, Confirm'),
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
        title: const Text('Event Details'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event image placeholder
            if (widget.event.imageUrl != null && widget.event.imageUrl!.isNotEmpty)
              Image.network(
                widget.event.imageUrl!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              )
            else
              Container(
                width: double.infinity,
                height: 200,
                color: AppColors.lightGrey,
                child: Icon(
                  Icons.event,
                  size: 80,
                  color: AppColors.grey,
                ),
              ),
            // Container(
            //   width: double.infinity,
            //   height: 200,
            //   color: AppColors.lightGrey,
            //   child: Icon(
            //     Icons.event,
            //     size: 80,
            //     color: AppColors.grey,
            //   ),
            // ),
            Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event title and registration count
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.event.title,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(
                              AppDimensions.borderRadiusSmall),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _realRegistrationCount.toString(),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              'Registered',
                              style:
                                  Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppColors.grey,
                                      ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Location and Date
                  _InfoRow(
                    icon: Icons.location_on_outlined,
                    label: 'Location',
                    value: widget.event.location,
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Date',
                    value:
                        '${widget.event.eventDate.day}/${widget.event.eventDate.month}/${widget.event.eventDate.year}',
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.access_time_outlined,
                    label: 'Time',
                    value:
                        '${widget.event.eventDate.hour.toString().padLeft(2, '0')}:${widget.event.eventDate.minute.toString().padLeft(2, '0')}',
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.people_outline,
                    label: 'Capacity',
                    value:
                        '$_realRegistrationCount/${widget.event.capacity}'
                  ),
                  const SizedBox(height: 24),

                  // Description
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.event.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.darkGrey,
                        ),
                  ),
                  const SizedBox(height: 24),

                  // Registration button
                  if (!isAdmin)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _toggleRegistration,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isRegistered
                              ? AppColors.error
                              : AppColors.primary,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _isRegistered
                                    ? 'Unregister from Event'
                                    : 'Register for Event',
                              ),
                      ),
                    ),

                  // Admin edit button
                  if (isAdmin)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Edit event coming soon'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit Event'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.primary,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.grey,
                  ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}
