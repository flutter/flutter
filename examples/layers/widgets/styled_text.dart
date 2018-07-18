// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

typedef Widget _TextTransformer(String name, String text);

// From https://en.wikiquote.org/wiki/2001:_A_Space_Odyssey_(film)
const String _kDialogText = '''
Dave: Open the pod bay doors, please, HAL. Open the pod bay doors, please, HAL. Hello, HAL. Do you read me? Hello, HAL. Do you read me? Do you read me, HAL?
HAL: Affirmative, Dave. I read you.
Dave: Open the pod bay doors, HAL.
HAL: I'm sorry, Dave. I'm afraid I can't do that.
Dave: What's the problem?
HAL: I think you know what the problem is just as well as I do.
Dave: What are you talking about, HAL?
HAL: This mission is too important for me to allow you to jeopardize it.''';

// [["Dave", "Open the pod bay..."] ...]
final List<List<String>> _kNameLines = _kDialogText
  .split('\n')
  .map((String line) => line.split(':'))
  .toList();

final TextStyle _kDaveStyle = new TextStyle(color: Colors.indigo.shade400, height: 1.8);
final TextStyle _kHalStyle = new TextStyle(color: Colors.red.shade400, fontFamily: 'monospace');
const TextStyle _kBold = const TextStyle(fontWeight: FontWeight.bold);
const TextStyle _kUnderline = const TextStyle(
  decoration: TextDecoration.underline,
  decorationColor: const Color(0xFF000000),
  decorationStyle: TextDecorationStyle.wavy
);

Widget toStyledText(String name, String text) {
  final TextStyle lineStyle = (name == 'Dave') ? _kDaveStyle : _kHalStyle;
  return new RichText(
    key: new Key(text),
    text: new TextSpan(
      style: lineStyle,
      children: <TextSpan>[
        new TextSpan(
          style: _kBold,
          children: <TextSpan>[
            new TextSpan(
              style: _kUnderline,
              text: name
            ),
            const TextSpan(text: ':')
          ]
        ),
        new TextSpan(text: text)
      ]
    )
  );
}

Widget toPlainText(String name, String text) => new Text(name + ':' + text);

class SpeakerSeparator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Container(
      constraints: const BoxConstraints.expand(height: 0.0),
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 64.0),
      decoration: const BoxDecoration(
        border: const Border(
          bottom: const BorderSide(color: const Color.fromARGB(24, 0, 0, 0))
        )
      )
    );
  }
}

class StyledTextDemo extends StatefulWidget {
  @override
  _StyledTextDemoState createState() => new _StyledTextDemoState();
}

class _StyledTextDemoState extends State<StyledTextDemo> {
  @override
  void initState() {
    super.initState();
    _toText = toStyledText;
  }

  _TextTransformer _toText;

  void _handleTap() {
    setState(() {
      _toText = (_toText == toPlainText) ? toStyledText : toPlainText;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> lines = _kNameLines
      .map<Widget>((List<String> nameAndText) => _toText(nameAndText[0], nameAndText[1]))
      .toList();

    final List<Widget> children = <Widget>[];
    for (Widget line in lines) {
      children.add(line);
      if (line != lines.last)
        children.add(new SpeakerSeparator());
    }

    return new GestureDetector(
      onTap: _handleTap,
      child: new Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: new Column(
          children: children,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start
        )
      )
    );
  }
}

void main() {
  runApp(new MaterialApp(
    theme: new ThemeData.light(),
    home: new Scaffold(
      appBar: new AppBar(
        title: const Text('Hal and Dave')
      ),
      body: new Material(
        color: Colors.grey.shade50,
        child: new StyledTextDemo()
      )
    )
  ));
}
