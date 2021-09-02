// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is run as part of a reduced test set in CI on Mac and Windows
// machines.
@Tags(<String>['reduced-test-set'])

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';

void main() {
  testWidgets('Container control test', (WidgetTester tester) async {
    final Container container = Container(
      alignment: Alignment.bottomRight,
      padding: const EdgeInsets.all(7.0),
      // uses color, not decoration:
      color: const Color(0xFF00FF00),
      foregroundDecoration: const BoxDecoration(color: Color(0x7F0000FF)),
      width: 53.0,
      height: 76.0,
      constraints: const BoxConstraints(
        minWidth: 50.0,
        maxWidth: 55.0,
        minHeight: 78.0,
        maxHeight: 82.0,
      ),
      margin: const EdgeInsets.all(5.0),
      child: const SizedBox(
        width: 25.0,
        height: 33.0,
        child: DecoratedBox(
          // uses decoration, not color:
          decoration: BoxDecoration(color: Color(0xFFFFFF00)),
        ),
      ),
    );

    expect(container, hasOneLineDescription);

    await tester.pumpWidget(Align(
      alignment: Alignment.topLeft,
      child: container,
    ));

    final RenderBox box = tester.renderObject(find.byType(Container));
    expect(box, isNotNull);

    expect(box, paints
      ..rect(rect: const Rect.fromLTWH(5.0, 5.0, 53.0, 78.0), color: const Color(0xFF00FF00))
      ..rect(rect: const Rect.fromLTWH(26.0, 43.0, 25.0, 33.0), color: const Color(0xFFFFFF00))
      ..rect(rect: const Rect.fromLTWH(5.0, 5.0, 53.0, 78.0), color: const Color(0x7F0000FF)),
    );

    expect(box, hasAGoodToStringDeep);
    expect(
      box.toStringDeep(minLevel: DiagnosticLevel.info),
      equalsIgnoringHashCodes(
        'RenderPadding#00000 relayoutBoundary=up1\n'
        ' │ parentData: offset=Offset(0.0, 0.0) (can use size)\n'
        ' │ constraints: BoxConstraints(0.0<=w<=800.0, 0.0<=h<=600.0)\n'
        ' │ size: Size(63.0, 88.0)\n'
        ' │ padding: EdgeInsets.all(5.0)\n'
        ' │\n'
        ' └─child: RenderConstrainedBox#00000 relayoutBoundary=up2\n'
        '   │ parentData: offset=Offset(5.0, 5.0) (can use size)\n'
        '   │ constraints: BoxConstraints(0.0<=w<=790.0, 0.0<=h<=590.0)\n'
        '   │ size: Size(53.0, 78.0)\n'
        '   │ additionalConstraints: BoxConstraints(w=53.0, h=78.0)\n'
        '   │\n'
        '   └─child: RenderDecoratedBox#00000\n'
        '     │ parentData: <none> (can use size)\n'
        '     │ constraints: BoxConstraints(w=53.0, h=78.0)\n'
        '     │ size: Size(53.0, 78.0)\n'
        '     │ decoration: BoxDecoration:\n'
        '     │   color: Color(0x7f0000ff)\n'
        '     │ configuration: ImageConfiguration(bundle:\n'
        '     │   PlatformAssetBundle#00000(), devicePixelRatio: 1.0, platform:\n'
        '     │   android)\n'
        '     │\n'
        '     └─child: _RenderColoredBox#00000\n'
        '       │ parentData: <none> (can use size)\n'
        '       │ constraints: BoxConstraints(w=53.0, h=78.0)\n'
        '       │ size: Size(53.0, 78.0)\n'
        '       │ behavior: opaque\n'
        '       │\n'
        '       └─child: RenderPadding#00000\n'
        '         │ parentData: <none> (can use size)\n'
        '         │ constraints: BoxConstraints(w=53.0, h=78.0)\n'
        '         │ size: Size(53.0, 78.0)\n'
        '         │ padding: EdgeInsets.all(7.0)\n'
        '         │\n'
        '         └─child: RenderPositionedBox#00000\n'
        '           │ parentData: offset=Offset(7.0, 7.0) (can use size)\n'
        '           │ constraints: BoxConstraints(w=39.0, h=64.0)\n'
        '           │ size: Size(39.0, 64.0)\n'
        '           │ alignment: Alignment.bottomRight\n'
        '           │ widthFactor: expand\n'
        '           │ heightFactor: expand\n'
        '           │\n'
        '           └─child: RenderConstrainedBox#00000 relayoutBoundary=up1\n'
        '             │ parentData: offset=Offset(14.0, 31.0) (can use size)\n'
        '             │ constraints: BoxConstraints(0.0<=w<=39.0, 0.0<=h<=64.0)\n'
        '             │ size: Size(25.0, 33.0)\n'
        '             │ additionalConstraints: BoxConstraints(w=25.0, h=33.0)\n'
        '             │\n'
        '             └─child: RenderDecoratedBox#00000\n'
        '                 parentData: <none> (can use size)\n'
        '                 constraints: BoxConstraints(w=25.0, h=33.0)\n'
        '                 size: Size(25.0, 33.0)\n'
        '                 decoration: BoxDecoration:\n'
        '                   color: Color(0xffffff00)\n'
        '                 configuration: ImageConfiguration(bundle:\n'
        '                   PlatformAssetBundle#00000(), devicePixelRatio: 1.0, platform:\n'
        '                   android)\n',
      ),
    );

    expect(
      box.toStringDeep(minLevel: DiagnosticLevel.debug),
      equalsIgnoringHashCodes(
        'RenderPadding#00000 relayoutBoundary=up1\n'
        ' │ creator: Padding ← Container ← Align ← [root]\n'
        ' │ parentData: offset=Offset(0.0, 0.0) (can use size)\n'
        ' │ constraints: BoxConstraints(0.0<=w<=800.0, 0.0<=h<=600.0)\n'
        ' │ size: Size(63.0, 88.0)\n'
        ' │ padding: EdgeInsets.all(5.0)\n'
        ' │\n'
        ' └─child: RenderConstrainedBox#00000 relayoutBoundary=up2\n'
        '   │ creator: ConstrainedBox ← Padding ← Container ← Align ← [root]\n'
        '   │ parentData: offset=Offset(5.0, 5.0) (can use size)\n'
        '   │ constraints: BoxConstraints(0.0<=w<=790.0, 0.0<=h<=590.0)\n'
        '   │ size: Size(53.0, 78.0)\n'
        '   │ additionalConstraints: BoxConstraints(w=53.0, h=78.0)\n'
        '   │\n'
        '   └─child: RenderDecoratedBox#00000\n'
        '     │ creator: DecoratedBox ← ConstrainedBox ← Padding ← Container ←\n'
        '     │   Align ← [root]\n'
        '     │ parentData: <none> (can use size)\n'
        '     │ constraints: BoxConstraints(w=53.0, h=78.0)\n'
        '     │ size: Size(53.0, 78.0)\n'
        '     │ decoration: BoxDecoration:\n'
        '     │   color: Color(0x7f0000ff)\n'
        '     │ configuration: ImageConfiguration(bundle:\n'
        '     │   PlatformAssetBundle#00000(), devicePixelRatio: 1.0, platform:\n'
        '     │   android)\n'
        '     │\n'
        '     └─child: _RenderColoredBox#00000\n'
        '       │ creator: ColoredBox ← DecoratedBox ← ConstrainedBox ← Padding ←\n'
        '       │   Container ← Align ← [root]\n'
        '       │ parentData: <none> (can use size)\n'
        '       │ constraints: BoxConstraints(w=53.0, h=78.0)\n'
        '       │ size: Size(53.0, 78.0)\n'
        '       │ behavior: opaque\n'
        '       │\n'
        '       └─child: RenderPadding#00000\n'
        '         │ creator: Padding ← ColoredBox ← DecoratedBox ← ConstrainedBox ←\n'
        '         │   Padding ← Container ← Align ← [root]\n'
        '         │ parentData: <none> (can use size)\n'
        '         │ constraints: BoxConstraints(w=53.0, h=78.0)\n'
        '         │ size: Size(53.0, 78.0)\n'
        '         │ padding: EdgeInsets.all(7.0)\n'
        '         │\n'
        '         └─child: RenderPositionedBox#00000\n'
        '           │ creator: Align ← Padding ← ColoredBox ← DecoratedBox ←\n'
        '           │   ConstrainedBox ← Padding ← Container ← Align ← [root]\n'
        '           │ parentData: offset=Offset(7.0, 7.0) (can use size)\n'
        '           │ constraints: BoxConstraints(w=39.0, h=64.0)\n'
        '           │ size: Size(39.0, 64.0)\n'
        '           │ alignment: Alignment.bottomRight\n'
        '           │ widthFactor: expand\n'
        '           │ heightFactor: expand\n'
        '           │\n'
        '           └─child: RenderConstrainedBox#00000 relayoutBoundary=up1\n'
        '             │ creator: SizedBox ← Align ← Padding ← ColoredBox ← DecoratedBox ←\n'
        '             │   ConstrainedBox ← Padding ← Container ← Align ← [root]\n'
        '             │ parentData: offset=Offset(14.0, 31.0) (can use size)\n'
        '             │ constraints: BoxConstraints(0.0<=w<=39.0, 0.0<=h<=64.0)\n'
        '             │ size: Size(25.0, 33.0)\n'
        '             │ additionalConstraints: BoxConstraints(w=25.0, h=33.0)\n'
        '             │\n'
        '             └─child: RenderDecoratedBox#00000\n'
        '                 creator: DecoratedBox ← SizedBox ← Align ← Padding ← ColoredBox ←\n'
        '                   DecoratedBox ← ConstrainedBox ← Padding ← Container ← Align ←\n'
        '                   [root]\n'
        '                 parentData: <none> (can use size)\n'
        '                 constraints: BoxConstraints(w=25.0, h=33.0)\n'
        '                 size: Size(25.0, 33.0)\n'
        '                 decoration: BoxDecoration:\n'
        '                   color: Color(0xffffff00)\n'
        '                 configuration: ImageConfiguration(bundle:\n'
        '                   PlatformAssetBundle#00000(), devicePixelRatio: 1.0, platform:\n'
        '                   android)\n',
      ),
    );

    expect(
      box.toStringDeep(minLevel: DiagnosticLevel.fine),
      equalsIgnoringHashCodes(
        'RenderPadding#00000 relayoutBoundary=up1\n'
        ' │ creator: Padding ← Container ← Align ← [root]\n'
        ' │ parentData: offset=Offset(0.0, 0.0) (can use size)\n'
        ' │ constraints: BoxConstraints(0.0<=w<=800.0, 0.0<=h<=600.0)\n'
        ' │ layer: null\n'
        ' │ semantics node: null\n'
        ' │ size: Size(63.0, 88.0)\n'
        ' │ padding: EdgeInsets.all(5.0)\n'
        ' │ textDirection: null\n'
        ' │\n'
        ' └─child: RenderConstrainedBox#00000 relayoutBoundary=up2\n'
        '   │ creator: ConstrainedBox ← Padding ← Container ← Align ← [root]\n'
        '   │ parentData: offset=Offset(5.0, 5.0) (can use size)\n'
        '   │ constraints: BoxConstraints(0.0<=w<=790.0, 0.0<=h<=590.0)\n'
        '   │ layer: null\n'
        '   │ semantics node: null\n'
        '   │ size: Size(53.0, 78.0)\n'
        '   │ additionalConstraints: BoxConstraints(w=53.0, h=78.0)\n'
        '   │\n'
        '   └─child: RenderDecoratedBox#00000\n'
        '     │ creator: DecoratedBox ← ConstrainedBox ← Padding ← Container ←\n'
        '     │   Align ← [root]\n'
        '     │ parentData: <none> (can use size)\n'
        '     │ constraints: BoxConstraints(w=53.0, h=78.0)\n'
        '     │ layer: null\n'
        '     │ semantics node: null\n'
        '     │ size: Size(53.0, 78.0)\n'
        '     │ decoration: BoxDecoration:\n'
        '     │   color: Color(0x7f0000ff)\n'
        '     │   image: null\n'
        '     │   border: null\n'
        '     │   borderRadius: null\n'
        '     │   boxShadow: null\n'
        '     │   gradient: null\n'
        '     │   shape: rectangle\n'
        '     │ configuration: ImageConfiguration(bundle:\n'
        '     │   PlatformAssetBundle#00000(), devicePixelRatio: 1.0, platform:\n'
        '     │   android)\n'
        '     │\n'
        '     └─child: _RenderColoredBox#00000\n'
        '       │ creator: ColoredBox ← DecoratedBox ← ConstrainedBox ← Padding ←\n'
        '       │   Container ← Align ← [root]\n'
        '       │ parentData: <none> (can use size)\n'
        '       │ constraints: BoxConstraints(w=53.0, h=78.0)\n'
        '       │ layer: null\n'
        '       │ semantics node: null\n'
        '       │ size: Size(53.0, 78.0)\n'
        '       │ behavior: opaque\n'
        '       │\n'
        '       └─child: RenderPadding#00000\n'
        '         │ creator: Padding ← ColoredBox ← DecoratedBox ← ConstrainedBox ←\n'
        '         │   Padding ← Container ← Align ← [root]\n'
        '         │ parentData: <none> (can use size)\n'
        '         │ constraints: BoxConstraints(w=53.0, h=78.0)\n'
        '         │ layer: null\n'
        '         │ semantics node: null\n'
        '         │ size: Size(53.0, 78.0)\n'
        '         │ padding: EdgeInsets.all(7.0)\n'
        '         │ textDirection: null\n'
        '         │\n'
        '         └─child: RenderPositionedBox#00000\n'
        '           │ creator: Align ← Padding ← ColoredBox ← DecoratedBox ←\n'
        '           │   ConstrainedBox ← Padding ← Container ← Align ← [root]\n'
        '           │ parentData: offset=Offset(7.0, 7.0) (can use size)\n'
        '           │ constraints: BoxConstraints(w=39.0, h=64.0)\n'
        '           │ layer: null\n'
        '           │ semantics node: null\n'
        '           │ size: Size(39.0, 64.0)\n'
        '           │ alignment: Alignment.bottomRight\n'
        '           │ textDirection: null\n'
        '           │ widthFactor: expand\n'
        '           │ heightFactor: expand\n'
        '           │\n'
        '           └─child: RenderConstrainedBox#00000 relayoutBoundary=up1\n'
        '             │ creator: SizedBox ← Align ← Padding ← ColoredBox ← DecoratedBox ←\n'
        '             │   ConstrainedBox ← Padding ← Container ← Align ← [root]\n'
        '             │ parentData: offset=Offset(14.0, 31.0) (can use size)\n'
        '             │ constraints: BoxConstraints(0.0<=w<=39.0, 0.0<=h<=64.0)\n'
        '             │ layer: null\n'
        '             │ semantics node: null\n'
        '             │ size: Size(25.0, 33.0)\n'
        '             │ additionalConstraints: BoxConstraints(w=25.0, h=33.0)\n'
        '             │\n'
        '             └─child: RenderDecoratedBox#00000\n'
        '                 creator: DecoratedBox ← SizedBox ← Align ← Padding ← ColoredBox ←\n'
        '                   DecoratedBox ← ConstrainedBox ← Padding ← Container ← Align ←\n'
        '                   [root]\n'
        '                 parentData: <none> (can use size)\n'
        '                 constraints: BoxConstraints(w=25.0, h=33.0)\n'
        '                 layer: null\n'
        '                 semantics node: null\n'
        '                 size: Size(25.0, 33.0)\n'
        '                 decoration: BoxDecoration:\n'
        '                   color: Color(0xffffff00)\n'
        '                   image: null\n'
        '                   border: null\n'
        '                   borderRadius: null\n'
        '                   boxShadow: null\n'
        '                   gradient: null\n'
        '                   shape: rectangle\n'
        '                 configuration: ImageConfiguration(bundle:\n'
        '                   PlatformAssetBundle#00000(), devicePixelRatio: 1.0, platform:\n'
        '                   android)\n',
      ),
    );

    expect(
      box.toStringDeep(minLevel: DiagnosticLevel.hidden),
      equalsIgnoringHashCodes(
        'RenderPadding#00000 relayoutBoundary=up1\n'
        ' │ needsCompositing: false\n'
        ' │ creator: Padding ← Container ← Align ← [root]\n'
        ' │ parentData: offset=Offset(0.0, 0.0) (can use size)\n'
        ' │ constraints: BoxConstraints(0.0<=w<=800.0, 0.0<=h<=600.0)\n'
        ' │ layer: null\n'
        ' │ semantics node: null\n'
        ' │ isBlockingSemanticsOfPreviouslyPaintedNodes: false\n'
        ' │ isSemanticBoundary: false\n'
        ' │ size: Size(63.0, 88.0)\n'
        ' │ padding: EdgeInsets.all(5.0)\n'
        ' │ textDirection: null\n'
        ' │\n'
        ' └─child: RenderConstrainedBox#00000 relayoutBoundary=up2\n'
        '   │ needsCompositing: false\n'
        '   │ creator: ConstrainedBox ← Padding ← Container ← Align ← [root]\n'
        '   │ parentData: offset=Offset(5.0, 5.0) (can use size)\n'
        '   │ constraints: BoxConstraints(0.0<=w<=790.0, 0.0<=h<=590.0)\n'
        '   │ layer: null\n'
        '   │ semantics node: null\n'
        '   │ isBlockingSemanticsOfPreviouslyPaintedNodes: false\n'
        '   │ isSemanticBoundary: false\n'
        '   │ size: Size(53.0, 78.0)\n'
        '   │ additionalConstraints: BoxConstraints(w=53.0, h=78.0)\n'
        '   │\n'
        '   └─child: RenderDecoratedBox#00000\n'
        '     │ needsCompositing: false\n'
        '     │ creator: DecoratedBox ← ConstrainedBox ← Padding ← Container ←\n'
        '     │   Align ← [root]\n'
        '     │ parentData: <none> (can use size)\n'
        '     │ constraints: BoxConstraints(w=53.0, h=78.0)\n'
        '     │ layer: null\n'
        '     │ semantics node: null\n'
        '     │ isBlockingSemanticsOfPreviouslyPaintedNodes: false\n'
        '     │ isSemanticBoundary: false\n'
        '     │ size: Size(53.0, 78.0)\n'
        '     │ decoration: BoxDecoration:\n'
        '     │   color: Color(0x7f0000ff)\n'
        '     │   image: null\n'
        '     │   border: null\n'
        '     │   borderRadius: null\n'
        '     │   boxShadow: null\n'
        '     │   gradient: null\n'
        '     │   shape: rectangle\n'
        '     │ configuration: ImageConfiguration(bundle:\n'
        '     │   PlatformAssetBundle#00000(), devicePixelRatio: 1.0, platform:\n'
        '     │   android)\n'
        '     │\n'
        '     └─child: _RenderColoredBox#00000\n'
        '       │ needsCompositing: false\n'
        '       │ creator: ColoredBox ← DecoratedBox ← ConstrainedBox ← Padding ←\n'
        '       │   Container ← Align ← [root]\n'
        '       │ parentData: <none> (can use size)\n'
        '       │ constraints: BoxConstraints(w=53.0, h=78.0)\n'
        '       │ layer: null\n'
        '       │ semantics node: null\n'
        '       │ isBlockingSemanticsOfPreviouslyPaintedNodes: false\n'
        '       │ isSemanticBoundary: false\n'
        '       │ size: Size(53.0, 78.0)\n'
        '       │ behavior: opaque\n'
        '       │\n'
        '       └─child: RenderPadding#00000\n'
        '         │ needsCompositing: false\n'
        '         │ creator: Padding ← ColoredBox ← DecoratedBox ← ConstrainedBox ←\n'
        '         │   Padding ← Container ← Align ← [root]\n'
        '         │ parentData: <none> (can use size)\n'
        '         │ constraints: BoxConstraints(w=53.0, h=78.0)\n'
        '         │ layer: null\n'
        '         │ semantics node: null\n'
        '         │ isBlockingSemanticsOfPreviouslyPaintedNodes: false\n'
        '         │ isSemanticBoundary: false\n'
        '         │ size: Size(53.0, 78.0)\n'
        '         │ padding: EdgeInsets.all(7.0)\n'
        '         │ textDirection: null\n'
        '         │\n'
        '         └─child: RenderPositionedBox#00000\n'
        '           │ needsCompositing: false\n'
        '           │ creator: Align ← Padding ← ColoredBox ← DecoratedBox ←\n'
        '           │   ConstrainedBox ← Padding ← Container ← Align ← [root]\n'
        '           │ parentData: offset=Offset(7.0, 7.0) (can use size)\n'
        '           │ constraints: BoxConstraints(w=39.0, h=64.0)\n'
        '           │ layer: null\n'
        '           │ semantics node: null\n'
        '           │ isBlockingSemanticsOfPreviouslyPaintedNodes: false\n'
        '           │ isSemanticBoundary: false\n'
        '           │ size: Size(39.0, 64.0)\n'
        '           │ alignment: Alignment.bottomRight\n'
        '           │ textDirection: null\n'
        '           │ widthFactor: expand\n'
        '           │ heightFactor: expand\n'
        '           │\n'
        '           └─child: RenderConstrainedBox#00000 relayoutBoundary=up1\n'
        '             │ needsCompositing: false\n'
        '             │ creator: SizedBox ← Align ← Padding ← ColoredBox ← DecoratedBox ←\n'
        '             │   ConstrainedBox ← Padding ← Container ← Align ← [root]\n'
        '             │ parentData: offset=Offset(14.0, 31.0) (can use size)\n'
        '             │ constraints: BoxConstraints(0.0<=w<=39.0, 0.0<=h<=64.0)\n'
        '             │ layer: null\n'
        '             │ semantics node: null\n'
        '             │ isBlockingSemanticsOfPreviouslyPaintedNodes: false\n'
        '             │ isSemanticBoundary: false\n'
        '             │ size: Size(25.0, 33.0)\n'
        '             │ additionalConstraints: BoxConstraints(w=25.0, h=33.0)\n'
        '             │\n'
        '             └─child: RenderDecoratedBox#00000\n'
        '                 needsCompositing: false\n'
        '                 creator: DecoratedBox ← SizedBox ← Align ← Padding ← ColoredBox ←\n'
        '                   DecoratedBox ← ConstrainedBox ← Padding ← Container ← Align ←\n'
        '                   [root]\n'
        '                 parentData: <none> (can use size)\n'
        '                 constraints: BoxConstraints(w=25.0, h=33.0)\n'
        '                 layer: null\n'
        '                 semantics node: null\n'
        '                 isBlockingSemanticsOfPreviouslyPaintedNodes: false\n'
        '                 isSemanticBoundary: false\n'
        '                 size: Size(25.0, 33.0)\n'
        '                 decoration: BoxDecoration:\n'
        '                   color: Color(0xffffff00)\n'
        '                   image: null\n'
        '                   border: null\n'
        '                   borderRadius: null\n'
        '                   boxShadow: null\n'
        '                   gradient: null\n'
        '                   shape: rectangle\n'
        '                 configuration: ImageConfiguration(bundle:\n'
        '                   PlatformAssetBundle#00000(), devicePixelRatio: 1.0, platform:\n'
        '                   android)\n',
      ),
    );

    final RenderBox decoratedBox = tester.renderObject(find.byType(DecoratedBox).last);
    final PaintingContext context = _MockPaintingContext();
    late FlutterError error;
    try {
      decoratedBox.paint(context, Offset.zero);
    } on FlutterError catch (e) {
      error = e;
    }
    expect(error, isNotNull);
    expect(
      error.toStringDeep(),
      'FlutterError\n'
      '   BoxDecoration painter had mismatching save and restore calls.\n'
      '   Before painting the decoration, the canvas save count was 0.\n'
      '   After painting it, the canvas save count was 2. Every call to\n'
      '   save() or saveLayer() must be matched by a call to restore().\n'
      '   The decoration was:\n'
      '     BoxDecoration(color: Color(0xffffff00))\n'
      '   The painter was:\n'
      '     BoxPainter for BoxDecoration(color: Color(0xffffff00))\n',
    );
  });

  testWidgets('Can be placed in an infinite box', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ListView(children: <Widget>[Container()]),
      ),
    );
  });

  testWidgets('Container transformAlignment', (WidgetTester tester) async {
    final Key key = UniqueKey();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          children: <Widget>[
            Positioned(
              top: 100.0,
              left: 100.0,
              child: Container(
                width: 100.0,
                height: 100.0,
                color: const Color(0xFF0000FF),
              ),
            ),
            Positioned(
              top: 100.0,
              left: 100.0,
              child: Container(
                width: 100.0,
                height: 100.0,
                key: key,
                transform: Matrix4.diagonal3Values(0.5, 0.5, 1.0),
                transformAlignment: Alignment.centerRight,
                child: Container(
                  color: const Color(0xFF00FFFF),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final Finder finder = find.byKey(key);

    expect(tester.getSize(finder), equals(const Size(100, 100)));

    expect(tester.getTopLeft(finder), equals(const Offset(100, 100)));
    expect(tester.getTopRight(finder), equals(const Offset(200, 100)));

    expect(tester.getBottomLeft(finder), equals(const Offset(100, 200)));
    expect(tester.getBottomRight(finder), equals(const Offset(200, 200)));
  });

  testWidgets('giving clipBehaviour Clip.None, will not add a ClipPath to the tree', (WidgetTester tester) async {
    await tester.pumpWidget(Container(
      clipBehavior: Clip.none,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(1),
      ),
      child: const SizedBox(),
    ));

    expect(
      find.byType(ClipPath),
      findsNothing,
    );
  });

  testWidgets('giving clipBehaviour not a Clip.None, will add a ClipPath to the tree', (WidgetTester tester) async {
    final Container container = Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(1),
      ),
      child: const SizedBox(),
    );

    await tester.pumpWidget(container);

    expect(
      find.byType(ClipPath),
      findsOneWidget,
    );
  });

  testWidgets('getClipPath() works for lots of kinds of decorations', (WidgetTester tester) async {
    Future<void> test(Decoration decoration) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.rtl,
          child: Center(
            child: SizedBox(
              width: 100.0,
              height: 100.0,
              child: RepaintBoundary(
                child: Container(
                  clipBehavior: Clip.hardEdge,
                  decoration: decoration,
                  child: ColoredBox(
                    color: Colors.yellow.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await expectLater(find.byType(Container), matchesGoldenFile('container_test.getClipPath.${decoration.runtimeType}.png'));
    }
    await test(const BoxDecoration());
    await test(const UnderlineTabIndicator());
    await test(const ShapeDecoration(shape: StadiumBorder()));
    await test(const FlutterLogoDecoration());
  });

  testWidgets('Container is hittable only when having decorations', (WidgetTester tester) async {
    bool tapped = false;
    await tester.pumpWidget(GestureDetector(
      onTap: () { tapped = true; },
      child: Container(
        decoration: const BoxDecoration(color: Colors.black),
      ),
    ));

    await tester.tap(find.byType(Container));
    expect(tapped, true);
    tapped = false;

    await tester.pumpWidget(GestureDetector(
      onTap: () { tapped = true; },
      child: Container(
        foregroundDecoration: const BoxDecoration(color: Colors.black),
      ),
    ));

    await tester.tap(find.byType(Container));
    expect(tapped, true);
    tapped = false;

    await tester.pumpWidget(GestureDetector(
      onTap: () { tapped = true; },
      child: Container(
        color: Colors.black,
      ),
    ));

    await tester.tap(find.byType(Container));
    expect(tapped, true);
    tapped = false;

    // Everything but color or decorations
    await tester.pumpWidget(GestureDetector(
      onTap: () { tapped = true; },
      child: Center(
        child: Container(
          alignment: Alignment.bottomRight,
          padding: const EdgeInsets.all(2),
          width: 50,
          height: 50,
          margin: const EdgeInsets.all(2),
          transform: Matrix4.rotationZ(1),
        ),
      ),
    ));

    await tester.tap(find.byType(Container), warnIfMissed: false);
    expect(tapped, false);
  });

  testWidgets('using clipBehaviour and shadow, should not clip the shadow', (WidgetTester tester) async {
    final Container container = Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: Colors.red,
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Colors.blue,
            offset: Offset.zero,
            spreadRadius: 10,
            blurRadius: 20.0,
          ),
        ],
      ),
      child: const SizedBox(width: 50, height: 50),
    );

    await tester.pumpWidget(
      RepaintBoundary(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: container,
        ),
      ),
    );

    await expectLater(
      find.byType(RepaintBoundary),
      matchesGoldenFile('container.clipBehaviour.with.shadow.png'),
    );
  });
}

class _MockPaintingContext extends Fake implements PaintingContext {
  @override
  final Canvas canvas = _MockCanvas();
}

class _MockCanvas extends Fake implements Canvas {
  int saveCount = 0;

  @override
  int getSaveCount() {
    return saveCount++;
  }

  @override
  void drawRect(Rect rect, Paint paint) { }
}
