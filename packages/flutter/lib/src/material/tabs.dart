// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'app_bar.dart';
import 'colors.dart';
import 'debug.dart';
import 'icon.dart';
import 'icon_theme.dart';
import 'icon_theme_data.dart';
import 'ink_well.dart';
import 'material.dart';
import 'theme.dart';

typedef void _TabLayoutChanged(Size size, List<double> widths);

// See https://www.google.com/design/spec/components/tabs.html#tabs-specs
const double _kTabHeight = 46.0;
const double _kTextAndIconTabHeight = 72.0;
const double _kTabIndicatorHeight = 2.0;
const double _kMinTabWidth = 72.0;
const double _kMaxTabWidth = 264.0;
const EdgeInsets _kTabLabelPadding = const EdgeInsets.symmetric(horizontal: 12.0);
const double _kTabBarScrollDrag = 0.025;
const Duration _kTabBarScroll = const Duration(milliseconds: 200);

// Curves for the leading and trailing edge of the selected tab indicator.
const Curve _kTabIndicatorLeadingCurve = Curves.easeOut;
const Curve _kTabIndicatorTrailingCurve = Curves.easeIn;

// The additional factor of 5 is to further increase sensitivity to swipe
// gestures and was determined "experimentally".
final double _kMinFlingVelocity = kPixelScrollTolerance.velocity / 5.0;

class _TabBarParentData extends ContainerBoxParentDataMixin<RenderBox> { }

class _RenderTabBar extends RenderBox with
    ContainerRenderObjectMixin<RenderBox, _TabBarParentData>,
    RenderBoxContainerDefaultsMixin<RenderBox, _TabBarParentData> {

  _RenderTabBar(this.onLayoutChanged);

  int _selectedIndex;
  int get selectedIndex => _selectedIndex;
  set selectedIndex(int value) {
    if (_selectedIndex != value) {
      _selectedIndex = value;
      markNeedsPaint();
    }
  }

  Color _indicatorColor;
  Color get indicatorColor => _indicatorColor;
  set indicatorColor(Color value) {
    if (_indicatorColor != value) {
      _indicatorColor = value;
      markNeedsPaint();
    }
  }

  Rect _indicatorRect;
  Rect get indicatorRect => _indicatorRect;
  set indicatorRect(Rect value) {
    if (_indicatorRect != value) {
      _indicatorRect = value;
      markNeedsPaint();
    }
  }

  bool _textAndIcons;
  bool get textAndIcons => _textAndIcons;
  set textAndIcons(bool value) {
    if (_textAndIcons != value) {
      _textAndIcons = value;
      markNeedsLayout();
    }
  }

  bool _isScrollable;
  bool get isScrollable => _isScrollable;
  set isScrollable(bool value) {
    if (_isScrollable != value) {
      _isScrollable = value;
      markNeedsLayout();
    }
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _TabBarParentData)
      child.parentData = new _TabBarParentData();
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    double maxWidth = 0.0;
    RenderBox child = firstChild;
    while (child != null) {
      maxWidth = math.max(maxWidth, child.getMinIntrinsicWidth(height));
      final _TabBarParentData childParentData = child.parentData;
      child = childParentData.nextSibling;
    }
    return isScrollable ? maxWidth : maxWidth * childCount;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    double maxWidth = 0.0;
    double totalWidth = 0.0;
    RenderBox child = firstChild;
    while (child != null) {
      double childWidth = child.getMaxIntrinsicWidth(height);
      maxWidth = math.max(maxWidth, childWidth);
      totalWidth += childWidth;
      final _TabBarParentData childParentData = child.parentData;
      child = childParentData.nextSibling;
    }
    return isScrollable ? totalWidth : maxWidth * childCount;
  }

  double get _tabHeight => textAndIcons ? _kTextAndIconTabHeight : _kTabHeight;
  double get _tabBarHeight => _tabHeight + _kTabIndicatorHeight;

  @override
  double computeMinIntrinsicHeight(double width) => _tabBarHeight;

  @override
  double computeMaxIntrinsicHeight(double width) => _tabBarHeight;

  void layoutFixedWidthTabs() {
    double tabWidth = size.width / childCount;
    BoxConstraints tabConstraints =
      new BoxConstraints.tightFor(width: tabWidth, height: _tabHeight);
    double x = 0.0;
    RenderBox child = firstChild;
    while (child != null) {
      child.layout(tabConstraints);
      final _TabBarParentData childParentData = child.parentData;
      childParentData.offset = new Offset(x, 0.0);
      x += tabWidth;
      child = childParentData.nextSibling;
    }
  }

  double layoutScrollableTabs() {
    BoxConstraints tabConstraints = new BoxConstraints(
      minWidth: _kMinTabWidth,
      maxWidth: _kMaxTabWidth,
      minHeight: _tabHeight,
      maxHeight: _tabHeight
    );
    double x = 0.0;
    RenderBox child = firstChild;
    while (child != null) {
      child.layout(tabConstraints, parentUsesSize: true);
      final _TabBarParentData childParentData = child.parentData;
      childParentData.offset = new Offset(x, 0.0);
      x += child.size.width;
      child = childParentData.nextSibling;
    }
    return x;
  }

  Size layoutSize;
  List<double> layoutWidths;
  _TabLayoutChanged onLayoutChanged;

  void reportLayoutChangedIfNeeded() {
    assert(onLayoutChanged != null);
    List<double> widths = new List<double>(childCount);
    if (!isScrollable && childCount > 0) {
      double tabWidth = size.width / childCount;
      widths.fillRange(0, widths.length, tabWidth);
    } else if (isScrollable) {
      RenderBox child = firstChild;
      int childIndex = 0;
      while (child != null) {
        widths[childIndex++] = child.size.width;
        final _TabBarParentData childParentData = child.parentData;
        child = childParentData.nextSibling;
      }
      assert(childIndex == widths.length);
    }
    if (size != layoutSize || widths != layoutWidths) {
      layoutSize = size;
      layoutWidths = widths;
      onLayoutChanged(layoutSize, layoutWidths);
    }
  }

  @override
  void performLayout() {
    assert(constraints is BoxConstraints);
    if (childCount == 0)
      return;

    if (isScrollable) {
      double tabBarWidth = layoutScrollableTabs();
      size = constraints.constrain(new Size(tabBarWidth, _tabBarHeight));
    } else {
      size = constraints.constrain(new Size(constraints.maxWidth, _tabBarHeight));
      layoutFixedWidthTabs();
    }

    if (onLayoutChanged != null)
      reportLayoutChangedIfNeeded();
  }

  @override
  bool hitTestChildren(HitTestResult result, { Point position }) {
    return defaultHitTestChildren(result, position: position);
  }

  void _paintIndicator(Canvas canvas, RenderBox selectedTab, Offset offset) {
    if (indicatorColor == null)
      return;

    if (indicatorRect != null) {
      canvas.drawRect(indicatorRect.shift(offset), new Paint()..color = indicatorColor);
      return;
    }

    final Size size = new Size(selectedTab.size.width, _kTabIndicatorHeight);
    final _TabBarParentData selectedTabParentData = selectedTab.parentData;
    final Point point = new Point(
      selectedTabParentData.offset.dx,
      _tabBarHeight - _kTabIndicatorHeight
    );
    canvas.drawRect((point + offset) & size, new Paint()..color = indicatorColor);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    int index = 0;
    RenderBox child = firstChild;
    while (child != null) {
      final _TabBarParentData childParentData = child.parentData;
      context.paintChild(child, childParentData.offset + offset);
      if (index++ == selectedIndex)
        _paintIndicator(context.canvas, child, offset);
      child = childParentData.nextSibling;
    }
  }
}

class _TabBarWrapper extends MultiChildRenderObjectWidget {
  _TabBarWrapper({
    Key key,
    List<Widget> children,
    this.selectedIndex,
    this.indicatorColor,
    this.indicatorRect,
    this.textAndIcons,
    this.isScrollable: false,
    this.onLayoutChanged
  }) : super(key: key, children: children);

  final int selectedIndex;
  final Color indicatorColor;
  final Rect indicatorRect;
  final bool textAndIcons;
  final bool isScrollable;
  final _TabLayoutChanged onLayoutChanged;

  @override
  _RenderTabBar createRenderObject(BuildContext context) {
    _RenderTabBar result = new _RenderTabBar(onLayoutChanged);
    updateRenderObject(context, result);
    return result;
  }

  @override
  void updateRenderObject(BuildContext context, _RenderTabBar renderObject) {
    renderObject
      ..selectedIndex = selectedIndex
      ..indicatorColor = indicatorColor
      ..indicatorRect = indicatorRect
      ..textAndIcons = textAndIcons
      ..isScrollable = isScrollable
      ..onLayoutChanged = onLayoutChanged;
  }
}

/// Signature for building icons for tabs.
///
/// See also:
///
///  * [TabLabel]
typedef Widget TabLabelIconBuilder(BuildContext context, Color color);

/// Each TabBar tab can display either a title [text], an icon, or both. An icon
/// can be specified by either the [icon] or [iconBuilder] parameters. In either
/// case the icon will occupy a 24x24 box above the title text. If iconBuilder
/// is specified its color parameter is the color that an ordinary icon would
/// have been drawn with. The color reflects that tab's selection state.
class TabLabel {
  /// Creates a tab label description.
  ///
  /// At least one of [text], [icon], or [iconBuilder] must be non-null.
  const TabLabel({ this.text, this.icon, this.iconBuilder });

  /// The text to display as the label of the tab.
  final String text;

  /// The icon to display as the label of the tab.
  ///
  /// The size and color of the icon is configured automatically using an
  /// [IconTheme] and therefore does not need to be explicitly given in the
  /// icon widget.
  ///
  /// See [Icon], [ImageIcon].
  final Widget icon;

  /// Called if [icon] is null to build an icon as a label for this tab.
  ///
  /// The color argument to this builder is the color that an ordinary icon
  /// would have been drawn with. The color reflects that tab's selection state.
  ///
  /// Return value must be non-null.
  final TabLabelIconBuilder iconBuilder;

  /// Whether this label has any text (specified using [text]).
  bool get hasText => text != null;

  /// Whether this label has an icon (specified either using [icon] or [iconBuilder]).
  bool get hasIcon => icon != null || iconBuilder != null;
}

class _Tab extends StatelessWidget {
  _Tab({
    Key key,
    this.onSelected,
    this.label,
    this.color
  }) : super(key: key) {
    assert(label.hasText || label.hasIcon);
  }

  final VoidCallback onSelected;
  final TabLabel label;
  final Color color;

  Widget _buildLabelText() {
    assert(label.text != null);
    TextStyle style = new TextStyle(color: color);
    return new Text(
      label.text,
      style: style,
      softWrap: false,
      overflow: TextOverflow.fade
    );
  }

  Widget _buildLabelIcon(BuildContext context) {
    assert(label.hasIcon);
    if (label.icon != null) {
      return new IconTheme.merge(
        context: context,
        data: new IconThemeData(
          color: color,
          size: 24.0
        ),
        child: label.icon
      );
    } else {
      return new SizedBox(
        width: 24.0,
        height: 24.0,
        child: label.iconBuilder(context, color)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    Widget labelContent;
    if (!label.hasIcon) {
      labelContent = _buildLabelText();
    } else if (!label.hasText) {
      labelContent = _buildLabelIcon(context);
    } else {
      labelContent = new Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          new Container(
            child: _buildLabelIcon(context),
            margin: const EdgeInsets.only(bottom: 10.0)
          ),
          _buildLabelText()
        ]
      );
    }

    Container centeredLabel = new Container(
      child: new Center(child: labelContent, widthFactor: 1.0, heightFactor: 1.0),
      constraints: new BoxConstraints(minWidth: _kMinTabWidth),
      padding: _kTabLabelPadding
    );

    return new InkWell(
      onTap: onSelected,
      child: centeredLabel
    );
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('$label');
  }
}

class _TabsScrollBehavior extends BoundedBehavior {
  _TabsScrollBehavior();

  @override
  bool isScrollable = true;

  @override
  Simulation createScrollSimulation(double position, double velocity) {
    if (!isScrollable)
      return null;

    double velocityPerSecond = velocity * 1000.0;
    return new BoundedFrictionSimulation(
      _kTabBarScrollDrag, position, velocityPerSecond, minScrollOffset, maxScrollOffset
    );
  }

  @override
  double applyCurve(double scrollOffset, double scrollDelta) {
    return (isScrollable) ? super.applyCurve(scrollOffset, scrollDelta) : 0.0;
  }
}

/// An abstract interface through which [TabBarSelection] reports changes.
abstract class TabBarSelectionAnimationListener {
  /// Called when the status of the [TabBarSelection] animation changes.
  void handleStatusChange(AnimationStatus status);

  /// Called on each animation frame when the [TabBarSelection] animation ticks.
  void handleProgressChange();

  /// Called when the [TabBarSelection] is deactivated.
  ///
  /// Implementations typically drop their reference to the [TabBarSelection]
  /// during this callback.
  void handleSelectionDeactivate();
}

/// Coordinates the tab selection between a [TabBar] and a [TabBarView].
///
/// Place a [TabBarSelection] widget in the tree such that it is a common
/// ancestor of both the [TabBar] and the [TabBarView]. Both the [TabBar] and
/// the [TabBarView] can alter which tab is selected. They coodinate by
/// listening to the selection value stored in a common ancestor
/// [TabBarSelection] selection widget.
class TabBarSelection<T> extends StatefulWidget {
  /// Creates a tab bar selection.
  ///
  /// The values argument must be non-null, non-empty, and each value must be
  /// unique. The value argument must either be null or contained in the values
  /// argument. The child argument must be non-null.
  TabBarSelection({
    Key key,
    this.value,
    @required this.values,
    this.onChanged,
    @required this.child
  }) : super(key: key)  {
    assert(values != null && values.length > 0);
    assert(new Set<T>.from(values).length == values.length);
    assert(value == null ? true : values.where((T e) => e == value).length == 1);
    assert(child != null);
  }

  /// The current value of the selection.
  final T value;

  /// The list of possible values that the selection can obtain.
  List<T> values;

  /// Called when the value of the selection should change.
  ///
  /// The tab bar selection passes the new value to the callback but does not
  /// actually change state until the parent widget rebuilds the tab bar
  /// selection with the new value.
  ///
  /// If null, the tab bar selection cannot change value.
  final ValueChanged<T> onChanged;

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  TabBarSelectionState<T> createState() => new TabBarSelectionState<T>();

  /// The state from the closest instance of this class that encloses the given context.
  static TabBarSelectionState<dynamic/*=T*/> of/*<T>*/(BuildContext context) {
    return context.ancestorStateOfType(new TypeMatcher<TabBarSelectionState<dynamic/*=T*/>>());
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('current tab: $value');
    description.add('available tabs: $values');
  }
}

/// State for a [TabBarSelection] widget.
///
/// Subclasses of [TabBarSelection] typically use [State] objects that extend
/// this class.
class TabBarSelectionState<T> extends State<TabBarSelection<T>> with SingleTickerProviderStateMixin {

  // Both the TabBar and TabBarView classes access _controller because they
  // alternately drive selection progress between tabs.
  AnimationController _controller;

  /// An animation that updates as the selected tab changes.
  Animation<double> get animation => _controller.view;

  final Map<T, int> _valueToIndex = new Map<T, int>();

  @override
  void initState() {
    super.initState();

    _controller = new AnimationController(
      duration: _kTabBarScroll,
      value: 1.0,
      vsync: this,
    );

    _value = config.value ?? PageStorage.of(context)?.readState(context) ?? values.first;

    // If the selection's values have changed since the selected value was saved with
    // PageStorage.writeState() then use the default.
    if (!values.contains(_value))
      _value = values.first;

    _previousValue = _value;
    _initValueToIndex();
  }

  @override
  void didUpdateConfig(TabBarSelection<T> oldConfig) {
    super.didUpdateConfig(oldConfig);
    if (values != oldConfig.values)
      _initValueToIndex();
  }

  void _initValueToIndex() {
    _valueToIndex.clear();
    int index = 0;
    for (T value in values)
      _valueToIndex[value] = index++;
  }

  void _writeValue() {
    PageStorage.of(context)?.writeState(context, _value);
  }

  /// The list of possible values that the selection can obtain.
  List<T> get values => config.values;

  /// The previously selected value.
  ///
  /// When the tab selection changes, the tab selection animates from the
  /// previously selected value to the new value.
  T get previousValue => _previousValue;
  T _previousValue;

  /// Whether the tab selection is in the process of animating from one value to
  /// another.
  // TODO(abarth): Try computing this value from _controller.state so we don't
  // need to keep a separate bool in sync.
  bool get valueIsChanging => _valueIsChanging;
  bool _valueIsChanging = false;

  /// The index of a given value in [values].
  ///
  /// Runs in constant time.
  int indexOf(T tabValue) => _valueToIndex[tabValue];

  /// The index of the currently selected value.
  int get index => _valueToIndex[value];

  /// The index of the previoulsy selected value.
  int get previousIndex => indexOf(_previousValue);

  /// The currently selected value.
  ///
  /// Writing to this field will cause the tab selection to animate from the
  /// previous value to the new value.
  T get value => _value;
  T _value;
  set value(T newValue) {
    if (newValue == _value)
      return;
    _previousValue = _value;
    _value = newValue;
    _writeValue();
    _valueIsChanging = true;

    // If the selected value change was triggered by a drag gesture, the current
    // value of _controller.value will reflect where the gesture ended. While
    // the drag was underway the controller's value indicates where the indicator
    // and TabBarView scrollPositions are vis the indices of the two tabs adjacent
    // to the selected one. So 0.5 means the drag didn't move at all, 0.0 means the
    // drag extended to the beginning of the tab on the left and 1.0 likewise for
    // the tab on the right. That is unless the index of the selected value was 0
    // or values.length - 1. In those cases the controller's value just moves between
    // the selected tab and the adjacent one. So: convert the controller's value
    // here to reflect the fact that we're now moving between (just) the previous
    // and current selection index.

    double value;
    if (_controller.status == AnimationStatus.completed)
      value = 0.0;
    else if (_previousValue == values.first)
      value = _controller.value;
    else if (_previousValue == values.last)
      value = 1.0 - _controller.value;
    else if (previousIndex < index)
      value = (_controller.value - 0.5) * 2.0;
    else
      value = 1.0 - _controller.value * 2.0;

    _controller
      ..value = value
      ..forward().then((_) {
        // TODO(abarth): Consider using a status listener and checking for
        // AnimationStatus.completed.
        if (_controller.value == 1.0) {
          if (config.onChanged != null)
            config.onChanged(_value);
          _valueIsChanging = false;
        }
      });
  }

  final List<TabBarSelectionAnimationListener> _animationListeners = <TabBarSelectionAnimationListener>[];

  /// Calls listener methods every time the value or status of the selection animation changes.
  ///
  /// Listeners can be removed with [removeAnimationListener].
  void addAnimationListener(TabBarSelectionAnimationListener listener) {
    _animationListeners.add(listener);
    _controller
      ..addStatusListener(listener.handleStatusChange)
      ..addListener(listener.handleProgressChange);
  }

  /// Stop calling listener methods every time the value or status of the animation changes.
  ///
  /// Listeners can be added with [addAnimationListener].
  void removeAnimationListener(TabBarSelectionAnimationListener listener) {
    _animationListeners.remove(listener);
    _controller
      ..removeStatusListener(listener.handleStatusChange)
      ..removeListener(listener.handleProgressChange);
  }

  @override
  void deactivate() {
    _controller.stop();
    for (TabBarSelectionAnimationListener listener in _animationListeners.toList()) {
      listener.handleSelectionDeactivate();
      removeAnimationListener(listener);
    }
    assert(_animationListeners.isEmpty);
    _writeValue();
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    return config.child;
  }
}

// Used when the user is dragging the TabBar or the TabBarView left or right.
// Dragging from the selected tab to the left varies t between 0.5 and 0.0.
// Dragging towards the tab on the right varies t between 0.5 and 1.0.
class _TabIndicatorTween extends Tween<Rect> {
  _TabIndicatorTween({ Rect begin, this.middle, Rect end }) : super(begin: begin, end: end);

  final Rect middle;

  @override
  Rect lerp(double t) {
    return t <= 0.5
      ? Rect.lerp(begin, middle, t * 2.0)
      : Rect.lerp(middle, end, (t - 0.5) * 2.0);
    }
}

/// A widget that displays a horizontal row of tabs, one per label.
///
/// Requires one of its ancestors to be a [TabBarSelection] widget to enable
/// saving and monitoring the selected tab.
///
/// Requires one of its ancestors to be a [Material] widget.
///
/// See also:
///
///  * [TabBarSelection]
///  * [TabBarView]
///  * [AppBar.tabBar]
///  * <https://www.google.com/design/spec/components/tabs.html>
class TabBar<T> extends Scrollable implements AppBarBottomWidget {
  /// Creates a widget that displays a horizontal row of tabs, one per label.
  ///
  /// The [labels] argument must not be null.
  TabBar({
    Key key,
    @required this.labels,
    this.isScrollable: false,
    this.indicatorColor,
    this.labelColor
  }) : super(key: key, scrollDirection: Axis.horizontal) {
    assert(labels != null);
  }

  /// The labels to display in the tabs.
  ///
  /// The [TabBarSelection.values] are used as keys for this map to determine
  /// which tab label is selected.
  final Map<T, TabLabel> labels;

  /// Whether this tab bar can be scrolled horizontally.
  ///
  /// If [isScrollable] is true then each tab is as wide as needed for its label
  /// and the entire [TabBar] is scrollable. Otherwise each tab gets an equal
  /// share of the available space.
  final bool isScrollable;

  /// The color of the line that appears below the selected tab. If this parameter
  /// is null then the value of the Theme's indicatorColor property is used.
  final Color indicatorColor;

  /// The color of selected tab labels. Unselected tab labels are rendered
  /// with the same color rendered at 70% opacity. If this parameter is null then
  /// the color of the theme's body2 text color is used.
  final Color labelColor;

  /// The height of the tab labels and indicator.
  @override
  double get bottomHeight {
    for (TabLabel label in labels.values) {
      if (label.hasText && label.hasIcon)
        return _kTextAndIconTabHeight + _kTabIndicatorHeight;
    }
    return _kTabHeight + _kTabIndicatorHeight;
  }

  @override
  _TabBarState<T> createState() => new _TabBarState<T>();
}

class _TabBarState<T> extends ScrollableState<TabBar<T>> implements TabBarSelectionAnimationListener {
  TabBarSelectionState<T> _selection;
  bool _valueIsChanging = false;
  int _lastSelectedIndex = -1;

  void _initSelection(TabBarSelectionState<T> newSelection) {
    if (_selection == newSelection)
      return;
    _selection?.removeAnimationListener(this);
    _selection = newSelection;
    _selection?.addAnimationListener(this);
    if (_selection != null)
      _lastSelectedIndex = _selection.index;
  }

  @override
  void didUpdateConfig(TabBar<T> oldConfig) {
    super.didUpdateConfig(oldConfig);
    if (config.isScrollable != oldConfig.isScrollable) {
      scrollBehavior.isScrollable = config.isScrollable;
      if (!config.isScrollable)
        scrollTo(0.0);
    }
  }

  @override
  void dispose() {
    _selection?.removeAnimationListener(this);
    super.dispose();
  }

  @override
  void handleSelectionDeactivate() {
    _selection = null;
  }

  // Initialize _indicatorTween for interactive dragging between the tab on the left
  // and the tab on the right. In this case _selection.animation.value is 0.5 when
  // the indicator is below the selected tab, 0.0 when it's under the left tab, and 1.0
  // when it's under the tab on the right.
  void _initIndicatorTweenForDrag() {
    assert(!_valueIsChanging);
    int index = _selection.index;
    int beginIndex = math.max(0, index - 1);
    int endIndex = math.min(config.labels.length - 1, index + 1);
    if (beginIndex == index || endIndex == index) {
      _indicatorTween = new RectTween(
        begin: _tabIndicatorRect(beginIndex),
        end: _tabIndicatorRect(endIndex)
      );
    } else {
      _indicatorTween = new _TabIndicatorTween(
        begin: _tabIndicatorRect(beginIndex),
        middle: _tabIndicatorRect(index),
        end: _tabIndicatorRect(endIndex)
      );
    }
  }

  // Initialize _indicatorTween for animating the selected tab indicator from the
  // previously selected tab to the newly selected one. In this case
  // _selection.animation.value is 0.0 when the indicator is below the previously
  // selected tab, and 1.0 when it's under the newly selected one.
  void _initIndicatorTweenForAnimation() {
    assert(_valueIsChanging);
    _indicatorTween = new RectTween(
      begin: _indicatorRect ?? _tabIndicatorRect(_selection.previousIndex),
      end: _tabIndicatorRect(_selection.index)
    );
  }

  @override
  void handleStatusChange(AnimationStatus status) {
    if (config.labels.length == 0)
      return;

    if (_valueIsChanging && status == AnimationStatus.completed) {
      _valueIsChanging = false;
      setState(() {
        _initIndicatorTweenForDrag();
        _indicatorRect = _tabIndicatorRect(_selection.index);
      });
    }
  }

  @override
  void handleProgressChange() {
    if (config.labels.length == 0 || _selection == null)
      return;

    if (_lastSelectedIndex != _selection.index) {
      _valueIsChanging = true;
      if (config.isScrollable)
        scrollTo(_centeredTabScrollOffset(_selection.index), duration: _kTabBarScroll);
      _initIndicatorTweenForAnimation();
      _lastSelectedIndex = _selection.index;
    } else if (_indicatorTween == null) {
      _initIndicatorTweenForDrag();
    }

    Rect oldRect = _indicatorRect;
    double t = _selection.animation.value;

    // When _valueIsChanging is false, we're animating based on drag gesture and
    // want linear selected tab indicator motion. When _valueIsChanging is true,
    // a ticker is driving the selection change and we want to curve the animation.
    // In this case the leading and trailing edges of the move at different rates.
    // The easiest way to do this is to lerp 2 rects, and piece them together into 1.
    if (!_valueIsChanging) {
      _indicatorRect = _indicatorTween.lerp(t);
    } else {
      Rect leftRect, rightRect;
      if (_selection.index > _selection.previousIndex) {
        // Moving to the right - right edge is leading.
        rightRect = _indicatorTween.lerp(_kTabIndicatorLeadingCurve.transform(t));
        leftRect = _indicatorTween.lerp(_kTabIndicatorTrailingCurve.transform(t));
      } else {
        // Moving to the left - left edge is leading.
        leftRect = _indicatorTween.lerp(_kTabIndicatorLeadingCurve.transform(t));
        rightRect = _indicatorTween.lerp(_kTabIndicatorTrailingCurve.transform(t));
      }
      _indicatorRect = new Rect.fromLTRB(
        leftRect.left, leftRect.top, rightRect.right, rightRect.bottom
      );
    }
    if (oldRect != _indicatorRect)
      setState(() { /* The indicator rect has changed. */ });
  }

  Size _viewportSize = Size.zero;
  Size _tabBarSize;
  List<double> _tabWidths;
  Rect _indicatorRect;
  Tween<Rect> _indicatorTween;

  Rect _tabRect(int tabIndex) {
    assert(_tabBarSize != null);
    assert(_tabWidths != null);
    assert(tabIndex >= 0 && tabIndex < _tabWidths.length);
    double tabLeft = 0.0;
    if (tabIndex > 0)
      tabLeft = _tabWidths.take(tabIndex).reduce((double sum, double width) => sum + width);
    final double tabTop = 0.0;
    final double tabBottom = _tabBarSize.height - _kTabIndicatorHeight;
    final double tabRight = tabLeft + _tabWidths[tabIndex];
    return new Rect.fromLTRB(tabLeft, tabTop, tabRight, tabBottom);
  }

  Rect _tabIndicatorRect(int tabIndex) {
    Rect r = _tabRect(tabIndex);
    return new Rect.fromLTRB(r.left, r.bottom, r.right, r.bottom + _kTabIndicatorHeight);
  }

  @override
  ExtentScrollBehavior createScrollBehavior() {
    return new _TabsScrollBehavior()
      ..isScrollable = config.isScrollable;
  }

  @override
  _TabsScrollBehavior get scrollBehavior => super.scrollBehavior;

  double _centeredTabScrollOffset(int tabIndex) {
    double viewportWidth = scrollBehavior.containerExtent;
    Rect tabRect = _tabRect(tabIndex);
    return (tabRect.left + tabRect.width / 2.0 - viewportWidth / 2.0)
      .clamp(scrollBehavior.minScrollOffset, scrollBehavior.maxScrollOffset);
  }

  void _handleTabSelected(int tabIndex) {
    if (_selection != null && tabIndex != _selection.index)
      setState(() {
        _selection.value = _selection.values[tabIndex];
      });
  }

  Widget _toTab(TabLabel label, int tabIndex, Color color, Color selectedColor) {
    Color labelColor = color;
    if (_selection != null) {
      final bool isSelectedTab = tabIndex == _selection.index;
      final bool isPreviouslySelectedTab = tabIndex == _selection.previousIndex;
      labelColor = isSelectedTab ? selectedColor : color;
      if (_selection.valueIsChanging) {
        if (isSelectedTab)
          labelColor = Color.lerp(color, selectedColor, _selection.animation.value);
        else if (isPreviouslySelectedTab)
          labelColor = Color.lerp(selectedColor, color, _selection.animation.value);
      }
    }
    return new _Tab(
      onSelected: () { _handleTabSelected(tabIndex); },
      label: label,
      color: labelColor
    );
  }

  void _updateScrollBehavior() {
    didUpdateScrollBehavior(scrollBehavior.updateExtents(
      containerExtent: config.scrollDirection == Axis.vertical ? _viewportSize.height : _viewportSize.width,
      contentExtent: _tabWidths.reduce((double sum, double width) => sum + width),
      scrollOffset: scrollOffset
    ));
  }

  void _layoutChanged(Size tabBarSize, List<double> tabWidths) {
    // This is bad. We should use a LayoutBuilder or CustomMultiChildLayout or some such.
    // As designed today, tabs are always lagging one frame behind, taking two frames
    // to handle a layout change.
    _tabBarSize = tabBarSize;
    _tabWidths = tabWidths;
    _indicatorRect = _selection != null ? _tabIndicatorRect(_selection.index) : Rect.zero;
    _updateScrollBehavior();
    SchedulerBinding.instance.addPostFrameCallback((Duration timeStamp) {
      if (mounted) {
        setState(() {
          // the changes were made at layout time
          // TODO(ianh): remove this setState: https://github.com/flutter/flutter/issues/5749
        });
      }
    });
  }

  Offset _handlePaintOffsetUpdateNeeded(ViewportDimensions dimensions) {
    // We make various state changes here but don't have to do so in a
    // setState() callback because we are called during layout and all
    // we're updating is the new offset, which we are providing to the
    // render object via our return value.
    _viewportSize = dimensions.containerSize;
    _updateScrollBehavior();
    if (config.isScrollable && _selection != null)
      scrollTo(_centeredTabScrollOffset(_selection.index), duration: _kTabBarScroll);
    return scrollOffsetToPixelDelta(scrollOffset);
  }

  @override
  Widget buildContent(BuildContext context) {
    TabBarSelectionState<T> newSelection = TabBarSelection.of(context);
    _initSelection(newSelection);

    assert(config.labels.isNotEmpty);
    assert(Material.of(context) != null);

    ThemeData themeData = Theme.of(context);
    Color backgroundColor = Material.of(context).color;
    Color indicatorColor = config.indicatorColor ?? themeData.indicatorColor;
    if (indicatorColor == backgroundColor) {
      // ThemeData tries to avoid this by having indicatorColor avoid being the
      // primaryColor. However, it's possible that the tab bar is on a
      // Material that isn't the primaryColor. In that case, if the indicator
      // color ends up clashing, then this overrides it. When that happens,
      // automatic transitions of the theme will likely look ugly as the
      // indicator color suddenly snaps to white at one end, but it's not clear
      // how to avoid that any further.
      indicatorColor = Colors.white;
    }

    final TextStyle textStyle = themeData.primaryTextTheme.body2;
    final Color selectedLabelColor = config.labelColor ?? themeData.primaryTextTheme.body2.color;
    final Color labelColor = selectedLabelColor.withAlpha(0xB2); // 70% alpha

    List<Widget> tabs = <Widget>[];
    bool textAndIcons = false;
    int tabIndex = 0;
    for (TabLabel label in config.labels.values) {
      tabs.add(_toTab(label, tabIndex++, labelColor, selectedLabelColor));
      if (label.hasText && label.hasIcon)
        textAndIcons = true;
    }

    Widget contents = new DefaultTextStyle(
      style: textStyle,
      child: new _TabBarWrapper(
        children: tabs,
        selectedIndex: _selection?.index,
        indicatorColor: indicatorColor,
        indicatorRect: _indicatorRect,
        textAndIcons: textAndIcons,
        isScrollable: config.isScrollable,
        onLayoutChanged: _layoutChanged
      )
    );

    if (config.isScrollable) {
      return new Viewport(
        mainAxis: Axis.horizontal,
        paintOffset: scrollOffsetToPixelDelta(scrollOffset),
        onPaintOffsetUpdateNeeded: _handlePaintOffsetUpdateNeeded,
        child: contents
      );
    }

    return contents;
  }
}

/// A widget that displays the contents of a tab.
///
/// Requires one of its ancestors to be a [TabBarSelection] widget to enable
/// saving and monitoring the selected tab.
///
/// See also:
///
///  * [TabBarSelection]
///  * [TabBar]
///  * <https://www.google.com/design/spec/components/tabs.html>
class TabBarView<T> extends PageableList {
  /// Creates a widget that displays the contents of a tab.
  ///
  /// The [children] argument must not be null and must not be empty.
  TabBarView({
    Key key,
    @required List<Widget> children
  }) : super(
    key: key,
    scrollDirection: Axis.horizontal,
    children: children
  ) {
    assert(children != null);
    assert(children.length > 1);
  }

  @override
  _TabBarViewState<T> createState() => new _TabBarViewState<T>();
}

class _TabBarViewState<T> extends PageableListState<TabBarView<T>> implements TabBarSelectionAnimationListener {

  TabBarSelectionState<T> _selection;
  List<Widget> _items;

  int get _tabCount => config.children.length;

  BoundedBehavior _boundedBehavior;

  @override
  ExtentScrollBehavior get scrollBehavior {
    _boundedBehavior ??= new BoundedBehavior(platform: platform);
    return _boundedBehavior;
  }

  @override
  TargetPlatform get platform => Theme.of(context).platform;

  void _initSelection(TabBarSelectionState<T> newSelection) {
    if (_selection == newSelection)
      return;
    _selection?.removeAnimationListener(this);
    _selection = newSelection;
    _selection?.addAnimationListener(this);
    if (_selection != null)
      _updateItemsAndScrollBehavior();
  }

  @override
  void didUpdateConfig(TabBarView<T> oldConfig) {
    super.didUpdateConfig(oldConfig);
    if (_selection != null && config.children != oldConfig.children)
      _updateItemsForSelectedIndex(_selection.index);
  }

  @override
  void dispose() {
    _selection?.removeAnimationListener(this);
    super.dispose();
  }

  @override
  void handleSelectionDeactivate() {
    _selection = null;
  }

  void _updateItemsFromChildren(int first, int second, [int third]) {
    List<Widget> widgets = config.children;
    _items = <Widget>[
      new KeyedSubtree.wrap(widgets[first], first),
      new KeyedSubtree.wrap(widgets[second], second),
    ];
    if (third != null)
      _items.add(new KeyedSubtree.wrap(widgets[third], third));
  }

  void _updateItemsForSelectedIndex(int selectedIndex) {
    if (selectedIndex == 0) {
      _updateItemsFromChildren(0, 1);
    } else if (selectedIndex == _tabCount - 1) {
      _updateItemsFromChildren(selectedIndex - 1, selectedIndex);
    } else {
      _updateItemsFromChildren(selectedIndex - 1, selectedIndex, selectedIndex + 1);
    }
  }

  void _updateScrollBehaviorForSelectedIndex(int selectedIndex) {
    if (selectedIndex == 0) {
      didUpdateScrollBehavior(scrollBehavior.updateExtents(contentExtent: 2.0, containerExtent: 1.0, scrollOffset: 0.0));
    } else if (selectedIndex == _tabCount - 1) {
      didUpdateScrollBehavior(scrollBehavior.updateExtents(contentExtent: 2.0, containerExtent: 1.0, scrollOffset: 1.0));
    } else {
      didUpdateScrollBehavior(scrollBehavior.updateExtents(contentExtent: 3.0, containerExtent: 1.0, scrollOffset: 1.0));
    }
  }

  void _updateItemsAndScrollBehavior() {
    assert(_selection != null);
    final int selectedIndex = _selection.index;
    assert(selectedIndex != null);
    _updateItemsForSelectedIndex(selectedIndex);
    _updateScrollBehaviorForSelectedIndex(selectedIndex);
  }

  @override
  void handleStatusChange(AnimationStatus status) {
  }

  @override
  void handleProgressChange() {
    if (_selection == null || !_selection.valueIsChanging)
      return;
    // The TabBar is driving the TabBarSelection animation.

    final Animation<double> animation = _selection.animation;

    if (animation.status == AnimationStatus.completed) {
      _updateItemsAndScrollBehavior();
      return;
    }

    if (animation.status != AnimationStatus.forward)
      return;

    final int selectedIndex = _selection.index;
    final int previousSelectedIndex = _selection.previousIndex;

    if (selectedIndex < previousSelectedIndex) {
      _updateItemsFromChildren(selectedIndex, previousSelectedIndex);
      scrollTo(new CurveTween(curve: Curves.fastOutSlowIn.flipped).evaluate(new ReverseAnimation(animation)));
    } else {
      _updateItemsFromChildren(previousSelectedIndex, selectedIndex);
      scrollTo(new CurveTween(curve: Curves.fastOutSlowIn).evaluate(animation));
    }
  }

  @override
  void dispatchOnScroll() {
    if (_selection == null || _selection.valueIsChanging)
      return;
    // This class is driving the TabBarSelection's animation.

    final AnimationController controller = _selection._controller;

    if (_selection.index == 0 || _selection.index == _tabCount - 1)
      controller.value = scrollOffset;
    else
      controller.value = scrollOffset / 2.0;
  }

  @override
  Future<Null> fling(double scrollVelocity) {
    if (_selection == null || _selection.valueIsChanging)
      return new Future<Null>.value();

    if (scrollVelocity.abs() > _kMinFlingVelocity) {
      final int selectionDelta = scrollVelocity.sign.truncate();
      final int targetIndex = (_selection.index + selectionDelta).clamp(0, _tabCount - 1);
      if (_selection.index != targetIndex) {
        _selection.value = _selection.values[targetIndex];
        return new Future<Null>.value();
      }
    }

    final int selectionIndex = _selection.index;
    final int settleIndex = snapScrollOffset(scrollOffset).toInt();
    if (selectionIndex > 0 && settleIndex != 1) {
      final int targetIndex = (selectionIndex + (settleIndex == 2 ? 1 : -1)).clamp(0, _tabCount - 1);
      _selection.value = _selection.values[targetIndex];
      return new Future<Null>.value();
    } else if (selectionIndex == 0 && settleIndex == 1) {
      _selection.value = _selection.values[1];
      return new Future<Null>.value();
    }
    return settleScrollOffset();
  }

  @override
  Widget buildContent(BuildContext context) {
    TabBarSelectionState<T> newSelection = TabBarSelection.of(context);
    _initSelection(newSelection);
    return new PageViewport(
      itemsWrap: config.itemsWrap,
      mainAxis: config.scrollDirection,
      startOffset: scrollOffset,
      children: _items
    );
  }
}

/// A widget that displays a visual indicator of which tab is selected.
///
/// Requires one of its ancestors to be a [TabBarSelection] widget to enable
/// saving and monitoring the selected tab.
///
/// See also:
///
///  * [TabBarSelection]
///  * [TabBarView]
class TabPageSelector<T> extends StatelessWidget {
  /// Creates a widget that displays a visual indicator of which tab is selected.
  ///
  /// Requires one of its ancestors to be a [TabBarSelection] widget to enable
  /// saving and monitoring the selected tab.
  const TabPageSelector({ Key key }) : super(key: key);

  Widget _buildTabIndicator(TabBarSelectionState<T> selection, T tab, Animation<double> animation, ColorTween selectedColor, ColorTween previousColor) {
    Color background;
    if (selection.valueIsChanging) {
      // The selection's animation is animating from previousValue to value.
      if (selection.value == tab)
        background = selectedColor.evaluate(animation);
      else if (selection.previousValue == tab)
        background = previousColor.evaluate(animation);
      else
        background = selectedColor.begin;
    } else {
      background = selection.value == tab ? selectedColor.end : selectedColor.begin;
    }
    return new Container(
      width: 12.0,
      height: 12.0,
      margin: new EdgeInsets.all(4.0),
      decoration: new BoxDecoration(
        backgroundColor: background,
        border: new Border.all(color: selectedColor.end),
        shape: BoxShape.circle
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final TabBarSelectionState<T> selection = TabBarSelection.of(context);
    final Color color = Theme.of(context).accentColor;
    final ColorTween selectedColor = new ColorTween(begin: Colors.transparent, end: color);
    final ColorTween previousColor = new ColorTween(begin: color, end: Colors.transparent);
    Animation<double> animation = new CurvedAnimation(parent: selection.animation, curve: Curves.fastOutSlowIn);
    return new AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget child) {
        return new Semantics(
          label: 'Page ${selection.index + 1} of ${selection.values.length}',
          child: new Row(
            children: selection.values.map((T tab) => _buildTabIndicator(selection, tab, animation, selectedColor, previousColor)).toList(),
            mainAxisSize: MainAxisSize.min
          )
        );
      }
    );
  }
}
