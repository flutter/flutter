// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'bottom_sheet_scroll_controller.dart';
import 'colors.dart';
import 'debug.dart';
import 'material.dart';
import 'material_localizations.dart';
import 'scaffold.dart';
import 'theme.dart';

const Duration _kBottomSheetDuration = Duration(milliseconds: 200);
const double _kMinFlingVelocity = 700.0;
const double _kCloseProgressThreshold = 0.5;

/// A material design bottom sheet.
///
/// There are two kinds of bottom sheets in material design:
///
///  * _Persistent_. A persistent bottom sheet shows information that
///    supplements the primary content of the app. A persistent bottom sheet
///    remains visible even when the user interacts with other parts of the app.
///    Persistent bottom sheets can be created and displayed with the
///    [ScaffoldState.showBottomSheet] function or by specifying the
///    [Scaffold.bottomSheet] constructor parameter.
///
///  * _Modal_. A modal bottom sheet is an alternative to a menu or a dialog and
///    prevents the user from interacting with the rest of the app. Modal bottom
///    sheets can be created and displayed with the [showModalBottomSheet]
///    function.
///
/// The [BottomSheet] widget itself is rarely used directly. Instead, prefer to
/// create a persistent bottom sheet with [ScaffoldState.showBottomSheet] or
/// [Scaffold.bottomSheet], and a modal bottom sheet with [showModalBottomSheet].
///
/// See also:
///
///  * [showBottomSheet] and [ScaffoldState.showBottomSheet], for showing
///    non-modal "persistent" bottom sheets.
///  * [showModalBottomSheet], which can be used to display a modal bottom
///    sheet.
///  * <https://material.io/design/components/sheets-bottom.html>
class BottomSheet extends StatefulWidget {
  /// Creates a bottom sheet.
  ///
  /// Typically, bottom sheets are created implicitly by
  /// [ScaffoldState.showBottomSheet], for persistent bottom sheets, or by
  /// [showModalBottomSheet], for modal bottom sheets.
  const BottomSheet({
    Key key,
    this.animationController,
    this.enableDrag = true,
    this.scrollController,
    this.elevation = 0.0,
    @required this.onClosing,
    @required this.builder
  }) : assert(enableDrag != null),
       assert(onClosing != null),
       assert(
         scrollController == null || animationController == null,
         'A BottomSheet can either have a scrollController or an '
         'animationController, but not both. If the scrollController is '
         'specified, the animation will be controlled by the.',
       ),
       assert(
         (scrollController != null && enableDrag) || scrollController == null,
         'A BottomSheet with a scrollController must have enableDrag set to true.',
       ),
       assert(builder != null),
       assert(elevation != null && elevation >= 0.0),
       super(key: key);

  /// The animation that controls the bottom sheet's position, if
  /// [scrollController] is not specified.
  ///
  /// The BottomSheet widget will manipulate the position of this animation, it
  /// is not just a passive observer.
  final AnimationController animationController;

  /// The [BottomSheetScrollController] that will act as the
  /// [PrimaryScrollController] for this [BottomSheet], controlling its height
  /// and its child's scroll offset.
  ///
  /// If [animationController] is specified, this property must not be.
  final BottomSheetScrollController scrollController;

  /// Called when the bottom sheet begins to close.
  ///
  /// A bottom sheet might be prevented from closing (e.g., by user
  /// interaction) even after this callback is called. For this reason, this
  /// callback might be call multiple times for a given bottom sheet.
  final VoidCallback onClosing;

  /// A builder for the contents of the sheet.
  ///
  /// The bottom sheet will wrap the widget produced by this builder in a
  /// [Material] widget.
  final WidgetBuilder builder;

  /// If true, the bottom sheet can be dragged up and down and dismissed by
  /// swiping downards.
  ///
  /// Default is true.  If [scrollController] is specified, this must be true.
  final bool enableDrag;

  /// The z-coordinate at which to place this material relative to its parent.
  ///
  /// This controls the size of the shadow below the material.
  ///
  /// Defaults to 0. The value is non-negative.
  final double elevation;

  @override
  _BottomSheetState createState() => _BottomSheetState();

  /// Creates an [AnimationController] suitable for controlling a [BottomSheet].
  static AnimationController createAnimationController(TickerProvider vsync) {
    return AnimationController(
      duration: _kBottomSheetDuration,
      debugLabel: 'BottomSheet',
      vsync: vsync
    );
  }

  /// Creates a [BottomSheetScrollController] suitable for animating the
  /// [BottomSheet].
  static BottomSheetScrollController createScrollController({
    double initialHeightPercentage = 0.5,
    double minTop = 0.0,
    bool isPersistent = false,
    @required BuildContext context,
    bool forFullScreen = false,
  }) {
    assert(minTop != null);
    assert(context != null);
    assert(debugCheckHasMediaQuery(context));

    return BottomSheetScrollController(
      debugLabel: 'BottomSheetScrollController',
      initialHeightPercentage: initialHeightPercentage,
      minTop: minTop,
      isPersistent: isPersistent,
      context: context,
      forFullScreen: forFullScreen,
    );
  }
}

class _BottomSheetState extends State<BottomSheet> {

  final GlobalKey _childKey = GlobalKey(debugLabel: 'BottomSheet child');

  double get _childHeight {
    final RenderBox renderBox = _childKey.currentContext.findRenderObject();
    return renderBox.size.height;
  }

  bool get _dismissUnderway => widget.animationController.status == AnimationStatus.reverse;

  void _handleDragUpdate(DragUpdateDetails details) {
    assert(widget.scrollController == null);
    assert(widget.enableDrag);
    if (_dismissUnderway)
      return;
    widget.animationController.value -= details.primaryDelta / (_childHeight ?? details.primaryDelta);
  }

  void _handleDragEnd(DragEndDetails details) {
    assert(widget.scrollController == null);
    assert(widget.enableDrag);
    if (_dismissUnderway)
      return;
    if (details.velocity.pixelsPerSecond.dy > _kMinFlingVelocity) {
      final double flingVelocity = -details.velocity.pixelsPerSecond.dy / _childHeight;
      if (widget.animationController.value > 0.0) {
        widget.animationController.fling(velocity: flingVelocity);
      }
      if (flingVelocity < 0.0) {
        widget.onClosing();
      }
    } else if (widget.animationController.value < _kCloseProgressThreshold) {
      if (widget.animationController.value > 0.0)
        widget.animationController.fling(velocity: -1.0);
      widget.onClosing();
    } else {
      widget.animationController.forward();
   }
  }

  @override
  void initState() {
    super.initState();
    widget.scrollController?.addTopListener(_maybeCloseBottomSheet);
  }

  /// This method is only intended for use in a scroll controlled widget.
  void _maybeCloseBottomSheet() {
    assert(widget.scrollController != null);
    if (!widget.scrollController.isPersistent &&
        widget.scrollController.top >= widget.scrollController.maxTop) {
      // onClosing is asserted not null
      widget.onClosing();
   }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.scrollController != null) {
      return PrimaryScrollController(
        controller: widget.scrollController,
        child: Material(
          elevation: widget.elevation,
          child: SizedBox.expand(
            child: widget.builder(context),
          ),
        ),
      );
    }
    final Widget bottomSheet = Material(
      key: _childKey,
      elevation: widget.elevation,
      child: widget.builder(context),
    );
    return !widget.enableDrag ? bottomSheet : GestureDetector(
      onVerticalDragUpdate: _handleDragUpdate,
      onVerticalDragEnd: _handleDragEnd,
      child: bottomSheet,
      excludeFromSemantics: true,
    );
  }

  @override
  void dispose() {
    widget.scrollController?.removeTopListener(_maybeCloseBottomSheet);
    super.dispose();
  }
}

// PERSISTENT BOTTOM SHEETS

// See scaffold.dart


// MODAL BOTTOM SHEETS

class _ModalBottomSheetScrollControllerLayout extends SingleChildLayoutDelegate {
  _ModalBottomSheetScrollControllerLayout(this.top);

  final double top;

  @override
  Size getSize(BoxConstraints constraints) {
    return Size(constraints.maxWidth, top);
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    return Offset(0.0, top);
  }

  @override
  bool shouldRelayout(_ModalBottomSheetScrollControllerLayout oldDelegate) {
    return top != oldDelegate.top;
  }
}


class _ModalBottomSheetAnimationControllerLayout extends SingleChildLayoutDelegate {
  _ModalBottomSheetAnimationControllerLayout(this.progress);

  final double progress;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints(
      minWidth: constraints.maxWidth,
      maxWidth: constraints.maxWidth,
      minHeight: 0.0,
      maxHeight: constraints.maxHeight * 9.0 / 16.0
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    return Offset(0.0, size.height - childSize.height * progress);
  }

  @override
  bool shouldRelayout(_ModalBottomSheetAnimationControllerLayout oldDelegate) {
    return progress != oldDelegate.progress;
  }
}


class _ModalBottomSheet<T> extends StatefulWidget {
  const _ModalBottomSheet({
    Key key,
    this.route,
    this.scrollController,
  }) : super(key: key);

  final _ModalBottomSheetRoute<T> route;
  final BottomSheetScrollController scrollController;

  @override
  _ModalBottomSheetState<T> createState() => _ModalBottomSheetState<T>();
}

class _ModalBottomSheetState<T> extends State<_ModalBottomSheet<T>> {
  @override
  void initState() {
    super.initState();
    widget.scrollController?.addTopListener(_rebuild);
  }

  /// Rebuild the sheet when the [BottomSheetScrollController.top] value has changed.
  void _rebuild() {
    setState(() { /* state is contained in BottomSheetScrollController.top */ });
  }

  String _getRouteLabel(MaterialLocalizations localizations) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return '';
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        return localizations.dialogLabel;
    }
    return null;
  }

  Widget _buildScrollControlledWidget(String routeLabel) {
    assert(widget.scrollController != null);
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      label: routeLabel,
      explicitChildNodes: true,
      child: ClipRect(
        child: CustomSingleChildLayout(
          delegate: _ModalBottomSheetScrollControllerLayout(widget.scrollController.top),
          child: BottomSheet(
            onClosing: () => Navigator.pop(context),
            builder: widget.route.builder,
            scrollController: widget.scrollController,
          ),
        ),
      ),
    );
  }

  Widget _buildAnimationControlledWidget(String routeLabel, BuildContext context) {
    assert(widget.scrollController == null);
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    return GestureDetector(
      excludeFromSemantics: true,
      onTap: () => Navigator.pop(context),
      child: AnimatedBuilder(
        animation: widget.route.animation,
        builder: (BuildContext context, Widget child) {
          // Disable the initial animation when accessible navigation is on so
          // that the semantics are added to the tree at the correct time.
          final double animationValue = mediaQuery.accessibleNavigation ? 1.0 : widget.route.animation.value;
          return Semantics(
            scopesRoute: true,
            namesRoute: true,
            label: routeLabel,
            explicitChildNodes: true,
            child: ClipRect(
              child: CustomSingleChildLayout(
                delegate: _ModalBottomSheetAnimationControllerLayout(animationValue),
                child: BottomSheet(
                  animationController: widget.route._animationController,
                  onClosing: () => Navigator.pop(context),
                  builder: widget.route.builder,
                ),
              ),
            ),
          );
        }
      )
    );
  }
  @override
  Widget build(BuildContext context) {
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);
    final String routeLabel = _getRouteLabel(localizations);

    if (widget.scrollController != null) {
      return _buildScrollControlledWidget(routeLabel);
    }
    return _buildAnimationControlledWidget(routeLabel, context);
  }

  @override
  void dispose() {
    widget.scrollController?.removeTopListener(_rebuild);
    super.dispose();
  }
}

class _ModalBottomSheetRoute<T> extends PopupRoute<T> {
  _ModalBottomSheetRoute({
    this.builder,
    this.theme,
    this.barrierLabel,
    this.isScrollControlled = false,
    this.initialHeightPercentage,
    RouteSettings settings,
  }) : assert(isScrollControlled != null),
       super(settings: settings);

  final WidgetBuilder builder;
  final ThemeData theme;
  final bool isScrollControlled;
  final double initialHeightPercentage;

  BottomSheetScrollController _scrollController;
  AnimationController _animationController;

  @override
  Duration get transitionDuration => _kBottomSheetDuration;

  @override
  bool get barrierDismissible => true;

  @override
  final String barrierLabel;

  @override
  Color get barrierColor => Colors.black54;

  @override
  AnimationController createAnimationController() {
    if (!isScrollControlled) {
      assert(_animationController == null);
      _animationController = BottomSheet.createAnimationController(navigator.overlay);
      return _animationController;
    }
    return super.createAnimationController();
  }

  @override
  void dispose() {
    if (isScrollControlled) {
      _scrollController?.dispose();
    }
    super.dispose();
  }

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    if (isScrollControlled) {
      _scrollController = BottomSheet.createScrollController(
        initialHeightPercentage: initialHeightPercentage,
        minTop: 0.0,
        context: context,
        forFullScreen: true,
      );
    }
    // By definition, the bottom sheet is aligned to the bottom of the page
    // and isn't exposed to the top padding of the MediaQuery.
    Widget bottomSheet = MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: _ModalBottomSheet<T>(
        route: this,
        scrollController: _scrollController,
      ),
    );
    if (theme != null)
      bottomSheet = Theme(data: theme, child: bottomSheet);
    return bottomSheet;
  }
}

/// Shows a modal material design bottom sheet.
///
/// A modal bottom sheet is an alternative to a menu or a dialog and prevents
/// the user from interacting with the rest of the app.
///
/// A closely related widget is a persistent bottom sheet, which shows
/// information that supplements the primary content of the app without
/// preventing the use from interacting with the app. Persistent bottom sheets
/// can be created and displayed with the [showBottomSheet] function or the
/// [ScaffoldState.showBottomSheet] method.
///
/// The `context` argument is used to look up the [Navigator] and [Theme] for
/// the bottom sheet. It is only used when the method is called. Its
/// corresponding widget can be safely removed from the tree before the bottom
/// sheet is closed.
///
/// The `isScrollControlled` parameter specifies whether this is a route for
/// a bottom sheet that will utilize [BottomSheet.scrollController]. If you wish
/// to have a bottom sheet that has a scrollable child such as a [ListView] or
/// a [GridView], you should set this parameter to true. In such a case, the
/// `initialHeightPercentage` specifies how much of the available screen space
/// the sheet should take at the start.
///
/// Returns a `Future` that resolves to the value (if any) that was passed to
/// [Navigator.pop] when the modal bottom sheet was closed.
///
/// See also:
///
///  * [BottomSheet], which is the widget normally returned by the function
///    passed as the `builder` argument to [showModalBottomSheet].
///  * [showBottomSheet] and [ScaffoldState.showBottomSheet], for showing
///    non-modal bottom sheets.
///  * <https://material.io/design/components/sheets-bottom.html#modal-bottom-sheet>
Future<T> showModalBottomSheet<T>({
  @required BuildContext context,
  @required WidgetBuilder builder,
  bool isScrollControlled = false,
  double initialHeightPercentage = 0.5,
}) {
  assert(context != null);
  assert(builder != null);
  assert(isScrollControlled != null);
  assert(initialHeightPercentage != null);
  assert(initialHeightPercentage >= 0.0 && initialHeightPercentage <= 1.0);
  assert(debugCheckHasMediaQuery(context));
  assert(debugCheckHasMaterialLocalizations(context));

  return Navigator.push(context, _ModalBottomSheetRoute<T>(
    builder: builder,
    theme: Theme.of(context, shadowThemeOnly: true),
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    isScrollControlled: isScrollControlled,
    initialHeightPercentage: initialHeightPercentage,
  ));
}

/// Shows a material design bottom sheet in the nearest [Scaffold]. If you wish
/// to show a persistent bottom sheet, use [Scaffold.bottomSheet].
///
/// Returns a controller that can be used to close and otherwise manipulate the
/// bottom sheet.
///
/// The `isScrollControlled` parameter specifies whether this is a route for
/// a bottom sheet that will utilize [BottomSheet.scrollController]. If you wish
/// to have a bottom sheet that has a scrollable child such as a [ListView] or
/// a [GridView], you should set this parameter to true. In such a case, the
/// `initialHeightPercentage` specifies how much of the available screen space
/// the sheet should take at the start.
///
/// To rebuild the bottom sheet (e.g. if it is stateful), call
/// [PersistentBottomSheetController.setState] on the controller returned by
/// this method.
///
/// The new bottom sheet becomes a [LocalHistoryEntry] for the enclosing
/// [ModalRoute] and a back button is added to the appbar of the [Scaffold]
/// that closes the bottom sheet.
///
/// To create a persistent bottom sheet that is not a [LocalHistoryEntry] and
/// does not add a back button to the enclosing Scaffold's appbar, use the
/// [Scaffold.bottomSheet] constructor parameter.
///
/// A closely related widget is a modal bottom sheet, which is an alternative
/// to a menu or a dialog and prevents the user from interacting with the rest
/// of the app. Modal bottom sheets can be created and displayed with the
/// [showModalBottomSheet] function.
///
/// The `context` argument is used to look up the [Scaffold] for the bottom
/// sheet. It is only used when the method is called. Its corresponding widget
/// can be safely removed from the tree before the bottom sheet is closed.
///
/// See also:
///
///  * [BottomSheet], which is the widget typically returned by the `builder`.
///  * [showModalBottomSheet], which can be used to display a modal bottom
///    sheet.
///  * [Scaffold.of], for information about how to obtain the [BuildContext].
///  * <https://material.io/design/components/sheets-bottom.html#standard-bottom-sheet>
PersistentBottomSheetController<T> showBottomSheet<T>({
  @required BuildContext context,
  @required WidgetBuilder builder,
  bool isScrollControlled = false,
  double initialHeightPercentage = 0.5,
}) {
  assert(context != null);
  assert(builder != null);
  assert(debugCheckHasScaffold(context));

  return Scaffold.of(context).showBottomSheet<T>(
    builder,
    isScrollControlled: isScrollControlled,
    initialHeightPercentage: initialHeightPercentage,
  );
}
