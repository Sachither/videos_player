import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:wecinema/services/auth_service.dart';
import 'dart:math';

class RoomService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final AuthService _auth = AuthService();

  dynamic get currentUser => _auth.currentUser;

  // Generate a random 6-digit room code
  String _generateRoomCode() {
    var r = Random();
    return List.generate(6, (index) => r.nextInt(10)).join();
  }

  // Expanded Identity pools (15 unique pairs)
  final List<String> _randomNames = [
    'Cool Cat',
    'Fast Fox',
    'Strong Bear',
    'Wise Owl',
    'Happy Hippo',
    'Silent Shark',
    'Brave Bison',
    'Lazy Lizard',
    'Magic Monkey',
    'Quick Quokka',
    'Daring Deer',
    'Epic Eagle',
    'Funky Frog',
    'Glitzy Giraffe',
    'Sunny Seal'
  ];

  // Create a new room
  Future<String> createRoom({
    required String fileId,
    required String fileName,
    required String videoUrl,
    String? posterUrl,
    bool isDriveFile = true,
  }) async {
    User? user = _auth.currentUser;
    if (user == null) {
      debugPrint('🪄 No user found, performing silent anonymous sign-in...');
      final creds = await _auth.signInAnonymously();
      user = creds?.user;
    }

    if (user == null) {
      throw Exception(
          'Failed to sign in anonymously. Please check your connection.');
    }

    String roomId = _generateRoomCode();
    DatabaseReference roomRef = _db.ref('rooms/$roomId');

    // Check if room already exists (collision) - simplified for MVP
    // In production, we'd loop until unique.

    await roomRef.set({
      'hostIds': {user.uid: true},
      'status': 'waiting', // waiting, playing, paused
      'createdAt': ServerValue.timestamp,
      'movie': {
        'id': fileId,
        'title': fileName,
        'url': videoUrl,
        'posterUrl': posterUrl,
        'source': isDriveFile ? 'drive' : 'upload',
      },
      'playback': {
        'position': 0,
        'isPlaying': false,
        'updatedAt': ServerValue.timestamp,
      },
      'participants': {
        user.uid: {
          'name': user.displayName ??
              _randomNames[Random().nextInt(_randomNames.length)],
          'photoUrl': user.photoURL,
          'status': 'online',
          'iconIndex': Random().nextInt(15),
        }
      },
      'settings': {
        'closeOnExit': true,
        'autoTransferOwnership': false,
      }
    });

    return roomId;
  }

  // Join a room
  Future<void> joinRoom(String roomId) async {
    User? user = _auth.currentUser;
    if (user == null) {
      debugPrint('🪄 Guest user detected, joining anonymously...');
      final creds = await _auth.signInAnonymously();
      user = creds?.user;
    }

    if (user == null) {
      throw Exception('Anonymous sign-in failed. Cannot join room.');
    }

    DatabaseReference roomRef = _db.ref('rooms/$roomId');
    final snapshot = await roomRef.get();

    if (!snapshot.exists) {
      throw Exception('Room not found');
    }

    // Check capacity (Max 5)
    final participants = snapshot.child('participants').value as Map?;
    if (participants != null && participants.length >= 5) {
      throw Exception('Room is full (Max 5 participants)');
    }

    // Add participant with random identity if no name exists
    String participantName =
        user.displayName ?? _randomNames[Random().nextInt(_randomNames.length)];

    await roomRef.child('participants/${user.uid}').set({
      'name': participantName,
      'photoUrl': user.photoURL,
      'status': 'online',
      'iconIndex': Random().nextInt(15),
    });
  }

  // Get a specific room snapshot
  DatabaseReference getRoom(String roomId) {
    return _db.ref('rooms/$roomId');
  }

  // Listen to room updates
  Stream<DatabaseEvent> getRoomStream(String roomId) {
    return _db.ref('rooms/$roomId').onValue;
  }

  // Update playback state (Host only)
  Future<void> updatePlayback({
    required String roomId,
    required bool isPlaying,
    required int positionMs,
  }) async {
    await _db.ref('rooms/$roomId/playback').update({
      'isPlaying': isPlaying,
      'position': positionMs,
      'updatedAt': ServerValue.timestamp,
    });
  }

  // Update room status (e.g., from 'waiting' to 'playing')
  Future<void> updateRoomStatus(String roomId, String status) async {
    await _db.ref('rooms/$roomId').update({'status': status});
  }

  // Update local buffer status for a user
  Future<void> updateUserBuffer({
    required String roomId,
    required String userId,
    required int bufferSecs,
  }) async {
    await _db.ref('rooms/$roomId/participants/$userId').update({
      'bufferSecs': bufferSecs,
    });
  }

  // Update room settings (Host only) - with exclusivity
  Future<void> updateRoomSettings(
      String roomId, Map<String, dynamic> settings) async {
    final ref = _db.ref('rooms/$roomId/settings');

    // Logic for mutual exclusivity
    if (settings.containsKey('closeOnExit') &&
        settings['closeOnExit'] == true) {
      settings['autoTransferOwnership'] = false;
    } else if (settings.containsKey('autoTransferOwnership') &&
        settings['autoTransferOwnership'] == true) {
      settings['closeOnExit'] = false;
    }

    await ref.update(settings);
  }

  // Chat logic
  Future<void> sendMessage(String roomId, String text) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final roomSnapshot = await getRoom(roomId).get();
    if (!roomSnapshot.exists) return;

    final participants = roomSnapshot.child('participants').value as Map?;
    final userData = participants?[user.uid] as Map?;

    await _db.ref('rooms/$roomId/messages').push().set({
      'senderId': user.uid,
      'senderName': userData?['name'] ?? 'User',
      'iconIndex': userData?['iconIndex'] ?? 0,
      'text': text,
      'timestamp': ServerValue.timestamp,
    });
  }

  Stream<DatabaseEvent> getChatStream(String roomId) {
    return _db.ref('rooms/$roomId/messages').orderByChild('timestamp').onValue;
  }

  // Leave a room
  Future<void> leaveRoom(String roomId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    DatabaseReference roomRef = _db.ref('rooms/$roomId');
    final snapshot = await roomRef.get();
    if (!snapshot.exists) return;

    final data = snapshot.value as Map;
    final Map? settings = data['settings'] as Map?;
    final Map? participants = data['participants'] as Map?;
    final Map? hostIds = data['hostIds'] as Map?;

    bool isHost = hostIds != null && hostIds.containsKey(user.uid);

    if (isHost) {
      bool closeOnExit = settings?['closeOnExit'] ?? true;
      bool autoTransfer = settings?['autoTransferOwnership'] ?? false;

      if (closeOnExit) {
        // Tag room as closed for cleanup (deleted after 3hrs by backend/observer)
        // For MVP, we can just delete, but setting 'expiresAt' allows background cleanup
        await roomRef.update({
          'closedAt': ServerValue.timestamp,
          'expiresAt':
              (DateTime.now().millisecondsSinceEpoch + (3 * 60 * 60 * 1000)),
        });
        await roomRef.remove(); // Direct removal for now to keep it simple
      } else if (autoTransfer &&
          participants != null &&
          participants.length > 1) {
        // Transfer ownership to another participant
        String? nextHostUid;
        participants.forEach((key, value) {
          if (key != user.uid && nextHostUid == null) {
            nextHostUid = key;
          }
        });

        if (nextHostUid != null) {
          await roomRef.child('hostIds').update({nextHostUid!: true});
          await roomRef.child('hostIds/${user.uid}').remove();
          await roomRef.child('participants/${user.uid}').remove();
        } else {
          // No one left, delete
          await roomRef.remove();
        }
      } else {
        // Just leave, but room stays
        await roomRef.child('participants/${user.uid}').remove();
        await roomRef.child('hostIds/${user.uid}').remove();
      }
    } else {
      // Just a guest leaving
      await roomRef.child('participants/${user.uid}').remove();
    }
  }
}
