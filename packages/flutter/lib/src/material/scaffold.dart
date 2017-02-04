// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'app_bar.dart';
import 'bottom_sheet.dart';
import 'button_bar.dart';
import 'button.dart';
import 'drawer.dart';
import 'icon.dart';
import 'icon_button.dart';
import 'icons.dart';
import 'material.dart';
import 'snack_bar.dart';
import 'theme.dart';

const double _kFloatingActionButtonMargin = 16.0; // TODO(hmuller): should be device dependent
const Duration _kFloatingActionButtonSegue = const Duration(milliseconds: 200);
final Tween<double> _kFloatingActionButtonTurnTween = new Tween<double>(begin: -0.125, end: 0.0);

const double _kBackGestureWidth = 20.0;

/// The Scaffold's appbar is the toolbar, bottom, and the "flexible space"
/// that's stacked behind them. The Scaffold's appBarBehavior defines how
/// its layout responds to scrolling the application's body.
enum AppBarBehavior {
  /// The app bar's layout does not respond to scrolling.
  anchor,

  /// The app bar's appearance and layout depend on the scrollOffset of the
  /// Scrollable identified by the Scaffold's scrollableKey. With the scrollOffset
  /// at 0.0, scrolling downwards causes the toolbar's flexible space to shrink,
  /// and then the app bar fades out and scrolls off the top of the screen.
  /// Scrolling upwards always causes the app bar's bottom widget to reappear
  /// if the bottom widget isn't null, otherwise the app bar's toolbar reappears.
  scroll,

  /// The app bar's appearance and layout depend on the scrollOffset of the
  /// Scrollable identified by the Scaffold's scrollableKey. With the scrollOffset
  /// at 0.0, Scrolling downwards causes the toolbar's flexible space to shrink.
  /// If the bottom widget isn't null the app bar shrinks to the bottom widget's
  /// [AppBarBottomWidget.bottomHeight], otherwise the app bar shrinks to its
  /// [AppBar.collapsedHeight].
  under,
}

enum _ScaffoldSlot {
  body,
  appBar,
  bottomSheet,
  snackBar,
  persistentFooter,
  bottomNavigationBar,
  floatingActionButton,
  drawer,
  statusBar,
}

class _ScaffoldLayout extends MultiChildLayoutDelegate {
  _ScaffoldLayout({
    this.padding,
    this.statusBarHeight,
    this.appBarBehavior: AppBarBehavior.anchor
  });

  final EdgeInsets padding;
  final double statusBarHeight;
  final AppBarBehavior appBarBehavior;

  @override
  void performLayout(Size size) {
    BoxConstraints looseConstraints = new BoxConstraints.loose(size);

    // This part of the layout has the same effect as putting the app bar and
    // body in a column and making the body flexible. What's different is that
    // in this case the app bar appears _after_ the body in the stacking order,
    // so the app bar's shadow is drawn on top of the body.

    final BoxConstraints fullWidthConstraints = looseConstraints.tighten(width: size.width);
    double contentTop = padding.top;
    double bottom = size.height - padding.bottom;
    double contentBottom = bottom;

    if (hasChild(_ScaffoldSlot.appBar)) {
      final double appBarHeight = layoutChild(_ScaffoldSlot.appBar, fullWidthConstraints).height;
      if (appBarBehavior == AppBarBehavior.anchor)
        contentTop = appBarHeight;
      positionChild(_ScaffoldSlot.appBar, Offset.zero);
    }

    if (hasChild(_ScaffoldSlot.bottomNavigationBar)) {
      final double bottomNavigationBarHeight = layoutChild(_ScaffoldSlot.bottomNavigationBar, fullWidthConstraints).height;
      contentBottom -= bottomNavigationBarHeight;
      positionChild(_ScaffoldSlot.bottomNavigationBar, new Offset(0.0, contentBottom));
    }

    if (hasChild(_ScaffoldSlot.persistentFooter)) {
      final double persistentFooterHeight = layoutChild(_ScaffoldSlot.persistentFooter, fullWidthConstraints.copyWith(maxHeight: contentBottom - contentTop)).height;
      contentBottom -= persistentFooterHeight;
      positionChild(_ScaffoldSlot.persistentFooter, new Offset(0.0, contentBottom));
    }

    if (hasChild(_ScaffoldSlot.body)) {
      final double bodyHeight = contentBottom - contentTop;
      final BoxConstraints bodyConstraints = new BoxConstraints(
        maxWidth: fullWidthConstraints.maxWidth,
        maxHeight: bodyHeight,
      );
      layoutChild(_ScaffoldSlot.body, bodyConstraints);
      positionChild(_ScaffoldSlot.body, new Offset(0.0, contentTop));
    }

    // The BottomSheet and the SnackBar are anchored to the bottom of the parent,
    // they're as wide as the parent and are given their intrinsic height. The
    // only difference is that SnackBar appears on the top side of the
    // BottomNavigationBar while the BottomSheet is stacked on top of it.
    //
    // If all three elements are present then either the center of the FAB straddles
    // the top edge of the BottomSheet or the bottom of the FAB is
    // _kFloatingActionButtonMargin above the SnackBar, whichever puts the FAB
    // the farthest above the bottom of the parent. If only the FAB is has a
    // non-zero height then it's inset from the parent's right and bottom edges
    // by _kFloatingActionButtonMargin.

    Size bottomSheetSize = Size.zero;
    Size snackBarSize = Size.zero;

    if (hasChild(_ScaffoldSlot.bottomSheet)) {
      bottomSheetSize = layoutChild(_ScaffoldSlot.bottomSheet, fullWidthConstraints.copyWith(maxHeight: contentBottom - contentTop));
      positionChild(_ScaffoldSlot.bottomSheet, new Offset((size.width - bottomSheetSize.width) / 2.0, bottom - bottomSheetSize.height));
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

    if (hasChild(_ScaffoldSlot.statusBar)) {
      layoutChild(_ScaffoldSlot.statusBar, fullWidthConstraints.tighten(height: statusBarHeight));
      positionChild(_ScaffoldSlot.statusBar, Offset.zero);
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
    this.child,
  }) : super(key: key);

  final Widget child;

  @override
  _FloatingActionButtonTransitionState createState() => new _FloatingActionButtonTransitionState();
}

class _FloatingActionButtonTransitionState extends State<_FloatingActionButtonTransition> with TickerProviderStateMixin {
  AnimationController _previousController;
  AnimationController _currentController;
  CurvedAnimation _previousAnimation;
  CurvedAnimation _currentAnimation;
  Widget _previousChild;

  @override
  void initState() {
    super.initState();

    _previousController = new AnimationController(
      duration: _kFloatingActionButtonSegue,
      vsync: this,
    )..addStatusListener(_handleAnimationStatusChanged);
    _previousAnimation = new CurvedAnimation(
      parent: _previousController,
      curve: Curves.easeIn
    );

    _currentController = new AnimationController(
      duration: _kFloatingActionButtonSegue,
      vsync: this,
    );
    _currentAnimation = new CurvedAnimation(
      parent: _currentController,
      curve: Curves.easeIn
    );

    // If we start out with a child, have the child appear fully visible instead
    // of animating in.
    if (config.child != null)
      _currentController.value = 1.0;
  }

  @override
  void dispose() {
    _previousController.stop();
    _currentController.stop();
    super.dispose();
  }

  @override
  void didUpdateConfig(_FloatingActionButtonTransition oldConfig) {
    final bool oldChildIsNull = oldConfig.child == null;
    final bool newChildIsNull = config.child == null;
    if (oldChildIsNull == newChildIsNull && oldConfig.child?.key == config.child?.key)
      return;
    if (_previousController.status == AnimationStatus.dismissed) {
      final double currentValue = _currentController.value;
      if (currentValue == 0.0 || oldConfig.child == null) {
        // The current child hasn't started its entrance animation yet. We can
        // just skip directly to the new child's entrance.
        _previousChild = null;
        if (config.child != null)
          _currentController.forward();
      } else {
        // Otherwise, we need to copy the state from the current controller to
        // the previous controller and run an exit animation for the previous
        // widget before running the entrance animation for the new child.
        _previousChild = oldConfig.child;
        _previousController
          ..value = currentValue
          ..reverse();
        _currentController.value = 0.0;
      }
    }
  }

  void _handleAnimationStatusChanged(AnimationStatus status) {
    setState(() {
      if (status == AnimationStatus.dismissed) {
        assert(_currentController.status == AnimationStatus.dismissed);
        if (config.child != null)
          _currentController.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = new List<Widget>();
    if (_previousAnimation.status != AnimationStatus.dismissed) {
      children.add(new ScaleTransition(
        scale: _previousAnimation,
        child: _previousChild,
      ));
    }
    if (_currentAnimation.status != AnimationStatus.dismissed) {
      children.add(new ScaleTransition(
        scale: _currentAnimation,
        child: new RotationTransition(
          turns: _kFloatingActionButtonTurnTween.animate(_currentAnimation),
          child: config.child,
        )
      ));
    }
    return new Stack(children: children);
  }
}

/// Implements the basic material design visual layout structure.
///
/// This class provides APIs for showing drawers, snack bars, and bottom sheets.
///
/// To display a snackbar or a persistent bottom sheet, obtain the
/// [ScaffoldState] for the current [BuildContext] via [Scaffold.of] and use the
/// [ScaffoldState.showSnackBar] and [ScaffoldState.showBottomSheet] functions.
///
/// See also:
///
///  * [AppBar], which is a horizontal bar typically shown at the top of an app
///    using the [appBar] property.
///  * [FloatingActionButton], which is a circular button typically shown in the
///    bottom right corner of the app using the [floatingActionButton] property.
///  * [Drawer], which is a vertical panel that is typically displayed to the
///    left of the body (and often hidden on phones) using the [drawer]
///    property.
///  * [BottomNavigationBar], which is a horizontal array of buttons typically
///    shown along the bottom of the app using the [bottomNavigationBar]
///    property.
///  * [SnackBar], which is a temporary notification typically shown near the
///    bottom of the app using the [ScaffoldState.showSnackBar] method.
///  * [BottomSheet], which is an overlay typically shown near the bottom of the
///    app. A bottom sheet can either be persistent, in which case it is shown
///    using the [ScaffoldState.showBottomSheet] method, or modal, in which case
///    it is shown using the [showModalBottomSheet] function.
///  * [ScaffoldState], which is the state associated with this widget.
///  * <https://material.google.com/layout/structure.html>
class Scaffold extends StatefulWidget {
  /// Creates a visual scaffold for material design widgets.
  ///
  /// By default, the [appBarBehavior] causes the [appBar] not to respond to
  /// scrolling and the [body] is resized to avoid the window padding (e.g., to
  /// to avoid being obscured by an onscreen keyboard).
  Scaffold({
    Key key,
    this.appBar,
    this.body,
    this.floatingActionButton,
    this.persistentFooterButtons,
    this.drawer,
    this.bottomNavigationBar,
    this.backgroundColor,
    this.scrollableKey,
    this.appBarBehavior: AppBarBehavior.anchor,
    this.resizeToAvoidBottomPadding: true
  }) : super(key: key);

  /// An app bar to display at the top of the scaffold.
  final AppBar appBar;

  /// The primary content of the scaffold.
  ///
  /// Displayed below the app bar and behind the [floatingActionButton] and
  /// [drawer]. To avoid the body being resized to avoid the window padding
  /// (e.g., from the onscreen keyboard), see [resizeToAvoidBottomPadding].
  ///
  /// The widget in the body of the scaffold is positioned at the top-left of
  /// the available space between the app bar and the bottom of the scaffold. To
  /// center this widget instead, consider putting it in a [Center] widget and
  /// having that be the body. To expand this widget instead, consider
  /// putting it in a [SizedBox.expand].
  ///
  /// If you have a column of widgets that should normally fit on the screen,
  /// but may overflow and would in such cases need to scroll, consider using a
  /// [ScrollList] as the body of the scaffold. This is also a good choice for
  /// the case where your body is a scrollable list.
  final Widget body;

  /// A button displayed floating above [body], in the bottom right corner.
  ///
  /// Typically a [FloatingActionButton].
  final Widget floatingActionButton;

  /// A set of buttons that are displayed at the bottom of the scaffold.
  ///
  /// Typically this is a list of [FlatButton] widgets. These buttons are
  /// persistently visible, even of the [body] of the scaffold scrolls.
  ///
  /// These widgets will be wrapped in a [ButtonBar].
  ///
  /// See also:
  ///
  ///  * <https://material.google.com/components/buttons.html#buttons-persistent-footer-buttons>
  final List<Widget> persistentFooterButtons;

  /// A panel displayed to the side of the [body], often hidden on mobile
  /// devices.
  ///
  /// If the [appBar] lacks an [AppBar.leading] widget, the scaffold will add a
  /// button that opens the drawer. The scaffold will also open the drawer if
  /// the user drags from the left edge of the scaffold.
  ///
  /// In the uncommon case that you wish to open the drawer manually, use the
  /// [ScaffoldState.openDrawer] function.
  ///
  /// Typically a [Drawer].
  final Widget drawer;

  /// The color of the [Material] widget that underlies the entire Scaffold.
  ///
  /// The theme's [ThemeData.scaffoldBackgroundColor] by default.
  final Color backgroundColor;

  /// A bottom navigation bar to display at the bottom of the scaffold.
  ///
  /// Snack bars slide from underneath the bottom navigation bar while bottom
  /// sheets are stacked on top.
  final Widget bottomNavigationBar;

  /// The key of the primary [Scrollable] widget in the [body].
  ///
  /// Used to control scroll-linked effects, such as the collapse of the
  /// [appBar].
  final GlobalKey<ScrollableState> scrollableKey;

  /// How the [appBar] should respond to scrolling.
  ///
  /// By default, the [appBar] does not respond to scrolling.
  final AppBarBehavior appBarBehavior;

  /// Whether the [body] (and other floating widgets) should size themselves to
  /// avoid the window's bottom padding.
  ///
  /// For example, if there is an onscreen keyboard displayed above the
  /// scaffold, the body can be resized to avoid overlapping the keyboard, which
  /// prevents widgets inside the body from being obscured by the keyboard.
  ///
  /// Defaults to true.
  final bool resizeToAvoidBottomPadding;

  /// The state from the closest instance of this class that encloses the given context.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// @override
  /// Widget build(BuildContext context) {
  ///   return new RaisedButton(
  ///     child: new Text('SHOW A SNACKBAR'),
  ///     onPressed: () {
  ///       Scaffold.of(context).showSnackBar(new SnackBar(
  ///         content: new Text('Hello!'),
  ///       ));
  ///     },
  ///   );
  /// }
  /// ```
  ///
  /// When the [Scaffold] is actually created in the same `build` function, the
  /// `context` argument to the `build` function can't be used to find the
  /// [Scaffold] (since it's "above" the widget being returned). In such cases,
  /// the following technique with a [Builder] can be used to provide a new
  /// scope with a [BuildContext] that is "under" the [Scaffold]:
  ///
  /// ```dart
  /// @override
  /// Widget build(BuildContext context) {
  ///   return new Scaffold(
  ///     appBar: new AppBar(
  ///       title: new Text('Demo')
  ///     ),
  ///     body: new Builder(
  ///       // Create an inner BuildContext so that the onPressed methods
  ///       // can refer to the Scaffold with Scaffold.of().
  ///       builder: (BuildContext context) {
  ///         return new Center(
  ///           child: new RaisedButton(
  ///             child: new Text('SHOW A SNACKBAR'),
  ///             onPressed: () {
  ///               Scaffold.of(context).showSnackBar(new SnackBar(
  ///                 content: new Text('Hello!'),
  ///               ));
  ///             },
  ///           ),
  ///         );
  ///       },
  ///     ),
  ///   );
  /// }
  /// ```
  ///
  /// A more efficient solution is to split your build function into several
  /// widgets. This introduces a new context from which you can obtain the
  /// [Scaffold]. In this solution, you would have an outer widget that creates
  /// the [Scaffold] populated by instances of your new inner widgets, and then
  /// in these inner widgets you would use [Scaffold.of].
  ///
  /// A less elegant but more expedient solution is assign a [GlobalKey] to the
  /// [Scaffold], then use the `key.currentState` property to obtain the
  /// [ScaffoldState] rather than using the [Scaffold.of] function.
  ///
  /// If there is no [Scaffold] in scope, then this will throw an exception.
  /// To return null if there is no [Scaffold], then pass `nullOk: true`.
  static ScaffoldState of(BuildContext context, { bool nullOk: false }) {
    assert(nullOk != null);
    assert(context != null);
    ScaffoldState result = context.ancestorStateOfType(const TypeMatcher<ScaffoldState>());
    if (nullOk || result != null)
      return result;
    throw new FlutterError(
      'Scaffold.of() called with a context that does not contain a Scaffold.\n'
      'No Scaffold ancestor could be found starting from the context that was passed to Scaffold.of(). '
      'This usually happens when the context provided is from the same StatefulWidget as that '
      'whose build function actually creates the Scaffold widget being sought.\n'
      'There are several ways to avoid this problem. The simplest is to use a Builder to get a '
      'context that is "under" the Scaffold. For an example of this, please see the '
      'documentation for Scaffold.of():\n'
      '  https://docs.flutter.io/flutter/material/Scaffold/of.html\n'
      'A more efficient solution is to split your build function into several widgets. This '
      'introduces a new context from which you can obtain the Scaffold. In this solution, '
      'you would have an outer widget that creates the Scaffold populated by instances of '
      'your new inner widgets, and then in these inner widgets you would use Scaffold.of().\n'
      'A less elegant but more expedient solution is assign a GlobalKey to the Scaffold, '
      'then use the key.currentState property to obtain the ScaffoldState rather than '
      'using the Scaffold.of() function.\n'
      'The context used was:\n'
      '  $context'
    );
  }

  @override
  ScaffoldState createState() => new ScaffoldState();
}

/// State for a [Scaffold].
///
/// Can display [SnackBar]s and [BottomSheet]s. Retrieve a [ScaffoldState] from
/// the current [BuildContext] using [Scaffold.of].
class ScaffoldState extends State<Scaffold> with TickerProviderStateMixin {

  static final Object _kScaffoldStorageIdentifier = new Object();

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
  ///
  /// Normally this is not needed since the [Scaffold] automatically shows an
  /// appropriate [IconButton], and handles the edge-swipe gesture, to show the
  /// drawer.
  ///
  /// To close the drawer once it is open, use [Navigator.pop].
  ///
  /// See [Scaffold.of] for information about how to obtain the [ScaffoldState].
  void openDrawer() {
    _drawerKey.currentState?.open();
  }

  // SNACKBAR API

  Queue<ScaffoldFeatureController<SnackBar, SnackBarClosedReason>> _snackBars = new Queue<ScaffoldFeatureController<SnackBar, SnackBarClosedReason>>();
  AnimationController _snackBarController;
  Timer _snackBarTimer;

  /// Shows a [SnackBar] at the bottom of the scaffold.
  ///
  /// A scaffold can show at most one snack bar at a time. If this function is
  /// called while another snack bar is already visible, the given snack bar
  /// will be added to a queue and displayed after the earlier snack bars have
  /// closed.
  ///
  /// To control how long a [SnackBar] remains visible, use [SnackBar.duration].
  ///
  /// To remove the [SnackBar] with an exit animation, use [hideCurrentSnackBar]
  /// or call [ScaffoldFeatureController.close] on the returned
  /// [ScaffoldFeatureController]. To remove a [SnackBar] suddenly (without an
  /// animation), use [removeCurrentSnackBar].
  ///
  /// See [Scaffold.of] for information about how to obtain the [ScaffoldState].
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSnackBar(SnackBar snackbar) {
    _snackBarController ??= SnackBar.createAnimationController(vsync: this)
      ..addStatusListener(_handleSnackBarStatusChange);
    if (_snackBars.isEmpty) {
      assert(_snackBarController.isDismissed);
      _snackBarController.forward();
    }
    ScaffoldFeatureController<SnackBar, SnackBarClosedReason> controller;
    controller = new ScaffoldFeatureController<SnackBar, SnackBarClosedReason>._(
      // We provide a fallback key so that if back-to-back snackbars happen to
      // match in structure, material ink splashes and highlights don't survive
      // from one to the next.
      snackbar.withAnimation(_snackBarController, fallbackKey: new UniqueKey()),
      new Completer<SnackBarClosedReason>(),
      () {
        assert(_snackBars.first == controller);
        hideCurrentSnackBar(reason: SnackBarClosedReason.hide);
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
  void removeCurrentSnackBar({ SnackBarClosedReason reason: SnackBarClosedReason.remove }) {
    assert(reason != null);
    if (_snackBars.isEmpty)
      return;
    final Completer<SnackBarClosedReason> completer = _snackBars.first._completer;
    if (!completer.isCompleted)
      completer.complete(reason);
    _snackBarTimer?.cancel();
    _snackBarTimer = null;
    _snackBarController.value = 0.0;
  }

  /// Removes the current [SnackBar] by running its normal exit animation.
  void hideCurrentSnackBar({ SnackBarClosedReason reason: SnackBarClosedReason.hide }) {
    assert(reason != null);
    if (_snackBars.isEmpty || _snackBarController.status == AnimationStatus.dismissed)
      return;
    final Completer<SnackBarClosedReason> completer = _snackBars.first._completer;
    if (!completer.isCompleted)
      completer.complete(reason);
    _snackBarController.reverse();
    _snackBarTimer?.cancel();
    _snackBarTimer = null;
  }

  // PERSISTENT BOTTOM SHEET API

  final List<_PersistentBottomSheet> _dismissedBottomSheets = <_PersistentBottomSheet>[];
  PersistentBottomSheetController<dynamic> _currentBottomSheet;

  /// Shows a persistent material design bottom sheet.
  ///
  /// A persistent bottom sheet shows information that supplements the primary
  /// content of the app. A persistent bottom sheet remains visible even when
  /// the user interacts with other parts of the app.
  ///
  /// A closely related widget is a modal bottom sheet, which is an alternative
  /// to a menu or a dialog and prevents the user from interacting with the rest
  /// of the app. Modal bottom sheets can be created and displayed with the
  /// [showModalBottomSheet] function.
  ///
  /// Returns a contoller that can be used to close and otherwise manipulate the
  /// button sheet.
  ///
  /// See also:
  ///
  ///  * [BottomSheet], which is the widget typicaly returned by the `builder`.
  ///  * [showModalBottomSheet], which can be used to display a modal bottom
  ///    sheet.
  ///  * [Scaffold.of], for information about how to obtain the [ScaffoldState].
  ///  * <https://material.google.com/components/bottom-sheets.html#bottom-sheets-persistent-bottom-sheets>
  PersistentBottomSheetController<T> showBottomSheet<T>(WidgetBuilder builder) {
    if (_currentBottomSheet != null) {
      _currentBottomSheet.close();
      assert(_currentBottomSheet == null);
    }
    Completer<T> completer = new Completer<T>();
    GlobalKey<_PersistentBottomSheetState> bottomSheetKey = new GlobalKey<_PersistentBottomSheetState>();
    AnimationController controller = BottomSheet.createAnimationController(this)
      ..forward();
    _PersistentBottomSheet bottomSheet;
    LocalHistoryEntry entry = new LocalHistoryEntry(
      onRemove: () {
        assert(_currentBottomSheet._widget == bottomSheet);
        assert(bottomSheetKey.currentState != null);
        bottomSheetKey.currentState.close();
        if (controller.status != AnimationStatus.dismissed)
          _dismissedBottomSheets.add(bottomSheet);
        setState(() {
          _currentBottomSheet = null;
        });
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
        if (_dismissedBottomSheets.contains(bottomSheet)) {
          setState(() {
            _dismissedBottomSheets.remove(bottomSheet);
          });
        }
      },
      builder: builder
    );
    ModalRoute.of(context).addLocalHistoryEntry(entry);
    setState(() {
      _currentBottomSheet = new PersistentBottomSheetController<T>._(
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
    _appBarController = new AnimationController(vsync: this);
    // Use an explicit identifier to guard against the possibility that the
    // Scaffold's key is recreated by the Widget that creates the Scaffold.
    List<double> scrollValues = PageStorage.of(context)?.readState(context,
      identifier: _kScaffoldStorageIdentifier
    );
    if (scrollValues != null) {
      assert(scrollValues.length == 2);
      _scrollOffset = scrollValues[0];
      _scrollOffsetDelta = scrollValues[1];
    }
  }

  @override
  void dispose() {
    _appBarController.dispose();
    _snackBarController?.dispose();
    _snackBarController = null;
    _snackBarTimer?.cancel();
    _snackBarTimer = null;
    for (_PersistentBottomSheet bottomSheet in _dismissedBottomSheets)
      bottomSheet.animationController.dispose();
    if (_currentBottomSheet != null)
      _currentBottomSheet._widget.animationController.dispose();
    PageStorage.of(context)?.writeState(context, <double>[_scrollOffset, _scrollOffsetDelta],
      identifier: _kScaffoldStorageIdentifier
    );
    super.dispose();
  }

  void _addIfNonNull(List<LayoutId> children, Widget child, Object childId) {
    if (child != null)
      children.add(new LayoutId(child: child, id: childId));
  }

  bool _shouldShowBackArrow;

  Future<Null> _back() async {
    if (await Navigator.willPop(context) && mounted)
      Navigator.pop(context);
  }

  Widget _getModifiedAppBar({ EdgeInsets padding, int elevation}) {
    AppBar appBar = config.appBar;
    if (appBar == null)
      return null;
    Widget leading = appBar.leading;
    if (leading == null) {
      if (config.drawer != null) {
        leading = new IconButton(
          icon: new Icon(Icons.menu),
          alignment: FractionalOffset.centerLeft,
          onPressed: openDrawer,
          tooltip: 'Open navigation menu' // TODO(ianh): Figure out how to localize this string
        );
      } else {
        _shouldShowBackArrow ??= Navigator.canPop(context);
        if (_shouldShowBackArrow) {
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
            alignment: FractionalOffset.centerLeft,
            onPressed: _back,
            tooltip: 'Back' // TODO(ianh): Figure out how to localize this string
          );
        }
      }
    }
    return appBar.copyWith(
      elevation: elevation ?? appBar.elevation ?? 4,
      padding: new EdgeInsets.only(top: padding.top),
      leading: leading
    );
  }

  double _scrollOffset = 0.0;
  double _scrollOffsetDelta = 0.0;
  double _floatingAppBarHeight = 0.0;

  bool _handleScrollNotification(ScrollNotification notification) {
    final ScrollableState scrollable = notification.scrollable;
    if ((scrollable.config.scrollDirection == Axis.vertical) &&
        (config.scrollableKey == null || config.scrollableKey == scrollable.config.key)) {
      double newScrollOffset = scrollable.scrollOffset;
      final ClampOverscrolls clampOverscrolls = ClampOverscrolls.of(context);
      if (clampOverscrolls != null)
        newScrollOffset = clampOverscrolls.clampScrollOffset(scrollable);
      if (_scrollOffset != newScrollOffset) {
        setState(() {
          _scrollOffsetDelta = _scrollOffset - newScrollOffset;
          _scrollOffset = newScrollOffset;
        });
      }
    }
    return false;
  }

  Widget _buildAnchoredAppBar(double expandedHeight, double height, EdgeInsets padding) {
    // Drive _appBarController to the point where the flexible space has disappeared.
    _appBarController.value = (expandedHeight - height) / expandedHeight;
    return new SizedBox(
      height: height,
      child: _getModifiedAppBar(padding: padding)
    );
  }

  Widget _buildScrollableAppBar(BuildContext context, EdgeInsets padding) {
    final double expandedHeight = (config.appBar?.expandedHeight ?? 0.0) + padding.top;
    final double collapsedHeight = (config.appBar?.collapsedHeight ?? 0.0) + padding.top;
    final double bottomHeight = config.appBar?.bottomHeight + padding.top;
    final double underHeight = config.appBar.bottom != null ? bottomHeight : collapsedHeight;
    Widget appBar;

    if (_scrollOffset <= expandedHeight && _scrollOffset >= expandedHeight - underHeight) {
      // scrolled to the top, flexible space collapsed, only the toolbar and tabbar are (partially) visible.
      if (config.appBarBehavior == AppBarBehavior.under) {
        appBar = _buildAnchoredAppBar(expandedHeight, underHeight, padding);
      } else {
        final double height = math.max(_floatingAppBarHeight, expandedHeight - _scrollOffset);
        _appBarController.value = (expandedHeight - height) / expandedHeight;
        appBar = new SizedBox(
          height: height,
          child: _getModifiedAppBar(padding: padding)
        );
      }
    } else if (_scrollOffset > expandedHeight) {
      // scrolled past the entire app bar, maybe show the "floating" toolbar.
      if (config.appBarBehavior == AppBarBehavior.under) {
        appBar = _buildAnchoredAppBar(expandedHeight, underHeight, padding);
      } else {
        _floatingAppBarHeight = (_floatingAppBarHeight + _scrollOffsetDelta).clamp(0.0, collapsedHeight);
        _appBarController.value = (expandedHeight - _floatingAppBarHeight) / expandedHeight;
        appBar = new SizedBox(
          height: _floatingAppBarHeight,
          child: _getModifiedAppBar(padding: padding)
        );
      }
    } else {
      // _scrollOffset < expandedHeight - collapsedHeight, scrolled to the top, flexible space is visible]
      final double height = expandedHeight - _scrollOffset.clamp(0.0, expandedHeight);
      _appBarController.value = (expandedHeight - height) / expandedHeight;
      appBar = new SizedBox(
        height: height,
        child: _getModifiedAppBar(padding: padding, elevation: 0)
      );
      _floatingAppBarHeight = 0.0;

    }

    return appBar;
  }

  // On iOS, tapping the status bar scrolls the app's primary scrollable to the top.
  void _handleStatusBarTap() {
    ScrollableState scrollable = config.scrollableKey?.currentState;
    if (scrollable == null || scrollable.scrollBehavior is! ExtentScrollBehavior)
      return;

    ExtentScrollBehavior behavior = scrollable.scrollBehavior;
    scrollable.scrollTo(
      behavior.minScrollOffset,
      duration: const Duration(milliseconds: 300)
    );
  }

  // IOS-specific back gesture.

  final GlobalKey _backGestureKey = new GlobalKey();
  NavigationGestureController _backGestureController;

  bool _shouldHandleBackGesture() {
    return Theme.of(context).platform == TargetPlatform.iOS && Navigator.canPop(context);
  }

  void _handleDragStart(DragStartDetails details) {
    _backGestureController = Navigator.of(context).startPopGesture();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    _backGestureController?.dragUpdate(details.primaryDelta / context.size.width);
  }

  void _handleDragEnd(DragEndDetails details) {
    final bool willPop = _backGestureController?.dragEnd(details.velocity.pixelsPerSecond.dx / context.size.width) ?? false;
    if (willPop)
      _currentBottomSheet?.close();
    _backGestureController = null;
  }

  void _handleDragCancel() {
    final bool willPop = _backGestureController?.dragEnd(0.0) ?? false;
    if (willPop)
      _currentBottomSheet?.close();
    _backGestureController = null;
  }

  @override
  Widget build(BuildContext context) {
    EdgeInsets padding = MediaQuery.of(context).padding;
    ThemeData themeData = Theme.of(context);
    if (!config.resizeToAvoidBottomPadding)
      padding = new EdgeInsets.fromLTRB(padding.left, padding.top, padding.right, 0.0);

    if (_snackBars.isNotEmpty) {
      final ModalRoute<dynamic> route = ModalRoute.of(context);
      if (route == null || route.isCurrent) {
        if (_snackBarController.isCompleted && _snackBarTimer == null)
          _snackBarTimer = new Timer(_snackBars.first._widget.duration, () {
            assert(_snackBarController.status == AnimationStatus.forward ||
                   _snackBarController.status == AnimationStatus.completed);
            hideCurrentSnackBar(reason: SnackBarClosedReason.timeout);
          });
      } else {
        _snackBarTimer?.cancel();
        _snackBarTimer = null;
      }
    }

    final List<LayoutId> children = new List<LayoutId>();

    Widget body;
    if (config.appBarBehavior != AppBarBehavior.anchor) {
      body = new NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,
        child: config.body,
      );
    } else {
      body = config.body;
    }
    _addIfNonNull(children, body, _ScaffoldSlot.body);

    if (config.appBarBehavior == AppBarBehavior.anchor) {
      final double expandedHeight = (config.appBar?.expandedHeight ?? 0.0) + padding.top;
      final Widget appBar = new ConstrainedBox(
        constraints: new BoxConstraints(maxHeight: expandedHeight),
        child: _getModifiedAppBar(padding: padding)
      );
      _addIfNonNull(children, appBar, _ScaffoldSlot.appBar);
    } else {
      children.add(new LayoutId(child: _buildScrollableAppBar(context, padding), id: _ScaffoldSlot.appBar));
    }
    // Otherwise the AppBar will be part of a [app bar, body] Stack. See
    // AppBarBehavior.scroll below.

    if (_snackBars.isNotEmpty)
      _addIfNonNull(children, _snackBars.first._widget, _ScaffoldSlot.snackBar);

    if (config.persistentFooterButtons != null) {
      children.add(new LayoutId(
        id: _ScaffoldSlot.persistentFooter,
        child: new Container(
          decoration: new BoxDecoration(
            border: new Border(
              top: new BorderSide(
                color: themeData.dividerColor
              ),
            ),
          ),
          child: new ButtonTheme.bar(
            child: new ButtonBar(
              children: config.persistentFooterButtons
            ),
          ),
        ),
      ));
    }

    if (config.bottomNavigationBar != null) {
      children.add(new LayoutId(
        id: _ScaffoldSlot.bottomNavigationBar,
        child: config.bottomNavigationBar
      ));
    }

    if (_currentBottomSheet != null || _dismissedBottomSheets.isNotEmpty) {
      final List<Widget> bottomSheets = <Widget>[];
      if (_dismissedBottomSheets.isNotEmpty)
        bottomSheets.addAll(_dismissedBottomSheets);
      if (_currentBottomSheet != null)
        bottomSheets.add(_currentBottomSheet._widget);
      Widget stack = new Stack(
        children: bottomSheets,
        alignment: FractionalOffset.bottomCenter
      );
      _addIfNonNull(children, stack, _ScaffoldSlot.bottomSheet);
    }

    children.add(new LayoutId(
      id: _ScaffoldSlot.floatingActionButton,
      child: new _FloatingActionButtonTransition(
        child: config.floatingActionButton
      )
    ));

    if (themeData.platform == TargetPlatform.iOS) {
      children.add(new LayoutId(
        id: _ScaffoldSlot.statusBar,
        child: new GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _handleStatusBarTap
        )
      ));
    }

    if (config.drawer != null) {
      children.add(new LayoutId(
        id: _ScaffoldSlot.drawer,
        child: new DrawerController(
          key: _drawerKey,
          child: config.drawer
        )
      ));
    } else if (_shouldHandleBackGesture()) {
      // Add a gesture for navigating back.
      children.add(new LayoutId(
        id: _ScaffoldSlot.drawer,
        child: new Align(
          alignment: FractionalOffset.centerLeft,
          child: new GestureDetector(
            key: _backGestureKey,
            onHorizontalDragStart: _handleDragStart,
            onHorizontalDragUpdate: _handleDragUpdate,
            onHorizontalDragEnd: _handleDragEnd,
            onHorizontalDragCancel: _handleDragCancel,
            behavior: HitTestBehavior.translucent,
            excludeFromSemantics: true,
            child: new Container(width: _kBackGestureWidth)
          )
        )
      ));
    }

    EdgeInsets appPadding = (config.appBarBehavior != AppBarBehavior.anchor) ? EdgeInsets.zero : padding;
    Widget application = new CustomMultiChildLayout(
      children: children,
      delegate: new _ScaffoldLayout(
        padding: appPadding,
        statusBarHeight: padding.top,
        appBarBehavior: config.appBarBehavior
      )
    );

    return new Material(
      color: config.backgroundColor ?? themeData.scaffoldBackgroundColor,
      child: application,
    );
  }
}

/// An interface for controlling a feature of a [Scaffold].
///
/// Commonly obtained from [Scaffold.showSnackBar] or [Scaffold.showBottomSheet].
class ScaffoldFeatureController<T extends Widget, U> {
  const ScaffoldFeatureController._(this._widget, this._completer, this.close, this.setState);
  final T _widget;
  final Completer<U> _completer;

  /// Completes when the feature controlled by this object is no longer visible.
  Future<U> get closed => _completer.future;

  /// Remove the feature (e.g., bottom sheet or snack bar) from the scaffold.
  final VoidCallback close;

  /// Mark the feature (e.g., bottom sheet or snack bar) as needing to rebuild.
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
