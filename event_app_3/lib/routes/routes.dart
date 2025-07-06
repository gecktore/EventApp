import 'package:event_app_3/landing.dart';
import 'package:event_app_3/screens/add_edit_event_screen.dart';
import 'package:event_app_3/screens/chat_screen.dart';
import 'package:event_app_3/screens/edit_password_screen.dart';
import 'package:event_app_3/screens/event_detail_screen.dart';
import 'package:event_app_3/screens/favorites_screen.dart';
import 'package:event_app_3/screens/help_screen.dart';
import 'package:event_app_3/screens/home_screen.dart';
import 'package:event_app_3/screens/login_screen.dart';
import 'package:event_app_3/screens/notifications_screen.dart';
import 'package:event_app_3/screens/patcipants_screen.dart';
import 'package:event_app_3/screens/profile_screen.dart';
import 'package:event_app_3/screens/register_screen.dart';
import 'package:event_app_3/screens/search_screen.dart';
import 'package:event_app_3/screens/settings_screen.dart';
import 'package:flutter/material.dart';

final routes = {
  '/': (context) => const Landing(),
  '/add_edit_event': (context) => const AddEditEventScreen(),
  '/chat': (context) => const ChatScreen(),
  '/favorites': (context) => const SavedEventsScreen(),
  '/help': (context) => const HelpScreen(),
  '/home': (context) => const HomeScreen(),
  '/login': (context) => const LoginScreen(),
  '/notifications': (context) => const NotificationsScreen(),
  '/participants': (context) => const ParticipantsScreen(),
  '/profile': (context) => const ProfileScreen(),
  '/register': (context) => const RegisterScreen(),
  '/search': (context) => const SearchScreen(),
  '/settings': (context) => const SettingsScreen(),
  '/edit_password': (context) => const ChangePasswordScreen(),
  '/event':
      (context) => EventDetailScreen(
        eventId: ModalRoute.of(context)!.settings.arguments as String,
      ),
};
