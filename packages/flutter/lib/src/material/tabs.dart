// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/gestures.dart' show DragStartBehavior;

import 'app_bar.dart';
import 'colors.dart';
import 'constants.dart';
import 'debug.dart';
import 'ink_well.dart';
import 'material.dart';
import 'material_localizations.dart';
import 'tab_bar_theme.dart';
import 'tab_controller.dart';
import 'tab_indicator.dart';
import 'theme.dart';

const double _kTabHeight = 46.0;
const double _kTextAndIconTabHeight = 72.0;

/// Defines how the bounds of the selected tab indicator are computed.
///
/// See also:
///
///  * [TabBar], which displays a row of tabs.
///  * [TabBarView], which displays a widget for the currently selected tab.
///  * [TabBar.indicator], which defines the appearance of the selected tab
///    indicator relative to the tab's bounds.
enum TabBarIndicatorSize {
  /// The tab indicator's bounds are as wide as the space occupied by the tab
  /// in the tab bar: from the right edge of the previous tab to the left edge
  /// of the next tab.
  tab,

  /// The tab's bounds are only as wide as the (centered) tab widget itself.
  ///
  /// This value is used to align the tab's label, typically a [Tab]
  /// widget's text or icon, with the selected tab indicator.
  label,
}

/// A material design [TabBar] tab.
///
/// If both [icon] and [text] are provided, the text is displayed below
/// the icon.
///
/// See also:
///
///  * [TabBar], which displays a row of tabs.
///  * [TabBarView], which displays a widget for the currently selected tab.
///  * [TabController], which coordinates tab selection between a [TabBar] and a [TabBarView].
///  * <https://material.io/design/components/tabs.html>
class Tab extends StatelessWidget {
  /// Creates a material design [TabBar] tab.
  ///
  /// At least one of [text], [icon], and [child] must be non-null. The [text]
  /// and [child] arguments must not be used at the same time.
  const Tab({
    Key key,
    this.text,
    this.icon,
    this.child,
  }) : assert(text != null || child != null || icon != null),
       assert(!(text != null && null != child)), // TODO(goderbauer): https://github.com/dart-lang/sdk/issues/34180
       super(key: key);

  /// The text to display as the tab's label.
  ///
  /// Must not be used in combination with [child].
  final String text;

  /// The widget to be used as the tab's label.
  ///
  /// Usually a [Text] widget, possibly wrapped in a [Semantics] widget.
  ///
  /// Must not be used in combination with [text].
  final Widget child;

  /// An icon to display as the tab's label.
  final Widget icon;

  Widget _buildLabelText() {
    return child ?? Text(text, softWrap: false, overflow: TextOverflow.fade);
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));

    double height;
    Widget label;
    if (icon == null) {
      height = _kTabHeight;
      label = _buildLabelText();
    } else if (text == null && child == null) {
      height = _kTabHeight;
      label = icon;
    } else {
      height = _kTextAndIconTabHeight;
      label = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            child: icon,
            margin: const EdgeInsets.only(bottom: 10.0),
          ),
          _buildLabelText(),
        ],
      );
    }

    return SizedBox(
      height: height,
      child: Center(
        child: label,
        widthFactor: 1.0,
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('text', text, defaultValue: null));
    properties.add(DiagnosticsProperty<Widget>('icon', icon, defaultValue: null));
  }
}

class _TabStyle extends AnimatedWidget {
  const _TabStyle({
    Key key,
    Animation<double> animation,
    this.selected,
    this.labelColor,
    this.unselectedLabelColor,
    this.labelStyle,
    this.unselectedLabelStyle,
    @required this.child,
  }) : super(key: key, listenable: animation);

  final TextStyle labelStyle;
  final TextStyle unselectedLabelStyle;
  final bool selected;
  final Color labelColor;
  final Color unselectedLabelColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final TabBarTheme tabBarTheme = TabBarTheme.of(context);
    final Animation<double> animation = listenable;

    // To enable TextStyle.lerp(style1, style2, value), both styles must have
    // the same value of inherit. Force that to be inherit=true here.
    final TextStyle defaultStyle = (labelStyle
      ?? tabBarTheme.labelStyle
      ?? themeData.primaryTextTheme.body2
    ).copyWith(inherit: true);
    final TextStyle defaultUnselectedStyle = (unselectedLabelStyle
      ?? tabBarTheme.unselectedLabelStyle
      ?? labelStyle
      ?? themeData.primaryTextTheme.body2
    ).copyWith(inherit: true);
    final TextStyle textStyle = selected
      ? TextStyle.lerp(defaultStyle, defaultUnselectedStyle, animation.value)
      : TextStyle.lerp(defaultUnselectedStyle, defaultStyle, animation.value);

    final Color selectedColor = labelColor
       ?? tabBarTheme.labelColor
       ?? themeData.primaryTextTheme.body2.color;
    final Color unselectedColor = unselectedLabelColor
      ?? tabBarTheme.unselectedLabelColor
      ?? selectedColor.withAlpha(0xB2); // 70% alpha
    final Color color = selected
      ? Color.lerp(selectedColor, unselectedColor, animation.value)
      : Color.lerp(unselectedColor, selectedColor, animation.value);

    return DefaultTextStyle(
      style: textStyle.copyWith(color: color),
      child: IconTheme.merge(
        data: IconThemeData(
          size: 24.0,
          color: color,
        ),
        child: child,
      ),
    );
  }
}

typedef _LayoutCallback = void Function(List<double> xOffsets, TextDirection textDirection, double width);

class _TabLabelBarRenderer extends RenderFlex {
  _TabLabelBarRenderer({
    List<RenderBox> children,
    @required Axis direction,
    @required MainAxisSize mainAxisSize,
    @required MainAxisAlignment mainAxisAlignment,
    @required CrossAxisAlignment crossAxisAlignment,
    @required TextDirection textDirection,
    @required VerticalDirection verticalDirection,
    @required this.onPerformLayout,
  }) : assert(onPerformLayout != null),
       assert(textDirection != null),
       super(
         children: children,
         direction: direction,
         mainAxisSize: mainAxisSize,
         mainAxisAlignment: mainAxisAlignment,
         crossAxisAlignment: crossAxisAlignment,
         textDirection: textDirection,
         verticalDirection: verticalDirection,
       );

  _LayoutCallback onPerformLayout;

  @override
  void performLayout() {
    super.performLayout();
    // xOffsets will contain childCount+1 values, giving the offsets of the
    // leading edge of the first tab as the first value, of the leading edge of
    // the each subsequent tab as each subsequent value, and of the trailing
    // edge of the last tab as the last value.
    RenderBox child = firstChild;
    final List<double> xOffsets = <double>[];
    while (child != null) {
      final FlexParentData childParentData = child.parentData;
      xOffsets.add(childParentData.offset.dx);
      assert(child.parentData == childParentData);
      child = childParentData.nextSibling;
    }
    assert(textDirection != null);
    switch (textDirection) {
      case TextDirection.rtl:
        xOffsets.insert(0, size.width);
        break;
      case TextDirection.ltr:
        xOffsets.add(size.width);
        break;
    }
    onPerformLayout(xOffsets, textDirection, size.width);
  }
}

// This class and its renderer class only exist to report the widths of the tabs
// upon layout. The tab widths are only used at paint time (see _IndicatorPainter)
// or in response to input.
class _TabLabelBar extends Flex {
  _TabLabelBar({
    Key key,
    List<Widget> children = const <Widget>[],
    this.onPerformLayout,
  }) : super(
    key: key,
    children: children,
    direction: Axis.horizontal,
    mainAxisSize: MainAxisSize.max,
    mainAxisAlignment: MainAxisAlignment.start,
    crossAxisAlignment: CrossAxisAlignment.center,
    verticalDirection: VerticalDirection.down,
  );

  final _LayoutCallback onPerformLayout;

  @override
  RenderFlex createRenderObject(BuildContext context) {
    return _TabLabelBarRenderer(
      direction: direction,
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      crossAxisAlignment: crossAxisAlignment,
      textDirection: getEffectiveTextDirection(context),
      verticalDirection: verticalDirection,
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
  final double controllerValue = controller.animation.value;
  final double previousIndex = controller.previousIndex.toDouble();
  final double currentIndex = controller.index.toDouble();

  // The controller's offset is changing because the user is dragging the
  // TabBarView's PageView to the left or right.
  if (!controller.indexIsChanging)
    return (currentIndex - controllerValue).abs().clamp(0.0, 1.0);

  // The TabController animation's value is changing from previousIndex to currentIndex.
  return (controllerValue - currentIndex).abs() / (currentIndex - previousIndex).abs();
}

class _IndicatorPainter extends CustomPainter {
  _IndicatorPainter({
    @required this.controller,
    @required this.indicator,
    @required this.indicatorSize,
    @required this.tabKeys,
    _IndicatorPainter old,
  }) : assert(controller != null),
       assert(indicator != null),
       super(repaint: controller.animation) {
    if (old != null)
      saveTabOffsets(old._currentTabOffsets, old._currentTextDirection);
  }

  final TabController controller;
  final Decoration indicator;
  final TabBarIndicatorSize indicatorSize;
  final List<GlobalKey> tabKeys;

  List<double> _currentTabOffsets;
  TextDirection _currentTextDirection;
  Rect _currentRect;
  BoxPainter _painter;
  bool _needsPaint = false;
  void markNeedsPaint() {
    _needsPaint = true;
  }

  void dispose() {
    _painter?.dispose();
  }

  void saveTabOffsets(List<double> tabOffsets, TextDirection textDirection) {
    _currentTabOffsets = tabOffsets;
    _currentTextDirection = textDirection;
  }

  // _currentTabOffsets[index] is the offset of the start edge of the tab at index, and
  // _currentTabOffsets[_currentTabOffsets.length] is the end edge of the last tab.
  int get maxTabIndex => _currentTabOffsets.length - 2;

  double centerOf(int tabIndex) {
    assert(_currentTabOffsets != null);
    assert(_currentTabOffsets.isNotEmpty);
    assert(tabIndex >= 0);
    assert(tabIndex <= maxTabIndex);
    return (_currentTabOffsets[tabIndex] + _currentTabOffsets[tabIndex + 1]) / 2.0;
  }

  Rect indicatorRect(Size tabBarSize, int tabIndex) {
    assert(_currentTabOffsets != null);
    assert(_currentTextDirection != null);
    assert(_currentTabOffsets.isNotEmpty);
    assert(tabIndex >= 0);
    assert(tabIndex <= maxTabIndex);
    double tabLeft, tabRight;
    switch (_currentTextDirection) {
      case TextDirection.rtl:
        tabLeft = _currentTabOffsets[tabIndex + 1];
        tabRight = _currentTabOffsets[tabIndex];
        break;
      case TextDirection.ltr:
        tabLeft = _currentTabOffsets[tabIndex];
        tabRight = _currentTabOffsets[tabIndex + 1];
        break;
    }

    if (indicatorSize == TabBarIndicatorSize.label) {
      final double tabWidth = tabKeys[tabIndex].currentContext.size.width;
      final double delta = ((tabRight - tabLeft) - tabWidth) / 2.0;
      tabLeft += delta;
      tabRight -= delta;
    }

    return Rect.fromLTWH(tabLeft, 0.0, tabRight - tabLeft, tabBarSize.height);
  }

  @override
  void paint(Canvas canvas, Size size) {
    _needsPaint = false;
    _painter ??= indicator.createBoxPainter(markNeedsPaint);

    if (controller.indexIsChanging) {
      // The user tapped on a tab, the tab controller's animation is running.
      final Rect targetRect = indicatorRect(size, controller.index);
      _currentRect = Rect.lerp(targetRect, _currentRect ?? targetRect, _indexChangeProgress(controller));
    } else {
      // The user is dragging the TabBarView's PageView left or right.
      final int currentIndex = controller.index;
      final Rect previous = currentIndex > 0 ? indicatorRect(size, currentIndex - 1) : null;
      final Rect middle = indicatorRect(size, currentIndex);
      final Rect next = currentIndex < maxTabIndex ? indicatorRect(size, currentIndex + 1) : null;
      final double index = controller.index.toDouble();
      final double value = controller.animation.value;
      if (value == index - 1.0)
        _currentRect = previous ?? middle;
      else if (value == index + 1.0)
        _currentRect = next ?? middle;
      else if (value == index)
        _currentRect = middle;
      else if (value < index)
        _currentRect = previous == null ? middle : Rect.lerp(middle, previous, index - value);
      else
        _currentRect = next == null ? middle : Rect.lerp(middle, next, value - index);
    }
    assert(_currentRect != null);

    final ImageConfiguration configuration = ImageConfiguration(
      size: _currentRect.size,
      textDirection: _currentTextDirection,
    );
    _painter.paint(canvas, _currentRect.topLeft, configuration);
  }

  static bool _tabOffsetsEqual(List<double> a, List<double> b) {
    // TODO(shihaohong): The following null check should be replaced when a fix
    // for https://github.com/flutter/flutter/issues/40014 is available.
    if (a == null || b == null || a.length != b.length)
      return false;
    for (int i = 0; i < a.length; i += 1) {
      if (a[i] != b[i])
        return false;
    }
    return true;
  }

  @override
  bool shouldRepaint(_IndicatorPainter old) {
    return _needsPaint
        || controller != old.controller
        || indicator != old.indicator
        || tabKeys.length != old.tabKeys.length
        || (!_tabOffsetsEqual(_currentTabOffsets, old._currentTabOffsets))
        || _currentTextDirection != old._currentTextDirection;
  }
}

class _ChangeAnimation extends Animation<double> with AnimationWithParentMixin<double> {
  _ChangeAnimation(this.controller);

  final TabController controller;

  @override
  Animation<double> get parent => controller.animation;

  @override
  void removeStatusListener(AnimationStatusListener listener) {
    if (parent != null)
      super.removeStatusListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    if (parent != null)
      super.removeListener(listener);
  }

  @override
  double get value => _indexChangeProgress(controller);
}

class _DragAnimation extends Animation<double> with AnimationWithParentMixin<double> {
  _DragAnimation(this.controller, this.index);

  final TabController controller;
  final int index;

  @override
  Animation<double> get parent => controller.animation;

  @override
  void removeStatusListener(AnimationStatusListener listener) {
    if (parent != null)
      super.removeStatusListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    if (parent != null)
      super.removeListener(listener);
  }

  @override
  double get value {
    assert(!controller.indexIsChanging);
    return (controller.animation.value - index.toDouble()).abs().clamp(0.0, 1.0);
  }
}

// This class, and TabBarScrollController, only exist to handle the case
// where a scrollable TabBar has a non-zero initialIndex. In that case we can
// only compute the scroll position's initial scroll offset (the "correct"
// pixels value) after the TabBar viewport width and scroll limits are known.
class _TabBarScrollPosition extends ScrollPositionWithSingleContext {
  _TabBarScrollPosition({
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition oldPosition,
    this.tabBar,
  }) : super(
    physics: physics,
    context: context,
    initialPixels: null,
    oldPosition: oldPosition,
  );

  final _TabBarState tabBar;

  bool _initialViewportDimensionWasZero;

  @override
  bool applyContentDimensions(double minScrollExtent, double maxScrollExtent) {
    bool result = true;
    if (_initialViewportDimensionWasZero != true) {
      // If the viewport never had a non-zero dimension, we just want to jump
      // to the initial scroll position to avoid strange scrolling effects in
      // release mode: In release mode, the viewport temporarily may have a
      // dimension of zero before the actual dimension is calculated. In that
      // scenario, setting the actual dimension would cause a strange scroll
      // effect without this guard because the super call below would starts a
      // ballistic scroll activity.
      assert(viewportDimension != null);
      _initialViewportDimensionWasZero = viewportDimension != 0.0;
      correctPixels(tabBar._initialScrollOffset(viewportDimension, minScrollExtent, maxScrollExtent));
      result = false;
    }
    return super.applyContentDimensions(minScrollExtent, maxScrollExtent) && result;
  }
}

// This class, and TabBarScrollPosition, only exist to handle the case
// where a scrollable TabBar has a non-zero initialIndex.
class _TabBarScrollController extends ScrollController {
  _TabBarScrollController(this.tabBar);

  final _TabBarState tabBar;

  @override
  ScrollPosition createScrollPosition(ScrollPhysics physics, ScrollContext context, ScrollPosition oldPosition) {
    return _TabBarScrollPosition(
      physics: physics,
      context: context,
      oldPosition: oldPosition,
      tabBar: tabBar,
    );
  }
}

/// A material design widget that displays a horizontal row of tabs.
///
/// Typically created as the [AppBar.bottom] part of an [AppBar] and in
/// conjunction with a [TabBarView].
///
/// If a [TabController] is not provided, then a [DefaultTabController] ancestor
/// must be provided instead. The tab controller's [TabController.length] must
/// equal the length of the [tabs] list and the length of the
/// [TabBarView.children] list.
///
/// Requires one of its ancestors to be a [Material] widget.
///
/// Uses values from [TabBarTheme] if it is set in the current context.
///
/// To see a sample implementation, visit the [TabController] documentation.
///
/// See also:
///
///  * [TabBarView], which displays page views that correspond to each tab.
class TabBar extends StatefulWidget implements PreferredSizeWidget {
  /// Creates a material design tab bar.
  ///
  /// The [tabs] argument must not be null and its length must match the [controller]'s
  /// [TabController.length].
  ///
  /// If a [TabController] is not provided, then there must be a
  /// [DefaultTabController] ancestor.
  ///
  /// The [indicatorWeight] parameter defaults to 2, and must not be null.
  ///
  /// The [indicatorPadding] parameter defaults to [EdgeInsets.zero], and must not be null.
  ///
  /// If [indicator] is not null, then [indicatorWeight], [indicatorPadding], and
  /// [indicatorColor] are ignored.
  const TabBar({
    Key key,
    @required this.tabs,
    this.controller,
    this.isScrollable = false,
    this.indicatorColor,
    this.indicatorWeight = 2.0,
    this.indicatorPadding = EdgeInsets.zero,
    this.indicator,
    this.indicatorSize,
    this.labelColor,
    this.labelStyle,
    this.labelPadding,
    this.unselectedLabelColor,
    this.unselectedLabelStyle,
    this.dragStartBehavior = DragStartBehavior.start,
    this.onTap,
  }) : assert(tabs != null),
       assert(isScrollable != null),
       assert(dragStartBehavior != null),
       assert(indicator != null || (indicatorWeight != null && indicatorWeight > 0.0)),
       assert(indicator != null || (indicatorPadding != null)),
       super(key: key);

  /// Typically a list of two or more [Tab] widgets.
  ///
  /// The length of this list must match the [controller]'s [TabController.length]
  /// and the length of the [TabBarView.children] list.
  final List<Widget> tabs;

  /// This widget's selection and animation state.
  ///
  /// If [TabController] is not provided, then the value of [DefaultTabController.of]
  /// will be used.
  final TabController controller;

  /// Whether this tab bar can be scrolled horizontally.
  ///
  /// If [isScrollable] is true, then each tab is as wide as needed for its label
  /// and the entire [TabBar] is scrollable. Otherwise each tab gets an equal
  /// share of the available space.
  final bool isScrollable;

  /// The color of the line that appears below the selected tab.
  ///
  /// If this parameter is null, then the value of the Theme's indicatorColor
  /// property is used.
  ///
  /// If [indicator] is specified, this property is ignored.
  final Color indicatorColor;

  /// The thickness of the line that appears below the selected tab.
  ///
  /// The value of this parameter must be greater than zero and its default
  /// value is 2.0.
  ///
  /// If [indicator] is specified, this property is ignored.
  final double indicatorWeight;

  /// The horizontal padding for the line that appears below the selected tab.
  ///
  /// For [isScrollable] tab bars, specifying [kTabLabelPadding] will align
  /// the indicator with the tab's text for [Tab] widgets and all but the
  /// shortest [Tab.text] values.
  ///
  /// The [EdgeInsets.top] and [EdgeInsets.bottom] values of the
  /// [indicatorPadding] are ignored.
  ///
  /// The default value of [indicatorPadding] is [EdgeInsets.zero].
  ///
  /// If [indicator] is specified, this property is ignored.
  final EdgeInsetsGeometry indicatorPadding;

  /// Defines the appearance of the selected tab indicator.
  ///
  /// If [indicator] is specified, the [indicatorColor], [indicatorWeight],
  /// and [indicatorPadding] properties are ignored.
  ///
  /// The default, underline-style, selected tab indicator can be defined with
  /// [UnderlineTabIndicator].
  ///
  /// The indicator's size is based on the tab's bounds. If [indicatorSize]
  /// is [TabBarIndicatorSize.tab] the tab's bounds are as wide as the space
  /// occupied by the tab in the tab bar. If [indicatorSize] is
  /// [TabBarIndicatorSize.label], then the tab's bounds are only as wide as
  /// the tab widget itself.
  final Decoration indicator;

  /// Defines how the selected tab indicator's size is computed.
  ///
  /// The size of the selected tab indicator is defined relative to the
  /// tab's overall bounds if [indicatorSize] is [TabBarIndicatorSize.tab]
  /// (the default) or relative to the bounds of the tab's widget if
  /// [indicatorSize] is [TabBarIndicatorSize.label].
  ///
  /// The selected tab's location appearance can be refined further with
  /// the [indicatorColor], [indicatorWeight], [indicatorPadding], and
  /// [indicator] properties.
  final TabBarIndicatorSize indicatorSize;

  /// The color of selected tab labels.
  ///
  /// Unselected tab labels are rendered with the same color rendered at 70%
  /// opacity unless [unselectedLabelColor] is non-null.
  ///
  /// If this parameter is null, then the color of the [ThemeData.primaryTextTheme]'s
  /// body2 text color is used.
  final Color labelColor;

  /// The color of unselected tab labels.
  ///
  /// If this property is null, unselected tab labels are rendered with the
  /// [labelColor] with 70% opacity.
  final Color unselectedLabelColor;

  /// The text style of the selected tab labels.
  ///
  /// If [unselectedLabelStyle] is null, then this text style will be used for
  /// both selected and unselected label styles.
  ///
  /// If this property is null, then the text style of the
  /// [ThemeData.primaryTextTheme]'s body2 definition is used.
  final TextStyle labelStyle;

  /// The padding added to each of the tab labels.
  ///
  /// If this property is null, then kTabLabelPadding is used.
  final EdgeInsetsGeometry labelPadding;

  /// The text style of the unselected tab labels
  ///
  /// If this property is null, then the [labelStyle] value is used. If [labelStyle]
  /// is null, then the text style of the [ThemeData.primaryTextTheme]'s
  /// body2 definition is used.
  final TextStyle unselectedLabelStyle;

  /// {@macro flutter.widgets.scrollable.dragStartBehavior}
  final DragStartBehavior dragStartBehavior;

  /// An optional callback that's called when the [TabBar] is tapped.
  ///
  /// The callback is applied to the index of the tab where the tap occurred.
  ///
  /// This callback has no effect on the default handling of taps. It's for
  /// applications that want to do a little extra work when a tab is tapped,
  /// even if the tap doesn't change the TabController's index. TabBar [onTap]
  /// callbacks should not make changes to the TabController since that would
  /// interfere with the default tap handler.
  final ValueChanged<int> onTap;

  /// A size whose height depends on if the tabs have both icons and text.
  ///
  /// [AppBar] uses this this size to compute its own preferred size.
  @override
  Size get preferredSize {
    for (Widget item in tabs) {
      if (item is Tab) {
        final Tab tab = item;
        if (tab.text != null && tab.icon != null)
          return Size.fromHeight(_kTextAndIconTabHeight + indicatorWeight);
      }
    }
    return Size.fromHeight(_kTabHeight + indicatorWeight);
  }

  @override
  _TabBarState createState() => _TabBarState();
}

class _TabBarState extends State<TabBar> {
  ScrollController _scrollController;
  TabController _controller;
  _IndicatorPainter _indicatorPainter;
  int _currentIndex;
  double _tabStripWidth;
  List<GlobalKey> _tabKeys;

  @override
  void initState() {
    super.initState();
    // If indicatorSize is TabIndicatorSize.label, _tabKeys[i] is used to find
    // the width of tab widget i. See _IndicatorPainter.indicatorRect().
    _tabKeys = widget.tabs.map((Widget tab) => GlobalKey()).toList();
  }

  Decoration get _indicator {
    if (widget.indicator != null)
      return widget.indicator;
    final TabBarTheme tabBarTheme = TabBarTheme.of(context);
    if (tabBarTheme.indicator != null)
      return tabBarTheme.indicator;

    Color color = widget.indicatorColor ?? Theme.of(context).indicatorColor;
    // ThemeData tries to avoid this by having indicatorColor avoid being the
    // primaryColor. However, it's possible that the tab bar is on a
    // Material that isn't the primaryColor. In that case, if the indicator
    // color ends up matching the material's color, then this overrides it.
    // When that happens, automatic transitions of the theme will likely look
    // ugly as the indicator color suddenly snaps to white at one end, but it's
    // not clear how to avoid that any further.
    //
    // The material's color might be null (if it's a transparency). In that case
    // there's no good way for us to find out what the color is so we don't.
    if (color.value == Material.of(context).color?.value)
      color = Colors.white;

    return UnderlineTabIndicator(
      insets: widget.indicatorPadding,
      borderSide: BorderSide(
        width: widget.indicatorWeight,
        color: color,
      ),
    );
  }

  // If the TabBar is rebuilt with a new tab controller, the caller should
  // dispose the old one. In that case the old controller's animation will be
  // null and should not be accessed.
  bool get _controllerIsValid => _controller?.animation != null;

  void _updateTabController() {
    final TabController newController = widget.controller ?? DefaultTabController.of(context);
    assert(() {
      if (newController == null) {
        throw FlutterError(
          'No TabController for ${widget.runtimeType}.\n'
          'When creating a ${widget.runtimeType}, you must either provide an explicit '
          'TabController using the "controller" property, or you must ensure that there '
          'is a DefaultTabController above the ${widget.runtimeType}.\n'
          'In this case, there was neither an explicit controller nor a default controller.'
        );
      }
      return true;
    }());

    if (newController == _controller)
      return;

    if (_controllerIsValid) {
      _controller.animation.removeListener(_handleTabControllerAnimationTick);
      _controller.removeListener(_handleTabControllerTick);
    }
    _controller = newController;
    if (_controller != null) {
      _controller.animation.addListener(_handleTabControllerAnimationTick);
      _controller.addListener(_handleTabControllerTick);
      _currentIndex = _controller.index;
    }
  }

  void _initIndicatorPainter() {
    _indicatorPainter = !_controllerIsValid ? null : _IndicatorPainter(
      controller: _controller,
      indicator: _indicator,
      indicatorSize: widget.indicatorSize ?? TabBarTheme.of(context).indicatorSize,
      tabKeys: _tabKeys,
      old: _indicatorPainter,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    assert(debugCheckHasMaterial(context));
    _updateTabController();
    _initIndicatorPainter();
  }

  @override
  void didUpdateWidget(TabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _updateTabController();
      _initIndicatorPainter();
    } else if (widget.indicatorColor != oldWidget.indicatorColor ||
        widget.indicatorWeight != oldWidget.indicatorWeight ||
        widget.indicatorSize != oldWidget.indicatorSize ||
        widget.indicator != oldWidget.indicator) {
      _initIndicatorPainter();
    }

    if (widget.tabs.length > oldWidget.tabs.length) {
      final int delta = widget.tabs.length - oldWidget.tabs.length;
      _tabKeys.addAll(List<GlobalKey>.generate(delta, (int n) => GlobalKey()));
    } else if (widget.tabs.length < oldWidget.tabs.length) {
      _tabKeys.removeRange(widget.tabs.length, oldWidget.tabs.length);
    }
  }

  @override
  void dispose() {
    _indicatorPainter.dispose();
    if (_controllerIsValid) {
      _controller.animation.removeListener(_handleTabControllerAnimationTick);
      _controller.removeListener(_handleTabControllerTick);
    }
    _controller = null;
    // We don't own the _controller Animation, so it's not disposed here.
    super.dispose();
  }

  int get maxTabIndex => _indicatorPainter.maxTabIndex;

  double _tabScrollOffset(int index, double viewportWidth, double minExtent, double maxExtent) {
    if (!widget.isScrollable)
      return 0.0;
    double tabCenter = _indicatorPainter.centerOf(index);
    switch (Directionality.of(context)) {
      case TextDirection.rtl:
        tabCenter = _tabStripWidth - tabCenter;
        break;
      case TextDirection.ltr:
        break;
    }
    return (tabCenter - viewportWidth / 2.0).clamp(minExtent, maxExtent);
  }

  double _tabCenteredScrollOffset(int index) {
    final ScrollPosition position = _scrollController.position;
    return _tabScrollOffset(index, position.viewportDimension, position.minScrollExtent, position.maxScrollExtent);
  }

  double _initialScrollOffset(double viewportWidth, double minExtent, double maxExtent) {
    return _tabScrollOffset(_currentIndex, viewportWidth, minExtent, maxExtent);
  }

  void _scrollToCurrentIndex() {
    final double offset = _tabCenteredScrollOffset(_currentIndex);
    _scrollController.animateTo(offset, duration: kTabScrollDuration, curve: Curves.ease);
  }

  void _scrollToControllerValue() {
    final double leadingPosition = _currentIndex > 0 ? _tabCenteredScrollOffset(_currentIndex - 1) : null;
    final double middlePosition = _tabCenteredScrollOffset(_currentIndex);
    final double trailingPosition = _currentIndex < maxTabIndex ? _tabCenteredScrollOffset(_currentIndex + 1) : null;

    final double index = _controller.index.toDouble();
    final double value = _controller.animation.value;
    double offset;
    if (value == index - 1.0)
      offset = leadingPosition ?? middlePosition;
    else if (value == index + 1.0)
      offset = trailingPosition ?? middlePosition;
    else if (value == index)
      offset = middlePosition;
    else if (value < index)
      offset = leadingPosition == null ? middlePosition : lerpDouble(middlePosition, leadingPosition, index - value);
    else
      offset = trailingPosition == null ? middlePosition : lerpDouble(middlePosition, trailingPosition, value - index);

    _scrollController.jumpTo(offset);
  }

  void _handleTabControllerAnimationTick() {
    assert(mounted);
    if (!_controller.indexIsChanging && widget.isScrollable) {
      // Sync the TabBar's scroll position with the TabBarView's PageView.
      _currentIndex = _controller.index;
      _scrollToControllerValue();
    }
  }

  void _handleTabControllerTick() {
    if (_controller.index != _currentIndex) {
      _currentIndex = _controller.index;
      if (widget.isScrollable)
        _scrollToCurrentIndex();
    }
    setState(() {
      // Rebuild the tabs after a (potentially animated) index change
      // has completed.
    });
  }

  // Called each time layout completes.
  void _saveTabOffsets(List<double> tabOffsets, TextDirection textDirection, double width) {
    _tabStripWidth = width;
    _indicatorPainter?.saveTabOffsets(tabOffsets, textDirection);
  }

  void _handleTap(int index) {
    assert(index >= 0 && index < widget.tabs.length);
    _controller.animateTo(index);
    if (widget.onTap != null) {
      widget.onTap(index);
    }
  }

  Widget _buildStyledTab(Widget child, bool selected, Animation<double> animation) {
    return _TabStyle(
      animation: animation,
      selected: selected,
      labelColor: widget.labelColor,
      unselectedLabelColor: widget.unselectedLabelColor,
      labelStyle: widget.labelStyle,
      unselectedLabelStyle: widget.unselectedLabelStyle,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterialLocalizations(context));
    assert(() {
      if (_controller.length != widget.tabs.length) {
        throw FlutterError(
          'Controller\'s length property (${_controller.length}) does not match the \n'
          'number of tabs (${widget.tabs.length}) present in TabBar\'s tabs property.'
        );
      }
      return true;
    }());
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);
    if (_controller.length == 0) {
      return Container(
        height: _kTabHeight + widget.indicatorWeight,
      );
    }

    final TabBarTheme tabBarTheme = TabBarTheme.of(context);

    final List<Widget> wrappedTabs = List<Widget>(widget.tabs.length);
    for (int i = 0; i < widget.tabs.length; i += 1) {
      wrappedTabs[i] = Center(
        heightFactor: 1.0,
        child: Padding(
          padding: widget.labelPadding ?? tabBarTheme.labelPadding ?? kTabLabelPadding,
          child: KeyedSubtree(
            key: _tabKeys[i],
            child: widget.tabs[i],
          ),
        ),
      );

    }

    // If the controller was provided by DefaultTabController and we're part
    // of a Hero (typically the AppBar), then we will not be able to find the
    // controller during a Hero transition. See https://github.com/flutter/flutter/issues/213.
    if (_controller != null) {
      final int previousIndex = _controller.previousIndex;

      if (_controller.indexIsChanging) {
        // The user tapped on a tab, the tab controller's animation is running.
        assert(_currentIndex != previousIndex);
        final Animation<double> animation = _ChangeAnimation(_controller);
        wrappedTabs[_currentIndex] = _buildStyledTab(wrappedTabs[_currentIndex], true, animation);
        wrappedTabs[previousIndex] = _buildStyledTab(wrappedTabs[previousIndex], false, animation);
      } else {
        // The user is dragging the TabBarView's PageView left or right.
        final int tabIndex = _currentIndex;
        final Animation<double> centerAnimation = _DragAnimation(_controller, tabIndex);
        wrappedTabs[tabIndex] = _buildStyledTab(wrappedTabs[tabIndex], true, centerAnimation);
        if (_currentIndex > 0) {
          final int tabIndex = _currentIndex - 1;
          final Animation<double> previousAnimation = ReverseAnimation(_DragAnimation(_controller, tabIndex));
          wrappedTabs[tabIndex] = _buildStyledTab(wrappedTabs[tabIndex], false, previousAnimation);
        }
        if (_currentIndex < widget.tabs.length - 1) {
          final int tabIndex = _currentIndex + 1;
          final Animation<double> nextAnimation = ReverseAnimation(_DragAnimation(_controller, tabIndex));
          wrappedTabs[tabIndex] = _buildStyledTab(wrappedTabs[tabIndex], false, nextAnimation);
        }
      }
    }

    // Add the tap handler to each tab. If the tab bar is not scrollable,
    // then give all of the tabs equal flexibility so that they each occupy
    // the same share of the tab bar's overall width.
    final int tabCount = widget.tabs.length;
    for (int index = 0; index < tabCount; index += 1) {
      wrappedTabs[index] = InkWell(
        onTap: () { _handleTap(index); },
        child: Padding(
          padding: EdgeInsets.only(bottom: widget.indicatorWeight),
          child: Stack(
            children: <Widget>[
              wrappedTabs[index],
              Semantics(
                selected: index == _currentIndex,
                label: localizations.tabLabel(tabIndex: index + 1, tabCount: tabCount),
              ),
            ],
          ),
        ),
      );
      if (!widget.isScrollable)
        wrappedTabs[index] = Expanded(child: wrappedTabs[index]);
    }

    Widget tabBar = CustomPaint(
      painter: _indicatorPainter,
      child: _TabStyle(
        animation: kAlwaysDismissedAnimation,
        selected: false,
        labelColor: widget.labelColor,
        unselectedLabelColor: widget.unselectedLabelColor,
        labelStyle: widget.labelStyle,
        unselectedLabelStyle: widget.unselectedLabelStyle,
        child: _TabLabelBar(
          onPerformLayout: _saveTabOffsets,
          children: wrappedTabs,
        ),
      ),
    );

    if (widget.isScrollable) {
      _scrollController ??= _TabBarScrollController(this);
      tabBar = SingleChildScrollView(
        dragStartBehavior: widget.dragStartBehavior,
        scrollDirection: Axis.horizontal,
        controller: _scrollController,
        child: tabBar,
      );
    }

    return tabBar;
  }
}

/// A page view that displays the widget which corresponds to the currently
/// selected tab.
///
/// This widget is typically used in conjunction with a [TabBar].
///
/// If a [TabController] is not provided, then there must be a [DefaultTabController]
/// ancestor.
///
/// The tab controller's [TabController.length] must equal the length of the
/// [children] list and the length of the [TabBar.tabs] list.
///
/// To see a sample implementation, visit the [TabController] documentation.
class TabBarView extends StatefulWidget {
  /// Creates a page view with one child per tab.
  ///
  /// The length of [children] must be the same as the [controller]'s length.
  const TabBarView({
    Key key,
    @required this.children,
    this.controller,
    this.physics,
    this.dragStartBehavior = DragStartBehavior.start,
  }) : assert(children != null),
       assert(dragStartBehavior != null),
       super(key: key);

  /// This widget's selection and animation state.
  ///
  /// If [TabController] is not provided, then the value of [DefaultTabController.of]
  /// will be used.
  final TabController controller;

  /// One widget per tab.
  ///
  /// Its length must match the length of the [TabBar.tabs]
  /// list, as well as the [controller]'s [TabController.length].
  final List<Widget> children;

  /// How the page view should respond to user input.
  ///
  /// For example, determines how the page view continues to animate after the
  /// user stops dragging the page view.
  ///
  /// The physics are modified to snap to page boundaries using
  /// [PageScrollPhysics] prior to being used.
  ///
  /// Defaults to matching platform conventions.
  final ScrollPhysics physics;

  /// {@macro flutter.widgets.scrollable.dragStartBehavior}
  final DragStartBehavior dragStartBehavior;

  @override
  _TabBarViewState createState() => _TabBarViewState();
}

final PageScrollPhysics _kTabBarViewPhysics = const PageScrollPhysics().applyTo(const ClampingScrollPhysics());

class _TabBarViewState extends State<TabBarView> {
  TabController _controller;
  PageController _pageController;
  List<Widget> _children;
  List<Widget> _childrenWithKey;
  int _currentIndex;
  int _warpUnderwayCount = 0;

  // If the TabBarView is rebuilt with a new tab controller, the caller should
  // dispose the old one. In that case the old controller's animation will be
  // null and should not be accessed.
  bool get _controllerIsValid => _controller?.animation != null;

  void _updateTabController() {
    final TabController newController = widget.controller ?? DefaultTabController.of(context);
    assert(() {
      if (newController == null) {
        throw FlutterError(
          'No TabController for ${widget.runtimeType}.\n'
          'When creating a ${widget.runtimeType}, you must either provide an explicit '
          'TabController using the "controller" property, or you must ensure that there '
          'is a DefaultTabController above the ${widget.runtimeType}.\n'
          'In this case, there was neither an explicit controller nor a default controller.'
        );
      }
      return true;
    }());

    if (newController == _controller)
      return;

    if (_controllerIsValid)
      _controller.animation.removeListener(_handleTabControllerAnimationTick);
    _controller = newController;
    if (_controller != null)
      _controller.animation.addListener(_handleTabControllerAnimationTick);
  }

  @override
  void initState() {
    super.initState();
    _updateChildren();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateTabController();
    _currentIndex = _controller?.index;
    _pageController = PageController(initialPage: _currentIndex ?? 0);
  }

  @override
  void didUpdateWidget(TabBarView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller)
      _updateTabController();
    if (widget.children != oldWidget.children && _warpUnderwayCount == 0)
      _updateChildren();
  }

  @override
  void dispose() {
    if (_controllerIsValid)
      _controller.animation.removeListener(_handleTabControllerAnimationTick);
    _controller = null;
    // We don't own the _controller Animation, so it's not disposed here.
    super.dispose();
  }

  void _updateChildren() {
    _children = widget.children;
    _childrenWithKey = KeyedSubtree.ensureUniqueKeysForList(widget.children);
  }

  void _handleTabControllerAnimationTick() {
    if (_warpUnderwayCount > 0 || !_controller.indexIsChanging)
      return; // This widget is driving the controller's animation.

    if (_controller.index != _currentIndex) {
      _currentIndex = _controller.index;
      _warpToCurrentIndex();
    }
  }

  Future<void> _warpToCurrentIndex() async {
    if (!mounted)
      return Future<void>.value();

    if (_pageController.page == _currentIndex.toDouble())
      return Future<void>.value();

    final int previousIndex = _controller.previousIndex;
    if ((_currentIndex - previousIndex).abs() == 1)
      return _pageController.animateToPage(_currentIndex, duration: kTabScrollDuration, curve: Curves.ease);

    assert((_currentIndex - previousIndex).abs() > 1);
    final int initialPage = _currentIndex > previousIndex
        ? _currentIndex - 1
        : _currentIndex + 1;
    final List<Widget> originalChildren = _childrenWithKey;
    setState(() {
      _warpUnderwayCount += 1;

      _childrenWithKey = List<Widget>.from(_childrenWithKey, growable: false);
      final Widget temp = _childrenWithKey[initialPage];
      _childrenWithKey[initialPage] = _childrenWithKey[previousIndex];
      _childrenWithKey[previousIndex] = temp;
    });
    _pageController.jumpToPage(initialPage);

    await _pageController.animateToPage(_currentIndex, duration: kTabScrollDuration, curve: Curves.ease);
    if (!mounted)
      return Future<void>.value();
    setState(() {
      _warpUnderwayCount -= 1;
      if (widget.children != _children) {
        _updateChildren();
      } else {
        _childrenWithKey = originalChildren;
      }
    });
  }

  // Called when the PageView scrolls
  bool _handleScrollNotification(ScrollNotification notification) {
    if (_warpUnderwayCount > 0)
      return false;

    if (notification.depth != 0)
      return false;

    _warpUnderwayCount += 1;
    if (notification is ScrollUpdateNotification && !_controller.indexIsChanging) {
      if ((_pageController.page - _controller.index).abs() > 1.0) {
        _controller.index = _pageController.page.floor();
        _currentIndex =_controller.index;
      }
      _controller.offset = (_pageController.page - _controller.index).clamp(-1.0, 1.0);
    } else if (notification is ScrollEndNotification) {
      _controller.index = _pageController.page.round();
      _currentIndex = _controller.index;
    }
    _warpUnderwayCount -= 1;

    return false;
  }

  @override
  Widget build(BuildContext context) {
    assert(() {
      if (_controller.length != widget.children.length) {
        throw FlutterError(
          'Controller\'s length property (${_controller.length}) does not match the \n'
          'number of tabs (${widget.children.length}) present in TabBar\'s tabs property.'
        );
      }
      return true;
    }());
    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: PageView(
        dragStartBehavior: widget.dragStartBehavior,
        controller: _pageController,
        physics: widget.physics == null ? _kTabBarViewPhysics : _kTabBarViewPhysics.applyTo(widget.physics),
        children: _childrenWithKey,
      ),
    );
  }
}

/// Displays a single circle with the specified border and background colors.
///
/// Used by [TabPageSelector] to indicate the selected page.
class TabPageSelectorIndicator extends StatelessWidget {
  /// Creates an indicator used by [TabPageSelector].
  ///
  /// The [backgroundColor], [borderColor], and [size] parameters must not be null.
  const TabPageSelectorIndicator({
    Key key,
    @required this.backgroundColor,
    @required this.borderColor,
    @required this.size,
  }) : assert(backgroundColor != null),
       assert(borderColor != null),
       assert(size != null),
       super(key: key);

  /// The indicator circle's background color.
  final Color backgroundColor;

  /// The indicator circle's border color.
  final Color borderColor;

  /// The indicator circle's diameter.
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor),
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Displays a row of small circular indicators, one per tab.
///
/// The selected tab's indicator is highlighted. Often used in conjunction with
/// a [TabBarView].
///
/// If a [TabController] is not provided, then there must be a
/// [DefaultTabController] ancestor.
class TabPageSelector extends StatelessWidget {
  /// Creates a compact widget that indicates which tab has been selected.
  const TabPageSelector({
    Key key,
    this.controller,
    this.indicatorSize = 12.0,
    this.color,
    this.selectedColor,
  }) : assert(indicatorSize != null && indicatorSize > 0.0),
       super(key: key);

  /// This widget's selection and animation state.
  ///
  /// If [TabController] is not provided, then the value of
  /// [DefaultTabController.of] will be used.
  final TabController controller;

  /// The indicator circle's diameter (the default value is 12.0).
  final double indicatorSize;

  /// The indicator circle's fill color for unselected pages.
  ///
  /// If this parameter is null, then the indicator is filled with [Colors.transparent].
  final Color color;

  /// The indicator circle's fill color for selected pages and border color
  /// for all indicator circles.
  ///
  /// If this parameter is null, then the indicator is filled with the theme's
  /// accent color, [ThemeData.accentColor].
  final Color selectedColor;

  Widget _buildTabIndicator(
    int tabIndex,
    TabController tabController,
    ColorTween selectedColorTween,
    ColorTween previousColorTween,
  ) {
    Color background;
    if (tabController.indexIsChanging) {
      // The selection's animation is animating from previousValue to value.
      final double t = 1.0 - _indexChangeProgress(tabController);
      if (tabController.index == tabIndex)
        background = selectedColorTween.lerp(t);
      else if (tabController.previousIndex == tabIndex)
        background = previousColorTween.lerp(t);
      else
        background = selectedColorTween.begin;
    } else {
      // The selection's offset reflects how far the TabBarView has / been dragged
      // to the previous page (-1.0 to 0.0) or the next page (0.0 to 1.0).
      final double offset = tabController.offset;
      if (tabController.index == tabIndex) {
        background = selectedColorTween.lerp(1.0 - offset.abs());
      } else if (tabController.index == tabIndex - 1 && offset > 0.0) {
        background = selectedColorTween.lerp(offset);
      } else if (tabController.index == tabIndex + 1 && offset < 0.0) {
        background = selectedColorTween.lerp(-offset);
      } else {
        background = selectedColorTween.begin;
      }
    }
    return TabPageSelectorIndicator(
      backgroundColor: background,
      borderColor: selectedColorTween.end,
      size: indicatorSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color fixColor = color ?? Colors.transparent;
    final Color fixSelectedColor = selectedColor ?? Theme.of(context).accentColor;
    final ColorTween selectedColorTween = ColorTween(begin: fixColor, end: fixSelectedColor);
    final ColorTween previousColorTween = ColorTween(begin: fixSelectedColor, end: fixColor);
    final TabController tabController = controller ?? DefaultTabController.of(context);
    assert(() {
      if (tabController == null) {
        throw FlutterError(
          'No TabController for $runtimeType.\n'
          'When creating a $runtimeType, you must either provide an explicit TabController '
          'using the "controller" property, or you must ensure that there is a '
          'DefaultTabController above the $runtimeType.\n'
          'In this case, there was neither an explicit controller nor a default controller.'
        );
      }
      return true;
    }());
    final Animation<double> animation = CurvedAnimation(
      parent: tabController.animation,
      curve: Curves.fastOutSlowIn,
    );
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget child) {
        return Semantics(
          label: 'Page ${tabController.index + 1} of ${tabController.length}',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List<Widget>.generate(tabController.length, (int tabIndex) {
              return _buildTabIndicator(tabIndex, tabController, selectedColorTween, previousColorTween);
            }).toList(),
          ),
        );
      },
    );
  }
}
