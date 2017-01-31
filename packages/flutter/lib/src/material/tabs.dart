// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'app_bar.dart';
import 'colors.dart';
import 'constants.dart';
import 'debug.dart';
import 'icon_theme.dart';
import 'icon_theme_data.dart';
import 'ink_well.dart';
import 'material.dart';
import 'tab_controller.dart';
import 'theme.dart';

const double _kTabHeight = 46.0;
const double _kTextAndIconTabHeight = 72.0;
const double _kTabIndicatorHeight = 2.0;
const double _kMinTabWidth = 72.0;
const double _kMaxTabWidth = 264.0;
const EdgeInsets _kTabLabelPadding = const EdgeInsets.symmetric(horizontal: 12.0);

/// A material design [TabBar] tab. If both [icon] and [text] are
/// provided, the text is displayed below the icon.
///
/// See also:
///
///  * [TabBar], which displays a row of tabs.
///  * [TabBarView], which displays a widget for the currently selected tab.
///  * [TabController], which coordinates tab selection between a [TabBar] and a [TabBarView].
///  * <https://material.google.com/components/tabs.html>
class Tab extends StatelessWidget {
  /// Creates a material design [TabBar] tab. At least one of [text] and [icon]
  /// must be non-null.
  Tab({
    Key key,
    this.text,
    this.icon,
  }) : super(key: key) {
    assert(text != null || icon != null);
  }

  /// The text to display as the tab's label.
  final String text;

  /// An icon to display as the tab's label.
  final Widget icon;

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
    this.unselectedLabelColor,
    @required this.child,
  }) : super(key: key, animation: animation);

  final bool selected;
  final Color labelColor;
  final Color unselectedLabelColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final TextStyle textStyle = themeData.primaryTextTheme.body2;
    final Color selectedColor = labelColor ?? themeData.primaryTextTheme.body2.color;
    final Color unselectedColor = unselectedLabelColor ?? selectedColor.withAlpha(0xB2); // 70% alpha
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

double _indexChangeProgress(TabController controller) {
  if (!controller.indexIsChanging)
    return 1.0;

  final double controllerValue = controller.animation.value;
  final double previousIndex = controller.previousIndex.toDouble();
  final double currentIndex = controller.index.toDouble();
  if (controllerValue == previousIndex)
    return 0.0;
  else if (controllerValue == currentIndex)
    return 1.0;
  else
    return (controllerValue - previousIndex).abs() / (currentIndex - previousIndex).abs();
}

class _IndicatorPainter extends CustomPainter {
  _IndicatorPainter(this.controller) : super(repaint: controller.animation);

  TabController controller;
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
      final Rect targetRect = indicatorRect(size, controller.index);
      currentRect = Rect.lerp(currentRect ?? targetRect, targetRect, _indexChangeProgress(controller));
    } else {
      final int currentIndex = controller.index;
      final Rect left = currentIndex > 0 ? indicatorRect(size, currentIndex - 1) : null;
      final Rect middle = indicatorRect(size, currentIndex);
      final Rect right = currentIndex < maxTabIndex ? indicatorRect(size, currentIndex + 1) : null;

      final double index = controller.index.toDouble();
      final double value = controller.animation.value;
      if (value == index - 1.0)
        currentRect = left ?? middle;
      else if (value == index + 1.0)
        currentRect = right ?? middle;
      else if (value == index)
         currentRect = middle;
      else if (value < index)
        currentRect = left == null ? middle : Rect.lerp(middle, left, index - value);
      else
        currentRect = right == null ? middle : Rect.lerp(middle, right, value - index);
    }
    assert(currentRect != null);
    canvas.drawRect(currentRect, new Paint()..color = color);
  }

  static bool tabOffsetsNotEqual(List<double> a, List<double> b) {
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

class _ChangeAnimation extends Animation<double> with AnimationWithParentMixin<double> {
  _ChangeAnimation(this.controller);

  final TabController controller;

  @override
  Animation<double> get parent => controller.animation;

  @override
  double get value => _indexChangeProgress(controller);
}

/// A material design widget that displays a horizontal row of tabs. Typically
/// created as part of an [AppBar] and in conjuction with a [TabBarView].
///
/// If a [TabController] is not provided, then there must be a [DefaultTabController]
/// ancestor.
///
/// Requires one of its ancestors to be a [Material] widget
class TabBar extends StatefulWidget implements AppBarBottomWidget {
  TabBar({
    Key key,
    @required this.tabs,
    this.controller,
    this.isScrollable: false,
    this.indicatorColor,
    this.labelColor,
    this.unselectedLabelColor,
  }) : super(key: key) {
    assert(tabs != null && tabs.length > 1);
    assert(isScrollable != null);
  }

  /// Typically a list of [Tab] widgets.
  final List<Widget> tabs;

  /// This widget's selection and animation state.
  ///
  /// If [TabController] is not provided, then the value of [DefaultTabController.of]
  /// will be used.
  final TabController controller;

  /// Whether this tab bar can be scrolled horizontally.
  ///
  /// If [isScrollable] is true then each tab is as wide as needed for its label
  /// and the entire [TabBar] is scrollable. Otherwise each tab gets an equal
  /// share of the available space.
  final bool isScrollable;

  /// The color of the line that appears below the selected tab. If this parameter
  /// is null then the value of the Theme's indicatorColor property is used.
  final Color indicatorColor;

  /// The color of selected tab labels.
  ///
  /// Unselected tab labels are rendered with the same color rendered at 70%
  /// opacity unless [unselectedLabelColor] is non-null.
  ///
  /// If this parameter is null then the color of the theme's body2 text color
  /// is used.
  final Color labelColor;

  /// The color of unselected tab labels.
  ///
  /// If this property is null, Unselected tab labels are rendered with the
  /// [labelColor] rendered at 70% opacity.
  final Color unselectedLabelColor;

  @override
  double get bottomHeight {
    for (Widget widget in tabs) {
      if (widget is Tab) {
        final Tab tab = widget;
        if (tab.text != null && tab.icon != null)
          return _kTextAndIconTabHeight + _kTabIndicatorHeight;
      }
    }
    return _kTabHeight + _kTabIndicatorHeight;
  }

  @override
  _TabBarState createState() => new _TabBarState();
}

class _TabBarState extends State<TabBar> {
  final GlobalKey<ScrollableState> viewportKey = new GlobalKey<ScrollableState>();

  TabController _controller;
  _ChangeAnimation _changeAnimation;
  _IndicatorPainter _indicatorPainter;
  int _currentIndex;

  void _updateTabController() {
    TabController newController = config.controller ?? DefaultTabController.of(context);
    if (newController == _controller)
      return;

    if (_controller != null)
      _controller.animation.removeListener(_handleTick);
    _controller = newController;
    if (_controller != null) {
      _controller.animation.addListener(_handleTick);
      _changeAnimation = new _ChangeAnimation(_controller);
      _currentIndex = _controller.index;
      final List<double> offsets = _indicatorPainter?.tabOffsets;
      _indicatorPainter = new _IndicatorPainter(_controller)..tabOffsets = offsets;
    }
  }

  @override
  void dependenciesChanged() {
    super.dependenciesChanged();
    _updateTabController();
  }

  @override
  void didUpdateConfig(TabBar oldConfig) {
    super.didUpdateConfig(oldConfig);
    if (config.controller != oldConfig.controller)
      _updateTabController();
  }

  @override
  void dispose() {
    if (_controller != null)
      _controller.animation.removeListener(_handleTick);
    // We don't own the _controller Animation, so it's not disposed here.
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

  void _scrollToCurrentIndex() {
    final ScrollableState viewport = viewportKey.currentState;
    final double offset = _tabCenteredScrollOffset(viewport, _currentIndex);
    viewport.scrollTo(offset, duration: kTabScrollDuration);
  }

  void _scrollToControllerValue() {
    final ScrollableState viewport = viewportKey.currentState;
    final double left = _currentIndex > 0 ? _tabCenteredScrollOffset(viewport, _currentIndex - 1) : null;
    final double middle = _tabCenteredScrollOffset(viewport, _currentIndex);
    final double right = _currentIndex < maxTabIndex ? _tabCenteredScrollOffset(viewport, _currentIndex + 1) : null;

    final double index = _controller.index.toDouble();
    final double value = _controller.animation.value;
    double offset;
    if (value == index - 1.0)
      offset = left ?? middle;
    else if (value == index + 1.0)
      offset = right ?? middle;
    else if (value == index)
       offset = middle;
    else if (value < index)
      offset = left == null ? middle : lerpDouble(middle, left, index - value);
    else
      offset = right == null ? middle : lerpDouble(middle, right, value - index);

    viewport.scrollTo(offset);
  }

  void _handleTick() {
    assert(mounted);

    if (_controller.indexIsChanging) {
      setState(() {
        // Rebuild so that the tab label colors reflect the selected tab index.
        // The first build for a new _controller.index value will also trigger
        // a scroll to center the selected tab.
      });
    } else if (config.isScrollable) {
      _scrollToControllerValue();
    }
  }

  void _saveTabOffsets(List<double> tabOffsets) {
    _indicatorPainter?.tabOffsets = tabOffsets;
  }

  void _handleTap(int index) {
    assert(index >= 0 && index < config.tabs.length);
    _controller.animateTo(index);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> wrappedTabs = new List<Widget>.from(config.tabs, growable: false);

    // If the controller was provided by DefaultTabController and we're part
    // of a Hero (typically the AppBar), then we will not be able to find the
    // controller during a Hero transition. See https://github.com/flutter/flutter/issues/213.
    if (_controller != null) {
      _indicatorPainter.color = config.indicatorColor ?? Theme.of(context).indicatorColor;
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
          _scrollToCurrentIndex();
      }

      final int previousIndex = _controller.previousIndex;

      if (_controller.indexIsChanging) {
        assert(_currentIndex != previousIndex);
        wrappedTabs[_currentIndex] = new _TabStyle(
          animation: _changeAnimation,
          selected: true,
          labelColor: config.labelColor,
          unselectedLabelColor: config.unselectedLabelColor,
          child: wrappedTabs[_currentIndex],
        );
        wrappedTabs[previousIndex] = new _TabStyle(
          animation: _changeAnimation,
          selected: false,
          labelColor: config.labelColor,
          unselectedLabelColor: config.unselectedLabelColor,
          child: wrappedTabs[previousIndex],
        );
      } else {
        wrappedTabs[_currentIndex] = new _TabStyle(
          animation: kAlwaysCompleteAnimation,
          selected: true,
          labelColor: config.labelColor,
          unselectedLabelColor: config.unselectedLabelColor,
          child: wrappedTabs[_currentIndex],
        );
      }
    }

    // Add the tap handler to each tab. If the tab bar is scrollable
    // then give all of the tabs equal flexibility so that their widths
    // reflect the intrinsic width of their labels.
    for (int index = 0; index < config.tabs.length; index++) {
      wrappedTabs[index] = new InkWell(
        onTap: () { _handleTap(index); },
        child: wrappedTabs[index],
      );
      if (!config.isScrollable)
        wrappedTabs[index] = new Expanded(child: wrappedTabs[index]);
    }

    Widget tabBar = new CustomPaint(
      painter: _indicatorPainter,
      child: new Padding(
        padding: const EdgeInsets.only(bottom: _kTabIndicatorHeight),
        child: new _TabStyle(
          animation: kAlwaysCompleteAnimation,
          selected: false,
          labelColor: config.labelColor,
          unselectedLabelColor: config.unselectedLabelColor,
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

class _PageableTabBarView extends PageableList {
  _PageableTabBarView({
    Key key,
    List<Widget> children,
    double initialScrollOffset: 0.0,
  }) : super(
    key: key,
    scrollDirection: Axis.horizontal,
    children: children,
    initialScrollOffset: initialScrollOffset,
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

/// A pageable list that displays the widget which corresponds to the currently
/// selected tab. Typically used in conjuction with a [TabBar].
///
/// If a [TabController] is not provided, then there must be a [DefaultTabController]
/// ancestor.
class TabBarView extends StatefulWidget {
  /// Creates a pageable list with one child per tab.
  ///
  /// The length of [children] must be the same as the [controller]'s length.
  TabBarView({
    Key key,
    @required this.children,
    this.controller,
  }) : super(key: key) {
    assert(children != null && children.length > 1);
  }

  /// This widget's selection and animation state.
  ///
  /// If [TabController] is not provided, then the value of [DefaultTabController.of]
  /// will be used.
  final TabController controller;

  /// One widget per tab.
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
  int _warpUnderwayCount = 0;

  void _updateTabController() {
    TabController newController = config.controller ?? DefaultTabController.of(context);
    if (newController == _controller)
      return;

    if (_controller != null)
      _controller.animation.removeListener(_handleTick);
    _controller = newController;
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
    _updateTabController();
    _currentIndex = _controller?.index;
  }

  @override
  void didUpdateConfig(TabBarView oldConfig) {
    super.didUpdateConfig(oldConfig);
    if (config.controller != oldConfig.controller)
      _updateTabController();
    if (config.children != oldConfig.children && _warpUnderwayCount == 0)
      _children = config.children;
  }

  @override
  void dispose() {
    if (_controller != null)
      _controller.animation.removeListener(_handleTick);
    // We don't own the _controller Animation, so it's not disposed here.
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
    if (!mounted)
      return new Future<Null>.value();

    final ScrollableState viewport = viewportKey.currentState;
    if (viewport.scrollOffset == _currentIndex.toDouble())
      return new Future<Null>.value();

    final int previousIndex = _controller.previousIndex;
    if ((_currentIndex - previousIndex).abs() == 1)
      return viewport.scrollTo(_currentIndex.toDouble(), duration: kTabScrollDuration);

    assert((_currentIndex - previousIndex).abs() > 1);
    double initialScroll;
    setState(() {
      _warpUnderwayCount += 1;
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
    if (!mounted)
      return new Future<Null>.value();

    await viewport.scrollTo(_currentIndex.toDouble(), duration: kTabScrollDuration);
    if (!mounted)
      return new Future<Null>.value();

    setState(() {
      _warpUnderwayCount -= 1;
      _children = config.children;
    });
  }

  // Called when the _PageableTabBarView scrolls
  bool _handleScrollNotification(ScrollNotification notification) {
    if (_warpUnderwayCount > 0)
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
          // The animation duration is short since the tab indicator and this
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
        initialScrollOffset: (_controller?.index ?? 0).toDouble(),
      ),
    );
  }
}

/// Displays a row of small circular indicators, one per tab. The selected
/// tab's indicator is highlighted. Often used in conjuction with a [TabBarView].
///
/// If a [TabController] is not provided, then there must be a [DefaultTabController]
/// ancestor.
class TabPageSelector extends StatelessWidget {
  /// Creates a compact widget that indicates which tab has been selected.
  TabPageSelector({ Key key, this.controller }) : super(key: key);

  /// This widget's selection and animation state.
  ///
  /// If [TabController] is not provided, then the value of [DefaultTabController.of]
  /// will be used.
  final TabController controller;

  Widget _buildTabIndicator(
    int tabIndex,
    TabController tabController,
    ColorTween selectedColor,
    ColorTween previousColor,
  ) {
    Color background;
    if (tabController.indexIsChanging) {
      // The selection's animation is animating from previousValue to value.
      if (tabController.index == tabIndex)
        background = selectedColor.lerp(_indexChangeProgress(tabController));
      else if (tabController.previousIndex == tabIndex)
        background = previousColor.lerp(_indexChangeProgress(tabController));
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
    final TabController tabController = controller ?? DefaultTabController.of(context);
    assert(tabController != null);
    final Animation<double> animation = new CurvedAnimation(
      parent: tabController.animation,
      curve: Curves.fastOutSlowIn,
    );
    return new AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget child) {
        return new Semantics(
          label: 'Page ${tabController.index + 1} of ${tabController.length}',
          child: new Row(
            mainAxisSize: MainAxisSize.min,
            children: new List<Widget>.generate(tabController.length, (int tabIndex) {
              return _buildTabIndicator(tabIndex, tabController, selectedColor, previousColor);
            }).toList(),
          ),
        );
      }
    );
  }
}
