// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'semantics_tester.dart';

void main() {
  testWidgets('Semantics 1', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    // smoketest
    await tester.pumpWidget(
      new Container(
        child: new Semantics(
          label: 'test1',
          child: new Container()
        )
      )
    );

    expect(semantics, hasSemantics(new TestSemantics.root(label: 'test1')));

    // control for forking
    await tester.pumpWidget(
      new Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          new Container(
            height: 10.0,
            child: const Semantics(label: 'child1')
          ),
          new Container(
            height: 10.0,
            child: const IgnorePointer(
              ignoring: true,
              child: const Semantics(label: 'child2')
            )
          ),
        ],
      )
    );

    expect(semantics, hasSemantics(new TestSemantics.root(label: 'child1')));

    // forking semantics
    await tester.pumpWidget(
      new Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          new Container(
            height: 10.0,
            child: const Semantics(label: 'child1')
          ),
          new Container(
            height: 10.0,
            child: const IgnorePointer(
              ignoring: false,
              child: const Semantics(label: 'child2')
            )
          ),
        ],
      )
    );

    expect(semantics, hasSemantics(
      new TestSemantics.root(
        children: <TestSemantics>[
          new TestSemantics.rootChild(
            id: 1,
            label: 'child1',
            rect: new Rect.fromLTRB(0.0, 0.0, 800.0, 10.0),
          ),
          new TestSemantics.rootChild(
            id: 2,
            label: 'child2',
            rect: new Rect.fromLTRB(0.0, 0.0, 800.0, 10.0),
            transform: new Matrix4.translationValues(0.0, 10.0, 0.0),
          ),
        ],
      )
    ));

    // toggle a branch off
    await tester.pumpWidget(
      new Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          new Container(
            height: 10.0,
            child: const Semantics(label: 'child1')
          ),
          new Container(
            height: 10.0,
            child: const IgnorePointer(
              ignoring: true,
              child: const Semantics(label: 'child2')
            )
          ),
        ],
      )
    );

    expect(semantics, hasSemantics(new TestSemantics.root(label: 'child1')));

    // toggle a branch back on
    await tester.pumpWidget(
      new Column(
        children: <Widget>[
          new Container(
            height: 10.0,
            child: const Semantics(label: 'child1')
          ),
          new Container(
            height: 10.0,
            child: const IgnorePointer(
              ignoring: false,
              child: const Semantics(label: 'child2')
            )
          ),
        ],
        crossAxisAlignment: CrossAxisAlignment.stretch
      )
    );

    expect(semantics, hasSemantics(
      new TestSemantics.root(
        children: <TestSemantics>[
          new TestSemantics.rootChild(
            id: 3,
            label: 'child1',
            rect: new Rect.fromLTRB(0.0, 0.0, 800.0, 10.0),
          ),
          new TestSemantics.rootChild(
            id: 2,
            label: 'child2',
            rect: new Rect.fromLTRB(0.0, 0.0, 800.0, 10.0),
            transform: new Matrix4.translationValues(0.0, 10.0, 0.0),
          ),
        ],
      )
    ));

    semantics.dispose();
  });
}
