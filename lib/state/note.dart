class Note {
  final String? id; // Firestore's document ID will be a String
  final String title;
  final String content;
  final String userId; // Maps to the Firestore userId field
  final DateTime createdAt;
  final String? pin; // Optional security pin

  Note({
    this.id, // Will be the Firestore document ID
    required this.title,
    required this.content,
    required this.userId,
    required this.createdAt,
    this.pin,
  });

  // Convert Note object to Firestore-compatible Map
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'pin': pin,
    };
  }

  // Factory constructor to create a Note object from Firestore data
  factory Note.fromMap(String id, Map<String, dynamic> map) {
    return Note(
      id: id, 
      title: map['title'] as String,
      content: map['content'] as String,
      userId: map['userId'] as String,
      createdAt: DateTime.parse(map['createdAt']),
      pin: map['pin'] as String?,
    );
  }

  // Method to copy a Note with optional updates
  Note copyWith({
    String? id,
    String? title,
    String? content,
    String? userId,
    DateTime? createdAt,
    String? pin,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      pin: pin ?? this.pin,
    );
  }
}
