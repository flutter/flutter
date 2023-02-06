// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Flutter code sample for [Divider].

import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(colorSchemeSeed: const Color(0xff6750a4), useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(title: const Text('Divider Sample')),
        body: const DividerExample(),
      ),
    );
  }
}

class DividerExample extends StatelessWidget {
  const DividerExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: const <Widget>[
            Expanded(
              child: Card(
                child: SizedBox.expand(),
              ),
            ),
            VerticalDivider(),
            Expanded(
              child: Card(
                child: SizedBox.expand(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
