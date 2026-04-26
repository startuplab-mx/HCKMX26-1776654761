import 'package:flutter/material.dart';
import '../models/post.dart';

class PostCard extends StatelessWidget {
  final Post post;

  const PostCard({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con usuario
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blueAccent,
              child: Text(post.userId[0].toUpperCase()),
            ),
            title: Text(post.userId, style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(post.timestamp.toString()),
          ),

          // Imagen opcional
          if (post.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(post.imageUrl!, fit: BoxFit.cover),
            ),

          // Contenido del post
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(post.content),
          ),

          // Botones de interacción
          ButtonBar(
            alignment: MainAxisAlignment.start,
            children: [
              TextButton.icon(
                onPressed: () {
                  // Aquí podrías manejar "like"
                },
                icon: Icon(Icons.thumb_up_alt_outlined),
                label: Text("Like"),
              ),
              TextButton.icon(
                onPressed: () {
                  // Aquí podrías manejar "comentario"
                },
                icon: Icon(Icons.comment_outlined),
                label: Text("Comentar"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
