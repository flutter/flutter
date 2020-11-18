// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Rendering Error', (WidgetTester tester) async {
    // This should fail with user created widget = Row.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: const Text('RenderFlex OverFlow'),
          ),
          body: Container(
            width: 400.0,
            child: Row(
              children: <Widget>[
                const Icon(Icons.message),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const <Widget>[
                    Text('Title'),
                    Text(
                      'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed '
                      'do eiusmod tempor incididunt ut labore et dolore magna '
                      'aliqua. Ut enim ad minim veniam, quis nostrud '
                      'exercitation ullamco laboris nisi ut aliquip ex ea '
                      'commodo consequat.'
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      )
    );
  });
}
