import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class NoteEditorScreen extends StatefulWidget {
  final String? noteId; // Firestore's document ID format (String)
  final String? initialTitle;
  final String? initialContent;
  final String? initialPin;
  final DateTime? createdAt;
  final Function(String? id, String title, String content, String? pin) onSave;

  const NoteEditorScreen({
    super.key,
    this.noteId,
    this.initialTitle,
    this.initialContent,
    this.initialPin,
    this.createdAt,
    required this.onSave,
  });

  @override
  _NoteEditorScreenState createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String? _pin;
  bool _isSaving = false;
  late AnimationController _animationController;
  late Animation<Color?> _lockColorAnimation;
  late Animation<double> _lockSizeAnimation;

  @override
  void initState() {
    super.initState();
    _loadNoteData();
    _setupAnimations();
  }

  void _loadNoteData() {
    _titleController.text = widget.initialTitle ?? '';
    _contentController.text = widget.initialContent ?? '';
    _pin = widget.initialPin;
    print("Initial pin loaded: $_pin");
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _lockColorAnimation = ColorTween(
      begin: Colors.grey.shade400,
      end: Colors.green.shade400,
    ).animate(_animationController);

    _lockSizeAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  Future<void> _saveNote() async {
    if (_isSaving) return; // Prevent multiple saves
    if (_titleController.text.trim().isEmpty &&
        _contentController.text.trim().isEmpty) {
      // Skip saving if both title and content are empty
      print("Skipping save: Both title and content are empty.");
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final title = _titleController.text.trim();
      final content = _contentController.text.trim();

      print("Saving note: title = $title, content = $content, pin = $_pin");

      // Call the onSave function passed from the parent widget
      await widget.onSave(widget.noteId, title, content, _pin);

      print("Note saved successfully.");
    } catch (e) {
      print("Error saving note: $e");
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _togglePin() {
    if (_pin == null) {
      _showSetPinDialog();
    } else {
      _removePin();
    }
  }

  void _showSetPinDialog() {
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
              'Set a PIN',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: pinController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly, // Allow digits only
                    LengthLimitingTextInputFormatter(4), // Limit to 4 characters
                  ],
                  decoration: InputDecoration(
                    hintText: 'Enter a 4-digit PIN',
                    counterText: "",
                    // ignore: dead_code
                    errorText: isValidPin ? null : 'Invalid PIN. Enter 4 digits.',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.blue),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  obscureText: true,
                  onChanged: (value) {
                    setState(() {
                      isValidPin = value.length == 4; // Ensure exactly 4 digits
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
                      backgroundColor: isValidPin ? Colors.green : Colors.grey,
                    ),
                    onPressed: isValidPin
                        ? () {
                            final pin = pinController.text.trim();
                            setState(() {
                              _pin = pin;
                              _animationController.forward();
                            });
                            print("Pin set: $_pin");
                            Navigator.of(context).pop();
                          }
                        : null, // Disable button if PIN is invalid
                    child: const Text('Set', style: TextStyle(color: Colors.black)),
                  ),
                ],
              ),
            ],
          );
        },
      );
    },
  );
}

  void _removePin() {
    setState(() {
      _pin = null;
      _animationController.reverse();
    });
    print("Pin removed, new value: $_pin");
    // Only save the note after removing the PIN
    _saveNote();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _saveNote();
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF9EB),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFFF9EB),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16, top: 8),
              child: GestureDetector(
                onTap: _togglePin,
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _lockSizeAnimation.value,
                      child: Icon(
                        _pin == null ? Icons.lock_open : Icons.lock_outline,
                        color: _lockColorAnimation.value,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.createdAt != null) // Check if createdAt is provided
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Text(
                      'Created on: ${DateFormat('EEEE, MMM d, yyyy - hh:mm a').format(widget.createdAt!)}',
                      style: const TextStyle(
                        fontSize: 14.0,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _titleController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: "Title",
                    hintStyle: TextStyle(color: Theme.of(context).hintColor),
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(
                    fontSize: 26.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _contentController,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    hintText: "Write your note here...",
                    hintStyle: TextStyle(color: Theme.of(context).hintColor),
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(fontSize: 18.0),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
