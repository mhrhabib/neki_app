import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads a file to Firebase Storage and returns the download URL.
  Future<String?> uploadFile({required File file, required String path, Map<String, String>? metadata}) async {
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = ref.putFile(file, SettableMetadata(customMetadata: metadata));

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ [FirebaseStorage] Upload Error: $e');
      return null;
    }
  }

  /// Uploads raw data (bytes) and returns the download URL.
  Future<String?> uploadData({required Uint8List data, required String path, String? contentType}) async {
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = ref.putData(data, SettableMetadata(contentType: contentType));

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ [FirebaseStorage] Data Upload Error: $e');
      return null;
    }
  }

  /// Deletes a file from Firebase Storage.
  Future<bool> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
      return true;
    } catch (e) {
      debugPrint('❌ [FirebaseStorage] Delete Error: $e');
      return false;
    }
  }

  /// Gets a reference to a path.
  Reference getRef(String path) => _storage.ref().child(path);
}
