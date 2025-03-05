import 'dart:ui';
import 'package:flutter/material.dart';
import 'chat.dart';

class Folder {
  final int id;
  final String name;
  final String? color;
  final int userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Chat>? chats;
  final int chatCount;

  Folder({
    required this.id,
    required this.name,
    this.color,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.chats,
    required this.chatCount,
  });

  factory Folder.fromJson(Map<String, dynamic> json) {
    List<Chat>? chatsList;
    if (json['chats'] != null) {
      chatsList =
          (json['chats'] as List).map((chat) => Chat.fromJson(chat)).toList();
    }

    return Folder(
      id: json['id'],
      name: json['name'],
      color: json['color'],
      userId: json['user_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      chats: chatsList,
      chatCount: json['chat_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'chat_count': chatCount,
    };
  }

  Folder copyWith({
    int? id,
    String? name,
    String? color,
    int? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Chat>? chats,
    int? chatCount,
  }) {
    return Folder(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      chats: chats ?? this.chats,
      chatCount: chatCount ?? this.chatCount,
    );
  }

  // Helper method to convert string color to Color object
  Color? getColor() {
    if (color == null || color!.isEmpty) {
      return null;
    }

    try {
      // Assuming color is stored as a hex string like "#RRGGBB" or "RRGGBB"
      String hexColor = color!;
      if (hexColor.startsWith('#')) {
        hexColor = hexColor.substring(1);
      }

      return Color(int.parse('FF$hexColor', radix: 16));
    } catch (e) {
      return null;
    }
  }
}
