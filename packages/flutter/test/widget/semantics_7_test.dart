// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test/test.dart';

import 'test_semantics.dart';
import 'package:sky_services/semantics/semantics.mojom.dart' as mojom;

void main() {
  testWidgets('Semantics 7 - Merging', (WidgetTester tester) {
      TestSemanticsListener client = new TestSemanticsListener();

      String label;

      label = '1';
      tester.pumpWidget(
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
      expect(client.updates[0].children.length, equals(2));
      expect(client.updates[0].children[0].id, equals(1));
      expect(client.updates[0].children[0].flags.canBeTapped, isFalse);
      expect(client.updates[0].children[0].flags.canBeLongPressed, isFalse);
      expect(client.updates[0].children[0].flags.canBeScrolledHorizontally, isFalse);
      expect(client.updates[0].children[0].flags.canBeScrolledVertically, isFalse);
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
      expect(client.updates[0].children[1].flags.canBeTapped, isFalse);
      expect(client.updates[0].children[1].flags.canBeLongPressed, isFalse);
      expect(client.updates[0].children[1].flags.canBeScrolledHorizontally, isFalse);
      expect(client.updates[0].children[1].flags.canBeScrolledVertically, isFalse);
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
      expect(client.updates[1], isNull);
      client.updates.clear();

      label = '2';
      tester.pumpWidget(
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
      expect(client.updates.length, equals(3));
      expect(client.updates[2], isNull);

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
      expect(a.flags.canBeTapped, isFalse);
      expect(a.flags.canBeLongPressed, isFalse);
      expect(a.flags.canBeScrolledHorizontally, isFalse);
      expect(a.flags.canBeScrolledVertically, isFalse);
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
      expect(b.flags.canBeTapped, isFalse);
      expect(b.flags.canBeLongPressed, isFalse);
      expect(b.flags.canBeScrolledHorizontally, isFalse);
      expect(b.flags.canBeScrolledVertically, isFalse);
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

  });
}
