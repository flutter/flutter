// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show ImageFilter, window;

import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'theme.dart';

// Standard iOS 11 tab bar height.
const double _kTabBarHeight = 49.0;
const double _kTabBarCompactHeight = 32.0;

const double _kTabBarIconHeight = 27.5;
const double _kTabBarCompactIconHeight = 21.0;

const Color _kDefaultTabBarBorderColor = CupertinoDynamicColor.withBrightness(
  color: Color(0x4C000000),
  darkColor: Color(0x29000000),
);
const Color _kDefaultTabBarInactiveColor = CupertinoColors.inactiveGray;

/// The enumerator for [CupertinoBottomTabBar]'s layout mode
enum CupertinoTabBarLayoutMode {
  /// Regular tab bar height (compatible with vertical and horizontal icon layouts)
  regular,
  /// Compact tab bar height (compatible only with horizontal icon layout)
  compact
}

/// The enumerator for [CupertinoBottomTabBar]'s item inner layout mode
enum CupertinoTabBarItemLayoutMode {
  /// Stacked item layout, text under icon
  vertical,
  /// Horizontal item layout, text to the right of icon
  horizontal
}

/*
 *
 */
enum CupertinoSizeClass {
  compact,
  regular,
}

class CupertinoSizeClassHelper {

  static bool isTablet() {
    if(window.devicePixelRatio < 2 && (window.physicalSize.width >= 1000 || window.physicalSize.height >= 1000)) {
      return true;
    }
    else if(window.devicePixelRatio == 2 && (window.physicalSize.width >= 1920 || window.physicalSize.height >= 1920)) {
      return true;
    }
    else
      return false;
  }

  // TODO: take Split View into consideration, be less resolution dependent

  /// Returns true if phone is Xs Max, 11 Pro Max
  static bool isMaxStyle() {
    return window.devicePixelRatio == 3 && (window.physicalSize.width == 2688 || window.physicalSize.height == 2688);
  }

  /// Returns true if phone is X, Xr, Xs, 11, 11 Pro
  static bool is10Style() {
    return (window.physicalSize.width == 828 || window.physicalSize.height == 828) || (window.physicalSize.width == 1125 || window.physicalSize.height == 1125);
  }

  /// Returns true if phone is 6+, 6s+, 7+, 8+
  static bool isPlusStyle() {
    return window.devicePixelRatio == 3 && (window.physicalSize.width == 2208 || window.physicalSize.height == 2208);
  }

  /// Returns true if phone is 6, 6s, 7, 8 (non-plus)
  static bool is6Style() {
    return window.devicePixelRatio == 2 && (window.physicalSize.width == 750 || window.physicalSize.height == 750);
  }

  /// Returns true if phone is 5, 5c, 5s, SE, iPod 5g
  /// NOTE: also includes 4, 4s, iPod 4g
  static bool is5Style() {
    return window.devicePixelRatio == 2 && (window.physicalSize.width == 640 || window.physicalSize.height == 640);
  }

  // TODO: create separate qualifier for iPhone/iPod series 4

  // NOTE: devices from series 3 and below are not included because they don't support iOS 8

  static CupertinoSizeClass getWidthSizeClass(BuildContext context) {
    if(isTablet()) {
      return CupertinoSizeClass.regular;
    } else if(MediaQuery.of(context).orientation == Orientation.portrait) {
      return isPlusStyle() || isMaxStyle() ? CupertinoSizeClass.regular : CupertinoSizeClass.compact;
    } else {
      return CupertinoSizeClass.compact;
    } 
  }

  static CupertinoSizeClass getHeightSizeClass(BuildContext context) {
    if(isTablet()) {
      return CupertinoSizeClass.regular;
    } else {
      return MediaQuery.of(context).orientation == Orientation.portrait ? CupertinoSizeClass.regular : CupertinoSizeClass.compact;
    }
  }
}
/*
 *
 */

/// An iOS-styled bottom navigation tab bar.
///
/// Displays multiple tabs using [BottomNavigationBarItem] with one tab being
/// active, the first tab by default.
///
/// This [StatelessWidget] doesn't store the active tab itself. You must
/// listen to the [onTap] callbacks and call `setState` with a new [currentIndex]
/// for the new selection to reflect. This can also be done automatically
/// by wrapping this with a [CupertinoTabScaffold].
///
/// Tab changes typically trigger a switch between [Navigator]s, each with its
/// own navigation stack, per standard iOS design. This can be done by using
/// [CupertinoTabView]s inside each tab builder in [CupertinoTabScaffold].
///
/// If the given [backgroundColor]'s opacity is not 1.0 (which is the case by
/// default), it will produce a blurring effect to the content behind it.
///
/// When used as [CupertinoTabScaffold.tabBar], by default `CupertinoTabBar` has
/// its text scale factor set to 1.0 and does not respond to text scale factor
/// changes from the operating system, to match the native iOS behavior. To override
/// this behavior, wrap each of the `navigationBar`'s components inside a [MediaQuery]
/// with the desired [MediaQueryData.textScaleFactor] value. The text scale factor
/// value from the operating system can be retrieved in many ways, such as querying
/// [MediaQuery.textScaleFactorOf] against [CupertinoApp]'s [BuildContext].
///
/// See also:
///
///  * [CupertinoTabScaffold], which hosts the [CupertinoTabBar] at the bottom.
///  * [BottomNavigationBarItem], an item in a [CupertinoTabBar].
class CupertinoTabBar extends StatelessWidget implements PreferredSizeWidget {
  /// Creates a tab bar in the iOS style.
  const CupertinoTabBar({
    Key key,
    @required this.items,
    this.barLayoutMode,
    this.itemLayoutMode,
    this.onTap,
    this.currentIndex = 0,
    this.backgroundColor,
    this.activeColor,
    this.inactiveColor = _kDefaultTabBarInactiveColor,
    this.iconSize = _kTabBarIconHeight,
    this.compactIconSize = _kTabBarCompactIconHeight,
    this.border = const Border(
      top: BorderSide(
        color: _kDefaultTabBarBorderColor,
        width: 0.0, // One physical pixel.
        style: BorderStyle.solid,
      ),
    ),
  }) : assert(items != null),
       assert(
         !(barLayoutMode == CupertinoTabBarLayoutMode.compact && itemLayoutMode == CupertinoTabBarItemLayoutMode.vertical),
         "Tab bar's compact layout and items' vertical layout are not compatible"
       ),
       assert(
         items.length >= 2,
         "Tabs need at least 2 items to conform to Apple's HIG",
       ),
       assert(currentIndex != null),
       assert(0 <= currentIndex && currentIndex < items.length),
       assert(iconSize != null),
       assert(compactIconSize != null),
       assert(inactiveColor != null),
       super(key: key);

  /// The interactive items laid out within the bottom navigation bar.
  ///
  /// Must not be null.
  final List<BottomNavigationBarItem> items;

  /// Controls whether the tab bar should be displayed in its compact mode (landscape mode on iPhone) or the regular one.
  ///
  /// When this value is [null], the layout mode is automatically calculated on build
  final CupertinoTabBarLayoutMode barLayoutMode;

  /// Controls whether the buttons should have a wide appearance, which, as of iOS 11,
  /// is common apps in landscape mode (iPhone) or always on iPad.
  /// (source: https://developer.apple.com/videos/play/wwdc2017/204/)
  ///
  /// When this value is [null], the layout mode is automatically calculated on build
  final CupertinoTabBarItemLayoutMode itemLayoutMode;

  /// The callback that is called when a item is tapped.
  ///
  /// The widget creating the bottom navigation bar needs to keep track of the
  /// current index and call `setState` to rebuild it with the newly provided
  /// index.
  final ValueChanged<int> onTap;

  /// The index into [items] of the current active item.
  ///
  /// Must not be null and must inclusively be between 0 and the number of tabs
  /// minus 1.
  final int currentIndex;

  /// The background color of the tab bar. If it contains transparency, the
  /// tab bar will automatically produce a blurring effect to the content
  /// behind it.
  ///
  /// Defaults to [CupertinoTheme]'s `barBackgroundColor` when null.
  final Color backgroundColor;

  /// The foreground color of the icon and title for the [BottomNavigationBarItem]
  /// of the selected tab.
  ///
  /// Defaults to [CupertinoTheme]'s `primaryColor` if null.
  final Color activeColor;

  /// The foreground color of the icon and title for the [BottomNavigationBarItem]s
  /// in the unselected state.
  ///
  /// Defaults to a [CupertinoDynamicColor] that matches the disabled foreground
  /// color of the native `UITabBar` component. Cannot be null.
  final Color inactiveColor;

  /// The size of all of the [BottomNavigationBarItem] icons.
  ///
  /// This value is used to configure the [IconTheme] for the navigation bar.
  /// When a [BottomNavigationBarItem.icon] widget is not an [Icon] the widget
  /// should configure itself to match the icon theme's size and color.
  ///
  /// Must not be null.
  final double iconSize;

  /// Same as `iconSize`, but applies when `isWide` and `isCompact` are both true
  final double compactIconSize;

  /// The border of the [CupertinoTabBar].
  ///
  /// The default value is a one physical pixel top border with grey color.
  final Border border;

  @override
  Size get preferredSize => _isBarCompact ? const Size.fromHeight(_kTabBarCompactHeight) : const Size.fromHeight(_kTabBarHeight);

  // TODO(kerberjg): reconsider the usage of [window.physicalSize] since it leads to incorrect size detection when mocking size in tests
  bool get _isBarCompact => barLayoutMode != CupertinoTabBarLayoutMode.regular && window.physicalSize.height < 800;

  /// Indicates whether the tab bar is fully opaque or can have contents behind
  /// it show through it.
  bool opaque(BuildContext context) {
    final Color backgroundColor =
        this.backgroundColor ?? CupertinoTheme.of(context).barBackgroundColor;
    return CupertinoDynamicColor.resolve(backgroundColor, context).alpha == 0xFF;
  }

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.of(context).padding.bottom;

    final Color backgroundColor = CupertinoDynamicColor.resolve(
      this.backgroundColor ?? CupertinoTheme.of(context).barBackgroundColor,
      context,
    );

    BorderSide resolveBorderSide(BorderSide side) {
      return side == BorderSide.none
        ? side
        : side.copyWith(color: CupertinoDynamicColor.resolve(side.color, context));
    }

    // Return the border as is when it's a subclass.
    final Border resolvedBorder = border == null || border.runtimeType != Border
      ? border
      : Border(
        top: resolveBorderSide(border.top),
        left: resolveBorderSide(border.left),
        bottom: resolveBorderSide(border.bottom),
        right: resolveBorderSide(border.right),
      );

    final Color inactive = CupertinoDynamicColor.resolve(inactiveColor, context);

    bool isIconCompact, isItemVertical;

    // Applies the manual layout types, if specified
    switch(barLayoutMode) {
      case CupertinoTabBarLayoutMode.compact:
        isIconCompact = true; break;
      case CupertinoTabBarLayoutMode.regular:
        isIconCompact = false; break;
    }

    switch(itemLayoutMode) {
      case CupertinoTabBarItemLayoutMode.vertical:
        isItemVertical = true; break;
      case CupertinoTabBarItemLayoutMode.horizontal:
        isItemVertical = false; break;
    }

    // Automatically determines the layouts of the tab bar and its items based on the context view's size classes
    if(CupertinoSizeClassHelper.getWidthSizeClass(context) == CupertinoSizeClass.compact) {
      switch(CupertinoSizeClassHelper.getHeightSizeClass(context)) {
        case CupertinoSizeClass.compact:
          isIconCompact ??= true;
          isItemVertical ??= false;
          break;

        case CupertinoSizeClass.regular:
          isIconCompact ??= false;
          isItemVertical ??= true;
          break;
      }
    } else {
      isIconCompact ??= false;
      isItemVertical ??= false;
    }

    Widget result = DecoratedBox(
      decoration: BoxDecoration(
        border: resolvedBorder,
        color: backgroundColor,
      ),
      child: SizedBox(
        height: preferredSize.height + bottomPadding,
        child: IconTheme.merge( // Default with the inactive state.
          data: IconThemeData(
            color: inactive,
            size: isIconCompact ? compactIconSize : iconSize,
          ),
          child: DefaultTextStyle( // Default with the inactive state.
            style: (isItemVertical ?
              CupertinoTheme.of(context).textTheme.tabLabelTextStyle
              : CupertinoTheme.of(context).textTheme.tabWideLabelTextStyle).copyWith(color: inactive),
            child: Padding(
              padding: isItemVertical ? EdgeInsets.only(top: 4.0, bottom: bottomPadding) : EdgeInsets.only(bottom: bottomPadding),
              child: _buildTabItems(context, isItemVertical),
            ),
          ),
        ),
      ),
    );

    if (!opaque(context)) {
      // For non-opaque backgrounds, apply a blur effect.
      result = ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: result,
        ),
      );
    }

    return result;
  }

  Widget _buildTabItems(BuildContext context, bool isVertical) {
    final List<Widget> result = <Widget>[];

    for (int index = 0; index < items.length; index += 1) {
      final bool active = index == currentIndex;
      result.add(
        _wrapActiveItem(
          context,
          Expanded(
            child: Semantics(
              selected: active,
              // TODO(xster): This needs localization support. https://github.com/flutter/flutter/issues/13452
              hint: 'tab, ${index + 1} of ${items.length}',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTap == null ? null : () { onTap(index); },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: isVertical ? _buildSingleTabItem(items[index], active) : _buildSingleWideTabItem(items[index], active)
                ),
              ),
            ),
          ),
          active: active,
        ),
      );
    }

    return Row(
      // Align bottom since we want the labels to be aligned.
      // Wide items however need to be center-aligned
      crossAxisAlignment: isVertical ? CrossAxisAlignment.end : CrossAxisAlignment.center,
      children: result,
    );
  }

  Widget _buildSingleTabItem(BottomNavigationBarItem item, bool active) {
    final List<Widget> components = <Widget>[
      Expanded(
        child: Center(child: active ? item.activeIcon : item.icon),
      ),
    ];

    if (item.title != null) {
      components.add(item.title);
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: components
    );
  }

  Widget _buildSingleWideTabItem(BottomNavigationBarItem item, bool active) {
    final List<Widget> components = <Widget>[
      if (active) item.activeIcon else item.icon,
    ];

    if (item.title != null) {
      components.add(
        Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: item.title,
        )
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: components,
    );
  }

  /// Change the active tab item's icon and title colors to active.
  Widget _wrapActiveItem(BuildContext context, Widget item, { @required bool active }) {
    if (!active)
      return item;

    final Color activeColor = CupertinoDynamicColor.resolve(
      this.activeColor ?? CupertinoTheme.of(context).primaryColor,
      context,
    );
    return IconTheme.merge(
      data: IconThemeData(color: activeColor),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: activeColor),
        child: item,
      ),
    );
  }

  /// Create a clone of the current [CupertinoTabBar] but with provided
  /// parameters overridden.
  CupertinoTabBar copyWith({
    Key key,
    CupertinoTabBarLayoutMode barLayoutMode,
    CupertinoTabBarItemLayoutMode itemLayoutMode,
    List<BottomNavigationBarItem> items,
    Color backgroundColor,
    Color activeColor,
    Color inactiveColor,
    double iconSize,
    double compactIconSize,
    Border border,
    int currentIndex,
    ValueChanged<int> onTap,
  }) {
    return CupertinoTabBar(
      key: key ?? this.key,
      barLayoutMode: barLayoutMode ?? this.barLayoutMode,
      itemLayoutMode: itemLayoutMode ?? this.itemLayoutMode,
      items: items ?? this.items,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      activeColor: activeColor ?? this.activeColor,
      inactiveColor: inactiveColor ?? this.inactiveColor,
      iconSize: iconSize ?? this.iconSize,
      compactIconSize: compactIconSize ?? this.compactIconSize,
      border: border ?? this.border,
      currentIndex: currentIndex ?? this.currentIndex,
      onTap: onTap ?? this.onTap,
    );
  }
}
