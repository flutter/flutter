// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'semantics_tester.dart';

void main() {
  testWidgets('can cease to be semantics boundary after markNeedsSemanticsUpdate() has already been called once', (final WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      buildTestWidgets(
        excludeSemantics: false,
        label: 'label',
        isSemanticsBoundary: true,
      ),
    );

    // The following should not trigger an assert.
    await tester.pumpWidget(
      buildTestWidgets(
        excludeSemantics: true,
        label: 'label CHANGED',
        isSemanticsBoundary: false,
      ),
    );

    semantics.dispose();
  });
}

Widget buildTestWidgets({
  required final bool excludeSemantics,
  required final String label,
  required final bool isSemanticsBoundary,
}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Semantics(
      label: 'container',
      container: true,
      child: ExcludeSemantics(
        excluding: excludeSemantics,
        child: TestWidget(
          label: label,
          isSemanticBoundary: isSemanticsBoundary,
          child: Column(
            children: <Widget>[
              Semantics(
                label: 'child1',
              ),
              Semantics(
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
    super.key,
    required Widget super.child,
    required this.label,
    required this.isSemanticBoundary,
  });

  final String label;
  final bool isSemanticBoundary;

  @override
  RenderTest createRenderObject(final BuildContext context) {
    return RenderTest()
      ..label = label
      ..isSemanticBoundary = isSemanticBoundary;
  }

  @override
  void updateRenderObject(final BuildContext context, final RenderTest renderObject) {
    renderObject
      ..label = label
      ..isSemanticBoundary = isSemanticBoundary;
  }
}

class RenderTest extends RenderProxyBox {
  @override
  void describeSemanticsConfiguration(final SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);

    if (!_isSemanticBoundary) {
      return;
    }

    config
      ..isSemanticBoundary = _isSemanticBoundary
      ..label = _label
      ..textDirection = TextDirection.ltr;

  }

  String get label => _label;
  String _label = '<>';
  set label(final String value) {
    if (value == _label) {
      return;
    }
    _label = value;
    markNeedsSemanticsUpdate();
  }


  bool get isSemanticBoundary => _isSemanticBoundary;
  bool _isSemanticBoundary = false;
  set isSemanticBoundary(final bool value) {
    if (_isSemanticBoundary == value) {
      return;
    }
    _isSemanticBoundary = value;
    markNeedsSemanticsUpdate();
  }
}
