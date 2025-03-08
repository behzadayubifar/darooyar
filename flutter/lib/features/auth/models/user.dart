import 'dart:convert';

class User {
  final String id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final double credit;
  final DateTime createdAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.credit,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Properly decode Persian/UTF-8 strings
    String decodeString(dynamic value) {
      if (value == null) return '';
      try {
        // Make sure we're handling UTF-8 strings properly
        final str = value.toString();

        // Check if the string seems to be improperly encoded (contains placeholder chars)
        if (str.contains('Ø') || str.contains('Ù') || str.contains('§')) {
          // Try to decode from UTF-8 bytes if needed
          try {
            // This is a fallback that attempts to re-encode potentially garbled text
            final bytes = utf8.encode(str);
            final decodedStr = utf8.decode(bytes, allowMalformed: true);
            return decodedStr;
          } catch (_) {
            // If all decoding attempts fail, return the original string
            return str;
          }
        }

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
      credit: json['credit'] != null
          ? double.parse(json['credit'].toString())
          : 0.0,
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
      'credit': credit,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Add a helper method to get the full name in Persian
  String get fullName => '$firstName $lastName';
}
