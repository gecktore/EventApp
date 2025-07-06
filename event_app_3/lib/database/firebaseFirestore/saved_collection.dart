import 'package:cloud_firestore/cloud_firestore.dart';

class SavedCollection {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  // Метод для добавления мероприятия в избранное
  Future<void> saveSaved({
    required String userId,
    required String eventId,
  }) async {
    try {
      await _firebaseFirestore.collection('saved').add({
        'user_id': userId,
        'event_id': eventId,
      });
    } catch (e) {
      print('Ошибка при добавлении мероприятия в избранное: $e');
      rethrow;
    }
  }

  // Получение избранных мероприятий для пользователя с сортировкой по времени
  Stream<QuerySnapshot> getSavedEventsForUser(String userId) {
    return _firebaseFirestore
        .collection('saved')
        .where('user_id', isEqualTo: userId)
        .snapshots();
  }

  // Метод для удаления мероприятия из избранного
  Future<void> deleteSavedEvent(String savedId) async {
    try {
      await _firebaseFirestore.collection('saved').doc(savedId).delete();
    } catch (e) {
      print('Ошибка при удалении мероприятия из избранного: $e');
      rethrow;
    }
  }
}
