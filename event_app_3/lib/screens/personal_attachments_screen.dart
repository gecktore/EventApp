import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PersonalAttachmentsScreen extends StatefulWidget {
  final String eventId;

  const PersonalAttachmentsScreen({Key? key, required this.eventId})
    : super(key: key);

  @override
  _PersonalAttachmentsScreenState createState() =>
      _PersonalAttachmentsScreenState();
}

class _PersonalAttachmentsScreenState extends State<PersonalAttachmentsScreen> {
  List<Map<String, dynamic>> _attachments = [];
  bool _isLoading = true;
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadAttachments();
  }

  Future<void> _loadAttachments() async {
    try {
      if (currentUser == null) return;

      final snapshot =
          await FirebaseFirestore.instance
              .collection('personal_event_attachments')
              .where('event_id', isEqualTo: widget.eventId)
              .where('user_id', isEqualTo: currentUser!.uid)
              .orderBy('uploaded_at', descending: true)
              .get();

      setState(() {
        _attachments =
            snapshot.docs.map((doc) {
              return {
                'id': doc.id,
                'filepath': doc['filepath'],
                'filename': _extractFilenameFromUrl(doc['filepath']),
                'extension':
                    _extractFilenameFromUrl(
                      doc['filepath'],
                    ).split('.').last.toLowerCase(),
                'uploaded_at': doc['uploaded_at'],
              };
            }).toList();
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
          fullFileName.length > 77 ? fullFileName.substring(76) : fullFileName;
      return doneFileName; // Возвращаем полное имя файла
    } catch (e) {
      return 'Файл';
    }
  }

  Future<void> openFile(String fileUrl) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = fileUrl.substring(fileUrl.lastIndexOf('/') + 1);
      final filePath = '${tempDir.path}/$fileName';

      final ref = FirebaseStorage.instance.refFromURL(fileUrl);
      final file = File(filePath);
      await ref.writeToFile(file);

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
    if (currentUser == null) return;

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
        'personal_event_attachments/${widget.eventId}/${currentUser!.uid}/$fileName',
      );

      if (filePath != null) {
        await storageRef.putFile(File(filePath!));
      } else {
        await storageRef.putData(fileBytes!);
      }

      final downloadUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('personal_event_attachments')
          .add({
            'event_id': widget.eventId,
            'user_id': currentUser!.uid,
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

      // Удаляем запись из Firestore
      await FirebaseFirestore.instance
          .collection('personal_event_attachments')
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
      case 'mp4':
      case 'mov':
        return Icons.videocam;
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
      appBar: AppBar(title: const Text('Личные вложения')),
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
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _removeAttachment(attachment['id']),
                    ),
                    onTap: () => openFile(attachment['filepath']),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: _pickFile,
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Нет данных';

    final date =
        timestamp is Timestamp
            ? timestamp.toDate()
            : DateTime.parse(timestamp.toString());
    return '${date.day}.${date.month}.${date.year}';
  }
}
