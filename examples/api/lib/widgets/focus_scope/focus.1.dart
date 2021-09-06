// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Template: dev/snippets/config/templates/stateless_widget_material.tmpl
//
// Comment lines marked with "▼▼▼" and "▲▲▲" are used for authoring
// of samples, and may be ignored if you are just exploring the sample.

// Flutter code sample for Focus
//
//***************************************************************************
//* ▼▼▼▼▼▼▼▼ description ▼▼▼▼▼▼▼▼ (do not modify or remove section marker)

// This example shows how to wrap another widget in a [Focus] widget to make it
// focusable. It wraps a [Container], and changes the container's color when it
// is set as the [FocusManager.primaryFocus].
//
// If you also want to handle mouse hover and/or keyboard actions on a widget,
// consider using a [FocusableActionDetector], which combines several different
// widgets to provide those capabilities.

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
    return const MaterialApp(
      title: _title,
      home: MyStatelessWidget(),
    );
  }
}

//*****************************************************************************
//* ▼▼▼▼▼▼▼▼ code-preamble ▼▼▼▼▼▼▼▼ (do not modify or remove section marker)

class FocusableText extends StatelessWidget {
  const FocusableText(
    this.data, {
    Key? key,
    required this.autofocus,
  }) : super(key: key);

  /// The string to display as the text for this widget.
  final String data;

  /// Whether or not to focus this widget initially if nothing else is focused.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: autofocus,
      child: Builder(builder: (BuildContext context) {
        // The contents of this Builder are being made focusable. It is inside
        // of a Builder because the builder provides the correct context
        // variable for Focus.of() to be able to find the Focus widget that is
        // the Builder's parent. Without the builder, the context variable used
        // would be the one given the FocusableText build function, and that
        // would start looking for a Focus widget ancestor of the FocusableText
        // instead of finding the one inside of its build function.
        return Container(
          padding: const EdgeInsets.all(8.0),
          // Change the color based on whether or not this Container has focus.
          color: Focus.of(context).hasPrimaryFocus ? Colors.black12 : null,
          child: Text(data),
        );
      }),
    );
  }
}

//* ▲▲▲▲▲▲▲▲ code-preamble ▲▲▲▲▲▲▲▲ (do not modify or remove section marker)
//*****************************************************************************

/// This is the stateless widget that the main application instantiates.
class MyStatelessWidget extends StatelessWidget {
  const MyStatelessWidget({Key? key}) : super(key: key);

  @override
//********************************************************************
//* ▼▼▼▼▼▼▼▼ code ▼▼▼▼▼▼▼▼ (do not modify or remove section marker)

  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemBuilder: (BuildContext context, int index) => FocusableText(
          'Item $index',
          autofocus: index == 0,
        ),
        itemCount: 50,
      ),
    );
  }

//* ▲▲▲▲▲▲▲▲ code ▲▲▲▲▲▲▲▲ (do not modify or remove section marker)
//********************************************************************

}
