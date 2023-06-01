import 'package:flutter/material.dart';

// This example demonstrates highlighting URLs in a TextSpan tree instead of a
// flat String.

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
      home: const MyHomePage(title: 'Flutter LinkedText.spans Demo'),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({
    super.key,
    required this.title,
  });

  final String title;

  void _onTapUrl (BuildContext context, String urlString) {
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
                  LinkedText.spans(
                    onTap: (String urlString) => _onTapUrl(context, urlString),
                    children: <InlineSpan>[
                      TextSpan(
                        text: 'Check out https://www.',
                        style: DefaultTextStyle.of(context).style,
                        children: const <InlineSpan>[
                          TextSpan(
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                            ),
                            text: 'flutter',
                          ),
                        ],
                      ),
                      TextSpan(
                        text: '.dev!',
                        style: DefaultTextStyle.of(context).style,
                      ),
                    ],
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
