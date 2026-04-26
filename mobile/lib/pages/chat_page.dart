import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../apiServices/ApiConexion.dart';

class ChatPage extends StatelessWidget {
  final String chatId;
  final String currentUserId;
  final VoidCallback onToggleTheme; // 👉 recibe el callback global

  ChatPage({
    required this.chatId,
    required this.currentUserId,
    required this.onToggleTheme,
  });

  final messageController = TextEditingController();

  Future<DocumentSnapshot> _getOtherUser() async {
    final chatDoc =
        await FirebaseFirestore.instance.collection('chats').doc(chatId).get();
    final participants = List<String>.from(chatDoc['participants']);
    final otherUserId = participants.firstWhere((id) => id != currentUserId);
    return FirebaseFirestore.instance
        .collection('users')
        .doc(otherUserId)
        .get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: FutureBuilder<DocumentSnapshot>(
          future: _getOtherUser(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return AppBar(title: Text("Chat"));
            }
            final userData = snapshot.data!;
            return AppBar(
              elevation: 1,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              leading: IconButton(
                icon: Icon(Icons.arrow_back,
                    color: Theme.of(context).iconTheme.color),
                onPressed: () => Navigator.pop(context),
              ),
              title: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(
                        "https://i.pravatar.cc/150?u=${userData.id}"),
                  ),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userData['username'] ?? userData['email'],
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text("En línea",
                          style: TextStyle(color: Colors.green, fontSize: 12)),
                    ],
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.brightness_6,
                      color: Theme.of(context).iconTheme.color),
                  onPressed: onToggleTheme,
                ),
                IconButton(
                  icon: Icon(Icons.more_vert,
                      color: Theme.of(context).iconTheme.color),
                  onPressed: () {},
                ),
              ],
            );
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return Center(child: CircularProgressIndicator());
                final messages = snapshot.data!.docs;

                return ListView.builder(
                  padding: EdgeInsets.all(10),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['senderId'] == currentUserId;

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(msg['senderId'])
                          .get(),
                      builder: (context, userSnapshot) {
                        String timeString = "Ahora";
                        if (msg['timestamp'] != null) {
                          try {
                            final DateTime date =
                                (msg['timestamp'] as Timestamp).toDate();
                            timeString =
                                "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
                          } catch (e) {
                            // Ignorar si no se puede parsear
                          }
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 6.0, horizontal: 8.0),
                          child: Row(
                            mainAxisAlignment: isMe
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (!isMe) ...[
                                CircleAvatar(
                                  radius: 14,
                                  backgroundImage: NetworkImage(
                                      "https://i.pravatar.cc/150?u=${msg['senderId']}"),
                                ),
                                SizedBox(width: 8),
                              ],
                              Flexible(
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 14),
                                  decoration: BoxDecoration(
                                      color: isMe
                                          ? Colors.blueAccent
                                          : (Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.grey[800]
                                              : Colors.grey[200]),
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(18),
                                        topRight: Radius.circular(18),
                                        bottomLeft: isMe
                                            ? Radius.circular(18)
                                            : Radius.circular(0),
                                        bottomRight: isMe
                                            ? Radius.circular(0)
                                            : Radius.circular(18),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ]),
                                  child: Column(
                                    crossAxisAlignment: isMe
                                        ? CrossAxisAlignment.end
                                        : CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        msg['text'],
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: isMe
                                              ? Colors.white
                                              : Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.color,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        timeString,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isMe
                                              ? Colors.white70
                                              : Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),

          // 👉 Caja de texto para enviar mensajes
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.add_circle_outline,
                        color: Colors.blueAccent),
                    onPressed: () {},
                  ),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[800]
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextField(
                        controller: messageController,
                        style: TextStyle(
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color),
                        decoration: InputDecoration(
                          hintText: "Escribe un mensaje...",
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                        icon: Icon(Icons.send, color: Colors.white, size: 20),
                        onPressed: () async {
                          if (messageController.text.trim().isEmpty) return;

                          String mensaje = messageController.text.trim();

                          // 1️⃣ Guardar mensaje del usuario
                          await FirebaseFirestore.instance
                              .collection('chats')
                              .doc(chatId)
                              .collection('messages')
                              .add({
                            'text': mensaje,
                            'senderId': currentUserId,
                            'timestamp': DateTime.now(),
                          });

                          messageController.clear();

                          try {
                            // 2️⃣ Obtener los correos de los participantes para verificar si tienen control parental
                            final chatDoc = await FirebaseFirestore.instance
                                .collection('chats')
                                .doc(chatId)
                                .get();
                            final participants = List<String>.from(
                                chatDoc['participants'] ?? []);
                            final otherUserId = participants.firstWhere(
                                (id) => id != currentUserId,
                                orElse: () => 'Desconocido');

                            final currentUserDoc = await FirebaseFirestore
                                .instance
                                .collection('users')
                                .doc(currentUserId)
                                .get();
                            final currentUserEmail =
                                currentUserDoc.data()?['email'];

                            final otherUserDoc = await FirebaseFirestore
                                .instance
                                .collection('users')
                                .doc(otherUserId)
                                .get();
                            final otherUserEmail =
                                otherUserDoc.data()?['email'];

                            bool isControlled = false;
                            String? menorUserId;
                            int edadMenor = 0;

                            // Comprobar si el usuario actual es un menor controlado
                            if (currentUserEmail != null) {
                              final query1 = await FirebaseFirestore.instance
                                  .collection('control')
                                  .where('correo_menor',
                                      isEqualTo: currentUserEmail)
                                  .get();
                              if (query1.docs.isNotEmpty) {
                                isControlled = true;
                                menorUserId = currentUserId;
                                edadMenor = currentUserDoc.data()?['edad'] ?? 0;
                              }
                            }

                            // Comprobar si el otro usuario es un menor controlado
                            if (!isControlled && otherUserEmail != null) {
                              final query2 = await FirebaseFirestore.instance
                                  .collection('control')
                                  .where('correo_menor',
                                      isEqualTo: otherUserEmail)
                                  .get();
                              if (query2.docs.isNotEmpty) {
                                isControlled = true;
                                menorUserId = otherUserId;
                                edadMenor = otherUserDoc.data()?['edad'] ?? 0;
                              }
                            }

                            // 3️⃣ Enviar mensaje a la API SOLAMENTE si hay control parental activo
                            if (isControlled && menorUserId != null) {
                              // 3.1 Construir metadata
                              String metadata =
                                  "Menor de ${edadMenor > 0 ? edadMenor : 12} años jugando Sentinel App.";

                              var respuestaApi = await ApiConexion.consulta(
                                menorUserId,
                                chatId,
                                mensaje,
                                metadata,
                              );
                              print(respuestaApi);

                              var analysis = respuestaApi['analysis'] ?? {};
                              bool riesgoDetectado =
                                  analysis['riesgo_detectado'] ?? false;
                              String nivelAlerta =
                                  analysis['nivel_alerta'] ?? 'NINGUNO';

                              // Guardar la respuesta de la API en la colección 'alerts'
                              // SOLO si representa un riesgo
                              if (riesgoDetectado) {
                                await FirebaseFirestore.instance
                                    .collection('alerts')
                                    .add({
                                  'senderId': currentUserId,
                                  'otherUserId': otherUserId,
                                  'chatId': chatId,
                                  'message': mensaje,
                                  'riskLevel': nivelAlerta,
                                  'timestamp': DateTime.now(),
                                  'rawResponse': analysis,
                                  'actionRequired':
                                      respuestaApi['action_required'] ?? '',
                                });
                              }
                            }
                          } catch (e) {
                            print("Error API/Firebase: $e");
                          }
                        }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
