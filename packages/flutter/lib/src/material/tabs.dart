// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'app_bar.dart';
import 'colors.dart';
import 'debug.dart';
import 'icon.dart';
import 'icon_theme.dart';
import 'icon_theme_data.dart';
import 'ink_well.dart';
import 'material.dart';
import 'theme.dart';

const double _kTabHeight = 46.0;
const double _kTextAndIconTabHeight = 72.0;
const double _kTabIndicatorHeight = 2.0;
const double _kMinTabWidth = 72.0;
const double _kMaxTabWidth = 264.0;
const EdgeInsets _kTabLabelPadding = const EdgeInsets.symmetric(horizontal: 12.0);
const Duration _kTabScrollDuration = const Duration(milliseconds: 200);

class TabController {
  TabController({ int initialIndex: 0, this.length, TickerProvider vsync })
    : _index = initialIndex,
      _previousIndex = initialIndex,
      _animationController = new AnimationController(
        value: 0.5,
        vsync: vsync
   ) {
    assert(length != null && length > 1);
    assert(initialIndex != null && initialIndex >= 0 && initialIndex < length);
  }

  final AnimationController _animationController;
  Animation<double> get animation => _animationController.view;

  final int length;

  int get previousIndex => _previousIndex;
  int _previousIndex;

  bool _indexIsChanging = false;
  bool get indexIsChanging => _indexIsChanging;

  int get index => _index;
  int _index;

  void animateTo(int value, { Duration duration: _kTabScrollDuration, Curve curve: Curves.ease }) {
    assert(value != null);
    assert(value >= 0 && value < length);
    if (value == _index)
      return;
    _indexIsChanging = true;
    _previousIndex = index;
    _index = value;
    _animationController
      ..value = 0.0
      ..animateTo(1.0, duration: duration, curve: curve).then((_) {
        _animationController.value = 0.5;
        _indexIsChanging = false;
      });
  }

  double get offset => 2.0 * _animationController.value - 1.0;
  set offset(double value) {
    assert(value != null);
    assert(value >= -1.0 && value <= 1.0);
    assert(!indexIsChanging);
    if (value == offset)
      return;
    _animationController.value = (value + 1.0) / 2.0;
  }

  void dispose() {
    _animationController.dispose();
  }
}

class _TabControllerScope extends InheritedWidget {
  _TabControllerScope({
    Key key,
    this.controller,
    this.enabled,
    Widget child
  }) : super(key: key, child: child);

  final TabController controller;
  final bool enabled;

  @override
  bool updateShouldNotify(_TabControllerScope old) {
    return enabled != old.enabled || controller != old.controller;
  }
}

class DefaultTabController extends StatefulWidget {
  DefaultTabController({
    Key key,
    @required this.length,
    this.initialIndex: 0,
    this.child
  }) : super(key: key);

  final int length;
  final int initialIndex;
  final Widget child;

  static TabController of(BuildContext context) {
    _TabControllerScope scope = context.inheritFromWidgetOfExactType(_TabControllerScope);
    return scope?.controller;
  }

  @override
  _DefaultTabControllerState createState() => new _DefaultTabControllerState();
}

class _DefaultTabControllerState extends State<DefaultTabController> with SingleTickerProviderStateMixin {
  TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = new TabController(
      vsync: this,
      length: config.length,
      initialIndex: config.initialIndex,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return new _TabControllerScope(
      controller: _controller,
      enabled: TickerMode.of(context),
      child: config.child,
    );
  }
}

class Tab extends StatelessWidget {
  Tab({
    Key key,
    this.text,
    this.icon,
  }) : super(key: key) {
    assert(text != null || icon != null);
  }

  final String text;
  final Icon icon;

  Widget _buildLabelText() {
    return new Text(text, softWrap: false, overflow: TextOverflow.fade);
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));

    double height;
    Widget label;
    if (icon == null) {
      height = _kTabHeight;
      label = _buildLabelText();
    } else if (text == null) {
      height = _kTabHeight;
      label = icon;
    } else {
      height = _kTextAndIconTabHeight;
      label = new Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          new Container(
            child: icon,
            margin: const EdgeInsets.only(bottom: 10.0)
          ),
          _buildLabelText()
        ]
      );
    }

    return new Container(
      padding: _kTabLabelPadding,
      height: height,
      constraints: const BoxConstraints(minWidth: _kMinTabWidth),
      child: new Center(child: label),
    );
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    if (text != null)
      description.add('text: $text');
    if (icon != null)
      description.add('icon: $icon');
  }
}

class _TabStyle extends AnimatedWidget {
  _TabStyle({
    Key key,
    Animation<double> animation,
    this.selected,
    this.labelColor,
    this.child
  }) : super(key: key, animation: animation);

  final bool selected;
  final Color labelColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final TextStyle textStyle = themeData.primaryTextTheme.body2;
    final Color selectedColor = labelColor ?? themeData.primaryTextTheme.body2.color;
    final Color unselectedColor = selectedColor.withAlpha(0xB2); // 70% alpha
    final Color color = selected
      ? Color.lerp(unselectedColor, selectedColor, animation.value)
      : Color.lerp(selectedColor, unselectedColor, animation.value);

    return new DefaultTextStyle(
      style: textStyle.copyWith(color: color),
      child: new IconTheme.merge(
        context: context,
        data: new IconThemeData(
          size: 24.0,
          color: color,
        ),
        child: child,
      ),
    );
  }
}

class _TabLabelBarRenderer extends RenderFlex {
  _TabLabelBarRenderer({
    List<RenderBox> children,
    Axis direction,
    MainAxisSize mainAxisSize,
    MainAxisAlignment mainAxisAlignment,
    CrossAxisAlignment crossAxisAlignment,
    TextBaseline textBaseline,
    this.onPerformLayout,
  }) : super(
    children: children,
    direction: direction,
    mainAxisSize: mainAxisSize,
    mainAxisAlignment: mainAxisAlignment,
    crossAxisAlignment: crossAxisAlignment,
    textBaseline: textBaseline,
  ) {
    assert(onPerformLayout != null);
  }

  ValueChanged<List<double>> onPerformLayout;

  @override
  void performLayout() {
    super.performLayout();
    RenderBox child = firstChild;
    final List<double> xOffsets = <double>[];
    while (child != null) {
      final FlexParentData childParentData = child.parentData;
      xOffsets.add(childParentData.offset.dx);
      assert(child.parentData == childParentData);
      child = childParentData.nextSibling;
    }
    xOffsets.add(size.width); // So xOffsets[lastTabIndex + 1] is valid.
    onPerformLayout(xOffsets);
  }
}

// This class and its renderer class only exist to report the widths of the tabs
// upon layout. The tab widths are only used at paint time (see _IndicatorPainter)
// or in response to input.
class _TabLabelBar extends Flex {
  _TabLabelBar({
    Key key,
    MainAxisAlignment mainAxisAlignment,
    CrossAxisAlignment crossAxisAlignment,
    List<Widget> children: const <Widget>[],
    this.onPerformLayout,
  }) : super(
    key: key,
    children: children,
    direction: Axis.horizontal,
    mainAxisSize: MainAxisSize.max,
    mainAxisAlignment: MainAxisAlignment.start,
    crossAxisAlignment: CrossAxisAlignment.center,
  );

  final ValueChanged<List<double>> onPerformLayout;

  @override
  RenderFlex createRenderObject(BuildContext context) {
    return new _TabLabelBarRenderer(
      direction: direction,
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      crossAxisAlignment: crossAxisAlignment,
      textBaseline: textBaseline,
      onPerformLayout: onPerformLayout,
    );
  }

  @override
  void updateRenderObject(BuildContext context, _TabLabelBarRenderer renderObject) {
    super.updateRenderObject(context, renderObject);
    renderObject.onPerformLayout = onPerformLayout;
  }
}

class _IndicatorRectTween extends Animatable<Rect> {
  _IndicatorRectTween(this.left, this.middle, this.right) {
    assert(middle != null);
    assert(left != null || right != null);
  }

  final Rect left;
  final Rect middle;
  final Rect right;

  @override
  Rect evaluate(Animation<double> animation) {
    final double t = animation.value;
    if (t == 0.0)
      return left ?? middle;
    if (t == 1.0)
      return right ?? middle;
    if (t == 0.5)
      return middle;
    if (t < 0.5)
      return left == null ? middle : Rect.lerp(left, middle, t * 2.0);
    return right == null ? middle : Rect.lerp(middle, right, (t - 0.5) * 2.0);
  }
}

class _IndicatorPainter extends CustomPainter {
  _IndicatorPainter(this.controller)
    : currentIndex = controller.index, super(repaint: controller.animation);

  TabController controller;
  int currentIndex;
  List<double> tabOffsets;
  Color color;
  Animatable<Rect> indicatorTween;
  Rect currentRect;

  // tabOffsets[index] is the offset of the left edge of the tab at index, and
  // tabOffsets[tabOffsets.length] is the right edge of the last tab.
  int get maxTabIndex => tabOffsets.length - 2;

  Rect indicatorRect(Size tabBarSize, int tabIndex) {
    assert(tabOffsets != null && tabIndex >= 0 && tabIndex <= maxTabIndex);
    final double tabLeft = tabOffsets[tabIndex];
    final double tabRight = tabOffsets[tabIndex + 1];
    final double tabTop = tabBarSize.height - _kTabIndicatorHeight;
    return new Rect.fromLTWH(tabLeft, tabTop, tabRight - tabLeft, _kTabIndicatorHeight);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (controller.indexIsChanging) {
      if (indicatorTween == null || controller.index != currentIndex) {
        indicatorTween = new RectTween(
          begin: currentRect ?? indicatorRect(size, currentIndex),
          end: indicatorRect(size, controller.index),
        );
        currentIndex = controller.index;
      }
    } else {
      indicatorTween = new _IndicatorRectTween(
        currentIndex > 0 ? indicatorRect(size, currentIndex - 1) : null,
        indicatorRect(size, currentIndex),
        currentIndex < maxTabIndex ? indicatorRect(size, currentIndex + 1) : null,
      );
    }
    currentRect = indicatorTween.evaluate(controller.animation);
    canvas.drawRect(currentRect, new Paint()..color = color);
  }

  bool tabOffsetsNotEqual(List<double> a, List<double> b) {
    assert(a != null && b != null && a.length == b.length);
    for(int i = 0; i < a.length; i++) {
      if (a[i] != b[i])
        return true;
    }
    return false;
  }

  @override
  bool shouldRepaint(_IndicatorPainter old) {
    return controller != old.controller ||
      tabOffsets?.length != old.tabOffsets?.length ||
      tabOffsetsNotEqual(tabOffsets, old.tabOffsets);
  }
}

class _TabScrollOffsetTween extends Animatable<double> {
  _TabScrollOffsetTween(this.left, this.middle, this.right) {
    assert(middle != null);
    assert(left != null || right != null);
  }

  final double left;
  final double middle;
  final double right;

  @override
  double evaluate(Animation<double> animation) {
    final double t = animation.value;
    if (t == 0.0)
      return left ?? middle;
    if (t == 1.0)
      return right ?? middle;
    if (t == 0.5)
      return middle;
    if (t < 0.5)
      return left == null ? middle : lerpDouble(left, middle, t * 2.0);
    return right == null ? middle : lerpDouble(middle, right, (t - 0.5) * 2.0);
  }
}

class TabBar extends StatefulWidget implements AppBarBottomWidget {
  TabBar({
    Key key,
    @required this.tabs,
    this.isScrollable: false,
    this.indicatorColor,
    this.labelColor,
    this.controller,
  }) : super(key: key) {
    assert(tabs != null && tabs.length > 1);
    assert(isScrollable != null);
  }

  final TabController controller;

  final List<Widget> tabs;

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

  // TBD: this is a non-working hack.
  @override
  double get bottomHeight => _kTextAndIconTabHeight + _kTabIndicatorHeight;

  @override
  _TabBarState createState() => new _TabBarState();
}

class _TabBarState extends State<TabBar> {
  final GlobalKey<ScrollableState> viewportKey = new GlobalKey<ScrollableState>();

  TabController _controller;
  _IndicatorPainter _indicatorPainter;
  double _currentOffset = 0.0; // TBD compute at initState time based on controller.index
  int _currentIndex;

  void _initTabController() {
    if (_controller != null)
      _controller.animation.removeListener(_handleTick);
    _controller = config.controller ?? DefaultTabController.of(context);
    if (_controller != null) {
      _controller.animation.addListener(_handleTick);
      _currentIndex = _controller.index;
      final List<double> offsets = _indicatorPainter?.tabOffsets;
      _indicatorPainter = new _IndicatorPainter(_controller)..tabOffsets = offsets;
    }
  }

  @override
  void dependenciesChanged() {
    super.dependenciesChanged();
    _initTabController();
  }

  @override
  void didUpdateConfig(TabBar oldConfig) {
    super.didUpdateConfig(oldConfig);
    if (config.controller != oldConfig.controller)
      _initTabController();
  }

  @override
  void dispose() {
    if (_controller != null)
      _controller.animation.removeListener(_handleTick);
    super.dispose();
  }

  // tabOffsets[index] is the offset of the left edge of the tab at index, and
  // tabOffsets[tabOffsets.length] is the right edge of the last tab.
  int get maxTabIndex => _indicatorPainter.tabOffsets.length - 2;

  double _tabCenteredScrollOffset(ScrollableState viewport, int tabIndex) {
    final List<double> tabOffsets = _indicatorPainter.tabOffsets;
    assert(tabOffsets != null && tabIndex >= 0 && tabIndex <= maxTabIndex);

    final ExtentScrollBehavior scrollBehavior = viewport.scrollBehavior;
    final double viewportWidth = scrollBehavior.containerExtent;
    final double tabCenter = (tabOffsets[tabIndex] + tabOffsets[tabIndex + 1]) / 2.0;
    return (tabCenter - viewportWidth / 2.0)
      .clamp(scrollBehavior.minScrollOffset, scrollBehavior.maxScrollOffset);
  }

  void _handleTick() {
    if (_controller.indexIsChanging) {
      setState(() {
        // Rebuild so that the tab label colors reflect the
        // new selected tab index.
      });
    } else if (config.isScrollable) {
      final int currentIndex = _controller.index;
      final ScrollableState viewport = viewportKey.currentState;
      _TabScrollOffsetTween tween = new _TabScrollOffsetTween(
        currentIndex > 0 ? _tabCenteredScrollOffset(viewport, currentIndex - 1) : null,
        _tabCenteredScrollOffset(viewport, currentIndex),
        currentIndex < maxTabIndex ? _tabCenteredScrollOffset(viewport, currentIndex + 1) : null
      );
      viewport.scrollTo(tween.evaluate(_controller.animation));
    }
  }

  void _saveTabOffsets(List<double> tabOffsets) {
    _indicatorPainter.tabOffsets = tabOffsets;
  }

  void _scrollToCenter(int tabIndex) {
    final ScrollableState viewport = viewportKey.currentState;
    _currentOffset = _tabCenteredScrollOffset(viewport, tabIndex);
    viewport.scrollTo(_currentOffset, duration: _kTabScrollDuration);
  }

  void _handleTap(int index) {
    assert(index >= 0 && index < config.tabs.length);
    _controller.animateTo(index);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    _indicatorPainter.color = config.indicatorColor ?? themeData.indicatorColor;
    if (_indicatorPainter.color == Material.of(context).color) {
      // ThemeData tries to avoid this by having indicatorColor avoid being the
      // primaryColor. However, it's possible that the tab bar is on a
      // Material that isn't the primaryColor. In that case, if the indicator
      // color ends up clashing, then this overrides it. When that happens,
      // automatic transitions of the theme will likely look ugly as the
      // indicator color suddenly snaps to white at one end, but it's not clear
      // how to avoid that any further.
      _indicatorPainter.color = Colors.white;
    }

    if (_controller.index != _currentIndex) {
      _currentIndex = _controller.index;
      if (config.isScrollable)
        _scrollToCenter(_currentIndex);
    }

    final List<Widget> wrappedTabs = new List<Widget>.from(config.tabs, growable: false);
    final int previousIndex = _controller.previousIndex;

    if (_controller.indexIsChanging) {
      assert(_currentIndex != previousIndex);
      wrappedTabs[_currentIndex] = new _TabStyle(
        animation: _controller.animation,
        selected: true,
        labelColor: config.labelColor,
        child: wrappedTabs[_currentIndex],
      );
      wrappedTabs[previousIndex] = new _TabStyle(
        animation: _controller.animation,
        selected: false,
        labelColor: config.labelColor,
        child: wrappedTabs[previousIndex],
      );
    } else {
      wrappedTabs[_currentIndex] = new _TabStyle(
        animation: kAlwaysCompleteAnimation,
        selected: true,
        labelColor: config.labelColor,
        child: wrappedTabs[_currentIndex],
      );
    }

    // Add the tap handler to each tab. If the tab bar is scrollable
    // then give all of the tabs equal flexibility so that their widths
    // reflect the intrinsic width of their labels.
    for(int index = 0; index < config.tabs.length; index++) {
      final int tabIndex = index;
      wrappedTabs[index] = new InkWell(
        onTap: () { _handleTap(tabIndex); },
        child: wrappedTabs[index],
      );
      if (!config.isScrollable)
        wrappedTabs[index] = new Flexible(child: wrappedTabs[index]);
    }

    Widget tabBar = new CustomPaint(
      painter: _indicatorPainter,
      child: new Padding(
        padding: const EdgeInsets.only(bottom: _kTabIndicatorHeight),
        child: new _TabStyle(
          animation: kAlwaysCompleteAnimation,
          selected: false,
          labelColor: config.labelColor,
          child: new _TabLabelBar(
            onPerformLayout: _saveTabOffsets,
            children:  wrappedTabs,
          ),
        ),
      ),
    );

    if (config.isScrollable) {
      tabBar = new ScrollableViewport(
        scrollableKey: viewportKey,
        scrollDirection: Axis.horizontal,
        child: tabBar
      );
    }

    return tabBar;
  }
}

// TODO(hansmuller: prevent the pageable list from being dragged more then
// one page in either direction.
class _PageableTabBarView extends PageableList {
  _PageableTabBarView({
    Key key,
    List<Widget> children,
  }) : super(
    key: key,
    scrollDirection: Axis.horizontal,
    children: children,
  );

  @override
  _PageableTabBarViewState createState() => new _PageableTabBarViewState();
}

class _PageableTabBarViewState extends PageableListState<_PageableTabBarView> {
  BoundedBehavior _boundedBehavior;

  @override
  ExtentScrollBehavior get scrollBehavior {
    _boundedBehavior ??= new BoundedBehavior(
      platform: platform,
      containerExtent: 1.0,
      contentExtent: config.children.length.toDouble(),
    );
    return _boundedBehavior;
  }

  @override
  TargetPlatform get platform => Theme.of(context).platform;

  @override
  Future<Null> fling(double scrollVelocity) {
    final double newScrollOffset = snapScrollOffset(scrollOffset + scrollVelocity.sign)
      .clamp(snapScrollOffset(scrollOffset - 0.5), snapScrollOffset(scrollOffset + 0.5))
      .clamp(0.0, (config.children.length - 1).toDouble());
    return scrollTo(newScrollOffset, duration: config.duration, curve: config.curve);
  }

  @override
  Widget buildContent(BuildContext context) {
    return new PageViewport(
      mainAxis: config.scrollDirection,
      startOffset: scrollOffset,
      children: config.children,
    );
  }
}

/// TBD
///
///
/// See also:
///
///  * [TabBarSelection]
///  * [TabBar]
///  * <https://material.google.com/components/tabs.html>
class TabBarView extends StatefulWidget {
  /// Creates a widget that displays the contents of a tab.
  ///
  /// The [children] argument must not be null and must not be empty.
  TabBarView({
    Key key,
    this.children,
    this.controller,
  }) : super(key: key); // TBD: how to verify that tabCount is the same as TabBar's tabs.length? And that it's intrinsically valid

  final TabController controller;
  final List<Widget> children;

  @override
  _TabBarViewState createState() => new _TabBarViewState();
}

class _TabBarViewState extends State<TabBarView> {
  final GlobalKey<ScrollableState> viewportKey = new GlobalKey<ScrollableState>();

  TabController _controller;
  List<Widget> _children;
  double _offsetAnchor;
  double _offsetBias = 0.0;
  int _currentIndex;
  bool _warpUnderway = false;

  void _initTabController() {
    if (_controller != null)
      _controller.animation.removeListener(_handleTick);
    _controller = config.controller ?? DefaultTabController.of(context);
    if (_controller != null)
      _controller.animation.addListener(_handleTick);
  }

  @override
  void initState() {
    super.initState();
    _children = config.children;
  }

  @override
  void dependenciesChanged() {
    super.dependenciesChanged();
    _initTabController();
    _currentIndex = _controller?.index;
  }

  @override
  void didUpdateConfig(TabBarView oldConfig) {
    super.didUpdateConfig(oldConfig);
    if (config.controller != oldConfig.controller)
      _initTabController();
    if (config.children != oldConfig.children && !_warpUnderway)
      _children = config.children;
  }

  @override
  void dispose() {
    _controller.animation.removeListener(_handleTick);
    super.dispose();
  }

  void _handleTick() {
    if (!_controller.indexIsChanging)
      return; // This widget is driving the controller's animation.

    if (_controller.index != _currentIndex) {
      _currentIndex = _controller.index;
      _warpToCurrentIndex();
    }
  }

  Future<Null> _warpToCurrentIndex() async {
    assert(_controller.indexIsChanging);

    final ScrollableState viewport = viewportKey.currentState;
    if (viewport.scrollOffset == _currentIndex.toDouble())
      return new Future<Null>.value();

    final int previousIndex = _controller.previousIndex;
    if ((_currentIndex - previousIndex).abs() == 1)
      return viewport.scrollTo(_currentIndex.toDouble(), duration: _kTabScrollDuration);

    assert((_currentIndex - previousIndex).abs() > 1);
    double initialScroll;
    setState(() {
      _warpUnderway = true;
      _children = new List<Widget>.from(config.children, growable: false);
      if (_currentIndex > previousIndex) {
        _children[_currentIndex - 1] = _children[previousIndex];
        initialScroll = (_currentIndex - 1).toDouble();
      } else {
        _children[_currentIndex + 1] = _children[previousIndex];
        initialScroll = (_currentIndex + 1).toDouble();
      }
    });
    await viewport.scrollTo(initialScroll);
    await viewport.scrollTo(_currentIndex.toDouble(), duration: _kTabScrollDuration);
    setState(() {
      _warpUnderway = false;
      _children = config.children;
    });
  }

  // Called when the _PageableTabBarView scrolls
  bool _handleScrollNotification(ScrollNotification notification) {
    if (_warpUnderway)
      return false;

    final ScrollableState scrollable = notification.scrollable;
    if (scrollable.config.key != viewportKey)
      return false;

    switch(notification.kind) {
      case ScrollNotificationKind.started:
        _offsetAnchor = null;
        break;

      case ScrollNotificationKind.updated:
        if (!_controller.indexIsChanging) {
          _offsetAnchor ??= scrollable.scrollOffset;
          _controller.offset = (_offsetBias + scrollable.scrollOffset - _offsetAnchor).clamp(-1.0, 1.0);
        }
        break;

      // Either the the animation that follows a fling has completed and we've landed
      // on a new tab view, or a new pointer gesture has interrupted the fling
      // animation before it has completed.
      case ScrollNotificationKind.ended:
        final double integralScrollOffset = scrollable.scrollOffset.floorToDouble();
        if (integralScrollOffset == scrollable.scrollOffset) {
          _offsetBias = 0.0;
          // The animaion duration is short since the tab indicator and this
          // pageable list have already moved.
          _controller.animateTo(
            integralScrollOffset.floor(),
            duration: const Duration(milliseconds: 30)
          );
        } else {
          // The fling scroll animation was interrupted.
          _offsetBias = _controller.offset;
        }
        break;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return new NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: new _PageableTabBarView(
        key: viewportKey,
        children: _children,
      ),
    );
  }
}

/// TBD
///
class TabPageSelector extends StatelessWidget {
  /// TBD
  TabPageSelector({ Key key, this.controller }) : super(key: key);

  final TabController controller;

  Widget _buildTabIndicator(
    int tabIndex,
    TabController tabController,
    Animation<double> animation,
    ColorTween selectedColor,
    ColorTween previousColor,
  ) {
    Color background;
    if (tabController.indexIsChanging) {
      // The selection's animation is animating from previousValue to value.
      if (tabController.index == tabIndex)
        background = selectedColor.evaluate(animation);
      else if (tabController.previousIndex == tabIndex)
        background = previousColor.evaluate(animation);
      else
        background = selectedColor.begin;
    } else {
      background = tabController.index == tabIndex ? selectedColor.end : selectedColor.begin;
    }
    return new Container(
      width: 12.0,
      height: 12.0,
      margin: const EdgeInsets.all(4.0),
      decoration: new BoxDecoration(
        backgroundColor: background,
        border: new Border.all(color: selectedColor.end),
        shape: BoxShape.circle
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color color = Theme.of(context).accentColor;
    final ColorTween selectedColor = new ColorTween(begin: Colors.transparent, end: color);
    final ColorTween previousColor = new ColorTween(begin: color, end: Colors.transparent);
    TabController tabController = controller ?? DefaultTabController.of(context);
    Animation<double> animation = new CurvedAnimation(
      parent: tabController.animation,
      curve: Curves.fastOutSlowIn,
    );
    return new AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget child) {
        return new Semantics(
          label: 'Page ${controller.index + 1} of ${controller.length}',
          child: new Row(
            mainAxisSize: MainAxisSize.min,
            children: new List<Widget>.generate(controller.length, (int tabIndex) {
              return _buildTabIndicator(tabIndex, controller, animation, selectedColor, previousColor);
            }).toList(),
          ),
        );
      }
    );
  }
}
