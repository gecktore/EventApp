import 'package:event_app_3/screens/add_edit_event_screen.dart';
import 'package:event_app_3/screens/event_attachments_screen.dart';
import 'package:event_app_3/screens/personal_attachments_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;

  const EventDetailScreen({Key? key, required this.eventId}) : super(key: key);

  @override
  _EventDetailScreenState createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  Map<String, dynamic>? eventData;
  bool isCreator = false;
  bool isLoading = true;
  List<String> participants = [];
  final TextEditingController _messageController = TextEditingController();
  bool isSaved = false;
  bool isParticipant = false;

  @override
  void initState() {
    super.initState();
    _loadEventData();
    _loadParticipants();
  }

  Future<void> _leaveEvent() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId != null) {
      try {
        final snapshot =
            await FirebaseFirestore.instance
                .collection('registrations')
                .where('event_id', isEqualTo: widget.eventId)
                .where('user_id', isEqualTo: currentUserId)
                .get();
        for (var doc in snapshot.docs) {
          await doc.reference.delete();
        }
        setState(() {
          participants.remove(currentUserId);
          isParticipant = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Вы вышли из мероприятия!')),
        );
      } catch (e) {
        print("Error leaving event: $e");
      }
    }
  }

  Future<void> _joinEvent() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId != null) {
      try {
        await FirebaseFirestore.instance.collection('registrations').add({
          'event_id': widget.eventId,
          'user_id': currentUserId,
        });
        setState(() {
          participants.add(currentUserId);
          isParticipant = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Вы стали участником мероприятия!')),
        );
      } catch (e) {
        print("Error joining event: $e");
      }
    }
  }

  Future<void> _deleteEvent() async {
    try {
      await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .delete();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Мероприятие удалено!')));
      Navigator.pop(context);
    } catch (e) {
      print('Ошибка при удалении мероприятия: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка при удалении мероприятия')),
      );
    }
  }

  Future<void> _loadEventData() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('events')
            .doc(widget.eventId)
            .get();
    final data = doc.data();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    setState(() {
      eventData = data;
      isCreator = data?['user_created_id'] == currentUserId;
      isLoading = false;
    });
  }

  Future<void> _checkIfSaved() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId != null) {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('saved')
              .where('user_id', isEqualTo: currentUserId)
              .where('event_id', isEqualTo: widget.eventId)
              .get();
      setState(() {
        isSaved = snapshot.docs.isNotEmpty;
      });
    }
  }

  Future<void> _toggleSaveEvent() async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId != null) {
        if (isSaved) {
          // Удаляем из избранного
          try {
            final snapshot =
                await FirebaseFirestore.instance
                    .collection('saved')
                    .where('user_id', isEqualTo: currentUserId)
                    .where('event_id', isEqualTo: widget.eventId)
                    .get();
            for (var doc in snapshot.docs) {
              await doc.reference.delete();
            }
            setState(() {
              isSaved = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Мероприятие удалено из избранного!'),
              ),
            );
          } catch (e) {
            print('Ошибка при удалении из избранного: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ошибка при удалении из избранного'),
              ),
            );
          }
        } else {
          // Добавляем в избранное
          try {
            await FirebaseFirestore.instance.collection('saved').add({
              'user_id': currentUserId,
              'event_id': widget.eventId,
            });
            setState(() {
              isSaved = true;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Мероприятие добавлено в избранное!'),
              ),
            );
          } catch (e) {
            print('Ошибка при добавлении в избранное: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ошибка при добавлении в избранное'),
              ),
            );
          }
        }
      }
    } catch (e) {
      print("Ошибка ${e}");
    }
  }

  Future<void> _loadParticipants() async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      final snapshot =
          await FirebaseFirestore.instance
              .collection('registrations')
              .where('event_id', isEqualTo: widget.eventId)
              .get();

      setState(() {
        participants =
            snapshot.docs.map((doc) => doc['user_id'] as String).toList();
        isParticipant =
            currentUserId != null && participants.contains(currentUserId);
      });
    } catch (e) {
      print("Error loading participants: $e");
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      try {
        final currentUserId = FirebaseAuth.instance.currentUser?.uid;

        await FirebaseFirestore.instance.collection('messages').add({
          'event_id': widget.eventId,
          'user_id': currentUserId,
          'text': _messageController.text,
          'timestamp': FieldValue.serverTimestamp(),
        });
        _messageController.clear();
      } catch (e) {
        print("Error sending message: $e");
      }
    }
  }

  void _shareEventLink() {}

  Future<String> _getUsername(String userId) async {
    if (userId == null) return 'Неизвестный пользователь';

    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('profiles')
              .doc(userId)
              .get();
      if (!userDoc.exists) {
        return 'Неизвестный пользователь';
      }
      return userDoc.data()?['username'] ?? 'Неизвестный пользователь';
    } catch (e) {
      print("Error fetching username: $e");
      return 'Неизвестный пользователь';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(eventData?['title'] ?? 'Детали мероприятия'),
        actions: [
          if (!isLoading && isCreator)
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Удалить мероприятие',
              onPressed: _deleteEvent,
            ),
          if (!isLoading && isCreator)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Редактировать',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => AddEditEventScreen(
                          eventId: widget.eventId,
                          title: eventData?['title'],
                          description: eventData?['description'],
                          category: eventData?['category'],
                          date: eventData?['date'],
                          time: eventData?['time'],
                          location: eventData?['location'],
                          privacy: eventData?['privacy'],
                        ),
                  ),
                ).then((_) => _loadEventData());
              },
            ),
          IconButton(
            icon: Icon(isSaved ? Icons.favorite : Icons.favorite_border),
            tooltip: isSaved ? 'Удалить из избранного' : 'Добавить в избранное',
            onPressed: _toggleSaveEvent,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Поделиться',
            onPressed: () {
              const String accessCode = 'tudim_sudim';

              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Поделиться мероприятием'),
                    content: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/icons/qr.png',
                          width: 150,
                          height: 150,
                          errorBuilder:
                              (context, error, stackTrace) =>
                                  const Icon(Icons.broken_image, size: 150),
                        ),
                        const SizedBox(width: 16),
                        Flexible(
                          child: SelectableText(
                            accessCode,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Закрыть'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : eventData == null
              ? const Center(child: Text('Мероприятие не найдено'))
              : ListView(
                children: [
                  Image(
                    image:
                        eventData?['image'] != null &&
                                eventData!['image']!.isNotEmpty
                            ? NetworkImage(eventData!['image'])
                            : const AssetImage('assets/icons/event_zagl.png')
                                as ImageProvider,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: const Icon(Icons.error),
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          eventData?['title'] ?? 'Без названия',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16),
                            const SizedBox(width: 4),
                            Text(eventData?['date'] ?? 'Дата не указана'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 16),
                            const SizedBox(width: 4),
                            Text(eventData?['location'] ?? 'Место не указано'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          eventData?['description'] ?? 'Описание отсутствует',
                          style: const TextStyle(fontSize: 16),
                        ),
                        if (!isCreator) // Если не организатор
                          if (isParticipant) // Если участник
                            ElevatedButton(
                              onPressed: _leaveEvent,
                              child: const Text('Выйти из мероприятия'),
                            )
                          else // Если не участник
                            ElevatedButton(
                              onPressed: _joinEvent,
                              child: const Text('Стать участником'),
                            ),
                        const SizedBox(height: 20),

                        const Text(
                          'Участники:',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Количество участников: ${participants.length} из ${eventData?['participantsQantity'] ?? 'неизвестно'}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        if (participants.isEmpty)
                          const Text('Нет зарегистрированных участников.')
                        else
                          ...participants.map((participantId) {
                            return FutureBuilder<String>(
                              future: _getUsername(participantId),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }
                                if (snapshot.hasError) {
                                  return Text('Ошибка: ${snapshot.error}');
                                }
                                final userData = snapshot.data;
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage:
                                        const AssetImage(
                                              'assets/icons/profile.png',
                                            )
                                            as ImageProvider,
                                  ),
                                  title: Text(
                                    snapshot.data ?? 'Неизвестный пользователь',
                                  ),
                                  trailing:
                                      isCreator &&
                                              participantId !=
                                                  FirebaseAuth
                                                      .instance
                                                      .currentUser
                                                      ?.uid // Показываем кнопку удаления только организатору и не для него самого
                                          ? IconButton(
                                            icon: const Icon(Icons.delete),
                                            onPressed: () {
                                              // Логика удаления участника
                                              // _removeParticipant(participantId);
                                            },
                                            tooltip: 'Удалить участника',
                                          )
                                          : null,
                                );
                              },
                            );
                          }).toList(),

                        const SizedBox(height: 20),
                        const Text(
                          'Чат:',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        StreamBuilder<QuerySnapshot>(
                          stream:
                              FirebaseFirestore.instance
                                  .collection('messages')
                                  .where('event_id', isEqualTo: widget.eventId)
                                  .orderBy('timestamp')
                                  .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (snapshot.hasError) {
                              return Center(
                                child: Text(
                                  'Ошибка загрузки сообщений: ${snapshot.error}',
                                ),
                              );
                            }
                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return const Text('Нет сообщений.');
                            }

                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: snapshot.data!.docs.length,
                              itemBuilder: (context, index) {
                                final message =
                                    snapshot.data!.docs[index].data()
                                        as Map<String, dynamic>;
                                return FutureBuilder<String>(
                                  future: _getUsername(message['user_id']),
                                  builder: (context, usernameSnapshot) {
                                    if (usernameSnapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }
                                    if (usernameSnapshot.hasError) {
                                      return Text(
                                        'Ошибка : ${usernameSnapshot.error}',
                                      );
                                    }
                                    return ListTile(
                                      leading: CircleAvatar(
                                        backgroundImage:
                                            const AssetImage(
                                                  'assets/icons/profile.png',
                                                )
                                                as ImageProvider,
                                      ),
                                      title: Text(message['text']),
                                      subtitle: Text(
                                        usernameSnapshot.data ??
                                            'Неизвестный пользователь',
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: const InputDecoration(
                              labelText: 'Введите сообщение',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: _sendMessage,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => PersonalAttachmentsScreen(
                                      eventId: widget.eventId,
                                    ),
                              ),
                            );
                          },
                          child: const Text('Личные вложения'),
                        ),
                        SizedBox(
                          width: 207,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => EventAttachmentsScreen(
                                        eventId: widget.eventId,
                                        creatorId:
                                            eventData?['user_created_id'],
                                      ),
                                ),
                              );
                            },
                            child: const Center(
                              child: Text(
                                'Вложения мероприятия',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }
}
