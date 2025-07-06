import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState with ChangeNotifier {
  bool _isDarkTheme = false;
  String _selectedLanguage = 'English'; // По умолчанию английский

  AppState() {
    _loadTheme(); // Загружаем тему при инициализации
    _loadLanguage(); // Загружаем язык при инициализации
  }

  bool get isDarkTheme => _isDarkTheme;
  String get selectedLanguage => _selectedLanguage;

  void toggleTheme() {
    _isDarkTheme = !_isDarkTheme;
    _saveTheme(); // Сохраняем тему при изменении
    notifyListeners();
  }

  void setLanguage(String language) {
    _selectedLanguage = language;
    _saveLanguage(); // Сохраняем язык при изменении
    notifyListeners();
  }

  // Метод для сохранения темы в SharedPreferences
  Future<void> _saveTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkTheme', _isDarkTheme);
  }

  // Метод для загрузки темы из SharedPreferences
  Future<void> _loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isDarkTheme =
        prefs.getBool('isDarkTheme') ?? false; // По умолчанию светлая тема
    notifyListeners();
  }

  // Метод для сохранения языка в SharedPreferences
  Future<void> _saveLanguage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', _selectedLanguage);
  }

  // Метод для загрузки языка из SharedPreferences
  Future<void> _loadLanguage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? language = prefs.getString('language');
    // Устанавливаем язык по умолчанию, если значение не соответствует ожидаемым
    _selectedLanguage =
        (language == 'Русский' || language == 'English')
            ? language!
            : 'English'; // Используем оператор ! для указания, что language не null
    notifyListeners();
  }
}
