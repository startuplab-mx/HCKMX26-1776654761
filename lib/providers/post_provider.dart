import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post.dart';

class PostProvider extends ChangeNotifier {
  final List<Post> _posts = [];
  List<Post> get posts => _posts;

  StreamSubscription? _subscription;

  PostProvider() {
    _subscription = FirebaseFirestore.instance
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      _posts.clear();
      for (var doc in snapshot.docs) {
        _posts.add(Post.fromDoc(doc.id, doc.data()));
      }
      notifyListeners();
    });
  }

  /// 👉 Método para crear un nuevo post
  Future<void> addPost(String userId, String content, {String? imageUrl}) async {
    await FirebaseFirestore.instance.collection('posts').add({
      'userId': userId,
      'content': content,
      'timestamp': DateTime.now(),
      'imageUrl': imageUrl,
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
