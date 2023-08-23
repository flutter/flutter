import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

// This example demonstrates highlighting both URLs and Twitter handles with
// different actions and different styles.

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
      home: MyHomePage(title: 'Flutter Link Twitter Handle Demo'),
    );
  }
}

class MyHomePage extends StatelessWidget {
  MyHomePage({
    super.key,
    required this.title
  });

  final String title;
  static const String _text = 'Check out @FlutterDev on Twitter for the latest, or go to flutter.dev.';

  void _handleTapTwitterHandle(BuildContext context, String linkText) {
    final String handleWithoutAt = linkText.substring(1);
    final String twitterUriString = 'https://www.twitter.com/$handleWithoutAt';
    final Uri? uri = Uri.tryParse(twitterUriString);
    if (uri == null) {
      throw Exception('Failed to parse $twitterUriString.');
    }
    _showDialog(context, uri);
  }

  void _handleTapUrl(BuildContext context, String urlString) {
    final Uri? uri = Uri.tryParse(urlString);
    if (uri == null) {
      throw Exception('Failed to parse $urlString.');
    }
    _showDialog(context, uri);
  }

  void _showDialog(BuildContext context, Uri uri) {
    // A package like url_launcher would be useful for actually opening the URL
    // here instead of just showing a dialog.
    Navigator.of(context).push(
      DialogRoute<void>(
        context: context,
        builder: (BuildContext context) => AlertDialog(title: Text('You tapped: $uri')),
      ),
    );
  }

  final RegExp _twitterHandleRegExp = RegExp(r'@[a-zA-Z0-9]{4,15}');
  final RegExp _urlRegExp = RegExp(r'(?<!@[a-zA-Z0-9-]*)(?<![\/\.a-zA-Z0-9-])((https?:\/\/)?(([a-zA-Z0-9-]*\.)*[a-zA-Z0-9-]+(\.[a-zA-Z]+)+))(?::\d{1,5})?(?:\/[^\s]*)?(?:\?[^\s#]*)?(?:#[^\s]*)?(?![a-zA-Z0-9-]*@)');

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
                  LinkedText.textLinkers(
                    text: _text,
                    textLinkers: <TextLinker>[
                      TextLinker(
                        textRangesFinder: TextLinker.textRangesFinderFromRegExp(_urlRegExp),
                        linkBuilder: InlineLinkedText.getDefaultLinkBuilder((String urlString) {
                          return _handleTapUrl(context, urlString);
                        }),
                      ),
                      TextLinker(
                        textRangesFinder: TextLinker.textRangesFinderFromRegExp(_twitterHandleRegExp),
                        linkBuilder: (String displayText, String linkText) {
                          final TapGestureRecognizer recognizer = TapGestureRecognizer()
                              ..onTap = () => _handleTapTwitterHandle(context, linkText);
                          return (
                            InlineLink(
                              text: displayText,
                              style: const TextStyle(
                                color: Color(0xff00aaaa),
                              ),
                              recognizer: recognizer,
                            ),
                            recognizer,
                          );
                        },
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
