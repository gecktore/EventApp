import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
const HelpScreen({super.key});

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: const Text('Помощь')),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          const Text(
            'Часто задаваемые вопросы (FAQ)',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildFAQItem(
            question: 'Как создать новое мероприятие?',
            answer:
                'Чтобы создать новое мероприятие, перейдите на главную страницу и нажмите кнопку «Создать мероприятие».',
          ),
          _buildFAQItem(
            question: 'Как зарегистрироваться на мероприятие?',
            answer:
                'Выберите мероприятие из списка и нажмите кнопку «Зарегистрироваться».',
          ),
          _buildFAQItem(
            question: 'Как изменить свои настройки?',
            answer:
                'Перейдите в раздел «Настройки» в меню и измените необходимые параметры.',
          ),
          const SizedBox(height: 20),
          const Text(
            'Контактная информация',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Если у вас есть дополнительные вопросы, вы можете связаться с нашей службой поддержки по электронной почте:',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 10),
          const Text(
            'gecktore00@mail.ru',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    ),
  );
}

Widget _buildFAQItem({required String question, required String answer}) {
  return Card(
    margin: const EdgeInsets.symmetric(vertical: 8.0),
    child: ExpansionTile(
      title: Text(question),
      children: [
        Padding(padding: const EdgeInsets.all(16.0), child: Text(answer)),
      ],
    ),
  );
}
}
