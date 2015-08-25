// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:sky' as sky;

import 'package:newton/newton.dart';
import 'package:sky/animation/animation_performance.dart';
import 'package:sky/animation/animated_value.dart';
import 'package:sky/animation/curves.dart';
import 'package:sky/animation/scroll_behavior.dart';
import 'package:sky/painting/text_style.dart';
import 'package:sky/rendering/box.dart';
import 'package:sky/rendering/object.dart';
import 'package:sky/rendering/viewport.dart';
import 'package:sky/theme/colors.dart' as colors;
import 'package:sky/theme/typography.dart' as typography;
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/default_text_style.dart';
import 'package:sky/widgets/icon.dart';
import 'package:sky/widgets/ink_well.dart';
import 'package:sky/widgets/scrollable.dart';
import 'package:sky/widgets/theme.dart';
import 'package:sky/widgets/transitions.dart';
import 'package:sky/widgets/framework.dart';

typedef void SelectedIndexChanged(int selectedIndex);
typedef void LayoutChanged(Size size, List<double> widths);

// See https://www.google.com/design/spec/components/tabs.html#tabs-specs
const double _kTabHeight = 46.0;
const double _kTextAndIconTabHeight = 72.0;
const double _kTabIndicatorHeight = 2.0;
const double _kMinTabWidth = 72.0;
const double _kMaxTabWidth = 264.0;
const EdgeDims _kTabLabelPadding = const EdgeDims.symmetric(horizontal: 12.0);
const int _kTabIconSize = 24;
const double _kTabBarScrollDrag = 0.025;
const Duration _kTabBarScroll = const Duration(milliseconds: 200);

class TabBarParentData extends BoxParentData with
    ContainerParentDataMixin<RenderBox> { }

class RenderTabBar extends RenderBox with
    ContainerRenderObjectMixin<RenderBox, TabBarParentData>,
    RenderBoxContainerDefaultsMixin<RenderBox, TabBarParentData> {

  RenderTabBar(this.onLayoutChanged);

  int _selectedIndex;
  int get selectedIndex => _selectedIndex;
  void set selectedIndex(int value) {
    if (_selectedIndex != value) {
      _selectedIndex = value;
      markNeedsPaint();
    }
  }

  Color _backgroundColor;
  Color get backgroundColor => _backgroundColor;
  void set backgroundColor(Color value) {
    if (_backgroundColor != value) {
      _backgroundColor = value;
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
    if (child.parentData is! TabBarParentData)
      child.parentData = new TabBarParentData();
  }

  double getMinIntrinsicWidth(BoxConstraints constraints) {
    BoxConstraints widthConstraints =
        new BoxConstraints(maxWidth: constraints.maxWidth, maxHeight: constraints.maxHeight);

    double maxWidth = 0.0;
    RenderBox child = firstChild;
    while (child != null) {
      maxWidth = math.max(maxWidth, child.getMinIntrinsicWidth(widthConstraints));
      assert(child.parentData is TabBarParentData);
      child = child.parentData.nextSibling;
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
      assert(child.parentData is TabBarParentData);
      child = child.parentData.nextSibling;
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
      assert(child.parentData is TabBarParentData);
      child.parentData.position = new Point(x, 0.0);
      x += tabWidth;
      child = child.parentData.nextSibling;
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
      assert(child.parentData is TabBarParentData);
      child.parentData.position = new Point(x, 0.0);
      x += child.size.width;
      child = child.parentData.nextSibling;
    }
    return x;
  }

  Size layoutSize;
  List<double> layoutWidths;
  LayoutChanged onLayoutChanged;

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
        child = child.parentData.nextSibling;
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

  void hitTestChildren(HitTestResult result, { Point position }) {
    defaultHitTestChildren(result, position: position);
  }

  void _paintIndicator(PaintingCanvas canvas, RenderBox selectedTab, Offset offset) {
    if (indicatorColor == null)
      return;

    if (indicatorRect != null) {
      canvas.drawRect(indicatorRect.shift(offset), new Paint()..color = indicatorColor);
      return;
    }

    var size = new Size(selectedTab.size.width, _kTabIndicatorHeight);
    var point = new Point(
      selectedTab.parentData.position.x,
      _tabBarHeight - _kTabIndicatorHeight
    );
    Rect rect = (point + offset) & size;
    canvas.drawRect(rect, new Paint()..color = indicatorColor);
  }

  void paint(PaintingContext context, Offset offset) {
    if (backgroundColor != null) {
      double width = layoutWidths != null
        ? layoutWidths.reduce((sum, width) => sum + width)
        : size.width;
      Rect rect = offset & new Size(width, size.height);
      context.canvas.drawRect(rect, new Paint()..color = backgroundColor);
    }
    int index = 0;
    RenderBox child = firstChild;
    while (child != null) {
      assert(child.parentData is TabBarParentData);
      context.paintChild(child, child.parentData.position + offset);
      if (index++ == selectedIndex)
        _paintIndicator(context.canvas, child, offset);
      child = child.parentData.nextSibling;
    }
  }
}

class TabBarWrapper extends MultiChildRenderObjectWrapper {
  TabBarWrapper({
    Key key,
    List<Widget> children,
    this.selectedIndex,
    this.backgroundColor,
    this.indicatorColor,
    this.indicatorRect,
    this.textAndIcons,
    this.isScrollable: false,
    this.onLayoutChanged
  }) : super(key: key, children: children);

  final int selectedIndex;
  final Color backgroundColor;
  final Color indicatorColor;
  final Rect indicatorRect;
  final bool textAndIcons;
  final bool isScrollable;
  final LayoutChanged onLayoutChanged;

  RenderTabBar get renderObject => super.renderObject;
  RenderTabBar createNode() => new RenderTabBar(onLayoutChanged);

  void syncRenderObject(Widget old) {
    super.syncRenderObject(old);
    renderObject.selectedIndex = selectedIndex;
    renderObject.backgroundColor = backgroundColor;
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
}

class Tab extends Component {
  Tab({
    Key key,
    this.label,
    this.color,
    this.selected: false,
    this.selectedColor
  }) : super(key: key) {
    assert(label.text != null || label.icon != null);
  }

  final TabLabel label;
  final Color color;
  final bool selected;
  final Color selectedColor;

  Widget _buildLabelText() {
    assert(label.text != null);
    TextStyle style = new TextStyle(color: selected ? selectedColor : color);
    return new Text(label.text, style: style);
  }

  Widget _buildLabelIcon() {
    assert(label.icon != null);
    Color iconColor = selected ? selectedColor : color;
    sky.ColorFilter filter = new sky.ColorFilter.mode(iconColor, sky.TransferMode.srcATop);
    return new Icon(type: label.icon, size: _kTabIconSize, colorFilter: filter);
  }

  Widget build() {
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
      child: new Center(child: labelContent),
      constraints: new BoxConstraints(minWidth: _kMinTabWidth),
      padding: _kTabLabelPadding
    );

    return new InkWell(child: centeredLabel);
  }
}

class _TabsScrollBehavior extends BoundedBehavior {
  _TabsScrollBehavior();

  bool isScrollable = true;

  Simulation release(double position, double velocity) {
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

class TabBar extends Scrollable {
  TabBar({
    Key key,
    this.labels,
    this.selectedIndex: 0,
    this.onChanged,
    this.isScrollable: false
  }) : super(key: key, scrollDirection: ScrollDirection.horizontal);

  Iterable<TabLabel> labels;
  int selectedIndex;
  SelectedIndexChanged onChanged;
  bool isScrollable;

  Size _tabBarSize;
  Size _viewportSize = Size.zero;
  List<double> _tabWidths;
  ValueAnimation<Rect> _indicatorAnimation;

  void initState() {
    super.initState();
    _indicatorAnimation = new ValueAnimation<Rect>()
      ..duration = _kTabBarScroll
      ..variable = new AnimatedRect(null, curve: ease);
    scrollBehavior.isScrollable = isScrollable;
  }

  void syncConstructorArguments(TabBar source) {
    super.syncConstructorArguments(source);
    labels = source.labels;
    selectedIndex = source.selectedIndex;
    onChanged = source.onChanged;
    isScrollable = source.isScrollable;
    if (!isScrollable)
      scrollTo(0.0);
    scrollBehavior.isScrollable = source.isScrollable;
  }

  AnimatedRect get _indicatorRect => _indicatorAnimation.variable;

  void _startIndicatorAnimation(int fromTabIndex, int toTabIndex) {
    _indicatorRect
      ..begin = (_indicatorRect.value == null ? _tabIndicatorRect(fromTabIndex) : _indicatorRect.value)
      ..end = _tabIndicatorRect(toTabIndex);
    _indicatorAnimation
      ..progress = 0.0
      ..play();
  }

  ScrollBehavior createScrollBehavior() => new _TabsScrollBehavior();
  _TabsScrollBehavior get scrollBehavior => super.scrollBehavior;

  Rect _tabRect(int tabIndex) {
    assert(_tabBarSize != null);
    assert(_tabWidths != null);
    assert(tabIndex >= 0 && tabIndex < _tabWidths.length);
    double tabLeft = 0.0;
    if (tabIndex > 0)
      tabLeft = _tabWidths.take(tabIndex).reduce((sum, width) => sum + width);
    double tabTop = 0.0;
    double tabBottom = _tabBarSize.height - _kTabIndicatorHeight;
    double tabRight = tabLeft + _tabWidths[tabIndex];
    return new Rect.fromLTRB(tabLeft, tabTop, tabRight, tabBottom);
  }

  Rect _tabIndicatorRect(int tabIndex) {
    Rect r = _tabRect(tabIndex);
    return new Rect.fromLTRB(r.left, r.bottom, r.right, r.bottom + _kTabIndicatorHeight);
  }

  double _centeredTabScrollOffset(int tabIndex) {
    double viewportWidth = scrollBehavior.containerExtent;
    return (_tabRect(tabIndex).left + _tabWidths[tabIndex] / 2.0 - viewportWidth / 2.0)
      .clamp(scrollBehavior.minScrollOffset, scrollBehavior.maxScrollOffset);
  }

  EventDisposition _handleTap(int tabIndex) {
    if (tabIndex != selectedIndex) {
      if (_tabWidths != null) {
        if (isScrollable)
          scrollTo(_centeredTabScrollOffset(tabIndex), duration: _kTabBarScroll);
        _startIndicatorAnimation(selectedIndex, tabIndex);
      }
      if (onChanged != null)
        onChanged(tabIndex);
      return EventDisposition.processed;
    }
    return EventDisposition.ignored;
  }

  Widget _toTab(TabLabel label, int tabIndex, Color color, Color selectedColor) {
    return new Listener(
      child: new Tab(
        label: label,
        color: color,
        selected: tabIndex == selectedIndex,
        selectedColor: selectedColor
      ),
      onGestureTap: (_) => _handleTap(tabIndex)
    );
  }

  void _updateScrollBehavior() {
    scrollBehavior.updateExtents(
      containerExtent: scrollDirection == ScrollDirection.vertical ? _viewportSize.height : _viewportSize.width,
      contentExtent: _tabWidths.reduce((sum, width) => sum + width)
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
  }

  Widget buildContent() {
    assert(labels != null && labels.isNotEmpty);

    ThemeData themeData = Theme.of(this);
    Color backgroundColor = themeData.primaryColor;
    Color indicatorColor = themeData.accentColor;
    if (indicatorColor == backgroundColor) {
      indicatorColor = colors.white;
    }

    TextStyle textStyle;
    IconThemeColor iconThemeColor;
    switch (themeData.primaryColorBrightness) {
      case ThemeBrightness.light:
        textStyle = typography.black.body1;
        iconThemeColor = IconThemeColor.black;
        break;
      case ThemeBrightness.dark:
        textStyle = typography.white.body1;
        iconThemeColor = IconThemeColor.white;
        break;
    }

    List<Widget> tabs = <Widget>[];
    bool textAndIcons = false;
    int tabIndex = 0;
    for (TabLabel label in labels) {
      tabs.add(_toTab(label, tabIndex++, textStyle.color, indicatorColor));
      if (label.text != null && label.icon != null)
        textAndIcons = true;
    }

    Widget tabBar = new IconTheme(
      data: new IconThemeData(color: iconThemeColor),
      child: new DefaultTextStyle(
        style: textStyle,
        child: new BuilderTransition(
          variables: [_indicatorRect],
          direction: Direction.forward,
          performance: _indicatorAnimation,
          builder: () {
            return new TabBarWrapper(
              children: tabs,
              selectedIndex: selectedIndex,
              backgroundColor: backgroundColor,
              indicatorColor: indicatorColor,
              indicatorRect: _indicatorRect.value,
              textAndIcons: textAndIcons,
              isScrollable: isScrollable,
              onLayoutChanged: _layoutChanged
            );
          }
        )
      )
    );

    if (!isScrollable)
      return tabBar;

    return new SizeObserver(
      callback: _handleViewportSizeChanged,
      child: new Viewport(
        scrollDirection: ScrollDirection.horizontal,
        scrollOffset: new Offset(scrollOffset, 0.0),
        child: tabBar
      )
    );
  }
}

class TabNavigatorView {
  TabNavigatorView({ this.label, this.builder });

  final TabLabel label;
  final Builder builder;

  Widget buildContent() {
    assert(builder != null);
    Widget content = builder();
    assert(content != null);
    return content;
  }
}

class TabNavigator extends Component {
  TabNavigator({
    Key key,
    this.views,
    this.selectedIndex: 0,
    this.onChanged,
    this.isScrollable: false
  }) : super(key: key);

  final List<TabNavigatorView> views;
  final int selectedIndex;
  final SelectedIndexChanged onChanged;
  final bool isScrollable;

  void _handleSelectedIndexChanged(int tabIndex) {
    if (onChanged != null)
      onChanged(tabIndex);
  }

  Widget build() {
    assert(views != null && views.isNotEmpty);
    assert(selectedIndex >= 0 && selectedIndex < views.length);

    TabBar tabBar = new TabBar(
      labels: views.map((view) => view.label),
      onChanged: _handleSelectedIndexChanged,
      selectedIndex: selectedIndex,
      isScrollable: isScrollable
    );

    Widget content = views[selectedIndex].buildContent();
    return new Column([tabBar, new Flexible(child: content)]);
  }
}
