// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';

import 'theme.dart';

const double _kScrollbarThickness = 6.0;
const Duration _kScrollbarFadeDuration = Duration(milliseconds: 300);
const Duration _kScrollbarTimeToFade = Duration(milliseconds: 600);

/// A material design scrollbar thumb.
///
/// A scrollbar thumb indicates which portion of a [Scrollable] widget is actually
/// visible.
///
/// Dynamically changes to an iOS style scrollbar that looks like
/// [CupertinoScrollbar] on the iOS platform.
///
/// To add a scrollbar thumb to a [ScrollView], simply wrap the scroll view
/// widget in a [Scrollbar] widget.
///
/// See also:
///
///  * [RawScrollbarThumb], the abstract base class this inherits from.
///  * [ListView], which display a linear, scrollable list of children.
///  * [GridView], which display a 2 dimensional, scrollable array of children.
class Scrollbar extends RawScrollbarThumb {
  /// Creates a material design scrollbar thumb that wraps the given [child].
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
  late TextDirection _textDirection;
  late Color _themeColor;
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
        _themeColor = theme.highlightColor.withOpacity(1.0);
        _textDirection = Directionality.of(context)!;
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
      color: _themeColor,
      textDirection: _textDirection,
      thickness: widget.thickness ?? _kScrollbarThickness,
      radius: widget.radius,
      fadeoutOpacityAnimation: fadeoutOpacityAnimation,
      padding: MediaQuery.of(context).padding,
    );
  }

  @override
  bool handleScrollNotification(ScrollNotification notification) {
    final ScrollMetrics metrics = notification.metrics;
    if (metrics.maxScrollExtent <= metrics.minScrollExtent) {
      return false;
    }
    if (_useCupertinoScrollbar)
      return false;
    return super.handleScrollNotification(notification);
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
        child: CustomPaint(
          foregroundPainter: painter,
          child: RepaintBoundary(
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
