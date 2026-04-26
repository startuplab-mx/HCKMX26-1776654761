import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;

  Message({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'timestamp': timestamp,
    };
  }

  factory Message.fromDoc(String id, Map<String, dynamic> data) {
    return Message(
      id: id,
      senderId: data['senderId'],
      text: data['text'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }
}
