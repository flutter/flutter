// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'app_bar_theme.dart';
import 'back_button.dart';
import 'constants.dart';
import 'debug.dart';
import 'flexible_space_bar.dart';
import 'icon_button.dart';
import 'icons.dart';
import 'material.dart';
import 'material_localizations.dart';
import 'scaffold.dart';
import 'tabs.dart';
import 'text_theme.dart';
import 'theme.dart';

const double _kLeadingWidth = kToolbarHeight; // So the leading button is square.

// Bottom justify the kToolbarHeight child which may overflow the top.
class _ToolbarContainerLayout extends SingleChildLayoutDelegate {
  const _ToolbarContainerLayout();

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return constraints.tighten(height: kToolbarHeight);
  }

  @override
  Size getSize(BoxConstraints constraints) {
    return Size(constraints.maxWidth, kToolbarHeight);
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    return Offset(0.0, size.height - childSize.height);
  }

  @override
  bool shouldRelayout(_ToolbarContainerLayout oldDelegate) => false;
}

// TODO(eseidel): Toolbar needs to change size based on orientation:
// https://material.io/design/components/app-bars-top.html#specs
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
/// the app bar as a fixed-height widget at the top of the screen. For a scrollable
/// app bar, see [SliverAppBar], which embeds an [AppBar] in a sliver for use in
/// a [CustomScrollView].
///
/// When not used as [Scaffold.appBar], or when wrapped in a [Hero], place the app
/// bar in a [MediaQuery] to take care of the padding around the content of the
/// app bar if needed, as the padding will not be handled by [Scaffold].
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
/// flexibleSpace is behind all of them.](https://flutter.github.io/assets-for-api-docs/assets/material/app_bar.png)
///
/// If the [leading] widget is omitted, but the [AppBar] is in a [Scaffold] with
/// a [Drawer], then a button will be inserted to open the drawer. Otherwise, if
/// the nearest [Navigator] has any previous routes, a [BackButton] is inserted
/// instead. This behavior can be turned off by setting the [automaticallyImplyLeading]
/// to false. In that case a null leading widget will result in the middle/title widget
/// stretching to start.
///
/// {@tool dartpad --template=stateless_widget_material}
///
/// This sample shows an [AppBar] with two simple actions. The first action
/// opens a [SnackBar], while the second action navigates to a new page.
///
/// ```dart preamble
/// final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
/// final SnackBar snackBar = const SnackBar(content: Text('Showing Snackbar'));
///
/// void openPage(BuildContext context) {
///   Navigator.push(context, MaterialPageRoute(
///     builder: (BuildContext context) {
///       return Scaffold(
///         appBar: AppBar(
///           title: const Text('Next page'),
///         ),
///         body: const Center(
///           child: Text(
///             'This is the next page',
///             style: TextStyle(fontSize: 24),
///           ),
///         ),
///       );
///     },
///   ));
/// }
/// ```
///
/// ```dart
/// Widget build(BuildContext context) {
///   return Scaffold(
///     key: scaffoldKey,
///     appBar: AppBar(
///       title: const Text('AppBar Demo'),
///       actions: <Widget>[
///         IconButton(
///           icon: const Icon(Icons.add_alert),
///           tooltip: 'Show Snackbar',
///           onPressed: () {
///             scaffoldKey.currentState.showSnackBar(snackBar);
///           },
///         ),
///         IconButton(
///           icon: const Icon(Icons.navigate_next),
///           tooltip: 'Next page',
///           onPressed: () {
///             openPage(context);
///           },
///         ),
///       ],
///     ),
///     body: const Center(
///       child: Text(
///         'This is the home page',
///         style: TextStyle(fontSize: 24),
///       ),
///     ),
///   );
/// }
/// ```
/// {@end-tool}
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
///  * <https://material.io/design/components/app-bars-top.html>
class AppBar extends StatefulWidget implements PreferredSizeWidget {
  /// Creates a material design app bar.
  ///
  /// The arguments [primary], [toolbarOpacity], [bottomOpacity]
  /// and [automaticallyImplyLeading] must not be null. Additionally, if
  /// [elevation] is specified, it must be non-negative.
  ///
  /// If [backgroundColor], [elevation], [brightness], [iconTheme],
  /// [actionsIconTheme], or [textTheme] are null, then their [AppBarTheme]
  /// values will be used. If the corresponding [AppBarTheme] property is null,
  /// then the default specified in the property's documentation will be used.
  ///
  /// Typically used in the [Scaffold.appBar] property.
  AppBar({
    Key key,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.title,
    this.actions,
    this.flexibleSpace,
    this.bottom,
    this.elevation,
    this.shape,
    this.backgroundColor,
    this.brightness,
    this.iconTheme,
    this.actionsIconTheme,
    this.textTheme,
    this.primary = true,
    this.centerTitle,
    this.titleSpacing = NavigationToolbar.kMiddleSpacing,
    this.toolbarOpacity = 1.0,
    this.bottomOpacity = 1.0,
  }) : assert(automaticallyImplyLeading != null),
       assert(elevation == null || elevation >= 0.0),
       assert(primary != null),
       assert(titleSpacing != null),
       assert(toolbarOpacity != null),
       assert(bottomOpacity != null),
       preferredSize = Size.fromHeight(kToolbarHeight + (bottom?.preferredSize?.height ?? 0.0)),
       super(key: key);

  /// A widget to display before the [title].
  ///
  /// If this is null and [automaticallyImplyLeading] is set to true, the
  /// [AppBar] will imply an appropriate widget. For example, if the [AppBar] is
  /// in a [Scaffold] that also has a [Drawer], the [Scaffold] will fill this
  /// widget with an [IconButton] that opens the drawer (using [Icons.menu]). If
  /// there's no [Drawer] and the parent [Navigator] can go back, the [AppBar]
  /// will use a [BackButton] that calls [Navigator.maybePop].
  ///
  /// {@tool sample}
  ///
  /// The following code shows how the drawer button could be manually specified
  /// instead of relying on [automaticallyImplyLeading]:
  ///
  /// ```dart
  /// AppBar(
  ///   leading: Builder(
  ///     builder: (BuildContext context) {
  ///       return IconButton(
  ///         icon: const Icon(Icons.menu),
  ///         onPressed: () { Scaffold.of(context).openDrawer(); },
  ///         tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
  ///       );
  ///     },
  ///   ),
  /// )
  /// ```
  /// {@end-tool}
  ///
  /// The [Builder] is used in this example to ensure that the `context` refers
  /// to that part of the subtree. That way this code snippet can be used even
  /// inside the very code that is creating the [Scaffold] (in which case,
  /// without the [Builder], the `context` wouldn't be able to see the
  /// [Scaffold], since it would refer to an ancestor of that widget).
  ///
  /// See also:
  ///
  ///  * [Scaffold.appBar], in which an [AppBar] is usually placed.
  ///  * [Scaffold.drawer], in which the [Drawer] is usually placed.
  final Widget leading;

  /// Controls whether we should try to imply the leading widget if null.
  ///
  /// If true and [leading] is null, automatically try to deduce what the leading
  /// widget should be. If false and [leading] is null, leading space is given to [title].
  /// If leading widget is not null, this parameter has no effect.
  final bool automaticallyImplyLeading;

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
  final List<Widget> actions;

  /// This widget is stacked behind the toolbar and the tab bar. It's height will
  /// be the same as the app bar's overall height.
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

  /// The z-coordinate at which to place this app bar relative to its parent.
  ///
  /// This controls the size of the shadow below the app bar.
  ///
  /// The value is non-negative.
  ///
  /// If this property is null, then [ThemeData.appBarTheme.elevation] is used,
  /// if that is also null, the default value is 4, the appropriate elevation
  /// for app bars.
  final double elevation;

  /// The material's shape as well its shadow.
  ///
  /// A shadow is only displayed if the [elevation] is greater than
  /// zero.
  final ShapeBorder shape;

  /// The color to use for the app bar's material. Typically this should be set
  /// along with [brightness], [iconTheme], [textTheme].
  ///
  /// If this property is null, then [ThemeData.appBarTheme.color] is used,
  /// if that is also null, then [ThemeData.primaryColor] is used.
  final Color backgroundColor;

  /// The brightness of the app bar's material. Typically this is set along
  /// with [backgroundColor], [iconTheme], [textTheme].
  ///
  /// If this property is null, then [ThemeData.appBarTheme.brightness] is used,
  /// if that is also null, then [ThemeData.primaryColorBrightness] is used.
  final Brightness brightness;

  /// The color, opacity, and size to use for app bar icons. Typically this
  /// is set along with [backgroundColor], [brightness], [textTheme].
  ///
  /// If this property is null, then [ThemeData.appBarTheme.iconTheme] is used,
  /// if that is also null, then [ThemeData.primaryIconTheme] is used.
  final IconThemeData iconTheme;

  /// The color, opacity, and size to use for the icons that appear in the app
  /// bar's [actions]. This should only be used when the [actions] should be
  /// themed differently than the icon that appears in the app bar's [leading]
  /// widget.
  ///
  /// If this property is null, then [ThemeData.appBarTheme.actionsIconTheme] is
  /// used, if that is also null, then this falls back to [iconTheme].
  final IconThemeData actionsIconTheme;

  /// The typographic styles to use for text in the app bar. Typically this is
  /// set along with [brightness] [backgroundColor], [iconTheme].
  ///
  /// If this property is null, then [ThemeData.appBarTheme.textTheme] is used,
  /// if that is also null, then [ThemeData.primaryTextTheme] is used.
  final TextTheme textTheme;

  /// Whether this app bar is being displayed at the top of the screen.
  ///
  /// If true, the app bar's toolbar elements and [bottom] widget will be
  /// padded on top by the height of the system status bar. The layout
  /// of the [flexibleSpace] is not affected by the [primary] property.
  final bool primary;

  /// Whether the title should be centered.
  ///
  /// Defaults to being adapted to the current [TargetPlatform].
  final bool centerTitle;

  /// The spacing around [title] content on the horizontal axis. This spacing is
  /// applied even if there is no [leading] content or [actions]. If you want
  /// [title] to take all the space available, set this value to 0.0.
  ///
  /// Defaults to [NavigationToolbar.kMiddleSpacing].
  final double titleSpacing;

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

  bool _getEffectiveCenterTitle(ThemeData theme) {
    if (centerTitle != null)
      return centerTitle;
    assert(theme.platform != null);
    switch (theme.platform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        return false;
      case TargetPlatform.iOS:
        return actions == null || actions.length < 2;
    }
    return null;
  }

  @override
  _AppBarState createState() => _AppBarState();
}

class _AppBarState extends State<AppBar> {
  static const double _defaultElevation = 4.0;

  void _handleDrawerButton() {
    Scaffold.of(context).openDrawer();
  }

  void _handleDrawerButtonEnd() {
    Scaffold.of(context).openEndDrawer();
  }

  @override
  Widget build(BuildContext context) {
    assert(!widget.primary || debugCheckHasMediaQuery(context));
    assert(debugCheckHasMaterialLocalizations(context));
    final ThemeData theme = Theme.of(context);
    final AppBarTheme appBarTheme = AppBarTheme.of(context);
    final ScaffoldState scaffold = Scaffold.of(context, nullOk: true);
    final ModalRoute<dynamic> parentRoute = ModalRoute.of(context);

    final bool hasDrawer = scaffold?.hasDrawer ?? false;
    final bool hasEndDrawer = scaffold?.hasEndDrawer ?? false;
    final bool canPop = parentRoute?.canPop ?? false;
    final bool useCloseButton = parentRoute is PageRoute<dynamic> && parentRoute.fullscreenDialog;

    IconThemeData overallIconTheme = widget.iconTheme
      ?? appBarTheme.iconTheme
      ?? theme.primaryIconTheme;
    IconThemeData actionsIconTheme = widget.actionsIconTheme
      ?? appBarTheme.actionsIconTheme
      ?? overallIconTheme;
    TextStyle centerStyle = widget.textTheme?.title
      ?? appBarTheme.textTheme?.title
      ?? theme.primaryTextTheme.title;
    TextStyle sideStyle = widget.textTheme?.body1
      ?? appBarTheme.textTheme?.body1
      ?? theme.primaryTextTheme.body1;

    if (widget.toolbarOpacity != 1.0) {
      final double opacity = const Interval(0.25, 1.0, curve: Curves.fastOutSlowIn).transform(widget.toolbarOpacity);
      if (centerStyle?.color != null)
        centerStyle = centerStyle.copyWith(color: centerStyle.color.withOpacity(opacity));
      if (sideStyle?.color != null)
        sideStyle = sideStyle.copyWith(color: sideStyle.color.withOpacity(opacity));
      overallIconTheme = overallIconTheme.copyWith(
        opacity: opacity * (overallIconTheme.opacity ?? 1.0)
      );
      actionsIconTheme = actionsIconTheme.copyWith(
        opacity: opacity * (actionsIconTheme.opacity ?? 1.0)
      );
    }

    Widget leading = widget.leading;
    if (leading == null && widget.automaticallyImplyLeading) {
      if (hasDrawer) {
        leading = IconButton(
          icon: const Icon(Icons.menu),
          onPressed: _handleDrawerButton,
          tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
        );
      } else {
        if (canPop)
          leading = useCloseButton ? const CloseButton() : const BackButton();
      }
    }
    if (leading != null) {
      leading = ConstrainedBox(
        constraints: const BoxConstraints.tightFor(width: _kLeadingWidth),
        child: leading,
      );
    }

    Widget title = widget.title;
    if (title != null) {
      bool namesRoute;
      switch (theme.platform) {
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
           namesRoute = true;
           break;
        case TargetPlatform.iOS:
          break;
      }
      title = DefaultTextStyle(
        style: centerStyle,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        child: Semantics(
          namesRoute: namesRoute,
          child: title,
          header: true,
        ),
      );
    }

    Widget actions;
    if (widget.actions != null && widget.actions.isNotEmpty) {
      actions = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: widget.actions,
      );
    } else if (hasEndDrawer) {
      actions = IconButton(
        icon: const Icon(Icons.menu),
        onPressed: _handleDrawerButtonEnd,
        tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
      );
    }

    // Allow the trailing actions to have their own theme if necessary.
    if (actions != null) {
      actions = IconTheme.merge(
        data: actionsIconTheme,
        child: actions,
      );
    }

    final Widget toolbar = NavigationToolbar(
      leading: leading,
      middle: title,
      trailing: actions,
      centerMiddle: widget._getEffectiveCenterTitle(theme),
      middleSpacing: widget.titleSpacing,
    );

    // If the toolbar is allocated less than kToolbarHeight make it
    // appear to scroll upwards within its shrinking container.
    Widget appBar = ClipRect(
      child: CustomSingleChildLayout(
        delegate: const _ToolbarContainerLayout(),
        child: IconTheme.merge(
          data: overallIconTheme,
          child: DefaultTextStyle(
            style: sideStyle,
            child: toolbar,
          ),
        ),
      ),
    );
    if (widget.bottom != null) {
      appBar = Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: kToolbarHeight),
              child: appBar,
            ),
          ),
          widget.bottomOpacity == 1.0 ? widget.bottom : Opacity(
            opacity: const Interval(0.25, 1.0, curve: Curves.fastOutSlowIn).transform(widget.bottomOpacity),
            child: widget.bottom,
          ),
        ],
      );
    }

    // The padding applies to the toolbar and tabbar, not the flexible space.
    if (widget.primary) {
      appBar = SafeArea(
        top: true,
        child: appBar,
      );
    }

    appBar = Align(
      alignment: Alignment.topCenter,
      child: appBar,
    );

    if (widget.flexibleSpace != null) {
      appBar = Stack(
        fit: StackFit.passthrough,
        children: <Widget>[
          widget.flexibleSpace,
          appBar,
        ],
      );
    }
    final Brightness brightness = widget.brightness
      ?? appBarTheme.brightness
      ?? theme.primaryColorBrightness;
    final SystemUiOverlayStyle overlayStyle = brightness == Brightness.dark
      ? SystemUiOverlayStyle.light
      : SystemUiOverlayStyle.dark;

    return Semantics(
      container: true,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: overlayStyle,
        child: Material(
          color: widget.backgroundColor
            ?? appBarTheme.color
            ?? theme.primaryColor,
          elevation: widget.elevation
            ?? appBarTheme.elevation
            ?? _defaultElevation,
          shape: widget.shape,
          child: Semantics(
            explicitChildNodes: true,
            child: appBar,
          ),
        ),
      ),
    );
  }
}

class _FloatingAppBar extends StatefulWidget {
  const _FloatingAppBar({ Key key, this.child }) : super(key: key);

  final Widget child;

  @override
  _FloatingAppBarState createState() => _FloatingAppBarState();
}

// A wrapper for the widget created by _SliverAppBarDelegate that starts and
// stops the floating app bar's snap-into-view or snap-out-of-view animation.
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
    @required this.automaticallyImplyLeading,
    @required this.title,
    @required this.actions,
    @required this.flexibleSpace,
    @required this.bottom,
    @required this.elevation,
    @required this.forceElevated,
    @required this.backgroundColor,
    @required this.brightness,
    @required this.iconTheme,
    @required this.actionsIconTheme,
    @required this.textTheme,
    @required this.primary,
    @required this.centerTitle,
    @required this.titleSpacing,
    @required this.expandedHeight,
    @required this.collapsedHeight,
    @required this.topPadding,
    @required this.floating,
    @required this.pinned,
    @required this.snapConfiguration,
    @required this.shape,
  }) : assert(primary || topPadding == 0.0),
       _bottomHeight = bottom?.preferredSize?.height ?? 0.0;

  final Widget leading;
  final bool automaticallyImplyLeading;
  final Widget title;
  final List<Widget> actions;
  final Widget flexibleSpace;
  final PreferredSizeWidget bottom;
  final double elevation;
  final bool forceElevated;
  final Color backgroundColor;
  final Brightness brightness;
  final IconThemeData iconTheme;
  final IconThemeData actionsIconTheme;
  final TextTheme textTheme;
  final bool primary;
  final bool centerTitle;
  final double titleSpacing;
  final double expandedHeight;
  final double collapsedHeight;
  final double topPadding;
  final bool floating;
  final bool pinned;
  final ShapeBorder shape;

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

    // Truth table for `toolbarOpacity`:
    // pinned | floating | bottom != null || opacity
    // ----------------------------------------------
    //    0   |    0     |        0       ||  fade
    //    0   |    0     |        1       ||  fade
    //    0   |    1     |        0       ||  fade
    //    0   |    1     |        1       ||  fade
    //    1   |    0     |        0       ||  1.0
    //    1   |    0     |        1       ||  1.0
    //    1   |    1     |        0       ||  1.0
    //    1   |    1     |        1       ||  fade
    final double toolbarOpacity = !pinned || (floating && bottom != null)
      ? ((visibleMainHeight - _bottomHeight) / kToolbarHeight).clamp(0.0, 1.0)
      : 1.0;

    final Widget appBar = FlexibleSpaceBar.createSettings(
      minExtent: minExtent,
      maxExtent: maxExtent,
      currentExtent: math.max(minExtent, maxExtent - shrinkOffset),
      toolbarOpacity: toolbarOpacity,
      child: AppBar(
        leading: leading,
        automaticallyImplyLeading: automaticallyImplyLeading,
        title: title,
        actions: actions,
        flexibleSpace: (title == null && flexibleSpace != null)
          ? Semantics(child: flexibleSpace, header: true)
          : flexibleSpace,
        bottom: bottom,
        elevation: forceElevated || overlapsContent || (pinned && shrinkOffset > maxExtent - minExtent) ? elevation ?? 4.0 : 0.0,
        backgroundColor: backgroundColor,
        brightness: brightness,
        iconTheme: iconTheme,
        actionsIconTheme: actionsIconTheme,
        textTheme: textTheme,
        primary: primary,
        centerTitle: centerTitle,
        titleSpacing: titleSpacing,
        shape: shape,
        toolbarOpacity: toolbarOpacity,
        bottomOpacity: pinned ? 1.0 : (visibleMainHeight / _bottomHeight).clamp(0.0, 1.0),
      ),
    );
    return floating ? _FloatingAppBar(child: appBar) : appBar;
  }

  @override
  bool shouldRebuild(covariant _SliverAppBarDelegate oldDelegate) {
    return leading != oldDelegate.leading
        || automaticallyImplyLeading != oldDelegate.automaticallyImplyLeading
        || title != oldDelegate.title
        || actions != oldDelegate.actions
        || flexibleSpace != oldDelegate.flexibleSpace
        || bottom != oldDelegate.bottom
        || _bottomHeight != oldDelegate._bottomHeight
        || elevation != oldDelegate.elevation
        || backgroundColor != oldDelegate.backgroundColor
        || brightness != oldDelegate.brightness
        || iconTheme != oldDelegate.iconTheme
        || actionsIconTheme != oldDelegate.actionsIconTheme
        || textTheme != oldDelegate.textTheme
        || primary != oldDelegate.primary
        || centerTitle != oldDelegate.centerTitle
        || titleSpacing != oldDelegate.titleSpacing
        || expandedHeight != oldDelegate.expandedHeight
        || topPadding != oldDelegate.topPadding
        || pinned != oldDelegate.pinned
        || floating != oldDelegate.floating
        || snapConfiguration != oldDelegate.snapConfiguration;
  }

  @override
  String toString() {
    return '${describeIdentity(this)}(topPadding: ${topPadding.toStringAsFixed(1)}, bottomHeight: ${_bottomHeight.toStringAsFixed(1)}, ...)';
  }
}

/// A material design app bar that integrates with a [CustomScrollView].
///
/// An app bar consists of a toolbar and potentially other widgets, such as a
/// [TabBar] and a [FlexibleSpaceBar]. App bars typically expose one or more
/// common actions with [IconButton]s which are optionally followed by a
/// [PopupMenuButton] for less common operations.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=R9C5KMJKluE}
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
/// {@tool sample}
///
/// This is an example that could be included in a [CustomScrollView]'s
/// [CustomScrollView.slivers] list:
///
/// ```dart
/// SliverAppBar(
///   expandedHeight: 150.0,
///   flexibleSpace: const FlexibleSpaceBar(
///     title: Text('Available seats'),
///   ),
///   actions: <Widget>[
///     IconButton(
///       icon: const Icon(Icons.add_circle),
///       tooltip: 'Add new entry',
///       onPressed: () { /* ... */ },
///     ),
///   ]
/// )
/// ```
/// {@end-tool}
///
/// ## Animated Examples
///
/// The following animations show how app bars with different configurations
/// behave when a user scrolls up and then down again.
///
/// * App bar with [floating]: false, [pinned]: false, [snap]: false:
///   {@animation 476 400 https://flutter.github.io/assets-for-api-docs/assets/material/app_bar.mp4}
///
/// * App bar with [floating]: true, [pinned]: false, [snap]: false:
///   {@animation 476 400 https://flutter.github.io/assets-for-api-docs/assets/material/app_bar_floating.mp4}
///
/// * App bar with [floating]: true, [pinned]: false, [snap]: true:
///   {@animation 476 400 https://flutter.github.io/assets-for-api-docs/assets/material/app_bar_floating_snap.mp4}
///
/// * App bar with [floating]: true, [pinned]: true, [snap]: false:
///   {@animation 476 400 https://flutter.github.io/assets-for-api-docs/assets/material/app_bar_pinned_floating.mp4}
///
/// * App bar with [floating]: true, [pinned]: true, [snap]: true:
///   {@animation 476 400 https://flutter.github.io/assets-for-api-docs/assets/material/app_bar_pinned_floating_snap.mp4}
///
/// * App bar with [floating]: false, [pinned]: true, [snap]: false:
///   {@animation 476 400 https://flutter.github.io/assets-for-api-docs/assets/material/app_bar_pinned.mp4}
///
/// The property [snap] can only be set to true if [floating] is also true.
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
///  * <https://material.io/design/components/app-bars-top.html>
class SliverAppBar extends StatefulWidget {
  /// Creates a material design app bar that can be placed in a [CustomScrollView].
  ///
  /// The arguments [forceElevated], [primary], [floating], [pinned], [snap]
  /// and [automaticallyImplyLeading] must not be null.
  const SliverAppBar({
    Key key,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.title,
    this.actions,
    this.flexibleSpace,
    this.bottom,
    this.elevation,
    this.forceElevated = false,
    this.backgroundColor,
    this.brightness,
    this.iconTheme,
    this.actionsIconTheme,
    this.textTheme,
    this.primary = true,
    this.centerTitle,
    this.titleSpacing = NavigationToolbar.kMiddleSpacing,
    this.expandedHeight,
    this.floating = false,
    this.pinned = false,
    this.snap = false,
    this.shape,
  }) : assert(automaticallyImplyLeading != null),
       assert(forceElevated != null),
       assert(primary != null),
       assert(titleSpacing != null),
       assert(floating != null),
       assert(pinned != null),
       assert(snap != null),
       assert(floating || !snap, 'The "snap" argument only makes sense for floating app bars.'),
       super(key: key);

  /// A widget to display before the [title].
  ///
  /// If this is null and [automaticallyImplyLeading] is set to true, the [AppBar] will
  /// imply an appropriate widget. For example, if the [AppBar] is in a [Scaffold]
  /// that also has a [Drawer], the [Scaffold] will fill this widget with an
  /// [IconButton] that opens the drawer. If there's no [Drawer] and the parent
  /// [Navigator] can go back, the [AppBar] will use a [BackButton] that calls
  /// [Navigator.maybePop].
  final Widget leading;

  /// Controls whether we should try to imply the leading widget if null.
  ///
  /// If true and [leading] is null, automatically try to deduce what the leading
  /// widget should be. If false and [leading] is null, leading space is given to [title].
  /// If leading widget is not null, this parameter has no effect.
  final bool automaticallyImplyLeading;

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
  /// {@tool sample}
  ///
  /// ```dart
  /// Scaffold(
  ///   body: CustomScrollView(
  ///     primary: true,
  ///     slivers: <Widget>[
  ///       SliverAppBar(
  ///         title: Text('Hello World'),
  ///         actions: <Widget>[
  ///           IconButton(
  ///             icon: Icon(Icons.shopping_cart),
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
  /// )
  /// ```
  /// {@end-tool}
  final List<Widget> actions;

  /// This widget is stacked behind the toolbar and the tab bar. It's height will
  /// be the same as the app bar's overall height.
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
  /// content. This controls the size of the shadow below the app bar.
  ///
  /// If this property is null, then [ThemeData.appBarTheme.elevation] is used,
  /// if that is also null, the default value is 4, the appropriate elevation
  /// for app bars.
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
  /// If this property is null, then [ThemeData.appBarTheme.color] is used,
  /// if that is also null, then [ThemeData.primaryColor] is used.
  final Color backgroundColor;

  /// The brightness of the app bar's material. Typically this is set along
  /// with [backgroundColor], [iconTheme], [textTheme].
  ///
  /// If this property is null, then [ThemeData.appBarTheme.brightness] is used,
  /// if that is also null, then [ThemeData.primaryColorBrightness] is used.
  final Brightness brightness;

  /// The color, opacity, and size to use for app bar icons. Typically this
  /// is set along with [backgroundColor], [brightness], [textTheme].
  ///
  /// If this property is null, then [ThemeData.appBarTheme.iconTheme] is used,
  /// if that is also null, then [ThemeData.primaryIconTheme] is used.
  final IconThemeData iconTheme;

  /// The color, opacity, and size to use for trailing app bar icons. This
  /// should only be used when the trailing icons should be themed differently
  /// than the leading icons.
  ///
  /// If this property is null, then [ThemeData.appBarTheme.actionsIconTheme] is
  /// used, if that is also null, then this falls back to [iconTheme].
  final IconThemeData actionsIconTheme;

  /// The typographic styles to use for text in the app bar. Typically this is
  /// set along with [brightness] [backgroundColor], [iconTheme].
  ///
  /// If this property is null, then [ThemeData.appBarTheme.textTheme] is used,
  /// if that is also null, then [ThemeData.primaryTextTheme] is used.
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

  /// The spacing around [title] content on the horizontal axis. This spacing is
  /// applied even if there is no [leading] content or [actions]. If you want
  /// [title] to take all the space available, set this value to 0.0.
  ///
  /// Defaults to [NavigationToolbar.kMiddleSpacing].
  final double titleSpacing;

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
  ///
  /// ## Animated Examples
  ///
  /// The following animations show how the app bar changes its scrolling
  /// behavior based on the value of this property.
  ///
  /// * App bar with [floating] set to false:
  ///   {@animation 476 400 https://flutter.github.io/assets-for-api-docs/assets/material/app_bar.mp4}
  /// * App bar with [floating] set to true:
  ///   {@animation 476 400 https://flutter.github.io/assets-for-api-docs/assets/material/app_bar_floating.mp4}
  ///
  /// See also:
  ///
  ///  * [SliverAppBar] for more animated examples of how this property changes the
  ///    behavior of the app bar in combination with [pinned] and [snap].
  final bool floating;

  /// Whether the app bar should remain visible at the start of the scroll view.
  ///
  /// The app bar can still expand and contract as the user scrolls, but it will
  /// remain visible rather than being scrolled out of view.
  ///
  /// ## Animated Examples
  ///
  /// The following animations show how the app bar changes its scrolling
  /// behavior based on the value of this property.
  ///
  /// * App bar with [pinned] set to false:
  ///   {@animation 476 400 https://flutter.github.io/assets-for-api-docs/assets/material/app_bar.mp4}
  /// * App bar with [pinned] set to true:
  ///   {@animation 476 400 https://flutter.github.io/assets-for-api-docs/assets/material/app_bar_pinned.mp4}
  ///
  /// See also:
  ///
  ///  * [SliverAppBar] for more animated examples of how this property changes the
  ///    behavior of the app bar in combination with [floating].
  final bool pinned;

  /// The material's shape as well its shadow.
  ///
  /// A shadow is only displayed if the [elevation] is greater than
  /// zero.
  final ShapeBorder shape;

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
  ///
  /// ## Animated Examples
  ///
  /// The following animations show how the app bar changes its scrolling
  /// behavior based on the value of this property.
  ///
  /// * App bar with [snap] set to false:
  ///   {@animation 476 400 https://flutter.github.io/assets-for-api-docs/assets/material/app_bar_floating.mp4}
  /// * App bar with [snap] set to true:
  ///   {@animation 476 400 https://flutter.github.io/assets-for-api-docs/assets/material/app_bar_floating_snap.mp4}
  ///
  /// See also:
  ///
  ///  * [SliverAppBar] for more animated examples of how this property changes the
  ///    behavior of the app bar in combination with [pinned] and [floating].
  final bool snap;

  @override
  _SliverAppBarState createState() => _SliverAppBarState();
}

// This class is only Stateful because it owns the TickerProvider used
// by the floating appbar snap animation (via FloatingHeaderSnapConfiguration).
class _SliverAppBarState extends State<SliverAppBar> with TickerProviderStateMixin {
  FloatingHeaderSnapConfiguration _snapConfiguration;

  void _updateSnapConfiguration() {
    if (widget.snap && widget.floating) {
      _snapConfiguration = FloatingHeaderSnapConfiguration(
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

    return MediaQuery.removePadding(
      context: context,
      removeBottom: true,
      child: SliverPersistentHeader(
        floating: widget.floating,
        pinned: widget.pinned,
        delegate: _SliverAppBarDelegate(
          leading: widget.leading,
          automaticallyImplyLeading: widget.automaticallyImplyLeading,
          title: widget.title,
          actions: widget.actions,
          flexibleSpace: widget.flexibleSpace,
          bottom: widget.bottom,
          elevation: widget.elevation,
          forceElevated: widget.forceElevated,
          backgroundColor: widget.backgroundColor,
          brightness: widget.brightness,
          iconTheme: widget.iconTheme,
          actionsIconTheme: widget.actionsIconTheme,
          textTheme: widget.textTheme,
          primary: widget.primary,
          centerTitle: widget.centerTitle,
          titleSpacing: widget.titleSpacing,
          expandedHeight: widget.expandedHeight,
          collapsedHeight: collapsedHeight,
          topPadding: topPadding,
          floating: widget.floating,
          pinned: widget.pinned,
          shape: widget.shape,
          snapConfiguration: _snapConfiguration,
        ),
      ),
    );
  }
}
