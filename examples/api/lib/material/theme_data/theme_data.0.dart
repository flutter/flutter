// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for ThemeData

import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  static const String _title = 'ThemeData Sample';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _title,
      home: Scaffold(
        appBar: AppBar(title: const Text(_title)),
        body: const MyStatelessWidget(),
      ),
    );
  }
}

class MyStatelessWidget extends StatelessWidget {
  const MyStatelessWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.from(
        // Setting the colorScheme here sets the color scheme for
        // all the descendants of the Theme widget.
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.amber),
      ),
      child: Builder(
        builder: (BuildContext context) {
          return Container(
            width: 100,
            height: 100,
            color: Theme.of(context).colorScheme.primary,
          );
        },
      ),
    );
  }
}
