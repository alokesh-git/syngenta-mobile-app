import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/message_model.dart';
import '../services/firestore_service.dart';

class ChatProvider extends ChangeNotifier {
  final FirestoreService _service = FirestoreService();
  final _uuid = const Uuid();

  List<ChatRoom> _chatRooms = [];
  List<MessageModel> _messages = [];
  bool _isLoading = false;

  List<ChatRoom> get chatRooms => _chatRooms;
  List<MessageModel> get messages => _messages;
  bool get isLoading => _isLoading;

  void loadChatRooms(String uid) {
    try {
      _service.getUserChatRooms(uid).listen((rooms) {
        _chatRooms = rooms;
        notifyListeners();
      });
    } catch (_) {}
  }

  void loadMessages(String chatRoomId) {
    _isLoading = true;
    notifyListeners();

    try {
      _service.getMessages(chatRoomId).listen((msgs) {
        _messages = msgs;
        _isLoading = false;
        notifyListeners();
      });
    } catch (_) {
      _messages = _getMockMessages();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ChatRoom?> openChat(
    String myUid, String otherUid,
    String myName, String otherName,
  ) async {
    try {
      return await _service.getOrCreateChatRoom(
          myUid, otherUid, myName, otherName);
    } catch (_) {
      return null;
    }
  }

  Future<void> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    final message = MessageModel(
      id: _uuid.v4(),
      senderId: senderId,
      senderName: senderName,
      text: text,
      timestamp: DateTime.now(),
    );

    // Optimistic update
    _messages = [..._messages, message];
    notifyListeners();

    try {
      await _service.sendMessage(chatRoomId, message);
    } catch (_) {
      // Message stays in local list for demo purposes
    }
  }

  List<MessageModel> _getMockMessages() => [
        MessageModel(
          id: '1',
          senderId: 'mock1',
          senderName: 'Rajesh Kumar',
          text: 'Namaste! Do you have extra DAP fertilizer? My crop needs it urgently.',
          timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        ),
        MessageModel(
          id: '2',
          senderId: 'current_user',
          senderName: 'You',
          text: 'Yes I have 2 bags. Come over anytime today.',
          timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
        ),
        MessageModel(
          id: '3',
          senderId: 'mock1',
          senderName: 'Rajesh Kumar',
          text: 'Thank you brother! I will come by evening. What price?',
          timestamp: DateTime.now().subtract(const Duration(minutes: 20)),
        ),
      ];
}
