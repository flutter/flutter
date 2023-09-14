// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

// This example demonstrates highlighting both URLs and Twitter handles with
// different actions and different styles.

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
      home: const MyHomePage(title: 'Flutter Link Twitter Handle Demo'),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({
    super.key,
    required this.title
  });

  final String title;
  static const String _text = '@FlutterDev is our Twitter account, or find us at www.flutter.dev';

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
                text: _text,
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
    required this.text,
    required this.onTapUrl,
    required this.onTapTwitterHandle,
  });

  final String text;
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
      <TextSpan>[TextSpan(text: widget.text)],
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
              ..onTap = () => widget.onTapUrl(linkString);
          _recognizers.add(recognizer);
          return _MyInlineLinkSpan(
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

    if (widget.text != oldWidget.text
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
