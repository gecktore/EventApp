import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileCollection {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  Future<void> addProfile(
    String id,
    String surname,
    String name,
    String patronymic,
    String? phone,
    String email,
    String password,
    String? description,
    String? image,
    String? username,
  ) async {
    try {
      CollectionReference profiles = _firebaseFirestore.collection('profiles');
      await profiles.doc(id).set({
        'uid': id,
        'surname': surname,
        'name': name,
        'patronymic': patronymic,
        'phone': phone,
        'email': email,
        'password': password,
        'description': description,
        'image': image,
        'username': username,
      });
    } catch (e) {
      print("Error adding profile: $e");
    }
  }

  Future<void> editImageProfile(dynamic docs, String image) async {
    try {
      await _firebaseFirestore.collection('profiles').doc(docs.id).update({
        'image': image,
      });
    } catch (e) {
      print("Error editing profile image: $e");
    }
  }

  Future<void> editProfile(
    dynamic docs,
    String surname,
    String name,
    String patronymic,
    String phone,
    String description,
    String username,
  ) async {
    try {
      await _firebaseFirestore.collection('profiles').doc(docs['uid']).update({
        'surname': surname,
        'name': name,
        'patronymic': patronymic,
        'phone': phone,
        'description': description,
        'username': username,
      });
    } catch (e) {
      print("Error editing profile: $e");
    }
  }

  Future<void> deleteProfile(dynamic docs) async {
    try {
      await _firebaseFirestore.collection('profiles').doc(docs.id).delete();
    } catch (e) {
      print("Error deleting profile: $e");
    }
  }
}
