import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/farmer_model.dart';
import '../models/message_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Farmers
  Future<void> saveFarmer(FarmerModel farmer) async {
    await _db.collection('farmers').doc(farmer.uid).set(farmer.toFirestore());
  }

  Future<FarmerModel?> getFarmer(String uid) async {
    final doc = await _db.collection('farmers').doc(uid).get();
    if (!doc.exists) return null;
    return FarmerModel.fromFirestore(doc);
  }

  Stream<List<FarmerModel>> getNearbyFarmers({
    required double lat,
    required double lng,
    double radiusKm = 50,
  }) {
    // Firestore doesn't support native geo queries without GeoFlutter.
    // Simple bounding-box approach for demo:
    final double degreeOffset = radiusKm / 111.0;
    return _db
        .collection('farmers')
        .where('latitude', isGreaterThan: lat - degreeOffset)
        .where('latitude', isLessThan: lat + degreeOffset)
        .limit(30)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => FarmerModel.fromFirestore(d)).toList());
  }

  Future<void> updateOnlineStatus(String uid, bool isOnline) async {
    await _db.collection('farmers').doc(uid).update({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  // Chat
  Future<ChatRoom> getOrCreateChatRoom(
    String uid1, String uid2,
    String name1, String name2,
  ) async {
    final roomId = ChatRoom.generateId(uid1, uid2);
    final doc = await _db.collection('chats').doc(roomId).get();

    if (!doc.exists) {
      final room = {
        'participantIds': [uid1, uid2],
        'participantNames': [name1, name2],
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount': 0,
      };
      await _db.collection('chats').doc(roomId).set(room);
    }

    final fresh = await _db.collection('chats').doc(roomId).get();
    return ChatRoom.fromFirestore(fresh);
  }

  Stream<List<MessageModel>> getMessages(String chatRoomId) {
    return _db
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => MessageModel.fromFirestore(d)).toList());
  }

  Future<void> sendMessage(String chatRoomId, MessageModel message) async {
    final batch = _db.batch();
    final msgRef = _db
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .doc();
    batch.set(msgRef, message.toFirestore());
    batch.update(_db.collection('chats').doc(chatRoomId), {
      'lastMessage': message.text,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Stream<List<ChatRoom>> getUserChatRooms(String uid) {
    return _db
        .collection('chats')
        .where('participantIds', arrayContains: uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ChatRoom.fromFirestore(d)).toList());
  }
}
