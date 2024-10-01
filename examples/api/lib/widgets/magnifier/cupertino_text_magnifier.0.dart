// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';


void main() => runApp(const TextMagnifierExampleApp(text: 'Hello world!'));

class TextMagnifierExampleApp extends StatefulWidget {
  const TextMagnifierExampleApp({
    super.key,
    required this.text,
  });


  final String text;

  @override
  State<TextMagnifierExampleApp> createState() => _TextMagnifierExampleAppState();
}

class _TextMagnifierExampleAppState extends State<TextMagnifierExampleApp> {
  final MagnifierController _controller = MagnifierController();
  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      theme: const CupertinoThemeData(brightness: Brightness.light),
      home: CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
        middle: Text('CupertinoTextMagnifier Sample'),
      ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48.0),
          child: Center(
            child: CupertinoTextField(
              magnifierConfiguration: TextMagnifierConfiguration(
                magnifierBuilder: (_, __, ValueNotifier<MagnifierInfo> magnifierInfo) => CupertinoTextMagnifier(
                  controller: _controller,
                  magnifierInfo: magnifierInfo,
                ),
              ),
              controller: TextEditingController(text: widget.text),
            ),
          ),
        ),
      ),
    );
  }
}
