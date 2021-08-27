// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Template: dev/snippets/config/templates/stateless_widget_material.tmpl
//
// Comment lines marked with "▼▼▼" and "▲▲▲" are used for authoring
// of samples, and may be ignored if you are just exploring the sample.

// Flutter code sample for Image.errorBuilder
//
//***************************************************************************
//* ▼▼▼▼▼▼▼▼ description ▼▼▼▼▼▼▼▼ (do not modify or remove section marker)

// The following sample uses [errorBuilder] to show a '😢' in place of the
// image that fails to load, and prints the error to the console.

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

/// This is the stateless widget that the main application instantiates.
class MyStatelessWidget extends StatelessWidget {
  const MyStatelessWidget({Key? key}) : super(key: key);

  @override
//********************************************************************
//* ▼▼▼▼▼▼▼▼ code ▼▼▼▼▼▼▼▼ (do not modify or remove section marker)

  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Image.network(
        'https://example.does.not.exist/image.jpg',
        errorBuilder:
            (BuildContext context, Object exception, StackTrace? stackTrace) {
          // Appropriate logging or analytics, e.g.
          // myAnalytics.recordError(
          //   'An error occurred loading "https://example.does.not.exist/image.jpg"',
          //   exception,
          //   stackTrace,
          // );
          return const Text('😢');
        },
      ),
    );
  }

//* ▲▲▲▲▲▲▲▲ code ▲▲▲▲▲▲▲▲ (do not modify or remove section marker)
//********************************************************************

}
