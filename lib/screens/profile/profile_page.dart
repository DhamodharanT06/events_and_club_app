import 'package:flutter/material.dart';
import 'package:event_lister/constants/app_constants.dart';
import 'package:event_lister/models/user_model.dart';
import 'package:event_lister/services/auth_service.dart';
import 'package:event_lister/screens/auth/login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late AuthService _authService;
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;
  late TextEditingController _profileImageController;
  bool _isSaving = false;
  User? _dbUser;
  bool _loadingUser = true;

  @override
  void initState() {
    super.initState();
    _authService = AuthService.instance;
    final user = _authService.getCurrentUser();
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
    _profileImageController = TextEditingController(text: user?.profileImage ?? '');
    _loadUserFromDatabase();
  }

  Future<void> _loadUserFromDatabase() async {
    try {
      final user = await _authService.getCurrentUserFromDatabase();
      if (mounted) {
        setState(() {
          _dbUser = user;
          _loadingUser = false;
          if (user != null) {
            _nameController.text = user.name;
            _phoneController.text = user.phone;
            _bioController.text = user.bio ?? '';
            _profileImageController.text = user.profileImage ?? '';
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingUser = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _profileImageController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name is required')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = _dbUser ?? _authService.getCurrentUser();
      if (user == null) return;

      final imageUrl = _profileImageController.text.trim().isEmpty
          ? null
          : _profileImageController.text.trim();

      await _authService.updateUserProfile(
        userId: user.id,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        bio: _bioController.text.trim(),
        profileImage: imageUrl,
      );

      // Reload fresh user
      await _loadUserFromDatabase();

      setState(() {
        _isEditing = false;
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
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
    final user = _dbUser ?? _authService.getCurrentUser();
    if (user == null) {
      return const Scaffold(body: Center(child: Text('No user found')));
    }

    final isAdmin = user.role == UserRole.admin;
    final hasProfileImage = user.profileImage != null && user.profileImage!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
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
        onRefresh: _loadUserFromDatabase,
        child: SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: _loadingUser
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile header
                Center(
                  child: Column(
                    children: [
                      // Profile image or letter avatar
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                          border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 3),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: hasProfileImage
                            ? Image.network(
                                user.profileImage!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _buildLetterAvatar(user),
                              )
                            : _buildLetterAvatar(user),
                      ),
                      const SizedBox(height: 16),
                      if (!_isEditing) ...[
                        Text(
                          user.name,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        // Role badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: isAdmin
                                ? AppColors.error.withOpacity(0.15)
                                : AppColors.secondary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
                          ),
                          child: Text(
                            isAdmin ? 'Admin' : 'User',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: isAdmin ? AppColors.error : AppColors.secondary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Points badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.primaryDark],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                '${user.points} Points',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Edit/Save button
                if (!_isEditing)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () => setState(() => _isEditing = true),
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Profile'),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _saveProfile,
                          icon: const Icon(Icons.save),
                          label: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Save Changes'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _isEditing = false;
                              _nameController.text = user.name;
                              _phoneController.text = user.phone;
                              _bioController.text = user.bio ?? '';
                              _profileImageController.text = user.profileImage ?? '';
                            });
                          },
                          child: const Text('Cancel'),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 24),

                // Personal information
                Text(
                  'Personal Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                _InfoField(label: 'Email', value: user.email, editable: false),
                const SizedBox(height: 16),

                if (!_isEditing)
                  _InfoField(label: 'Full Name', value: user.name, editable: false)
                else ...[
                  Text('Full Name', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Enter full name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                if (!_isEditing)
                  _InfoField(label: 'Phone', value: user.phone, editable: false)
                else ...[
                  Text('Phone', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      hintText: 'Enter phone number',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                if (!_isEditing)
                  _InfoField(label: 'Bio', value: user.bio ?? 'No bio added', editable: false)
                else ...[
                  Text('Bio', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _bioController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Tell us about yourself',
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Profile image URL (only in edit mode)
                if (_isEditing) ...[
                  Text('Profile Image URL', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _profileImageController,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      hintText: 'https://example.com/photo.jpg',
                      prefixIcon: Icon(Icons.image_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Account Information
                Text(
                  'Account Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                _InfoField(label: 'Role', value: isAdmin ? 'Administrator' : 'User', editable: false),
                const SizedBox(height: 16),

                _InfoField(
                  label: 'Member Since',
                  value: '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}',
                  editable: false,
                ),
                const SizedBox(height: 16),

                // Points display (always visible)
                _InfoField(
                  label: 'Total Points',
                  value: '${user.points} pts  (Register event: +10 pts • Join club: +20 pts)',
                  editable: false,
                ),
              ],
            ),
    )));
  }

  Widget _buildLetterAvatar(User user) {
    return Center(
      child: Text(
        user.name.isNotEmpty ? user.name.substring(0, 1).toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _InfoField extends StatelessWidget {
  final String label;
  final String value;
  final bool editable;

  const _InfoField({
    required this.label,
    required this.value,
    required this.editable,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.grey),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: editable ? AppColors.surface : AppColors.lightGrey,
            border: Border.all(color: AppColors.lightGrey),
            borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
          ),
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
