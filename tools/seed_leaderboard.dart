/// Standalone seed script — run with: dart run tools/seed_leaderboard.dart
///
/// Creates `users` and `users_points` Firestore documents for your existing
/// Bangladeshi accounts using the Firebase Auth + Firestore REST APIs.
///
/// Setup:
///   1. Deploy firestore.rules first:  firebase deploy --only firestore:rules
///   2. Set WEB_API_KEY below (Firebase Console > Project Settings > Web API key)
///   3. Fill in the real email/password for each account in seedUsers
///   4. Run: dart run tools/seed_leaderboard.dart
library;

import 'dart:convert';
import 'dart:io';

// ─── CONFIG ────────────────────────────────────────────────────────────────
const String projectId = 'nekiapp-52446';

/// Firebase Web API Key — find it at:
/// Firebase Console > Project Settings > General > "Web API key"
const String webApiKey = 'YOUR_FIREBASE_WEB_API_KEY';

/// Your existing Bangladeshi accounts. Each must already exist in Firebase Auth.
/// Fill in real email/password pairs before running.
const List<Map<String, dynamic>> seedUsers = [
  {
    'email': 'user1@example.com',
    'password': 'Password123!',
    'name': 'User One',
    'country': 'Bangladesh',
    'totalPoints': 0,
  },
  // Add more accounts here:
  // {
  //   'email': 'user2@example.com',
  //   'password': 'Password123!',
  //   'name': 'User Two',
  //   'country': 'Bangladesh',
  //   'totalPoints': 0,
  // },
];
// ─── END CONFIG ─────────────────────────────────────────────────────────────

final HttpClient _httpClient = HttpClient();

Future<Map<String, dynamic>> _post(String url, Map<String, dynamic> body) async {
  final uri = Uri.parse(url);
  final request = await _httpClient.postUrl(uri);
  request.headers.set('Content-Type', 'application/json');
  request.write(jsonEncode(body));
  final response = await request.close();
  final responseBody = await response.transform(utf8.decoder).join();
  return jsonDecode(responseBody) as Map<String, dynamic>;
}

Future<Map<String, dynamic>> _patch(
    String url, Map<String, dynamic> body, String idToken) async {
  final uri = Uri.parse(url);
  final request = await _httpClient.patchUrl(uri);
  request.headers.set('Content-Type', 'application/json');
  request.headers.set('Authorization', 'Bearer $idToken');
  request.write(jsonEncode(body));
  final response = await request.close();
  final responseBody = await response.transform(utf8.decoder).join();
  return jsonDecode(responseBody) as Map<String, dynamic>;
}

Future<Map<String, String>> _signIn(String email, String password) async {
  print('  Signing in as $email...');
  final result = await _post(
    'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$webApiKey',
    {'email': email, 'password': password, 'returnSecureToken': true},
  );
  if (result.containsKey('error')) {
    throw Exception('Auth failed for $email: ${result['error']}');
  }
  return {
    'idToken': result['idToken'] as String,
    'uid': result['localId'] as String,
  };
}

Map<String, dynamic> _firestoreValue(dynamic value) {
  if (value is String) return {'stringValue': value};
  if (value is int) return {'integerValue': value.toString()};
  if (value is double) return {'doubleValue': value};
  if (value is bool) return {'booleanValue': value};
  if (value == null) return {'nullValue': null};
  throw ArgumentError('Unsupported type: ${value.runtimeType}');
}

Future<void> _writeDoc({
  required String collection,
  required String docId,
  required Map<String, dynamic> data,
  required String idToken,
}) async {
  final url =
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/$collection/$docId';
  final body = {
    'fields': data.map((k, v) => MapEntry(k, _firestoreValue(v))),
  };
  final result = await _patch(url, body, idToken);
  if (result.containsKey('error')) {
    throw Exception('Firestore write failed ($collection/$docId): ${result['error']}');
  }
  print('    ✅ Written $collection/$docId');
}

Future<void> main() async {
  if (webApiKey == 'YOUR_FIREBASE_WEB_API_KEY') {
    print('ERROR: Set webApiKey before running.');
    print('Find it at: Firebase Console > Project Settings > General > Web API key');
    exit(1);
  }

  print('=== Leaderboard Seed Script ===');
  print('Project: $projectId');
  print('Seeding ${seedUsers.length} user(s)...\n');

  for (final user in seedUsers) {
    final email = user['email'] as String;
    final password = user['password'] as String;
    final name = user['name'] as String;
    final country = user['country'] as String;
    final totalPoints = user['totalPoints'] as int;

    print('Processing: $name ($email)');

    try {
      final auth = await _signIn(email, password);
      final uid = auth['uid']!;
      final idToken = auth['idToken']!;
      final now = DateTime.now().toIso8601String();

      await _writeDoc(
        collection: 'users',
        docId: uid,
        data: {
          'name': name,
          'email': email,
          'photoUrl': '',
          'country': country,
          'createdAt': now,
        },
        idToken: idToken,
      );

      await _writeDoc(
        collection: 'users_points',
        docId: uid,
        data: {
          'userId': uid,
          'totalPoints': totalPoints,
          'todayPoints': 0,
          'weekPoints': 0,
          'monthPoints': 0,
          'currentStreak': 0,
          'longestStreak': 0,
          'lastActiveDate': now,
        },
        idToken: idToken,
      );

      print('  Done: $name\n');
    } catch (e) {
      print('  ERROR for $name: $e\n');
    }
  }

  print('=== Seed complete ===');
  _httpClient.close();
}
