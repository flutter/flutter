import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';

// This example demonstrates highlighting both URLs and Twitter handles with
// different actions and different styles.

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
  static const String text = 'Check out @FlutterDev on Twitter for the latest, or go to flutter.dev.';

  void _onTapTwitterHandle (String linkText) async {
    final String handleWithoutAt = linkText.substring(1);
    Uri uri = Uri.parse('https://www.twitter.com/$handleWithoutAt');
    if (!await launchUrl(uri)) {
      throw 'Could not launch $uri.';
    }
  }

  void _onTapUrl (String urlString) async {
    Uri uri = Uri.parse(urlString);
    if (uri.host.isEmpty) {
      uri = Uri.parse('https://$urlString');
    }
    if (!await launchUrl(uri)) {
      throw 'Could not launch $urlString.';
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
                LinkedText.textLinkers(
                  text: text,
                  textLinkers: <TextLinker>[
                    TextLinker(
                      rangesFinder: TextLinker.urlRangesFinder,
                      linkBuilder: InlineLinkedText.getDefaultLinkBuilder(_onTapUrl),
                    ),
                    TextLinker(
                      rangesFinder: TextLinker.rangesFinderFromRegExp(_twitterHandleRegExp),
                      linkBuilder: (String linkText) {
                        return InlineLink(
                          text: linkText,
                          style: const TextStyle(
                            color: Color(0xff00aaaa),
                          ),
                          onTap: _onTapTwitterHandle,
                        );
                      },
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

