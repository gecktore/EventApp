import 'package:event_app_3/screens/qr_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_app_3/screens/event_detail_screen.dart';
import 'package:event_app_3/screens/access_code_screen.dart';
// Импортируйте экран сканирования QR-кода

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _searchResults = [];
  List<DocumentSnapshot> _events = [];

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  void _fetchEvents() async {
    // Получаем все мероприятия
    QuerySnapshot eventsSnapshot =
        await FirebaseFirestore.instance.collection('events').get();

    setState(() {
      _events = eventsSnapshot.docs;
      _searchResults = _events; // Изначально показываем все мероприятия
    });
  }

  void _searchEvents(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = _events; // Возвращаем все мероприятия
      });
      return;
    }

    setState(() {
      _searchResults =
          _events.where((eventDoc) {
            final event = eventDoc.data() as Map<String, dynamic>;
            return (event['title'] ?? '').toLowerCase().contains(
              query.toLowerCase(),
            );
          }).toList();
    });
  }

  void _scanQRCode() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => QRScannerScreen()),
    );

    if (result != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Отсканирован код: $result')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Поиск мероприятий')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Введите название мероприятия',
                border: OutlineInputBorder(),
              ),
              onChanged: _searchEvents,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AccessCodeScreen(),
                      ),
                    );
                  },
                  child: const Text('Ввести код'),
                ),
                ElevatedButton(
                  onPressed: _scanQRCode, // Обработчик для сканирования QR-кода
                  child: const Text('Отсканировать QR-Code'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final eventDoc = _searchResults[index];
                  final event = eventDoc.data() as Map<String, dynamic>;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      title: Text(
                        event['title'] ?? 'Без названия',
                      ), // Проверка на null
                      subtitle: Text(event['date'] ?? 'Дата не указана'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    EventDetailScreen(eventId: eventDoc.id),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
