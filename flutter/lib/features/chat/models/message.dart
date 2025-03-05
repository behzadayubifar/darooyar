class Message {
  final String id;
  final String content;
  final String role;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String contentType; // 'text', 'image', etc.

  Message({
    required this.id,
    required this.content,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
    this.contentType = 'text', // Default to text
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'].toString(),
      content: json['content'] ?? '',
      role: json['role'] ?? 'user',
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      contentType: json['content_type'] ?? 'text',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'role': role,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'content_type': contentType,
    };
  }

  bool get isImage => contentType == 'image';
  bool get isText => contentType == 'text';
}
