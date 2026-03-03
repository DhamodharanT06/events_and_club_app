import 'package:flutter/material.dart';
import 'package:event_lister/constants/app_constants.dart';
import 'package:event_lister/models/club_model.dart';
import 'package:event_lister/services/club_service.dart';
import 'package:event_lister/services/event_service.dart';

class AdminAddEventPage extends StatefulWidget {
  /// Pre-selected club ID. If null, admin must pick a club from the dropdown.
  final String? clubId;
  final String adminId;

  const AdminAddEventPage({
    Key? key,
    this.clubId,
    required this.adminId,
  }) : super(key: key);

  @override
  State<AdminAddEventPage> createState() => _AdminAddEventPageState();
}

class _AdminAddEventPageState extends State<AdminAddEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _capacityController = TextEditingController();
  final _formLinkController = TextEditingController();
  final _imageUrlController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;
  String? _feedbackMessage;
  bool _isFeedbackSuccess = false;

  // Club picker
  List<Club> _clubs = [];
  Club? _selectedClub;
  List<String> _coClubIds = [];  // for collab events
  bool _loadingClubs = true;

  final EventService _eventService = EventService.instance;
  final ClubService _clubService = ClubService.instance;

  @override
  void initState() {
    super.initState();
    _loadClubs();
  }

  Future<void> _loadClubs() async {
    final clubs = await _clubService.getClubs();
    if (mounted) {
      setState(() {
        _clubs = clubs;
        // Pre-select club if clubId was passed
        if (widget.clubId != null) {
          try {
            _selectedClub = clubs.firstWhere((c) => c.id == widget.clubId);
          } catch (_) {
            _selectedClub = clubs.isNotEmpty ? clubs.first : null;
          }
        } else {
          _selectedClub = clubs.isNotEmpty ? clubs.first : null;
        }
        _loadingClubs = false;
      });
    }
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

  Future<void> _selectDateTime(BuildContext context, bool isStartDate) async {
    // First, pick the date
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: isStartDate ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now()),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      // Then, pick the time
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          isStartDate 
            ? (_startDate ?? DateTime.now()) 
            : (_endDate ?? DateTime.now())
        ),
      );

      if (pickedTime != null) {
        final dateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          if (isStartDate) {
            _startDate = dateTime;
          } else {
            _endDate = dateTime;
          }
        });
      }
    }
  }

  Future<void> _createEvent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_startDate == null || _endDate == null) {
      _showFeedback('Please select both start and end date & time', false);
      return;
    }

    if (_endDate!.isBefore(_startDate!)) {
      _showFeedback('End date & time must be after start date & time', false);
      return;
    }

    setState(() {
      _isLoading = true;
      _feedbackMessage = null;
    });

    if (_selectedClub == null) {
      _showFeedback('Please select a club', false);
      setState(() => _isLoading = false);
      return;
    }

    try {
      final capacity = int.parse(_capacityController.text);

      final imageUrl = _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim();

      final newEvent = await _eventService.createEvent(
        title: _titleController.text,
        description: _descriptionController.text,
        location: _locationController.text,
        eventDate: _startDate!,
        clubId: _selectedClub!.id,
        createdBy: widget.adminId,
        capacity: capacity,
        imageUrl: imageUrl,
        googleFormLink: _formLinkController.text.isNotEmpty ? _formLinkController.text : null,
      );
      print('✅ Event created: ${newEvent.id}');

      _showFeedback('✅ Event created successfully!', true);

      // Clear form
      _titleController.clear();
      _descriptionController.clear();
      _locationController.clear();
      _capacityController.clear();
      _formLinkController.clear();
      _imageUrlController.clear();
      setState(() {
        _startDate = null;
        _endDate = null;
        _coClubIds = [];
      });

      // Go back after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      });
    } catch (e) {
      print('❌ Error creating event: $e');
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
        title: const Text('Add New Event'),
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
                      color: _isFeedbackSuccess
                          ? Colors.green
                          : Colors.red,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isFeedbackSuccess
                            ? Icons.check_circle
                            : Icons.error,
                        color: _isFeedbackSuccess
                            ? Colors.green
                            : Colors.red,
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

              // Club Selector
              if (_loadingClubs)
                const Center(child: CircularProgressIndicator())
              else if (_clubs.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    border: Border.all(color: Colors.orange),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No clubs found. Please create a club first.',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                )
              else
                DropdownButtonFormField<Club>(
                  value: _selectedClub,
                  decoration: InputDecoration(
                    labelText: 'Select Club',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.group),
                  ),
                  items: _clubs
                      .map((club) => DropdownMenuItem<Club>(
                            value: club,
                            child: Text(club.name, overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (club) => setState(() => _selectedClub = club),
                  validator: (value) =>
                      value == null ? 'Please select a club' : null,
                ),
              const SizedBox(height: 16),

              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Event Title',
                  hintText: 'e.g., Flutter Workshop',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.event),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description Field
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Event details and information',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.description),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Description is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Location Field
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Location',
                  hintText: 'e.g., Auditorium A',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Location is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Start Date & Time Picker
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _startDate == null
                      ? 'Select Start Date & Time'
                      : 'Start: ${_startDate!.toString().replaceFirst('.000', '')}',
                ),
                leading: Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: const Icon(Icons.calendar_today),
                ),
                onTap: () => _selectDateTime(context, true),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),

              // End Date & Time Picker
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _endDate == null
                      ? 'Select End Date & Time'
                      : 'End: ${_endDate!.toString().replaceFirst('.000', '')}',
                ),
                leading: Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: const Icon(Icons.calendar_today),
                ),
                onTap: () => _selectDateTime(context, false),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),

              // Capacity Field
              TextFormField(
                controller: _capacityController,
                decoration: InputDecoration(
                  labelText: 'Max Capacity',
                  hintText: 'e.g., 100',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.people),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Capacity is required';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Google Form Link (Optional)
              TextFormField(
                controller: _formLinkController,
                decoration: InputDecoration(
                  labelText: 'Google Form Link (Optional)',
                  hintText: 'https://forms.gle/...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.link),
                ),
              ),
              const SizedBox(height: 16),

              // Event Image URL (Optional)
              TextFormField(
                controller: _imageUrlController,
                decoration: InputDecoration(
                  labelText: 'Event Image URL (Optional)',
                  hintText: 'https://example.com/event.jpg',
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

              // Co-Club Selector (for collab events)
              if (_clubs.length > 1) ...[
                const Text(
                  'Collaborating Clubs (optional)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ..._clubs
                    .where((c) => c.id != _selectedClub?.id)
                    .map((club) => CheckboxListTile(
                          value: _coClubIds.contains(club.id),
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                _coClubIds.add(club.id);
                              } else {
                                _coClubIds.remove(club.id);
                              }
                            });
                          },
                          title: Text(club.name),
                          contentPadding: EdgeInsets.zero,
                          activeColor: AppColors.primary,
                          controlAffinity: ListTileControlAffinity.leading,
                        ))
                    .toList(),
                const SizedBox(height: 8),
              ],

              // Create Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createEvent,
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
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Create Event',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              
            ],
          ),
        ),
      ),
    );
  }
}
