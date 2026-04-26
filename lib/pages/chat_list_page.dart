import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_page.dart';

class ChatListPage extends StatelessWidget {
  final String currentUserId;
  final VoidCallback onToggleTheme; // 👉 recibe el callback global

  ChatListPage({required this.currentUserId, required this.onToggleTheme});

  Future<DocumentSnapshot?> _findExistingChat(String otherUserId) async {
    final query = await FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .get();

    for (var doc in query.docs) {
      final participants = List<String>.from(doc['participants']);
      if (participants.contains(otherUserId)) {
        return doc;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(
          "Mensajes",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Theme.of(context).iconTheme.color),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.brightness_6,
                color: Theme.of(context).iconTheme.color),
            onPressed: onToggleTheme,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barra de búsqueda simulada
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                decoration: InputDecoration(
                  icon: Icon(Icons.search, color: Colors.grey),
                  hintText: "Buscar conversaciones...",
                  border: InputBorder.none,
                ),
              ),
            ),
          ),

          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Text(
              "Contactos",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),

          // 👉 Carrusel horizontal de todos los usuarios
          SizedBox(
            height: 100,
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("No hay usuarios registrados"));
                }

                final users = snapshot.data!.docs
                    .where((u) => u.id != currentUserId)
                    .toList();

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return GestureDetector(
                      onTap: () async {
                        // 👉 Buscar si ya existe un chat con este usuario
                        final existingChat = await _findExistingChat(user.id);

                        if (existingChat != null) {
                          // Abrir el chat existente
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatPage(
                                chatId: existingChat.id,
                                currentUserId: currentUserId,
                                onToggleTheme: onToggleTheme,
                              ),
                            ),
                          );
                        } else {
                          // Crear un nuevo chat
                          final newChat = await FirebaseFirestore.instance
                              .collection('chats')
                              .add({
                            'participants': [currentUserId, user.id],
                            'createdAt': DateTime.now(),
                          });

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatPage(
                                chatId: newChat.id,
                                currentUserId: currentUserId,
                                onToggleTheme: onToggleTheme,
                              ),
                            ),
                          );
                        }
                      },
                      child: Container(
                        width: 75,
                        margin: EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 32,
                                  backgroundColor:
                                      Colors.blueAccent.withOpacity(0.2),
                                  backgroundImage: NetworkImage(
                                      "https://i.pravatar.cc/150?u=${user.id}"),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 4,
                                  child: Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Theme.of(context)
                                            .scaffoldBackgroundColor,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              user['username'] ?? user['email'] ?? "Usuario",
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Text(
              "Recientes",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),

          // 👉 Lista de chats existentes
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .where('participants', arrayContains: currentUserId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 60, color: Colors.grey),
                        SizedBox(height: 16),
                        Text("Sin ningún chat hasta el momento",
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                final chats = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    final otherUserId = (chat['participants'] as List)
                        .firstWhere((id) => id != currentUserId);

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(otherUserId)
                          .get(),
                      builder: (context, userSnapshot) {
                        if (!userSnapshot.hasData) {
                          return ListTile(
                            leading:
                                CircleAvatar(backgroundColor: Colors.grey[300]),
                            title: Container(
                                color: Colors.grey[300],
                                height: 15,
                                width: 100),
                          );
                        }
                        final userData = userSnapshot.data!;

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 2.0),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                            leading: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundImage: NetworkImage(
                                      "https://i.pravatar.cc/150?u=${userData.id}"),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Theme.of(context)
                                            .scaffoldBackgroundColor,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                            title: Text(
                              userData['username'] ??
                                  userData['email'] ??
                                  "Usuario",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            subtitle: Text(
                              "Toca para ver los mensajes...",
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text("Ahora",
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 12)),
                                SizedBox(height: 4),
                                Container(
                                  padding: EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: Colors.blueAccent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    "1",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold),
                                  ),
                                )
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatPage(
                                    chatId: chat.id,
                                    currentUserId: currentUserId,
                                    onToggleTheme: onToggleTheme,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
