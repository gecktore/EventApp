import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MessageCollection {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  // Метод для отправки сообщения в чат мероприятия
  Future<void> sendMessage({
    required String eventId,
    required String text,
  }) async {
    try {
      final String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('Пользователь не авторизован');
      }

      await _firebaseFirestore.collection('messages').add({
        'event_id': eventId,
        'user_id': userId,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Ошибка при отправке сообщения: $e');
      rethrow;
    }
  }

  // Получение сообщений для мероприятия с сортировкой по времени
  Stream<QuerySnapshot> getMessagesForEvent(String eventId) {
    return _firebaseFirestore
        .collection('messages')
        .where('event_id', isEqualTo: eventId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
