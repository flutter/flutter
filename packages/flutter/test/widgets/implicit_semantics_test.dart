// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'semantics_tester.dart';

void main() {
  testWidgets('Semantics 1', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    await tester.pumpWidget(
        new Semantics(
          container: true,
          forceExplicitChildNodes: true,
          child: new Column(
              children: <Widget>[
                const Text('Michael Goderbauer'),
                const Text('goderbauer@google.com'),
              ]
          ),
        ),
    );

    //SemanticsNode(label: "Michael Goderbauer\ngoderbauer@google.com")

    await tester.pumpWidget(
      new Semantics(
        container: true,
        forceExplicitChildNodes: false,
        child: new Column(
            children: <Widget>[
              const Text('Michael Goderbauer'),
              const Text('goderbauer@google.com'),
            ]
        ),
      ),
    );

    //SemanticsNode()
    //   - SemanticsNode(label: "Michael Goderbauer")
    //   - SemanticsNode(label: "goderbauer@google.com")

    await tester.pumpWidget(
      new Semantics(
        container: true,
        forceExplicitChildNodes: false,
        child: new Semantics(
          label: "Signed in as ",
          child: new Column(
              children: <Widget>[
                const Text('Michael Goderbauer'),
                const Text('goderbauer@google.com'),
              ]
          ),
        ),
      ),
    );

    //SemanticsNode()
    //   - SemanticsNode(label: "Signed in as Michael Goderbauer\ngoderbauer@google.com")

    await tester.pumpWidget(
      new Semantics(
        container: true,
        forceExplicitChildNodes: true,
        child: new Semantics(
          label: "Signed in as ",
          child: new Column(
              children: <Widget>[
                const Text('Michael Goderbauer'),
                const Text('goderbauer@google.com'),
              ]
          ),
        ),
      ),
    );

    //SemanticsNode(label: "Signed in as Michael Goderbauer\ngoderbauer@google.com")

    semantics.dispose();
  });
}
