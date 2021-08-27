// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Template: dev/snippets/config/templates/stateless_widget_scaffold_center.tmpl
//
// Comment lines marked with "▼▼▼" and "▲▲▲" are used for authoring
// of samples, and may be ignored if you are just exploring the sample.

// Flutter code sample for Tooltip
//
//***************************************************************************
//* ▼▼▼▼▼▼▼▼ description ▼▼▼▼▼▼▼▼ (do not modify or remove section marker)

// This example covers most of the attributes available in Tooltip.
// `decoration` has been used to give a gradient and borderRadius to Tooltip.
// `height` has been used to set a specific height of the Tooltip.
// `preferBelow` is false, the tooltip will prefer showing above [Tooltip]'s child widget.
// However, it may show the tooltip below if there's not enough space
// above the widget.
// `textStyle` has been used to set the font size of the 'message'.
// `showDuration` accepts a Duration to continue showing the message after the long
// press has been released or the mouse pointer exits the child widget.
// `waitDuration` accepts a Duration for which a mouse pointer has to hover over the child
// widget before the tooltip is shown.

//* ▲▲▲▲▲▲▲▲ description ▲▲▲▲▲▲▲▲ (do not modify or remove section marker)
//***************************************************************************

import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

/// This is the main application widget.
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  static const String _title = 'Flutter Code Sample';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _title,
      home: Scaffold(
        appBar: AppBar(title: const Text(_title)),
        body: const Center(
          child: MyStatelessWidget(),
        ),
      ),
    );
  }
}

/// This is the stateless widget that the main application instantiates.
class MyStatelessWidget extends StatelessWidget {
  const MyStatelessWidget({Key? key}) : super(key: key);

  @override
//********************************************************************
//* ▼▼▼▼▼▼▼▼ code ▼▼▼▼▼▼▼▼ (do not modify or remove section marker)

  Widget build(BuildContext context) {
    return Tooltip(
      message: 'I am a Tooltip',
      child: const Text('Tap this text and hold down to show a tooltip.'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient:
            const LinearGradient(colors: <Color>[Colors.amber, Colors.red]),
      ),
      height: 50,
      padding: const EdgeInsets.all(8.0),
      preferBelow: false,
      textStyle: const TextStyle(
        fontSize: 24,
      ),
      showDuration: const Duration(seconds: 2),
      waitDuration: const Duration(seconds: 1),
    );
  }

//* ▲▲▲▲▲▲▲▲ code ▲▲▲▲▲▲▲▲ (do not modify or remove section marker)
//********************************************************************

}
