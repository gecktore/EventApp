import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

class EventAttachmentsScreen extends StatefulWidget {
  final String eventId;
  final String creatorId;

  const EventAttachmentsScreen({
    Key? key,
    required this.eventId,
    required this.creatorId,
  }) : super(key: key);

  @override
  _EventAttachmentsScreenState createState() => _EventAttachmentsScreenState();
}

class _EventAttachmentsScreenState extends State<EventAttachmentsScreen> {
  List<Map<String, dynamic>> _attachments = [];
  bool _isLoading = true;
  bool _isCreator = false;

  @override
  void initState() {
    super.initState();
    _loadAttachments();
    _checkIfCreator();
  }

  Future<void> _checkIfCreator() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    setState(() {
      _isCreator =
          currentUserId ==
          widget.creatorId; // Сравниваем с идентификатором организатора
    });
  }

  Future<void> _loadAttachments() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('events_attachment')
              .where('event_id', isEqualTo: widget.eventId)
              .get();

      final attachments = await Future.wait(
        snapshot.docs.map((doc) async {
          final filepath = doc['filepath'] as String;
          final filename = _extractFilenameFromUrl(filepath);

          return {
            'id': doc.id,
            'filepath': filepath,
            'filename': filename,
            'extension': filename.split('.').last.toLowerCase(),
            'uploaded_at': doc['uploaded_at'],
          };
        }),
      );

      setState(() {
        _attachments = attachments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки вложений: ${e.toString()}')),
      );
    }
  }

  String _extractFilenameFromUrl(String url) {
    try {
      // Удаляем параметры запроса после знака ?
      final path = url.split('?')[0];
      // Берем последнюю часть пути после /
      final fullFileName = path.split('/').last;
      final doneFileName =
          fullFileName.length > 37 ? fullFileName.substring(36) : fullFileName;
      return doneFileName; // Возвращаем полное имя файла
    } catch (e) {
      return 'Файл';
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Нет данных';

    final date =
        timestamp is Timestamp
            ? timestamp.toDate()
            : DateTime.parse(timestamp.toString());
    return '${date.day}.${date.month}.${date.year}';
  }

  Future<void> openFile(String fileUrl) async {
    try {
      // Скачать файл во временную директорию
      final tempDir = await getTemporaryDirectory();
      final fileName = fileUrl.substring(fileUrl.lastIndexOf('/') + 1);
      final filePath = '${tempDir.path}/$fileName';

      // Для Firebase Storage:
      final ref = FirebaseStorage.instance.refFromURL(fileUrl);
      final file = File(filePath);
      await ref.writeToFile(file);

      // Открыть файл
      final result = await OpenFile.open(filePath);

      if (result.type != ResultType.done) {
        throw Exception('Не удалось открыть файл');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: ${e.toString()}')));
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.any,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final fileName = file.name;
    final fileBytes = file.bytes;
    final filePath = file.path;

    if (fileName.isEmpty || (fileBytes == null && filePath == null)) return;

    setState(() => _isLoading = true);

    try {
      final storageRef = FirebaseStorage.instance.ref().child(
        'event_attachments/${widget.eventId}/$fileName',
      );

      if (filePath != null) {
        await storageRef.putFile(File(filePath!));
      } else {
        await storageRef.putData(fileBytes!);
      }

      final downloadUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance.collection('events_attachment').add({
        'event_id': widget.eventId,
        'filepath': downloadUrl,
        'uploaded_at': FieldValue.serverTimestamp(),
      });

      await _loadAttachments();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки файла: ${e.toString()}')),
      );
    }
  }

  Future<void> _removeAttachment(String id) async {
    try {
      setState(() => _isLoading = true);
      await FirebaseFirestore.instance
          .collection('events_attachment')
          .doc(id)
          .delete();
      await _loadAttachments();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка удаления вложения: ${e.toString()}')),
      );
    }
  }

  IconData _getFileIcon(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'zip':
      case 'rar':
        return Icons.archive;
      case 'txt':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Вложения мероприятия')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _attachments.isEmpty
              ? const Center(child: Text('Нет прикрепленных файлов'))
              : ListView.builder(
                itemCount: _attachments.length,
                itemBuilder: (context, index) {
                  final attachment = _attachments[index];
                  return ListTile(
                    leading: Icon(_getFileIcon(attachment['extension'])),
                    title: Text(attachment['filename']),
                    subtitle: Text(
                      'Добавлено: ${_formatDate(attachment['uploaded_at'])}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    trailing:
                        _isCreator // Показываем кнопку удаления только организатору
                            ? IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed:
                                  () => _removeAttachment(attachment['id']),
                            )
                            : null, // Участники не видят кнопку удаления
                    onTap: () async {
                      await openFile(attachment['filepath']);
                    },
                  );
                },
              ),
      floatingActionButton:
          _isCreator // Показываем кнопку добавления только организатору
              ? FloatingActionButton(
                child: const Icon(Icons.add),
                onPressed: _pickFile,
              )
              : null, // Участники не видят кнопку добавления
    );
  }
}
