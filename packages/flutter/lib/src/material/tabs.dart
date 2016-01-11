// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:newton/newton.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'icon.dart';
import 'icon_theme.dart';
import 'icon_theme_data.dart';
import 'ink_well.dart';
import 'material.dart';
import 'theme.dart';

typedef void TabSelectedIndexChanged(int selectedIndex);
typedef void TabLayoutChanged(Size size, List<double> widths);

// See https://www.google.com/design/spec/components/tabs.html#tabs-specs
const double _kTabHeight = 46.0;
const double _kTextAndIconTabHeight = 72.0;
const double _kTabIndicatorHeight = 2.0;
const double _kMinTabWidth = 72.0;
const double _kMaxTabWidth = 264.0;
const EdgeDims _kTabLabelPadding = const EdgeDims.symmetric(horizontal: 12.0);
const double _kTabBarScrollDrag = 0.025;
const Duration _kTabBarScroll = const Duration(milliseconds: 300);

// The scrollOffset (velocity) provided to fling() is pixels/ms, and the
// tolerance velocity is pixels/sec.
final double _kMinFlingVelocity = kPixelScrollTolerance.velocity / 2000.0;

class _TabBarParentData extends ContainerBoxParentDataMixin<RenderBox> { }

class _RenderTabBar extends RenderBox with
    ContainerRenderObjectMixin<RenderBox, _TabBarParentData>,
    RenderBoxContainerDefaultsMixin<RenderBox, _TabBarParentData> {

  _RenderTabBar(this.onLayoutChanged);

  int _selectedIndex;
  int get selectedIndex => _selectedIndex;
  void set selectedIndex(int value) {
    if (_selectedIndex != value) {
      _selectedIndex = value;
      markNeedsPaint();
    }
  }

  Color _indicatorColor;
  Color get indicatorColor => _indicatorColor;
  void set indicatorColor(Color value) {
    if (_indicatorColor != value) {
      _indicatorColor = value;
      markNeedsPaint();
    }
  }

  Rect _indicatorRect;
  Rect get indicatorRect => _indicatorRect;
  void set indicatorRect(Rect value) {
    if (_indicatorRect != value) {
      _indicatorRect = value;
      markNeedsPaint();
    }
  }

  bool _textAndIcons;
  bool get textAndIcons => _textAndIcons;
  void set textAndIcons(bool value) {
    if (_textAndIcons != value) {
      _textAndIcons = value;
      markNeedsLayout();
    }
  }

  bool _isScrollable;
  bool get isScrollable => _isScrollable;
  void set isScrollable(bool value) {
    if (_isScrollable != value) {
      _isScrollable = value;
      markNeedsLayout();
    }
  }

  void setupParentData(RenderBox child) {
    if (child.parentData is! _TabBarParentData)
      child.parentData = new _TabBarParentData();
  }

  double getMinIntrinsicWidth(BoxConstraints constraints) {
    BoxConstraints widthConstraints =
        new BoxConstraints(maxWidth: constraints.maxWidth, maxHeight: constraints.maxHeight);

    double maxWidth = 0.0;
    RenderBox child = firstChild;
    while (child != null) {
      maxWidth = math.max(maxWidth, child.getMinIntrinsicWidth(widthConstraints));
      final _TabBarParentData childParentData = child.parentData;
      child = childParentData.nextSibling;
    }
    double width = isScrollable ? maxWidth : maxWidth * childCount;
    return constraints.constrainWidth(width);
  }

  double getMaxIntrinsicWidth(BoxConstraints constraints) {
    BoxConstraints widthConstraints =
        new BoxConstraints(maxWidth: constraints.maxWidth, maxHeight: constraints.maxHeight);

    double maxWidth = 0.0;
    RenderBox child = firstChild;
    while (child != null) {
      maxWidth = math.max(maxWidth, child.getMaxIntrinsicWidth(widthConstraints));
      final _TabBarParentData childParentData = child.parentData;
      child = childParentData.nextSibling;
    }
    double width = isScrollable ? maxWidth : maxWidth * childCount;
    return constraints.constrainWidth(width);
  }

  double get _tabHeight => textAndIcons ? _kTextAndIconTabHeight : _kTabHeight;
  double get _tabBarHeight => _tabHeight + _kTabIndicatorHeight;

  double _getIntrinsicHeight(BoxConstraints constraints) => constraints.constrainHeight(_tabBarHeight);

  double getMinIntrinsicHeight(BoxConstraints constraints) => _getIntrinsicHeight(constraints);

  double getMaxIntrinsicHeight(BoxConstraints constraints) => _getIntrinsicHeight(constraints);

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
  TabLayoutChanged onLayoutChanged;

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
  final TabLayoutChanged onLayoutChanged;

  _RenderTabBar createRenderObject() {
    _RenderTabBar result = new _RenderTabBar(onLayoutChanged);
    updateRenderObject(result, null);
    return result;
  }

  void updateRenderObject(_RenderTabBar renderObject, _TabBarWrapper oldWidget) {
    renderObject.selectedIndex = selectedIndex;
    renderObject.indicatorColor = indicatorColor;
    renderObject.indicatorRect = indicatorRect;
    renderObject.textAndIcons = textAndIcons;
    renderObject.isScrollable = isScrollable;
    renderObject.onLayoutChanged = onLayoutChanged;
  }
}

class TabLabel {
  const TabLabel({ this.text, this.icon });

  final String text;
  final String icon;

  String toString() {
    if (text != null && icon != null)
      return '"$text" ($icon)';
    if (text != null)
      return '"$text"';
    if (icon != null)
      return '$icon';
    return 'EMPTY TAB LABEL';
  }
}

class _Tab extends StatelessComponent {
  _Tab({
    Key key,
    this.onSelected,
    this.label,
    this.color
  }) : super(key: key) {
    assert(label.text != null || label.icon != null);
  }

  final VoidCallback onSelected;
  final TabLabel label;
  final Color color;

  Widget _buildLabelText() {
    assert(label.text != null);
    TextStyle style = new TextStyle(color: color);
    return new Text(label.text, style: style);
  }

  Widget _buildLabelIcon() {
    assert(label.icon != null);
    ColorFilter filter = new ColorFilter.mode(color, TransferMode.srcATop);
    return new Icon(icon: label.icon, colorFilter: filter);
  }

  Widget build(BuildContext context) {
    Widget labelContent;
    if (label.icon == null) {
      labelContent = _buildLabelText();
    } else if (label.text == null) {
      labelContent = _buildLabelIcon();
    } else {
      labelContent = new Column(
        <Widget>[
          new Container(
            child: _buildLabelIcon(),
            margin: const EdgeDims.only(bottom: 10.0)
          ),
          _buildLabelText()
        ],
        justifyContent: FlexJustifyContent.center,
        alignItems: FlexAlignItems.center
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

  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('$label');
  }
}

class _TabsScrollBehavior extends BoundedBehavior {
  _TabsScrollBehavior();

  bool isScrollable = true;

  Simulation createFlingScrollSimulation(double position, double velocity) {
    if (!isScrollable)
      return null;

    double velocityPerSecond = velocity * 1000.0;
    return new BoundedFrictionSimulation(
      _kTabBarScrollDrag, position, velocityPerSecond, minScrollOffset, maxScrollOffset
    );
  }

  double applyCurve(double scrollOffset, double scrollDelta) {
    return (isScrollable) ? super.applyCurve(scrollOffset, scrollDelta) : 0.0;
  }
}

abstract class TabBarSelectionPerformanceListener {
  void handleStatusChange(PerformanceStatus status);
  void handleProgressChange();
  void handleSelectionDeactivate();
}

class TabBarSelection<T> extends StatefulComponent {
  TabBarSelection({
    Key key,
    this.value,
    this.values,
    this.onChanged,
    this.child
  }) : super(key: key)  {
    assert(values != null && values.length > 0);
    assert(new Set<T>.from(values).length == values.length);
    assert(value == null ? true : values.where((T e) => e == value).length == 1);
    assert(child != null);
  }

  final T value;
  List<T> values;
  final ValueChanged<T> onChanged;
  final Widget child;

  TabBarSelectionState createState() => new TabBarSelectionState<T>();

  static TabBarSelectionState of(BuildContext context) {
    return context.ancestorStateOfType(const TypeMatcher<TabBarSelectionState>());
  }
}

class TabBarSelectionState<T> extends State<TabBarSelection<T>> {

  PerformanceView get performance => _performance.view;
  // Both the TabBar and TabBarView classes access _performance because they
  // alternately drive selection progress between tabs.
  final _performance = new Performance(duration: _kTabBarScroll, progress: 1.0);
  final Map<T, int> _valueToIndex = new Map<T, int>();

  void _initValueToIndex() {
    _valueToIndex.clear();
    int index = 0;
    for(T value in values)
      _valueToIndex[value] = index++;
  }

  void initState() {
    super.initState();
    _value = config.value ?? PageStorage.of(context)?.readState(context) ?? values.first;
    _previousValue = _value;
    _initValueToIndex();
  }

  void didUpdateConfig(TabBarSelection oldConfig) {
    super.didUpdateConfig(oldConfig);
    if (values != oldConfig.values)
      _initValueToIndex();
  }

  void dispose() {
    _performance.stop();
    PageStorage.of(context)?.writeState(context, _value);
    super.dispose();
  }

  List<T> get values => config.values;

  T get previousValue => _previousValue;
  T _previousValue;

  bool _valueIsChanging = false;
  bool get valueIsChanging => _valueIsChanging;

  int indexOf(T tabValue) => _valueToIndex[tabValue];
  int get index => _valueToIndex[value];
  int get previousIndex => indexOf(_previousValue);

  T get value => _value;
  T _value;
  void set value(T newValue) {
    if (newValue == _value)
      return;
    if (!_valueIsChanging)
      _previousValue = _value;
    _value = newValue;
    _valueIsChanging = true;

    // If the selected value change was triggered by a drag gesture, the current
    // value of _performance.progress will reflect where the gesture ended. While
    // the drag was underway progress indicates where the indicator and TabBarView
    // scrollPosition are vis the indices of the two tabs adjacent to the selected
    // one. So 0.5 means the drag didn't move at all, 0.0 means the drag extended
    // to the beginning of the tab on the left and 1.0 likewise for the tab on the
    // right. That is unless the index of the selected value was 0 or values.length - 1.
    // In those cases progress just moves between the selected tab and the adjacent
    // one. Convert progress to reflect the fact that we're now moving between (just)
    // the previous and current selection index.

    double progress;
    if (_performance.status == PerformanceStatus.completed)
      progress = 0.0;
    else if (_previousValue == values.first)
      progress = _performance.progress;
    else if (_previousValue == values.last)
      progress = 1.0 - _performance.progress;
    else if (previousIndex < index)
      progress = (_performance.progress - 0.5) * 2.0;
    else
      progress = 1.0 - _performance.progress * 2.0;

    _performance
      ..progress = progress
      ..forward().then((_) {
        if (_performance.progress == 1.0) {
          if (config.onChanged != null)
            config.onChanged(_value);
          _valueIsChanging = false;
        }
      });
  }

  final List<TabBarSelectionPerformanceListener> _performanceListeners = <TabBarSelectionPerformanceListener>[];

  void registerPerformanceListener(TabBarSelectionPerformanceListener listener) {
    _performanceListeners.add(listener);
    _performance
      ..addStatusListener(listener.handleStatusChange)
      ..addListener(listener.handleProgressChange);
  }

  void unregisterPerformanceListener(TabBarSelectionPerformanceListener listener) {
    _performanceListeners.remove(listener);
    _performance
      ..removeStatusListener(listener.handleStatusChange)
      ..removeListener(listener.handleProgressChange);
  }

  void deactivate() {
    for (TabBarSelectionPerformanceListener listener in _performanceListeners.toList()) {
      listener.handleSelectionDeactivate();
      unregisterPerformanceListener(listener);
    }
    assert(_performanceListeners.isEmpty);
  }

  Widget build(BuildContext context) {
    return config.child;
  }
}

/// Displays a horizontal row of tabs, one per label. If isScrollable is
/// true then each tab is as wide as needed for its label and the entire
/// [TabBar] is scrollable. Otherwise each tab gets an equal share of the
/// available space. A [TabBarSelection] widget ancestor must have been
/// built to enable saving and monitoring the selected tab.
///
/// Tabs must always have an ancestor Material object.
class TabBar<T> extends Scrollable {
  TabBar({
    Key key,
    this.labels,
    this.isScrollable: false
  }) : super(key: key, scrollDirection: Axis.horizontal);

  final Map<T, TabLabel> labels;
  final bool isScrollable;

  _TabBarState createState() => new _TabBarState();
}

class _TabBarState<T> extends ScrollableState<TabBar<T>> implements TabBarSelectionPerformanceListener {

  TabBarSelectionState _selection;
  bool _valueIsChanging = false;

  void _initSelection(TabBarSelectionState<T> selection) {
    _selection?.unregisterPerformanceListener(this);
    _selection = selection;
    _selection?.registerPerformanceListener(this);
  }

  void initState() {
    super.initState();
    scrollBehavior.isScrollable = config.isScrollable;
    _initSelection(TabBarSelection.of(context));
  }

  void didUpdateConfig(TabBar oldConfig) {
    super.didUpdateConfig(oldConfig);
    if (!config.isScrollable)
      scrollTo(0.0);
  }

  void dispose() {
    _selection?.unregisterPerformanceListener(this);
    super.dispose();
  }

  void handleSelectionDeactivate() {
    _selection = null;
  }

  void handleStatusChange(PerformanceStatus status) {
    if (config.labels.length == 0)
      return;

    if (_valueIsChanging && status == PerformanceStatus.completed) {
      _valueIsChanging = false;
      double progress = 0.5;
      if (_selection.index == 0)
        progress = 0.0;
      else if (_selection.index == config.labels.length - 1)
        progress = 1.0;
      setState(() {
        _indicatorRect
          ..begin = _tabIndicatorRect(math.max(0, _selection.index - 1))
          ..end = _tabIndicatorRect(math.min(config.labels.length - 1, _selection.index + 1))
          ..curve = null
          ..setProgress(progress, AnimationDirection.forward);
      });
    }
  }

  void handleProgressChange() {
    if (config.labels.length == 0 || _selection == null)
      return;

    if (!_valueIsChanging && _selection.valueIsChanging) {
      if (config.isScrollable)
        scrollTo(_centeredTabScrollOffset(_selection.index), duration: _kTabBarScroll);
      _indicatorRect
        ..begin = _indicatorRect.value ?? _tabIndicatorRect(_selection.previousIndex)
        ..end = _tabIndicatorRect(_selection.index)
        ..curve = Curves.ease;
      _valueIsChanging = true;
    }
    Rect oldRect = _indicatorRect.value;
    _indicatorRect.setProgress(_selection.performance.progress, AnimationDirection.forward);
    Rect newRect = _indicatorRect.value;
    if (oldRect != newRect)
      setState(() { });
  }

  Size _viewportSize = Size.zero;
  Size _tabBarSize;
  List<double> _tabWidths;
  AnimatedRectValue _indicatorRect = new AnimatedRectValue(null);

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

  ScrollBehavior createScrollBehavior() => new _TabsScrollBehavior();
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
          labelColor = Color.lerp(color, selectedColor, _selection.performance.progress);
        else if (isPreviouslySelectedTab)
          labelColor = Color.lerp(selectedColor, color, _selection.performance.progress);
      }
    }
    return new _Tab(
      onSelected: () { _handleTabSelected(tabIndex); },
      label: label,
      color: labelColor
    );
  }

  void _updateScrollBehavior() {
    scrollBehavior.updateExtents(
      containerExtent: config.scrollDirection == Axis.vertical ? _viewportSize.height : _viewportSize.width,
      contentExtent: _tabWidths.reduce((double sum, double width) => sum + width)
    );
  }

  void _layoutChanged(Size tabBarSize, List<double> tabWidths) {
    setState(() {
      _tabBarSize = tabBarSize;
      _tabWidths = tabWidths;
      _updateScrollBehavior();
    });
  }

  void _handleViewportSizeChanged(Size newSize) {
    _viewportSize = newSize;
    _updateScrollBehavior();
    if (config.isScrollable)
      scrollTo(_centeredTabScrollOffset(_selection.index), duration: _kTabBarScroll);
  }

  Widget buildContent(BuildContext context) {
    TabBarSelectionState<T> newSelection = TabBarSelection.of(context);
    if (_selection != newSelection)
      _initSelection(newSelection);

    assert(config.labels.isNotEmpty);
    assert(Material.of(context) != null);

    ThemeData themeData = Theme.of(context);
    Color backgroundColor = Material.of(context).color;
    Color indicatorColor = themeData.accentColor;
    if (indicatorColor == backgroundColor)
      indicatorColor = Colors.white;

    TextStyle textStyle = themeData.primaryTextTheme.body1;
    IconThemeData iconTheme = themeData.primaryIconTheme;

    List<Widget> tabs = <Widget>[];
    bool textAndIcons = false;
    int tabIndex = 0;
    for (TabLabel label in config.labels.values) {
      tabs.add(_toTab(label, tabIndex++, textStyle.color, indicatorColor));
      if (label.text != null && label.icon != null)
        textAndIcons = true;
    }

    Widget contents = new IconTheme(
      data: iconTheme,
      child: new DefaultTextStyle(
        style: textStyle,
        child: new _TabBarWrapper(
          children: tabs,
          selectedIndex: _selection?.index,
          indicatorColor: indicatorColor,
          indicatorRect: _indicatorRect.value,
          textAndIcons: textAndIcons,
          isScrollable: config.isScrollable,
          onLayoutChanged: _layoutChanged
        )
      )
    );

    if (config.isScrollable) {
      contents = new SizeObserver(
        onSizeChanged: _handleViewportSizeChanged,
        child: new Viewport(
          scrollDirection: Axis.horizontal,
          scrollOffset: new Offset(scrollOffset, 0.0),
          child: contents
        )
      );
    }

    return contents;
  }
}

class TabBarView extends PageableList {
  TabBarView({
    Key key,
    List<Widget> children
  }) : super(
    key: key,
    scrollDirection: Axis.horizontal,
    children: children
  ) {
    assert(children != null);
    assert(children.length > 1);
  }

  _TabBarViewState createState() => new _TabBarViewState();
}

class _TabBarViewState extends PageableListState<TabBarView> implements TabBarSelectionPerformanceListener {

  TabBarSelectionState _selection;
  List<Widget> _items;
  AnimationDirection _scrollDirection = AnimationDirection.forward;

  int get _tabCount => config.children.length;

  BoundedBehavior _boundedBehavior;

  ExtentScrollBehavior get scrollBehavior {
    _boundedBehavior ??= new BoundedBehavior();
    return _boundedBehavior;
  }

  void _initSelection(TabBarSelectionState selection) {
    _selection = selection;
    if (_selection != null) {
      _selection.registerPerformanceListener(this);
      _updateItemsAndScrollBehavior();
    }
  }

  void initState() {
    super.initState();
    _initSelection(TabBarSelection.of(context));
  }

  void didUpdateConfig(TabBarView oldConfig) {
    super.didUpdateConfig(oldConfig);
    if (_selection != null && config.children != oldConfig.children)
      _updateItemsForSelectedIndex(_selection.index);
  }

  void dispose() {
    _selection?.unregisterPerformanceListener(this);
    super.dispose();
  }

  void handleSelectionDeactivate() {
    _selection = null;
  }

  void _updateItemsFromChildren(int first, int second, [int third]) {
    List<Widget> widgets = config.children;
    _items = <Widget>[widgets[first], widgets[second]];
    if (third != null)
      _items.add(widgets[third]);
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
      scrollTo(scrollBehavior.updateExtents(contentExtent: 2.0, containerExtent: 1.0, scrollOffset: 0.0));
    } else if (selectedIndex == _tabCount - 1) {
      scrollTo(scrollBehavior.updateExtents(contentExtent: 2.0, containerExtent: 1.0, scrollOffset: 1.0));
    } else {
      scrollTo(scrollBehavior.updateExtents(contentExtent: 3.0, containerExtent: 1.0, scrollOffset: 1.0));
    }
  }

  void _updateItemsAndScrollBehavior() {
    assert(_selection != null);
    final int selectedIndex = _selection.index;
    _updateItemsForSelectedIndex(selectedIndex);
    _updateScrollBehaviorForSelectedIndex(selectedIndex);
  }

  void handleStatusChange(PerformanceStatus status) {
  }

  void handleProgressChange() {
    if (_selection == null || !_selection.valueIsChanging)
      return;
    // The TabBar is driving the TabBarSelection performance.

    final Performance performance = _selection.performance;

    if (performance.status == PerformanceStatus.completed) {
      _updateItemsAndScrollBehavior();
      return;
    }

    if (performance.status != PerformanceStatus.forward)
      return;

    final int selectedIndex = _selection.index;
    final int previousSelectedIndex = _selection.previousIndex;

    if (selectedIndex < previousSelectedIndex) {
      _updateItemsFromChildren(selectedIndex, previousSelectedIndex);
      _scrollDirection = AnimationDirection.reverse;
    } else {
      _updateItemsFromChildren(previousSelectedIndex, selectedIndex);
      _scrollDirection = AnimationDirection.forward;
    }

    if (_scrollDirection == AnimationDirection.forward)
      scrollTo(performance.progress);
    else
      scrollTo(1.0 - performance.progress);
  }

  void dispatchOnScroll() {
    if (_selection == null || _selection.valueIsChanging)
      return;
    // This class is driving the TabBarSelection's performance.

    final Performance performance = _selection._performance;

    if (_selection.index == 0 || _selection.index == _tabCount - 1)
      performance.progress = scrollOffset;
    else
      performance.progress = scrollOffset / 2.0;
  }

  Future fling(Offset scrollVelocity) {
    if (_selection == null || _selection.valueIsChanging)
      return new Future.value();

    if (scrollVelocity.dx.abs() > _kMinFlingVelocity) {
      final int selectionDelta = scrollVelocity.dx > 0 ? -1 : 1;
      final int targetIndex = (_selection.index + selectionDelta).clamp(0, _tabCount - 1);
      _selection.value = _selection.values[targetIndex];
      return new Future.value();
    }

    final int selectionIndex = _selection.index;
    final int settleIndex = snapScrollOffset(scrollOffset).toInt();
    if (selectionIndex > 0 && settleIndex != 1) {
      final int targetIndex = (selectionIndex + (settleIndex == 2 ? 1 : -1)).clamp(0, _tabCount - 1);
      _selection.value = _selection.values[targetIndex];
      return new Future.value();
    } else if (selectionIndex == 0 && settleIndex == 1) {
      _selection.value = _selection.values[1];
      return new Future.value();
    }
    return settleScrollOffset();
  }

  Widget buildContent(BuildContext context) {
    TabBarSelectionState newSelection = TabBarSelection.of(context);
    if (_selection != newSelection)
      _initSelection(newSelection);
    return new PageViewport(
      itemsWrap: config.itemsWrap,
      scrollDirection: config.scrollDirection,
      startOffset: scrollOffset,
      overlayPainter: config.scrollableListPainter,
      children: _items
    );
  }
}
