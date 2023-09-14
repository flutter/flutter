// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

// This example demonstrates creating links in a TextSpan tree instead of a flat
// String.

void main() {
  runApp(const TextLinkerApp());
}

class TextLinkerApp extends StatelessWidget {
  const TextLinkerApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter TextLinker Span Demo'),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({
    super.key,
    required this.title
  });

  final String title;

  void _handleTapTwitterHandle(BuildContext context, String linkString) {
    final String handleWithoutAt = linkString.substring(1);
    final String twitterUriString = 'https://www.twitter.com/$handleWithoutAt';
    final Uri? uri = Uri.tryParse(twitterUriString);
    if (uri == null) {
      throw Exception('Failed to parse $twitterUriString.');
    }
    _showDialog(context, uri);
  }

  void _handleTapUrl(BuildContext context, String urlText) {
    final Uri? uri = Uri.tryParse(urlText);
    if (uri == null) {
      throw Exception('Failed to parse $urlText.');
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
              child: _TwitterAndUrlLinkedText(
                spans: <InlineSpan>[
                  TextSpan(
                    text: '@FlutterDev is our Twitter, or find us at www.',
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
                    text: '.dev',
                    style: DefaultTextStyle.of(context).style,
                  ),
                ],
                onTapUrl: (String urlString) => _handleTapUrl(context, urlString),
                onTapTwitterHandle: (String handleString) => _handleTapTwitterHandle(context, handleString),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TwitterAndUrlLinkedText extends StatefulWidget {
  const _TwitterAndUrlLinkedText({
    required this.spans,
    required this.onTapUrl,
    required this.onTapTwitterHandle,
  });

  final List<InlineSpan> spans;
  final ValueChanged<String> onTapUrl;
  final ValueChanged<String> onTapTwitterHandle;

  @override
  State<_TwitterAndUrlLinkedText> createState() => _TwitterAndUrlLinkedTextState();
}

class _TwitterAndUrlLinkedTextState extends State<_TwitterAndUrlLinkedText> {
  final List<GestureRecognizer> _recognizers = <GestureRecognizer>[];
  late Iterable<InlineSpan> _linkedSpans;
  late final List<TextLinker> _textLinkers;

  final RegExp _twitterHandleRegExp = RegExp(r'@[a-zA-Z0-9]{4,15}');

  void _disposeRecognizers() {
    for (final GestureRecognizer recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  void _linkSpans() {
    _disposeRecognizers();
    final Iterable<InlineSpan> linkedSpans = TextLinker.linkSpans(
      widget.spans,
      _textLinkers,
    );
    _linkedSpans = linkedSpans;
  }

  @override
  void initState() {
    super.initState();

    _textLinkers = <TextLinker>[
      TextLinker(
        regExp: LinkedText.defaultUriRegExp,
        linkBuilder: (String displayString, String linkString) {
          final TapGestureRecognizer recognizer = TapGestureRecognizer()
              // The linkString always contains the full matched text, so that's
              // what should be linked to.
              ..onTap = () => widget.onTapUrl(linkString);
          _recognizers.add(recognizer);
          return _MyInlineLinkSpan(
            // The displayString contains only the portion of the matched text
            // in a given TextSpan. For example, the bold "flutter" text in
            // the overall "www.flutter.dev" URL is in its own TextSpan with its
            // bold styling. linkBuilder is called separately for each part.
            text: displayString,
            color: const Color(0xff0000ee),
            recognizer: recognizer,
          );
        },
      ),
      TextLinker(
        regExp: _twitterHandleRegExp,
        linkBuilder: (String displayString, String linkString) {
          final TapGestureRecognizer recognizer = TapGestureRecognizer()
              ..onTap = () => widget.onTapTwitterHandle(linkString);
          _recognizers.add(recognizer);
          return _MyInlineLinkSpan(
            text: displayString,
              color: const Color(0xff00aaaa),
            recognizer: recognizer,
          );
        },
      ),
    ];

    _linkSpans();
  }

  @override
  void didUpdateWidget(_TwitterAndUrlLinkedText oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.spans != oldWidget.spans
      || widget.onTapUrl != oldWidget.onTapUrl
      || widget.onTapTwitterHandle != oldWidget.onTapTwitterHandle) {
      _linkSpans();
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_linkedSpans.isEmpty) {
      return const SizedBox.shrink();
    }

    return Text.rich(
      TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: _linkedSpans.toList(),
      ),
    );
  }
}

class _MyInlineLinkSpan extends TextSpan {
  _MyInlineLinkSpan({
    required String text,
    required Color color,
    required super.recognizer,
  }) : super(
    style: TextStyle(
      color: color,
      decorationColor: color,
      decoration: TextDecoration.underline,
    ),
    mouseCursor: SystemMouseCursors.click,
    text: text,
  );
}
