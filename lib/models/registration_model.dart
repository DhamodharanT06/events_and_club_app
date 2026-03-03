// Registration status enum
enum RegistrationStatus {
  registered,
  cancelled,
  attended;

  String get value {
    switch (this) {
      case RegistrationStatus.registered:
        return 'registered';
      case RegistrationStatus.cancelled:
        return 'cancelled';
      case RegistrationStatus.attended:
        return 'attended';
    }
  }

  static RegistrationStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'registered':
        return RegistrationStatus.registered;
      case 'cancelled':
        return RegistrationStatus.cancelled;
      case 'attended':
        return RegistrationStatus.attended;
      default:
        return RegistrationStatus.registered;
    }
  }
}

class Registration {
  final String id;
  final String userId;
  final String eventId;
  final DateTime registrationDate;
  final RegistrationStatus status;
  final bool googleFormSubmitted;
  final DateTime? submissionTime;
  final bool isActive;

  Registration({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.registrationDate,
    required this.status,
    required this.googleFormSubmitted,
    this.submissionTime,
    this.isActive = true,
  });

  factory Registration.fromJson(Map<String, dynamic> json) {
    /// Helper to get value from either camelCase or snake_case key
    dynamic _getField(String camelCase, String snakeCase) {
      return json[camelCase] ?? json[snakeCase];
    }

    final statusStr = _getField('status', 'status') as String? ?? 'registered';
    final submissionTimeStr = _getField('submissionTime', 'submission_time') as String?;

    return Registration(
      id: _getField('id', 'id') as String,
      userId: _getField('userId', 'user_id') as String,
      eventId: _getField('eventId', 'event_id') as String,
      registrationDate: DateTime.parse(_getField('registrationDate', 'registration_date') as String),
      status: RegistrationStatus.fromString(statusStr),
      googleFormSubmitted: (_getField('googleFormSubmitted', 'google_form_submitted') as bool?) ?? false,
      submissionTime: submissionTimeStr != null ? DateTime.parse(submissionTimeStr) : null,
      isActive: (_getField('isActive', 'is_active') as bool?) ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'event_id': eventId,
        'registration_date': registrationDate.toIso8601String(),
        'status': status.value,
        'google_form_submitted': googleFormSubmitted,
        'submission_time': submissionTime?.toIso8601String(),
        'is_active': isActive,
      };

  Registration copyWith({
    String? id,
    String? userId,
    String? eventId,
    DateTime? registrationDate,
    RegistrationStatus? status,
    bool? googleFormSubmitted,
    DateTime? submissionTime,
    bool? isActive,
  }) {
    return Registration(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      eventId: eventId ?? this.eventId,
      registrationDate: registrationDate ?? this.registrationDate,
      status: status ?? this.status,
      googleFormSubmitted: googleFormSubmitted ?? this.googleFormSubmitted,
      submissionTime: submissionTime ?? this.submissionTime,
      isActive: isActive ?? this.isActive,
    );
  }
}
