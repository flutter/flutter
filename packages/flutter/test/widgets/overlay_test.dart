// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('OverflowEntries context contains Overlay',
      (WidgetTester tester) async {
    final GlobalKey overlayKey = GlobalKey();
    bool didBuild = false;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          key: overlayKey,
          initialEntries: <OverlayEntry>[
            OverlayEntry(
              builder: (BuildContext context) {
                didBuild = true;
                final Overlay overlay = context.ancestorWidgetOfExactType(Overlay);
                expect(overlay, isNotNull);
                expect(overlay.key, equals(overlayKey));
                return Container();
              },
            ),
          ],
        ),
      ),
    );
    expect(didBuild, isTrue);
    final RenderObject theater = overlayKey.currentContext.findRenderObject();

    expect(theater, hasAGoodToStringDeep);
    expect(
      theater.toStringDeep(minLevel: DiagnosticLevel.info),
      equalsIgnoringHashCodes(
        '_RenderTheatre#f5cf2\n'
            ' │ parentData: <none>\n'
            ' │ constraints: BoxConstraints(w=800.0, h=600.0)\n'
            ' │ size: Size(800.0, 600.0)\n'
            ' │\n'
            ' ├─onstage: RenderStack#39819\n'
            ' ╎ │ parentData: not positioned; offset=Offset(0.0, 0.0) (can use\n'
            ' ╎ │   size)\n'
            ' ╎ │ constraints: BoxConstraints(w=800.0, h=600.0)\n'
            ' ╎ │ size: Size(800.0, 600.0)\n'
            ' ╎ │ alignment: AlignmentDirectional.topStart\n'
            ' ╎ │ textDirection: ltr\n'
            ' ╎ │ fit: expand\n'
            ' ╎ │ overflow: clip\n'
            ' ╎ │\n'
            ' ╎ └─child 1: RenderLimitedBox#d1448\n'
            ' ╎   │ parentData: not positioned; offset=Offset(0.0, 0.0) (can use\n'
            ' ╎   │   size)\n'
            ' ╎   │ constraints: BoxConstraints(w=800.0, h=600.0)\n'
            ' ╎   │ size: Size(800.0, 600.0)\n'
            ' ╎   │ maxWidth: 0.0\n'
            ' ╎   │ maxHeight: 0.0\n'
            ' ╎   │\n'
            ' ╎   └─child: RenderConstrainedBox#e8b87\n'
            ' ╎       parentData: <none> (can use size)\n'
            ' ╎       constraints: BoxConstraints(w=800.0, h=600.0)\n'
            ' ╎       size: Size(800.0, 600.0)\n'
            ' ╎       additionalConstraints: BoxConstraints(biggest)\n'
            ' ╎\n'
            ' └╌no offstage children\n'
      ),
    );
  });

  testWidgets('Offstage overlay', (WidgetTester tester) async {
    final GlobalKey overlayKey = GlobalKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          key: overlayKey,
          initialEntries: <OverlayEntry>[
            OverlayEntry(
              opaque: true,
              maintainState: true,
              builder: (BuildContext context) => Container(),
            ),
            OverlayEntry(
              opaque: true,
              maintainState: true,
              builder: (BuildContext context) => Container(),
            ),
            OverlayEntry(
              opaque: true,
              maintainState: true,
              builder: (BuildContext context) => Container(),
            ),
          ],
        ),
      ),
    );
    final RenderObject theater = overlayKey.currentContext.findRenderObject();

    expect(theater, hasAGoodToStringDeep);
    expect(
      theater.toStringDeep(minLevel: DiagnosticLevel.info),
      equalsIgnoringHashCodes(
        '_RenderTheatre#b22a8\n'
        ' │ parentData: <none>\n'
        ' │ constraints: BoxConstraints(w=800.0, h=600.0)\n'
        ' │ size: Size(800.0, 600.0)\n'
        ' │\n'
        ' ├─onstage: RenderStack#eab87\n'
        ' ╎ │ parentData: not positioned; offset=Offset(0.0, 0.0) (can use\n'
        ' ╎ │   size)\n'
        ' ╎ │ constraints: BoxConstraints(w=800.0, h=600.0)\n'
        ' ╎ │ size: Size(800.0, 600.0)\n'
        ' ╎ │ alignment: AlignmentDirectional.topStart\n'
        ' ╎ │ textDirection: ltr\n'
        ' ╎ │ fit: expand\n'
        ' ╎ │ overflow: clip\n'
        ' ╎ │\n'
        ' ╎ └─child 1: RenderLimitedBox#ca15b\n'
        ' ╎   │ parentData: not positioned; offset=Offset(0.0, 0.0) (can use\n'
        ' ╎   │   size)\n'
        ' ╎   │ constraints: BoxConstraints(w=800.0, h=600.0)\n'
        ' ╎   │ size: Size(800.0, 600.0)\n'
        ' ╎   │ maxWidth: 0.0\n'
        ' ╎   │ maxHeight: 0.0\n'
        ' ╎   │\n'
        ' ╎   └─child: RenderConstrainedBox#dffe5\n'
        ' ╎       parentData: <none> (can use size)\n'
        ' ╎       constraints: BoxConstraints(w=800.0, h=600.0)\n'
        ' ╎       size: Size(800.0, 600.0)\n'
        ' ╎       additionalConstraints: BoxConstraints(biggest)\n'
        ' ╎\n'
        ' ╎╌offstage 1: RenderLimitedBox#b6f09 NEEDS-LAYOUT NEEDS-PAINT\n'
        ' ╎ │ parentData: not positioned; offset=Offset(0.0, 0.0)\n'
        ' ╎ │ constraints: MISSING\n'
        ' ╎ │ size: MISSING\n'
        ' ╎ │ maxWidth: 0.0\n'
        ' ╎ │ maxHeight: 0.0\n'
        ' ╎ │\n'
        ' ╎ └─child: RenderConstrainedBox#5a057 NEEDS-LAYOUT NEEDS-PAINT\n'
        ' ╎     parentData: <none>\n'
        ' ╎     constraints: MISSING\n'
        ' ╎     size: MISSING\n'
        ' ╎     additionalConstraints: BoxConstraints(biggest)\n'
        ' ╎\n'
        ' └╌offstage 2: RenderLimitedBox#f689e NEEDS-LAYOUT NEEDS-PAINT\n'
        '   │ parentData: not positioned; offset=Offset(0.0, 0.0)\n'
        '   │ constraints: MISSING\n'
        '   │ size: MISSING\n'
        '   │ maxWidth: 0.0\n'
        '   │ maxHeight: 0.0\n'
        '   │\n'
        '   └─child: RenderConstrainedBox#c15f0 NEEDS-LAYOUT NEEDS-PAINT\n'
        '       parentData: <none>\n'
        '       constraints: MISSING\n'
        '       size: MISSING\n'
        '       additionalConstraints: BoxConstraints(biggest)\n'
      ),
    );
  });
}
