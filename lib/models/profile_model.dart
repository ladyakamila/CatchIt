class ProfileModel {
  final String id;
  final String? fullName;
  final String? phoneNumber;
  final String? avatarUrl;
  final String role;
  final DateTime? createdAt;

  ProfileModel({
    required this.id,
    this.fullName,
    this.phoneNumber,
    this.avatarUrl,
    required this.role,
    this.createdAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      phoneNumber: json['phone_number'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: json['role'] as String? ?? 'user',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'avatar_url': avatarUrl,
      'role': role,
    };
  }
  
}
