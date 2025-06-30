// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [Badge.count] with `maxCount`.
void main() => runApp(const BadgeMaxCountExampleApp());

class BadgeMaxCountExampleApp extends StatelessWidget {
  const BadgeMaxCountExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Badge Max Count Sample')),
        body: const BadgeMaxCountExample(),
      ),
    );
  }
}

class BadgeMaxCountExample extends StatelessWidget {
  const BadgeMaxCountExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          IconButton(
            icon: Badge.count(count: 1000, maxCount: 99, child: const Icon(Icons.notifications)),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
