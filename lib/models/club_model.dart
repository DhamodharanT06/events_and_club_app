class Club {
  final String id;
  final String name;
  final String description;
  final String? imageUrl;
  final String? formLink;
  final String createdBy; // UUID of user who created the club
  final int memberCount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  Club({
    required this.id,
    required this.name,
    required this.description,
    this.imageUrl,
    this.formLink,
    required this.createdBy,
    required this.memberCount,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  factory Club.fromJson(Map<String, dynamic> json) {
    /// Helper to get value from either camelCase or snake_case key
    dynamic _getField(String camelCase, String snakeCase) {
      return json[camelCase] ?? json[snakeCase];
    }

    return Club(
      id: _getField('id', 'id') as String,
      name: _getField('name', 'name') as String,
      description: _getField('description', 'description') as String,
      imageUrl: _getField('imageUrl', 'image_url') as String?,
      formLink: _getField('formLink', 'form_link') as String?,
      createdBy: _getField('createdBy', 'created_by') as String,
      memberCount: _getField('memberCount', 'member_count') as int? ?? 0,
      createdAt: DateTime.parse(_getField('createdAt', 'created_at') as String),
      updatedAt: _getField('updatedAt', 'updated_at') != null
          ? DateTime.parse(_getField('updatedAt', 'updated_at') as String)
          : null,
      isActive: (_getField('isActive', 'is_active') as bool?) ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'image_url': imageUrl,
        'form_link': formLink,
        'created_by': createdBy,
        'member_count': memberCount,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'is_active': isActive,
      };

  Club copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    String? formLink,
    String? createdBy,
    int? memberCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Club(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      formLink: formLink ?? this.formLink,
      createdBy: createdBy ?? this.createdBy,
      memberCount: memberCount ?? this.memberCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
