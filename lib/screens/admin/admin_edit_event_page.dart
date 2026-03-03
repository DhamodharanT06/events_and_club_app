import 'package:flutter/material.dart';
import 'package:event_lister/constants/app_constants.dart';
import 'package:event_lister/models/event_model.dart';
import 'package:event_lister/models/club_model.dart';
import 'package:event_lister/services/event_service.dart';
import 'package:event_lister/services/club_service.dart';

class AdminEditEventPage extends StatefulWidget {
  final Event event;

  const AdminEditEventPage({
    Key? key,
    required this.event,
  }) : super(key: key);

  @override
  State<AdminEditEventPage> createState() => _AdminEditEventPageState();
}

class _AdminEditEventPageState extends State<AdminEditEventPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _capacityController;
  late TextEditingController _formLinkController;
  late TextEditingController _imageUrlController;

  DateTime? _eventDate;
  bool _isLoading = false;
  String? _feedbackMessage;
  bool _isFeedbackSuccess = false;

  // Club picker
  List<Club> _clubs = [];
  Club? _selectedClub;
  bool _loadingClubs = true;

  final EventService _eventService = EventService.instance;
  final ClubService _clubService = ClubService.instance;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    _titleController = TextEditingController(text: event.title);
    _descriptionController = TextEditingController(text: event.description);
    _locationController = TextEditingController(text: event.location);
    _capacityController = TextEditingController(text: event.capacity.toString());
    _formLinkController = TextEditingController(text: event.googleFormLink ?? '');
    _imageUrlController = TextEditingController(text: event.imageUrl ?? '');
    _eventDate = event.eventDate;
    _loadClubs();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _capacityController.dispose();
    _formLinkController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadClubs() async {
    try {
      final clubs = await _clubService.getClubs();
      if (mounted) {
        setState(() {
          _clubs = clubs;
          // Pre-select the event's current club
          if (widget.event.clubId != null) {
            try {
              _selectedClub = clubs.firstWhere((c) => c.id == widget.event.clubId);
            } catch (_) {
              _selectedClub = clubs.isNotEmpty ? clubs.first : null;
            }
          } else {
            _selectedClub = clubs.isNotEmpty ? clubs.first : null;
          }
          _loadingClubs = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingClubs = false);
    }
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _eventDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_eventDate ?? DateTime.now()),
      );
      if (pickedTime != null && mounted) {
        setState(() {
          _eventDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _updateEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _feedbackMessage = null;
    });

    try {
      final capacity = int.tryParse(_capacityController.text);
      final imageUrl = _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim();
      final formLink = _formLinkController.text.trim().isEmpty ? null : _formLinkController.text.trim();

      await _eventService.updateEvent(
        widget.event.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        eventDate: _eventDate,
        imageUrl: imageUrl,
        googleFormLink: formLink,
        capacity: capacity,
      );

      _showFeedback('✅ Event updated successfully!', true);

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.of(context).pop(true);
      });
    } catch (e) {
      print('❌ Error updating event: $e');
      _showFeedback('❌ Error: $e', false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        title: const Text('Edit Event'),
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
                    color: _isFeedbackSuccess ? Colors.green.shade50 : Colors.red.shade50,
                    border: Border.all(color: _isFeedbackSuccess ? Colors.green : Colors.red),
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
                            color: _isFeedbackSuccess ? Colors.green.shade800 : Colors.red.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Club Selector
              if (_loadingClubs)
                const Center(child: CircularProgressIndicator())
              else if (_clubs.isNotEmpty)
                DropdownButtonFormField<Club>(
                  value: _selectedClub,
                  decoration: InputDecoration(
                    labelText: 'Club',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.group, color: AppColors.primary),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                  items: _clubs.map((club) => DropdownMenuItem<Club>(
                    value: club,
                    child: Text(club.name, overflow: TextOverflow.ellipsis),
                  )).toList(),
                  onChanged: (club) => setState(() => _selectedClub = club),
                ),
              const SizedBox(height: 16),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Event Title *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.event, color: AppColors.primary),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.description, color: AppColors.primary),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                maxLines: 3,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Description is required' : null,
              ),
              const SizedBox(height: 16),

              // Location
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Location *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.location_on, color: AppColors.primary),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Location is required' : null,
              ),
              const SizedBox(height: 16),

              // Date & Time
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Padding(
                  padding: EdgeInsets.only(left: 10),
                  child: Icon(Icons.calendar_today, color: AppColors.primary),
                ),
                title: Text(
                  _eventDate == null
                      ? 'Select Event Date & Time'
                      : 'Date: ${_eventDate!.day}/${_eventDate!.month}/${_eventDate!.year}  ${_eventDate!.hour.toString().padLeft(2, '0')}:${_eventDate!.minute.toString().padLeft(2, '0')}',
                ),
                onTap: () => _selectDateTime(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),

              // Capacity
              TextFormField(
                controller: _capacityController,
                decoration: InputDecoration(
                  labelText: 'Max Capacity *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.people, color: AppColors.primary),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Capacity is required';
                  if (int.tryParse(value) == null) return 'Please enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Image URL
              TextFormField(
                controller: _imageUrlController,
                decoration: InputDecoration(
                  labelText: 'Event Image URL (optional)',
                  hintText: 'https://example.com/event.jpg',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.image, color: AppColors.primary),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),

              // Form Link
              TextFormField(
                controller: _formLinkController,
                decoration: InputDecoration(
                  labelText: 'Google Form Link (optional)',
                  hintText: 'https://forms.gle/...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.link, color: AppColors.primary),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 24),

              // Update Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateEvent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                          'Update Event',
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
