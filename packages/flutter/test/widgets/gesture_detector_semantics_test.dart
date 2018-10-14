// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'semantics_tester.dart';

void main() {
  testWidgets('Vertical gesture detector has up/down actions', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    int callCount = 0;
    final GlobalKey detectorKey = GlobalKey();

    await tester.pumpWidget(
      Center(
        child: GestureDetector(
          key: detectorKey,
          onVerticalDragStart: (DragStartDetails _) {
            callCount += 1;
          },
          child: Container(),
        ),
      )
    );

    expect(semantics, includesNodeWith(
        actions: <SemanticsAction>[SemanticsAction.scrollUp, SemanticsAction.scrollDown])
    );

    final int detectorId = detectorKey.currentContext.findRenderObject().debugSemantics.id;
    tester.binding.pipelineOwner.semanticsOwner.performAction(detectorId, SemanticsAction.scrollLeft);
    tester.binding.pipelineOwner.semanticsOwner.performAction(detectorId, SemanticsAction.scrollRight);
    expect(callCount, 0);
    tester.binding.pipelineOwner.semanticsOwner.performAction(detectorId, SemanticsAction.scrollUp);
    expect(callCount, 1);
    tester.binding.pipelineOwner.semanticsOwner.performAction(detectorId, SemanticsAction.scrollDown);
    expect(callCount, 2);

    semantics.dispose();
  });

  testWidgets('Horizontal gesture detector has up/down actions', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    int callCount = 0;
    final GlobalKey detectorKey = GlobalKey();

    await tester.pumpWidget(
        Center(
          child: GestureDetector(
            key: detectorKey,
            onHorizontalDragStart: (DragStartDetails _) {
              callCount += 1;
            },
            child: Container(),
          ),
        )
    );

    expect(semantics, includesNodeWith(
        actions: <SemanticsAction>[SemanticsAction.scrollLeft, SemanticsAction.scrollRight])
    );

    final int detectorId = detectorKey.currentContext.findRenderObject().debugSemantics.id;
    tester.binding.pipelineOwner.semanticsOwner.performAction(detectorId, SemanticsAction.scrollUp);
    tester.binding.pipelineOwner.semanticsOwner.performAction(detectorId, SemanticsAction.scrollDown);
    expect(callCount, 0);
    tester.binding.pipelineOwner.semanticsOwner.performAction(detectorId, SemanticsAction.scrollLeft);
    expect(callCount, 1);
    tester.binding.pipelineOwner.semanticsOwner.performAction(detectorId, SemanticsAction.scrollRight);
    expect(callCount, 2);

    semantics.dispose();
  });
}
