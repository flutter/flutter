// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'bottom_sheet.dart';
import 'constants.dart';
import 'drawer.dart';
import 'icons.dart';
import 'icon_button.dart';
import 'material.dart';
import 'snack_bar.dart';
import 'tool_bar.dart';

const double _kFloatingActionButtonMargin = 16.0; // TODO(hmuller): should be device dependent
const Duration _kFloatingActionButtonSegue = const Duration(milliseconds: 400);

enum AppBarBehavior {
  anchor,
  scroll,
}

enum _ScaffoldSlot {
  body,
  toolBar,
  bottomSheet,
  snackBar,
  floatingActionButton,
  drawer,
}

class _ScaffoldLayout extends MultiChildLayoutDelegate {
  _ScaffoldLayout({ this.padding });

  final EdgeDims padding;

  void performLayout(Size size, BoxConstraints constraints) {

    BoxConstraints looseConstraints = constraints.loosen();

    // This part of the layout has the same effect as putting the toolbar and
    // body in a column and making the body flexible. What's different is that
    // in this case the toolbar appears -after- the body in the stacking order,
    // so the toolbar's shadow is drawn on top of the body.

    final BoxConstraints fullWidthConstraints = looseConstraints.tighten(width: size.width);
    double contentTop = padding.top;
    double contentBottom = size.height - padding.bottom;

    if (isChild(_ScaffoldSlot.toolBar)) {
      contentTop = layoutChild(_ScaffoldSlot.toolBar, fullWidthConstraints).height;
      positionChild(_ScaffoldSlot.toolBar, Offset.zero);
    }

    if (isChild(_ScaffoldSlot.body)) {
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

    if (isChild(_ScaffoldSlot.bottomSheet)) {
      bottomSheetSize = layoutChild(_ScaffoldSlot.bottomSheet, fullWidthConstraints);
      positionChild(_ScaffoldSlot.bottomSheet, new Offset((size.width - bottomSheetSize.width) / 2.0, contentBottom - bottomSheetSize.height));
    }

    if (isChild(_ScaffoldSlot.snackBar)) {
      snackBarSize = layoutChild(_ScaffoldSlot.snackBar, fullWidthConstraints);
      positionChild(_ScaffoldSlot.snackBar, new Offset(0.0, contentBottom - snackBarSize.height));
    }

    if (isChild(_ScaffoldSlot.floatingActionButton)) {
      final Size fabSize = layoutChild(_ScaffoldSlot.floatingActionButton, looseConstraints);
      final double fabX = size.width - fabSize.width - _kFloatingActionButtonMargin;
      double fabY = contentBottom - fabSize.height - _kFloatingActionButtonMargin;
      if (snackBarSize.height > 0.0)
        fabY = math.min(fabY, contentBottom - snackBarSize.height - fabSize.height - _kFloatingActionButtonMargin);
      if (bottomSheetSize.height > 0.0)
        fabY = math.min(fabY, contentBottom - bottomSheetSize.height - fabSize.height / 2.0);
      positionChild(_ScaffoldSlot.floatingActionButton, new Offset(fabX, fabY));
    }

    if (isChild(_ScaffoldSlot.drawer)) {
      layoutChild(_ScaffoldSlot.drawer, new BoxConstraints.tight(size));
      positionChild(_ScaffoldSlot.drawer, Offset.zero);
    }
  }

  bool shouldRelayout(_ScaffoldLayout oldDelegate) {
    return padding != oldDelegate.padding;
  }
}

class _FloatingActionButtonTransition extends StatefulComponent {
  _FloatingActionButtonTransition({
    Key key,
    this.child
  }) : super(key: key) {
    assert(child != null);
  }

  final Widget child;

  _FloatingActionButtonTransitionState createState() => new _FloatingActionButtonTransitionState();
}

class _FloatingActionButtonTransitionState extends State<_FloatingActionButtonTransition> {
  final AnimationController controller = new AnimationController(duration: _kFloatingActionButtonSegue);
  Widget oldChild;

  void initState() {
    super.initState();
    controller.forward().then((_) {
      oldChild = null;
    });
  }

  void dispose() {
    controller.stop();
    super.dispose();
  }

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

class Scaffold extends StatefulComponent {
  Scaffold({
    Key key,
    this.toolBar,
    this.body,
    this.floatingActionButton,
    this.drawer,
    this.scrollableKey,
    this.appBarBehavior: AppBarBehavior.anchor,
    this.appBarHeight
  }) : super(key: key) {
    assert((appBarBehavior == AppBarBehavior.scroll) ? scrollableKey != null : true);
    assert((appBarBehavior == AppBarBehavior.scroll) ? appBarHeight != null && appBarHeight > kToolBarHeight : true);
  }

  final ToolBar toolBar;
  final Widget body;
  final Widget floatingActionButton;
  final Widget drawer;
  final Key scrollableKey;
  final AppBarBehavior appBarBehavior;
  final double appBarHeight;

  /// The state from the closest instance of this class that encloses the given context.
  static ScaffoldState of(BuildContext context) => context.ancestorStateOfType(const TypeMatcher<ScaffoldState>());

  ScaffoldState createState() => new ScaffoldState();
}

class ScaffoldState extends State<Scaffold> {

  // APPBAR API

  AnimationController _appBarController;

  Animation<double> get appBarAnimation => _appBarController.view;

  double get appBarHeight => config.appBarHeight;

  // DRAWER API

  final GlobalKey<DrawerControllerState> _drawerKey = new GlobalKey<DrawerControllerState>();

  void openDrawer() {
    _drawerKey.currentState.open();
  }

  // SNACKBAR API

  Queue<ScaffoldFeatureController<SnackBar>> _snackBars = new Queue<ScaffoldFeatureController<SnackBar>>();
  AnimationController _snackBarController;
  Timer _snackBarTimer;

  ScaffoldFeatureController showSnackBar(SnackBar snackbar) {
    _snackBarController ??= SnackBar.createAnimationController()
      ..addStatusListener(_handleSnackBarStatusChange);
    if (_snackBars.isEmpty) {
      assert(_snackBarController.isDismissed);
      _snackBarController.forward();
    }
    ScaffoldFeatureController<SnackBar> controller;
    controller = new ScaffoldFeatureController<SnackBar>._(
      // We provide a fallback key so that if back-to-back snackbars happen to
      // match in structure, material ink splashes and highlights don't survive
      // from one to the next.
      snackbar.withAnimation(_snackBarController, fallbackKey: new UniqueKey()),
      new Completer(),
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

  void _hideSnackBar() {
    assert(_snackBarController.status == AnimationStatus.forward ||
           _snackBarController.status == AnimationStatus.completed);
    _snackBars.first._completer.complete();
    _snackBarController.reverse();
    _snackBarTimer = null;
  }


  // PERSISTENT BOTTOM SHEET API

  List<Widget> _dismissedBottomSheets;
  ScaffoldFeatureController _currentBottomSheet;

  ScaffoldFeatureController showBottomSheet(WidgetBuilder builder) {
    if (_currentBottomSheet != null) {
      _currentBottomSheet.close();
      assert(_currentBottomSheet == null);
    }
    Completer completer = new Completer();
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
      _currentBottomSheet = new ScaffoldFeatureController._(
        bottomSheet,
        completer,
        () => entry.remove(),
        (VoidCallback fn) { bottomSheetKey.currentState?.setState(fn); }
      );
    });
    return _currentBottomSheet;
  }


  // INTERNALS

  void initState() {
    super.initState();
    _appBarController = new AnimationController();
  }

  void dispose() {
    _appBarController.stop();
    _snackBarController?.stop();
    _snackBarController = null;
    _snackBarTimer?.cancel();
    _snackBarTimer = null;
    super.dispose();
  }

  void _addIfNonNull(List<LayoutId> children, Widget child, Object childId) {
    if (child != null)
      children.add(new LayoutId(child: child, id: childId));
  }

  bool _shouldShowBackArrow;

  Widget _getModifiedToolBar({ EdgeDims padding, double foregroundOpacity: 1.0, int elevation }) {
    ToolBar toolBar = config.toolBar;
    if (toolBar == null)
      return null;
    EdgeDims toolBarPadding = new EdgeDims.only(top: padding.top);
    Widget left = toolBar.left;
    if (left == null) {
      if (config.drawer != null) {
        left = new IconButton(
          icon: Icons.menu,
          onPressed: openDrawer,
          tooltip: 'Open navigation menu' // TODO(ianh): Figure out how to localize this string
        );
      } else {
        _shouldShowBackArrow ??= Navigator.canPop(context);
        if (_shouldShowBackArrow) {
          left = new IconButton(
            icon: Icons.arrow_back,
            onPressed: () => Navigator.pop(context),
            tooltip: 'Back' // TODO(ianh): Figure out how to localize this string
          );
        }
      }
    }
    return toolBar.copyWith(
      elevation: elevation ?? toolBar.elevation ?? 4,
      padding: toolBarPadding,
      foregroundOpacity: foregroundOpacity,
      left: left
    );
  }

  double _scrollOffset = 0.0;
  double _scrollOffsetDelta = 0.0;
  double _floatingAppBarHeight = 0.0;

  bool _handleScrollNotification(ScrollNotification notification) {
    final double newScrollOffset = notification.scrollable.scrollOffset;
    if (config.scrollableKey != null && config.scrollableKey == notification.scrollable.config.key)
      setState(() {
        _scrollOffsetDelta = _scrollOffset - newScrollOffset;
        _scrollOffset = newScrollOffset;
      });
    return false;
  }

  double _toolBarOpacity(double progress) {
    // The value of progress is 1.0 if the entire (padded) toolbar is visible, 0.0
    // if the toolbar's height is zero.
    return new Tween<double>(begin: 0.0, end: 1.0).evaluate(new CurvedAnimation(
      parent: new AnimationController()..value = progress.clamp(0.0, 1.0),
      curve: new Interval(0.50, 1.0)
    ));
  }

  Widget _buildScrollableAppBar(BuildContext context) {
    final EdgeDims toolBarPadding = MediaQuery.of(context)?.padding ?? EdgeDims.zero;
    final double toolBarHeight = kToolBarHeight + toolBarPadding.top;
    Widget appBar;

    if (_scrollOffset <= appBarHeight && _scrollOffset >= appBarHeight - toolBarHeight) {
      // scrolled to the top, only the toolbar is (partially) visible
      final double height = math.max(_floatingAppBarHeight, appBarHeight - _scrollOffset);
      final double opacity = _toolBarOpacity(1.0 - ((toolBarHeight - height) / toolBarHeight));
      _appBarController.value = (appBarHeight - height) / appBarHeight;
      appBar = new SizedBox(
        height: height,
        child: _getModifiedToolBar(padding: toolBarPadding, foregroundOpacity: opacity)
      );
    } else if (_scrollOffset > appBarHeight) {
      // scrolled down, show the "floating" toolbar
      _floatingAppBarHeight = (_floatingAppBarHeight + _scrollOffsetDelta).clamp(0.0, toolBarHeight);
      final toolBarOpacity = _toolBarOpacity(_floatingAppBarHeight / toolBarHeight);
      _appBarController.value = (appBarHeight - _floatingAppBarHeight) / appBarHeight;
      appBar = new SizedBox(
        height: _floatingAppBarHeight,
        child: _getModifiedToolBar(padding: toolBarPadding, foregroundOpacity: toolBarOpacity)
      );
    } else {
      // _scrollOffset < appBarHeight - toolBarHeight, scrolled to the top, flexible space is visible
      final double height = appBarHeight - _scrollOffset.clamp(0.0, appBarHeight);
      _appBarController.value = (appBarHeight - height) / appBarHeight;
      appBar = new SizedBox(
        height: height,
        child: _getModifiedToolBar(padding: toolBarPadding, elevation: 0)
      );
      _floatingAppBarHeight = 0.0;
    }

    return appBar;
  }

  Widget build(BuildContext context) {
    EdgeDims padding = MediaQuery.of(context)?.padding ?? EdgeDims.zero;

    if (_snackBars.length > 0) {
      ModalRoute route = ModalRoute.of(context);
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
      Widget toolBar = new ConstrainedBox(
        child: _getModifiedToolBar(padding: padding),
        constraints: new BoxConstraints(maxHeight: config.appBarHeight ?? kExtendedToolBarHeight + padding.top)
      );
      _addIfNonNull(children, toolBar, _ScaffoldSlot.toolBar);
    }
    // Otherwise the ToolBar will be part of a [toolbar, body] Stack. See AppBarBehavior.scroll below.

    if (_currentBottomSheet != null ||
        (_dismissedBottomSheets != null && _dismissedBottomSheets.isNotEmpty)) {
      List<Widget> bottomSheets = <Widget>[];
      if (_dismissedBottomSheets != null && _dismissedBottomSheets.isNotEmpty)
        bottomSheets.addAll(_dismissedBottomSheets);
      if (_currentBottomSheet != null)
        bottomSheets.add(_currentBottomSheet._widget);
      Widget stack = new Stack(
        children: bottomSheets,
        alignment: const FractionalOffset(0.5, 1.0) // bottom-aligned, centered
      );
      _addIfNonNull(children, stack, _ScaffoldSlot.bottomSheet);
    }

    if (_snackBars.isNotEmpty)
      _addIfNonNull(children, _snackBars.first._widget, _ScaffoldSlot.snackBar);

    if (config.floatingActionButton != null) {
      Widget fab = new _FloatingActionButtonTransition(
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

    if (config.appBarBehavior == AppBarBehavior.scroll) {
      double overScroll = _scrollOffset.clamp(double.NEGATIVE_INFINITY, 0.0);
      application = new NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,
        child: new Stack(
          children: <Widget> [
            new CustomMultiChildLayout(
              children: children,
              delegate: new _ScaffoldLayout(
                padding: EdgeDims.zero
              )
            ),
            new Positioned(
              top: -overScroll,
              left: 0.0,
              right: 0.0,
              child: _buildScrollableAppBar(context)
            )
          ]
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

class ScaffoldFeatureController<T extends Widget> {
  const ScaffoldFeatureController._(this._widget, this._completer, this.close, this.setState);
  final T _widget;
  final Completer _completer;
  Future get closed => _completer.future;
  final VoidCallback close; // call this to close the bottom sheet or snack bar
  final StateSetter setState;
}

class _PersistentBottomSheet extends StatefulComponent {
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

  _PersistentBottomSheetState createState() => new _PersistentBottomSheetState();
}

class _PersistentBottomSheetState extends State<_PersistentBottomSheet> {

  // We take ownership of the animation controller given in the first configuration.
  // We also share control of that animation with out BottomSheet widget.

  void initState() {
    super.initState();
    assert(config.animationController.status == AnimationStatus.forward);
    config.animationController.addStatusListener(_handleStatusChange);
  }

  void didUpdateConfig(_PersistentBottomSheet oldConfig) {
    super.didUpdateConfig(oldConfig);
    assert(config.animationController == oldConfig.animationController);
  }

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

  Widget build(BuildContext context) {
    return new AnimatedBuilder(
      animation: config.animationController,
      builder: (BuildContext context, Widget child) {
        return new Align(
          alignment: const FractionalOffset(0.0, 0.0),
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
