import 'package:event_app_3/database/firebaseAuth/users_service.dart';
import 'package:flutter/material.dart';
import 'package:toast/toast.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  TextEditingController emailController = TextEditingController();
  AuthService authService = AuthService();

  @override
  Widget build(BuildContext context) {
    ToastContext().init(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Смена пароля')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              obscureText: false,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await authService.editPassword(emailController.text);
                Toast.show('Сообщение отправлено!');
                Navigator.popAndPushNamed(context, '/');
              },
              child: const Text('Отправить сообщение.'),
            ),
          ],
        ),
      ),
    );
  }
}
