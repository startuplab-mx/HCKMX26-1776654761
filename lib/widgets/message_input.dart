import 'package:flutter/material.dart';
import '../providers/message_provider.dart';
import 'package:provider/provider.dart';

class MessageInput extends StatefulWidget {
  final String currentUserId;

  MessageInput({required this.currentUserId});

  @override
  _MessageInputState createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final TextEditingController _controller = TextEditingController();

  void _sendMessage(BuildContext context) {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      Provider.of<MessageProvider>(context, listen: false)
          .sendMessage(widget.currentUserId, text);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(controller: _controller),
        ),
        IconButton(
          icon: Icon(Icons.send),
          onPressed: () => _sendMessage(context),
        ),
      ],
    );
  }
}
