import 'package:flutter/material.dart';
import 'package:event_lister/constants/app_constants.dart';
import 'package:event_lister/models/club_model.dart';
import 'package:event_lister/services/club_service.dart';
import 'package:event_lister/services/auth_service.dart';
import 'package:event_lister/widgets/custom_widgets.dart';
import 'package:event_lister/screens/admin/admin_add_club_page.dart';
import 'package:event_lister/screens/auth/login_page.dart';
import 'club_detail_page.dart';

class ClubListPage extends StatefulWidget {
  const ClubListPage({super.key});

  @override
  State<ClubListPage> createState() => _ClubListPageState();
}

class _ClubListPageState extends State<ClubListPage> {
  late TextEditingController _searchController;
  late ClubService _clubService;
  late AuthService _authService;
  List<Club> _allClubs = [];
  List<Club> _filteredClubs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _clubService = ClubService.instance;
    _authService = AuthService.instance;
    _loadClubs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadClubs() async {
    try {
      final clubs = await _clubService.getClubs();
      if (mounted) {
        setState(() {
          _allClubs = clubs;
          _filteredClubs = clubs;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading clubs: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshClubs() async {
    setState(() {
      _isLoading = true;
      _allClubs = [];
      _filteredClubs = [];
    });
    _loadClubs();
  }

  void _searchClubs(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredClubs = _allClubs;
      });
    } else {
      setState(() {
        _filteredClubs = _allClubs
            .where((club) =>
                club.name.toLowerCase().contains(query.toLowerCase()) ||
                club.description.toLowerCase().contains(query.toLowerCase()))
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
        title: const Text('Clubs'),
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
      onRefresh: _refreshClubs,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Clubs',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                if (isAdmin) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const AdminAddClubPage(),
                          ),
                        );
                        if (result == true) {
                          _loadClubs();
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Create New Club'),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search clubs...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _searchClubs('');
                          },
                        )
                      : null,
                ),
                onChanged: _searchClubs,
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredClubs.isEmpty
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
                            'No clubs found',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
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
                      itemCount: _filteredClubs.length,
                      itemBuilder: (context, index) {
                        final club = _filteredClubs[index];
                        return ClubCard(
                          name: club.name,
                          description: club.description,
                          imageUrl: club.imageUrl ?? 'https://via.placeholder.com/300x200?text=${club.name}',
                          memberCount: club.memberCount,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ClubDetailPage(club: club),
                              ),
                            ).then((_) => _loadClubs());
                          },
                        );
                      },
                    ),
        ),
      ]),
    ));
  }
}
