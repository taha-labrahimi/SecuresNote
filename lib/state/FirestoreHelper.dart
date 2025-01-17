import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:secure_notes_app/state/note.dart';

class FirestoreHelper {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add a user to Firestore
  Future<void> createUser(String email, String username, String password) async {
    await _firestore.collection('users').doc(email).set({
      'email': email,
      'username': username,
      'password': password, // For simplicity, hash it before saving
    });
  }

  // Get user details by email
  Future<Map<String, dynamic>?> getUser(String email) async {
    final userDoc = await _firestore.collection('users').doc(email).get();
    if (userDoc.exists) {
      return userDoc.data();
    }
    return null;
  }

  // Add a note to Firestore
  Future<void> addNote(Note note) async {
    await _firestore.collection('notes').add(note.toMap());
  }

  // Get all notes for a specific user
  Future<List<Note>> getNotes(String userId) async {
    final querySnapshot = await _firestore
        .collection('notes')
        .where('userId', isEqualTo: userId)
        .get();
    return querySnapshot.docs.map((doc) {
      return Note.fromMap(doc.id, doc.data());
    }).toList();
  }

  // Update an existing note by ID
  Future<void> updateNote(Note note) async {
    if (note.id == null) {
      throw Exception("Note ID is required for updating.");
    }
    await _firestore.collection('notes').doc(note.id).update(note.toMap());
  }

  // Delete a note by ID
  Future<void> deleteNote(String noteId) async {
    await _firestore.collection('notes').doc(noteId).delete();
  }

  // Get a specific note by ID
  Future<Note?> getNoteById(String noteId) async {
    final doc = await _firestore.collection('notes').doc(noteId).get();
    if (doc.exists) {
      return Note.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    }
    return null;
  }
}
