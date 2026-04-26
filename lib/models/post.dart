import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String userId;
  final String content;
  final DateTime timestamp;
  final String? imageUrl;

  Post({
    required this.id,
    required this.userId,
    required this.content,
    required this.timestamp,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'content': content,
      'timestamp': timestamp,
      'imageUrl': imageUrl,
    };
  }

  factory Post.fromDoc(String id, Map<String, dynamic> data) {
    return Post(
      id: id,
      userId: data['userId'],
      content: data['content'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      imageUrl: data['imageUrl'],
    );
  }
}
