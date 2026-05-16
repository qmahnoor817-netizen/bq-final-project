import 'package:cloud_firestore/cloud_firestore.dart';

class Note {
  final String id;
  final String title;
  final String content; // Will store Quill JSON now
  final DateTime createdAt;
  final String userId;
  final int color; // Add this
  final List<String> tags; // Add this
  final bool isPinned; // Add this

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.userId,
    required this.color, // Add this
    required this.tags, // Add this
    required this.isPinned, // Add this
  });

  factory Note.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Note(
      id: doc.id,
      title: data['title']?? '',
      content: data['content']?? '[]', // Default empty Quill doc
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      userId: data['userId']?? '',
      color: data['color']?? 0xFFFFFFFF, // Add this - default white
      tags: List<String>.from(data['tags']?? []), // Add this
      isPinned: data['isPinned']?? false, // Add this
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'userId': userId,
      'color': color, // Add this
      'tags': tags, // Add this
      'isPinned': isPinned, // Add this
    };
  }
}