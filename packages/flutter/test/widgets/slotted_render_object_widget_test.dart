// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';

const Color green = Color(0xFF00FF00);
const Color yellow = Color(0xFFFFFF00);

void main() {
  testWidgets('SlottedRenderObjectWidget test', (WidgetTester tester) async {
    await tester.pumpWidget(buildWidget(
      topLeft: Container(
        height: 100,
        width: 80,
        color: yellow,
        child: const Text('topLeft'),
      ),
      bottomRight: Container(
        height: 120,
        width: 110,
        color: green,
        child: const Text('bottomRight'),
      ),
    ));

    expect(find.text('topLeft'), findsOneWidget);
    expect(find.text('bottomRight'), findsOneWidget);
    expect(tester.getSize(find.byType(_Diagonal)), const Size(80 + 110, 100 + 120));
    expect(find.byType(_Diagonal), paints
      ..rect(
        rect: const Rect.fromLTWH(0, 0, 80, 100),
        color: yellow,
      )
      ..rect(
        rect: const Rect.fromLTWH(80, 100, 110, 120),
        color: green,
      )
    );

    await tester.pumpWidget(buildWidget(
      topLeft: Container(
        height: 200,
        width: 100,
        color: yellow,
        child: const Text('topLeft'),
      ),
      bottomRight: Container(
        height: 220,
        width: 210,
        color: green,
        child: const Text('bottomRight'),
      ),
    ));

    expect(find.text('topLeft'), findsOneWidget);
    expect(find.text('bottomRight'), findsOneWidget);
    expect(tester.getSize(find.byType(_Diagonal)), const Size(100 + 210, 200 + 220));
    expect(find.byType(_Diagonal), paints
      ..rect(
        rect: const Rect.fromLTWH(0, 0, 100, 200),
        color: yellow,
      )
      ..rect(
        rect: const Rect.fromLTWH(100, 200, 210, 220),
        color: green,
      )
    );

    await tester.pumpWidget(buildWidget(
      topLeft: Container(
        height: 200,
        width: 100,
        color: yellow,
        child: const Text('topLeft'),
      ),
      bottomRight: Container(
        key: UniqueKey(),
        height: 230,
        width: 220,
        color: green,
        child: const Text('bottomRight'),
      ),
    ));

    expect(find.text('topLeft'), findsOneWidget);
    expect(find.text('bottomRight'), findsOneWidget);
    expect(tester.getSize(find.byType(_Diagonal)), const Size(100 + 220, 200 + 230));
    expect(find.byType(_Diagonal), paints
      ..rect(
        rect: const Rect.fromLTWH(0, 0, 100, 200),
        color: yellow,
      )
      ..rect(
        rect: const Rect.fromLTWH(100, 200, 220, 230),
        color: green,
      )
    );

    await tester.pumpWidget(buildWidget(
      topLeft: Container(
        height: 200,
        width: 100,
        color: yellow,
        child: const Text('topLeft'),
      ),
    ));

    expect(find.text('topLeft'), findsOneWidget);
    expect(find.text('bottomRight'), findsNothing);
    expect(tester.getSize(find.byType(_Diagonal)), const Size(100, 200));
    expect(find.byType(_Diagonal), paints
      ..rect(
        rect: const Rect.fromLTWH(0, 0, 100, 200),
        color: yellow,
      )
    );

    await tester.pumpWidget(buildWidget());
    expect(find.text('topLeft'), findsNothing);
    expect(find.text('bottomRight'), findsNothing);
    expect(tester.getSize(find.byType(_Diagonal)), Size.zero);
    expect(find.byType(_Diagonal), paintsNothing);

    await tester.pumpWidget(Container());
    expect(find.byType(_Diagonal), findsNothing);
  });

  test('nameForSlot', () {
    expect(_RenderDiagonal().publicNameForSlot(_DiagonalSlot.bottomRight), 'bottomRight');
    expect(_RenderDiagonal().publicNameForSlot(_DiagonalSlot.topLeft), 'topLeft');
    final _Slot slot = _Slot();
    expect(_RenderTest().publicNameForSlot(slot), slot.toString());
  });

  testWidgets('debugDescribeChildren', (WidgetTester tester) async {
    await tester.pumpWidget(buildWidget(
      topLeft: const SizedBox(
        height: 100,
        width: 80,
      ),
      bottomRight: const SizedBox(
        height: 120,
        width: 110,
      ),
    ));

    expect(
      tester.renderObject(find.byType(_Diagonal)).toStringDeep(),
      equalsIgnoringHashCodes(r'''
_RenderDiagonal#00000 relayoutBoundary=up1
 │ creator: _Diagonal ← Align ← Directionality ← [root]
 │ parentData: offset=Offset(0.0, 0.0) (can use size)
 │ constraints: BoxConstraints(0.0<=w<=800.0, 0.0<=h<=600.0)
 │ size: Size(190.0, 220.0)
 │
 ├─topLeft: RenderConstrainedBox#00000 relayoutBoundary=up2
 │   creator: SizedBox ← _Diagonal ← Align ← Directionality ← [root]
 │   parentData: offset=Offset(0.0, 0.0) (can use size)
 │   constraints: BoxConstraints(unconstrained)
 │   size: Size(80.0, 100.0)
 │   additionalConstraints: BoxConstraints(w=80.0, h=100.0)
 │
 └─bottomRight: RenderConstrainedBox#00000 relayoutBoundary=up2
     creator: SizedBox ← _Diagonal ← Align ← Directionality ← [root]
     parentData: offset=Offset(80.0, 100.0) (can use size)
     constraints: BoxConstraints(unconstrained)
     size: Size(110.0, 120.0)
     additionalConstraints: BoxConstraints(w=110.0, h=120.0)
''')
    );
  });
}

Widget buildWidget({Widget? topLeft, Widget? bottomRight}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Align(
      alignment: Alignment.topLeft,
      child: _Diagonal(
        topLeft: topLeft,
        bottomRight: bottomRight,
      ),
    ),
  );
}

enum _DiagonalSlot {
  topLeft,
  bottomRight,
}

class _Diagonal extends RenderObjectWidget with SlottedMultiChildRenderObjectWidgetMixin<_DiagonalSlot> {
  const _Diagonal({
    Key? key,
    this.topLeft,
    this.bottomRight,
    this.backgroundColor,
  }) : super(key: key);

  final Widget? topLeft;
  final Widget? bottomRight;
  final Color? backgroundColor;

  @override
  Iterable<_DiagonalSlot> get slots => _DiagonalSlot.values;

  @override
  Widget? childForSlot(_DiagonalSlot slot) {
    switch (slot) {
      case _DiagonalSlot.topLeft:
        return topLeft;
      case _DiagonalSlot.bottomRight:
        return bottomRight;
    }
  }

  @override
  SlottedContainerRenderObjectMixin<_DiagonalSlot> createRenderObject(
    BuildContext context,
  ) {
    return _RenderDiagonal();
  }
}

class _RenderDiagonal extends RenderBox with SlottedContainerRenderObjectMixin<_DiagonalSlot> {
  RenderBox? get _topLeft => childForSlot(_DiagonalSlot.topLeft);
  RenderBox? get _bottomRight => childForSlot(_DiagonalSlot.bottomRight);

  @override
  void performLayout() {
    const BoxConstraints childConstraints = BoxConstraints();

    Size topLeftSize = Size.zero;
    if (_topLeft != null) {
      _topLeft!.layout(childConstraints, parentUsesSize: true);
      _positionChild(_topLeft!, Offset.zero);
      topLeftSize = _topLeft!.size;
    }

    Size bottomRightSize = Size.zero;
    if (_bottomRight != null) {
      _bottomRight!.layout(childConstraints, parentUsesSize: true);
      _positionChild(
        _bottomRight!,
        Offset(topLeftSize.width, topLeftSize.height),
      );
      bottomRightSize = _bottomRight!.size;
    }

    size = constraints.constrain(Size(
      topLeftSize.width + bottomRightSize.width,
      topLeftSize.height + bottomRightSize.height,
    ));
  }

  void _positionChild(RenderBox child, Offset offset) {
    (child.parentData! as BoxParentData).offset = offset;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_topLeft != null) {
      _paintChild(_topLeft!, context, offset);
    }
    if (_bottomRight != null) {
      _paintChild(_bottomRight!, context, offset);
    }
  }

  void _paintChild(RenderBox child, PaintingContext context, Offset offset) {
    final BoxParentData childParentData = child.parentData! as BoxParentData;
    context.paintChild(child, childParentData.offset + offset);
  }

  String publicNameForSlot(_DiagonalSlot slot) => debugNameForSlot(slot);
}

class _Slot {
  @override
  String toString() => describeIdentity(this);
}

class _RenderTest extends RenderBox with SlottedContainerRenderObjectMixin<_Slot> {
  String publicNameForSlot(_Slot slot) => debugNameForSlot(slot);
}
