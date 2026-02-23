import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Generic method to add data to a collection.
  Future<String?> addDocument({required String collectionPath, required Map<String, dynamic> data}) async {
    try {
      final docRef = await _db.collection(collectionPath).add(data);
      return docRef.id;
    } catch (e) {
      debugPrint('❌ [Firestore] Add Document Error: $e');
      return null;
    }
  }

  /// Generic method to set (create or overwrite) data at a specific document path.
  Future<bool> setDocument({
    required String collectionPath,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _db.collection(collectionPath).doc(documentId).set(data);
      return true;
    } catch (e) {
      debugPrint('❌ [Firestore] Set Document Error: $e');
      return false;
    }
  }

  /// Generic method to update existing document fields.
  Future<bool> updateDocument({
    required String collectionPath,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _db.collection(collectionPath).doc(documentId).update(data);
      return true;
    } catch (e) {
      debugPrint('❌ [Firestore] Update Document Error: $e');
      return false;
    }
  }

  /// Generic method to get a document by ID.
  Future<DocumentSnapshot<Map<String, dynamic>>?> getDocument({
    required String collectionPath,
    required String documentId,
  }) async {
    try {
      return await _db.collection(collectionPath).doc(documentId).get();
    } catch (e) {
      debugPrint('❌ [Firestore] Get Document Error: $e');
      return null;
    }
  }

  /// Stream of a document's data.
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamDocument({
    required String collectionPath,
    required String documentId,
  }) {
    return _db.collection(collectionPath).doc(documentId).snapshots();
  }

  /// Stream of a collection's data with optional filtering.
  Stream<QuerySnapshot<Map<String, dynamic>>> streamCollection({
    required String collectionPath,
    Query<Map<String, dynamic>> Function(Query<Map<String, dynamic>> query)? queryBuilder,
  }) {
    Query<Map<String, dynamic>> query = _db.collection(collectionPath);
    if (queryBuilder != null) {
      query = queryBuilder(query);
    }
    return query.snapshots();
  }

  /// Generic method to get a collection's data with optional filtering as a Future.
  Future<QuerySnapshot<Map<String, dynamic>>> getCollection({
    required String collectionPath,
    Query<Map<String, dynamic>> Function(Query<Map<String, dynamic>> query)? queryBuilder,
  }) async {
    Query<Map<String, dynamic>> query = _db.collection(collectionPath);
    if (queryBuilder != null) {
      query = queryBuilder(query);
    }
    return await query.get();
  }

  /// Deletes a document.
  Future<bool> deleteDocument({required String collectionPath, required String documentId}) async {
    try {
      await _db.collection(collectionPath).doc(documentId).delete();
      return true;
    } catch (e) {
      debugPrint('❌ [Firestore] Delete Document Error: $e');
      return false;
    }
  }

  FirebaseFirestore get instance => _db;
}
