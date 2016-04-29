// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_semantics.dart';

void main() {
  testWidgets('Semantics 5', (WidgetTester tester) async {
    TestSemanticsListener client = new TestSemanticsListener();

    await tester.pumpWidget(
      new Stack(
        children: <Widget>[
          new Semantics(
            // this tests that empty nodes disappear
          ),
          new Semantics(
            // this tests whether you can have a container with no other semantics
            container: true
          ),
          new Semantics(
            label: 'label' // (force a fork)
          ),
        ]
      )
    );
    expect(client.updates.length, equals(2));
    expect(client.updates[0].id, equals(0));
    expect(client.updates[0].flags.hasCheckedState, isFalse);
    expect(client.updates[0].strings.label, equals(''));
    expect(client.updates[0].children.length, equals(2));
    expect(client.updates[0].children[0].id, equals(1));
    expect(client.updates[0].children[0].flags.hasCheckedState, isFalse);
    expect(client.updates[0].children[0].strings.label, equals(''));
    expect(client.updates[0].children[1].id, equals(2));
    expect(client.updates[0].children[1].flags.hasCheckedState, isFalse);
    expect(client.updates[0].children[1].strings.label, equals('label'));
    expect(client.updates[1], isNull);
    client.updates.clear();

  });
}
