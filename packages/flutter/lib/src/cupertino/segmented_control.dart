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
const EdgeInsets _kHorizontalItemPadding = EdgeInsets.symmetric(horizontal: 16.0);

// Minimum height of the segmented control.
const double _kMinSegmentedControlHeight = 28.0;

// The duration of the fade animation used to transition when a new widget
// is selected.
const Duration _kFadeDuration = Duration(milliseconds: 165);

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
/// The width of each child in the segmented control will be equal to the width
/// of widest child, unless the combined width of the children is wider than
/// the available horizontal space. In this case, the available horizontal space
/// is divided by the number of provided [children] to determine the width of
/// each widget. The selection area for each of the widgets in the [Map] of
/// [children] will then be expanded to fill the calculated space, so each
/// widget will appear to have the same dimensions.
///
/// A segmented control may optionally be created with custom colors. The
/// [unselectedColor], [selectedColor], [borderColor], and [pressedColor]
/// arguments can be used to change the segmented control's colors from
/// [CupertinoColors.activeBlue] and [CupertinoColors.white] to a custom
/// configuration.
///
/// See also:
///
///  * <https://developer.apple.com/design/human-interface-guidelines/ios/controls/segmented-controls/>
class CupertinoSegmentedControl<T> extends StatefulWidget {
  /// Creates an iOS-style segmented control bar.
  ///
  /// The [children], [onValueChanged], [unselectedColor], [selectedColor],
  /// [borderColor], and [pressedColor] arguments must not be null. The
  /// [children] argument must be an ordered [Map] such as a [LinkedHashMap].
  /// Further, the length of the [children] list must be greater than one.
  ///
  /// Each widget value in the map of [children] must have an associated key
  /// that uniquely identifies this widget. This key is what will be returned
  /// in the [onValueChanged] callback when a new value from the [children] map
  /// is selected.
  ///
  /// The [groupValue] is the currently selected value for the segmented control.
  /// If no [groupValue] is provided, or the [groupValue] is null, no widget will
  /// appear as selected. The [groupValue] must be either null or one of the keys
  /// in the [children] map.
  CupertinoSegmentedControl({
    Key key,
    @required this.children,
    @required this.onValueChanged,
    this.groupValue,
    this.unselectedColor = CupertinoColors.white,
    this.selectedColor = CupertinoColors.activeBlue,
    this.borderColor = CupertinoColors.activeBlue,
    this.pressedColor = const Color(0x33007AFF),
  })  : assert(children != null),
        assert(children.length >= 2),
        assert(onValueChanged != null),
        assert(groupValue == null || children.keys.any((T child) => child == groupValue),
        'The groupValue must be either null or one of the keys in the children map.'),
        assert(unselectedColor != null),
        assert(selectedColor != null),
        assert(borderColor != null),
        assert(pressedColor != null),
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
  /// {@tool sample}
  ///
  /// ```dart
  /// class SegmentedControlExample extends StatefulWidget {
  ///   @override
  ///   State createState() => SegmentedControlExampleState();
  /// }
  ///
  /// class SegmentedControlExampleState extends State<SegmentedControlExample> {
  ///   final Map<int, Widget> children = const {
  ///     0: Text('Child 1'),
  ///     1: Text('Child 2'),
  ///   };
  ///
  ///   int currentValue;
  ///
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     return Container(
  ///       child: CupertinoSegmentedControl<int>(
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
  /// {@end-tool}
  final ValueChanged<T> onValueChanged;

  /// The color used to fill the backgrounds of unselected widgets and as the
  /// text color of the selected widget.
  ///
  /// This attribute must not be null.
  ///
  /// If this attribute is unspecified, this color will default to
  /// [CupertinoColors.white].
  final Color unselectedColor;

  /// The color used to fill the background of the selected widget and as the text
  /// color of unselected widgets.
  ///
  /// This attribute must not be null.
  ///
  /// If this attribute is unspecified, this color will default to
  /// [CupertinoColors.activeBlue].
  final Color selectedColor;

  /// The color used as the border around each widget.
  ///
  /// This attribute must not be null.
  ///
  /// If this attribute is unspecified, this color will default to
  /// [CupertinoColors.activeBlue].
  final Color borderColor;

  /// The color used to fill the background of the widget the user is
  /// temporarily interacting with through a long press or drag.
  ///
  /// This attribute must not be null.
  ///
  /// If this attribute is unspecified, this color will default to
  /// `Color(0x33007AFF)`, a light, partially-transparent blue color.
  final Color pressedColor;

  @override
  _SegmentedControlState<T> createState() => _SegmentedControlState<T>();
}

class _SegmentedControlState<T> extends State<CupertinoSegmentedControl<T>>
    with TickerProviderStateMixin<CupertinoSegmentedControl<T>> {
  T _pressedKey;

  final List<AnimationController> _selectionControllers = <AnimationController>[];
  final List<ColorTween> _childTweens = <ColorTween>[];

  ColorTween _forwardBackgroundColorTween;
  ColorTween _reverseBackgroundColorTween;
  ColorTween _textColorTween;

  @override
  void initState() {
    super.initState();
    _forwardBackgroundColorTween = ColorTween(
      begin: widget.pressedColor,
      end: widget.selectedColor,
    );
    _reverseBackgroundColorTween = ColorTween(
      begin: widget.unselectedColor,
      end: widget.selectedColor,
    );
    _textColorTween = ColorTween(
      begin: widget.selectedColor,
      end: widget.unselectedColor,
    );

    for (T key in widget.children.keys) {
      final AnimationController animationController = createAnimationController();
      if (widget.groupValue == key) {
        _childTweens.add(_reverseBackgroundColorTween);
        animationController.value = 1.0;
      } else {
        _childTweens.add(_forwardBackgroundColorTween);
      }
      _selectionControllers.add(animationController);
    }
  }

  AnimationController createAnimationController() {
    return AnimationController(
      duration: _kFadeDuration,
      vsync: this,
    )..addListener(() {
        setState(() {
          // State of background/text colors has changed
        });
      });
  }

  @override
  void dispose() {
    for (AnimationController animationController in _selectionControllers) {
      animationController.dispose();
    }
    super.dispose();
  }

  void _onTapDown(T currentKey) {
    if (_pressedKey == null && currentKey != widget.groupValue) {
      setState(() {
        _pressedKey = currentKey;
      });
    }
  }

  void _onTapCancel() {
    setState(() {
      _pressedKey = null;
    });
  }

  void _onTap(T currentKey) {
    if (currentKey != widget.groupValue && currentKey == _pressedKey) {
      widget.onValueChanged(currentKey);
      _pressedKey = null;
    }
  }

  Color getTextColor(int index, T currentKey) {
    if (_selectionControllers[index].isAnimating)
      return _textColorTween.evaluate(_selectionControllers[index]);
    if (widget.groupValue == currentKey)
      return widget.unselectedColor;
    return widget.selectedColor;
  }

  Color getBackgroundColor(int index, T currentKey) {
    if (_selectionControllers[index].isAnimating)
      return _childTweens[index].evaluate(_selectionControllers[index]);
    if (widget.groupValue == currentKey)
      return widget.selectedColor;
    if (_pressedKey == currentKey)
      return widget.pressedColor;
    return widget.unselectedColor;
  }

  void updateAnimationControllers() {
    if (_selectionControllers.length > widget.children.length) {
      _selectionControllers.length = widget.children.length;
      _childTweens.length = widget.children.length;
    } else {
      for (int index = _selectionControllers.length; index < widget.children.length; index += 1) {
        _selectionControllers.add(createAnimationController());
        _childTweens.add(_reverseBackgroundColorTween);
      }
    }
  }

  @override
  void didUpdateWidget(CupertinoSegmentedControl<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.children.length != widget.children.length) {
      updateAnimationControllers();
    }

    if (oldWidget.groupValue != widget.groupValue) {
      int index = 0;
      for (T key in widget.children.keys) {
        if (widget.groupValue == key) {
          _childTweens[index] = _forwardBackgroundColorTween;
          _selectionControllers[index].forward();
        } else {
          _childTweens[index] = _reverseBackgroundColorTween;
          _selectionControllers[index].reverse();
        }
        index += 1;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _gestureChildren = <Widget>[];
    final List<Color> _backgroundColors = <Color>[];
    int index = 0;
    int selectedIndex;
    int pressedIndex;
    for (T currentKey in widget.children.keys) {
      selectedIndex = (widget.groupValue == currentKey) ? index : selectedIndex;
      pressedIndex = (_pressedKey == currentKey) ? index : pressedIndex;

      final TextStyle textStyle = DefaultTextStyle.of(context).style.copyWith(
        color: getTextColor(index, currentKey),
      );
      final IconThemeData iconTheme = IconThemeData(
        color: getTextColor(index, currentKey),
      );

      Widget child = Center(
        child: widget.children[currentKey],
      );

      child = GestureDetector(
        onTapDown: (TapDownDetails event) {
          _onTapDown(currentKey);
        },
        onTapCancel: _onTapCancel,
        onTap: () {
          _onTap(currentKey);
        },
        child: IconTheme(
          data: iconTheme,
          child: DefaultTextStyle(
            style: textStyle,
            child: Semantics(
              button: true,
              inMutuallyExclusiveGroup: true,
              selected: widget.groupValue == currentKey,
              child: child,
            ),
          ),
        ),
      );

      _backgroundColors.add(getBackgroundColor(index, currentKey));
      _gestureChildren.add(child);
      index += 1;
    }

    final Widget box = _SegmentedControlRenderWidget<T>(
      children: _gestureChildren,
      selectedIndex: selectedIndex,
      pressedIndex: pressedIndex,
      backgroundColors: _backgroundColors,
      borderColor: widget.borderColor,
    );

    return Padding(
      padding: _kHorizontalItemPadding.resolve(Directionality.of(context)),
      child: UnconstrainedBox(
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
    @required this.backgroundColors,
    @required this.borderColor,
  }) : super(
          key: key,
          children: children,
        );

  final int selectedIndex;
  final int pressedIndex;
  final List<Color> backgroundColors;
  final Color borderColor;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderSegmentedControl<T>(
      textDirection: Directionality.of(context),
      selectedIndex: selectedIndex,
      pressedIndex: pressedIndex,
      backgroundColors: backgroundColors,
      borderColor: borderColor,
    );
  }

  @override
  void updateRenderObject(BuildContext context, _RenderSegmentedControl<T> renderObject) {
    renderObject
      ..textDirection = Directionality.of(context)
      ..selectedIndex = selectedIndex
      ..pressedIndex = pressedIndex
      ..backgroundColors = backgroundColors
      ..borderColor = borderColor;
  }
}

class _SegmentedControlContainerBoxParentData extends ContainerBoxParentData<RenderBox> {
  RRect surroundingRect;
}

typedef _NextChild = RenderBox Function(RenderBox child);

class _RenderSegmentedControl<T> extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, ContainerBoxParentData<RenderBox>>,
        RenderBoxContainerDefaultsMixin<RenderBox, ContainerBoxParentData<RenderBox>> {
  _RenderSegmentedControl({
    List<RenderBox> children,
    @required int selectedIndex,
    @required int pressedIndex,
    @required TextDirection textDirection,
    @required List<Color> backgroundColors,
    @required Color borderColor,
  })  : assert(textDirection != null),
        _textDirection = textDirection,
        _selectedIndex = selectedIndex,
        _pressedIndex = pressedIndex,
        _backgroundColors = backgroundColors,
        _borderColor = borderColor {
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

  List<Color> get backgroundColors => _backgroundColors;
  List<Color> _backgroundColors;
  set backgroundColors(List<Color> value) {
    if (_backgroundColors == value) {
      return;
    }
    _backgroundColors = value;
    markNeedsPaint();
  }

  Color get borderColor => _borderColor;
  Color _borderColor;
  set borderColor(Color value) {
    if (_borderColor == value) {
      return;
    }
    _borderColor = value;
    markNeedsPaint();
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    RenderBox child = firstChild;
    double minWidth = 0.0;
    while (child != null) {
      final _SegmentedControlContainerBoxParentData childParentData = child.parentData;
      final double childWidth = child.getMinIntrinsicWidth(height);
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
      final double childWidth = child.getMaxIntrinsicWidth(height);
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
      final double childHeight = child.getMinIntrinsicHeight(width);
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
      final double childHeight = child.getMaxIntrinsicHeight(width);
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
      child.parentData = _SegmentedControlContainerBoxParentData();
    }
  }

  void _layoutRects(_NextChild nextChild, RenderBox leftChild, RenderBox rightChild) {
    RenderBox child = leftChild;
    double start = 0.0;
    while (child != null) {
      final _SegmentedControlContainerBoxParentData childParentData = child.parentData;
      final Offset childOffset = Offset(start, 0.0);
      childParentData.offset = childOffset;
      final Rect childRect = Rect.fromLTWH(start, 0.0, child.size.width, child.size.height);
      RRect rChildRect;
      if (child == leftChild) {
        rChildRect = RRect.fromRectAndCorners(childRect, topLeft: const Radius.circular(3.0),
            bottomLeft: const Radius.circular(3.0));
      } else if (child == rightChild) {
        rChildRect = RRect.fromRectAndCorners(childRect, topRight: const Radius.circular(3.0),
            bottomRight: const Radius.circular(3.0));
      } else {
        rChildRect = RRect.fromRectAndCorners(childRect);
      }
      childParentData.surroundingRect = rChildRect;
      start += child.size.width;
      child = nextChild(child);
    }
  }

  @override
  void performLayout() {
    double maxHeight = _kMinSegmentedControlHeight;

    double childWidth = constraints.minWidth / childCount;
    for (RenderBox child in getChildrenAsList()) {
      childWidth = math.max(childWidth, child.getMaxIntrinsicWidth(double.infinity));
    }
    childWidth = math.min(childWidth, constraints.maxWidth / childCount);

    RenderBox child = firstChild;
    while (child != null) {
      final double boxHeight = child.getMaxIntrinsicHeight(childWidth);
      maxHeight = math.max(maxHeight, boxHeight);
      child = childAfter(child);
    }

    constraints.constrainHeight(maxHeight);

    final BoxConstraints childConstraints = BoxConstraints.tightFor(
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

    size = constraints.constrain(Size(childWidth * childCount, maxHeight));
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

    context.canvas.drawRRect(
      childParentData.surroundingRect.shift(offset),
      Paint()
        ..color = backgroundColors[childIndex]
        ..style = PaintingStyle.fill,
    );
    context.canvas.drawRRect(
      childParentData.surroundingRect.shift(offset),
      Paint()
        ..color = borderColor
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke,
    );

    context.paintChild(child, childParentData.offset + offset);
  }

  @override
  bool hitTestChildren(HitTestResult result, {@required Offset position}) {
    assert(position != null);
    RenderBox child = lastChild;
    while (child != null) {
      final _SegmentedControlContainerBoxParentData childParentData = child.parentData;
      if (childParentData.surroundingRect.contains(position)) {
        return child.hitTest(result, position: (Offset.zero & child.size).center);
      }
      child = childParentData.previousSibling;
    }
    return false;
  }
}
