import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart'; // Import for testing

// Mocked ChatGptServiceImpl for demonstration
class MockedChatGptServiceImpl {
  Stream<String> sendMessageStream(String message) {
    // Simulate a delay for each word or chunk of the response
    final words = "This is a simulated response from ChatGPT.".split(" ");
    final streamController = StreamController<String>();
    String currentResponse = "";

    Future.forEach(words, (word) {
      return Future.delayed(Duration(milliseconds: 200), () {
        currentResponse += word + " ";
        streamController.add(currentResponse);
      });
    }).then((_) => streamController.close());

    return streamController.stream;
  }
}

// Mocked ChatMessage with sender information
class ChatMessage {
  final String text;
  final String senderId; // Unique ID for the sender
  final DateTime createdAt;

  ChatMessage({
    required this.text,
    required this.senderId,
    required this.createdAt,
  });
}

class ChatExampleApp extends StatefulWidget {
  const ChatExampleApp({superkey});

  @override
  _ChatExampleAppState createState() => _ChatExampleAppState();
}

class _ChatExampleAppState extends State<ChatExampleApp> {
  final List<ChatMessage> _messages = [];
  final String _chatGptUserIdentifier = "chatgpt_user"; // Unique ID for ChatGPT
  final String _currentUserIdentifier = "current_user"; // Unique ID for the current user
  final _chatGptService = MockedChatGptServiceImpl();

  @override
  void initState() {
    super.initState();
    _messages.add(
      ChatMessage(
        text: "Hello! How can I help you today?",
        senderId: _chatGptUserIdentifier,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Example'),
      ),
      body: 
      Chat(
        messages: _messages
            .map((m) => types.TextMessage(
                  author: m.senderId == _chatGptUserIdentifier
                      ? types.User(id: _chatGptUserIdentifier)
                      : types.User(id: _currentUserIdentifier),
                  createdAt: m.createdAt.millisecondsSinceEpoch,
                  id: UniqueKey().toString(), // Unique ID for each message
                  text: m.text,
                ))
            .toList(),
        onSendPressed: _handleSendPressed,
        user: types.User(id: _currentUserIdentifier), // Current user
      ),
    );
  }

  void _handleSendPressed(types.PartialText message) {
    final chatMessage = ChatMessage(
      text: message.text,
      senderId: _currentUserIdentifier,
      createdAt: DateTime.now(),
    );

    setState(() {
      _messages.add(chatMessage);
    });

    _simulateChatGptResponse(message.text);
  }

  void _simulateChatGptResponse(String userMessage) {
    // Simulate receiving a stream of responses from ChatGPT
    final stream = _chatGptService.sendMessageStream(userMessage);
    String fullResponse = "";

    stream.listen((responseChunk) {
      setState(() {
        // Find the last ChatGPT message or create a new one
        ChatMessage? lastGptMessage = _messages.lastWhere(
          (m) => m.senderId == _chatGptUserIdentifier,
          orElse: () => ChatMessage(
            text: "",
            senderId: _chatGptUserIdentifier,
            createdAt: DateTime.now(),
          ),
        );

        if (lastGptMessage.text.isEmpty ||
            _messages.last.senderId != _chatGptUserIdentifier) {
          // Add a new message if it's the first chunk or after a user message
          _messages.add(
            ChatMessage(
              text: responseChunk,
              senderId: _chatGptUserIdentifier,
              createdAt: DateTime.now(),
            ),
          );
        } else {
          // Update the last ChatGPT message with the new chunk
          _messages.remove(lastGptMessage);
          _messages.add(
            ChatMessage(
              text: responseChunk,
              senderId: _chatGptUserIdentifier,
              createdAt: lastGptMessage.createdAt,
            ),
          );
        }
      });
    }, onDone: () {
      // Handle completion if needed
    });
  }
}

void main() {
  runApp(const MaterialApp(
    home: ChatExampleApp(),
  ));
}

// Add this test suite
void main() {
  testWidgets('ChatExampleApp builds correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MaterialApp(home: ChatExampleApp()));

    // Verify that the AppBar with the title 'Chat Example' is present.
    expect(find.widgetWithText<AppBar>(AppBar, 'Chat Example'), findsOneWidget);

    // Verify that the Chat widget is present.
    expect(find.byType(Chat), findsOneWidget);

    // You can add more specific checks here, for example:
    // - Check for the initial message from ChatGPT.
    // - Check that the send button is present.
  });

    testWidgets('Chat message is added when _handleSendPressed is called', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MaterialApp(home: ChatExampleApp()));

    // Find the Chat widget.
    final chatFinder = find.byType(Chat);
    expect(chatFinder, findsOneWidget);
    final chatWidget = tester.widget<Chat>(chatFinder);

    // Simulate sending a message.  Since we can't directly call private methods,
    // we'll trigger the send button press, which calls the handler.
      final textFieldFinder = find.byType(TextField);
    expect(textFieldFinder, findsOneWidget);
    await tester.enterText(textFieldFinder, 'Hello Flutter!');

    final sendButtonFinder = find.byIcon(Icons.send);
    expect(sendButtonFinder, findsOneWidget);
    await tester.tap(sendButtonFinder);
    await tester.pump(); // Trigger a rebuild

    // Verify that the new message is added.  We check for the text.
    expect(find.text('Hello Flutter!'), findsOneWidget);

  });
}
