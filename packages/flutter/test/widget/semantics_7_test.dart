// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_services/semantics.dart' as mojom;

import '../rendering/test_semantics_client.dart';

void main() {
  testWidgets('Semantics 7 - Merging', (WidgetTester tester) async {
    TestSemanticsClient client = new TestSemanticsClient(tester.binding.pipelineOwner);

    String label;

    label = '1';
    await tester.pumpWidget(
      new Stack(
        children: <Widget>[
          new MergeSemantics(
            child: new Semantics(
              checked: true,
              container: true,
              child: new Semantics(
                container: true,
                label: label
              )
            )
          ),
          new MergeSemantics(
            child: new Stack(
              children: <Widget>[
                new Semantics(
                  checked: true
                ),
                new Semantics(
                  label: label
                )
              ]
            )
          ),
        ]
      )
    );
    expect(client.updates.length, equals(1));
    expect(client.updates[0].id, equals(0));
    expect(client.updates[0].actions, isEmpty);
    expect(client.updates[0].flags.hasCheckedState, isFalse);
    expect(client.updates[0].flags.isChecked, isFalse);
    expect(client.updates[0].strings.label, equals(''));
    expect(client.updates[0].geometry.transform, isNull);
    expect(client.updates[0].geometry.left, equals(0.0));
    expect(client.updates[0].geometry.top, equals(0.0));
    expect(client.updates[0].geometry.width, equals(800.0));
    expect(client.updates[0].geometry.height, equals(600.0));
    expect(client.updates[0].children.length, equals(2));
    expect(client.updates[0].children[0].id, equals(1));
    expect(client.updates[0].children[0].actions, isEmpty);
    expect(client.updates[0].children[0].flags.hasCheckedState, isTrue);
    expect(client.updates[0].children[0].flags.isChecked, isTrue);
    expect(client.updates[0].children[0].strings.label, equals(label));
    expect(client.updates[0].children[0].geometry.transform, isNull);
    expect(client.updates[0].children[0].geometry.left, equals(0.0));
    expect(client.updates[0].children[0].geometry.top, equals(0.0));
    expect(client.updates[0].children[0].geometry.width, equals(800.0));
    expect(client.updates[0].children[0].geometry.height, equals(600.0));
    expect(client.updates[0].children[0].children.length, equals(0));
    // IDs 2 and 3 are used up by the nodes that get merged in
    expect(client.updates[0].children[1].id, equals(4));
    expect(client.updates[0].children[1].actions, isEmpty);
    expect(client.updates[0].children[1].flags.hasCheckedState, isTrue);
    expect(client.updates[0].children[1].flags.isChecked, isTrue);
    expect(client.updates[0].children[1].strings.label, equals(label));
    expect(client.updates[0].children[1].geometry.transform, isNull);
    expect(client.updates[0].children[1].geometry.left, equals(0.0));
    expect(client.updates[0].children[1].geometry.top, equals(0.0));
    expect(client.updates[0].children[1].geometry.width, equals(800.0));
    expect(client.updates[0].children[1].geometry.height, equals(600.0));
    expect(client.updates[0].children[1].children.length, equals(0));
    // IDs 5 and 6 are used up by the nodes that get merged in
    client.updates.clear();

    label = '2';
    await tester.pumpWidget(
      new Stack(
        children: <Widget>[
          new MergeSemantics(
            child: new Semantics(
              checked: true,
              container: true,
              child: new Semantics(
                container: true,
                label: label
              )
            )
          ),
          new MergeSemantics(
            child: new Stack(
              children: <Widget>[
                new Semantics(
                  checked: true
                ),
                new Semantics(
                  label: label
                )
              ]
            )
          ),
        ]
      )
    );
    expect(client.updates.length, equals(2));

    // The order of the nodes is undefined, so allow both orders.
    mojom.SemanticsNode a, b;
    if (client.updates[0].id == 1) {
      a = client.updates[0];
      b = client.updates[1];
    } else {
      a = client.updates[1];
      b = client.updates[0];
    }

    expect(a.id, equals(1));
    expect(a.actions, isEmpty);
    expect(a.flags.hasCheckedState, isTrue);
    expect(a.flags.isChecked, isTrue);
    expect(a.strings.label, equals(label));
    expect(a.geometry.transform, isNull);
    expect(a.geometry.left, equals(0.0));
    expect(a.geometry.top, equals(0.0));
    expect(a.geometry.width, equals(800.0));
    expect(a.geometry.height, equals(600.0));
    expect(a.children.length, equals(0));

    expect(b.id, equals(4));
    expect(b.actions, isEmpty);
    expect(b.flags.hasCheckedState, isTrue);
    expect(b.flags.isChecked, isTrue);
    expect(b.strings.label, equals(label));
    expect(b.geometry.transform, isNull);
    expect(b.geometry.left, equals(0.0));
    expect(b.geometry.top, equals(0.0));
    expect(b.geometry.width, equals(800.0));
    expect(b.geometry.height, equals(600.0));
    expect(b.children.length, equals(0));

    client.updates.clear();
    client.dispose();
  });
}
