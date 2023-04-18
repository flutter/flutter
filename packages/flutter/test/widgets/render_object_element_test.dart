// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

@immutable
class Pair<T> {
  const Pair(this.first, this.second);
  final T? first;
  final T second;

  @override
  bool operator ==(final Object other) {
    return other is Pair<T> && other.first == first && other.second == second;
  }

  @override
  int get hashCode => Object.hash(first, second);

  @override
  String toString() => '($first,$second)';
}

/// Widget that will layout one child in the top half of this widget's size
/// and the other child in the bottom half. It will swap which child is on top
/// and which is on bottom every time the widget is rendered.
abstract class Swapper extends RenderObjectWidget {
  const Swapper({ super.key, this.stable, this.swapper });

  final Widget? stable;
  final Widget? swapper;

  @override
  SwapperElement createElement();

  @override
  RenderObject createRenderObject(final BuildContext context) => RenderSwapper();
}

class SwapperWithProperOverrides extends Swapper {
  const SwapperWithProperOverrides({
    super.key,
    super.stable,
    super.swapper,
  });

  @override
  SwapperElement createElement() => SwapperElementWithProperOverrides(this);
}

class SwapperWithNoOverrides extends Swapper {
  const SwapperWithNoOverrides({
    super.key,
    super.stable,
    super.swapper,
  });

  @override
  SwapperElement createElement() => SwapperElementWithNoOverrides(this);
}

abstract class SwapperElement extends RenderObjectElement {
  SwapperElement(Swapper super.widget);

  Element? stable;
  Element? swapper;
  bool swapperIsOnTop = true;
  List<dynamic> insertSlots = <dynamic>[];
  List<Pair<dynamic>> moveSlots = <Pair<dynamic>>[];
  List<dynamic> removeSlots = <dynamic>[];

  @override
  Swapper get widget => super.widget as Swapper;

  @override
  RenderSwapper get renderObject => super.renderObject as RenderSwapper;

  @override
  void visitChildren(final ElementVisitor visitor) {
    if (stable != null) {
      visitor(stable!);
    }
    if (swapper != null) {
      visitor(swapper!);
    }
  }

  @override
  void update(final Swapper newWidget) {
    super.update(newWidget);
    _updateChildren(newWidget);
  }

  @override
  void mount(final Element? parent, final Object? newSlot) {
    super.mount(parent, newSlot);
    _updateChildren(widget);
  }

  void _updateChildren(final Swapper widget) {
    stable = updateChild(stable, widget.stable, 'stable');
    swapper = updateChild(swapper, widget.swapper, swapperIsOnTop);
    swapperIsOnTop = !swapperIsOnTop;
  }

  @override
  void insertRenderObjectChild(covariant final RenderObject child, covariant final Object? slot) { }

  @override
  void moveRenderObjectChild(covariant final RenderObject child, covariant final Object? oldSlot, covariant final Object? newSlot) { }

  @override
  void removeRenderObjectChild(covariant final RenderObject child, covariant final Object? slot) { }
}

class SwapperElementWithProperOverrides extends SwapperElement {
  SwapperElementWithProperOverrides(super.widget);

  @override
  void insertRenderObjectChild(final RenderBox child, final Object? slot) {
    insertSlots.add(slot);
    if (slot == 'stable') {
      renderObject.stable = child;
    } else {
      renderObject.setSwapper(child, slot! as bool);
    }
  }

  @override
  void moveRenderObjectChild(final RenderBox child, final bool oldIsOnTop, final bool newIsOnTop) {
    moveSlots.add(Pair<bool>(oldIsOnTop, newIsOnTop));
    assert(oldIsOnTop == !newIsOnTop);
    renderObject.setSwapper(child, newIsOnTop);
  }

  @override
  void removeRenderObjectChild(final RenderBox child, final Object? slot) {
    removeSlots.add(slot);
    if (slot == 'stable') {
      renderObject.stable = null;
    } else {
      renderObject.setSwapper(null, slot! as bool);
    }
  }
}

class SwapperElementWithNoOverrides extends SwapperElement {
  SwapperElementWithNoOverrides(super.widget);
}

class RenderSwapper extends RenderBox {
  RenderBox? _stable;
  RenderBox? get stable => _stable;
  set stable(final RenderBox? child) {
    if (child == _stable) {
      return;
    }
    if (_stable != null) {
      dropChild(_stable!);
    }
    _stable = child;
    if (child != null) {
      adoptChild(child);
    }
  }

  bool? _swapperIsOnTop;
  RenderBox? _swapper;
  RenderBox? get swapper => _swapper;
  void setSwapper(final RenderBox? child, final bool isOnTop) {
    if (isOnTop != _swapperIsOnTop) {
      _swapperIsOnTop = isOnTop;
      markNeedsLayout();
    }
    if (child == _swapper) {
      return;
    }
    if (_swapper != null) {
      dropChild(_swapper!);
    }
    _swapper = child;
    if (child != null) {
      adoptChild(child);
    }
  }

  @override
  void visitChildren(final RenderObjectVisitor visitor) {
    if (_stable != null) {
      visitor(_stable!);
    }
    if (_swapper != null) {
      visitor(_swapper!);
    }
  }

  @override
  void attach(final PipelineOwner owner) {
    super.attach(owner);
    visitChildren((final RenderObject child) => child.attach(owner));
  }

  @override
  void detach() {
    super.detach();
    visitChildren((final RenderObject child) => child.detach());
  }

  @override
  Size computeDryLayout(final BoxConstraints constraints) {
    return constraints.biggest;
  }

  @override
  void performLayout() {
    assert(constraints.hasBoundedWidth);
    assert(constraints.hasTightHeight);
    size = constraints.biggest;
    const Offset topOffset = Offset.zero;
    final Offset bottomOffset = Offset(0, size.height / 2);
    final BoxConstraints childConstraints = constraints.copyWith(
      minHeight: constraints.minHeight / 2,
      maxHeight: constraints.maxHeight / 2,
    );
    if (_stable != null) {
      final BoxParentData stableParentData = _stable!.parentData! as BoxParentData;
      _stable!.layout(childConstraints);
      stableParentData.offset = _swapperIsOnTop! ? bottomOffset : topOffset;
    }
    if (_swapper != null) {
      final BoxParentData swapperParentData = _swapper!.parentData! as BoxParentData;
      _swapper!.layout(childConstraints);
      swapperParentData.offset = _swapperIsOnTop! ? topOffset : bottomOffset;
    }
  }

  @override
  void paint(final PaintingContext context, final Offset offset) {
    visitChildren((final RenderObject child) {
      final BoxParentData childParentData = child.parentData! as BoxParentData;
      context.paintChild(child, offset + childParentData.offset);
    });
  }

  @override
  void redepthChildren() {
    visitChildren((final RenderObject child) => redepthChild(child));
  }
}

BoxParentData parentDataFor(final RenderObject renderObject) => renderObject.parentData! as BoxParentData;

void main() {
  testWidgets('RenderObjectElement *RenderObjectChild methods get called with correct arguments', (final WidgetTester tester) async {
    const Key redKey = ValueKey<String>('red');
    const Key blueKey = ValueKey<String>('blue');
    Widget widget() {
      return SwapperWithProperOverrides(
        stable: ColoredBox(
          key: redKey,
          color: Color(nonconst(0xffff0000)),
        ),
        swapper: ColoredBox(
          key: blueKey,
          color: Color(nonconst(0xff0000ff)),
        ),
      );
    }

    await tester.pumpWidget(widget());
    final SwapperElement swapper = tester.element<SwapperElement>(find.byType(SwapperWithProperOverrides));
    final RenderBox redBox = tester.renderObject<RenderBox>(find.byKey(redKey));
    final RenderBox blueBox = tester.renderObject<RenderBox>(find.byKey(blueKey));
    expect(swapper.insertSlots.length, 2);
    expect(swapper.insertSlots, contains('stable'));
    expect(swapper.insertSlots, contains(true));
    expect(swapper.moveSlots, isEmpty);
    expect(swapper.removeSlots, isEmpty);
    expect(parentDataFor(redBox).offset, const Offset(0, 300));
    expect(parentDataFor(blueBox).offset, Offset.zero);
    await tester.pumpWidget(widget());
    expect(swapper.insertSlots.length, 2);
    expect(swapper.moveSlots.length, 1);
    expect(swapper.moveSlots, contains(const Pair<bool>(true, false)));
    expect(swapper.removeSlots, isEmpty);
    expect(parentDataFor(redBox).offset, Offset.zero);
    expect(parentDataFor(blueBox).offset, const Offset(0, 300));
    await tester.pumpWidget(const SwapperWithProperOverrides());
    expect(redBox.attached, false);
    expect(blueBox.attached, false);
    expect(swapper.insertSlots.length, 2);
    expect(swapper.moveSlots.length, 1);
    expect(swapper.removeSlots.length, 2);
    expect(swapper.removeSlots, contains('stable'));
    expect(swapper.removeSlots, contains(false));
  });
}
