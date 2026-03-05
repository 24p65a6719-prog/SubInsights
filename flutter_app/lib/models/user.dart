class User {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  bool isVerified;
  String? token;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.isVerified = false,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String? ?? json['user_id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String? ?? '',
      phone: json['phone'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      token: json['token'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'phone': phone,
        'is_verified': isVerified,
      };
}
