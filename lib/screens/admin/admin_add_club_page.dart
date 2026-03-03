import 'package:flutter/material.dart';
import 'package:event_lister/constants/app_constants.dart';
import 'package:event_lister/services/auth_service.dart';
import 'package:event_lister/services/club_service.dart';

class AdminAddClubPage extends StatefulWidget {
  final String? adminId;
  
  const AdminAddClubPage({
    Key? key,
    this.adminId,
  }) : super(key: key);

  @override
  State<AdminAddClubPage> createState() => _AdminAddClubPageState();
}

class _AdminAddClubPageState extends State<AdminAddClubPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _formLinkController = TextEditingController();

  bool _isLoading = false;
  String? _feedbackMessage;
  bool _isFeedbackSuccess = false;

  final ClubService _clubService = ClubService.instance;
  final AuthService _authService = AuthService.instance;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _formLinkController.dispose();
    super.dispose();
  }

  Future<void> _createClub() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _feedbackMessage = null;
    });

    try {
      // Resolve the creator's real UUID
      final creatorId = widget.adminId ?? _authService.getCurrentUser()?.id;
      if (creatorId == null) {
        _showFeedback('❌ Could not determine current user. Please log in again.', false);
        setState(() => _isLoading = false);
        return;
      }

      final imageUrl = _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim();
      final formLink = _formLinkController.text.trim().isEmpty ? null : _formLinkController.text.trim();

      final newClub = await _clubService.createClub(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        createdBy: creatorId,
        imageUrl: imageUrl,
        formLink: formLink,
      );
      print('✅ Club created: ${newClub.id}');

      _showFeedback('✅ Club created successfully!', true);

      // Clear form
      _nameController.clear();
      _descriptionController.clear();
      _imageUrlController.clear();
      _formLinkController.clear();

      // Go back after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      });
    } catch (e) {
      print('❌ Error creating club: $e');
      _showFeedback('❌ Error: $e', false);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showFeedback(String message, bool isSuccess) {
    setState(() {
      _feedbackMessage = message;
      _isFeedbackSuccess = isSuccess;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Club'),
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Feedback Message
              if (_feedbackMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isFeedbackSuccess
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    border: Border.all(
                      color: _isFeedbackSuccess ? Colors.green : Colors.red,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isFeedbackSuccess ? Icons.check_circle : Icons.error,
                        color: _isFeedbackSuccess ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _feedbackMessage!,
                          style: TextStyle(
                            color: _isFeedbackSuccess
                                ? Colors.green.shade800
                                : Colors.red.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Club Name Field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Club Name *',
                  hintText: 'e.g., Tech Club',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.groups, color: AppColors.primary),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Club name is required';
                  if (value.length < 3) return 'Club name must be at least 3 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description Field
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description *',
                  hintText: 'What is this club about?',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.description, color: AppColors.primary),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Description is required';
                  if (value.length < 10) return 'Description must be at least 10 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Image URL Field
              TextFormField(
                controller: _imageUrlController,
                decoration: InputDecoration(
                  labelText: 'Club Image URL (optional)',
                  hintText: 'https://example.com/image.jpg',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.image, color: AppColors.primary),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),

              // Form Link Field
              TextFormField(
                controller: _formLinkController,
                decoration: InputDecoration(
                  labelText: 'Registration Form Link (optional)',
                  hintText: 'https://forms.google.com/...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.link, color: AppColors.primary),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 24),

              // Create Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createClub,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Create Club',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
