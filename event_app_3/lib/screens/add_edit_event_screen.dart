import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_app_3/database/firebaseFirestore/event_collection.dart';
import 'package:event_app_3/database/firebaseFirestore/notification_collection.dart';
import 'package:event_app_3/database/firebaseFirestore/registration_collection.dart';
import 'package:event_app_3/database/firebaseStorage/image_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:toast/toast.dart';
import 'package:uuid/uuid.dart';

class AddEditEventScreen extends StatefulWidget {
  final String? eventId; // Для редактирования
  final String? title;
  final String? description;
  final String? category;
  final String? date;
  final String? time;
  final String? location;
  final String? privacy;

  const AddEditEventScreen({
    Key? key,
    this.eventId,
    this.title,
    this.description,
    this.category,
    this.date,
    this.time,
    this.location,
    this.privacy,
  }) : super(key: key);

  @override
  State<AddEditEventScreen> createState() => _AddEditEventScreenState();
}

class _AddEditEventScreenState extends State<AddEditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _participantsController = TextEditingController();
  final TextEditingController _quantityParticipantsController =
      TextEditingController();

  // String? organizerId;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedCategory;
  bool _isPrivate = false;
  XFile? selectImage; // Для хранения выбранного изображения
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  final ImageStorage imageStorage = ImageStorage();
  final EventCollection eventCollection = EventCollection();
  final NotificationCollection notificationCollection =
      NotificationCollection();
  final RegistrationCollection registrationCollection =
      RegistrationCollection();
  List<String> participants = [];

  @override
  void initState() {
    super.initState();
    // organizerId = FirebaseAuth.instance.currentUser?.uid;
    // Если передан eventId, загружаем данные мероприятия
    if (widget.eventId != null) {
      _loadEventData(widget.eventId!);
    }
  }

  Future<void> _loadEventData(String eventId) async {
    try {
      DocumentSnapshot eventDoc =
          await FirebaseFirestore.instance
              .collection('events')
              .doc(eventId)
              .get();
      if (eventDoc.exists) {
        var data = eventDoc.data() as Map<String, dynamic>;
        setState(() {
          _titleController.text = data['title'] ?? '';
          _descriptionController.text = data['description'] ?? '';
          _locationController.text = data['location'] ?? '';
          _selectedCategory = data['category'];
          _isPrivate = data['privacy'] == 'private';
          _quantityParticipantsController.text =
              data['participantsQantity']?.toString() ?? '';
          // Обработка даты и времени
          if (data['date'] != null) {
            _selectedDate = DateTime.parse(data['date']);
          }
          if (data['time'] != null) {
            List<String> timeParts = data['time'].split(':');
            if (timeParts.length == 2) {
              int hour = int.parse(timeParts[0]);
              int minute = int.parse(timeParts[1]);
              _selectedTime = TimeOfDay(hour: hour, minute: minute);
            }
          }
          selectImage = data['image'] != null ? XFile(data['image']) : null;
        });
      }
    } catch (e) {
      print("Error loading event data: $e");
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;
    if (!mounted) return;

    try {
      // 1. Подготовка данных
      final eventId =
          widget.eventId ?? DateTime.now().millisecondsSinceEpoch.toString();
      final organizerId = FirebaseAuth.instance.currentUser?.uid;
      if (organizerId == null) {
        Toast.show('Ошибка: пользователь не авторизован');
        return;
      }

      // 2. Добавляем/обновляем событие
      if (widget.eventId == null) {
        await eventCollection.addEvent(
          eventId,
          _titleController.text,
          _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text,
          _selectedCategory,
          _selectedDate?.toIso8601String(),
          _selectedTime != null
              ? '${_selectedTime!.hour}:${_selectedTime!.minute}'
              : null,
          _locationController.text.isEmpty ? null : _locationController.text,
          'active',
          _isPrivate ? 'private' : 'public',
          selectImage != null
              ? await imageStorage.addImageEventStorage(selectImage!)
              : null,
          _isPrivate ? Uuid().v4() : null,
          _quantityParticipantsController.text.isNotEmpty
              ? _quantityParticipantsController.text
              : '', // Передаем пустую строку вместо null
        );
      } else {
        // final registrationsSnapshot =
        //     await _firebaseFirestore
        //         .collection('registrations')
        //         .where('event_id', isEqualTo: widget.eventId)
        //         .get();

        // // Создаем уведомления для всех участников
        // for (var registration in registrationsSnapshot.docs) {
        //   final participantId =
        //       registration['user_id']; // Предполагается, что в регистрации есть поле user_id

        //   // Проверяем, что текст уведомления не пустой
        //   if (_titleController.text.isNotEmpty) {
        //     await _firebaseFirestore.collection('notifications').add({
        //       'user_id': participantId,
        //       'text': 'Мероприятие "${_titleController.text}" было изменено.',
        //       'timestamp': FieldValue.serverTimestamp(),
        //     });
        //   }
        // }
        await eventCollection.editEvent(
          widget.eventId!,
          _titleController.text,
          _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text,
          _selectedCategory,
          _selectedDate?.toIso8601String(),
          _selectedTime != null
              ? '${_selectedTime!.hour}:${_selectedTime!.minute}'
              : null,
          _locationController.text.isEmpty ? null : _locationController.text,
          'active',
          _isPrivate ? 'private' : 'public',
          _quantityParticipantsController.text.isNotEmpty
              ? _quantityParticipantsController.text
              : '', // Передаем пустую строку вместо null
        );

        String? imageUrl;
        if (selectImage != null) {
          try {
            imageUrl = await imageStorage.addImageEventStorage(selectImage!);
            if (imageUrl == null) {
              Toast.show('Ошибка загрузки изображения');
              return;
            }

            if (widget.eventId != null) {
              await eventCollection.editImageEvent(widget.eventId!, imageUrl);
            }
          } catch (e) {
            print('Ошибка загрузки изображения: $e');
            Toast.show('Ошибка загрузки изображения');
            return;
          }
        }
      }

      // 3. Сохраняем всех участников (включая организатора)
      final allParticipants = {organizerId, ...participants}.toList();
      for (final userId in allParticipants) {
        try {
          await registrationCollection.addRegistration(eventId, userId);
          print('Участник $userId успешно добавлен');
        } catch (e) {
          print('Ошибка добавления участника $userId: $e');
        }
      }

      if (mounted) {
        Navigator.pop(context);
        Toast.show('Мероприятие сохранено');
      }
    } catch (e) {
      if (mounted) Toast.show('Ошибка сохранения: ${e.toString()}');
      print('Ошибка сохранения: $e');
    }
  }

  Future<String?> _getUserIdByEmail(String email) async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('profiles')
              .where('email', isEqualTo: email.toLowerCase().trim())
              .limit(1)
              .get();

      return snapshot.docs.firstOrNull?['uid'] as String?;
    } catch (e) {
      print('Ошибка поиска пользователя: $e');
      return null;
    }
  }

  void _addParticipant() async {
    final email = _participantsController.text.trim();
    if (email.isEmpty) {
      Toast.show('Введите email участника');
      return;
    }

    try {
      final userId = await _getUserIdByEmail(email);
      if (userId == null) {
        Toast.show('Пользователь с email $email не найден');
        return;
      }

      if (participants.contains(userId)) {
        Toast.show('Этот участник уже добавлен');
        return;
      }

      setState(() {
        participants.add(userId);
        _participantsController.clear();
      });
      Toast.show('Участник добавлен');
    } catch (e) {
      Toast.show('Ошибка добавления участника');
      print('Ошибка: $e');
    }
  }

  Future<void> selectImageGallery() async {
    final returnImage = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (returnImage != null) {
      setState(() {
        selectImage = returnImage; // Сохраняем выбранное изображение
      });
    }
  }

  Future<List<String>> _getParticipantsEmails() async {
    try {
      // Предположим, что у вас есть коллекция "registrations", где хранятся участники
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance
              .collection('registrations')
              .where(
                'eventId',
                isEqualTo: widget.eventId,
              ) // Используйте правильный идентификатор события
              .get();

      return snapshot.docs.map((doc) => doc['email'] as String).toList();
    } catch (e) {
      print("Ошибка загрузки участников: $e");
      return [];
    }
  }

  Future<String?> _getEmailByUserId(String userId) async {
    try {
      DocumentSnapshot doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();
      return doc.get('email') as String?;
    } catch (e) {
      print('Error getting email: $e');
      return null;
    }
  }

  void _removeParticipant(String email) async {
    String? userId = await _getUserIdByEmail(email);
    if (userId != null && participants.contains(userId)) {
      setState(() {
        participants.remove(userId);
      });
      Toast.show('Участник $email удалён');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Создать/Редактировать мероприятие'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveEvent, // Вызов метода сохранения
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Загрузка обложки
              GestureDetector(
                onTap: () async {
                  await selectImageGallery();
                },
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    image:
                        selectImage != null
                            ? DecorationImage(
                              image: FileImage(File(selectImage!.path)),
                              fit: BoxFit.cover,
                            )
                            : null,
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo, size: 50),
                      Text('Добавить обложку'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Название мероприятия
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Название мероприятия',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите название';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Описание
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Описание',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Дата и время
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Дата',
                          border: OutlineInputBorder(),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedDate == null
                                  ? 'Выберите дату'
                                  : '${_selectedDate!.day}.${_selectedDate!.month}.${_selectedDate!.year}',
                            ),
                            const Icon(Icons.calendar_today),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Время',
                          border: OutlineInputBorder(),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedTime == null
                                  ? 'Выберите время'
                                  : _selectedTime!.format(context),
                            ),
                            const Icon(Icons.access_time),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Местоположение
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Местоположение',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Укажите место';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _quantityParticipantsController,
                decoration: const InputDecoration(
                  labelText: 'Количество участников',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (int.tryParse(value) == null) {
                      return 'Введите число';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Категория
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Категория',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Концерт', child: Text('Концерт')),
                  DropdownMenuItem(
                    value: 'Вечеринка',
                    child: Text('Вечеринка'),
                  ),
                  DropdownMenuItem(value: 'Спорт', child: Text('Спорт')),
                  DropdownMenuItem(value: 'Выставка', child: Text('Выставка')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Выберите категорию';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Приватность
              SwitchListTile(
                title: const Text('Приватное мероприятие'),
                value: _isPrivate,
                onChanged: (bool value) {
                  setState(() {
                    _isPrivate = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Поле для ввода участников
              TextFormField(
                controller: _participantsController,
                decoration: const InputDecoration(
                  labelText: 'Добавить участника (email/username)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _addParticipant,
                child: const Text('Добавить участника'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _participantsController.dispose(); // Освобождение контроллера участников
    super.dispose();
  }
}
