import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod/riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/chat.dart';
import '../models/message.dart';

/// A mock implementation of chat service for when the backend server is not available
class MockChatService {
  // In-memory storage
  final Map<int, Chat> _chats = {};
  final Map<int, List<Message>> _messages = {};
  int _nextChatId = 1;
  int _nextMessageId = 1;

  // Constructor with some sample data
  MockChatService() {
    // Create a few sample chats
    final chat1 = Chat(
      id: '1',
      title: 'گفتگو با دکتر محمدی',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      messages: [],
    );

    final chat2 = Chat(
      id: '2',
      title: 'مشاوره داروی آنتی‌بیوتیک',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      updatedAt: DateTime.now().subtract(const Duration(days: 3)),
      messages: [],
    );

    // Add a chat with ID 13 since that's what the app is trying to use
    final chat13 = Chat(
      id: '13',
      title: 'گفتگوی فعلی',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
      messages: [],
    );

    _chats[1] = chat1;
    _chats[2] = chat2;
    _chats[13] = chat13; // Add chat with ID 13
    _nextChatId = 14; // Update next ID

    // Add some sample messages
    _messages[1] = [
      Message(
        id: '1',
        content: 'سلام دکتر، وقت بخیر',
        role: 'user',
        contentType: 'text',
        createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      ),
      Message(
        id: '2',
        content: 'سلام، چطور می‌توانم کمکتان کنم؟',
        role: 'system',
        contentType: 'text',
        createdAt: DateTime.now()
            .subtract(const Duration(days: 1, hours: 1, minutes: 55)),
        updatedAt: DateTime.now()
            .subtract(const Duration(days: 1, hours: 1, minutes: 55)),
      ),
    ];

    _messages[2] = [
      Message(
        id: '3',
        content: 'نیاز به مشاوره در مورد داروی آنتی‌بیوتیک دارم',
        role: 'user',
        contentType: 'text',
        createdAt: DateTime.now().subtract(const Duration(days: 3, hours: 5)),
        updatedAt: DateTime.now().subtract(const Duration(days: 3, hours: 5)),
      ),
      Message(
        id: '4',
        content: 'بله، لطفاً نام دارو و دوز مصرفی آن را برایم ارسال کنید',
        role: 'system',
        contentType: 'text',
        createdAt: DateTime.now()
            .subtract(const Duration(days: 3, hours: 4, minutes: 45)),
        updatedAt: DateTime.now()
            .subtract(const Duration(days: 3, hours: 4, minutes: 45)),
      ),
    ];

    // Add messages for chat 13
    _messages[13] = [
      Message(
        id: '5',
        content: 'این یک پیام نمونه در گفتگوی شماره ۱۳ است',
        role: 'user',
        contentType: 'text',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      Message(
        id: '6',
        content: 'پاسخ نمونه از سیستم',
        role: 'system',
        contentType: 'text',
        createdAt: DateTime.now().subtract(const Duration(minutes: 55)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 55)),
      ),
    ];

    _nextMessageId = 7; // Update next message ID
  }

  // Get all chats
  Future<List<Chat>> getUserChats() async {
    await Future.delayed(
        const Duration(milliseconds: 500)); // Simulate network delay
    return _chats.values.toList();
  }

  // Get a single chat
  Future<Chat?> getChat(int chatId) async {
    await Future.delayed(
        const Duration(milliseconds: 300)); // Simulate network delay
    return _chats[chatId];
  }

  // Create a new chat
  Future<Chat?> createChat(String title) async {
    await Future.delayed(
        const Duration(milliseconds: 800)); // Simulate network delay

    // Generate a unique ID based on current timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final chatId = timestamp.toString();

    final chat = Chat(
      id: chatId,
      title: title,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      messages: [],
    );

    // Store using the numeric ID for internal tracking
    _chats[_nextChatId] = chat;
    _messages[_nextChatId] = [];
    _nextChatId++;

    return chat;
  }

  // Delete a chat
  Future<bool> deleteChat(int chatId) async {
    await Future.delayed(
        const Duration(milliseconds: 500)); // Simulate network delay

    if (_chats.containsKey(chatId)) {
      _chats.remove(chatId);
      _messages.remove(chatId);
      return true;
    }

    return false;
  }

  // Get all messages for a chat
  Future<List<Message>> getChatMessages(int chatId) async {
    await Future.delayed(
        const Duration(milliseconds: 700)); // Simulate network delay

    if (_messages.containsKey(chatId)) {
      return _messages[chatId]!;
    }

    return [];
  }

  // Send a text message
  Future<Message?> sendTextMessage(int chatId, String content) async {
    await Future.delayed(
        const Duration(milliseconds: 1000)); // Simulate network delay

    if (!_chats.containsKey(chatId)) {
      return null;
    }

    final message = Message(
      id: _nextMessageId.toString(),
      content: content,
      role: 'user',
      contentType: 'text',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _messages[chatId]!.add(message);
    _nextMessageId++;

    // Update chat's updatedAt time
    final chat = _chats[chatId]!;
    _chats[chatId] = Chat(
      id: chat.id,
      title: chat.title,
      createdAt: chat.createdAt,
      updatedAt: DateTime.now(),
      messages: chat.messages,
    );

    // Generate automatic response after a delay
    Timer(const Duration(seconds: 1), () {
      final response = Message(
        id: _nextMessageId.toString(),
        content: 'پیام شما دریافت شد. این یک پاسخ خودکار از سرویس آفلاین است.',
        role: 'system',
        contentType: 'text',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      _messages[chatId]!.add(response);
      _nextMessageId++;
    });

    return message;
  }

  // Send an image message
  Future<Message?> sendImageMessage(int chatId, String imagePath) async {
    await Future.delayed(
        const Duration(seconds: 2)); // Simulate network delay & upload time

    if (!_chats.containsKey(chatId)) {
      return null;
    }

    // Copy the image to app's documents directory to simulate "uploading" it
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = path.basename(imagePath);
    final savedFile = await File(imagePath).copy('${appDir.path}/$fileName');

    final message = Message(
      id: _nextMessageId.toString(),
      content: savedFile.path, // Local path to the "uploaded" image
      role: 'user',
      contentType: 'image',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _messages[chatId]!.add(message);
    _nextMessageId++;

    // Update chat's updatedAt time
    final chat = _chats[chatId]!;
    _chats[chatId] = Chat(
      id: chat.id,
      title: chat.title,
      createdAt: chat.createdAt,
      updatedAt: DateTime.now(),
      messages: chat.messages,
    );

    // Generate automatic response after a delay
    Timer(const Duration(seconds: 1), () {
      final response = Message(
        id: _nextMessageId.toString(),
        content: 'تصویر شما دریافت شد. این یک پاسخ خودکار از سرویس آفلاین است.',
        role: 'system',
        contentType: 'text',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      _messages[chatId]!.add(response);
      _nextMessageId++;
    });

    return message;
  }
}

final mockChatServiceProvider = Provider<MockChatService>((ref) {
  return MockChatService();
});
