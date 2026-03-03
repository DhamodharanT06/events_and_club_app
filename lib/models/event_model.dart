class Event {
  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime eventDate; // Combines event_date and event_time from DB
  final String? imageUrl;
  final String? clubId;
  final String createdBy; // UUID of user who created the event
  final String? googleFormLink;
  final int capacity;
  final int registrationCount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.eventDate,
    this.imageUrl,
    this.clubId,
    required this.createdBy,
    this.googleFormLink,
    required this.capacity,
    required this.registrationCount,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    /// Helper to get value from either camelCase or snake_case key
    dynamic _getField(String camelCase, String snakeCase) {
      return json[camelCase] ?? json[snakeCase];
    }

    // Parse event_date and event_time from Supabase
    final eventDateStr = _getField('eventDate', 'event_date') as String?;
    final eventTimeStr = _getField('eventTime', 'event_time') as String?;
    
    late DateTime eventDate;
    if (eventDateStr != null && eventTimeStr != null) {
      eventDate = DateTime.parse('${eventDateStr}T${eventTimeStr}');
    } else if (eventDateStr != null) {
      eventDate = DateTime.parse(eventDateStr);
    } else {
      eventDate = DateTime.now();
    }

    return Event(
      id: _getField('id', 'id') as String,
      title: _getField('title', 'title') as String,
      description: _getField('description', 'description') as String,
      location: (_getField('location', 'location') as String?) ?? '',
      eventDate: eventDate,
      imageUrl: _getField('imageUrl', 'image_url') as String?,
      clubId: _getField('clubId', 'club_id') as String?,
      createdBy: _getField('createdBy', 'created_by') as String,
      googleFormLink: _getField('googleFormLink', 'google_form_link') as String?,
      capacity: _getField('capacity', 'capacity') as int? ?? 0,
      registrationCount: (_getField('registrationCount', 'registration_count') as int?) ?? 0,
      createdAt: DateTime.parse(_getField('createdAt', 'created_at') as String),
      updatedAt: _getField('updatedAt', 'updated_at') != null
          ? DateTime.parse(_getField('updatedAt', 'updated_at') as String)
          : null,
      isActive: (_getField('isActive', 'is_active') as bool?) ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'location': location,
        'event_date': '${eventDate.year.toString().padLeft(4, '0')}-${eventDate.month.toString().padLeft(2, '0')}-${eventDate.day.toString().padLeft(2, '0')}',
        'event_time': '${eventDate.hour.toString().padLeft(2, '0')}:${eventDate.minute.toString().padLeft(2, '0')}:${eventDate.second.toString().padLeft(2, '0')}',
        'image_url': imageUrl,
        'club_id': clubId,
        'created_by': createdBy,
        'google_form_link': googleFormLink,
        'capacity': capacity,
        'registration_count': registrationCount,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'is_active': isActive,
      };

  Event copyWith({
    String? id,
    String? title,
    String? description,
    String? location,
    DateTime? eventDate,
    String? imageUrl,
    String? clubId,
    String? createdBy,
    String? googleFormLink,
    int? capacity,
    int? registrationCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      eventDate: eventDate ?? this.eventDate,
      imageUrl: imageUrl ?? this.imageUrl,
      clubId: clubId ?? this.clubId,
      createdBy: createdBy ?? this.createdBy,
      googleFormLink: googleFormLink ?? this.googleFormLink,
      capacity: capacity ?? this.capacity,
      registrationCount: registrationCount ?? this.registrationCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
