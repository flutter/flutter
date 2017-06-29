// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('OverflowEntries context contains Overlay',
      (WidgetTester tester) async {
    final GlobalKey overlayKey = new GlobalKey();
    bool didBuild = false;
    await tester.pumpWidget(new Overlay(
      key: overlayKey,
      initialEntries: <OverlayEntry>[
        new OverlayEntry(
          builder: (BuildContext context) {
            didBuild = true;
            final Overlay overlay = context.ancestorWidgetOfExactType(Overlay);
            expect(overlay, isNotNull);
            expect(overlay.key, equals(overlayKey));
            return new Container();
          },
        )
      ],
    ));
    expect(didBuild, isTrue);
    final RenderObject theater = overlayKey.currentContext.findRenderObject();

    // TODO(jacobr): toStringDeep output is missing a trailing line break.
    expect(theater, isNot(hasAGoodToStringDeep));
    expect(
      theater.toStringDeep(),
      equalsIgnoringHashCodes(
        '_RenderTheatre#00000\n'
        ' │ creator: _Theatre ← Overlay-[GlobalKey#00000] ← [root]\n'
        ' │ parentData: <none>\n'
        ' │ constraints: BoxConstraints(w=800.0, h=600.0)\n'
        ' │ size: Size(800.0, 600.0)\n'
        ' │\n'
        ' ├─onstage: RenderStack#00000\n'
        ' ╎ │ creator: Stack ← _Theatre ← Overlay-[GlobalKey#00000] ← [root]\n'
        ' ╎ │ parentData: not positioned; offset=Offset(0.0, 0.0) (can use\n'
        ' ╎ │   size)\n'
        ' ╎ │ constraints: BoxConstraints(w=800.0, h=600.0)\n'
        ' ╎ │ size: Size(800.0, 600.0)\n'
        ' ╎ │ alignment: FractionalOffset(0.0, 0.0)\n'
        ' ╎ │ fit: StackFit.expand\n'
        ' ╎ │ overflow: Overflow.clip\n'
        ' ╎ │\n'
        ' ╎ └─child 1: RenderLimitedBox#00000\n'
        ' ╎   │ creator: LimitedBox ← Container ←\n'
        ' ╎   │   _OverlayEntry-[LabeledGlobalKey<_OverlayEntryState>#00000] ←\n'
        ' ╎   │   Stack ← _Theatre ← Overlay-[GlobalKey#00000] ← [root]\n'
        ' ╎   │ parentData: not positioned; offset=Offset(0.0, 0.0) (can use\n'
        ' ╎   │   size)\n'
        ' ╎   │ constraints: BoxConstraints(w=800.0, h=600.0)\n'
        ' ╎   │ size: Size(800.0, 600.0)\n'
        ' ╎   │ maxWidth: 0.0\n'
        ' ╎   │ maxHeight: 0.0\n'
        ' ╎   │\n'
        ' ╎   └─child: RenderConstrainedBox#00000\n'
        ' ╎       creator: ConstrainedBox ← LimitedBox ← Container ←\n'
        ' ╎         _OverlayEntry-[LabeledGlobalKey<_OverlayEntryState>#00000] ←\n'
        ' ╎         Stack ← _Theatre ← Overlay-[GlobalKey#00000] ← [root]\n'
        ' ╎       parentData: <none> (can use size)\n'
        ' ╎       constraints: BoxConstraints(w=800.0, h=600.0)\n'
        ' ╎       size: Size(800.0, 600.0)\n'
        ' ╎       additionalConstraints: BoxConstraints(biggest)\n'
        ' ╎\n'
        ' └╌no offstage children',
      ),
    );

    // TODO(jacobr): add a test with offstage children.
  });
}
