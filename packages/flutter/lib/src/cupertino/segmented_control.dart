// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'theme.dart';

// Minimum padding from edges of the segmented control to edges of
// encompassing widget.
const EdgeInsetsGeometry _kHorizontalItemPadding = EdgeInsets.symmetric(vertical: 2, horizontal: 3);

// The duration of the fade animation used to transition when a new widget
// is selected.
const Duration _kFadeDuration = Duration(milliseconds: 165);

// Extracted from https://developer.apple.com/design/resources/.
// The corner radius of the thumb.
const double _kThumbCornerRadius = 6.93;
const EdgeInsets _kThumbInsets = EdgeInsets.symmetric(horizontal: 1);

// The corner radius of the segmented control.
const double _kCornerRadius = 8.91;

// Minimum height of the segmented control.
const double _kMinSegmentedControlHeight = 28.0;

const Color _kSeparatorColor = Color(0x4D8E8E93);

const CupertinoDynamicColor _kThumbColor = CupertinoDynamicColor.withBrightness(
  color: Color(0xFFFFFFFF),
  darkColor: Color(0xFF636366),
);

// The amount of space by which to inset each separator.
const EdgeInsets _kSeparatorInset = EdgeInsets.symmetric(vertical: 6);
const double _kSeparatorWidth = 1;

const SpringDescription _kSegmentedControlSpringDescription = SpringDescription(mass: 1, stiffness: 503.551, damping: 44.8799);

const Duration _kSpringAnimationDuration = Duration(milliseconds: 410);

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
/// arguments can be used to override the segmented control's colors from
/// [CupertinoTheme] defaults.
///
/// See also:
///
///  * <https://developer.apple.com/design/human-interface-guidelines/ios/controls/segmented-controls/>
class CupertinoSegmentedControl<T> extends StatefulWidget {
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
  /// The [groupValue] is the currently selected value for the segmented control.
  /// If no [groupValue] is provided, or the [groupValue] is null, no widget will
  /// appear as selected. The [groupValue] must be either null or one of the keys
  /// in the [children] map.
  CupertinoSegmentedControl({
    Key key,
    @required this.children,
    @required this.onValueChanged,
    this.groupValue,
    this.unselectedColor,
    this.selectedColor,
    this.borderColor,
    this.pressedColor,
    this.padding,
  }) : assert(children != null),
       assert(children.length >= 2),
       assert(onValueChanged != null),
       assert(
         groupValue == null || children.keys.any((T child) => child == groupValue),
         'The groupValue must be either null or one of the keys in the children map.',
       ),
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
  /// Defaults to [CupertinoTheme]'s `primaryContrastingColor` if null.
  final Color unselectedColor;

  /// The color used to fill the background of the selected widget and as the text
  /// color of unselected widgets.
  ///
  /// Defaults to [CupertinoTheme]'s `primaryColor` if null.
  final Color selectedColor;

  /// The color used as the border around each widget.
  ///
  /// Defaults to [CupertinoTheme]'s `primaryColor` if null.
  final Color borderColor;

  /// The color used to fill the background of the widget the user is
  /// temporarily interacting with through a long press or drag.
  ///
  /// Defaults to the selectedColor at 20% opacity if null.
  final Color pressedColor;

  /// The CupertinoSegmentedControl will be placed inside this padding
  ///
  /// Defaults to EdgeInsets.symmetric(horizontal: 16.0)
  final EdgeInsetsGeometry padding;

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

  Color _selectedColor;
  Color _unselectedColor;
  Color _borderColor;
  Color _pressedColor;

  TextDirection textDirection;

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

  bool _updateColors() {
    assert(mounted, 'This should only be called after didUpdateDependencies');
    bool changed = false;
    final Color selectedColor = widget.selectedColor ?? CupertinoTheme.of(context).primaryColor;
    if (_selectedColor != selectedColor) {
      changed = true;
      _selectedColor = selectedColor;
    }
    final Color unselectedColor = widget.unselectedColor ?? CupertinoTheme.of(context).primaryContrastingColor;
    if (_unselectedColor != unselectedColor) {
      changed = true;
      _unselectedColor = unselectedColor;
    }
    final Color borderColor = widget.borderColor ?? CupertinoTheme.of(context).primaryColor;
    if (_borderColor != borderColor) {
      changed = true;
      _borderColor = borderColor;
    }
    final Color pressedColor = widget.pressedColor ?? CupertinoTheme.of(context).primaryColor.withOpacity(0.2);
    if (_pressedColor != pressedColor) {
      changed = true;
      _pressedColor = pressedColor;
    }

    _forwardBackgroundColorTween = ColorTween(
      begin: _pressedColor,
      end: _selectedColor,
    );
    _reverseBackgroundColorTween = ColorTween(
      begin: _unselectedColor,
      end: _selectedColor,
    );
    _textColorTween = ColorTween(
      begin: _selectedColor,
      end: _unselectedColor,
    );
    return changed;
  }

  void _updateAnimationControllers() {
    assert(mounted, 'This should only be called after didUpdateDependencies');
    for (AnimationController controller in _selectionControllers) {
      controller.dispose();
    }
    _selectionControllers.clear();
    _childTweens.clear();

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    textDirection = Directionality.of(context);

    if (_updateColors()) {
      _updateAnimationControllers();
    }
  }

  @override
  void didUpdateWidget(CupertinoSegmentedControl<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_updateColors() || oldWidget.children.length != widget.children.length) {
      _updateAnimationControllers();
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
      return _unselectedColor;
    return _selectedColor;
  }

  Color getBackgroundColor(int index, T currentKey) {
    if (_selectionControllers[index].isAnimating)
      return _childTweens[index].evaluate(_selectionControllers[index]);
    if (widget.groupValue == currentKey)
      return _selectedColor;
    if (_pressedKey == currentKey)
      return _pressedColor;
    return _unselectedColor;
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _gestureChildren = <Widget>[];
    final List<Color> _backgroundColors = <Color>[];

    int index = 0;
    int selectedIndex;
    int pressedIndex;

    Iterable<T> keys;

    switch (textDirection) {
      case TextDirection.ltr:
        keys = widget.children.keys;
        break;
      case TextDirection.rtl:
        keys = widget.children.keys.toList().reversed;
        break;
    }

    for (T currentKey in keys) {
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

      child = IconTheme(
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
      borderColor: _borderColor,
      vsync: this,
    );

    return Container(
      padding: widget.padding ?? _kHorizontalItemPadding,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(_kCornerRadius)),
        color: CupertinoDynamicColor.resolve(CupertinoColors.tertiarySystemFill, context),
      ),
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
    @required this.vsync,
  }) : super(
          key: key,
          children: children,
        );

  final int selectedIndex;
  final int pressedIndex;
  final List<Color> backgroundColors;
  final Color borderColor;
  final TickerProvider vsync;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderSegmentedControl<T>(
      selectedIndex: selectedIndex,
      pressedIndex: pressedIndex,
      backgroundColors: backgroundColors,
      thumbColor: CupertinoDynamicColor.resolve(_kThumbColor, context),
      vsync: vsync,
    );
  }

  @override
  void updateRenderObject(BuildContext context, _RenderSegmentedControl<T> renderObject) {
    renderObject
      ..selectedIndex = selectedIndex
      ..pressedIndex = pressedIndex
      ..thumbColor = CupertinoDynamicColor.resolve(_kThumbColor, context)
      ..backgroundColors = backgroundColors;
  }
}

class _SegmentedControlContainerBoxParentData extends ContainerBoxParentData<RenderBox> { }

// The behavior of a UISegmentedControl as observed on iOS 13.1:
//
// 1. Tap up events inside it will set the current selected index to the index of the
//    segment at the tap up location instantaneously (there might be animation
//    but the index change seems to happen right away), unless the tap down event from the same
//    touch event didn't happen within the segmented control, in which case the touch event will be ignored
//    entirely (will be referring to these touch events as invalid touch events below).
//
// 2. A valid tap up event will also trigger the sliding CASpringAnimation (even
//    when it lands on the current segment), starting from the current `frame`
//    of the thumb. The previous sliding animation, if still playing, will be
//    removed and its velocity reset to 0. The sliding animation has a fixed
//    duration, regardless of the distance or transform.
//
// 3. When the sliding animation plays two other animations take place. In one animation
//    the content of the current segment gradually becomes "highlighted", turning the
//    font weight to semibold. The other is the separator fadein/fadeout animation.
//
// 4. A tap down event on the segment pointed to by the current selected
//    index will trigger a CABasciaAnimation that shrinks the thumb, even if the
//    sliding animation is still playing. The corresponding tap up event will revert
//    the process (eyeballed).
//
// 5. A tap down event on other segments will trigger a CABasciaAnimation that
//    fades out the content, eventually reduces the alpha of that segment to 20%.
class _RenderSegmentedControl<T> extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, ContainerBoxParentData<RenderBox>>,
        RenderBoxContainerDefaultsMixin<RenderBox, ContainerBoxParentData<RenderBox>> {
  _RenderSegmentedControl({
    List<RenderBox> children,
    @required int selectedIndex,
    @required int pressedIndex,
    @required List<Color> backgroundColors,
    @required Color thumbColor,
    @required this.vsync,
  }) : _selectedIndex = selectedIndex,
       _pressedIndex = pressedIndex,
       _backgroundColors = backgroundColors,
       _thumbColor = thumbColor,
       thumbController = AnimationController(
         duration: _kSpringAnimationDuration,
         value: 0,
         vsync: vsync,
       ),
       thumbScaleController = AnimationController(
         duration: _kSpringAnimationDuration,
         value: 1,
         lowerBound: 0.95,
         upperBound: 1,
         vsync: vsync,
       ) {
         addAll(children);
         thumbController.addListener(markNeedsPaint);
         thumbScaleController.addListener(markNeedsPaint);

         _drag
          ..onDown = _onDown
          ..onUpdate = _onUpdate
          ..onEnd = _onEnd
          ..onCancel = _onCancel;
       }

  final TickerProvider vsync;

  final HorizontalDragGestureRecognizer _drag = HorizontalDragGestureRecognizer();

  // Unscaled Thumb Rect
  Rect _currentThumbRect;

  // Unscaled Thumb Rect;
  Tween<Rect> _currentThumbTween;
  final AnimationController thumbController;
  final Tween<double> thumbScaleTween = Tween<double>(begin: 1, end: 0.6);
  final AnimationController thumbScaleController;

  int get selectedIndex => _selectedIndex;
  int _selectedIndex;

  final SpringSimulation thumbRectSimulation = SpringSimulation(
    _kSegmentedControlSpringDescription,
    0,
    1,
    0, // Everytime a new spring animation starts the previous animation stops.
  );

  bool _needsThumbAnimationUpdate = false;
  set selectedIndex(int value) {
    if (_selectedIndex == value) {
      return;
    }

    _needsThumbAnimationUpdate = true;
    _selectedIndex = value;
    markNeedsPaint();
    markNeedsSemanticsUpdate();
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

  List<Color> get backgroundColors => _backgroundColors;
  List<Color> _backgroundColors;
  set backgroundColors(List<Color> value) {
    if (_backgroundColors == value) {
      return;
    }
    _backgroundColors = value;
    markNeedsPaint();
  }

  Color get thumbColor => _thumbColor;
  Color _thumbColor;
  set thumbColor(Color value) {
    if (_thumbColor == value) {
      return;
    }
    _thumbColor = value;
    markNeedsPaint();
  }

  // When the touch event lands directly on top of the thumb, the thumb shrinks
  // animatedly
  double _thumbScale = 1;
  double get thumbScale => _thumbScale;
  set thumbScale(double value) {
    if (thumbScale == value) {
      return;
    }
    _thumbScale = value;
    markNeedsPaint();
  }

  double get totalSeparatorWidth => (_kSeparatorInset.horizontal + _kSeparatorWidth) * (childCount - 1);

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    assert(debugHandleEvent(event, entry));
    if (event is PointerDownEvent) {
      _drag.addPointer(event);
    }
  }

  Offset localDragOffset;
  bool startedOnSelectedSegment;

  int indexFromLocation(Offset location) => (localDragOffset.dx / (size.width / childCount)).floor();

  void _onDown(DragDownDetails details) {
    assert(size.contains(details.localPosition));
    localDragOffset = details.localPosition;
    final int index = indexFromLocation(localDragOffset);
    startedOnSelectedSegment = index == selectedIndex;

    if (startedOnSelectedSegment) {
      thumbScaleController.reverse();
    }
  }

  void _onUpdate(DragUpdateDetails details) {
    localDragOffset = details.localPosition;

    if (startedOnSelectedSegment) {
      selectedIndex = indexFromLocation(localDragOffset);
    }
  }

  void _onEnd(DragEndDetails details) {
    if (startedOnSelectedSegment) {
      thumbScaleController.forward();
    }
    if (localDragOffset != null && size.contains(localDragOffset)) {
      selectedIndex = indexFromLocation(localDragOffset);
    }
  }

  void _onCancel() {
    if (startedOnSelectedSegment) {
      thumbScaleController.forward();
    }
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
    return minWidth * childCount + totalSeparatorWidth;
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
    return maxWidth * childCount + totalSeparatorWidth;
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

  @override
  void performLayout() {
    double childWidth = (constraints.minWidth - totalSeparatorWidth) / childCount;
    double maxHeight = _kMinSegmentedControlHeight;

    for (RenderBox child in getChildrenAsList()) {
      childWidth = math.max(childWidth, child.getMaxIntrinsicWidth(double.infinity));
    }

    childWidth = math.min(
      childWidth,
      (constraints.maxWidth - totalSeparatorWidth) / childCount,
    );

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

    // Layout children.
    child = firstChild;
    while (child != null) {
      child.layout(childConstraints, parentUsesSize: true);
      child = childAfter(child);
    }

    double start = 0.0;
    child = firstChild;

    while (child != null) {
      final _SegmentedControlContainerBoxParentData childParentData = child.parentData;
      final Offset childOffset = Offset(start, 0.0);
      childParentData.offset = childOffset;
      start += child.size.width + _kSeparatorWidth + _kSeparatorInset.horizontal;
      child = childAfter(child);
    }

    size = constraints.constrain(Size(childWidth * childCount + totalSeparatorWidth, maxHeight));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final List<RenderBox> children = getChildrenAsList();

    if (selectedIndex != null) {
      final RenderBox selectedChild = children[selectedIndex];
      final Rect unscaledThumbTargetRect = _unscaledThumbRectFrom(selectedChild);

      if (_needsThumbAnimationUpdate) {
        // Needs to ensure _currentThumbRect makes sense.
        _currentThumbTween = RectTween(begin: _currentThumbRect, end: unscaledThumbTargetRect);
        thumbController.animateWith(thumbRectSimulation);
        _needsThumbAnimationUpdate = false;
      }

      _currentThumbRect = _currentThumbTween?.evaluate(thumbController)
                        ?? unscaledThumbTargetRect;

      final double thumbScale = thumbScaleController.value;

      final Rect thumbRect = Rect.fromCenter(
        center: _currentThumbRect.center,
        width: _currentThumbRect.width * thumbScale,
        height: _currentThumbRect.height * thumbScale,
      );

      _paintThumb(context, offset, thumbRect);
    } else {
      _currentThumbRect = null;
    }

    for (int index = 0; index < children.length; index++) {
      _paintChild(context, offset, children[index], index);
    }
  }

  void _paintChild(PaintingContext context, Offset offset, RenderBox child, int childIndex) {
    assert(child != null);

    final _SegmentedControlContainerBoxParentData childParentData = child.parentData;
    context.paintChild(child, childParentData.offset + offset);
  }

  // The target thumb rect before scaled by thumbScale.
  Rect _unscaledThumbRectFrom(RenderBox selectedChild) {
    final _SegmentedControlContainerBoxParentData childParentData = selectedChild.parentData;
    return _kThumbInsets.inflateRect(childParentData.offset & selectedChild.size);
  }

  void _paintThumb(PaintingContext context, Offset offset, Rect thumbRect) {
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(thumbRect.shift(offset), const Radius.circular(_kThumbCornerRadius)),
      Paint()
        ..style = PaintingStyle.fill
        ..color = thumbColor,
    );
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, { @required Offset position }) {
    assert(position != null);
    RenderBox child = lastChild;
    while (child != null) {
      final _SegmentedControlContainerBoxParentData childParentData = child.parentData;
      if ((childParentData.offset & child.size).contains(position)) {
        final Offset center = (Offset.zero & child.size).center;
        return result.addWithRawTransform(
          transform: MatrixUtils.forceToPoint(center),
          position: center,
          hitTest: (BoxHitTestResult result, Offset position) {
            assert(position == center);
            return child.hitTest(result, position: center);
          },
        );
      }
      child = childParentData.previousSibling;
    }
    return false;
  }
}
