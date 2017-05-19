// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'back_button.dart';
import 'constants.dart';
import 'flexible_space_bar.dart';
import 'icon_button.dart';
import 'icons.dart';
import 'material.dart';
import 'page.dart';
import 'scaffold.dart';
import 'tabs.dart';
import 'theme.dart';
import 'typography.dart';

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
  static const double kTitleLeftWithLeading = 72.0; // As per https://material.io/guidelines/layout/metrics-keylines.html#metrics-keylines-keylines-spacing.
  static const double kTitleLeftWithoutLeading = 16.0;

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
      final double titleLeftMargin =
          hasChild(_ToolbarSlot.leading) ? kTitleLeftWithLeading : kTitleLeftWithoutLeading;
      final double maxWidth = math.max(size.width - titleLeftMargin - actionsWidth, 0.0);
      final BoxConstraints constraints = new BoxConstraints.loose(size).copyWith(maxWidth: maxWidth);
      final Size titleSize = layoutChild(_ToolbarSlot.title, constraints);
      final double titleY = (size.height - titleSize.height) / 2.0;
      double titleX = titleLeftMargin;

      // If the centered title will not fit between the leading and actions
      // widgets, then align its left or right edge with the adjacent boundary.
      if (centerTitle) {
        titleX = (size.width - titleSize.width) / 2.0;
        if (titleX + titleSize.width > size.width - actionsWidth)
          titleX = size.width - actionsWidth - titleSize.width;
        else if (titleX < titleLeftMargin)
          titleX = titleLeftMargin;
      }

      positionChild(_ToolbarSlot.title, new Offset(titleX, titleY));
    }
  }

  @override
  bool shouldRelayout(_ToolbarLayout oldDelegate) => centerTitle != oldDelegate.centerTitle;
}

// Bottom justify the kToolbarHeight child which may overflow the top.
class _ToolbarContainerLayout extends SingleChildLayoutDelegate {
  const _ToolbarContainerLayout();

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return constraints.tighten(height: kToolbarHeight);
  }

  @override
  Size getSize(BoxConstraints constraints) {
    return new Size(constraints.maxWidth, kToolbarHeight);
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    return new Offset(0.0, size.height - childSize.height);
  }

  @override
  bool shouldRelayout(_ToolbarContainerLayout oldDelegate) => false;
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
/// common [actions] with [IconButton]s which are optionally followed by a
/// [PopupMenuButton] for less common operations (sometimes called the "overflow
/// menu").
///
/// App bars are typically used in the [Scaffold.appBar] property, which places
/// the app bar as a fixed-height widget at the top of the screen. For a
/// scrollable app bar, see [SliverAppBar], which embeds an [AppBar] in a sliver
/// for use in a [CustomScrollView].
///
/// The AppBar displays the toolbar widgets, [leading], [title], and [actions],
/// above the [bottom] (if any). The [bottom] is usually used for a [TabBar]. If
/// a [flexibleSpace] widget is specified then it is stacked behind the toolbar
/// and the bottom widget. The following diagram shows where each of these slots
/// appears in the toolbar when the writing language is left-to-right (e.g.
/// English):
///
/// ![The leading widget is in the top left, the actions are in the top right,
/// the title is between them. The bottom is, naturally, at the bottom, and the
/// flexibleSpace is behind all of them.](https://flutter.github.io/assets-for-api-docs/material/app_bar.png)
///
/// If the [leading] widget is omitted, but the [AppBar] is in a [Scaffold] with
/// a [Drawer], then a button will be inserted to open the drawer. Otherwise, if
/// the nearest [Navigator] has any previous routes, a [BackButton] is inserted
/// instead.
///
/// ## Sample code
///
/// ```dart
/// new AppBar(
///   title: new Text('My Fancy Dress'),
///   actions: <Widget>[
///     new IconButton(
///       icon: new Icon(Icons.playlist_play),
///       tooltip: 'Air it',
///       onPressed: _airDress,
///     ),
///     new IconButton(
///       icon: new Icon(Icons.playlist_add),
///       tooltip: 'Restitch it',
///       onPressed: _restitchDress,
///     ),
///     new IconButton(
///       icon: new Icon(Icons.playlist_add_check),
///       tooltip: 'Repair it',
///       onPressed: _repairDress,
///     ),
///   ],
/// )
/// ```
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
class AppBar extends StatefulWidget implements PreferredSizeWidget {
  /// Creates a material design app bar.
  ///
  /// Typically used in the [Scaffold.appBar] property.
  AppBar({
    Key key,
    this.leading,
    this.title,
    this.actions,
    this.flexibleSpace,
    this.bottom,
    this.elevation: 4.0,
    this.backgroundColor,
    this.brightness,
    this.iconTheme,
    this.textTheme,
    this.primary: true,
    this.centerTitle,
    this.toolbarOpacity: 1.0,
    this.bottomOpacity: 1.0,
  }) : preferredSize = new Size.fromHeight(kToolbarHeight + (bottom?.preferredSize?.height ?? 0.0)),
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
  /// [AppBar] will use a [BackButton] that calls [Navigator.maybePop].
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
  /// changes the [AppBar]'s height when scrolled.
  ///
  /// Typically a [FlexibleSpaceBar]. See [FlexibleSpaceBar] for details.
  final Widget flexibleSpace;

  /// This widget appears across the bottom of the app bar.
  ///
  /// Typically a [TabBar]. Only widgets that implement [PreferredSizeWidget] can
  /// be used at the bottom of an app bar.
  ///
  /// See also:
  ///
  ///  * [PreferredSize], which can be used to give an arbitrary widget a preferred size.
  final PreferredSizeWidget bottom;

  /// The z-coordinate at which to place this app bar.
  ///
  /// Defaults to 4, the appropriate elevation for app bars.
  final double elevation;

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
  /// If true, the appbar's toolbar elements and [bottom] widget will be
  /// padded on top by the height of the system status bar. The layout
  /// of the [flexibleSpace] is not affected by the [primary] property.
  final bool primary;

  /// Whether the title should be centered.
  ///
  /// Defaults to being adapted to the current [TargetPlatform].
  final bool centerTitle;

  /// How opaque the toolbar part of the app bar is.
  ///
  /// A value of 1.0 is fully opaque, and a value of 0.0 is fully transparent.
  ///
  /// Typically, this value is not changed from its default value (1.0). It is
  /// used by [SliverAppBar] to animate the opacity of the toolbar when the app
  /// bar is scrolled.
  final double toolbarOpacity;

  /// How opaque the bottom part of the app bar is.
  ///
  /// A value of 1.0 is fully opaque, and a value of 0.0 is fully transparent.
  ///
  /// Typically, this value is not changed from its default value (1.0). It is
  /// used by [SliverAppBar] to animate the opacity of the toolbar when the app
  /// bar is scrolled.
  final double bottomOpacity;

  /// A size whose height is the sum of [kToolbarHeight] and the [bottom] widget's
  /// preferred height.
  ///
  /// [Scaffold] uses this this size to set its app bar's height.
  @override
  final Size preferredSize;

  bool _getEffectiveCenterTitle(ThemeData themeData) {
    if (centerTitle != null)
      return centerTitle;
    assert(themeData.platform != null);
    switch (themeData.platform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        return false;
      case TargetPlatform.iOS:
        return actions == null || actions.length < 2;
    }
    return null;
  }

  @override
  _AppBarState createState() => new _AppBarState();
}

class _AppBarState extends State<AppBar> {
  void _handleDrawerButton() {
    Scaffold.of(context).openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    assert(!widget.primary || debugCheckHasMediaQuery(context));
    final ThemeData themeData = Theme.of(context);
    final ScaffoldState scaffold = Scaffold.of(context, nullOk: true);
    final ModalRoute<dynamic> parentRoute = ModalRoute.of(context);

    final bool hasDrawer = scaffold?.hasDrawer ?? false;
    final bool canPop = parentRoute?.canPop ?? false;
    final bool useCloseButton = parentRoute is MaterialPageRoute<dynamic> && parentRoute.fullscreenDialog;

    IconThemeData appBarIconTheme = widget.iconTheme ?? themeData.primaryIconTheme;
    TextStyle centerStyle = widget.textTheme?.title ?? themeData.primaryTextTheme.title;
    TextStyle sideStyle = widget.textTheme?.body1 ?? themeData.primaryTextTheme.body1;

    final Brightness brightness = widget.brightness ?? themeData.primaryColorBrightness;
    SystemChrome.setSystemUIOverlayStyle(brightness == Brightness.dark
      ? SystemUiOverlayStyle.light
      : SystemUiOverlayStyle.dark);

    if (widget.toolbarOpacity != 1.0) {
      final double opacity = const Interval(0.25, 1.0, curve: Curves.fastOutSlowIn).transform(widget.toolbarOpacity);
      if (centerStyle?.color != null)
        centerStyle = centerStyle.copyWith(color: centerStyle.color.withOpacity(opacity));
      if (sideStyle?.color != null)
        sideStyle = sideStyle.copyWith(color: sideStyle.color.withOpacity(opacity));
      appBarIconTheme = appBarIconTheme.copyWith(
        opacity: opacity * (appBarIconTheme.opacity ?? 1.0)
      );
    }

    final List<Widget> toolbarChildren = <Widget>[];
    Widget leading = widget.leading;
    if (leading == null) {
      if (hasDrawer) {
        leading = new IconButton(
          icon: const Icon(Icons.menu),
          onPressed: _handleDrawerButton,
          tooltip: 'Open navigation menu' // TODO(ianh): Figure out how to localize this string
        );
      } else {
        if (canPop)
          leading = useCloseButton ? const CloseButton() : const BackButton();
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

    if (widget.title != null) {
      toolbarChildren.add(
        new LayoutId(
          id: _ToolbarSlot.title,
          child: new DefaultTextStyle(
            style: centerStyle,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            child: widget.title,
          ),
        ),
      );
    }
    if (widget.actions != null && widget.actions.isNotEmpty) {
      toolbarChildren.add(
        new LayoutId(
          id: _ToolbarSlot.actions,
          child: new Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: widget.actions,
          ),
        ),
      );
    }

    final Widget toolbar = new Padding(
      padding: const EdgeInsets.only(right: 4.0),
      child: new CustomMultiChildLayout(
        delegate: new _ToolbarLayout(
          centerTitle: widget._getEffectiveCenterTitle(themeData),
        ),
        children: toolbarChildren,
      ),
    );

    // If the toolbar is allocated less than kToolbarHeight make it
    // appear to scroll upwards within its shrinking container.
    Widget appBar = new ClipRect(
      child: new CustomSingleChildLayout(
        delegate: const _ToolbarContainerLayout(),
        child: IconTheme.merge(
          data: appBarIconTheme,
          child: new DefaultTextStyle(
            style: sideStyle,
            child: toolbar,
          ),
        ),
      ),
    );

    if (widget.bottom != null) {
      appBar = new Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          new Flexible(
            child: new ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: kToolbarHeight),
              child: appBar,
            ),
          ),
          widget.bottomOpacity == 1.0 ? widget.bottom : new Opacity(
            opacity: const Interval(0.25, 1.0, curve: Curves.fastOutSlowIn).transform(widget.bottomOpacity),
            child: widget.bottom,
          ),
        ],
      );
    }

    // The padding applies to the toolbar and tabbar, not the flexible space.
    if (widget.primary) {
      appBar = new Padding(
        padding: new EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        child: appBar,
      );
    }

    appBar = new Align(
      alignment: FractionalOffset.topCenter,
      child: appBar,
    );

    if (widget.flexibleSpace != null) {
      appBar = new Stack(
        fit: StackFit.passthrough,
        children: <Widget>[
          widget.flexibleSpace,
          appBar,
        ],
      );
    }

    return new Material(
      color: widget.backgroundColor ?? themeData.primaryColor,
      elevation: widget.elevation,
      child: appBar,
    );
  }
}

class _FloatingAppBar extends StatefulWidget {
  const _FloatingAppBar({ Key key, this.child }) : super(key: key);

  final Widget child;

  @override
  _FloatingAppBarState createState() => new _FloatingAppBarState();
}

// A wrapper for the widget created by _SliverAppBarDelegate that starts and
/// stops the floating appbar's snap-into-view or snap-out-of-view animation.
class _FloatingAppBarState extends State<_FloatingAppBar> {
  ScrollPosition _position;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_position != null)
      _position.isScrollingNotifier.removeListener(_isScrollingListener);
    _position = Scrollable.of(context)?.position;
    if (_position != null)
      _position.isScrollingNotifier.addListener(_isScrollingListener);
  }

  @override
  void dispose() {
    if (_position != null)
      _position.isScrollingNotifier.removeListener(_isScrollingListener);
    super.dispose();
  }

  RenderSliverFloatingPersistentHeader _headerRenderer() {
    return context.ancestorRenderObjectOfType(const TypeMatcher<RenderSliverFloatingPersistentHeader>());
  }

  void _isScrollingListener() {
    if (_position == null)
      return;

    // When a scroll stops, then maybe snap the appbar into view.
    // Similarly, when a scroll starts, then maybe stop the snap animation.
    final RenderSliverFloatingPersistentHeader header = _headerRenderer();
    if (_position.isScrollingNotifier.value)
      header?.maybeStopSnapAnimation(_position.userScrollDirection);
    else
      header?.maybeStartSnapAnimation(_position.userScrollDirection);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate({
    @required this.leading,
    @required this.title,
    @required this.actions,
    @required this.flexibleSpace,
    @required this.bottom,
    @required this.elevation,
    @required this.forceElevated,
    @required this.backgroundColor,
    @required this.brightness,
    @required this.iconTheme,
    @required this.textTheme,
    @required this.primary,
    @required this.centerTitle,
    @required this.expandedHeight,
    @required this.collapsedHeight,
    @required this.topPadding,
    @required this.floating,
    @required this.pinned,
    @required this.snapConfiguration,
  }) : _bottomHeight = bottom?.preferredSize?.height ?? 0.0 {
    assert(primary || topPadding == 0.0);
  }

  final Widget leading;
  final Widget title;
  final List<Widget> actions;
  final Widget flexibleSpace;
  final PreferredSizeWidget bottom;
  final double elevation;
  final bool forceElevated;
  final Color backgroundColor;
  final Brightness brightness;
  final IconThemeData iconTheme;
  final TextTheme textTheme;
  final bool primary;
  final bool centerTitle;
  final double expandedHeight;
  final double collapsedHeight;
  final double topPadding;
  final bool floating;
  final bool pinned;

  final double _bottomHeight;

  @override
  double get minExtent => collapsedHeight ?? (topPadding + kToolbarHeight + _bottomHeight);

  @override
  double get maxExtent => math.max(topPadding + (expandedHeight ?? kToolbarHeight + _bottomHeight), minExtent);

  @override
  final FloatingHeaderSnapConfiguration snapConfiguration;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final double visibleMainHeight = maxExtent - shrinkOffset - topPadding;
    final double toolbarOpacity = pinned && !floating ? 1.0
      : ((visibleMainHeight - _bottomHeight) / kToolbarHeight).clamp(0.0, 1.0);
    final Widget appBar = FlexibleSpaceBar.createSettings(
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
        elevation: forceElevated || overlapsContent || (pinned && shrinkOffset > maxExtent - minExtent) ? elevation ?? 4.0 : 0.0,
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
    return floating ? new _FloatingAppBar(child: appBar) : appBar;
  }

  @override
  bool shouldRebuild(covariant _SliverAppBarDelegate oldDelegate) {
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
        || topPadding != oldDelegate.topPadding
        || pinned != oldDelegate.pinned
        || floating != oldDelegate.floating
        || snapConfiguration != oldDelegate.snapConfiguration;
  }

  @override
  String toString() {
    return '$runtimeType#$hashCode(topPadding: ${topPadding.toStringAsFixed(1)}, bottomHeight: ${_bottomHeight.toStringAsFixed(1)}, ...)';
  }
}

/// A material design app bar that integrates with a [CustomScrollView].
///
/// An app bar consists of a toolbar and potentially other widgets, such as a
/// [TabBar] and a [FlexibleSpaceBar]. App bars typically expose one or more
/// common actions with [IconButton]s which are optionally followed by a
/// [PopupMenuButton] for less common operations.
///
/// Sliver app bars are typically used as the first child of a
/// [CustomScrollView], which lets the app bar integrate with the scroll view so
/// that it can vary in height according to the scroll offset or float above the
/// other content in the scroll view. For a fixed-height app bar at the top of
/// the screen see [AppBar], which is used in the [Scaffold.appBar] slot.
///
/// The AppBar displays the toolbar widgets, [leading], [title], and
/// [actions], above the [bottom] (if any). If a [flexibleSpace] widget is
/// specified then it is stacked behind the toolbar and the bottom widget.
///
/// See also:
///
///  * [CustomScrollView], which integrates the [SliverAppBar] into its
///    scrolling.
///  * [AppBar], which is a fixed-height app bar for use in [Scaffold.appBar].
///  * [TabBar], which is typically placed in the [bottom] slot of the [AppBar]
///    if the screen has multiple pages arranged in tabs.
///  * [IconButton], which is used with [actions] to show buttons on the app bar.
///  * [PopupMenuButton], to show a popup menu on the app bar, via [actions].
///  * [FlexibleSpaceBar], which is used with [flexibleSpace] when the app bar
///    can expand and collapse.
///  * <https://material.google.com/layout/structure.html#structure-toolbars>
class SliverAppBar extends StatefulWidget {
  /// Creates a material design app bar that can be placed in a [CustomScrollView].
  const SliverAppBar({
    Key key,
    this.leading,
    this.title,
    this.actions,
    this.flexibleSpace,
    this.bottom,
    this.elevation,
    this.forceElevated: false,
    this.backgroundColor,
    this.brightness,
    this.iconTheme,
    this.textTheme,
    this.primary: true,
    this.centerTitle,
    this.expandedHeight,
    this.floating: false,
    this.pinned: false,
    this.snap: false,
  }) : assert(forceElevated != null),
       assert(primary != null),
       assert(floating != null),
       assert(pinned != null),
       assert(!pinned || !floating || bottom != null, 'A pinned and floating app bar must have a bottom widget.'),
       assert(snap != null),
       assert(floating || !snap, 'The "snap" argument only makes sense for floating app bars.'),
       super(key: key);

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
  ///             onPressed: () {
  ///               // handle the press
  ///             },
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
  /// Typically a [TabBar]. Only widgets that implement [PreferredSizeWidget] can
  /// be used at the bottom of an app bar.
  ///
  /// See also:
  ///
  ///  * [PreferredSize], which can be used to give an arbitrary widget a preferred size.
  final PreferredSizeWidget bottom;

  /// The z-coordinate at which to place this app bar when it is above other
  /// content.
  ///
  /// Defaults to 4, the appropriate elevation for app bars.
  ///
  /// If [forceElevated] is false, the elevation is ignored when the app bar has
  /// no content underneath it. For example, if the app bar is [pinned] but no
  /// content is scrolled under it, or if it scrolls with the content, then no
  /// shadow is drawn, regardless of the value of [elevation].
  final double elevation;

  /// Whether to show the shadow appropriate for the [elevation] even if the
  /// content is not scrolled under the [AppBar].
  ///
  /// Defaults to false, meaning that the [elevation] is only applied when the
  /// [AppBar] is being displayed over content that is scrolled under it.
  ///
  /// When set to true, the [elevation] is applied regardless.
  ///
  /// Ignored when [elevation] is zero.
  final bool forceElevated;

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
  final double expandedHeight;

  /// Whether the app bar should become visible as soon as the user scrolls
  /// towards the app bar.
  ///
  /// Otherwise, the user will need to scroll near the top of the scroll view to
  /// reveal the app bar.
  ///
  /// If [snap] is true then a scroll that exposes the app bar will trigger an
  /// animation that slides the entire app bar into view. Similarly if a scroll
  /// dismisses the app bar, the animation will slide it completely out of view.
  final bool floating;

  /// Whether the app bar should remain visible at the start of the scroll view.
  ///
  /// The app bar can still expand an contract as the user scrolls, but it will
  /// remain visible rather than being scrolled out of view.
  final bool pinned;

  /// If [snap] and [floating] are true then the floating app bar will "snap"
  /// into view.
  ///
  /// If [snap] is true then a scroll that exposes the floating app bar will
  /// trigger an animation that slides the entire app bar into view. Similarly if
  /// a scroll dismisses the app bar, the animation will slide the app bar
  /// completely out of view.
  ///
  /// Snapping only applies when the app bar is floating, not when the appbar
  /// appears at the top of its scroll view.
  final bool snap;

  @override
  _SliverAppBarState createState() => new _SliverAppBarState();
}

// This class is only Stateful because it owns the TickerProvider used
// by the floating appbar snap animation (via FloatingHeaderSnapConfiguration).
class _SliverAppBarState extends State<SliverAppBar> with TickerProviderStateMixin {
  FloatingHeaderSnapConfiguration _snapConfiguration;

  void _updateSnapConfiguration() {
    if (widget.snap && widget.floating) {
      _snapConfiguration = new FloatingHeaderSnapConfiguration(
        vsync: this,
        curve: Curves.easeOut,
        duration: const Duration(milliseconds: 200),
      );
    } else {
      _snapConfiguration = null;
    }
  }

  @override
  void initState() {
    super.initState();
    _updateSnapConfiguration();
  }

  @override
  void didUpdateWidget(SliverAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.snap != oldWidget.snap || widget.floating != oldWidget.floating)
      _updateSnapConfiguration();
  }

  @override
  Widget build(BuildContext context) {
    assert(!widget.primary || debugCheckHasMediaQuery(context));
    final double topPadding = widget.primary ? MediaQuery.of(context).padding.top : 0.0;
    final double collapsedHeight = (widget.pinned && widget.floating && widget.bottom != null)
      ? widget.bottom.preferredSize.height + topPadding : null;

    return new SliverPersistentHeader(
      floating: widget.floating,
      pinned: widget.pinned,
      delegate: new _SliverAppBarDelegate(
        leading: widget.leading,
        title: widget.title,
        actions: widget.actions,
        flexibleSpace: widget.flexibleSpace,
        bottom: widget.bottom,
        elevation: widget.elevation,
        forceElevated: widget.forceElevated,
        backgroundColor: widget.backgroundColor,
        brightness: widget.brightness,
        iconTheme: widget.iconTheme,
        textTheme: widget.textTheme,
        primary: widget.primary,
        centerTitle: widget.centerTitle,
        expandedHeight: widget.expandedHeight,
        collapsedHeight: collapsedHeight,
        topPadding: topPadding,
        floating: widget.floating,
        pinned: widget.pinned,
        snapConfiguration: _snapConfiguration,
      ),
    );
  }
}
