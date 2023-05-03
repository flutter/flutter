import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';

// This example demonstrates using LinkedText to make URLs open on tap.

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Link Demo'),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;
  static const String text = 'Check out https://www.flutter.dev, or maybe just flutter.dev or www.flutter.dev. Or if not, just google it: https://www.google.com!';

  void _onTapUrl (String urlString) async {
    Uri uri = Uri.parse(urlString);
    if (uri.host.isEmpty) {
      uri = Uri.parse('https://$urlString');
    }
    if (!await launchUrl(uri)) {
      throw 'Could not launch $urlString.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Builder(
          builder: (BuildContext context) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                LinkedText(
                  text: text,
                  onTap: _onTapUrl,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
