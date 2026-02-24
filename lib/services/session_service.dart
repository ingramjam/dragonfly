import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

final firebaseDatabaseProvider = Provider((_) => FirebaseDatabase.instance);

// Provides a stream of the current session state from Firebase.
final sessionServiceProvider = StreamProvider.family<SessionState, String>((ref, sessionId) {
  final db = ref.watch(firebaseDatabaseProvider);
  final controller = StreamController<SessionState>();

  final sessionRef = db.ref('sessions/$sessionId');
  final subscription = sessionRef.onValue.listen((event) {
    if (event.snapshot.exists) {
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      controller.add(SessionState.fromMap(data));
    }
  });

  ref.onDispose(() {
    subscription.cancel();
    controller.close();
  });

  return controller.stream;
});

// Represents the state of a session.
class SessionState {
  final String id;
  final String hostId;
  final List<String> joinedUsers;

  SessionState({required this.id, required this.hostId, this.joinedUsers = const []});

  factory SessionState.fromMap(Map<String, dynamic> map) {
    return SessionState(
      id: map['id'],
      hostId: map['hostId'],
      joinedUsers: List<String>.from(map['joinedUsers'] ?? []),
    );
  }
}

// Manages creating and joining sessions in Firebase.
class SessionManager {
  final FirebaseDatabase _db;
  final String _userId;

  SessionManager(this._db, this._userId);

  // Creates a new session in Firebase.
  Future<String> createSession() async {
    final sessionId = const Uuid().v4();
    final sessionRef = _db.ref('sessions/$sessionId');
    await sessionRef.set({
      'id': sessionId,
      'hostId': _userId,
      'joinedUsers': [_userId],
    });
    return sessionId;
  }

  // Joins an existing session.
  Future<void> joinSession(String sessionId) async {
    final sessionRef = _db.ref('sessions/$sessionId/joinedUsers');
    final snapshot = await sessionRef.get();
    final List<String> users = snapshot.exists ? List<String>.from(snapshot.value as List) : [];
    if (!users.contains(_userId)) {
      users.add(_userId);
      await sessionRef.set(users);
    }
  }
}
