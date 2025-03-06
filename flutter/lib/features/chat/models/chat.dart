import 'message.dart';

class Chat {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Message> messages;
  final int? folderId;

  Chat({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
    this.folderId,
  });

  // Add helper method to get the ID as an integer
  int get idAsInt {
    try {
      return int.parse(id);
    } catch (e) {
      // Return a fallback value if the ID is not a valid integer
      return 1; // Default to chat ID 1 if parsing fails
    }
  }

  factory Chat.fromJson(Map<String, dynamic> json) {
    List<Message> messagesList = [];
    if (json.containsKey('messages') && json['messages'] != null) {
      messagesList = (json['messages'] as List)
          .map((message) => Message.fromJson(message))
          .toList();
    }

    // Safely convert ID to string regardless of whether it's int or String in the JSON
    String idString = json['id'].toString();

    return Chat(
      id: idString,
      title: json['title'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      messages: messagesList,
      folderId: json['folder_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'messages': messages.map((message) => message.toJson()).toList(),
      'folder_id': folderId,
    };
  }

  Chat copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Message>? messages,
    int? folderId,
  }) {
    return Chat(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
      folderId: folderId ?? this.folderId,
    );
  }
}
