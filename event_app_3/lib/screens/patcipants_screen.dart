import 'package:flutter/material.dart';

class ParticipantsScreen extends StatelessWidget {
  const ParticipantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Пример списка участников
    final List<String> participants = [
      'Иван Иванов',
      'Мария Петрова',
      'Алексей Смирнов',
      'Елена Кузнецова',
      'Дмитрий Сидоров',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Участники')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: participants.length,
          itemBuilder: (context, index) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: ListTile(
                title: Text(participants[index]),
                trailing: IconButton(
                  icon: const Icon(Icons.message),
                  onPressed: () {
                    // Логика для отправки сообщения участнику
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Сообщение отправлено ${participants[index]}!',
                        ),
                      ),
                    );
                  },
                ),
                onTap: () {
                  // Логика для перехода к профилю участника
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => ParticipantProfileScreen(
                            participantName: participants[index],
                          ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class ParticipantProfileScreen extends StatelessWidget {
  final String participantName;

  const ParticipantProfileScreen({super.key, required this.participantName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(participantName)),
      body: Center(
        child: Text(
          'Профиль участника: $participantName',
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
