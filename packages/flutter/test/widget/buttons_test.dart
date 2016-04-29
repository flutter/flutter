// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test/test.dart';

import 'test_semantics.dart';

void main() {
  testWidgets('Does FlatButton contribute semantics', (WidgetTester tester) {
    TestSemanticsListener client = new TestSemanticsListener();
    tester.pumpWidget(
      new Material(
        child: new Center(
          child: new FlatButton(
            onPressed: () { },
            child: new Text('Hello')
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
    expect(client.updates[0].flags.hasCheckedState, isFalse);
    expect(client.updates[0].flags.isChecked, isFalse);
    expect(client.updates[0].strings.label, equals(''));
    expect(client.updates[0].geometry.transform, isNull);
    expect(client.updates[0].geometry.left, equals(0.0));
    expect(client.updates[0].geometry.top, equals(0.0));
    expect(client.updates[0].geometry.width, equals(800.0));
    expect(client.updates[0].geometry.height, equals(600.0));
    expect(client.updates[0].children.length, equals(1));
    expect(client.updates[0].children[0].id, equals(1));
    expect(client.updates[0].children[0].flags.canBeTapped, isTrue);
    expect(client.updates[0].children[0].flags.canBeLongPressed, isFalse);
    expect(client.updates[0].children[0].flags.canBeScrolledHorizontally, isFalse);
    expect(client.updates[0].children[0].flags.canBeScrolledVertically, isFalse);
    expect(client.updates[0].children[0].flags.hasCheckedState, isFalse);
    expect(client.updates[0].children[0].flags.isChecked, isFalse);
    expect(client.updates[0].children[0].strings.label, equals('Hello'));
    expect(client.updates[0].children[0].children.length, equals(0));
    expect(client.updates[1], isNull);
    client.updates.clear();
  });
}
