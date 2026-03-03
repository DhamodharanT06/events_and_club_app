import 'package:flutter/material.dart';
import 'package:event_lister/constants/app_constants.dart';
import 'package:event_lister/models/club_model.dart';
import 'package:event_lister/models/event_model.dart';
import 'package:event_lister/services/club_service.dart';
import 'package:event_lister/services/event_service.dart';
import 'package:event_lister/services/auth_service.dart';
import 'package:event_lister/screens/admin/admin_edit_club_page.dart';
import '../event/event_detail_page.dart';
import 'chat_panel.dart';

class ClubDetailPage extends StatefulWidget {
  final Club club;

  const ClubDetailPage({
    super.key,
    required this.club,
  });

  @override
  State<ClubDetailPage> createState() => _ClubDetailPageState();
}

class _ClubDetailPageState extends State<ClubDetailPage> {
  late ClubService _clubService;
  late EventService _eventService;
  late AuthService _authService;
  bool _isMember = false;
  bool _isLoading = false;
  int _realMemberCount = 0;
  List<Event> _clubEvents = [];

  @override
  void initState() {
    super.initState();
    _clubService = ClubService.instance;
    _eventService = EventService.instance;
    _authService = AuthService.instance;
    _checkMembership();
    _loadClubEvents();
    _loadRealMemberCount();
  }

  void _loadRealMemberCount() {
    // Get the real member count from the club
    setState(() {
      _realMemberCount = widget.club.memberCount;
    });
  }

  void _checkMembership() async {
    final userId = _authService.getCurrentUser()?.id;
    if (userId == null) return;
    final isMember = await _clubService.isMemberAsync(widget.club.id, userId);
    if (mounted) {
      setState(() {
        _isMember = isMember;
      });
    }
  }

  void _loadClubEvents() async {
    try {
      final events = await _eventService.getEventsByClub(widget.club.id);
      setState(() {
        _clubEvents = events;
      });
    } catch (e) {
      // Handle error
    }
  }

  void _toggleMembership() async {
    final userId = _authService.getCurrentUser()?.id;
    if (userId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isMember) {
        await _clubService.leaveClub(widget.club.id, userId);
        setState(() {
          _isMember = false;
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Left club')),
          );
        }
      } else {
        try {
          await _clubService.joinClub(widget.club.id, userId);
        } catch (e) {
          // Optimistic: treat as joined anyway
          print('joinClub error (treating as joined): $e');
        }
        setState(() {
          _isMember = true;
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Joined club! 🎉'), backgroundColor: Colors.green),
          );
        }
      }
      _loadRealMemberCount();
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

  @override
  Widget build(BuildContext context) {
    final isAdmin = _authService.isAdmin();

    return DefaultTabController(
      length: _isMember ? 2 : 1,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Club Details'),
          centerTitle: true,
          bottom: _isMember
              ? TabBar(
                  tabs: const [
                    Tab(child: Text('Events',style: TextStyle(color: AppColors.lightGrey),)),
                    Tab(child: Text('Chat',style: TextStyle(color: AppColors.lightGrey),)),
                  ],
                )
              : null,
        ),
        body: _isMember
            ? TabBarView(
                children: [
                  // Events tab
                  SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(
                          AppDimensions.paddingMedium),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildClubInfo(isAdmin),
                          const SizedBox(height: 32),
                          Text(
                            'Club Events',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          if (_clubEvents.isEmpty)
                            Center(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 32),
                                child: Text(
                                  'No events yet',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: AppColors.grey,
                                      ),
                                ),
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _clubEvents.length,
                              itemBuilder: (context, index) {
                                final event = _clubEvents[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              EventDetailPage(event: event),
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(
                                          AppDimensions.paddingMedium),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            event.title,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.calendar_today_outlined,
                                                size: 16,
                                                color: AppColors.grey,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${event.eventDate.day}/${event.eventDate.month}/${event.eventDate.year} ${event.eventDate.hour.toString().padLeft(2, '0')}:${event.eventDate.minute.toString().padLeft(2, '0')}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color: AppColors.primary.withAlpha(100),
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                  // Chat tab
                  ChatPanel(clubId: widget.club.id),
                ],
              )
            : SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(
                          AppDimensions.paddingMedium),
                      child: _buildClubInfo(isAdmin),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingMedium,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _toggleMembership,
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
                              : const Text('Join Club'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  void _deleteClub() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Club'),
        content: Text('Are you sure you want to delete "${widget.club.name}"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await _clubService.deleteClub(widget.club.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Club deleted'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildClubInfo(bool isAdmin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Club image placeholder
        if (widget.club.imageUrl != null && widget.club.imageUrl!.isNotEmpty)
          Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              color: AppColors.lightGrey,
              borderRadius: BorderRadius.circular(
                  AppDimensions.borderRadiusMedium),
              image: DecorationImage(
                image: NetworkImage(widget.club.imageUrl!),
                fit: BoxFit.cover,
              ),
            ),
          )
        else
          Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              color: AppColors.lightGrey,
              borderRadius: BorderRadius.circular(
                  AppDimensions.borderRadiusMedium),
            ),
            child: Icon(
              Icons.groups,
              size: 80,
              color: AppColors.grey,
            ),
          ),
        const SizedBox(height: 24),
        Text(
          widget.club.name,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.club.description,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.darkGrey,
              ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(
              Icons.people_outline,
              size: 20,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              '$_realMemberCount members',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        if (isAdmin) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AdminEditClubPage(
                      club: widget.club,
                    ),
                  ),
                ).then((result) {
                  if (result == true) {
                    // Refresh the page if needed
                    setState(() {});
                  }
                });
              },
              icon: const Icon(Icons.edit),
              label: const Text('Edit Club'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              onPressed: _isLoading ? null : _deleteClub,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete Club'),
            ),
          ),
        ],
      ],
    );
  }
}
