// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'constants.dart';
import 'flexible_space_bar.dart';
import 'icon.dart';
import 'icon_button.dart';
import 'icon_theme.dart';
import 'icon_theme_data.dart';
import 'icons.dart';
import 'material.dart';
import 'scaffold.dart';
import 'tabs.dart';
import 'theme.dart';
import 'typography.dart';

/// An interface for widgets that can appear at the bottom of an [AppBar] or
/// [SliverAppBar].
///
/// This interface exposes the height of the widget, so that the [Scaffold] and
/// [SliverAppBar] widgets can correctly size an [AppBar].
abstract class AppBarBottomWidget extends Widget {
  /// Defines the height of the app bar's optional bottom widget.
  double get bottomHeight;
}

enum _ToolbarSlot {
  leading,
  title,
  actions,
}

class _ToolbarLayout extends MultiChildLayoutDelegate {
  _ToolbarLayout({ this.centerTitle });

  // If false the title should be left or right justified within the space bewteen
  // the leading and actions widgets, depending on the locale's writing direction.
  // If true the title is centered within the toolbar (not within the horizontal
  // space bewteen the leading and actions widgets).
  final bool centerTitle;

  static const double kLeadingWidth = 56.0; // So it's square with kToolbarHeight.
  static const double kTitleLeft = 72.0; // As per https://material.io/guidelines/layout/metrics-keylines.html#metrics-keylines-keylines-spacing.

  @override
  void performLayout(Size size) {
    double actionsWidth = 0.0;

    if (hasChild(_ToolbarSlot.leading)) {
      final BoxConstraints constraints = new BoxConstraints.tight(new Size(kLeadingWidth, size.height));
      layoutChild(_ToolbarSlot.leading, constraints);
      positionChild(_ToolbarSlot.leading, Offset.zero);
    }

    if (hasChild(_ToolbarSlot.actions)) {
      final BoxConstraints constraints = new BoxConstraints.loose(size);
      final Size actionsSize = layoutChild(_ToolbarSlot.actions, constraints);
      final double actionsLeft = size.width - actionsSize.width;
      final double actionsTop = (size.height - actionsSize.height) / 2.0;
      actionsWidth = actionsSize.width;
      positionChild(_ToolbarSlot.actions, new Offset(actionsLeft, actionsTop));
    }

    if (hasChild(_ToolbarSlot.title)) {
      final double maxWidth = math.max(size.width - kTitleLeft - actionsWidth, 0.0);
      final BoxConstraints constraints = new BoxConstraints.loose(size).copyWith(maxWidth: maxWidth);
      final Size titleSize = layoutChild(_ToolbarSlot.title, constraints);
      final double titleY = (size.height - titleSize.height) / 2.0;
      double titleX = kTitleLeft;

      // If the centered title will not fit between the leading and actions
      // widgets, then align its left or right edge with the adjacent boundary.
      if (centerTitle) {
        titleX = (size.width - titleSize.width) / 2.0;
        if (titleX + titleSize.width > size.width - actionsWidth)
          titleX = size.width - actionsWidth - titleSize.width;
        else if (titleX < kTitleLeft)
          titleX = kTitleLeft;
      }

      positionChild(_ToolbarSlot.title, new Offset(titleX, titleY));
    }
  }

  @override
  bool shouldRelayout(_ToolbarLayout oldDelegate) => centerTitle != oldDelegate.centerTitle;
}

// TODO(eseidel) Toolbar needs to change size based on orientation:
// http://material.google.com/layout/structure.html#structure-app-bar
// Mobile Landscape: 48dp
// Mobile Portrait: 56dp
// Tablet/Desktop: 64dp

/// A material design app bar.
///
/// An app bar consists of a toolbar and potentially other widgets, such as a
/// [TabBar] and a [FlexibleSpaceBar]. App bars typically expose one or more
/// common actions with [IconButton]s which are optionally followed by a
/// [PopupMenuButton] for less common operations.
///
/// App bars are typically used in the [Scaffold.appBar] property, which places
/// the app bar as a fixed-height widget at the top of the screen. For a
/// scrollable app bar, see [SliverAppBar], which embeds an [AppBar] in a sliver
/// for use in a [CustomScrollView].
///
/// The AppBar displays the toolbar widgets, [leading], [title], and
/// [actions], above the [bottom] (if any). If a [flexibleSpace] widget is
/// specified then it is stacked behind the toolbar and the bottom widget.
///
/// See also:
///
///  * [Scaffold], which displays the [AppBar] in its [Scaffold.appBar] slot.
///  * [SliverAppBar], which uses [AppBar] to provide a flexible app bar that
///    can be used in a [CustomScrollView].
///  * [TabBar], which is typically placed in the [bottom] slot of the [AppBar]
///    if the screen has multiple pages arranged in tabs.
///  * [IconButton], which is used with [actions] to show buttons on the app bar.
///  * [PopupMenuButton], to show a popup menu on the app bar, via [actions].
///  * [FlexibleSpaceBar], which is used with [flexibleSpace] when the app bar
///    can expand and collapse.
///  * <https://material.google.com/layout/structure.html#structure-toolbars>
class AppBar extends StatefulWidget {
  /// Creates a material design app bar.
  ///
  /// Typically used in the [Scaffold.appBar] property.
  AppBar({
    Key key,
    this.leading,
    this.title,
    this.actions,
    this.flexibleSpace,
    AppBarBottomWidget bottom,
    this.elevation: 4,
    this.backgroundColor,
    this.brightness,
    this.iconTheme,
    this.textTheme,
    this.primary: true,
    this.centerTitle,
    this.toolbarOpacity: 1.0,
    this.bottomOpacity: 1.0,
  }) : bottom = bottom,
       _bottomHeight = bottom?.bottomHeight ?? 0.0,
       super(key: key) {
    assert(elevation != null);
    assert(primary != null);
    assert(toolbarOpacity != null);
    assert(bottomOpacity != null);
  }

  /// A widget to display before the [title].
  ///
  /// If this is null, the [AppBar] will imply an appropriate widget. For
  /// example, if the [AppBar] is in a [Scaffold] that also has a [Drawer], the
  /// [Scaffold] will fill this widget with an [IconButton] that opens the
  /// drawer. If there's no [Drawer] and the parent [Navigator] can go back, the
  /// [AppBar] will use an [IconButton] that calls [Navigator.pop].
  final Widget leading;

  /// The primary widget displayed in the appbar.
  ///
  /// Typically a [Text] widget containing a description of the current contents
  /// of the app.
  final Widget title;

  /// Widgets to display after the [title] widget.
  ///
  /// Typically these widgets are [IconButton]s representing common operations.
  /// For less common operations, consider using a [PopupMenuButton] as the
  /// last action.
  ///
  /// Widgets' minimum width will be automatically expanded to the recommended minimum touch target
  /// size of 48dp.
  ///
  /// For example:
  ///
  /// ```dart
  /// return new Scaffold(
  ///   appBar: new AppBar(
  ///     title: new Text('Hello World'),
  ///     actions: <Widget>[
  ///       new IconButton(
  ///         icon: new Icon(Icons.shopping_cart),
  ///         tooltip: 'Open shopping cart',
  ///         onPressed: _openCart,
  ///       ),
  ///     ],
  ///   ),
  ///   body: _buildBody(),
  /// );
  /// ```
  final List<Widget> actions;

  /// This widget is stacked behind the toolbar and the tabbar. It's height will
  /// be the same as the the app bar's overall height.
  ///
  /// A flexible space isn't actually flexible unless the [AppBar]'s container
  /// changes the [AppBar]'s size. A [SliverAppBar] in a [CustomScrollView]
  /// changes the [AppBar]'s height when scrolled. A [Scaffold] always sets the
  /// [AppBar] to the [minExtent].
  ///
  /// Typically a [FlexibleSpaceBar]. See [FlexibleSpaceBar] for details.
  final Widget flexibleSpace;

  /// This widget appears across the bottom of the app bar.
  ///
  /// Typically a [TabBar]. Only widgets that implement [AppBarBottomWidget] can
  /// be used at the bottom of an app bar.
  final AppBarBottomWidget bottom;

  /// The z-coordinate at which to place this app bar.
  ///
  /// The following elevations have defined shadows: 1, 2, 3, 4, 6, 8, 9, 12, 16, 24
  ///
  /// Defaults to 4, the appropriate elevation for app bars.
  final int elevation;

  /// The color to use for the app bar's material. Typically this should be set
  /// along with [brightness], [iconTheme], [textTheme].
  ///
  /// Defaults to [ThemeData.primaryColor].
  final Color backgroundColor;

  /// The brightness of the app bar's material. Typically this is set along
  /// with [backgroundColor], [iconTheme], [textTheme].
  ///
  /// Defaults to [ThemeData.primaryColorBrightness].
  final Brightness brightness;

  /// The color, opacity, and size to use for app bar icons. Typically this
  /// is set along with [backgroundColor], [brightness], [textTheme].
  ///
  /// Defaults to [ThemeData.primaryIconTheme].
  final IconThemeData iconTheme;

  /// The typographic styles to use for text in the app bar. Typically this is
  /// set along with [brightness] [backgroundColor], [iconTheme].
  ///
  /// Defaults to [ThemeData.primaryTextTheme].
  final TextTheme textTheme;

  /// Whether this app bar is being displayed at the top of the screen.
  ///
  /// If this is true, the top padding specified by the [MediaQuery] will be
  /// added to the top of the toolbar. See also [minExtent].
  final bool primary;

  /// Whether the title should be centered.
  ///
  /// Defaults to being adapted to the current [TargetPlatform].
  final bool centerTitle;

  final double toolbarOpacity;

  final double bottomOpacity;

  final double _bottomHeight;

  /// The height of the toolbar and the [bottom] widget.
  ///
  /// The parent widget should constrain the [AppBar] to a height between this
  /// and whatever maximum size it wants the [AppBar] to have.
  ///
  /// If [primary] is true, the parent should increase this height by the height
  /// of the top padding specified by the [MediaQuery] in scope for the
  /// [AppBar].
  double get minExtent => kToolbarHeight + _bottomHeight;

  bool _getEffectiveCenterTitle(ThemeData themeData) {
    if (centerTitle != null)
      return centerTitle;
    assert(themeData.platform != null);
    switch (themeData.platform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        return false;
      case TargetPlatform.iOS:
        return true;
    }
    return null;
  }

  @override
  AppBarState createState() => new AppBarState();
}

class AppBarState extends State<AppBar> {
  bool _hasDrawer = false;
  bool _canPop = false;

  @override
  void dependenciesChanged() {
    super.dependenciesChanged();
    ScaffoldState scaffold = Scaffold.of(context);
    _hasDrawer = scaffold?.hasDrawer ?? false;
    _canPop = ModalRoute.of(context)?.canPop() ?? false;
  }

  void _handleDrawerButton() {
    Scaffold.of(context).openDrawer();
  }

  void _handleBackButton() {
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    IconThemeData appBarIconTheme = config.iconTheme ?? themeData.primaryIconTheme;
    TextStyle centerStyle = config.textTheme?.title ?? themeData.primaryTextTheme.title;
    TextStyle sideStyle = config.textTheme?.body1 ?? themeData.primaryTextTheme.body1;

    Brightness brightness = config.brightness ?? themeData.primaryColorBrightness;
    SystemChrome.setSystemUIOverlayStyle(brightness == Brightness.dark
      ? SystemUiOverlayStyle.light
      : SystemUiOverlayStyle.dark);

    if (config.toolbarOpacity != 1.0) {
      final double opacity = const Interval(0.25, 1.0, curve: Curves.fastOutSlowIn).transform(config.toolbarOpacity);
      if (centerStyle?.color != null)
        centerStyle = centerStyle.copyWith(color: centerStyle.color.withOpacity(opacity));
      if (sideStyle?.color != null)
        sideStyle = sideStyle.copyWith(color: sideStyle.color.withOpacity(opacity));
      appBarIconTheme = appBarIconTheme.copyWith(
        opacity: opacity * (appBarIconTheme.opacity ?? 1.0)
      );
    }

    final List<Widget> toolbarChildren = <Widget>[];
    Widget leading = config.leading;
    if (leading == null) {
      if (_hasDrawer) {
        leading = new IconButton(
          icon: new Icon(Icons.menu),
          alignment: FractionalOffset.center,
          onPressed: _handleDrawerButton,
          tooltip: 'Open navigation menu' // TODO(ianh): Figure out how to localize this string
        );
      } else {
        if (_canPop) {
          IconData backIcon;
          switch (Theme.of(context).platform) {
            case TargetPlatform.android:
            case TargetPlatform.fuchsia:
              backIcon = Icons.arrow_back;
              break;
            case TargetPlatform.iOS:
              backIcon = Icons.arrow_back_ios;
              break;
          }
          assert(backIcon != null);
          leading = new IconButton(
            icon: new Icon(backIcon),
            alignment: FractionalOffset.center,
            onPressed: _handleBackButton,
            tooltip: 'Back' // TODO(ianh): Figure out how to localize this string
          );
        }
      }
    }
    if (leading != null) {
      toolbarChildren.add(
        new LayoutId(
          id: _ToolbarSlot.leading,
          child: leading
        )
      );
    }

    if (config.title != null) {
      toolbarChildren.add(
        new LayoutId(
          id: _ToolbarSlot.title,
          child: new DefaultTextStyle(
            style: centerStyle,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            child: config.title,
          ),
        ),
      );
    }
    if (config.actions != null && config.actions.isNotEmpty) {
      // Expand action widgets to at least 48dp.
      List<Widget> sizedActions = new List<Widget>();
      for (Widget action in config.actions) {
        sizedActions.add(new ConstrainedBox(
          constraints: new BoxConstraints(minWidth: 48.0),
          child: action,
        ));
      }
      toolbarChildren.add(
        new LayoutId(
          id: _ToolbarSlot.actions,
          child: new Row(
            mainAxisSize: MainAxisSize.min,
            children: sizedActions,
          ),
        ),
      );
    }

    Widget toolbar = new Padding(
      padding: const EdgeInsets.only(right: 4.0),
      child: new CustomMultiChildLayout(
        delegate: new _ToolbarLayout(
          centerTitle: config._getEffectiveCenterTitle(themeData),
        ),
        children: toolbarChildren,
      ),
    );

    Widget appBar = new SizedBox(
      height: kToolbarHeight,
      child: new IconTheme.merge(
        context: context,
        data: appBarIconTheme,
        child: new DefaultTextStyle(
          style: sideStyle,
          child: toolbar,
        ),
      ),
    );


    if (config.bottom != null) {
      appBar = new Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          appBar,
          config.bottomOpacity == 1.0 ? config.bottom : new Opacity(
            opacity: const Interval(0.25, 1.0, curve: Curves.fastOutSlowIn).transform(config.bottomOpacity),
            child: config.bottom,
          ),
        ],
      );
    }

    // The padding applies to the toolbar and tabbar, not the flexible space.
    if (config.primary) {
      appBar = new Padding(
        padding: new EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        child: appBar,
      );
    }

    if (config.flexibleSpace != null) {
      appBar = new Stack(
        children: <Widget>[
          config.flexibleSpace,
          new Positioned(top: 0.0, left: 0.0, right: 0.0, child: appBar),
        ],
      );
    }

    return new Material(
      color: config.backgroundColor ?? themeData.primaryColor,
      elevation: config.elevation,
      child: new Align(
        alignment: FractionalOffset.topCenter,
        child: appBar,
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate({
    @required this.leading,
    @required this.title,
    @required this.actions,
    @required this.flexibleSpace,
    @required AppBarBottomWidget bottom,
    @required this.elevation,
    @required this.backgroundColor,
    @required this.brightness,
    @required this.iconTheme,
    @required this.textTheme,
    @required this.primary,
    @required this.centerTitle,
    @required this.expandedHeight,
    @required this.topPadding,
    @required this.pinned,
  }) : bottom = bottom,
      _bottomHeight = bottom?.bottomHeight ?? 0.0 {
    assert(primary || topPadding == 0.0);
  }

  final Widget leading;
  final Widget title;
  final List<Widget> actions;
  final Widget flexibleSpace;
  final AppBarBottomWidget bottom;
  final int elevation;
  final Color backgroundColor;
  final Brightness brightness;
  final IconThemeData iconTheme;
  final TextTheme textTheme;
  final bool primary;
  final bool centerTitle;
  final double expandedHeight;
  final double topPadding;
  final bool pinned;

  final double _bottomHeight;

  @override
  double get minExtent => topPadding + kToolbarHeight + _bottomHeight;

  @override
  double get maxExtent => math.max(topPadding + (expandedHeight ?? kToolbarHeight), minExtent);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    double visibleMainHeight = maxExtent - shrinkOffset - topPadding;
    double toolbarOpacity = pinned ? 1.0 : ((visibleMainHeight - _bottomHeight) / kToolbarHeight).clamp(0.0, 1.0);
    return FlexibleSpaceBar.createSettings(
      minExtent: minExtent,
      maxExtent: maxExtent,
      currentExtent: math.max(minExtent, maxExtent - shrinkOffset),
      toolbarOpacity: toolbarOpacity,
      child: new AppBar(
        leading: leading,
        title: title,
        actions: actions,
        flexibleSpace: flexibleSpace,
        bottom: bottom,
        elevation: overlapsContent || (pinned && shrinkOffset > maxExtent - minExtent) ? elevation ?? 4 : 0,
        backgroundColor: backgroundColor,
        brightness: brightness,
        iconTheme: iconTheme,
        textTheme: textTheme,
        primary: primary,
        centerTitle: centerTitle,
        toolbarOpacity: toolbarOpacity,
        bottomOpacity: pinned ? 1.0 : (visibleMainHeight / _bottomHeight).clamp(0.0, 1.0),
      ),
    );
  }

  @override
  bool shouldRebuild(@checked _SliverAppBarDelegate oldDelegate) {
    return leading != oldDelegate.leading
        || title != oldDelegate.title
        || actions != oldDelegate.actions
        || flexibleSpace != oldDelegate.flexibleSpace
        || bottom != oldDelegate.bottom
        || _bottomHeight != oldDelegate._bottomHeight
        || elevation != oldDelegate.elevation
        || backgroundColor != oldDelegate.backgroundColor
        || brightness != oldDelegate.brightness
        || iconTheme != oldDelegate.iconTheme
        || textTheme != oldDelegate.textTheme
        || primary != oldDelegate.primary
        || centerTitle != oldDelegate.centerTitle
        || expandedHeight != oldDelegate.expandedHeight
        || topPadding != oldDelegate.topPadding;
  }

  @override
  String toString() {
    return '$runtimeType#$hashCode(topPadding: ${topPadding.toStringAsFixed(1)}, bottomHeight: ${_bottomHeight.toStringAsFixed(1)}, ...)';
  }
}

class SliverAppBar extends StatelessWidget {
  /// Creates a material design app bar that can be placed in a [CustomScrollView].
  SliverAppBar({
    Key key,
    this.leading,
    this.title,
    this.actions,
    this.flexibleSpace,
    this.bottom,
    this.elevation,
    this.backgroundColor,
    this.brightness,
    this.iconTheme,
    this.textTheme,
    this.primary: true,
    this.centerTitle,
    this.expandedHeight,
    this.floating: false,
    this.pinned: false,
  }) : super(key: key) {
    assert(primary != null);
    assert(floating != null);
    assert(pinned != null);
  }

  /// A widget to display before the [title].
  ///
  /// If this is null, the [AppBar] will imply an appropriate widget. For
  /// example, if the [AppBar] is in a [Scaffold] that also has a [Drawer], the
  /// [Scaffold] will fill this widget with an [IconButton] that opens the
  /// drawer. If there's no [Drawer] and the parent [Navigator] can go back, the
  /// [AppBar] will use an [IconButton] that calls [Navigator.pop].
  final Widget leading;

  /// The primary widget displayed in the appbar.
  ///
  /// Typically a [Text] widget containing a description of the current contents
  /// of the app.
  final Widget title;

  /// Widgets to display after the [title] widget.
  ///
  /// Typically these widgets are [IconButton]s representing common operations.
  /// For less common operations, consider using a [PopupMenuButton] as the
  /// last action.
  ///
  /// For example:
  ///
  /// ```dart
  /// return new Scaffold(
  ///   body: new CustomView(
  ///     primary: true,
  ///     slivers: <Widget>[
  ///       new SliverAppBar(
  ///         title: new Text('Hello World'),
  ///         actions: <Widget>[
  ///           new IconButton(
  ///             icon: new Icon(Icons.shopping_cart),
  ///             tooltip: 'Open shopping cart',
  ///             onPressed: _openCart,
  ///           ),
  ///         ],
  ///       ),
  ///       // ...rest of body...
  ///     ],
  ///   ),
  /// );
  /// ```
  final List<Widget> actions;

  /// This widget is stacked behind the toolbar and the tabbar. It's height will
  /// be the same as the the app bar's overall height.
  ///
  /// Typically a [FlexibleSpaceBar]. See [FlexibleSpaceBar] for details.
  final Widget flexibleSpace;

  /// This widget appears across the bottom of the appbar.
  ///
  /// Typically a [TabBar]. This widget must be a widget that implements the
  /// [AppBarBottomWidget] interface.
  final AppBarBottomWidget bottom;

  /// The z-coordinate at which to place this app bar.
  ///
  /// The following elevations have defined shadows: 1, 2, 3, 4, 6, 8, 9, 12, 16, 24
  ///
  /// Defaults to 4, the appropriate elevation for app bars.
  ///
  /// The elevation is ignored when the app bar has no content underneath it.
  /// For example, if the app bar is [pinned] but no content is scrolled under
  /// it, or if it scrolls with the content.
  final int elevation;

  /// The color to use for the app bar's material. Typically this should be set
  /// along with [brightness], [iconTheme], [textTheme].
  ///
  /// Defaults to [ThemeData.primaryColor].
  final Color backgroundColor;

  /// The brightness of the app bar's material. Typically this is set along
  /// with [backgroundColor], [iconTheme], [textTheme].
  ///
  /// Defaults to [ThemeData.primaryColorBrightness].
  final Brightness brightness;

  /// The color, opacity, and size to use for app bar icons. Typically this
  /// is set along with [backgroundColor], [brightness], [textTheme].
  ///
  /// Defaults to [ThemeData.primaryIconTheme].
  final IconThemeData iconTheme;

  /// The typographic styles to use for text in the app bar. Typically this is
  /// set along with [brightness] [backgroundColor], [iconTheme].
  ///
  /// Defaults to [ThemeData.primaryTextTheme].
  final TextTheme textTheme;

  /// Whether this app bar is being displayed at the top of the screen.
  ///
  /// If this is true, the top padding specified by the [MediaQuery] will be
  /// added to the top of the toolbar.
  final bool primary;

  /// Whether the title should be centered.
  ///
  /// Defaults to being adapted to the current [TargetPlatform].
  final bool centerTitle;

  /// The size of the app bar when it is fully expanded.
  ///
  /// By default, the total height of the toolbar and the bottom widget (if
  /// any). If a [flexibleSpace] widget is specified this height should be big
  /// enough to accommodate whatever that widget contains.
  ///
  /// This does not include the status bar height (which will be automatically
  /// included if [primary] is true).
  ///
  /// See also [AppBar.getExpandedHeightFor].
  final double expandedHeight;

  final bool floating;

  final bool pinned;

  @override
  Widget build(BuildContext context) {
    return new SliverPersistentHeader(
      floating: floating,
      pinned: pinned,
      delegate: new _SliverAppBarDelegate(
        leading: leading,
        title: title,
        actions: actions,
        flexibleSpace: flexibleSpace,
        bottom: bottom,
        elevation: elevation,
        backgroundColor: backgroundColor,
        brightness: brightness,
        iconTheme: iconTheme,
        textTheme: textTheme,
        primary: primary,
        centerTitle: centerTitle,
        expandedHeight: expandedHeight,
        topPadding: primary ? MediaQuery.of(context).padding.top : 0.0,
        pinned: pinned,
      ),
    );
  }
}
