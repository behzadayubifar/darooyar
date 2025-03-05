class User {
  final String id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final DateTime createdAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Properly decode Persian/UTF-8 strings
    String decodeString(dynamic value) {
      if (value == null) return '';
      try {
        // Ensure proper handling of UTF-8 strings
        final str = value.toString();
        return str;
      } catch (_) {
        return '';
      }
    }

    return User(
      id: json['id'].toString(),
      username: decodeString(json['username']),
      email: decodeString(json['email']),
      firstName: decodeString(json['first_name']),
      lastName: decodeString(json['last_name']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Add a helper method to get the full name in Persian
  String get fullName => '$firstName $lastName';
}
