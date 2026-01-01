import 'package:firebase_database/firebase_database.dart';
import 'package:wecinema/services/auth_service.dart';
import 'dart:math';

class RoomService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final AuthService _auth = AuthService();

  // Generate a random 6-digit room code
  String _generateRoomCode() {
    var r = Random();
    return List.generate(6, (index) => r.nextInt(10)).join();
  }

  // Create a new room
  Future<String> createRoom({
    required String fileId,
    required String fileName,
    required String videoUrl,
    bool isDriveFile = true,
  }) async {
    final user = _auth.currentUser;
    if (user == null)
      throw Exception('User must be signed in to create a room');

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
        'source': isDriveFile ? 'drive' : 'upload',
      },
      'playback': {
        'position': 0,
        'isPlaying': false,
        'updatedAt': ServerValue.timestamp,
      },
      'participants': {
        user.uid: {
          'name': user.displayName ?? 'Host',
          'photoUrl': user.photoURL,
          'status': 'online',
        }
      }
    });

    return roomId;
  }

  // Join a room
  Future<void> joinRoom(String roomId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User must be signed in to join');

    DatabaseReference roomRef = _db.ref('rooms/$roomId');
    final snapshot = await roomRef.get();

    if (!snapshot.exists) {
      throw Exception('Room not found');
    }

    // Add participant
    await roomRef.child('participants/${user.uid}').set({
      'name': user.displayName ?? 'Guest',
      'photoUrl': user.photoURL,
      'status': 'online',
    });
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
}
