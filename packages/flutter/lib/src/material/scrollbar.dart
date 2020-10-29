// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
class Scrollbar extends RawScrollbarThumb {
  /// Creates a material design scrollbar that wraps the given [child].
  ///
  /// The [child] should be a source of [ScrollNotification] notifications,
  /// typically a [Scrollable] widget.
  const Scrollbar({
    Key? key,
    required Widget child,
    ScrollController? controller,
    bool isAlwaysShown = false,
    double? thickness,
    Radius? radius,
  }) : super(
    key: key,
    child: child,
    controller: controller,
    isAlwaysShown: isAlwaysShown,
    thickness: thickness,
    radius: radius,
    fadeDuration: _kScrollbarFadeDuration,
    timeToFade: _kScrollbarTimeToFade,
  );

  @override
  _ScrollbarState createState() => _ScrollbarState();
}

class _ScrollbarState extends RawScrollbarThumbState<Scrollbar> {
  final GlobalKey _customPaintKey = GlobalKey();
  late bool _useCupertinoScrollbar;

  @override
  ScrollbarPainter? painter;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ThemeData theme = Theme.of(context)!;
    switch (theme.platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        // On iOS, stop all local animations. CupertinoScrollbar has its own
        // animations.
        fadeoutTimer?.cancel();
        fadeoutTimer = null;
        fadeoutAnimationController.reset();
        _useCupertinoScrollbar = true;
        break;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        painter = _buildMaterialScrollbarPainter();
        _useCupertinoScrollbar = false;
        triggerScrollbar();
        break;
    }
  }

  @override
  void didUpdateWidget(Scrollbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_useCupertinoScrollbar) {
      painter!
        ..thickness = widget.thickness ?? _kScrollbarThickness
        ..radius = widget.radius;
    }
  }

  ScrollbarPainter _buildMaterialScrollbarPainter() {
    return ScrollbarPainter(
      color: Theme.of(context)!.highlightColor.withOpacity(1.0),
      textDirection: Directionality.of(context)!,
      thickness: widget.thickness ?? _kScrollbarThickness,
      radius: widget.radius,
      fadeoutOpacityAnimation: fadeoutOpacityAnimation,
      padding: MediaQuery.of(context).padding,
    );
  }

  @override
  bool handleScrollNotification(ScrollNotification notification) {
    // iOS sub-delegates to the CupertinoScrollbar instead and doesn't handle
    // scroll notifications here.
    if (_useCupertinoScrollbar)
      return false;
    return super.handleScrollNotification(notification);
  }

  // Get the GestureRecognizerFactories used to detect gestures on the scrollbar
  // thumb.
  Map<Type, GestureRecognizerFactory> get _gestures {
    final Map<Type, GestureRecognizerFactory> gestures = <Type, GestureRecognizerFactory>{};
    if (controller == null)
      return gestures;

    gestures[_VerticalThumbDragGestureRecognizer] = GestureRecognizerFactoryWithHandlers<_VerticalThumbDragGestureRecognizer>(
      () => _VerticalThumbDragGestureRecognizer(
        debugOwner: this,
        customPaintKey: _customPaintKey,
      ),
      (_VerticalThumbDragGestureRecognizer instance) {
        instance.onStart = (DragStartDetails details) => handleGestureStart(details.localPosition);
        instance.onUpdate = (DragUpdateDetails details) => handleGestureUpdate(details.localPosition);
        instance.onEnd = (DragEndDetails details) => handleGestureEnd(details.velocity.pixelsPerSecond);
      },
    );
    gestures[_HorizontalThumbDragGestureRecognizer] = GestureRecognizerFactoryWithHandlers<_HorizontalThumbDragGestureRecognizer>(
      () => _HorizontalThumbDragGestureRecognizer(
        debugOwner: this,
        customPaintKey: _customPaintKey,
      ),
      (_HorizontalThumbDragGestureRecognizer instance) {
        instance.onStart = (DragStartDetails details) => handleGestureStart(details.localPosition);
        instance.onUpdate = (DragUpdateDetails details) => handleGestureUpdate(details.localPosition);
        instance.onEnd = (DragEndDetails details) => handleGestureEnd(details.velocity.pixelsPerSecond);
      },
    );

    return gestures;
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
      onNotification: handleScrollNotification,
      child: RepaintBoundary(
        child: RawGestureDetector(
          gestures: _gestures,
          child: CustomPaint(
            key: _customPaintKey,
            foregroundPainter: painter,
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
class _VerticalThumbDragGestureRecognizer extends VerticalDragGestureRecognizer with ScrollbarThumbHitTestMixin implements _ScrollbarThumbGestureRecognizerMixin {
  _VerticalThumbDragGestureRecognizer({
    PointerDeviceKind? kind,
    required Object debugOwner,
    required this.customPaintKey,
  }) : super(
        kind: kind,
        debugOwner: debugOwner,
       );
  @override
  final GlobalKey customPaintKey;
}

// A horizontal drag gesture detector that only responds to events on the
// scrollbar's thumb and ignores everything else.
class _HorizontalThumbDragGestureRecognizer extends HorizontalDragGestureRecognizer with ScrollbarThumbHitTestMixin implements  _ScrollbarThumbGestureRecognizerMixin {
  _HorizontalThumbDragGestureRecognizer({
    PointerDeviceKind? kind,
    required Object debugOwner,
    required this.customPaintKey,
  }) : super(
         kind: kind,
         debugOwner: debugOwner,
       );
  @override
  final GlobalKey customPaintKey;
}

mixin _ScrollbarThumbGestureRecognizerMixin on DragGestureRecognizer, ScrollbarThumbHitTestMixin {
  GlobalKey get customPaintKey;

  @override
  bool isPointerAllowed(PointerEvent event) {
    if (!hitTestInteractive(customPaintKey, event.position)) {
      return false;
    }
    return super.isPointerAllowed(event);
  }
}
