// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_semantics.dart';

void main() {
  testWidgets('Semantics 4', (WidgetTester tester) async {
    TestSemanticsListener client = new TestSemanticsListener(tester);

    //    O
    //   / \       O=root
    //  L   L      L=node with label
    //     / \     C=node with checked
    //    C   C*   *=node removed next pass
    //
    await tester.pumpWidget(
      new Stack(
        children: <Widget>[
          new Semantics(
            label: 'L1'
          ),
          new Semantics(
            label: 'L2',
            child: new Stack(
              children: <Widget>[
                new Semantics(
                  checked: true
                ),
                new Semantics(
                  checked: false
                )
              ]
            )
          )
        ]
      )
    );
    expect(client.updates.length, equals(2));
    expect(client.updates[0].id, equals(0));
    expect(client.updates[0].children.length, equals(2));
    expect(client.updates[0].children[0].id, equals(1));
    expect(client.updates[0].children[0].children.length, equals(0));
    expect(client.updates[0].children[1].id, equals(2));
    expect(client.updates[0].children[1].children.length, equals(2));
    expect(client.updates[0].children[1].children[0].id, equals(3));
    expect(client.updates[0].children[1].children[0].children.length, equals(0));
    expect(client.updates[0].children[1].children[1].id, equals(4));
    expect(client.updates[0].children[1].children[1].children.length, equals(0));
    expect(client.updates[1], isNull);
    client.updates.clear();

    //    O        O=root
    //   / \       L=node with label
    //  L* LC      C=node with checked
    //             *=node removed next pass
    //
    await tester.pumpWidget(
      new Stack(
        children: <Widget>[
          new Semantics(
            label: 'L1'
          ),
          new Semantics(
            label: 'L2',
            child: new Stack(
              children: <Widget>[
                new Semantics(
                  checked: true
                ),
                new Semantics()
              ]
            )
          )
        ]
      )
    );
    expect(client.updates.length, equals(2));
    expect(client.updates[0].id, equals(2));
    expect(client.updates[0].children.length, equals(0));
    expect(client.updates[1], isNull);
    client.updates.clear();

    //             O=root
    //    OLC      L=node with label
    //             C=node with checked
    //
    await tester.pumpWidget(
      new Stack(
        children: <Widget>[
          new Semantics(),
          new Semantics(
            label: 'L2',
            child: new Stack(
              children: <Widget>[
                new Semantics(
                  checked: true
                ),
                new Semantics()
              ]
            )
          )
        ]
      )
    );
    expect(client.updates.length, equals(2));
    expect(client.updates[0].id, equals(0));
    expect(client.updates[0].children.length, equals(0));
    expect(client.updates[1], isNull);
    client.updates.clear();

  });
}
