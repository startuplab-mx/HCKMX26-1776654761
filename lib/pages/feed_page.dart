import 'package:flutter/material.dart';
import 'package:maqueta_mensajes/pages/control/settings_page.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/post_provider.dart';
import '../widgets/post_card.dart';
import 'login_page.dart';
import 'chat_list_page.dart';

class FeedPage extends StatelessWidget {
  final VoidCallback onToggleTheme; // 👉 recibe el callback desde main.dart

  FeedPage({required this.onToggleTheme});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final postProvider = Provider.of<PostProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Feed"),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              final userEmail = authProvider.user?.email;
              if (userEmail == null) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsPage(
                    currentUserEmail: userEmail,
                    onToggleTheme: onToggleTheme,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.brightness_6),
            onPressed: onToggleTheme,
          ),
          IconButton(
            icon: Icon(Icons.chat_bubble_outline),
            onPressed: () {
              final userId = authProvider.user?.uid;
              if (userId == null) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatListPage(
                    currentUserId: userId,
                    onToggleTheme: onToggleTheme,
                  ),
                ),
              );
            },
          ),
          // Botón de cerrar sesión
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              final confirmar = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text('Cerrar sesión'),
                  content: Text('¿Estás seguro de que deseas cerrar sesión?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(
                        'Cerrar sesión',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );

              if (confirmar == true) {
                // Solo cerrar sesión — el StreamBuilder en main.dart
                // detecta el cambio y navega a LoginPage automáticamente
                await authProvider.signOut();
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Simula recargar el feed
          await Future.delayed(Duration(seconds: 1));
        },
        child: CustomScrollView(
          slivers: [
            // Sección de Historias (Stories)
            SliverToBoxAdapter(
              child: Container(
                height: 110,
                padding: EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1)),
                ),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 8,
                  itemBuilder: (context, index) {
                    bool isMe = index == 0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 65,
                                height: 65,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: isMe ? null : LinearGradient(
                                    colors: [Colors.purple, Colors.orange, Colors.pink],
                                    begin: Alignment.topRight,
                                    end: Alignment.bottomLeft,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(3.0),
                                  child: ClipOval(
                                    child: Image.network(
                                      isMe
                                          ? 'https://i.pravatar.cc/150?u=${authProvider.user?.uid ?? 'me'}'
                                          : 'https://i.pravatar.cc/150?u=$index',
                                      fit: BoxFit.cover,
                                      width: 65,
                                      height: 65,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: Colors.grey.shade300,
                                        child: Icon(Icons.person,
                                            color: Colors.grey.shade600,
                                            size: 30),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (isMe)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: Icon(Icons.add, color: Colors.white, size: 16),
                                  ),
                                )
                            ],
                          ),
                          SizedBox(height: 5),
                          Text(
                            isMe ? "Tu historia" : "Usuario $index",
                            style: TextStyle(fontSize: 12, fontWeight: isMe ? FontWeight.w500 : FontWeight.normal),
                          )
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            // Posts (Reales o Simulados si está vacío)
            if (postProvider.posts.isNotEmpty)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => PostCard(post: postProvider.posts[index]),
                  childCount: postProvider.posts.length,
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildDummyPost(context, index),
                  childCount: 3, // Mostrar 3 posts falsos para que no quede en blanco
                ),
              ),
            
            // Espacio extra al final
            SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        child: Icon(Icons.add, color: Colors.white),
        onPressed: () {
          // Aquí puedes abrir tu formulario para crear posts
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Crear publicación (En desarrollo)")));
        },
      ),
    );
  }

  // Widget para simular un Post real visualmente atractivo
  Widget _buildDummyPost(BuildContext context, int index) {
    List<String> names = ["Carlos Slim", "Ana Maria", "Juan Perez"];
    List<String> contents = [
      "¡Qué increíble día para empezar nuevos proyectos! 🚀✨ #Emprendimiento #Metas",
      "Disfrutando de este hermoso paisaje. La naturaleza nunca deja de sorprenderme. 🌲⛰️",
      "Acabo de terminar mi último diseño. ¿Qué les parece esta paleta de colores? 🎨💻"
    ];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0), // Sin margen lateral como Instagram
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      elevation: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con usuario
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey.shade300,
              backgroundImage: NetworkImage("https://i.pravatar.cc/150?img=${index + 10}"),
              onBackgroundImageError: (_, __) {},
            ),
            title: Text(names[index], style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("Hace ${index + 2} horas"),
            trailing: Icon(Icons.more_vert),
          ),

          // Imagen simulada
          Container(
            width: double.infinity,
            height: 300,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage("https://picsum.photos/seed/${index + 40}/600/400"),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Botones de interacción (Like, Comment, Share)
          Row(
            children: [
              IconButton(icon: Icon(Icons.favorite_border), onPressed: () {}),
              IconButton(icon: Icon(Icons.chat_bubble_outline), onPressed: () {}),
              IconButton(icon: Icon(Icons.send_outlined), onPressed: () {}),
              Spacer(),
              IconButton(icon: Icon(Icons.bookmark_border), onPressed: () {}),
            ],
          ),

          // Likes
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text("${(index + 1) * 42} Me gusta", style: TextStyle(fontWeight: FontWeight.bold)),
          ),

          // Contenido del post
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: RichText(
              text: TextSpan(
                style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                children: [
                  TextSpan(text: "${names[index]} ", style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: contents[index]),
                ],
              ),
            ),
          ),
          
          // Ver comentarios
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text("Ver los ${(index + 1) * 15} comentarios", style: TextStyle(color: Colors.grey)),
          ),
          SizedBox(height: 10),
        ],
      ),
    );
  }
}
