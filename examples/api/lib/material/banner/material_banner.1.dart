// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Flutter code sample for [MaterialBanner].

import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const String _title = 'Flutter Code Sample';

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: _title,
      home: MyStatelessWidget(),
    );
  }
}

class MyStatelessWidget extends StatelessWidget {
  const MyStatelessWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('The MaterialBanner is below'),
      ),
      body: Center(
        child: ElevatedButton(
          child: const Text('Show MaterialBanner'),
          onPressed: () => ScaffoldMessenger.of(context).showMaterialBanner(
            const MaterialBanner(
              padding: EdgeInsets.all(20),
              content: Text('Hello, I am a Material Banner'),
              leading: Icon(Icons.agriculture_outlined),
              backgroundColor: Colors.green,
              actions: <Widget>[
                TextButton(
                  onPressed: null,
                  child: Text('DISMISS'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
