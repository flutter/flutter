// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_services/semantics.dart' as mojom;

import '../rendering/test_semantics_client.dart';

void main() {
  testWidgets('Semantics shutdown and restart', (WidgetTester tester) async {
    TestSemanticsClient client = new TestSemanticsClient(tester.binding.pipelineOwner);

    await tester.pumpWidget(
      new Container(
        child: new Semantics(
          label: 'test1',
          child: new Container()
        )
      )
    );

    void checkUpdates(List<mojom.SemanticsNode> updates) {
      expect(updates.length, equals(1));
      expect(updates[0].id, equals(0));
      expect(updates[0].actions, isEmpty);
      expect(updates[0].flags.hasCheckedState, isFalse);
      expect(updates[0].flags.isChecked, isFalse);
      expect(updates[0].strings.label, equals('test1'));
      expect(updates[0].geometry.transform, isNull);
      expect(updates[0].geometry.left, equals(0.0));
      expect(updates[0].geometry.top, equals(0.0));
      expect(updates[0].geometry.width, equals(800.0));
      expect(updates[0].geometry.height, equals(600.0));
      expect(updates[0].children.length, equals(0));
    }

    checkUpdates(client.updates);
    client.updates.clear();
    client.dispose();

    expect(tester.binding.hasScheduledFrame, isFalse);
    client = new TestSemanticsClient(tester.binding.pipelineOwner);
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pump();

    checkUpdates(client.updates);
    client.updates.clear();
    client.dispose();
  });

  testWidgets('Detach and reattach assert', (WidgetTester tester) async {
    TestSemanticsClient client = new TestSemanticsClient(tester.binding.pipelineOwner);
    GlobalKey key = new GlobalKey();

    await tester.pumpWidget(
      new Container(
        child: new Semantics(
          label: 'test1',
          child: new Semantics(
            key: key,
            container: true,
            label: 'test2a',
            child: new Container()
          )
        )
      )
    );

    expect(client.updates.length, equals(1));
    expect(client.updates[0].strings.label, equals('test1'));
    expect(client.updates[0].children.length, equals(1));
    expect(client.updates[0].children[0].strings.label, equals('test2a'));
    client.updates.clear();

    await tester.pumpWidget(
      new Container(
        child: new Semantics(
          label: 'test1',
          child: new Semantics(
            container: true,
            label: 'middle',
            child: new Semantics(
              key: key,
              container: true,
              label: 'test2b',
              child: new Container()
            )
          )
        )
      )
    );

    expect(client.updates.length, equals(1));
    expect(client.updates[0].strings.label, equals('test1'));
    expect(client.updates[0].children.length, equals(1));
    expect(client.updates[0].children[0].strings.label, equals('middle'));
    expect(client.updates[0].children[0].children.length, equals(1));
    expect(client.updates[0].children[0].children[0].strings.label, equals('test2b'));
    expect(client.updates[0].children[0].children[0].children.length, equals(0));

    client.dispose();
  });
}
