// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'app_bar.dart';
import 'bottom_sheet.dart';
import 'button_bar.dart';
import 'button_theme.dart';
import 'divider.dart';
import 'drawer.dart';
import 'flexible_space_bar.dart';
import 'floating_action_button.dart';
import 'floating_action_button_location.dart';
import 'material.dart';
import 'snack_bar.dart';
import 'theme.dart';

const FloatingActionButtonLocation _kDefaultFloatingActionButtonLocation = FloatingActionButtonLocation.endFloat;
const FloatingActionButtonAnimator _kDefaultFloatingActionButtonAnimator = FloatingActionButtonAnimator.scaling;

enum _ScaffoldSlot {
  body,
  appBar,
  bottomSheet,
  snackBar,
  persistentFooter,
  bottomNavigationBar,
  floatingActionButton,
  drawer,
  endDrawer,
  statusBar,
}

/// The geometry of the [Scaffold] after all its contents have been laid out
/// except the [FloatingActionButton].
///
/// The [Scaffold] passes this prelayout geometry to its
/// [FloatingActionButtonLocation], which produces an [Offset] that the
/// [Scaffold] uses to position the [FloatingActionButton].
///
/// For a description of the [Scaffold]'s geometry after it has
/// finished laying out, see the [ScaffoldGeometry].
@immutable
class ScaffoldPrelayoutGeometry {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const ScaffoldPrelayoutGeometry({
    @required this.bottomSheetSize,
    @required this.contentBottom,
    @required this.contentTop,
    @required this.floatingActionButtonSize,
    @required this.minInsets,
    @required this.scaffoldSize,
    @required this.snackBarSize,
    @required this.textDirection,
  });

  /// The [Size] of [Scaffold.floatingActionButton].
  ///
  /// If [Scaffold.floatingActionButton] is null, this will be [Size.zero].
  final Size floatingActionButtonSize;

  /// The [Size] of the [Scaffold]'s [BottomSheet].
  ///
  /// If the [Scaffold] is not currently showing a [BottomSheet],
  /// this will be [Size.zero].
  final Size bottomSheetSize;

  /// The vertical distance from the Scaffold's origin to the bottom of
  /// [Scaffold.body].
  ///
  /// This is useful in a [FloatingActionButtonLocation] designed to
  /// place the [FloatingActionButton] at the bottom of the screen, while
  /// keeping it above the [BottomSheet], the [Scaffold.bottomNavigationBar],
  /// or the keyboard.
  ///
  /// The [Scaffold.body] is laid out with respect to [minInsets] already. This
  /// means that a [FloatingActionButtonLocation] does not need to factor in
  /// [minInsets.bottom] when aligning a [FloatingActionButton] to
  /// [contentBottom].
  final double contentBottom;

  /// The vertical distance from the [Scaffold]'s origin to the top of
  /// [Scaffold.body].
  ///
  /// This is useful in a [FloatingActionButtonLocation] designed to
  /// place the [FloatingActionButton] at the top of the screen, while
  /// keeping it below the [Scaffold.appBar].
  ///
  /// The [Scaffold.body] is laid out with respect to [minInsets] already. This
  /// means that a [FloatingActionButtonLocation] does not need to factor in
  /// [minInsets.top] when aligning a [FloatingActionButton] to [contentTop].
  final double contentTop;

  /// The minimum padding to inset the [FloatingActionButton] by for it
  /// to remain visible.
  ///
  /// This value is the result of calling [MediaQuery.padding] in the
  /// [Scaffold]'s [BuildContext],
  /// and is useful for insetting the [FloatingActionButton] to avoid features like
  /// the system status bar or the keyboard.
  ///
  /// If [Scaffold.resizeToAvoidBottomPadding] is set to false, [minInsets.bottom]
  /// will be 0.0 instead of [MediaQuery.padding.bottom].
  final EdgeInsets minInsets;

  /// The [Size] of the whole [Scaffold].
  ///
  /// If the [Size] of the [Scaffold]'s contents is modified by values such as
  /// [Scaffold.resizeToAvoidBottomPadding] or the keyboard opening, then the
  /// [scaffoldSize] will not reflect those changes.
  ///
  /// This means that [FloatingActionButtonLocation]s designed to reposition
  /// the [FloatingActionButton] based on events such as the keyboard popping
  /// up should use [minInsets] to make sure that the [FloatingActionButton] is
  /// inset by enough to remain visible.
  ///
  /// See [minInsets] and [MediaQuery.padding] for more information on the appropriate
  /// insets to apply.
  final Size scaffoldSize;

  /// The [Size] of the [Scaffold]'s [SnackBar].
  ///
  /// If the [Scaffold] is not showing a [SnackBar], this will be [Size.zero].
  final Size snackBarSize;

  /// The [TextDirection] of the [Scaffold]'s [BuildContext].
  final TextDirection textDirection;
}

/// A snapshot of a transition between two [FloatingActionButtonLocation]s.
///
/// [ScaffoldState] uses this to seamlessly change transition animations
/// when a running [FloatingActionButtonLocation] transition is interrupted by a new transition.
@immutable
class _TransitionSnapshotFabLocation extends FloatingActionButtonLocation {

  const _TransitionSnapshotFabLocation(this.begin, this.end, this.animator, this.progress);

  final FloatingActionButtonLocation begin;
  final FloatingActionButtonLocation end;
  final FloatingActionButtonAnimator animator;
  final double progress;

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    return animator.getOffset(
      begin: begin.getOffset(scaffoldGeometry),
      end: end.getOffset(scaffoldGeometry),
      progress: progress,
    );
  }

  @override
  String toString() {
    return '$runtimeType(begin: $begin, end: $end, progress: $progress)';
  }
}

/// Geometry information for [Scaffold] components after layout is finished.
///
/// To get a [ValueNotifier] for the scaffold geometry of a given
/// [BuildContext], use [Scaffold.geometryOf].
///
/// The ScaffoldGeometry is only available during the paint phase, because
/// its value is computed during the animation and layout phases prior to painting.
///
/// For an example of using the [ScaffoldGeometry], see the [BottomAppBar],
/// which uses the [ScaffoldGeometry] to paint a notch around the
/// [FloatingActionButton].
///
/// For information about the [Scaffold]'s geometry that is used while laying
/// out the [FloatingActionButton], see [ScaffoldPrelayoutGeometry].
@immutable
class ScaffoldGeometry {
  /// Create an object that describes the geometry of a [Scaffold].
  const ScaffoldGeometry({
    this.bottomNavigationBarTop,
    this.floatingActionButtonArea,
  });

  /// The distance from the [Scaffold]'s top edge to the top edge of the
  /// rectangle in which the [Scaffold.bottomNavigationBar] bar is laid out.
  ///
  /// Null if [Scaffold.bottomNavigationBar] is null.
  final double bottomNavigationBarTop;

  /// The [Scaffold.floatingActionButton]'s bounding rectangle.
  ///
  /// This is null when there is no floating action button showing.
  final Rect floatingActionButtonArea;

  ScaffoldGeometry _scaleFloatingActionButton(double scaleFactor) {
    if (scaleFactor == 1.0)
      return this;

    if (scaleFactor == 0.0) {
      return ScaffoldGeometry(
        bottomNavigationBarTop: bottomNavigationBarTop,
      );
    }

    final Rect scaledButton = Rect.lerp(
      floatingActionButtonArea.center & Size.zero,
      floatingActionButtonArea,
      scaleFactor
    );
    return copyWith(floatingActionButtonArea: scaledButton);
  }

  /// Creates a copy of this [ScaffoldGeometry] but with the given fields replaced with
  /// the new values.
  ScaffoldGeometry copyWith({
    double bottomNavigationBarTop,
    Rect floatingActionButtonArea,
  }) {
    return ScaffoldGeometry(
      bottomNavigationBarTop: bottomNavigationBarTop ?? this.bottomNavigationBarTop,
      floatingActionButtonArea: floatingActionButtonArea ?? this.floatingActionButtonArea,
    );
  }
}

class _ScaffoldGeometryNotifier extends ChangeNotifier implements ValueListenable<ScaffoldGeometry> {
  _ScaffoldGeometryNotifier(this.geometry, this.context)
    : assert (context != null);

  final BuildContext context;
  double floatingActionButtonScale;
  ScaffoldGeometry geometry;

  @override
  ScaffoldGeometry get value {
    assert(() {
      final RenderObject renderObject = context.findRenderObject();
      if (renderObject == null || !renderObject.owner.debugDoingPaint)
        throw FlutterError(
            'Scaffold.geometryOf() must only be accessed during the paint phase.\n'
            'The ScaffoldGeometry is only available during the paint phase, because\n'
            'its value is computed during the animation and layout phases prior to painting.'
        );
      return true;
    }());
    return geometry._scaleFloatingActionButton(floatingActionButtonScale);
  }

  void _updateWith({
    double bottomNavigationBarTop,
    Rect floatingActionButtonArea,
    double floatingActionButtonScale,
  }) {
    this.floatingActionButtonScale = floatingActionButtonScale ?? this.floatingActionButtonScale;
    geometry = geometry.copyWith(
      bottomNavigationBarTop: bottomNavigationBarTop,
      floatingActionButtonArea: floatingActionButtonArea,
    );
    notifyListeners();
  }
}

class _ScaffoldLayout extends MultiChildLayoutDelegate {
  _ScaffoldLayout({
    @required this.minInsets,
    @required this.textDirection,
    @required this.geometryNotifier,
    // for floating action button
    @required this.previousFloatingActionButtonLocation,
    @required this.currentFloatingActionButtonLocation,
    @required this.floatingActionButtonMoveAnimationProgress,
    @required this.floatingActionButtonMotionAnimator,
  }) : assert(previousFloatingActionButtonLocation != null),
       assert(currentFloatingActionButtonLocation != null);

  final EdgeInsets minInsets;
  final TextDirection textDirection;
  final _ScaffoldGeometryNotifier geometryNotifier;

  final FloatingActionButtonLocation previousFloatingActionButtonLocation;
  final FloatingActionButtonLocation currentFloatingActionButtonLocation;
  final double floatingActionButtonMoveAnimationProgress;
  final FloatingActionButtonAnimator floatingActionButtonMotionAnimator;

  @override
  void performLayout(Size size) {
    final BoxConstraints looseConstraints = BoxConstraints.loose(size);

    // This part of the layout has the same effect as putting the app bar and
    // body in a column and making the body flexible. What's different is that
    // in this case the app bar appears _after_ the body in the stacking order,
    // so the app bar's shadow is drawn on top of the body.

    final BoxConstraints fullWidthConstraints = looseConstraints.tighten(width: size.width);
    final double bottom = size.height;
    double contentTop = 0.0;
    double bottomWidgetsHeight = 0.0;

    if (hasChild(_ScaffoldSlot.appBar)) {
      contentTop = layoutChild(_ScaffoldSlot.appBar, fullWidthConstraints).height;
      positionChild(_ScaffoldSlot.appBar, Offset.zero);
    }

    double bottomNavigationBarTop;
    if (hasChild(_ScaffoldSlot.bottomNavigationBar)) {
      final double bottomNavigationBarHeight = layoutChild(_ScaffoldSlot.bottomNavigationBar, fullWidthConstraints).height;
      bottomWidgetsHeight += bottomNavigationBarHeight;
      bottomNavigationBarTop = math.max(0.0, bottom - bottomWidgetsHeight);
      positionChild(_ScaffoldSlot.bottomNavigationBar, Offset(0.0, bottomNavigationBarTop));
    }

    if (hasChild(_ScaffoldSlot.persistentFooter)) {
      final BoxConstraints footerConstraints = BoxConstraints(
        maxWidth: fullWidthConstraints.maxWidth,
        maxHeight: math.max(0.0, bottom - bottomWidgetsHeight - contentTop),
      );
      final double persistentFooterHeight = layoutChild(_ScaffoldSlot.persistentFooter, footerConstraints).height;
      bottomWidgetsHeight += persistentFooterHeight;
      positionChild(_ScaffoldSlot.persistentFooter, Offset(0.0, math.max(0.0, bottom - bottomWidgetsHeight)));
    }

    // Set the content bottom to account for the greater of the height of any
    // bottom-anchored material widgets or of the keyboard or other
    // bottom-anchored system UI.
    final double contentBottom = math.max(0.0, bottom - math.max(minInsets.bottom, bottomWidgetsHeight));

    if (hasChild(_ScaffoldSlot.body)) {
      final BoxConstraints bodyConstraints = BoxConstraints(
        maxWidth: fullWidthConstraints.maxWidth,
        maxHeight: math.max(0.0, contentBottom - contentTop),
      );
      layoutChild(_ScaffoldSlot.body, bodyConstraints);
      positionChild(_ScaffoldSlot.body, Offset(0.0, contentTop));
    }

    // The BottomSheet and the SnackBar are anchored to the bottom of the parent,
    // they're as wide as the parent and are given their intrinsic height. The
    // only difference is that SnackBar appears on the top side of the
    // BottomNavigationBar while the BottomSheet is stacked on top of it.
    //
    // If all three elements are present then either the center of the FAB straddles
    // the top edge of the BottomSheet or the bottom of the FAB is
    // kFloatingActionButtonMargin above the SnackBar, whichever puts the FAB
    // the farthest above the bottom of the parent. If only the FAB is has a
    // non-zero height then it's inset from the parent's right and bottom edges
    // by kFloatingActionButtonMargin.

    Size bottomSheetSize = Size.zero;
    Size snackBarSize = Size.zero;

    if (hasChild(_ScaffoldSlot.bottomSheet)) {
      final BoxConstraints bottomSheetConstraints = BoxConstraints(
        maxWidth: fullWidthConstraints.maxWidth,
        maxHeight: math.max(0.0, contentBottom - contentTop),
      );
      bottomSheetSize = layoutChild(_ScaffoldSlot.bottomSheet, bottomSheetConstraints);
      positionChild(_ScaffoldSlot.bottomSheet, Offset((size.width - bottomSheetSize.width) / 2.0, contentBottom - bottomSheetSize.height));
    }

    if (hasChild(_ScaffoldSlot.snackBar)) {
      snackBarSize = layoutChild(_ScaffoldSlot.snackBar, fullWidthConstraints);
      positionChild(_ScaffoldSlot.snackBar, Offset(0.0, contentBottom - snackBarSize.height));
    }

    Rect floatingActionButtonRect;
    if (hasChild(_ScaffoldSlot.floatingActionButton)) {
      final Size fabSize = layoutChild(_ScaffoldSlot.floatingActionButton, looseConstraints);

      // To account for the FAB position being changed, we'll animate between
      // the old and new positions.
      final ScaffoldPrelayoutGeometry currentGeometry = ScaffoldPrelayoutGeometry(
        bottomSheetSize: bottomSheetSize,
        contentBottom: contentBottom,
        contentTop: contentTop,
        floatingActionButtonSize: fabSize,
        minInsets: minInsets,
        scaffoldSize: size,
        snackBarSize: snackBarSize,
        textDirection: textDirection,
      );
      final Offset currentFabOffset = currentFloatingActionButtonLocation.getOffset(currentGeometry);
      final Offset previousFabOffset = previousFloatingActionButtonLocation.getOffset(currentGeometry);
      final Offset fabOffset = floatingActionButtonMotionAnimator.getOffset(
        begin: previousFabOffset,
        end: currentFabOffset,
        progress: floatingActionButtonMoveAnimationProgress,
      );
      positionChild(_ScaffoldSlot.floatingActionButton, fabOffset);
      floatingActionButtonRect = fabOffset & fabSize;
    }

    if (hasChild(_ScaffoldSlot.statusBar)) {
      layoutChild(_ScaffoldSlot.statusBar, fullWidthConstraints.tighten(height: minInsets.top));
      positionChild(_ScaffoldSlot.statusBar, Offset.zero);
    }

    if (hasChild(_ScaffoldSlot.drawer)) {
      layoutChild(_ScaffoldSlot.drawer, BoxConstraints.tight(size));
      positionChild(_ScaffoldSlot.drawer, Offset.zero);
    }

    if (hasChild(_ScaffoldSlot.endDrawer)) {
      layoutChild(_ScaffoldSlot.endDrawer, BoxConstraints.tight(size));
      positionChild(_ScaffoldSlot.endDrawer, Offset.zero);
    }

    geometryNotifier._updateWith(
      bottomNavigationBarTop: bottomNavigationBarTop,
      floatingActionButtonArea: floatingActionButtonRect,
    );
  }

  @override
  bool shouldRelayout(_ScaffoldLayout oldDelegate) {
    return oldDelegate.minInsets != minInsets
        || oldDelegate.textDirection != textDirection
        || oldDelegate.floatingActionButtonMoveAnimationProgress != floatingActionButtonMoveAnimationProgress
        || oldDelegate.previousFloatingActionButtonLocation != previousFloatingActionButtonLocation
        || oldDelegate.currentFloatingActionButtonLocation != currentFloatingActionButtonLocation;
  }
}

/// Handler for scale and rotation animations in the [FloatingActionButton].
///
/// Currently, there are two types of [FloatingActionButton] animations:
///
/// * Entrance/Exit animations, which this widget triggers
///   when the [FloatingActionButton] is added, updated, or removed.
/// * Motion animations, which are triggered by the [Scaffold]
///   when its [FloatingActionButtonLocation] is updated.
class _FloatingActionButtonTransition extends StatefulWidget {
  const _FloatingActionButtonTransition({
    Key key,
    @required this.child,
    @required this.fabMoveAnimation,
    @required this.fabMotionAnimator,
    @required this.geometryNotifier,
  }) : assert(fabMoveAnimation != null),
       assert(fabMotionAnimator != null),
       super(key: key);

  final Widget child;
  final Animation<double> fabMoveAnimation;
  final FloatingActionButtonAnimator fabMotionAnimator;
  final _ScaffoldGeometryNotifier geometryNotifier;

  @override
  _FloatingActionButtonTransitionState createState() => _FloatingActionButtonTransitionState();
}

class _FloatingActionButtonTransitionState extends State<_FloatingActionButtonTransition> with TickerProviderStateMixin {
  // The animations applied to the Floating Action Button when it is entering or exiting.
  // Controls the previous widget.child as it exits
  AnimationController _previousController;
  Animation<double> _previousScaleAnimation;
  Animation<double> _previousRotationAnimation;
  // Controls the current child widget.child as it exits
  AnimationController _currentController;
  // The animations to run, considering the widget's fabMoveAnimation and the current/previous entrance/exit animations.
  Animation<double> _currentScaleAnimation;
  Animation<double> _extendedCurrentScaleAnimation;
  Animation<double> _currentRotationAnimation;
  Widget _previousChild;

  @override
  void initState() {
    super.initState();

    _previousController = AnimationController(
      duration: kFloatingActionButtonSegue,
      vsync: this,
    )..addStatusListener(_handlePreviousAnimationStatusChanged);

    _currentController = AnimationController(
      duration: kFloatingActionButtonSegue,
      vsync: this,
    );

    _updateAnimations();

    if (widget.child != null) {
      // If we start out with a child, have the child appear fully visible instead
      // of animating in.
      _currentController.value = 1.0;
    }
    else {
      // If we start without a child we update the geometry object with a
      // floating action button scale of 0, as it is not showing on the screen.
      _updateGeometryScale(0.0);
    }
  }

  @override
  void dispose() {
    _previousController.dispose();
    _currentController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_FloatingActionButtonTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool oldChildIsNull = oldWidget.child == null;
    final bool newChildIsNull = widget.child == null;
    if (oldChildIsNull == newChildIsNull && oldWidget.child?.key == widget.child?.key)
      return;
    if (oldWidget.fabMotionAnimator != widget.fabMotionAnimator || oldWidget.fabMoveAnimation != oldWidget.fabMoveAnimation) {
      // Get the right scale and rotation animations to use for this widget.
      _updateAnimations();
    }
    if (_previousController.status == AnimationStatus.dismissed) {
      final double currentValue = _currentController.value;
      if (currentValue == 0.0 || oldWidget.child == null) {
        // The current child hasn't started its entrance animation yet. We can
        // just skip directly to the new child's entrance.
        _previousChild = null;
        if (widget.child != null)
          _currentController.forward();
      } else {
        // Otherwise, we need to copy the state from the current controller to
        // the previous controller and run an exit animation for the previous
        // widget before running the entrance animation for the new child.
        _previousChild = oldWidget.child;
        _previousController
          ..value = currentValue
          ..reverse();
        _currentController.value = 0.0;
      }
    }
  }

  static final Animatable<double> _entranceTurnTween = Tween<double>(
    begin: 1.0 - kFloatingActionButtonTurnInterval,
    end: 1.0,
  ).chain(CurveTween(curve: Curves.easeIn));

  void _updateAnimations() {
    // Get the animations for exit and entrance.
    final CurvedAnimation previousExitScaleAnimation = CurvedAnimation(
      parent: _previousController,
      curve: Curves.easeIn,
    );
    final Animation<double> previousExitRotationAnimation = Tween<double>(begin: 1.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _previousController,
        curve: Curves.easeIn,
      ),
    );

    final CurvedAnimation currentEntranceScaleAnimation = CurvedAnimation(
      parent: _currentController,
      curve: Curves.easeIn,
    );
    final Animation<double> currentEntranceRotationAnimation = _currentController.drive(_entranceTurnTween);

    // Get the animations for when the FAB is moving.
    final Animation<double> moveScaleAnimation = widget.fabMotionAnimator.getScaleAnimation(parent: widget.fabMoveAnimation);
    final Animation<double> moveRotationAnimation = widget.fabMotionAnimator.getRotationAnimation(parent: widget.fabMoveAnimation);

    // Aggregate the animations.
    _previousScaleAnimation = AnimationMin<double>(moveScaleAnimation, previousExitScaleAnimation);
    _currentScaleAnimation = AnimationMin<double>(moveScaleAnimation, currentEntranceScaleAnimation);
    _extendedCurrentScaleAnimation = _currentScaleAnimation.drive(CurveTween(curve: const Interval(0.0, 0.1)));

    _previousRotationAnimation = TrainHoppingAnimation(previousExitRotationAnimation, moveRotationAnimation);
    _currentRotationAnimation = TrainHoppingAnimation(currentEntranceRotationAnimation, moveRotationAnimation);

    _currentScaleAnimation.addListener(_onProgressChanged);
    _previousScaleAnimation.addListener(_onProgressChanged);
  }

  void _handlePreviousAnimationStatusChanged(AnimationStatus status) {
    setState(() {
      if (status == AnimationStatus.dismissed) {
        assert(_currentController.status == AnimationStatus.dismissed);
        if (widget.child != null)
          _currentController.forward();
      }
    });
  }

  bool _isExtendedFloatingActionButton(Widget widget) {
    if (widget is! FloatingActionButton)
      return false;
    final FloatingActionButton fab = widget;
    return fab.isExtended;
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = <Widget>[];

    if (_previousController.status != AnimationStatus.dismissed) {
      if (_isExtendedFloatingActionButton(_previousChild)) {
        children.add(FadeTransition(
          opacity: _previousScaleAnimation,
          child: _previousChild,
        ));
      } else {
        children.add(ScaleTransition(
          scale: _previousScaleAnimation,
          child: RotationTransition(
            turns: _previousRotationAnimation,
            child: _previousChild,
          ),
        ));
      }
    }

    if (_isExtendedFloatingActionButton(widget.child)) {
      children.add(ScaleTransition(
        scale: _extendedCurrentScaleAnimation,
        child: FadeTransition(
          opacity: _currentScaleAnimation,
          child: widget.child,
        ),
      ));
    } else {
      children.add(ScaleTransition(
        scale: _currentScaleAnimation,
        child: RotationTransition(
          turns: _currentRotationAnimation,
          child: widget.child,
        ),
      ));
    }

    return Stack(
      alignment: Alignment.centerRight,
      children: children,
    );
  }

  void _onProgressChanged() {
    _updateGeometryScale(math.max(_previousScaleAnimation.value, _currentScaleAnimation.value));
  }

  void _updateGeometryScale(double scale) {
    widget.geometryNotifier._updateWith(
      floatingActionButtonScale: scale,
    );
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
/// {@tool snippet --template=stateful_widget}
///
/// This example shows a [Scaffold] with an [AppBar], a [BottomAppBar] and a
/// [FloatingActionButton]. The [body] is a [Text] placed in a [Center] in order
/// to center the text within the [Scaffold] and the [FloatingActionButton] is
/// centered and docked within the [BottomAppBar] using
/// [FloatingActionButtonLocation.centerDocked]. The [FloatingActionButton] is
/// connected to a callback that increments a counter.
///
/// ```dart
/// int _count = 0;
///
/// Widget build(BuildContext context) {
///   return Scaffold(
///     appBar: AppBar(
///       title: Text('Sample Code'),
///     ),
///     body: Center(
///       child: Text('You have pressed the button $_count times.'),
///     ),
///     bottomNavigationBar: BottomAppBar(
///       child: Container(height: 50.0,),
///     ),
///     floatingActionButton: FloatingActionButton(
///       onPressed: () => setState(() {
///         _count++;
///       }),
///       tooltip: 'Increment Counter',
///       child: Icon(Icons.add),
///     ),
///     floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
///   );
/// }
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [AppBar], which is a horizontal bar typically shown at the top of an app
///    using the [appBar] property.
///  * [BottomAppBar], which is a horizontal bar typically shown at the bottom
///    of an app using the [bottomNavigationBar] property.
///  * [FloatingActionButton], which is a circular button typically shown in the
///    bottom right corner of the app using the [floatingActionButton] property.
///  * [FloatingActionButtonLocation], which is used to place the
///    [floatingActionButton] within the [Scaffold]'s layout.
///  * [FloatingActionButtonAnimator], which is used to animate the
///    [floatingActionButton] from one [floatingActionButtonLocation] to
///    another.
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
  const Scaffold({
    Key key,
    this.appBar,
    this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.floatingActionButtonAnimator,
    this.persistentFooterButtons,
    this.drawer,
    this.endDrawer,
    this.bottomNavigationBar,
    this.bottomSheet,
    this.backgroundColor,
    this.resizeToAvoidBottomPadding = true,
    this.primary = true,
  }) : assert(primary != null), super(key: key);

  /// An app bar to display at the top of the scaffold.
  final PreferredSizeWidget appBar;

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
  /// [ListView] as the body of the scaffold. This is also a good choice for
  /// the case where your body is a scrollable list.
  final Widget body;

  /// A button displayed floating above [body], in the bottom right corner.
  ///
  /// Typically a [FloatingActionButton].
  final Widget floatingActionButton;

  /// Responsible for determining where the [floatingActionButton] should go.
  ///
  /// If null, the [ScaffoldState] will use the default location, [FloatingActionButtonLocation.endFloat].
  final FloatingActionButtonLocation floatingActionButtonLocation;

  /// Animator to move the [floatingActionButton] to a new [floatingActionButtonLocation].
  ///
  /// If null, the [ScaffoldState] will use the default animator, [FloatingActionButtonAnimator.scaling].
  final FloatingActionButtonAnimator floatingActionButtonAnimator;

  /// A set of buttons that are displayed at the bottom of the scaffold.
  ///
  /// Typically this is a list of [FlatButton] widgets. These buttons are
  /// persistently visible, even if the [body] of the scaffold scrolls.
  ///
  /// These widgets will be wrapped in a [ButtonBar].
  ///
  /// The [persistentFooterButtons] are rendered above the
  /// [bottomNavigationBar] but below the [body].
  ///
  /// See also:
  ///
  ///  * <https://material.google.com/components/buttons.html#buttons-persistent-footer-buttons>
  final List<Widget> persistentFooterButtons;

  /// A panel displayed to the side of the [body], often hidden on mobile
  /// devices. Swipes in from either left-to-right ([TextDirection.ltr]) or
  /// right-to-left ([TextDirection.rtl])
  ///
  /// In the uncommon case that you wish to open the drawer manually, use the
  /// [ScaffoldState.openDrawer] function.
  ///
  /// Typically a [Drawer].
  final Widget drawer;

  /// A panel displayed to the side of the [body], often hidden on mobile
  /// devices. Swipes in from right-to-left ([TextDirection.ltr]) or
  /// left-to-right ([TextDirection.rtl])
  ///
  /// In the uncommon case that you wish to open the drawer manually, use the
  /// [ScaffoldState.openEndDrawer] function.
  ///
  /// Typically a [Drawer].
  final Widget endDrawer;

  /// The color of the [Material] widget that underlies the entire Scaffold.
  ///
  /// The theme's [ThemeData.scaffoldBackgroundColor] by default.
  final Color backgroundColor;

  /// A bottom navigation bar to display at the bottom of the scaffold.
  ///
  /// Snack bars slide from underneath the bottom navigation bar while bottom
  /// sheets are stacked on top.
  ///
  /// The [bottomNavigationBar] is rendered below the [persistentFooterButtons]
  /// and the [body].
  final Widget bottomNavigationBar;

  /// The persistent bottom sheet to display.
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
  /// Unlike the persistent bottom sheet displayed by [showBottomSheet]
  /// this bottom sheet is not a [LocalHistoryEntry] and cannot be dismissed
  /// with the scaffold appbar's back button.
  ///
  /// If a persistent bottom sheet created with [showBottomSheet] is already
  /// visible, it must be closed before building the Scaffold with a new
  /// [bottomSheet].
  ///
  /// The value of [bottomSheet] can be any widget at all. It's unlikely to
  /// actually be a [BottomSheet], which is used by the implementations of
  /// [showBottomSheet] and [showModalBottomSheet]. Typically it's a widget
  /// that includes [Material].
  ///
  /// See also:
  ///
  ///  * [showBottomSheet], which displays a bottom sheet as a route that can
  ///    be dismissed with the scaffold's back button.
  ///  * [showModalBottomSheet], which displays a modal bottom sheet.
  final Widget bottomSheet;

  /// Whether the [body] (and other floating widgets) should size themselves to
  /// avoid the window's bottom padding.
  ///
  /// For example, if there is an onscreen keyboard displayed above the
  /// scaffold, the body can be resized to avoid overlapping the keyboard, which
  /// prevents widgets inside the body from being obscured by the keyboard.
  ///
  /// Defaults to true.
  final bool resizeToAvoidBottomPadding;

  /// Whether this scaffold is being displayed at the top of the screen.
  ///
  /// If true then the height of the [appBar] will be extended by the height
  /// of the screen's status bar, i.e. the top padding for [MediaQuery].
  ///
  /// The default value of this property, like the default value of
  /// [AppBar.primary], is true.
  final bool primary;

  /// The state from the closest instance of this class that encloses the given context.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// @override
  /// Widget build(BuildContext context) {
  ///   return RaisedButton(
  ///     child: Text('SHOW A SNACKBAR'),
  ///     onPressed: () {
  ///       Scaffold.of(context).showSnackBar(SnackBar(
  ///         content: Text('Hello!'),
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
  ///   return Scaffold(
  ///     appBar: AppBar(
  ///       title: Text('Demo')
  ///     ),
  ///     body: Builder(
  ///       // Create an inner BuildContext so that the onPressed methods
  ///       // can refer to the Scaffold with Scaffold.of().
  ///       builder: (BuildContext context) {
  ///         return Center(
  ///           child: RaisedButton(
  ///             child: Text('SHOW A SNACKBAR'),
  ///             onPressed: () {
  ///               Scaffold.of(context).showSnackBar(SnackBar(
  ///                 content: Text('Hello!'),
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
  static ScaffoldState of(BuildContext context, { bool nullOk = false }) {
    assert(nullOk != null);
    assert(context != null);
    final ScaffoldState result = context.ancestorStateOfType(const TypeMatcher<ScaffoldState>());
    if (nullOk || result != null)
      return result;
    throw FlutterError(
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

  /// Returns a [ValueListenable] for the [ScaffoldGeometry] for the closest
  /// [Scaffold] ancestor of the given context.
  ///
  /// The [ValueListenable.value] is only available at paint time.
  ///
  /// Notifications are guaranteed to be sent before the first paint pass
  /// with the new geometry, but there is no guarantee whether a build or
  /// layout passes are going to happen between the notification and the next
  /// paint pass.
  ///
  /// The closest [Scaffold] ancestor for the context might change, e.g when
  /// an element is moved from one scaffold to another. For [StatefulWidget]s
  /// using this listenable, a change of the [Scaffold] ancestor will
  /// trigger a [State.didChangeDependencies].
  ///
  /// A typical pattern for listening to the scaffold geometry would be to
  /// call [Scaffold.geometryOf] in [State.didChangeDependencies], compare the
  /// return value with the previous listenable, if it has changed, unregister
  /// the listener, and register a listener to the new [ScaffoldGeometry]
  /// listenable.
  static ValueListenable<ScaffoldGeometry> geometryOf(BuildContext context) {
    final _ScaffoldScope scaffoldScope = context.inheritFromWidgetOfExactType(_ScaffoldScope);
    if (scaffoldScope == null)
      throw FlutterError(
        'Scaffold.geometryOf() called with a context that does not contain a Scaffold.\n'
        'This usually happens when the context provided is from the same StatefulWidget as that '
        'whose build function actually creates the Scaffold widget being sought.\n'
        'There are several ways to avoid this problem. The simplest is to use a Builder to get a '
        'context that is "under" the Scaffold. For an example of this, please see the '
        'documentation for Scaffold.of():\n'
        '  https://docs.flutter.io/flutter/material/Scaffold/of.html\n'
        'A more efficient solution is to split your build function into several widgets. This '
        'introduces a new context from which you can obtain the Scaffold. In this solution, '
        'you would have an outer widget that creates the Scaffold populated by instances of '
        'your new inner widgets, and then in these inner widgets you would use Scaffold.geometryOf().\n'
        'The context used was:\n'
        '  $context'
      );

    return scaffoldScope.geometryNotifier;
  }

  /// Whether the Scaffold that most tightly encloses the given context has a
  /// drawer.
  ///
  /// If this is being used during a build (for example to decide whether to
  /// show an "open drawer" button), set the `registerForUpdates` argument to
  /// true. This will then set up an [InheritedWidget] relationship with the
  /// [Scaffold] so that the client widget gets rebuilt whenever the [hasDrawer]
  /// value changes.
  ///
  /// See also:
  ///  * [Scaffold.of], which provides access to the [ScaffoldState] object as a
  ///    whole, from which you can show snackbars, bottom sheets, and so forth.
  static bool hasDrawer(BuildContext context, { bool registerForUpdates = true }) {
    assert(registerForUpdates != null);
    assert(context != null);
    if (registerForUpdates) {
      final _ScaffoldScope scaffold = context.inheritFromWidgetOfExactType(_ScaffoldScope);
      return scaffold?.hasDrawer ?? false;
    } else {
      final ScaffoldState scaffold = context.ancestorStateOfType(const TypeMatcher<ScaffoldState>());
      return scaffold?.hasDrawer ?? false;
    }
  }

  @override
  ScaffoldState createState() => ScaffoldState();
}

/// State for a [Scaffold].
///
/// Can display [SnackBar]s and [BottomSheet]s. Retrieve a [ScaffoldState] from
/// the current [BuildContext] using [Scaffold.of].
class ScaffoldState extends State<Scaffold> with TickerProviderStateMixin {

  // DRAWER API

  final GlobalKey<DrawerControllerState> _drawerKey = GlobalKey<DrawerControllerState>();
  final GlobalKey<DrawerControllerState> _endDrawerKey = GlobalKey<DrawerControllerState>();

  /// Whether this scaffold has a non-null [Scaffold.drawer].
  bool get hasDrawer => widget.drawer != null;
  /// Whether this scaffold has a non-null [Scaffold.endDrawer].
  bool get hasEndDrawer => widget.endDrawer != null;

  bool _drawerOpened = false;
  bool _endDrawerOpened = false;

  /// Whether the [Scaffold.drawer] is opened.
  ///
  /// See also:
  ///
  ///   * [ScaffoldState.openDrawer], which opens the [Scaffold.drawer] of a
  ///   [Scaffold].
  bool get isDrawerOpen => _drawerOpened;

  /// Whether the [Scaffold.endDrawer] is opened.
  ///
  /// See also:
  ///
  ///   * [ScaffoldState.openEndDrawer], which opens the [Scaffold.endDrawer] of
  ///     a [Scaffold].
  bool get isEndDrawerOpen => _endDrawerOpened;

  void _drawerOpenedCallback(bool isOpened) {
    setState(() {
      _drawerOpened = isOpened;
    });
  }

  void _endDrawerOpenedCallback(bool isOpened) {
    setState(() {
      _endDrawerOpened = isOpened;
    });
  }

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
    if (_endDrawerKey.currentState != null && _endDrawerOpened)
      _endDrawerKey.currentState.close();
    _drawerKey.currentState?.open();
  }

  /// Opens the end side [Drawer] (if any).
  ///
  /// If the scaffold has a non-null [Scaffold.endDrawer], this function will cause
  /// the end side drawer to begin its entrance animation.
  ///
  /// Normally this is not needed since the [Scaffold] automatically shows an
  /// appropriate [IconButton], and handles the edge-swipe gesture, to show the
  /// drawer.
  ///
  /// To close the end side drawer once it is open, use [Navigator.pop].
  ///
  /// See [Scaffold.of] for information about how to obtain the [ScaffoldState].
  void openEndDrawer() {
    if (_drawerKey.currentState != null && _drawerOpened)
      _drawerKey.currentState.close();
    _endDrawerKey.currentState?.open();
  }

  // SNACKBAR API

  final Queue<ScaffoldFeatureController<SnackBar, SnackBarClosedReason>> _snackBars = Queue<ScaffoldFeatureController<SnackBar, SnackBarClosedReason>>();
  AnimationController _snackBarController;
  Timer _snackBarTimer;
  bool _accessibleNavigation;

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
    controller = ScaffoldFeatureController<SnackBar, SnackBarClosedReason>._(
      // We provide a fallback key so that if back-to-back snackbars happen to
      // match in structure, material ink splashes and highlights don't survive
      // from one to the next.
      snackbar.withAnimation(_snackBarController, fallbackKey: UniqueKey()),
      Completer<SnackBarClosedReason>(),
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
  void removeCurrentSnackBar({ SnackBarClosedReason reason = SnackBarClosedReason.remove }) {
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
  ///
  /// The closed completer is called after the animation is complete.
  void hideCurrentSnackBar({ SnackBarClosedReason reason = SnackBarClosedReason.hide }) {
    assert(reason != null);
    if (_snackBars.isEmpty || _snackBarController.status == AnimationStatus.dismissed)
      return;
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final Completer<SnackBarClosedReason> completer = _snackBars.first._completer;
    if (mediaQuery.accessibleNavigation) {
      _snackBarController.value = 0.0;
      completer.complete(reason);
    } else {
      _snackBarController.reverse().then<void>((void value) {
        assert(mounted);
        if (!completer.isCompleted)
          completer.complete(reason);
      });
    }
    _snackBarTimer?.cancel();
    _snackBarTimer = null;
  }


  // PERSISTENT BOTTOM SHEET API

  final List<_PersistentBottomSheet> _dismissedBottomSheets = <_PersistentBottomSheet>[];
  PersistentBottomSheetController<dynamic> _currentBottomSheet;

  void _maybeBuildCurrentBottomSheet() {
    if (widget.bottomSheet != null) {
      // The new _currentBottomSheet is not a local history entry so a "back" button
      // will not be added to the Scaffold's appbar and the bottom sheet will not
      // support drag or swipe to dismiss.
      _currentBottomSheet = _buildBottomSheet<void>(
        (BuildContext context) => widget.bottomSheet,
        BottomSheet.createAnimationController(this) ..value = 1.0,
        false,
      );
    }
  }

  void _closeCurrentBottomSheet() {
    if (_currentBottomSheet != null) {
      _currentBottomSheet.close();
      assert(_currentBottomSheet == null);
    }
  }

  PersistentBottomSheetController<T> _buildBottomSheet<T>(WidgetBuilder builder, AnimationController controller, bool isLocalHistoryEntry) {
    final Completer<T> completer = Completer<T>();
    final GlobalKey<_PersistentBottomSheetState> bottomSheetKey = GlobalKey<_PersistentBottomSheetState>();
    _PersistentBottomSheet bottomSheet;

    void _removeCurrentBottomSheet() {
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

    final LocalHistoryEntry entry = isLocalHistoryEntry
      ? LocalHistoryEntry(onRemove: _removeCurrentBottomSheet)
      : null;

    bottomSheet = _PersistentBottomSheet(
      key: bottomSheetKey,
      animationController: controller,
      enableDrag: isLocalHistoryEntry,
      onClosing: () {
        assert(_currentBottomSheet._widget == bottomSheet);
        if (isLocalHistoryEntry)
          entry.remove();
        else
          _removeCurrentBottomSheet();
      },
      onDismissed: () {
        if (_dismissedBottomSheets.contains(bottomSheet)) {
          bottomSheet.animationController.dispose();
          setState(() {
            _dismissedBottomSheets.remove(bottomSheet);
          });
        }
      },
      builder: builder
    );

    if (isLocalHistoryEntry)
      ModalRoute.of(context).addLocalHistoryEntry(entry);

    return PersistentBottomSheetController<T>._(
      bottomSheet,
      completer,
      isLocalHistoryEntry ? entry.remove : _removeCurrentBottomSheet,
      (VoidCallback fn) { bottomSheetKey.currentState?.setState(fn); },
      isLocalHistoryEntry,
    );
  }

  /// Shows a persistent material design bottom sheet in the nearest [Scaffold].
  ///
  /// Returns a controller that can be used to close and otherwise manipulate the
  /// bottom sheet.
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
  /// A persistent bottom sheet shows information that supplements the primary
  /// content of the app. A persistent bottom sheet remains visible even when
  /// the user interacts with other parts of the app.
  ///
  /// A closely related widget is a modal bottom sheet, which is an alternative
  /// to a menu or a dialog and prevents the user from interacting with the rest
  /// of the app. Modal bottom sheets can be created and displayed with the
  /// [showModalBottomSheet] function.
  ///
  /// See also:
  ///
  ///  * [BottomSheet], which is the widget typically returned by the `builder`.
  ///  * [showBottomSheet], which calls this method given a [BuildContext].
  ///  * [showModalBottomSheet], which can be used to display a modal bottom
  ///    sheet.
  ///  * [Scaffold.of], for information about how to obtain the [ScaffoldState].
  ///  * <https://material.google.com/components/bottom-sheets.html#bottom-sheets-persistent-bottom-sheets>
  PersistentBottomSheetController<T> showBottomSheet<T>(WidgetBuilder builder) {
    _closeCurrentBottomSheet();
    final AnimationController controller = BottomSheet.createAnimationController(this)
      ..forward();
    setState(() {
      _currentBottomSheet = _buildBottomSheet<T>(builder, controller, true);
    });
    return _currentBottomSheet;
  }

  // Floating Action Button API
  AnimationController _floatingActionButtonMoveController;
  FloatingActionButtonAnimator _floatingActionButtonAnimator;
  FloatingActionButtonLocation _previousFloatingActionButtonLocation;
  FloatingActionButtonLocation _floatingActionButtonLocation;

  // Moves the Floating Action Button to the new Floating Action Button Location.
  void _moveFloatingActionButton(final FloatingActionButtonLocation newLocation) {
    FloatingActionButtonLocation previousLocation = _floatingActionButtonLocation;
    double restartAnimationFrom = 0.0;
    // If the Floating Action Button is moving right now, we need to start from a snapshot of the current transition.
    if (_floatingActionButtonMoveController.isAnimating) {
      previousLocation = _TransitionSnapshotFabLocation(_previousFloatingActionButtonLocation, _floatingActionButtonLocation, _floatingActionButtonAnimator, _floatingActionButtonMoveController.value);
      restartAnimationFrom = _floatingActionButtonAnimator.getAnimationRestart(_floatingActionButtonMoveController.value);
    }

    setState(() {
      _previousFloatingActionButtonLocation = previousLocation;
      _floatingActionButtonLocation = newLocation;
    });

    // Animate the motion even when the fab is null so that if the exit animation is running,
    // the old fab will start the motion transition while it exits instead of jumping to the
    // new position.
    _floatingActionButtonMoveController.forward(from: restartAnimationFrom);
  }

  // iOS FEATURES - status bar tap, back gesture

  // On iOS, tapping the status bar scrolls the app's primary scrollable to the
  // top. We implement this by providing a primary scroll controller and
  // scrolling it to the top when tapped.

  final ScrollController _primaryScrollController = ScrollController();

  void _handleStatusBarTap() {
    if (_primaryScrollController.hasClients) {
      _primaryScrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.linear, // TODO(ianh): Use a more appropriate curve.
      );
    }
  }

  // INTERNALS

  _ScaffoldGeometryNotifier _geometryNotifier;

  @override
  void initState() {
    super.initState();
    _geometryNotifier = _ScaffoldGeometryNotifier(const ScaffoldGeometry(), context);
    _floatingActionButtonLocation = widget.floatingActionButtonLocation ?? _kDefaultFloatingActionButtonLocation;
    _floatingActionButtonAnimator = widget.floatingActionButtonAnimator ?? _kDefaultFloatingActionButtonAnimator;
    _previousFloatingActionButtonLocation = _floatingActionButtonLocation;
    _floatingActionButtonMoveController = AnimationController(
      vsync: this,
      lowerBound: 0.0,
      upperBound: 1.0,
      value: 1.0,
      duration: kFloatingActionButtonSegue * 2,
    );
    _maybeBuildCurrentBottomSheet();
  }

  @override
  void didUpdateWidget(Scaffold oldWidget) {
    // Update the Floating Action Button Animator, and then schedule the Floating Action Button for repositioning.
    if (widget.floatingActionButtonAnimator != oldWidget.floatingActionButtonAnimator) {
      _floatingActionButtonAnimator = widget.floatingActionButtonAnimator ?? _kDefaultFloatingActionButtonAnimator;
    }
    if (widget.floatingActionButtonLocation != oldWidget.floatingActionButtonLocation) {
      _moveFloatingActionButton(widget.floatingActionButtonLocation ?? _kDefaultFloatingActionButtonLocation);
    }
    if (widget.bottomSheet != oldWidget.bottomSheet) {
      assert(() {
        if (widget.bottomSheet != null && _currentBottomSheet?._isLocalHistoryEntry == true) {
          throw FlutterError(
            'Scaffold.bottomSheet cannot be specified while a bottom sheet displayed '
            'with showBottomSheet() is still visible.\n Use the PersistentBottomSheetController '
            'returned by showBottomSheet() to close the old bottom sheet before creating '
            'a Scaffold with a (non null) bottomSheet.'
          );
        }
        return true;
      }());
      _closeCurrentBottomSheet();
      _maybeBuildCurrentBottomSheet();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void didChangeDependencies() {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    // If we transition from accessible navigation to non-accessible navigation
    // and there is a SnackBar that would have timed out that has already
    // completed its timer, dismiss that SnackBar. If the timer hasn't finished
    // yet, let it timeout as normal.
    if (_accessibleNavigation == true
      && !mediaQuery.accessibleNavigation
      && _snackBarTimer != null
      && !_snackBarTimer.isActive) {
      hideCurrentSnackBar(reason: SnackBarClosedReason.timeout);
    }
    _accessibleNavigation = mediaQuery.accessibleNavigation;
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _snackBarController?.dispose();
    _snackBarTimer?.cancel();
    _snackBarTimer = null;
    _geometryNotifier.dispose();
    for (_PersistentBottomSheet bottomSheet in _dismissedBottomSheets)
      bottomSheet.animationController.dispose();
    if (_currentBottomSheet != null)
      _currentBottomSheet._widget.animationController.dispose();
    _floatingActionButtonMoveController.dispose();
    super.dispose();
  }

  void _addIfNonNull(List<LayoutId> children, Widget child, Object childId, {
    @required bool removeLeftPadding,
    @required bool removeTopPadding,
    @required bool removeRightPadding,
    @required bool removeBottomPadding,
  }) {
    if (child != null) {
      children.add(
        LayoutId(
          id: childId,
          child: MediaQuery.removePadding(
            context: context,
            removeLeft: removeLeftPadding,
            removeTop: removeTopPadding,
            removeRight: removeRightPadding,
            removeBottom: removeBottomPadding,
            child: child,
          ),
        ),
      );
    }
  }

  void _buildEndDrawer(List<LayoutId> children, TextDirection textDirection) {
    if (widget.endDrawer != null) {
      assert(hasEndDrawer);
      _addIfNonNull(
        children,
        DrawerController(
          key: _endDrawerKey,
          alignment: DrawerAlignment.end,
          child: widget.endDrawer,
          drawerCallback: _endDrawerOpenedCallback,
        ),
        _ScaffoldSlot.endDrawer,
        // remove the side padding from the side we're not touching
        removeLeftPadding: textDirection == TextDirection.ltr,
        removeTopPadding: false,
        removeRightPadding: textDirection == TextDirection.rtl,
        removeBottomPadding: false,
      );
    }
  }

  void _buildDrawer(List<LayoutId> children, TextDirection textDirection) {
    if (widget.drawer != null) {
      assert(hasDrawer);
      _addIfNonNull(
        children,
        DrawerController(
          key: _drawerKey,
          alignment: DrawerAlignment.start,
          child: widget.drawer,
          drawerCallback: _drawerOpenedCallback,
        ),
        _ScaffoldSlot.drawer,
        // remove the side padding from the side we're not touching
        removeLeftPadding: textDirection == TextDirection.rtl,
        removeTopPadding: false,
        removeRightPadding: textDirection == TextDirection.ltr,
        removeBottomPadding: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    assert(debugCheckHasDirectionality(context));
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final ThemeData themeData = Theme.of(context);
    final TextDirection textDirection = Directionality.of(context);
    _accessibleNavigation = mediaQuery.accessibleNavigation;

    if (_snackBars.isNotEmpty) {
      final ModalRoute<dynamic> route = ModalRoute.of(context);
      if (route == null || route.isCurrent) {
        if (_snackBarController.isCompleted && _snackBarTimer == null) {
          final SnackBar snackBar = _snackBars.first._widget;
          _snackBarTimer = Timer(snackBar.duration, () {
            assert(_snackBarController.status == AnimationStatus.forward ||
                   _snackBarController.status == AnimationStatus.completed);
            // Look up MediaQuery again in case the setting changed.
            final MediaQueryData mediaQuery = MediaQuery.of(context);
            if (mediaQuery.accessibleNavigation && snackBar.action != null)
              return;
            hideCurrentSnackBar(reason: SnackBarClosedReason.timeout);
          });
        }
      } else {
        _snackBarTimer?.cancel();
        _snackBarTimer = null;
      }
    }

    final List<LayoutId> children = <LayoutId>[];

    _addIfNonNull(
      children,
      widget.body,
      _ScaffoldSlot.body,
      removeLeftPadding: false,
      removeTopPadding: widget.appBar != null,
      removeRightPadding: false,
      removeBottomPadding: widget.bottomNavigationBar != null ||
        widget.persistentFooterButtons != null,
    );

    if (widget.appBar != null) {
      final double topPadding = widget.primary ? mediaQuery.padding.top : 0.0;
      final double extent = widget.appBar.preferredSize.height + topPadding;
      assert(extent >= 0.0 && extent.isFinite);
      _addIfNonNull(
        children,
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: extent),
          child: FlexibleSpaceBar.createSettings(
            currentExtent: extent,
            child: widget.appBar,
          ),
        ),
        _ScaffoldSlot.appBar,
        removeLeftPadding: false,
        removeTopPadding: false,
        removeRightPadding: false,
        removeBottomPadding: true,
      );
    }

    if (_snackBars.isNotEmpty) {
      final bool removeBottomPadding = widget.persistentFooterButtons != null ||
        widget.bottomNavigationBar != null;
      _addIfNonNull(
        children,
        _snackBars.first._widget,
        _ScaffoldSlot.snackBar,
        removeLeftPadding: false,
        removeTopPadding: true,
        removeRightPadding: false,
        removeBottomPadding: removeBottomPadding,
      );
    }

    if (widget.persistentFooterButtons != null) {
      _addIfNonNull(
        children,
        Container(
          decoration: BoxDecoration(
            border: Border(
              top: Divider.createBorderSide(context, width: 1.0),
            ),
          ),
          child: SafeArea(
            child: ButtonTheme.bar(
              child: SafeArea(
                top: false,
                child: ButtonBar(
                  children: widget.persistentFooterButtons
                ),
              ),
            ),
          ),
        ),
        _ScaffoldSlot.persistentFooter,
        removeLeftPadding: false,
        removeTopPadding: true,
        removeRightPadding: false,
        removeBottomPadding: false,
      );
    }

    if (widget.bottomNavigationBar != null) {
      _addIfNonNull(
        children,
        widget.bottomNavigationBar,
        _ScaffoldSlot.bottomNavigationBar,
        removeLeftPadding: false,
        removeTopPadding: true,
        removeRightPadding: false,
        removeBottomPadding: false,
      );
    }

    if (_currentBottomSheet != null || _dismissedBottomSheets.isNotEmpty) {
      final List<Widget> bottomSheets = <Widget>[];
      if (_dismissedBottomSheets.isNotEmpty)
        bottomSheets.addAll(_dismissedBottomSheets);
      if (_currentBottomSheet != null)
        bottomSheets.add(_currentBottomSheet._widget);
      final Widget stack = Stack(
        children: bottomSheets,
        alignment: Alignment.bottomCenter,
      );
      _addIfNonNull(
        children,
        stack,
        _ScaffoldSlot.bottomSheet,
        removeLeftPadding: false,
        removeTopPadding: true,
        removeRightPadding: false,
        removeBottomPadding: widget.resizeToAvoidBottomPadding,
      );
    }

    _addIfNonNull(
      children,
      _FloatingActionButtonTransition(
        child: widget.floatingActionButton,
        fabMoveAnimation: _floatingActionButtonMoveController,
        fabMotionAnimator: _floatingActionButtonAnimator,
        geometryNotifier: _geometryNotifier,
      ),
      _ScaffoldSlot.floatingActionButton,
      removeLeftPadding: true,
      removeTopPadding: true,
      removeRightPadding: true,
      removeBottomPadding: true,
    );

    if (themeData.platform == TargetPlatform.iOS) {
      _addIfNonNull(
        children,
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _handleStatusBarTap,
          // iOS accessibility automatically adds scroll-to-top to the clock in the status bar
          excludeFromSemantics: true,
        ),
        _ScaffoldSlot.statusBar,
        removeLeftPadding: false,
        removeTopPadding: true,
        removeRightPadding: false,
        removeBottomPadding: true,
      );
    }

    if (_endDrawerOpened) {
      _buildDrawer(children, textDirection);
      _buildEndDrawer(children, textDirection);
    } else {
      _buildEndDrawer(children, textDirection);
      _buildDrawer(children, textDirection);
    }

    // The minimum insets for contents of the Scaffold to keep visible.
    final EdgeInsets minInsets = mediaQuery.padding.copyWith(
      bottom: widget.resizeToAvoidBottomPadding ? mediaQuery.viewInsets.bottom : 0.0,
    );

    return _ScaffoldScope(
      hasDrawer: hasDrawer,
      geometryNotifier: _geometryNotifier,
      child: PrimaryScrollController(
        controller: _primaryScrollController,
        child: Material(
          color: widget.backgroundColor ?? themeData.scaffoldBackgroundColor,
          child: AnimatedBuilder(animation: _floatingActionButtonMoveController, builder: (BuildContext context, Widget child) {
            return CustomMultiChildLayout(
              children: children,
              delegate: _ScaffoldLayout(
                minInsets: minInsets,
                currentFloatingActionButtonLocation: _floatingActionButtonLocation,
                floatingActionButtonMoveAnimationProgress: _floatingActionButtonMoveController.value,
                floatingActionButtonMotionAnimator: _floatingActionButtonAnimator,
                geometryNotifier: _geometryNotifier,
                previousFloatingActionButtonLocation: _previousFloatingActionButtonLocation,
                textDirection: textDirection,
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// An interface for controlling a feature of a [Scaffold].
///
/// Commonly obtained from [ScaffoldState.showSnackBar] or [ScaffoldState.showBottomSheet].
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
  const _PersistentBottomSheet({
    Key key,
    this.animationController,
    this.enableDrag = true,
    this.onClosing,
    this.onDismissed,
    this.builder
  }) : super(key: key);

  final AnimationController animationController; // we control it, but it must be disposed by whoever created it
  final bool enableDrag;
  final VoidCallback onClosing;
  final VoidCallback onDismissed;
  final WidgetBuilder builder;

  @override
  _PersistentBottomSheetState createState() => _PersistentBottomSheetState();
}

class _PersistentBottomSheetState extends State<_PersistentBottomSheet> {
  @override
  void initState() {
    super.initState();
    assert(widget.animationController.status == AnimationStatus.forward
        || widget.animationController.status == AnimationStatus.completed);
    widget.animationController.addStatusListener(_handleStatusChange);
  }

  @override
  void didUpdateWidget(_PersistentBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    assert(widget.animationController == oldWidget.animationController);
  }

  void close() {
    widget.animationController.reverse();
  }

  void _handleStatusChange(AnimationStatus status) {
    if (status == AnimationStatus.dismissed && widget.onDismissed != null)
      widget.onDismissed();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.animationController,
      builder: (BuildContext context, Widget child) {
        return Align(
          alignment: AlignmentDirectional.topStart,
          heightFactor: widget.animationController.value,
          child: child
        );
      },
      child: Semantics(
        container: true,
        onDismiss: () {
          close();
          widget.onClosing();
        },
        child: BottomSheet(
          animationController: widget.animationController,
          enableDrag: widget.enableDrag,
          onClosing: widget.onClosing,
          builder: widget.builder
        )
      )
    );
  }

}

/// A [ScaffoldFeatureController] for persistent bottom sheets.
///
/// This is the type of objects returned by [ScaffoldState.showBottomSheet].
class PersistentBottomSheetController<T> extends ScaffoldFeatureController<_PersistentBottomSheet, T> {
  const PersistentBottomSheetController._(
    _PersistentBottomSheet widget,
    Completer<T> completer,
    VoidCallback close,
    StateSetter setState,
    this._isLocalHistoryEntry,
  ) : super._(widget, completer, close, setState);

  final bool _isLocalHistoryEntry;
}

class _ScaffoldScope extends InheritedWidget {
  const _ScaffoldScope({
    @required this.hasDrawer,
    @required this.geometryNotifier,
    @required Widget child,
  }) : assert(hasDrawer != null),
       super(child: child);

  final bool hasDrawer;
  final _ScaffoldGeometryNotifier geometryNotifier;

  @override
  bool updateShouldNotify(_ScaffoldScope oldWidget) {
    return hasDrawer != oldWidget.hasDrawer;
  }
}
