// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_semantics.dart';

void main() {
  testWidgets('Semantics 8 - Merging with reset', (WidgetTester tester) async {
    TestSemanticsListener client = new TestSemanticsListener();

    await tester.pumpWidget(
      new MergeSemantics(
        child: new Semantics(
          container: true,
          child: new Semantics(
            container: true,
            child: new Stack(
              children: <Widget>[
                new Semantics(
                  checked: true
                ),
                new Semantics(
                  label: 'label'
                )
              ]
            )
          )
        )
      )
    );
    expect(client.updates.length, equals(2));
    expect(client.updates[0].id, equals(0));
    expect(client.updates[0].flags.canBeTapped, isFalse);
    expect(client.updates[0].flags.canBeLongPressed, isFalse);
    expect(client.updates[0].flags.canBeScrolledHorizontally, isFalse);
    expect(client.updates[0].flags.canBeScrolledVertically, isFalse);
    expect(client.updates[0].flags.hasCheckedState, isTrue);
    expect(client.updates[0].flags.isChecked, isTrue);
    expect(client.updates[0].strings.label, equals('label'));
    expect(client.updates[0].geometry.transform, isNull);
    expect(client.updates[0].geometry.left, equals(0.0));
    expect(client.updates[0].geometry.top, equals(0.0));
    expect(client.updates[0].geometry.width, equals(800.0));
    expect(client.updates[0].geometry.height, equals(600.0));
    expect(client.updates[0].children.length, equals(0));
    expect(client.updates[1], isNull);
    client.updates.clear();

    // switch the order of the inner Semantics node to trigger a reset
    await tester.pumpWidget(
      new MergeSemantics(
        child: new Semantics(
          container: true,
          child: new Semantics(
            container: true,
            child: new Stack(
              children: <Widget>[
                new Semantics(
                  label: 'label'
                ),
                new Semantics(
                  checked: true
                )
              ]
            )
          )
        )
      )
    );
    expect(client.updates.length, equals(2));
    expect(client.updates[0].id, equals(0));
    expect(client.updates[0].flags.canBeTapped, isFalse);
    expect(client.updates[0].flags.canBeLongPressed, isFalse);
    expect(client.updates[0].flags.canBeScrolledHorizontally, isFalse);
    expect(client.updates[0].flags.canBeScrolledVertically, isFalse);
    expect(client.updates[0].flags.hasCheckedState, isTrue);
    expect(client.updates[0].flags.isChecked, isTrue);
    expect(client.updates[0].strings.label, equals('label'));
    expect(client.updates[0].geometry.transform, isNull);
    expect(client.updates[0].geometry.left, equals(0.0));
    expect(client.updates[0].geometry.top, equals(0.0));
    expect(client.updates[0].geometry.width, equals(800.0));
    expect(client.updates[0].geometry.height, equals(600.0));
    expect(client.updates[0].children.length, equals(0));
    expect(client.updates[1], isNull);
    client.updates.clear();

  });
}
