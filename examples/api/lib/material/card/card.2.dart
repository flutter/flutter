// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [Card].

void main() {
  runApp(const CardExamplesApp());
}

class CardExamplesApp extends StatelessWidget {
  const CardExamplesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Card Examples')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Card(
                child: SizedBox(
                  width: 300,
                  height: 100,
                  child: Center(child: Text('Elevated Card')),
                ),
              ),
              Card.filled(
                child: SizedBox(
                  width: 300,
                  height: 100,
                  child: Center(child: Text('Filled Card')),
                ),
              ),
              Card.outlined(
                child: SizedBox(
                  width: 300,
                  height: 100,
                  child: Center(child: Text('Outlined Card')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
