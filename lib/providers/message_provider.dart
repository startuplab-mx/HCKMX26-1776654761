import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message.dart';
import 'dart:async';


class MessageProvider extends ChangeNotifier {
  final List<Message> _messages = [];
  List<Message> get messages => _messages;

  StreamSubscription? _subscription;

  void listenToFirestore() {
    _subscription = FirebaseFirestore.instance
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .listen((snapshot) {
      _messages.clear();
      for (var doc in snapshot.docs) {
        _messages.add(Message.fromDoc(doc.id, doc.data()));
      }
      notifyListeners();
    });
  }

  Future<void> sendMessage(String senderId, String text) async {
    await FirebaseFirestore.instance.collection('messages').add({
      'senderId': senderId,
      'text': text,
      'timestamp': DateTime.now(),
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
