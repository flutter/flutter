import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';

// This example demonstrates highlighting and linking Twitter handles.

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
      home: MyHomePage(title: 'Flutter Link Twitter Handle Demo'),
    );
  }
}

class MyHomePage extends StatelessWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;
  static const String text = 'Check out @FlutterDev on Twitter for the latest.';

  void _onTapTwitterHandle (String linkText) async {
    final String handleWithoutAt = linkText.substring(1);
    Uri uri = Uri.parse('https://www.twitter.com/$handleWithoutAt');
    if (!await launchUrl(uri)) {
      throw 'Could not launch $uri.';
    }
  }

  final RegExp _twitterHandleRegExp = RegExp(r'@[a-zA-Z0-9]{4,15}');

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
                LinkedText.regExp(
                  text: text,
                  regExp: _twitterHandleRegExp,
                  onTap: _onTapTwitterHandle,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
