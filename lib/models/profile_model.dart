class ProfileModel {
  final String id;
  final String name;
  final String email;
  final String role; // 'user' atau 'owner'
  final String? avatarUrl;
  final DateTime? createdAt;

  const ProfileModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl,
    this.createdAt,
  });

  bool get isOwner => role == 'owner';

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String? ?? 'user',
      avatarUrl: json['avatar_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'avatar_url': avatarUrl,
    };
  }

  ProfileModel copyWith({
    String? name,
    String? role,
    String? avatarUrl,
  }) {
    return ProfileModel(
      id: id,
      name: name ?? this.name,
      email: email,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt,
    );
  }
}
