// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';

// Minimum padding from horizontal edges of segmented control to edges of
// encompassing widget.
const EdgeInsets _kHorizontalItemPadding = const EdgeInsets.symmetric(horizontal: 16.0);

// Minimum height of the segmented control.
const double _kMinSegmentedControlHeight = 28.0;

// Light, partially-transparent blue color. Used to fill the background of
// a child option the user is temporarily interacting with through a long
// press or drag.
const Color _kPressedBackground = const Color(0x33007aff);

/// An iOS-style segmented control.
///
/// Displays the widgets provided in the [Map] of [children] in a
/// horizontal list. Used to select between a number of mutually exclusive
/// options. When one option in the segmented control is selected, the other
/// options in the segmented control cease to be selected.
///
/// A segmented control can feature any [Widget] as one of the values in its
/// [Map] of [children]. The type T is the type of the keys used
/// to identify each widget and determine which widget is selected. As
/// required by the [Map] class, keys must be of consistent types
/// and must be comparable. The ordering of the keys will determine the order
/// of the widgets in the segmented control.
///
/// When the state of the segmented control changes, the widget calls the
/// [onValueChanged] callback. The map key associated with the newly selected
/// widget is returned in the [onValueChanged] callback. Typically, widgets
/// that use a segmented control will listen for the [onValueChanged] callback
/// and rebuild the segmented control with a new [groupValue] to update which
/// option is currently selected.
///
/// The [children] will be displayed in the order of the keys in the [Map].
/// The height of the segmented control is determined by the height of the
/// tallest widget provided as a value in the [Map] of [children].
/// The width of the segmented control is determined by the horizontal
/// constraints on its parent. The available horizontal space is divided by
/// the number of provided [children] to determine the width of each widget.
/// The selection area for each of the widgets in the [Map] of
/// [children] will then be expanded to fill the calculated space, so each
/// widget will appear to have the same dimensions.
///
/// See also:
///
///  * <https://developer.apple.com/design/human-interface-guidelines/ios/controls/segmented-controls/>
class SegmentedControl<T> extends StatefulWidget {
  /// Creates an iOS-style segmented control bar.
  ///
  /// The [children] and [onValueChanged] arguments must not be null. The
  /// [children] argument must be an ordered [Map] such as a [LinkedHashMap].
  /// Further, the length of the [children] list must be greater than one.
  ///
  /// Each widget value in the map of [children] must have an associated key
  /// that uniquely identifies this widget. This key is what will be returned
  /// in the [onValueChanged] callback when a new value from the [children] map
  /// is selected.
  ///
  /// The [groupValue] must be one of the keys in the [children] map.
  /// The [groupValue] is the currently selected value for the segmented control.
  /// If no [groupValue] is provided, or the [groupValue] is null, no widget will
  /// appear as selected.
  SegmentedControl({
    Key key,
    @required this.children,
    @required this.onValueChanged,
    this.groupValue,
  })  : assert(children != null),
        assert(children.length >= 2),
        assert(onValueChanged != null),
        assert(groupValue == null || children.keys.any((T child) => child == groupValue)),
        super(key: key);

  /// The identifying keys and corresponding widget values in the
  /// segmented control.
  ///
  /// The map must have more than one entry.
  /// This attribute must be an ordered [Map] such as a [LinkedHashMap].
  final Map<T, Widget> children;

  /// The identifier of the widget that is currently selected.
  ///
  /// This must be one of the keys in the [Map] of [children].
  /// If this attribute is null, no widget will be initially selected.
  final T groupValue;

  /// The callback that is called when a new option is tapped.
  ///
  /// This attribute must not be null.
  ///
  /// The segmented control passes the newly selected widget's associated key
  /// to the callback but does not actually change state until the parent
  /// widget rebuilds the segmented control with the new [groupValue].
  ///
  /// The callback provided to [onValueChanged] should update the state of
  /// the parent [StatefulWidget] using the [State.setState] method, so that
  /// the parent gets rebuilt; for example:
  ///
  /// ## Sample code
  ///
  /// ```dart
  /// class SegmentedControlExample extends StatefulWidget {
  ///   @override
  ///   State createState() => new SegmentedControlExampleState();
  /// }
  ///
  /// class SegmentedControlExampleState extends State<SegmentedControlExample> {
  ///   final Map<int, Widget> children = const {
  ///     0: const Text('Child 1'),
  ///     1: const Text('Child 2'),
  ///   };
  ///
  ///   int currentValue;
  ///
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     return new Container(
  ///       child: new SegmentedControl<int>(
  ///         children: children,
  ///         onValueChanged: (int newValue) {
  ///           setState(() {
  ///             currentValue = newValue;
  ///           });
  ///         },
  ///         groupValue: currentValue,
  ///       ),
  ///     );
  ///   }
  /// }
  /// ```
  final ValueChanged<T> onValueChanged;

  @override
  _SegmentedControlState<T> createState() => _SegmentedControlState<T>();
}

class _SegmentedControlState<T> extends State<SegmentedControl<T>> {
  T _pressedKey;

  void _onTapDown(T currentKey) {
    setState(() {
      _pressedKey = currentKey;
    });
  }

  void _onTapUp(TapUpDetails event) {
    setState(() {
      _pressedKey = null;
    });
  }

  void _onTapCancel() {
    setState(() {
      _pressedKey = null;
    });
  }

  void _onTap(T currentKey) {
    if (currentKey != widget.groupValue) {
      widget.onValueChanged(currentKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> gestureChildren = <Widget>[];
    int index = 0;
    int selectedIndex;
    int pressedIndex;
    for (T currentKey in widget.children.keys) {
      selectedIndex = (widget.groupValue == currentKey) ? index : selectedIndex;
      pressedIndex = (_pressedKey == currentKey) ? index : pressedIndex;

      final TextStyle textStyle = DefaultTextStyle.of(context).style.copyWith(
        color: (widget.groupValue == currentKey) ?
          CupertinoColors.white : CupertinoColors.activeBlue,
      );
      final IconThemeData iconTheme = new IconThemeData(
        color: (widget.groupValue == currentKey) ?
          CupertinoColors.white : CupertinoColors.activeBlue,
      );

      Widget child = widget.children[currentKey];
      child = new GestureDetector(
        onTapDown: (TapDownDetails event) {
          _onTapDown(currentKey);
        },
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: () {
          _onTap(currentKey);
        },
        child: new IconTheme(
          data: iconTheme,
          child: new DefaultTextStyle(
            style: textStyle,
            child: new Semantics(
              inMutuallyExclusiveGroup: true,
              selected: widget.groupValue == currentKey,
              child: child,
            ),
          ),
        ),
      );
      gestureChildren.add(child);
      index += 1;
    }

    final Widget box = new _SegmentedControlRenderWidget<T>(
      children: gestureChildren,
      selectedIndex: selectedIndex,
      pressedIndex: pressedIndex,
    );

    return new Padding(
      padding: _kHorizontalItemPadding.resolve(Directionality.of(context)),
      child: new UnconstrainedBox(
        constrainedAxis: Axis.horizontal,
        child: box,
      ),
    );
  }
}

class _SegmentedControlRenderWidget<T> extends MultiChildRenderObjectWidget {
  _SegmentedControlRenderWidget({
    Key key,
    List<Widget> children = const <Widget>[],
    @required this.selectedIndex,
    @required this.pressedIndex,
  }) : super(
          key: key,
          children: children,
        );

  final int selectedIndex;
  final int pressedIndex;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return new _RenderSegmentedControl<T>(
      textDirection: Directionality.of(context),
      selectedIndex: selectedIndex,
      pressedIndex: pressedIndex,
    );
  }

  @override
  void updateRenderObject(BuildContext context, _RenderSegmentedControl<T> renderObject) {
    renderObject
      ..textDirection = Directionality.of(context)
      ..selectedIndex = selectedIndex
      ..pressedIndex = pressedIndex;
  }
}

class _SegmentedControlContainerBoxParentData extends ContainerBoxParentData<RenderBox> {
  RRect surroundingRect;
}

typedef RenderBox _NextChild(RenderBox child);

class _RenderSegmentedControl<T> extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, ContainerBoxParentData<RenderBox>>,
        RenderBoxContainerDefaultsMixin<RenderBox, ContainerBoxParentData<RenderBox>> {
  _RenderSegmentedControl({
    List<RenderBox> children,
    @required int selectedIndex,
    @required int pressedIndex,
    @required TextDirection textDirection,
  })  : assert(textDirection != null),
        _textDirection = textDirection,
        _selectedIndex = selectedIndex,
        _pressedIndex = pressedIndex {
    addAll(children);
  }

  int get selectedIndex => _selectedIndex;
  int _selectedIndex;
  set selectedIndex(int value) {
    if (_selectedIndex == value) {
      return;
    }
    _selectedIndex = value;
    markNeedsPaint();
  }

  int get pressedIndex => _pressedIndex;
  int _pressedIndex;
  set pressedIndex(int value) {
    if (_pressedIndex == value) {
      return;
    }
    _pressedIndex = value;
    markNeedsPaint();
  }

  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (_textDirection == value) {
      return;
    }
    _textDirection = value;
    markNeedsLayout();
  }

  final Paint _outlinePaint = new Paint()
    ..color = CupertinoColors.activeBlue
    ..strokeWidth = 1.0
    ..style = PaintingStyle.stroke;

  @override
  double computeMinIntrinsicWidth(double height) {
    RenderBox child = firstChild;
    double minWidth = 0.0;
    while (child != null) {
      final _SegmentedControlContainerBoxParentData childParentData = child.parentData;
      final double childWidth = child.computeMinIntrinsicWidth(height);
      minWidth = math.max(minWidth, childWidth);
      child = childParentData.nextSibling;
    }
    return minWidth * childCount;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    RenderBox child = firstChild;
    double maxWidth = 0.0;
    while (child != null) {
      final _SegmentedControlContainerBoxParentData childParentData = child.parentData;
      final double childWidth = child.computeMaxIntrinsicWidth(height);
      maxWidth = math.max(maxWidth, childWidth);
      child = childParentData.nextSibling;
    }
    return maxWidth * childCount;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    RenderBox child = firstChild;
    double minHeight = 0.0;
    while (child != null) {
      final _SegmentedControlContainerBoxParentData childParentData = child.parentData;
      final double childHeight = child.computeMinIntrinsicHeight(width);
      minHeight = math.max(minHeight, childHeight);
      child = childParentData.nextSibling;
    }
    return minHeight;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    RenderBox child = firstChild;
    double maxHeight = 0.0;
    while (child != null) {
      final _SegmentedControlContainerBoxParentData childParentData = child.parentData;
      final double childHeight = child.computeMaxIntrinsicHeight(width);
      maxHeight = math.max(maxHeight, childHeight);
      child = childParentData.nextSibling;
    }
    return maxHeight;
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    return defaultComputeDistanceToHighestActualBaseline(baseline);
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _SegmentedControlContainerBoxParentData) {
      child.parentData = new _SegmentedControlContainerBoxParentData();
    }
  }

  void _layoutRects(_NextChild nextChild, RenderBox leftChild, RenderBox rightChild) {
    RenderBox child = leftChild;
    double start = 0.0;
    while (child != null) {
      final _SegmentedControlContainerBoxParentData childParentData = child.parentData;
      final Offset childOffset = new Offset(start, 0.0);
      childParentData.offset = childOffset;
      final Rect childRect = new Rect.fromLTWH(start, 0.0, child.size.width, child.size.height);
      RRect rChildRect;
      if (child == leftChild) {
        rChildRect = new RRect.fromRectAndCorners(childRect, topLeft: const Radius.circular(3.0),
            bottomLeft: const Radius.circular(3.0));
      } else if (child == rightChild) {
        rChildRect = new RRect.fromRectAndCorners(childRect, topRight: const Radius.circular(3.0),
            bottomRight: const Radius.circular(3.0));
      } else {
        rChildRect = new RRect.fromRectAndCorners(childRect);
      }
      childParentData.surroundingRect = rChildRect;
      start += child.size.width;
      child = nextChild(child);
    }
  }

  @override
  void performLayout() {
    double maxHeight = _kMinSegmentedControlHeight;

    double childWidth;
    if (constraints.maxWidth.isFinite) {
      childWidth = constraints.maxWidth / childCount;
    } else {
      childWidth = constraints.minWidth / childCount;
      for (RenderBox child in getChildrenAsList()) {
        childWidth = math.max(childWidth, child.getMaxIntrinsicWidth(double.infinity));
      }
    }

    RenderBox child = firstChild;
    while (child != null) {
      final double boxHeight = child.getMaxIntrinsicHeight(childWidth);
      maxHeight = math.max(maxHeight, boxHeight);
      child = childAfter(child);
    }

    constraints.constrainHeight(maxHeight);

    final BoxConstraints childConstraints = new BoxConstraints.tightFor(
      width: childWidth,
      height: maxHeight,
    );

    child = firstChild;
    while (child != null) {
      child.layout(childConstraints, parentUsesSize: true);
      child = childAfter(child);
    }

    switch (textDirection) {
      case TextDirection.rtl:
        _layoutRects(
          childBefore,
          lastChild,
          firstChild,
        );
        break;
      case TextDirection.ltr:
        _layoutRects(
          childAfter,
          firstChild,
          lastChild,
        );
        break;
    }

    size = constraints.constrain(new Size(childWidth * childCount, maxHeight));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    RenderBox child = firstChild;
    int index = 0;
    while (child != null) {
      _paintChild(context, offset, child, index);
      child = childAfter(child);
      index += 1;
    }
  }

  void _paintChild(PaintingContext context, Offset offset, RenderBox child, int childIndex) {
    assert(child != null);

    final _SegmentedControlContainerBoxParentData childParentData = child.parentData;

    Color color = CupertinoColors.white;
    if (selectedIndex != null && selectedIndex == childIndex) {
      color = CupertinoColors.activeBlue;
    } else if (pressedIndex != null && pressedIndex == childIndex) {
      color = _kPressedBackground;
    }

    context.canvas.drawRRect(
      childParentData.surroundingRect.shift(offset),
      new Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
    context.canvas.drawRRect(
      childParentData.surroundingRect.shift(offset),
      _outlinePaint,
    );

    context.paintChild(child, childParentData.offset + offset);
  }

  @override
  bool hitTestChildren(HitTestResult result, {@required Offset position}) {
    assert(position != null);
    return defaultHitTestChildren(result, position: position);
  }
}
