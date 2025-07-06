import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EventCollection {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  // Метод для добавления нового события
  Future<void> addEvent(
    String id,
    String title,
    String? description,
    String? category,
    String? date,
    String? time,
    String? location,
    String? status,
    String privacy,
    String? image,
    String? access_code,
    String participantsQantity,
  ) async {
    try {
      CollectionReference events = _firebaseFirestore.collection('events');
      String? userId =
          FirebaseAuth
              .instance
              .currentUser
              ?.uid; // Получаем идентификатор текущего пользователя

      await events.doc(id).set({
        'uid': id,
        'title': title,
        'description': description,
        'category': category,
        'date': date,
        'time': time,
        'location': location,
        'status': status,
        'privacy': privacy,
        'user_created_id': userId,
        'image': image, // Ссылка на изображение
        'access_code ': access_code,
        'participantsQantity': participantsQantity,
      });
    } catch (e) {
      print("Error adding event: $e"); // Выводим ошибку в консоль для отладки
    }
  }

  // Метод для редактирования изображения события
  Future<void> editImageEvent(String eventId, String image) async {
    try {
      await _firebaseFirestore.collection('events').doc(eventId).update({
        'image': image,
      });
    } catch (e) {
      print(
        "Error editing event image: $e",
      ); // Выводим ошибку в консоль для отладки
    }
  }

  // Метод для редактирования события
  Future<void> editEvent(
    String eventId,
    String title,
    String? description,
    String? category,
    String? date,
    String? time,
    String? location,
    String? status,
    String privacy,
    String participantsQantity,
  ) async {
    try {
      await _firebaseFirestore.collection('events').doc(eventId).update({
        'title': title,
        'description': description,
        'category': category,
        'date': date,
        'time': time,
        'location': location,
        'status': status,
        'privacy': privacy,
        'participantsQantity': participantsQantity,
      });
    } catch (e) {
      print("Error editing event: $e"); // Выводим ошибку в консоль для отладки
    }
  }

  // Метод для удаления события
  Future<void> deleteEvent(String eventId) async {
    try {
      await _firebaseFirestore.collection('events').doc(eventId).delete();
    } catch (e) {
      print("Error deleting event: $e"); // Выводим ошибку в консоль для отладки
    }
  }
}
