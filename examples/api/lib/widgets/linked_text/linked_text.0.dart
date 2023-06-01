import 'package:flutter/material.dart';

// This example demonstrates using LinkedText to make URLs open on tap.

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
  });

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
  const MyHomePage({
    super.key,
    required this.title,
  });

  final String title;
  static const String text = 'Check out https://www.flutter.dev, or maybe just flutter.dev or www.flutter.dev. Or if not, just google it: https://www.google.com!';

  void _onTapUrl(BuildContext context, String urlString) {
    final Uri? uri = Uri.tryParse(urlString);
    if (uri == null) {
      throw Exception('Failed to parse $urlString.');
    }

    // A package like url_launcher would be useful for actually opening the URL
    // here instead of just showing a dialog.
    Navigator.of(context).push(
      DialogRoute<void>(
        context: context,
        builder: (BuildContext context) => AlertDialog(title: Text('You tapped: $uri')),
      ),
    );
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
            return SelectionArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  LinkedText(
                    text: text,
                    onTap: (String urlString) => _onTapUrl(context, urlString),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
