import 'package:event_app_3/app_state.dart';
import 'package:event_app_3/database/firebaseAuth/users_service.dart';
import 'package:event_app_3/database/firebaseFirestore/profile_collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'help_screen.dart'; // Импортируйте ваш экран помощи

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true; // Переключатель для уведомлений
  AuthService authService = AuthService();
  ProfileCollection profileCollection = ProfileCollection();

  @override
  void initState() {
    super.initState();
    _loadSettings(); // Загружаем настройки при инициализации
  }

  // Метод для загрузки настроек
  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications') ?? true;
    });
  }

  // Метод для сохранения настроек
  Future<void> _saveSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications', _notificationsEnabled);
  }

  Future<void> _deleteAccount() async {
    // Получаем текущего пользователя
    final user =
        AuthService()
            .currentUser; // Предполагается, что у вас есть метод для получения текущего пользователя

    if (user != null) {
      // Удаляем профиль из Firestore
      // await profileCollection.deleteProfile(user); // Удаляем профиль по uid

      // Удаляем пользователя из Firebase Authentication
      // await AuthService()
      //     .deleteUser(); // Предполагается, что у вас есть метод для удаления пользователя

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Аккаунт удален!')));

      // Здесь можно добавить логику для выхода из приложения или перехода на экран входа
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка: пользователь не найден.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(
      context,
    ); // Получаем состояние приложения

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Уведомления',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SwitchListTile(
              title: const Text('Включить уведомления'),
              value: _notificationsEnabled,
              onChanged: (bool value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Язык',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            DropdownButton<String>(
              value: appState.selectedLanguage,
              items:
                  <String>['English', 'Русский'].map<DropdownMenuItem<String>>((
                    String value,
                  ) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  appState.setLanguage(
                    newValue,
                  ); // Устанавливаем язык в состоянии
                }
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Тема',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SwitchListTile(
              title: const Text('Темная тема'),
              value: appState.isDarkTheme,
              onChanged: (bool value) {
                appState.toggleTheme(); // Переключаем тему
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _saveSettings(); // Сохраняем настройки
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Настройки сохранены!')),
                );
              },
              child: const Text('Сохранить настройки'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Переход на страницу помощи
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HelpScreen(),
                  ), // Переход на экран помощи
                );
              },
              child: const Text('Помощь'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                // Подтверждение удаления аккаунта
                bool? confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Удаление аккаунта'),
                      content: const Text(
                        'Вы уверены, что хотите удалить свой аккаунт?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Отмена'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Удалить'),
                        ),
                      ],
                    );
                  },
                );

                if (confirm == true) {
                  // await _deleteAccount(); // Удаляем аккаунт
                }
              },
              child: const Text('Удалить аккаунт'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ), // Используем backgroundColor вместо primary
            ),
          ],
        ),
      ),
    );
  }
}
