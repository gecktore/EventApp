import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_app_3/database/firebaseFirestore/saved_collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'event_detail_screen.dart'; // Импортируйте экран деталей мероприятия

class SavedEventsScreen extends StatefulWidget {
  const SavedEventsScreen({super.key});

  @override
  _SavedEventsScreenState createState() => _SavedEventsScreenState();
}

class _SavedEventsScreenState extends State<SavedEventsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? userId = FirebaseAuth.instance.currentUser?.uid;
  List<DocumentSnapshot> savedEvents = [];
  SavedCollection savedCollection = SavedCollection();

  @override
  void initState() {
    super.initState();
    _loadSavedEvents();
  }

  void _loadSavedEvents() {
    if (userId != null) {
      _firestore
          .collection('saved')
          .where('user_id', isEqualTo: userId)
          .snapshots()
          .listen(
            (snapshot) {
              setState(() {
                savedEvents = snapshot.docs;
              });
            },
            onError: (error) {
              print('Ошибка при загрузке избранных мероприятий: $error');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ошибка при загрузке избранных мероприятий'),
                ),
              );
            },
          );
    }
  }

  void _deleteSavedEvent(String savedId) async {
    try {
      await _firestore.collection('saved').doc(savedId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Мероприятие удалено из избранного!')),
      );
    } catch (e) {
      print('Ошибка при удалении мероприятия из избранного: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ошибка при удалении мероприятия из избранного'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Избранные мероприятия')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            savedEvents.isEmpty
                ? const Center(child: Text('Нет избранных мероприятий'))
                : FutureBuilder<List<Map<String, dynamic>>>(
                  future: Future.wait(
                    savedEvents.map((savedEvent) async {
                      final eventDoc =
                          await _firestore
                              .collection('events')
                              .doc(savedEvent['event_id'])
                              .get();
                      return eventDoc.data(); // Это может вернуть null
                    }),
                  ).then((eventData) {
                    // Фильтруем null значения
                    return eventData
                        .where((event) => event != null)
                        .cast<Map<String, dynamic>>()
                        .toList();
                  }),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Ошибка загрузки мероприятий: ${snapshot.error}',
                        ),
                      );
                    }
                    final events =
                        snapshot.data ??
                        []; // Обработка случая, когда данные null
                    return ListView.builder(
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        final event = events[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            title: Text(
                              event['title'] ?? 'Без названия',
                            ), // Обработка случая, когда title null
                            onTap: () {
                              // Переход к экрану деталей мероприятия
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => EventDetailScreen(
                                        eventId: savedEvents[index]['event_id'],
                                      ),
                                ),
                              );
                            },
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                _deleteSavedEvent(savedEvents[index].id);
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
      ),
    );
  }
}
