import 'dart:io';
import 'package:cross_file/cross_file.dart';
import 'package:event_app_3/database/firebaseAuth/user.dart';
import 'package:event_app_3/database/firebaseAuth/users_service.dart';
import 'package:event_app_3/database/firebaseFirestore/profile_collection.dart';
import 'package:event_app_3/screens/event_detail_screen.dart';
import 'package:event_app_3/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_app_3/database/firebaseStorage/image_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:toast/toast.dart';

final colRef = FirebaseFirestore.instance.collection('profiles');

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? userId; // = FirebaseAuth.instance.currentUser!.uid.toString();
  dynamic userDoc;
  XFile? selectImage;
  XFile? fileName;
  ImageStorage imageStorage = ImageStorage();
  ProfileCollection profileCollection = ProfileCollection();
  AuthService authService = AuthService();

  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _patronymicController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid; // Получаем userId
    if (userId != null) {
      getUserById();
    } else {
      // Если пользователь не авторизован, перенаправляем на экран входа
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      });
    }
  }

  Future<void> selectImageGallery() async {
    try {
      final returnImage = await ImagePicker().pickImage(
        source: ImageSource.gallery,
      );
      if (returnImage != null) {
        setState(() {
          fileName = returnImage;
          selectImage = XFile(returnImage.path);
        });
      }
    } catch (e) {
      print("Error selecting image: $e");
      Toast.show('Ошибка при выборе изображения');
    }
  }

  Future<void> getUserById() async {
    try {
      final DocumentSnapshot documentSnapshot = await colRef.doc(userId).get();
      setState(() {
        userDoc = documentSnapshot.data();
        _surnameController.text = userDoc['surname'] ?? '';
        _nameController.text = userDoc['name'] ?? '';
        _patronymicController.text = userDoc['patronymic'] ?? '';
        _phoneController.text = userDoc['phone'] ?? '';
        _descriptionController.text = userDoc['description'] ?? '';
        _usernameController.text = userDoc['username'] ?? '';
        _emailController.text =
            userDoc['email'] ?? ''; // Загружаем email из Firebase Auth
      });
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  Future<void> _saveProfile() async {
    try {
      // Обновляем остальные данные в Firestore
      await profileCollection.editProfile(
        userDoc,
        _surnameController.text,
        _nameController.text,
        _patronymicController.text,
        _phoneController.text,
        _descriptionController.text,
        _usernameController.text,
      );

      if (mounted) {
        Toast.show('Профиль обновлен!');
      }
      setState(() {
        _isEditing = false;
      });
      getUserById();
    } catch (e) {
      print("Error saving profile: $e");
      if (mounted) {
        Toast.show('Ошибка при обновлении профиля: ${e.toString()}');
      }
    }
  }

  Future<void> _logOut() async {
    await authService.logOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false, // Удаляем все предыдущие экраны из стека
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            onPressed: () async {
              if (_isEditing) {
                await _saveProfile();
              } else {
                setState(() {
                  _isEditing = true;
                });
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () {
              Navigator.pushNamed(context, '/favorites');
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logOut),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            StreamBuilder<DocumentSnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('profiles')
                      .doc(userId)
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                } else {
                  final userData = snapshot.data!.data();

                  return Column(
                    children: [
                      _buildProfileHeader(context, userData),
                      const SizedBox(height: 24),
                      _buildUserInfoSection(context, userData),
                      const SizedBox(height: 24),
                      _buildCreatedEventsSection(),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, dynamic userData) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage:
                  userData['image'] != null && userData['image'].isNotEmpty
                      ? NetworkImage(userData['image'])
                      : const AssetImage('assets/icons/profile.png')
                          as ImageProvider,
            ),
            if (_isEditing)
              FloatingActionButton.small(
                onPressed: () async {
                  await selectImageGallery();
                  if (selectImage != null) {
                    String? uploadedImageUrl = await imageStorage
                        .addImageProfileStorage(fileName!);
                    if (uploadedImageUrl != null) {
                      await profileCollection.editImageProfile(
                        userData,
                        uploadedImageUrl,
                      );
                      Toast.show('Изображение обновлено!');
                      getUserById(); // Обновите данные профиля
                    }
                  }
                },
                child: const Icon(Icons.camera_alt),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserInfoSection(BuildContext context, dynamic userData) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'О себе',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            if (_isEditing)
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              )
            else
              Text(
                userData['description'] ?? 'Нет описания',
                style: const TextStyle(fontSize: 14),
              ),
            const SizedBox(height: 16),
            if (_isEditing)
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Имя пользователя',
                  border: OutlineInputBorder(),
                ),
              )
            else
              _buildInfoRow(
                Icons.person_outline,
                'Имя пользователя',
                userData['username'] ?? '',
              ),

            const SizedBox(height: 8),

            _buildInfoRow(Icons.email, 'Email', userData['email'] ?? ''),
            const SizedBox(height: 8),
            if (_isEditing)
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Телефон'),
              )
            else
              _buildInfoRow(Icons.phone, 'Телефон', userData['phone'] ?? ''),
            const SizedBox(height: 8),
            if (_isEditing)
              TextFormField(
                controller: _surnameController,
                decoration: const InputDecoration(labelText: 'Фамилия'),
              )
            else
              _buildInfoRow(Icons.person, 'Фамилия', userData['surname'] ?? ''),
            const SizedBox(height: 8),
            if (_isEditing)
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Имя'),
              )
            else
              _buildInfoRow(Icons.person, 'Имя', userData['name'] ?? ''),
            const SizedBox(height: 8),
            if (_isEditing)
              TextFormField(
                controller: _patronymicController,
                decoration: const InputDecoration(labelText: 'Отчество'),
              )
            else
              _buildInfoRow(
                Icons.person,
                'Отчество',
                userData['patronymic'] ?? '',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(value, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  Future<List<DocumentSnapshot>> _fetchEvents(List<String> eventIds) async {
    if (eventIds.isEmpty) return [];

    // Получаем мероприятия по списку event_ids
    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance
            .collection('events')
            .where(FieldPath.documentId, whereIn: eventIds)
            .get();

    return querySnapshot.docs;
  }

  Widget _buildCreatedEventsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            'Мои мероприятия',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 150,
          child: StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('registrations')
                    .where(
                      'user_id',
                      isEqualTo: userId,
                    ) // Получаем регистрации пользователя
                    .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final registrations = snapshot.data!.docs;

              if (registrations.isEmpty) {
                return const Center(
                  child: Text('Нет зарегистрированных мероприятий'),
                );
              }

              // Получаем список event_id из регистраций
              List<String> eventIds =
                  registrations.map((doc) {
                    return doc['event_id'] as String; // Приводим к типу String
                  }).toList();

              return FutureBuilder<List<DocumentSnapshot>>(
                future: _fetchEvents(eventIds),
                builder: (context, eventSnapshot) {
                  if (eventSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (eventSnapshot.hasError) {
                    return const Center(
                      child: Text('Ошибка при загрузке мероприятий'),
                    );
                  }

                  final events = eventSnapshot.data;

                  if (events == null || events.isEmpty) {
                    return const Center(
                      child: Text('Нет мероприятий для отображения'),
                    );
                  }

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event =
                          events[index].data() as Map<String, dynamic>;

                      return GestureDetector(
                        onTap: () {
                          String eventId =
                              events[index].id; // Получаем ID события
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      EventDetailScreen(eventId: eventId),
                            ),
                          );
                        },
                        child: Container(
                          width: 200,
                          margin: const EdgeInsets.only(right: 8),
                          child: Card(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                        image:
                                            event['image'] != null &&
                                                    event['image'].isNotEmpty
                                                ? NetworkImage(event['image'])
                                                : const AssetImage(
                                                      'assets/icons/event_zagl.png',
                                                    )
                                                    as ImageProvider,
                                        fit: BoxFit.cover,
                                      ),
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(4),
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        event['title'] ?? 'Мероприятие',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        event['date'] ?? 'Дата не указана',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _surnameController.dispose();
    _nameController.dispose();
    _patronymicController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _usernameController.dispose();
    super.dispose();
  }
}
