import 'package:event_app_3/database/firebaseAuth/users_service.dart';
import 'package:event_app_3/notification.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:toast/toast.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService authService = AuthService();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    LocalNotification.initialize(flutterLocalNotificationsPlugin);
  }

  @override
  Widget build(BuildContext context) {
    ToastContext().init(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Авторизация')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Электронная почта',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите электронную почту';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Введите корректный адрес электронной почты';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Пароль',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите пароль';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    // Попробуем выполнить вход
                    var user = await authService.signIn(
                      emailController.text,
                      passwordController.text,
                    );
                    if (user == null) {
                      if (mounted) {
                        Toast.show('Неверный Email/Пароль!');
                      }
                    } else {
                      // Если вход успешен, переходим на главный экран
                      if (mounted) {
                        Navigator.popAndPushNamed(context, '/home');
                        Toast.show('Вы вошли!');
                      }
                    }
                  }
                },
                child: const Text('Войти'),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  // Показать уведомление и перейти на экран регистрации
                  LocalNotification.showNotification(
                    title: 'Изменение в мероприятии',
                    body: 'Мероприятие «Руки Вверх» было обновлено.',
                    flutterLocalNotificationsPlugin:
                        flutterLocalNotificationsPlugin,
                  );
                  Navigator.pushNamed(context, '/register');
                },
                child: const Text('Нет аккаунта? Зарегистрируйтесь'),
              ),
              const SizedBox(height: 5),
              TextButton(
                onPressed: () {
                  // Переход на экран восстановления пароля
                  Navigator.pushNamed(context, '/edit_password');
                },
                child: const Text('Забыли пароль?'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
