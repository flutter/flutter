// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/test_semantics_client.dart';

void main() {
  testWidgets('Semantics 3', (WidgetTester tester) async {
    TestSemanticsClient client = new TestSemanticsClient(tester.binding.pipelineOwner);

    // implicit annotators
    await tester.pumpWidget(
      new Container(
        child: new Semantics(
          label: 'test',
          child: new Container(
            child: new Semantics(
              checked: true
            )
          )
        )
      )
    );
    expect(client.updates.length, equals(1));
    expect(client.updates[0].id, equals(0));
    expect(client.updates[0].actions, isEmpty);
    expect(client.updates[0].flags.hasCheckedState, isTrue);
    expect(client.updates[0].flags.isChecked, isTrue);
    expect(client.updates[0].strings.label, equals('test'));
    expect(client.updates[0].geometry.transform, isNull);
    expect(client.updates[0].geometry.left, equals(0.0));
    expect(client.updates[0].geometry.top, equals(0.0));
    expect(client.updates[0].geometry.width, equals(800.0));
    expect(client.updates[0].geometry.height, equals(600.0));
    expect(client.updates[0].children.length, equals(0));
    client.updates.clear();

    // remove one
    await tester.pumpWidget(
      new Container(
        child: new Container(
          child: new Semantics(
            checked: true
          )
        )
      )
    );
    expect(client.updates.length, equals(1));
    expect(client.updates[0].id, equals(0));
    expect(client.updates[0].actions, isEmpty);
    expect(client.updates[0].flags.hasCheckedState, isTrue);
    expect(client.updates[0].flags.isChecked, isTrue);
    expect(client.updates[0].strings.label, equals(''));
    expect(client.updates[0].geometry.transform, isNull);
    expect(client.updates[0].geometry.left, equals(0.0));
    expect(client.updates[0].geometry.top, equals(0.0));
    expect(client.updates[0].geometry.width, equals(800.0));
    expect(client.updates[0].geometry.height, equals(600.0));
    expect(client.updates[0].children.length, equals(0));
    client.updates.clear();

    // change what it says
    await tester.pumpWidget(
      new Container(
        child: new Container(
          child: new Semantics(
            label: 'test'
          )
        )
      )
    );
    expect(client.updates.length, equals(1));
    expect(client.updates[0].id, equals(0));
    expect(client.updates[0].actions, isEmpty);
    expect(client.updates[0].flags.hasCheckedState, isFalse);
    expect(client.updates[0].flags.isChecked, isFalse);
    expect(client.updates[0].strings.label, equals('test'));
    expect(client.updates[0].geometry.transform, isNull);
    expect(client.updates[0].geometry.left, equals(0.0));
    expect(client.updates[0].geometry.top, equals(0.0));
    expect(client.updates[0].geometry.width, equals(800.0));
    expect(client.updates[0].geometry.height, equals(600.0));
    expect(client.updates[0].children.length, equals(0));
    client.updates.clear();

    // add a node
    await tester.pumpWidget(
      new Container(
        child: new Semantics(
          checked: true,
          child: new Container(
            child: new Semantics(
              label: 'test'
            )
          )
        )
      )
    );
    expect(client.updates.length, equals(1));
    expect(client.updates[0].id, equals(0));
    expect(client.updates[0].actions, isEmpty);
    expect(client.updates[0].flags.hasCheckedState, isTrue);
    expect(client.updates[0].flags.isChecked, isTrue);
    expect(client.updates[0].strings.label, equals('test'));
    expect(client.updates[0].geometry.transform, isNull);
    expect(client.updates[0].geometry.left, equals(0.0));
    expect(client.updates[0].geometry.top, equals(0.0));
    expect(client.updates[0].geometry.width, equals(800.0));
    expect(client.updates[0].geometry.height, equals(600.0));
    expect(client.updates[0].children.length, equals(0));
    client.updates.clear();

    // make no changes
    await tester.pumpWidget(
      new Container(
        child: new Semantics(
          checked: true,
          child: new Container(
            child: new Semantics(
              label: 'test'
            )
          )
        )
      )
    );
    expect(client.updates.length, equals(0));
    client.dispose();
  });
}
