// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
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
        actions: <SemanticsAction>[SemanticsAction.scrollUp, SemanticsAction.scrollDown]),
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
        actions: <SemanticsAction>[SemanticsAction.scrollLeft, SemanticsAction.scrollRight]),
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

  testWidgets('All registered handlers for the gesture kind are called', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    final Set<String> logs = <String>{};
    final GlobalKey detectorKey = GlobalKey();

    await tester.pumpWidget(
      Center(
        child: GestureDetector(
          key: detectorKey,
          onHorizontalDragStart: (_) { logs.add('horizontal'); },
          onPanStart: (_) { logs.add('pan'); },
          child: Container(),
        ),
      ),
    );

    final int detectorId = detectorKey.currentContext.findRenderObject().debugSemantics.id;
    tester.binding.pipelineOwner.semanticsOwner.performAction(detectorId, SemanticsAction.scrollLeft);
    expect(logs, <String>{'horizontal', 'pan'});

    semantics.dispose();
  });

  testWidgets('Replacing recognizers should update semantic handlers', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    // How the test is set up:
    //  - Base state: RawGestureDetector with a HorizontalGR
    //  - Calling `introduceLayoutPerformer()` adds a `TestLayoutPerformer` as
    //    child of RawGestureDetector.
    //  - TestLayoutPerformer calls RawGestureDetector.replaceGestureRecognizers
    //    during layout phase, which replaces the recognizers with a TapGR.

    final Set<String> logs = <String>{};
    final GlobalKey<RawGestureDetectorState> detectorKey = GlobalKey();
    final VoidCallback performLayout = () {
      detectorKey.currentState.replaceGestureRecognizers(<Type, GestureRecognizerFactory>{
        TapGestureRecognizer: GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
          () => TapGestureRecognizer(),
          (TapGestureRecognizer instance) {
            instance
              ..onTap = () { logs.add('tap'); };
          },
        )
      });
    };

    bool hasLayoutPerformer = false;
    VoidCallback introduceLayoutPerformer;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setter) {
          introduceLayoutPerformer = () {
            setter(() {
              hasLayoutPerformer = true;
            });
          };
          return Center(
            child: RawGestureDetector(
              key: detectorKey,
              gestures: <Type, GestureRecognizerFactory>{
                HorizontalDragGestureRecognizer: GestureRecognizerFactoryWithHandlers<HorizontalDragGestureRecognizer>(
                  () => HorizontalDragGestureRecognizer(),
                  (HorizontalDragGestureRecognizer instance) {
                    instance
                      ..onStart = (_) { logs.add('horizontal'); };
                  },
                )
              },
              child: hasLayoutPerformer ? TestLayoutPerformer(performLayout: performLayout) : null,
            ),
          );
        },
      ),
    );

    final int detectorId = detectorKey.currentContext.findRenderObject().debugSemantics.id;
    tester.binding.pipelineOwner.semanticsOwner.performAction(detectorId, SemanticsAction.scrollLeft);
    expect(logs, <String>{'horizontal'});
    logs.clear();

    introduceLayoutPerformer();
    await tester.pumpAndSettle();

    tester.binding.pipelineOwner.semanticsOwner.performAction(detectorId, SemanticsAction.scrollLeft);
    tester.binding.pipelineOwner.semanticsOwner.performAction(detectorId, SemanticsAction.tap);
    expect(logs, <String>{'tap'});
    logs.clear();

    semantics.dispose();
  });
}

class TestLayoutPerformer extends SingleChildRenderObjectWidget {
  const TestLayoutPerformer({
    Key key,
    this.performLayout,
  }) : super(key: key);

  final VoidCallback performLayout;

  @override
  RenderTestLayoutPerformer createRenderObject(BuildContext context) {
    return RenderTestLayoutPerformer(performLayout: performLayout);
  }
}

class RenderTestLayoutPerformer extends RenderBox {
  RenderTestLayoutPerformer({VoidCallback performLayout}) : _performLayout = performLayout;

  VoidCallback _performLayout;

  @override
  void performLayout() {
    size = const Size(1, 1);
    if (_performLayout != null)
      _performLayout();
  }
}
