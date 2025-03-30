import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';


class ChatGPTClient {
  final String apiKey;

  ChatGPTClient(this.apiKey);

  Future<String> sendMessage(String message) async {
    final url = Uri.parse('https://api.openai.com/v1/completions');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };
    final body = jsonEncode({
      'model': 'text-davinci-003',
      'prompt': message,
      'max_tokens': 1024,
      'n': 1,
      'stop': null,
      'temperature': 0.5,
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final choices = data['choices'] as List<dynamic>;
      final text = choices[0]['text'] as String;
      return text;
    } else {
      throw Exception('Failed to get response from ChatGPT API');
    }
  }
}


class ChatStreamController {
  final StreamController<String> _streamController = StreamController.broadcast();

  Stream<String> get stream => _streamController.stream;

  void addResponse(String response) {
    _streamController.add(response);
  }

  void close() {
    _streamController.close();
  }
}