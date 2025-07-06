import 'package:event_app_3/database/firebaseAuth/users_service.dart';
import 'package:event_app_3/routes/routes.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: 'AIzaSyCCcoFPwspWG2B1R0PT5_uLauZLrEm5_JA',
      appId: '1:540030464038:android:70817722890d8d73b376e7',
      messagingSenderId: '540030464038',
      projectId: 'flutter-d14f5',
    ),
  );
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(),
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamProvider.value(
      initialData: null,
      value: AuthService().currentUser, // Возвращаем текущего пользователя
      child: Consumer<AppState>(
        builder: (context, appState, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: appState.isDarkTheme ? ThemeData.dark() : ThemeData.light(),
            locale:
                appState.selectedLanguage == 'Русский'
                    ? const Locale('ru')
                    : const Locale('en'),
            initialRoute: '/',
            routes: routes,
          );
        },
      ),
    );
  }
}
