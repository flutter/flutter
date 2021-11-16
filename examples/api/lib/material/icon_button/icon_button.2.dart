// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for IconButton

import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  static const String _title = 'Flutter Code Sample';

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
    return Center(
      // CircleAvatar does not have an underlying Material.
      child: CircleAvatar(
        // Provide a transparent Material when wrapping IconButton
        // with a widget that does not have an underlying Material.
        child: Material(
          // This is to clip Matrial shape for underlying CircleAvatar.
          // Clip behavior is none by default.
          clipBehavior: Clip.antiAliasWithSaveLayer,
          // This provides a splash effect over the CircleAvatar.
          type: MaterialType.transparency,
          // This is to match the CircleAvatar's shape.
          shape: const CircleBorder(),
          child: IconButton(
            icon: const Icon(Icons.android),
            onPressed: () {},
          ),
        ),
      ),
    );
  }
}
