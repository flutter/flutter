// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/painting/text_style.dart';
import 'package:sky/rendering/box.dart';
import 'package:sky/rendering/flex.dart';
import 'package:sky/rendering/sky_binding.dart';
import 'package:sky/theme/colors.dart';
import 'package:sky/theme/typography.dart';
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/material.dart';
import 'package:sky/widgets/scaffold.dart';
import 'package:sky/widgets/tool_bar.dart';
import 'package:sky/widgets/widget.dart';


class StyledTextApp extends App {

  StyledTextApp() {
    toText = toStyledText;
    nameLines = dialogText
      .split('\n')
      .map((String line) => line.split(':'))
      .toList();
  }

  Function toText;

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

  final TextStyle daveStyle = new TextStyle(color: Indigo[400]);
  final TextStyle halStyle = new TextStyle(color: Red[400], fontFamily: "monospace");
  final TextStyle boldStyle = const TextStyle(fontWeight: bold);
  final TextStyle underlineStyle = const TextStyle(
    decoration: underline,
    decorationColor: const Color(0xFF000000),
    decorationStyle: TextDecorationStyle.wavy
  );
  
  Component toStyledText(String name, String text) {
    TextStyle lineStyle = (name == "Dave") ? daveStyle : halStyle;
    return new StyledText(
      key: text,
      elements: [lineStyle, [boldStyle, [underlineStyle, name], ":"], text]
    );
  }

  Component toPlainText(String name, String text) => new Text(name + ":" + text);

  Component createSeparator() {
    return new Container(
      constraints: const BoxConstraints(minWidth: double.INFINITY, maxHeight: 0.0),
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

  Widget build() {
    List<Component> lines = nameLines
      .map((nameAndText) => Function.apply(toText, nameAndText))
      .toList();

    List<Component> children = [];
    for (Component line in lines) {
      children.add(line);
      if (line != lines.last) {
        children.add(createSeparator());
      }
    }

    Container body = new Container(
        padding: new EdgeDims.symmetric(horizontal: 8.0),
        child: new Flex(children,
          direction: FlexDirection.vertical,
          justifyContent: FlexJustifyContent.center,
          alignItems: FlexAlignItems.flexStart
        )
      );

    Listener interactiveBody = new Listener(
      child: body,
      onPointerDown: toggleToTextFunction
    );

    return new Scaffold(
      body: new Material(child: interactiveBody),
      toolbar: new ToolBar(
        center: new Text('Hal and Dave', style: white.title),
        backgroundColor: Blue[500]
      )
    );
  }
}

void main() {
  runApp(new StyledTextApp());
  SkyBinding.instance.onFrame = () {
    // uncomment this for debugging:
    // SkyBinding.instance.debugDumpRenderTree();
  };
}
