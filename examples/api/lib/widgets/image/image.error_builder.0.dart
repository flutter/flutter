// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for Image.errorBuilder

import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  static const String _title = 'Flutter Code Sample';

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: _title,
      home: Scaffold(
        body: Center(
          child: MyStatelessWidget(),
        ),
      ),
    );
  }
}

class MyStatelessWidget extends StatelessWidget {
  const MyStatelessWidget({Key? key}) : super(key: key);

  @override
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
}
