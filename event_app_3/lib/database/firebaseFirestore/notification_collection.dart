import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationCollection {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  // Метод для отправки уведомления
  Future<void> sendNotification({
    required String userId,
    required String text,
  }) async {
    try {
      await _firebaseFirestore.collection('notifications').add({
        'user_id': userId,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Ошибка при отправке уведомления: $e');
      rethrow;
    }
  }

  // Получение уведомлений для пользователя с сортировкой по времени
  Stream<QuerySnapshot> getNotificationsForUser(String userId) {
    return _firebaseFirestore
        .collection('notifications')
        .where('user_id', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? userId = FirebaseAuth.instance.currentUser?.uid;
  List<DocumentSnapshot> notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    if (userId != null) {
      _firestore
          .collection('notifications')
          .where('user_id', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .snapshots()
          .listen(
            (snapshot) {
              setState(() {
                notifications = snapshot.docs;
              });
            },
            onError: (error) {
              print('Ошибка при загрузке уведомлений: $error');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ошибка при загрузке уведомлений'),
                ),
              );
            },
          );
    }
  }

  void _deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Уведомление удалено!')));
    } catch (e) {
      print('Ошибка при удалении уведомления: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка при удалении уведомления')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Уведомления')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            notifications.isEmpty
                ? const Center(child: Text('Нет уведомлений'))
                : ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        title: Text(notification['text']),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            _deleteNotification(notification.id);
                          },
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
