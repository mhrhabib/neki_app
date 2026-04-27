import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/services/firestore_service.dart';
import '../../data/models/support_status_model.dart';

abstract class SupportRepository {
  Future<SupportStatus> getSupportStatus();
  Future<void> updateSupportStatus(SupportStatus status);
  Stream<SupportStatus> get supportStatusStream;

  Future<int> getRecordedSalahCount();
  Future<void> incrementSalahCount();

  Future<void> recordDonation({
    required String productId,
    required double amount,
    required String transactionId,
  });
}

class SupportRepositoryImpl implements SupportRepository {
  SupportRepositoryImpl(this._prefs, this._firestoreService) {
    _bootstrap();
  }

  final SharedPreferences _prefs;
  final FirestoreService _firestoreService;

  static const String _statusKey = 'support_status_v1';
  static const String _salahCountKey = 'total_salah_recorded';

  static const String _usersCollection = 'users';
  static const String _supportSubCollection = 'meta';
  static const String _supportDoc = 'support_status';
  static const String _donationsSubCollection = 'donations';

  final _statusController = StreamController<SupportStatus>.broadcast();
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _remoteSub;
  SupportStatus _current = const SupportStatus();

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Future<void> _bootstrap() async {
    _current = await _readLocal();
    _statusController.add(_current);

    FirebaseAuth.instance.authStateChanges().listen((user) {
      _remoteSub?.cancel();
      if (user == null) return;
      _attachRemoteListener(user.uid);
      unawaited(_reconcileOnLogin(user.uid));
    });
  }

  void _attachRemoteListener(String uid) {
    _remoteSub = _firestoreService
        .streamDocument(
          collectionPath: '$_usersCollection/$uid/$_supportSubCollection',
          documentId: _supportDoc,
        )
        .listen(
      (snap) {
        if (!snap.exists) return;
        final data = snap.data();
        if (data == null) return;
        final remote = SupportStatus.fromFirestore(data);
        _current = remote;
        _writeLocal(remote);
        _statusController.add(remote);
      },
      onError: (error, _) {
        debugPrint('❌ [Support] Remote listen error: $error');
      },
    );
  }

  /// When a user logs in, push the local cache up to Firestore if remote
  /// is missing — covers first-run and re-install scenarios. If remote
  /// exists and is newer, the stream listener above will overwrite local.
  Future<void> _reconcileOnLogin(String uid) async {
    try {
      final snap = await _firestoreService.getDocument(
        collectionPath: '$_usersCollection/$uid/$_supportSubCollection',
        documentId: _supportDoc,
      );
      if (snap == null || !snap.exists) {
        await _writeRemote(uid, _current);
      }
    } catch (e) {
      debugPrint('❌ [Support] Reconcile error: $e');
    }
  }

  Future<SupportStatus> _readLocal() async {
    final raw = _prefs.getString(_statusKey);
    if (raw == null) return const SupportStatus();
    try {
      return SupportStatus.fromJson(json.decode(raw));
    } catch (_) {
      return const SupportStatus();
    }
  }

  Future<void> _writeLocal(SupportStatus status) async {
    await _prefs.setString(_statusKey, json.encode(status.toJson()));
  }

  Future<void> _writeRemote(String uid, SupportStatus status) async {
    await _firestoreService.setDocument(
      collectionPath: '$_usersCollection/$uid/$_supportSubCollection',
      documentId: _supportDoc,
      data: status.toFirestore(),
    );
  }

  @override
  Future<SupportStatus> getSupportStatus() async {
    return _current;
  }

  @override
  Future<void> updateSupportStatus(SupportStatus status) async {
    _current = status;
    await _writeLocal(status);
    _statusController.add(status);

    final uid = _uid;
    if (uid != null) {
      await _writeRemote(uid, status);
    }
  }

  @override
  Stream<SupportStatus> get supportStatusStream => _statusController.stream;

  @override
  Future<int> getRecordedSalahCount() async {
    return _prefs.getInt(_salahCountKey) ?? 0;
  }

  @override
  Future<void> incrementSalahCount() async {
    final current = await getRecordedSalahCount();
    await _prefs.setInt(_salahCountKey, current + 1);
  }

  @override
  Future<void> recordDonation({
    required String productId,
    required double amount,
    required String transactionId,
  }) async {
    final updated = _current.copyWith(
      lastDonationDate: DateTime.now(),
      lastDonationAmount: amount,
      totalDonated: _current.totalDonated + amount,
      donationCount: _current.donationCount + 1,
      hasDeclinedRecently: false,
      lastDeclineDate: null,
    );
    await updateSupportStatus(updated);

    final uid = _uid;
    if (uid == null) return;

    // Immutable ledger for auditing / troubleshooting refunds.
    await _firestoreService.setDocument(
      collectionPath:
          '$_usersCollection/$uid/$_supportSubCollection/$_supportDoc/$_donationsSubCollection',
      documentId: transactionId,
      data: {
        'productId': productId,
        'amount': amount,
        'transactionId': transactionId,
        'createdAt': FieldValue.serverTimestamp(),
      },
    );
  }

  void dispose() {
    _remoteSub?.cancel();
    _statusController.close();
  }
}
