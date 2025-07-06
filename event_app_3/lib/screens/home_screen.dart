import 'package:event_app_3/screens/event_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedCategory = 'Все';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мероприятия'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.pushNamed(context, '/search');
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.pushNamed(context, '/notifications');
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(children: [_buildCategoryFilter(), _buildEventList()]),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/add_edit_event');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<bool> _isUserParticipant(String eventId, String userId) async {
    final registrationsSnapshot =
        await FirebaseFirestore.instance
            .collection('registrations')
            .where('event_id', isEqualTo: eventId)
            .where('user_id', isEqualTo: userId)
            .get();

    return registrationsSnapshot.docs.isNotEmpty;
  }

  // Фильтр категорий (горизонтальный ListView)
  Widget _buildCategoryFilter() {
    final categories = ['Все', 'Концерт', 'Вечеринка', 'Спорт', 'Выставка'];
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ChoiceChip(
              label: Text(categories[index]),
              selected: selectedCategory == categories[index],
              onSelected: (selected) {
                setState(() {
                  selectedCategory = categories[index];
                });
              },
            ),
          );
        },
      ),
    );
  }

  Future<List<DocumentSnapshot>> _filterEvents(
    List<DocumentSnapshot> events,
  ) async {
    List<DocumentSnapshot> filteredEvents = [];
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    for (var eventDoc in events) {
      final event = eventDoc.data() as Map<String, dynamic>;
      final isPrivate = event['privacy'] == 'private';

      if (isPrivate) {
        // Проверяем, является ли пользователь участником, только если currentUser Id не null
        if (currentUserId != null) {
          bool isParticipant = await _isUserParticipant(
            eventDoc.id,
            currentUserId,
          );
          if (isParticipant) {
            filteredEvents.add(eventDoc);
          }
        }
      } else {
        filteredEvents.add(eventDoc); // Добавляем публичные мероприятия
      }
    }

    // Фильтруем по категории
    if (selectedCategory != 'Все') {
      filteredEvents =
          filteredEvents.where((eventDoc) {
            final event = eventDoc.data() as Map<String, dynamic>;
            return event['category'] == selectedCategory;
          }).toList();
    }

    return filteredEvents;
  }

  Widget _buildEventList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('events').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Ошибка при загрузке мероприятий'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Нет мероприятий'));
        }
        final events = snapshot.data!.docs;

        return FutureBuilder<List<DocumentSnapshot>>(
          future: _filterEvents(events),
          builder: (context, futureSnapshot) {
            if (futureSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (futureSnapshot.hasError) {
              return const Center(
                child: Text('Ошибка при фильтрации мероприятий'),
              );
            }

            final filteredEvents = futureSnapshot.data ?? [];
            return ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: filteredEvents.length,
              itemBuilder: (context, index) {
                final eventDoc = filteredEvents[index];
                final event = eventDoc.data() as Map<String, dynamic>;
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image(
                        image:
                            event['image'] != null && event['image']!.isNotEmpty
                                ? NetworkImage(event['image'])
                                : const AssetImage(
                                      'assets/icons/event_zagl.png',
                                    )
                                    as ImageProvider,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 150,
                            color: Colors.grey[300],
                            child: const Icon(Icons.error),
                          );
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event['title'] ?? 'Без названия',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16),
                                const SizedBox(width: 4),
                                Text(event['date'] ?? 'Дата не указана'),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 16),
                                const SizedBox(width: 4),
                                Text(event['location'] ?? 'Место не указано'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    String eventId = eventDoc.id;
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => EventDetailScreen(
                                              eventId: eventId,
                                            ),
                                      ),
                                    );
                                  },
                                  child: const Text('Подробнее'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
