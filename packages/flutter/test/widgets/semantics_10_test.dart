// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'semantics_tester.dart';

List<String> callLog = <String>[];

void main() {
  testWidgets('can call markNeedsSemanticsUpdate(onlyChanges: true) followed by markNeedsSemanticsUpdate(onlyChanges: false)', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    await tester.pumpWidget(
      buildTestWidgets(
        excludeSemantics: false,
        label: 'label',
        isSemanticsBoundary: true,
      ),
    );

    callLog.clear();

    // The following should not trigger an assert.
    await tester.pumpWidget(
      buildTestWidgets(
        excludeSemantics: true,
        label: 'label CHANGED',
        isSemanticsBoundary: false,
      ),
    );

    expect(callLog, <String>['markNeedsSemanticsUpdate(onlyChanges: true)', 'markNeedsSemanticsUpdate(onlyChanges: false)']);

    semantics.dispose();
  });
}

Widget buildTestWidgets({bool excludeSemantics, String label, bool isSemanticsBoundary}) {
  return new Directionality(
    textDirection: TextDirection.ltr,
    child: new Semantics(
      label: 'container',
      container: true,
      child: new ExcludeSemantics(
        excluding: excludeSemantics,
        child: new TestWidget(
          label: label,
          isSemanticBoundary: isSemanticsBoundary,
          child: new Column(
            children: <Widget>[
              const Semantics(
                label: 'child1',
              ),
              const Semantics(
                label: 'child2',
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class TestWidget extends SingleChildRenderObjectWidget {
  const TestWidget({
    Key key,
    Widget child,
    this.label,
    this.isSemanticBoundary,
  }) : super(key: key, child: child);

  final String label;
  final bool isSemanticBoundary;

  @override
  RenderTest createRenderObject(BuildContext context) {
    return new RenderTest()
      ..label = label
      ..isSemanticBoundary = isSemanticBoundary;
  }

  @override
  void updateRenderObject(BuildContext context, RenderTest renderObject) {
    renderObject
      ..label = label
      ..isSemanticBoundary = isSemanticBoundary;
  }
}

class RenderTest extends RenderProxyBox {
  @override
  SemanticsAnnotator get semanticsAnnotator => isSemanticBoundary ? _annotate : null;

  void _annotate(SemanticsNode node) {
    node.label = _label;
    node.textDirection = TextDirection.ltr;
  }

  String _label;
  set label(String value) {
    if (value == _label)
      return;
    _label = value;
    markNeedsSemanticsUpdate(onlyLocalUpdates: true);
    callLog.add('markNeedsSemanticsUpdate(onlyChanges: true)');
  }

  @override
  bool get isSemanticBoundary => _isSemanticBoundary;
  bool _isSemanticBoundary;
  set isSemanticBoundary(bool value) {
    if (_isSemanticBoundary == value)
      return;
    _isSemanticBoundary = value;
    markNeedsSemanticsUpdate(onlyLocalUpdates: false);
    callLog.add('markNeedsSemanticsUpdate(onlyChanges: false)');
  }
}
