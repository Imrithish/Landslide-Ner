/// User and Auth Response Model matching FastAPI /auth/me & /auth/login
class User {
  final int id;
  final String email;
  final String fullName;
  final String? phoneNumber;
  final String role;
  final String? state;
  final String? district;
  final String createdAt;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    required this.role,
    this.state,
    this.district,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      email: json['email']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString(),
      role: json['role']?.toString() ?? 'CITIZEN',
      state: json['state']?.toString(),
      district: json['district']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'role': role,
      'state': state,
      'district': district,
      'created_at': createdAt,
    };
  }

  User copyWith({
    int? id,
    String? email,
    String? fullName,
    String? phoneNumber,
    String? role,
    String? state,
    String? district,
    String? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      state: state ?? this.state,
      district: district ?? this.district,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class AuthTokenResult {
  final String accessToken;
  final String tokenType;
  final User user;

  AuthTokenResult({
    required this.accessToken,
    this.tokenType = 'bearer',
    required this.user,
  });

  factory AuthTokenResult.fromJson(Map<String, dynamic> json) {
    return AuthTokenResult(
      accessToken: json['access_token']?.toString() ?? '',
      tokenType: json['token_type']?.toString() ?? 'bearer',
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
