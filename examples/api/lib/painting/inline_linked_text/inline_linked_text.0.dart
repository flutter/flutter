import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

// This example demonstrates using InlineLinkedText to make URLs open on tap.

// TODO(justinmc): Test all examples.

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
      home: MyHomePage(title: 'Flutter Link Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget{
  MyHomePage({
    super.key,
    required this.title,
  });

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const String _text = 'Check out https://www.flutter.dev, or maybe just flutter.dev or www.flutter.dev.';
  final GlobalKey _textKey = GlobalKey();

  void _handleTapUri(BuildContext context, String urlString) {
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

  // InlineLinkedText creates TapGestureRecognizers to handle onTap, and they
  // all need to be disposed by this owning widget.
  static void _disposeRecognizers(Text text) {
    final InlineLinkedText inlineLinkedText = text.textSpan! as InlineLinkedText;
    for (final GestureRecognizer recognizer in inlineLinkedText.recognizers) {
      recognizer.dispose();
    }
  }

  @override
  void dispose() {
    _disposeRecognizers(_textKey.currentWidget! as Text);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Text? text = _textKey.currentWidget as Text?;
    if (text != null) {
      _disposeRecognizers(text);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Builder(
          builder: (BuildContext context) {
            return SelectionArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text.rich(
                    key: _textKey,
                    InlineLinkedText(
                      style: DefaultTextStyle.of(context).style,
                      text: _text,
                      onTap: (String urlString) => _handleTapUri(context, urlString),
                    ),
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
