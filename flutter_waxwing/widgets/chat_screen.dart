import 'package:flutter/material.dart';
import '../services/chatgpt_api.dart';

class ChatScreen extends StatefulWidget {
  final ChatStreamController streamController;

  const ChatScreen({required this.streamController});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ChatGPT Chat')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<String>(
              stream: widget.streamController.stream,
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data is String && snapshot.data != null) {
                  final String data = snapshot.data as String;
                  return ListView.builder(
                    itemCount: data.split('\n').length,
                    itemBuilder: (context, index) {
                      final message = data.split('\n')[index];
                      return ListTile(
                        title: Text(message),
                      );
                    },
                  );
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Enter your message',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    final message = _messageController.text;
                    if (message.isNotEmpty) {
                      widget.streamController.addResponse('You: $message');
                      // Send message to ChatGPT API and add response to stream
                      _messageController.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}