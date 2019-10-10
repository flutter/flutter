import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const MethodChannel channel = MethodChannel('com.example.abstract_method_smoke_test');
  await channel.invokeMethod<void>('show_keyboard');
  runApp(MyApp());
  print('Test suceeded');
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePage createState() => _HomePage();
}

class _HomePage extends State<HomePage> {
  @override
  void initState() {
    super.initState();

    // Trigger the second route.
    // https://github.com/flutter/flutter/issues/40126
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => SecondPage()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold();
  }
}

const String _webHtml = '''
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Test</title>
  </head>
  <body>
    <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod
    tempor incididunt ut labore et dolore magna aliqua.</p>
  </body>
</html>
''';

class SecondPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(
            child: WebView(initialUrl: 'data:text/html;base64,${base64.encode(utf8.encode(_webHtml))}')
          ),
        ],
      ),
    );
  }
}