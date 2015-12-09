// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

typedef Widget TextTransformer(String name, String text);

class StyledTextApp extends StatefulComponent {
  StyledTextAppState createState() => new StyledTextAppState();
}

class StyledTextAppState extends State<StyledTextApp> {
  void initState() {
    super.initState();
    toText = toStyledText;
    nameLines = dialogText
      .split('\n')
      .map((String line) => line.split(':'))
      .toList();
  }

  TextTransformer toText;

  // From https://en.wikiquote.org/wiki/2001:_A_Space_Odyssey_(film)
  final String dialogText = '''
Dave: Open the pod bay doors, please, HAL. Open the pod bay doors, please, HAL. Hello, HAL. Do you read me? Hello, HAL. Do you read me? Do you read me, HAL?
HAL: Affirmative, Dave. I read you.
Dave: Open the pod bay doors, HAL.
HAL: I'm sorry, Dave. I'm afraid I can't do that.
Dave: What's the problem?
HAL: I think you know what the problem is just as well as I do.
Dave: What are you talking about, HAL?
HAL: This mission is too important for me to allow you to jeopardize it.''';

  // [["Dave", "Open the pod bay..."] ...]
  List<List<String>> nameLines;

  final TextStyle daveStyle = new TextStyle(color: Colors.indigo[400], height: 1.8);
  final TextStyle halStyle = new TextStyle(color: Colors.red[400], fontFamily: "monospace");
  final TextStyle boldStyle = const TextStyle(fontWeight: FontWeight.bold);
  final TextStyle underlineStyle = const TextStyle(
    decoration: TextDecoration.underline,
    decorationColor: const Color(0xFF000000),
    decorationStyle: TextDecorationStyle.wavy
  );

  Widget toStyledText(String name, String text) {
    TextStyle lineStyle = (name == "Dave") ? daveStyle : halStyle;
    return new StyledText(
      key: new Key(text),
      elements: [lineStyle, [boldStyle, [underlineStyle, name], ":"], text]
    );
  }

  Widget toPlainText(String name, String text) => new Text(name + ":" + text);

  Widget createSeparator() {
    return new Container(
      constraints: const BoxConstraints.expand(height: 0.0),
      margin: const EdgeDims.symmetric(vertical: 10.0, horizontal: 64.0),
      decoration: const BoxDecoration(
        border: const Border(
          bottom: const BorderSide(color: const Color.fromARGB(24, 0, 0, 0))
        )
      )
    );
  }

  void toggleToTextFunction(_) {
    setState(() {
      toText = (toText == toPlainText) ? toStyledText : toPlainText;
    });
  }

  Widget build(BuildContext context) {
    List<Widget> lines = nameLines
      .map((List<String> nameAndText) => Function.apply(toText, nameAndText))
      .toList();

    List<Widget> children = <Widget>[];
    for (Widget line in lines) {
      children.add(line);
      if (line != lines.last) {
        children.add(createSeparator());
      }
    }

    Widget body = new Container(
        padding: new EdgeDims.symmetric(horizontal: 8.0),
        child: new Column(children,
          justifyContent: FlexJustifyContent.center,
          alignItems: FlexAlignItems.start
        )
      );

    Listener interactiveBody = new Listener(
      child: body,
      onPointerDown: toggleToTextFunction
    );

    return new Theme(
      data: new ThemeData.light(),
      child: new Scaffold(
        body: new Material(
          color: Colors.grey[50],
          child: interactiveBody
        ),
        toolBar: new ToolBar(
          center: new Text('Hal and Dave')
        )
      )
    );
  }
}

void main() {
  runApp(new StyledTextApp());
}
