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
  static const String text = 'Check out @FlutterDev on Twitter for the latest, or go to flutter.dev.';

  void _onTapTwitterHandle(BuildContext context, String linkText) {
    final String handleWithoutAt = linkText.substring(1);
    final String twitterUriString = 'https://www.twitter.com/$handleWithoutAt';
    final Uri? uri = Uri.tryParse(twitterUriString);
    if (uri == null) {
      throw Exception('Failed to parse $twitterUriString.');
    }
    _showDialog(context, uri);
  }

  void _onTapUrl(BuildContext context, String urlString) {
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
                    text: text,
                    textLinkers: <TextLinker>[
                      TextLinker(
                        rangesFinder: TextLinker.urlRangesFinder,
                        linkBuilder: InlineLinkedText.getDefaultLinkBuilder((String urlString) {
                          return _onTapUrl(context, urlString);
                        }),
                      ),
                      TextLinker(
                        rangesFinder: TextLinker.rangesFinderFromRegExp(_twitterHandleRegExp),
                        linkBuilder: (String displayText, String linkText) {
                          return InlineLink(
                            text: linkText,
                            style: const TextStyle(
                              color: Color(0xff00aaaa),
                            ),
                            onTap: () => _onTapTwitterHandle(context, linkText),
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
