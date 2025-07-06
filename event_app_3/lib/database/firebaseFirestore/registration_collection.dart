import 'package:cloud_firestore/cloud_firestore.dart';

class RegistrationCollection {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  // Метод для добавления регистрации участника
  Future<void> addRegistration(String eventId, String userId) async {
    try {
      CollectionReference registrations = _firebaseFirestore.collection(
        'registrations',
      );
      String registrationId =
          DateTime.now().millisecondsSinceEpoch
              .toString(); // Генерация уникального ID

      await registrations.doc(registrationId).set({
        'event_id': eventId,
        'user_id': userId,
        'status': 'pending', // Статус регистрации (ожидает подтверждения)
        'timestamp': FieldValue.serverTimestamp(), // Время регистрации
      });
    } catch (e) {
      print(
        "Error adding registration: $e",
      ); // Выводим ошибку в консоль для отладки
      return;
    }
  }

  // Метод для редактирования статуса регистрации
  Future<void> editRegistrationStatus(
    String registrationId,
    String status,
  ) async {
    try {
      await _firebaseFirestore
          .collection('registrations')
          .doc(registrationId)
          .update({'status': status});
    } catch (e) {
      print(
        "Error editing registration status: $e",
      ); // Выводим ошибку в консоль для отладки
      return;
    }
  }

  // Метод для удаления регистрации
  Future<void> deleteRegistration(String registrationId) async {
    try {
      await _firebaseFirestore
          .collection('registrations')
          .doc(registrationId)
          .delete();
    } catch (e) {
      print(
        "Error deleting registration: $e",
      ); // Выводим ошибку в консоль для отладки
      return;
    }
  }

  // Метод для получения всех регистраций для конкретного мероприятия
  Future<List<Map<String, dynamic>>> getRegistrationsForEvent(
    String eventId,
  ) async {
    try {
      QuerySnapshot snapshot =
          await _firebaseFirestore
              .collection('registrations')
              .where('event_id', isEqualTo: eventId)
              .get();

      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print(
        "Error getting registrations: $e",
      ); // Выводим ошибку в консоль для отладки
      return [];
    }
  }

  // Метод для получения всех регистраций для конкретного пользователя
  Future<List<Map<String, dynamic>>> getRegistrationsForUser(
    String userId,
  ) async {
    try {
      QuerySnapshot snapshot =
          await _firebaseFirestore
              .collection('registrations')
              .where('user_id', isEqualTo: userId)
              .get();

      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print(
        "Error getting user registrations: $e",
      ); // Выводим ошибку в консоль для отладки
      return [];
    }
  }
}
