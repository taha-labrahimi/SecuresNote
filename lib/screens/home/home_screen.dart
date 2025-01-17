import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../home/note_editor_screen.dart';
import 'SettingsScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _notes = [];
  List<Map<String, dynamic>> _filteredNotes = [];
  String _currentUser = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentUser().then((_) {
      _loadNotes();
    });
  }

  Future<void> _loadCurrentUser() async {
    final user = _auth.currentUser;
    setState(() {
      _currentUser = user?.uid ?? '';
      debugPrint("Current user ID: $_currentUser");
    });
  }

  Future<void> _loadNotes() async {
    if (_currentUser.isNotEmpty) {
      try {
        final querySnapshot = await _firestore
            .collection('notes')
            .where('userId', isEqualTo: _currentUser)
            .orderBy('createdAt', descending: true)
            .get();

        setState(() {
          _notes = querySnapshot.docs
              .map((doc) => {
                    'id': doc.id,
                    ...doc.data(),
                  })
              .toList();
          _filteredNotes = _notes;
        });

        debugPrint("Loaded notes: $_notes");
      } catch (e) {
        debugPrint("Error loading notes: $e");
      }
    }
  }

  Future<void> _saveNoteToFirestore(
      String? noteId, String title, String content,
      {String? pin}) async {
    try {
      print('Current User ID: $_currentUser');
      print(
          'Note Data: {title: $title, content: $content, userId: $_currentUser}');

      if (noteId == null) {
        // Add new note
        await _firestore.collection('notes').add({
          'title': title,
          'content': content,
          'userId': _currentUser,
          'createdAt': Timestamp.now(),
          'pin': pin,
        });
        debugPrint("New note added: title = $title, content = $content");
      } else {
        // Update existing note
        await _firestore.collection('notes').doc(noteId).update({
          'title': title,
          'content': content,
          'pin': pin,
        });
        debugPrint(
            "Note updated: ID = $noteId, title = $title, content = $content");
      }

      _loadNotes(); // Refresh notes after saving
    } catch (e) {
      debugPrint("Error saving note: $e");
    }
  }

  void _openEditor({Map<String, dynamic>? note}) {
    if (note != null && note['pin'] != null && note['pin'].isNotEmpty) {
      // If a PIN is set, show a dialog to enter the PIN
      final TextEditingController pinController = TextEditingController();
      showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              bool isValidPin = true;

              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Text(
                  'Enter PIN',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: pinController,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'Enter 4-digit PIN',
                        counterText: "",
                        errorText: isValidPin
                            ? null
                            // ignore: dead_code
                            : 'Invalid PIN. Please try again.',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.blue),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          isValidPin = value.length == 4;
                        });
                      },
                    ),
                  ],
                ),
                actions: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor:
                              isValidPin ? Colors.green : Colors.grey,
                        ),
                        onPressed: isValidPin
                            ? () {
                                if (pinController.text == note['pin']) {
                                  Navigator.of(context).pop();
                                  // Open the editor if the PIN is correct
                                  Get.to(() => NoteEditorScreen(
                                        noteId: note['id'],
                                        initialTitle: note['title'],
                                        initialContent: note['content'],
                                        initialPin: note['pin'],
                                        createdAt: note['createdAt']?.toDate(),
                                        onSave: (id, title, content, pin,
                                            {DateTime? reminder}) {
                                          if (title.isNotEmpty ||
                                              content.isNotEmpty) {
                                            _saveNoteToFirestore(
                                                id, title, content,
                                                pin: pin);

                                            if (reminder != null) {
                                              debugPrint(
                                                  'Reminder set for: $reminder');
                                              // Handle reminder-specific logic if needed
                                            }
                                          }
                                        },
                                      ));
                                } else {
                                  // Show error if the PIN is incorrect
                                  setState(() {
                                    isValidPin = false;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Incorrect PIN'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              }
                            : null, // Disable button if PIN is invalid
                        child: const Text('Submit',
                            style: TextStyle(color: Colors.black)),
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        },
      );
    } else {
      // If no PIN is set, directly open the editor
      Get.to(() => NoteEditorScreen(
            noteId: note?['id'],
            initialTitle: note?['title'],
            initialContent: note?['content'],
            initialPin: note?['pin'],
            createdAt: note?['createdAt']?.toDate(),
            onSave: (id, title, content, pin) {
              if (title.isNotEmpty || content.isNotEmpty) {
                _saveNoteToFirestore(id, title, content, pin: pin);
              }
            },
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9EB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildSearchBar(),
              const SizedBox(height: 20),
              Expanded(child: _buildListView()),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: "Add Note",
        onPressed: () => _openEditor(),
        backgroundColor: const Color(0xFFF7C242),
        child: const Icon(Icons.add_rounded, size: 40, color: Colors.black),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Notes',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () => Get.to(() => const SettingsScreen()),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      onChanged: (query) {
        setState(() {
          _filteredNotes = _notes
              .where((note) =>
                  note['title'].toLowerCase().contains(query.toLowerCase()) ||
                  note['content'].toLowerCase().contains(query.toLowerCase()))
              .toList();
        });
      },
    );
  }

  // Delete a note from Firestore
  Future<void> _deleteNoteFromFirestore(String noteId) async {
    try {
      await _firestore.collection('notes').doc(noteId).delete();
      debugPrint("Note deleted: ID = $noteId");
      _loadNotes(); // Refresh the notes list
    } catch (e) {
      debugPrint("Error deleting note: $e");
    }
  }

  Widget _buildListView() {
    final groupedNotes = _groupNotesByDate();

    return ListView.builder(
      itemCount: groupedNotes.keys.length,
      itemBuilder: (context, sectionIndex) {
        final section = groupedNotes.keys.elementAt(sectionIndex);
        final notes = groupedNotes[section]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Text(
                section,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            // Notes for this section
            ...notes.map((note) {
              final bool isLocked =
                  note['pin'] != null && note['pin'].isNotEmpty;

              return Dismissible(
                key: UniqueKey(),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  _deleteNoteFromFirestore(note['id']);
                },
                background: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                child: GestureDetector(
                  onTap: () {
                    _openEditor(note: note); // Open editor on tap
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 4,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title of the note
                        Text(
                          note['title'] ?? 'Untitled Note',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Content or Locked Message
                        Row(
                          children: [
                            if (isLocked)
                              const Icon(Icons.lock, color: Colors.redAccent),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isLocked
                                    ? 'This note is locked. Tap to unlock.'
                                    : note['content'] ??
                                        'No content available.',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isLocked
                                      ? Colors.redAccent
                                      : Colors.grey.shade700,
                                  fontStyle: isLocked
                                      ? FontStyle.italic
                                      : FontStyle.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  /// Group notes by "Today," "Yesterday," and "Previous 7 Days"
  Map<String, List<Map<String, dynamic>>> _groupNotesByDate() {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    final lastWeek = today.subtract(const Duration(days: 7));

    final groupedNotes = <String, List<Map<String, dynamic>>>{
      'Today': [],
      'Yesterday': [],
      'Previous 7 Days': [],
      'Older': [],
    };

    for (var note in _filteredNotes) {
      final noteDate = note['createdAt'].toDate();
      if (isSameDay(noteDate, today)) {
        groupedNotes['Today']!.add(note);
      } else if (isSameDay(noteDate, yesterday)) {
        groupedNotes['Yesterday']!.add(note);
      } else if (noteDate.isAfter(lastWeek)) {
        groupedNotes['Previous 7 Days']!.add(note);
      } else {
        groupedNotes['Older']!.add(note);
      }
    }

    // Remove empty sections
    groupedNotes.removeWhere((key, value) => value.isEmpty);
    return groupedNotes;
  }

  /// Helper to check if two dates are the same day
  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
