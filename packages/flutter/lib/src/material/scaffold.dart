// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'app_bar.dart';
import 'bottom_sheet.dart';
import 'drawer.dart';
import 'icons.dart';
import 'icon_button.dart';
import 'material.dart';
import 'snack_bar.dart';

const double _kFloatingActionButtonMargin = 16.0; // TODO(hmuller): should be device dependent
const Duration _kFloatingActionButtonSegue = const Duration(milliseconds: 400);

/// The Scaffold's appbar is the toolbar, tabbar, and the "flexible space" that's
/// stacked behind them. The Scaffold's appBarBehavior defines how the appbar
/// responds to scrolling the application.
enum AppBarBehavior {
  /// The tool bar's layout does not respond to scrolling.
  anchor,

  /// The tool bar's appearance and layout depend on the scrollOffset of the
  /// Scrollable identified by the Scaffold's scrollableKey. With the scrollOffset
  /// at 0.0, scrolling downwards causes the toolbar's flexible space to shrink,
  /// and then the entire toolbar fade outs and scrolls off the top of the screen.
  /// Scrolling upwards always causes the toolbar to reappear.
  scroll,

  /// The tool bar's appearance and layout depend on the scrollOffset of the
  /// Scrollable identified by the Scaffold's scrollableKey. With the scrollOffset
  /// at 0.0, Scrolling downwards causes the toolbar's flexible space to shrink.
  /// Other than that, the toolbar remains anchored at the top.
  under,
}

enum _ScaffoldSlot {
  body,
  appBar,
  bottomSheet,
  snackBar,
  floatingActionButton,
  drawer,
}

class _ScaffoldLayout extends MultiChildLayoutDelegate {
  _ScaffoldLayout({ this.padding, this.appBarBehavior: AppBarBehavior.anchor });

  final EdgeInsets padding;
  final AppBarBehavior appBarBehavior;

  @override
  void performLayout(Size size) {
    BoxConstraints looseConstraints = new BoxConstraints.loose(size);

    // This part of the layout has the same effect as putting the app bar and
    // body in a column and making the body flexible. What's different is that
    // in this case the app bar appears -after- the body in the stacking order,
    // so the app bar's shadow is drawn on top of the body.

    final BoxConstraints fullWidthConstraints = looseConstraints.tighten(width: size.width);
    double contentTop = padding.top;
    double contentBottom = size.height - padding.bottom;

    if (hasChild(_ScaffoldSlot.appBar)) {
      final double appBarHeight = layoutChild(_ScaffoldSlot.appBar, fullWidthConstraints).height;
      if (appBarBehavior == AppBarBehavior.anchor)
        contentTop = appBarHeight;
      positionChild(_ScaffoldSlot.appBar, Offset.zero);
    }

    if (hasChild(_ScaffoldSlot.body)) {
      final double bodyHeight = contentBottom - contentTop;
      final BoxConstraints bodyConstraints = fullWidthConstraints.tighten(height: bodyHeight);
      layoutChild(_ScaffoldSlot.body, bodyConstraints);
      positionChild(_ScaffoldSlot.body, new Offset(0.0, contentTop));
    }

    // The BottomSheet and the SnackBar are anchored to the bottom of the parent,
    // they're as wide as the parent and are given their intrinsic height.
    // If all three elements are present then either the center of the FAB straddles
    // the top edge of the BottomSheet or the bottom of the FAB is
    // _kFloatingActionButtonMargin above the SnackBar, whichever puts the FAB
    // the farthest above the bottom of the parent. If only the FAB is has a
    // non-zero height then it's inset from the parent's right and bottom edges
    // by _kFloatingActionButtonMargin.

    Size bottomSheetSize = Size.zero;
    Size snackBarSize = Size.zero;

    if (hasChild(_ScaffoldSlot.bottomSheet)) {
      bottomSheetSize = layoutChild(_ScaffoldSlot.bottomSheet, fullWidthConstraints);
      positionChild(_ScaffoldSlot.bottomSheet, new Offset((size.width - bottomSheetSize.width) / 2.0, contentBottom - bottomSheetSize.height));
    }

    if (hasChild(_ScaffoldSlot.snackBar)) {
      snackBarSize = layoutChild(_ScaffoldSlot.snackBar, fullWidthConstraints);
      positionChild(_ScaffoldSlot.snackBar, new Offset(0.0, contentBottom - snackBarSize.height));
    }

    if (hasChild(_ScaffoldSlot.floatingActionButton)) {
      final Size fabSize = layoutChild(_ScaffoldSlot.floatingActionButton, looseConstraints);
      final double fabX = size.width - fabSize.width - _kFloatingActionButtonMargin;
      double fabY = contentBottom - fabSize.height - _kFloatingActionButtonMargin;
      if (snackBarSize.height > 0.0)
        fabY = math.min(fabY, contentBottom - snackBarSize.height - fabSize.height - _kFloatingActionButtonMargin);
      if (bottomSheetSize.height > 0.0)
        fabY = math.min(fabY, contentBottom - bottomSheetSize.height - fabSize.height / 2.0);
      positionChild(_ScaffoldSlot.floatingActionButton, new Offset(fabX, fabY));
    }

    if (hasChild(_ScaffoldSlot.drawer)) {
      layoutChild(_ScaffoldSlot.drawer, new BoxConstraints.tight(size));
      positionChild(_ScaffoldSlot.drawer, Offset.zero);
    }
  }

  @override
  bool shouldRelayout(_ScaffoldLayout oldDelegate) {
    return padding != oldDelegate.padding;
  }
}

class _FloatingActionButtonTransition extends StatefulWidget {
  _FloatingActionButtonTransition({
    Key key,
    this.child
  }) : super(key: key) {
    assert(child != null);
  }

  final Widget child;

  @override
  _FloatingActionButtonTransitionState createState() => new _FloatingActionButtonTransitionState();
}

class _FloatingActionButtonTransitionState extends State<_FloatingActionButtonTransition> {
  final AnimationController controller = new AnimationController(duration: _kFloatingActionButtonSegue);
  Widget oldChild;

  @override
  void initState() {
    super.initState();
    controller.forward().then((_) {
      oldChild = null;
    });
  }

  @override
  void dispose() {
    controller.stop();
    super.dispose();
  }

  @override
  void didUpdateConfig(_FloatingActionButtonTransition oldConfig) {
    if (Widget.canUpdate(oldConfig.child, config.child))
      return;
    oldChild = oldConfig.child;
    controller
      ..value = 0.0
      ..forward().then((_) {
        oldChild = null;
      });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = new List<Widget>();
    if (oldChild != null) {
      children.add(new ScaleTransition(
        // TODO(abarth): We should use ReversedAnimation here.
        scale: new Tween<double>(
          begin: 1.0,
          end: 0.0
        ).animate(new CurvedAnimation(
          parent: controller,
          curve: const Interval(0.0, 0.5, curve: Curves.easeIn)
        )),
        child: oldChild
      ));
    }

    children.add(new ScaleTransition(
      scale: new CurvedAnimation(
        parent: controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn)
      ),
      child: config.child
    ));

    return new Stack(children: children);
  }
}

/// Implements the basic material design visual layout structure.
///
/// This class provides APIs for showing drawers, snackbars, and bottom sheets.
///
/// See: <https://www.google.com/design/spec/layout/structure.html>
class Scaffold extends StatefulWidget {
  Scaffold({
    Key key,
    this.appBar,
    this.body,
    this.floatingActionButton,
    this.drawer,
    this.scrollableKey,
    this.appBarBehavior: AppBarBehavior.anchor
  }) : super(key: key) {
    assert(scrollableKey != null ? (appBarBehavior != AppBarBehavior.anchor) : true);
  }

  final AppBar appBar;
  final Widget body;
  final Widget floatingActionButton;
  final Widget drawer;
  final Key scrollableKey;
  final AppBarBehavior appBarBehavior;

  /// The state from the closest instance of this class that encloses the given context.
  static ScaffoldState of(BuildContext context) => context.ancestorStateOfType(const TypeMatcher<ScaffoldState>());

  @override
  ScaffoldState createState() => new ScaffoldState();
}

class ScaffoldState extends State<Scaffold> {

  // APPBAR API

  AnimationController _appBarController;

  /// The animation controlling the size of the app bar.
  ///
  /// Useful for linking animation effects to the expansion and collapse of the
  /// app bar.
  Animation<double> get appBarAnimation => _appBarController.view;

  /// The height of the app bar when fully expanded.
  ///
  /// See [AppBar.expandedHeight].
  double get appBarHeight => config.appBar?.expandedHeight ?? 0.0;

  // DRAWER API

  final GlobalKey<DrawerControllerState> _drawerKey = new GlobalKey<DrawerControllerState>();

  /// Opens the [Drawer] (if any).
  ///
  /// If the scaffold has a non-null [Scaffold.drawer], this function will cause
  /// the drawer to begin its entrance animation.
  void openDrawer() {
    _drawerKey.currentState?.open();
  }

  // SNACKBAR API

  Queue<ScaffoldFeatureController<SnackBar, Null>> _snackBars = new Queue<ScaffoldFeatureController<SnackBar, Null>>();
  AnimationController _snackBarController;
  Timer _snackBarTimer;

  /// Shows a [SnackBar] at the bottom fo the scaffold.
  ///
  /// A scaffold can show at most one snack bar at a time. If this function is
  /// called while another snack bar is already visible, the given snack bar
  /// will be added to a queue and displayed after the earlier snack bars have
  /// closed.
  ScaffoldFeatureController<SnackBar, Null> showSnackBar(SnackBar snackbar) {
    _snackBarController ??= SnackBar.createAnimationController()
      ..addStatusListener(_handleSnackBarStatusChange);
    if (_snackBars.isEmpty) {
      assert(_snackBarController.isDismissed);
      _snackBarController.forward();
    }
    ScaffoldFeatureController<SnackBar, Null> controller;
    controller = new ScaffoldFeatureController<SnackBar, Null>._(
      // We provide a fallback key so that if back-to-back snackbars happen to
      // match in structure, material ink splashes and highlights don't survive
      // from one to the next.
      snackbar.withAnimation(_snackBarController, fallbackKey: new UniqueKey()),
      new Completer<Null>(),
      () {
        assert(_snackBars.first == controller);
        _hideSnackBar();
      },
      null // SnackBar doesn't use a builder function so setState() wouldn't rebuild it
    );
    setState(() {
      _snackBars.addLast(controller);
    });
    return controller;
  }

  void _handleSnackBarStatusChange(AnimationStatus status) {
    switch (status) {
      case AnimationStatus.dismissed:
        assert(_snackBars.isNotEmpty);
        setState(() {
          _snackBars.removeFirst();
        });
        if (_snackBars.isNotEmpty)
          _snackBarController.forward();
        break;
      case AnimationStatus.completed:
        setState(() {
          assert(_snackBarTimer == null);
          // build will create a new timer if necessary to dismiss the snack bar
        });
        break;
      case AnimationStatus.forward:
      case AnimationStatus.reverse:
        break;
    }
  }

  /// Removes the current [SnackBar] (if any) immediately.
  ///
  /// The removed snack bar does not run its normal exit animation. If there are
  /// any queued snack bars, they begin their entrance animation immediately.
  void removeCurrentSnackBar() {
    if (_snackBars.isEmpty)
      return;
    Completer<Null> completer = _snackBars.first._completer;
    if (!completer.isCompleted)
      completer.complete();
    _snackBarTimer?.cancel();
    _snackBarTimer = null;
    _snackBarController.value = 0.0;
  }

  void _hideSnackBar() {
    assert(_snackBarController.status == AnimationStatus.forward ||
           _snackBarController.status == AnimationStatus.completed);
    _snackBars.first._completer.complete();
    _snackBarController.reverse();
    _snackBarTimer?.cancel();
    _snackBarTimer = null;
  }


  // PERSISTENT BOTTOM SHEET API

  List<Widget> _dismissedBottomSheets;
  PersistentBottomSheetController<dynamic> _currentBottomSheet;

  /// Shows a persistent material design bottom sheet.
  ///
  /// A persistent bottom sheet shows information that supplements the primary
  /// content of the app. A persistent bottom sheet remains visible even when
  /// the user interacts with other parts of the app.
  ///
  /// A closely related widget is  a modal bottom sheet, which is an alternative
  /// to a menu or a dialog and prevents the user from interacting with the rest
  /// of the app. Modal bottom sheets can be created and displayed with the
  /// [showModalBottomSheet] function.
  ///
  /// Returns a contoller that can be used to close and otherwise manipulate the
  /// button sheet.
  ///
  /// See also:
  ///
  ///  * [BottomSheet]
  ///  * [showModalBottomSheet]
  ///  * <https://www.google.com/design/spec/components/bottom-sheets.html#bottom-sheets-persistent-bottom-sheets>
  PersistentBottomSheetController<dynamic/*=T*/> showBottomSheet/*<T>*/(WidgetBuilder builder) {
    if (_currentBottomSheet != null) {
      _currentBottomSheet.close();
      assert(_currentBottomSheet == null);
    }
    Completer<dynamic/*=T*/> completer = new Completer<dynamic/*=T*/>();
    GlobalKey<_PersistentBottomSheetState> bottomSheetKey = new GlobalKey<_PersistentBottomSheetState>();
    AnimationController controller = BottomSheet.createAnimationController()
      ..forward();
    _PersistentBottomSheet bottomSheet;
    LocalHistoryEntry entry = new LocalHistoryEntry(
      onRemove: () {
        assert(_currentBottomSheet._widget == bottomSheet);
        assert(bottomSheetKey.currentState != null);
        bottomSheetKey.currentState.close();
        _dismissedBottomSheets ??= <Widget>[];
        _dismissedBottomSheets.add(bottomSheet);
        _currentBottomSheet = null;
        completer.complete();
      }
    );
    bottomSheet = new _PersistentBottomSheet(
      key: bottomSheetKey,
      animationController: controller,
      onClosing: () {
        assert(_currentBottomSheet._widget == bottomSheet);
        entry.remove();
      },
      onDismissed: () {
        assert(_dismissedBottomSheets != null);
        setState(() {
          _dismissedBottomSheets.remove(bottomSheet);
        });
      },
      builder: builder
    );
    ModalRoute.of(context).addLocalHistoryEntry(entry);
    setState(() {
      _currentBottomSheet = new PersistentBottomSheetController<dynamic/*=T*/>._(
        bottomSheet,
        completer,
        () => entry.remove(),
        (VoidCallback fn) { bottomSheetKey.currentState?.setState(fn); }
      );
    });
    return _currentBottomSheet;
  }


  // INTERNALS

  @override
  void initState() {
    super.initState();
    _appBarController = new AnimationController();
    List<double> scrollValues = PageStorage.of(context)?.readState(context);
    if (scrollValues != null) {
      assert(scrollValues.length == 2);
      _scrollOffset = scrollValues[0];
      _scrollOffsetDelta = scrollValues[1];
    }
  }

  @override
  void dispose() {
    _appBarController.stop();
    _snackBarController?.stop();
    _snackBarController = null;
    _snackBarTimer?.cancel();
    _snackBarTimer = null;
    PageStorage.of(context)?.writeState(context, <double>[_scrollOffset, _scrollOffsetDelta]);
    super.dispose();
  }

  void _addIfNonNull(List<LayoutId> children, Widget child, Object childId) {
    if (child != null)
      children.add(new LayoutId(child: child, id: childId));
  }

  bool _shouldShowBackArrow;

  Widget _getModifiedAppBar({ EdgeInsets padding, int elevation, double actualHeight}) {
    AppBar appBar = config.appBar;
    if (appBar == null)
      return null;
    Widget leading = appBar.leading;
    if (leading == null) {
      if (config.drawer != null) {
        leading = new IconButton(
          icon: Icons.menu,
          alignment: FractionalOffset.centerLeft,
          onPressed: openDrawer,
          tooltip: 'Open navigation menu' // TODO(ianh): Figure out how to localize this string
        );
      } else {
        _shouldShowBackArrow ??= Navigator.canPop(context);
        if (_shouldShowBackArrow) {
          leading = new IconButton(
            icon: Icons.arrow_back,
            alignment: FractionalOffset.centerLeft,
            onPressed: () => Navigator.pop(context),
            tooltip: 'Back' // TODO(ianh): Figure out how to localize this string
          );
        }
      }
    }
    return appBar.copyWith(
      elevation: elevation ?? appBar.elevation ?? 4,
      padding: new EdgeInsets.only(top: padding.top),
      leading: leading,
      actualHeight: actualHeight
    );
  }

  double _scrollOffset = 0.0;
  double _scrollOffsetDelta = 0.0;
  double _floatingAppBarHeight = 0.0;

  bool _handleScrollNotification(ScrollNotification notification) {
    final ScrollableState scrollable = notification.scrollable;
    if ((scrollable.config.scrollDirection == Axis.vertical) &&
        (config.scrollableKey == null || config.scrollableKey == scrollable.config.key)) {
      final double newScrollOffset = scrollable.scrollOffset;
      setState(() {
        _scrollOffsetDelta = _scrollOffset - newScrollOffset;
        _scrollOffset = newScrollOffset;
      });
    }
    return false;
  }

  Widget _buildAnchoredAppBar(double expandedHeight, double height, EdgeInsets padding) {
    // Drive _appBarController to the point where the flexible space has disappeared.
    _appBarController.value = (expandedHeight - height) / expandedHeight;
    return new SizedBox(
      height: height,
      child: _getModifiedAppBar(padding: padding, actualHeight: height)
    );
  }

  Widget _buildScrollableAppBar(BuildContext context) {
    final EdgeInsets padding = MediaQuery.of(context).padding;
    final double expandedHeight = (config.appBar?.expandedHeight ?? 0.0) + padding.top;
    final double collapsedHeight = (config.appBar?.collapsedHeight ?? 0.0) + padding.top;
    final double minimumHeight = (config.appBar?.minimumHeight ?? 0.0) + padding.top;
    Widget appBar;

    if (_scrollOffset <= expandedHeight && _scrollOffset >= expandedHeight - minimumHeight) {
      // scrolled to the top, flexible space collapsed, only the toolbar and tabbar are (partially) visible.
      if (config.appBarBehavior == AppBarBehavior.under) {
        appBar = _buildAnchoredAppBar(expandedHeight, minimumHeight, padding);
      } else {
        final double height = math.max(_floatingAppBarHeight, expandedHeight - _scrollOffset);
        _appBarController.value = (expandedHeight - height) / expandedHeight;
        appBar = new SizedBox(
          height: height,
          child: _getModifiedAppBar(padding: padding, actualHeight: height)
        );
      }
    } else if (_scrollOffset > expandedHeight) {
      // scrolled past the entire app bar, maybe show the "floating" toolbar.
      if (config.appBarBehavior == AppBarBehavior.under) {
        appBar = _buildAnchoredAppBar(expandedHeight, minimumHeight, padding);
      } else {
        _floatingAppBarHeight = (_floatingAppBarHeight + _scrollOffsetDelta).clamp(0.0, collapsedHeight);
        _appBarController.value = (expandedHeight - _floatingAppBarHeight) / expandedHeight;
        appBar = new SizedBox(
          height: _floatingAppBarHeight,
          child: _getModifiedAppBar(padding: padding, actualHeight: _floatingAppBarHeight)
        );
      }
    } else {
      // _scrollOffset < expandedHeight - collapsedHeight, scrolled to the top, flexible space is visible]
      final double height = expandedHeight - _scrollOffset.clamp(0.0, expandedHeight);
      _appBarController.value = (expandedHeight - height) / expandedHeight;
      appBar = new SizedBox(
        height: height,
        child: _getModifiedAppBar(padding: padding, elevation: 0, actualHeight: height)
      );
      _floatingAppBarHeight = 0.0;

    }

    return appBar;
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets padding = MediaQuery.of(context).padding;

    if (_snackBars.length > 0) {
      final ModalRoute<dynamic> route = ModalRoute.of(context);
      if (route == null || route.isCurrent) {
        if (_snackBarController.isCompleted && _snackBarTimer == null)
          _snackBarTimer = new Timer(_snackBars.first._widget.duration, _hideSnackBar);
      } else {
        _snackBarTimer?.cancel();
        _snackBarTimer = null;
      }
    }

    final List<LayoutId> children = new List<LayoutId>();
    _addIfNonNull(children, config.body, _ScaffoldSlot.body);
    if (config.appBarBehavior == AppBarBehavior.anchor) {
      final double expandedHeight = (config.appBar?.expandedHeight ?? 0.0) + padding.top;
      final Widget appBar = new ConstrainedBox(
          child: _getModifiedAppBar(padding: padding, actualHeight: expandedHeight),
        constraints: new BoxConstraints(maxHeight: expandedHeight)
      );
      _addIfNonNull(children, appBar, _ScaffoldSlot.appBar);
    } else {
      children.add(new LayoutId(child: _buildScrollableAppBar(context), id: _ScaffoldSlot.appBar));
    }
    // Otherwise the AppBar will be part of a [app bar, body] Stack. See AppBarBehavior.scroll below.

    if (_currentBottomSheet != null ||
        (_dismissedBottomSheets != null && _dismissedBottomSheets.isNotEmpty)) {
      final List<Widget> bottomSheets = <Widget>[];
      if (_dismissedBottomSheets != null && _dismissedBottomSheets.isNotEmpty)
        bottomSheets.addAll(_dismissedBottomSheets);
      if (_currentBottomSheet != null)
        bottomSheets.add(_currentBottomSheet._widget);
      Widget stack = new Stack(
        children: bottomSheets,
        alignment: FractionalOffset.bottomCenter
      );
      _addIfNonNull(children, stack, _ScaffoldSlot.bottomSheet);
    }

    if (_snackBars.isNotEmpty)
      _addIfNonNull(children, _snackBars.first._widget, _ScaffoldSlot.snackBar);

    if (config.floatingActionButton != null) {
      final Widget fab = new _FloatingActionButtonTransition(
        key: new ValueKey<Key>(config.floatingActionButton.key),
        child: config.floatingActionButton
      );
      children.add(new LayoutId(child: fab, id: _ScaffoldSlot.floatingActionButton));
    }

    if (config.drawer != null) {
      children.add(new LayoutId(
        id: _ScaffoldSlot.drawer,
        child: new DrawerController(
          key: _drawerKey,
          child: config.drawer
        )
      ));
    }

    Widget application;

    if (config.appBarBehavior != AppBarBehavior.anchor) {
      application = new NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,
        child: new CustomMultiChildLayout(
          children: children,
          delegate: new _ScaffoldLayout(
            padding: EdgeInsets.zero,
            appBarBehavior: config.appBarBehavior
          )
        )
      );
    } else {
      application = new CustomMultiChildLayout(
        children: children,
        delegate: new _ScaffoldLayout(
          padding: padding
        )
      );
    }

    return new Material(child: application);
  }
}

class ScaffoldFeatureController<T extends Widget, U> {
  const ScaffoldFeatureController._(this._widget, this._completer, this.close, this.setState);
  final T _widget;
  final Completer<U> _completer;
  Future<U> get closed => _completer.future;
  final VoidCallback close; // call this to close the bottom sheet or snack bar
  final StateSetter setState;
}

class _PersistentBottomSheet extends StatefulWidget {
  _PersistentBottomSheet({
    Key key,
    this.animationController,
    this.onClosing,
    this.onDismissed,
    this.builder
  }) : super(key: key);

  final AnimationController animationController;
  final VoidCallback onClosing;
  final VoidCallback onDismissed;
  final WidgetBuilder builder;

  @override
  _PersistentBottomSheetState createState() => new _PersistentBottomSheetState();
}

class _PersistentBottomSheetState extends State<_PersistentBottomSheet> {

  // We take ownership of the animation controller given in the first configuration.
  // We also share control of that animation with out BottomSheet widget.

  @override
  void initState() {
    super.initState();
    assert(config.animationController.status == AnimationStatus.forward);
    config.animationController.addStatusListener(_handleStatusChange);
  }

  @override
  void didUpdateConfig(_PersistentBottomSheet oldConfig) {
    super.didUpdateConfig(oldConfig);
    assert(config.animationController == oldConfig.animationController);
  }

  @override
  void dispose() {
    config.animationController.stop();
    super.dispose();
  }

  void close() {
    config.animationController.reverse();
  }

  void _handleStatusChange(AnimationStatus status) {
    if (status == AnimationStatus.dismissed && config.onDismissed != null)
      config.onDismissed();
  }

  @override
  Widget build(BuildContext context) {
    return new AnimatedBuilder(
      animation: config.animationController,
      builder: (BuildContext context, Widget child) {
        return new Align(
          alignment: FractionalOffset.topLeft,
          heightFactor: config.animationController.value,
          child: child
        );
      },
      child: new Semantics(
        container: true,
        child: new BottomSheet(
          animationController: config.animationController,
          onClosing: config.onClosing,
          builder: config.builder
        )
      )
    );
  }

}

/// A [ScaffoldFeatureController] for persistent bottom sheets.
///
/// This is the type of objects returned by [Scaffold.showBottomSheet].
class PersistentBottomSheetController<T> extends ScaffoldFeatureController<_PersistentBottomSheet, T> {
  const PersistentBottomSheetController._(
    _PersistentBottomSheet widget,
    Completer<T> completer,
    VoidCallback close,
    StateSetter setState
  ) : super._(widget, completer, close, setState);
}
