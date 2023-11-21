// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [InputDecoration.prefixIconConstraints].

void main() => runApp(const PrefixIconConstraintsExampleApp());

class PrefixIconConstraintsExampleApp extends StatelessWidget {
  const PrefixIconConstraintsExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(title: const Text('InputDecoration Sample')),
        body: const PrefixIconConstraintsExample(),
      ),
    );
  }
}

class PrefixIconConstraintsExample extends StatelessWidget {
  const PrefixIconConstraintsExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          TextField(
            decoration: const InputDecoration(
              hintText: 'Normal Icon Constraints',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            decoration: const InputDecoration(
              isDense: true,
              hintText: 'Smaller Icon Constraints',
              prefixIcon: Icon(Icons.search),
              prefixIconConstraints: BoxConstraints(
                minHeight: 32,
                minWidth: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
