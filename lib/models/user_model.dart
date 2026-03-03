import '../constants/app_constants.dart';

class User {
  final String id;
  final String email;
  final String name;
  final String phone;
  final UserRole role;
  final String? profileImage;
  final String? bio;
  final int points;
  final DateTime createdAt;
  final DateTime? updatedAt;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.role,
    this.profileImage,
    this.bio,
    this.points = 0,
    required this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Support both snake_case (Supabase) and camelCase (local) keys
    final roleStr = (json['role'] as String? ?? 'user').toLowerCase();
    final createdAtStr = json['created_at'] as String? ??
        json['createdAt'] as String? ??
        DateTime.now().toIso8601String();
    final updatedAtStr = json['updated_at'] as String? ??
        json['updatedAt'] as String?;
    final profileImage = json['profile_image'] as String? ??
        json['profileImage'] as String?;

    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      phone: (json['phone'] as String?) ?? '',
      role: roleStr == 'admin' ? UserRole.admin : UserRole.user,
      profileImage: profileImage,
      bio: json['bio'] as String?,
      points: (json['points'] as int?) ?? 0,
      createdAt: DateTime.parse(createdAtStr),
      updatedAt: updatedAtStr != null ? DateTime.parse(updatedAtStr) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'phone': phone,
        'role': role.value,
        'profileImage': profileImage,
        'bio': bio,
        'points': points,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    UserRole? role,
    String? profileImage,
    String? bio,
    int? points,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      profileImage: profileImage ?? this.profileImage,
      bio: bio ?? this.bio,
      points: points ?? this.points,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
