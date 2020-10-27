// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import 'theme.dart';

const double _kScrollbarThickness = 6.0;
const Duration _kScrollbarFadeDuration = Duration(milliseconds: 300);
const Duration _kScrollbarTimeToFade = Duration(milliseconds: 600);

/// A material design scrollbar.
///
/// A scrollbar indicates which portion of a [Scrollable] widget is actually
/// visible.
///
/// Dynamically changes to an iOS style scrollbar that looks like
/// [CupertinoScrollbar] on the iOS platform.
///
/// To add a scrollbar to a [ScrollView], simply wrap the scroll view widget in
/// a [Scrollbar] widget.
///
/// See also:
///
///  * [ListView], which display a linear, scrollable list of children.
///  * [GridView], which display a 2 dimensional, scrollable array of children.
class Scrollbar extends StatefulWidget {
  /// Creates a material design scrollbar that wraps the given [child].
  ///
  /// The [child] should be a source of [ScrollNotification] notifications,
  /// typically a [Scrollable] widget.
  const Scrollbar({
    Key? key,
    required this.child,
    this.controller,
    this.isAlwaysShown = false,
    this.thickness,
    this.radius,
  }) : assert(!isAlwaysShown || controller != null, 'When isAlwaysShown is true, must pass a controller that is attached to a scroll view'),
       super(key: key);

  /// The widget below this widget in the tree.
  ///
  /// The scrollbar will be stacked on top of this child. This child (and its
  /// subtree) should include a source of [ScrollNotification] notifications.
  ///
  /// Typically a [ListView] or [CustomScrollView].
  final Widget child;

  /// {@macro flutter.cupertino.cupertinoScrollbar.controller}
  final ScrollController? controller;

  /// {@macro flutter.cupertino.cupertinoScrollbar.isAlwaysShown}
  final bool isAlwaysShown;

  /// The thickness of the scrollbar.
  ///
  /// If this is non-null, it will be used as the thickness of the scrollbar on
  /// all platforms, whether the scrollbar is being dragged by the user or not.
  /// By default (if this is left null), each platform will get a thickness
  /// that matches the look and feel of the platform, and the thickness may
  /// grow while the scrollbar is being dragged if the platform look and feel
  /// calls for such behavior.
  final double? thickness;

  /// The radius of the corners of the scrollbar.
  ///
  /// If this is non-null, it will be used as the fixed radius of the scrollbar
  /// on all platforms, whether the scrollbar is being dragged by the user or
  /// not. By default (if this is left null), each platform will get a radius
  /// that matches the look and feel of the platform, and the radius may
  /// change while the scrollbar is being dragged if the platform look and feel
  /// calls for such behavior.
  final Radius? radius;

  @override
  _ScrollbarState createState() => _ScrollbarState();
}

class _ScrollbarState extends State<Scrollbar> with SingleTickerProviderStateMixin {
  ScrollbarPainter? _materialPainter;
  final GlobalKey _customPaintKey = GlobalKey();
  late TextDirection _textDirection;
  late Color _themeColor;
  late bool _useCupertinoScrollbar;
  late AnimationController _fadeoutAnimationController;
  late Animation<double> _fadeoutOpacityAnimation;
  Timer? _fadeoutTimer;

  @override
  void initState() {
    super.initState();
    _fadeoutAnimationController = AnimationController(
      vsync: this,
      duration: _kScrollbarFadeDuration,
    );
    _fadeoutOpacityAnimation = CurvedAnimation(
      parent: _fadeoutAnimationController,
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ThemeData theme = Theme.of(context)!;
    switch (theme.platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        // On iOS, stop all local animations. CupertinoScrollbar has its own
        // animations.
        _fadeoutTimer?.cancel();
        _fadeoutTimer = null;
        _fadeoutAnimationController.reset();
        _useCupertinoScrollbar = true;
        break;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        _themeColor = theme.highlightColor.withOpacity(1.0);
        _textDirection = Directionality.of(context)!;
        _materialPainter = _buildMaterialScrollbarPainter();
        _useCupertinoScrollbar = false;
        _triggerScrollbar();
        break;
    }
  }

  @override
  void didUpdateWidget(Scrollbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAlwaysShown != oldWidget.isAlwaysShown) {
      if (widget.isAlwaysShown == false) {
        _fadeoutAnimationController.reverse();
      } else {
        _triggerScrollbar();
        _fadeoutAnimationController.animateTo(1.0);
      }
    }
    if (!_useCupertinoScrollbar) {
      _materialPainter!
        ..thickness = widget.thickness ?? _kScrollbarThickness
        ..radius = widget.radius;
    }
  }

  // Wait one frame and cause an empty scroll event.  This allows the thumb to
  // show immediately when isAlwaysShown is true.  A scroll event is required in
  // order to paint the thumb.
  void _triggerScrollbar() {
    WidgetsBinding.instance!.addPostFrameCallback((Duration duration) {
      if (widget.isAlwaysShown) {
        _fadeoutTimer?.cancel();
        widget.controller!.position.didUpdateScrollPositionBy(0);
      }
    });
  }

  ScrollbarPainter _buildMaterialScrollbarPainter() {
    return ScrollbarPainter(
      color: _themeColor,
      textDirection: _textDirection,
      thickness: widget.thickness ?? _kScrollbarThickness,
      radius: widget.radius,
      fadeoutOpacityAnimation: _fadeoutOpacityAnimation,
      padding: MediaQuery.of(context)!.padding,
    );
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    final ScrollMetrics metrics = notification.metrics;
    if (metrics.maxScrollExtent <= metrics.minScrollExtent) {
      return false;
    }

    // iOS sub-delegates to the CupertinoScrollbar instead and doesn't handle
    // scroll notifications here.
    if (!_useCupertinoScrollbar &&
        (notification is ScrollUpdateNotification ||
            notification is OverscrollNotification)) {
      if (_fadeoutAnimationController.status != AnimationStatus.forward) {
        _fadeoutAnimationController.forward();
      }

      _materialPainter!.update(
        notification.metrics,
        notification.metrics.axisDirection,
      );
      if (!widget.isAlwaysShown) {
        _fadeoutTimer?.cancel();
        _fadeoutTimer = Timer(_kScrollbarTimeToFade, () {
          _fadeoutAnimationController.reverse();
          _fadeoutTimer = null;
        });
      }
    }
    return false;
  }

  void _handleDragDown(DragDownDetails details) {
    print('dragDown');
  }

  void _handleDragStart(DragStartDetails details) {
    print('dragStart');
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    print('dragUpdate');
  }

  void _handleDragEnd(DragEndDetails details) {
    print('dragEnd');
  }

  void _handleDragCancel() {
    print('dragCancel');
  }

  // Get the GestureRecognizerFactories used to detect gestures on the scrollbar
  // thumb.
  Map<Type, GestureRecognizerFactory> get _gestures {
    final Map<Type, GestureRecognizerFactory> gestures = <Type, GestureRecognizerFactory>{};
    if (widget.controller == null)
      return gestures;
    final Axis direction = widget.controller!.position.axis;

    switch (direction) {
      case Axis.vertical:
        gestures[_VerticalThumbDragGestureRecognizer] = GestureRecognizerFactoryWithHandlers<_VerticalThumbDragGestureRecognizer>(
              () => _VerticalThumbDragGestureRecognizer(
                debugOwner: this,
                customPaintKey: _customPaintKey,
              ),
              (_VerticalThumbDragGestureRecognizer instance) {
              instance
                ..onDown = _handleDragDown
                ..onStart = _handleDragStart
                ..onUpdate = _handleDragUpdate
                ..onEnd = _handleDragEnd
                ..onCancel = _handleDragCancel;
            },
          );
        break;
      case Axis.horizontal:
        gestures[_HorizontalThumbDragGestureRecognizer] = GestureRecognizerFactoryWithHandlers<_HorizontalThumbDragGestureRecognizer>(
              () => _HorizontalThumbDragGestureRecognizer(
                debugOwner: this,
                customPaintKey: _customPaintKey,
              ),
              (_HorizontalThumbDragGestureRecognizer instance) {
              instance
                ..onDown = _handleDragDown
                ..onStart = _handleDragStart
                ..onUpdate = _handleDragUpdate
                ..onEnd = _handleDragEnd
                ..onCancel = _handleDragCancel;
            },
          );
        break;
    }

    return gestures;
  }

  @override
  void dispose() {
    _fadeoutAnimationController.dispose();
    _fadeoutTimer?.cancel();
    _materialPainter?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_useCupertinoScrollbar) {
      return CupertinoScrollbar(
        child: widget.child,
        isAlwaysShown: widget.isAlwaysShown,
        thickness: widget.thickness ?? CupertinoScrollbar.defaultThickness,
        thicknessWhileDragging: widget.thickness ?? CupertinoScrollbar.defaultThicknessWhileDragging,
        radius: widget.radius ?? CupertinoScrollbar.defaultRadius,
        radiusWhileDragging: widget.radius ?? CupertinoScrollbar.defaultRadiusWhileDragging,
        controller: widget.controller,
      );
    }
    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: RepaintBoundary(
        child: RawGestureDetector(
          gestures: _gestures,
          child: CustomPaint(
            key: _customPaintKey,
            foregroundPainter: _materialPainter,
            child: RepaintBoundary(
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

// A vertical drag gesture detector that only responds to events on the
// scrollbar's thumb and ignores everything else.
class _VerticalThumbDragGestureRecognizer extends VerticalDragGestureRecognizer {
  _VerticalThumbDragGestureRecognizer({
    PointerDeviceKind? kind,
    required Object debugOwner,
    required GlobalKey customPaintKey,
  }) :  _customPaintKey = customPaintKey,
      super(
      kind: kind,
      debugOwner: debugOwner,
    );

  final GlobalKey _customPaintKey;

  @override
  bool isPointerAllowed(PointerEvent event) {
    if (!_hitTestInteractive(_customPaintKey, event.position)) {
      return false;
    }
    return super.isPointerAllowed(event);
  }
}

// A horizontal drag gesture detector that only responds to events on the
// scrollbar's thumb and ignores everything else.
class _HorizontalThumbDragGestureRecognizer extends HorizontalDragGestureRecognizer {
  _HorizontalThumbDragGestureRecognizer({
    PointerDeviceKind? kind,
    required Object debugOwner,
    required GlobalKey customPaintKey,
  }) :  _customPaintKey = customPaintKey,
      super(
      kind: kind,
      debugOwner: debugOwner,
    );

  final GlobalKey _customPaintKey;

  @override
  bool isPointerAllowed(PointerEvent event) {
    if (!_hitTestInteractive(_customPaintKey, event.position)) {
      return false;
    }
    return super.isPointerAllowed(event);
  }
}

// foregroundPainter also hit tests its children by default, but the
// scrollbar should only respond to a gesture directly on its thumb, so
// manually check for a hit on the thumb here.
bool _hitTestInteractive(GlobalKey customPaintKey, Offset offset) {
  if (customPaintKey.currentContext == null) {
    return false;
  }
  final CustomPaint customPaint = customPaintKey.currentContext!.widget as CustomPaint;
  final ScrollbarPainter painter = customPaint.foregroundPainter! as ScrollbarPainter;
  final RenderBox renderBox = customPaintKey.currentContext!.findRenderObject()! as RenderBox;
  final Offset localOffset = renderBox.globalToLocal(offset);
  return painter.hitTestInteractive(localOffset);
}
