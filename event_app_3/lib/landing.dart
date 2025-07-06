import 'package:event_app_3/database/firebaseAuth/user.dart';
import 'package:event_app_3/screens/home_screen.dart';
import 'package:event_app_3/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toast/toast.dart';

class Landing extends StatelessWidget {
  const Landing({super.key});
  @override
  Widget build(BuildContext context) {
    ToastContext().init(context);
    final UserModel? userModel = Provider.of<UserModel?>(context);
    final bool check = userModel != null;
    return check ? const HomeScreen() : const LoginScreen();
  }
}
