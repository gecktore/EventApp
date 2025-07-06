import 'dart:io';
import 'package:cross_file/cross_file.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ImageStorage {
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;

  Future<String?> addImageProfileStorage(XFile path) async {
    try {
      // Уникальный путь для хранения изображения
      final String pathImage =
          'userLogo/${DateTime.now().millisecondsSinceEpoch}_${path.name}';
      Reference storageReference = _firebaseStorage.ref().child(pathImage);

      // Загрузка изображения
      UploadTask uploadTask = storageReference.putFile(File(path.path));
      TaskSnapshot taskSnapshot = await uploadTask;

      // Получение URL загруженного изображения
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      return downloadUrl; // Возвращаем URL загруженного изображения
    } catch (e) {
      print("Error uploading image: $e");
      return null; // Возвращаем null в случае ошибки
    }
  }

  Future<String?> addImageEventStorage(XFile path) async {
    try {
      // Уникальный путь для хранения изображения
      final String pathImage =
          'eventLogo/${DateTime.now().millisecondsSinceEpoch}_${path.name}';
      Reference storageReference = _firebaseStorage.ref().child(pathImage);

      // Загрузка изображения
      UploadTask uploadTask = storageReference.putFile(File(path.path));
      TaskSnapshot taskSnapshot = await uploadTask;

      // Получение URL загруженного изображения
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      return downloadUrl; // Возвращаем URL загруженного изображения
    } catch (e) {
      print("Error uploading image: $e");
      return null; // Возвращаем null в случае ошибки
    }
  }
}
