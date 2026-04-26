import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/post_provider.dart';
import '../providers/auth_provider.dart';

class CreatePostForm extends StatefulWidget {
  @override
  _CreatePostFormState createState() => _CreatePostFormState();
}

class _CreatePostFormState extends State<CreatePostForm> {
  final contentController = TextEditingController();
  final imageController = TextEditingController(); // URL de imagen opcional

  @override
  Widget build(BuildContext context) {
    final postProvider = Provider.of<PostProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text("Nuevo Post")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: contentController, decoration: InputDecoration(labelText: "Contenido")),
            TextField(controller: imageController, decoration: InputDecoration(labelText: "URL de imagen (opcional)")),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (authProvider.user != null) {
                  await postProvider.addPost(
                    authProvider.user!.uid,
                    contentController.text,
                    imageUrl: imageController.text.isNotEmpty ? imageController.text : null,
                  );
                  Navigator.pop(context); // Regresa al feed
                }
              },
              child: Text("Publicar"),
            ),
          ],
        ),
      ),
    );
  }
}
