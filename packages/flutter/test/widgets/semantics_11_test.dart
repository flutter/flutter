// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'semantics_tester.dart';

void main() {
  testWidgets('markNeedsSemanticsUpdate allways resets node', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    await tester.pumpWidget(const TestWidget());
    final RenderTest renderObj = tester.renderObject(find.byType(TestWidget));
    expect(renderObj.labelWasReset, hasLength(1));
    expect(renderObj.labelWasReset.last, true);
    expect(semantics, includesNodeWith(label: 'Label 1'));

    renderObj.markNeedsSemanticsUpdate(onlyLocalUpdates: false, noGeometry: false);
    await tester.pumpAndSettle();

    expect(renderObj.labelWasReset, hasLength(2));
    expect(renderObj.labelWasReset.last, true);
    expect(semantics, includesNodeWith(label: 'Label 2'));

    renderObj.markNeedsSemanticsUpdate(onlyLocalUpdates: true, noGeometry: false);
    await tester.pumpAndSettle();

    expect(renderObj.labelWasReset, hasLength(3));
    expect(renderObj.labelWasReset.last, true);
    expect(semantics, includesNodeWith(label: 'Label 3'));

    renderObj.markNeedsSemanticsUpdate(onlyLocalUpdates: true, noGeometry: true);
    await tester.pumpAndSettle();

    expect(renderObj.labelWasReset, hasLength(4));
    expect(renderObj.labelWasReset.last, true);
    expect(semantics, includesNodeWith(label: 'Label 4'));

    renderObj.markNeedsSemanticsUpdate(onlyLocalUpdates: false, noGeometry: true);
    await tester.pumpAndSettle();

    expect(renderObj.labelWasReset, hasLength(5));
    expect(renderObj.labelWasReset.last, true);
    expect(semantics, includesNodeWith(label: 'Label 5'));

    semantics.dispose();
  });
}

class TestWidget extends SingleChildRenderObjectWidget {
  const TestWidget({
    Key key,
    Widget child,
  }) : super(key: key, child: child);

  @override
  RenderTest createRenderObject(BuildContext context) {
    return new RenderTest();
  }
}

class RenderTest extends RenderProxyBox {
  List<bool> labelWasReset = <bool>[];

  @override
  SemanticsAnnotator get semanticsAnnotator => _annotate;

  void _annotate(SemanticsNode node) {
    labelWasReset.add(node.label == '');
    node.label = "Label ${labelWasReset.length}";
    node.textDirection = TextDirection.ltr;
  }
}
