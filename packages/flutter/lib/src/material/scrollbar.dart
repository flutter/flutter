// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

const double _kScrollbarThickness = 8.0;
const double _kScrollbarHoverThickness = 12.0;
const double _kScrollbarMargin = 2.0;
const double _kScrollbarMinLength = 48.0;
const Radius _kScrollbarRadius = Radius.circular(8.0);
const Duration _kScrollbarFadeDuration = Duration(milliseconds: 300);
const Duration _kScrollbarTimeToFade = Duration(milliseconds: 600);

/// A material design scrollbar.
///
/// To add a scrollbar thumb to a [ScrollView], simply wrap the scroll view
/// widget in a [Scrollbar] widget.
///
/// {@macro flutter.widgets.Scrollbar}
///
/// A scrollbar track can been drawn when triggered by a hover event, which is
/// controlled by [showTrackOnHover]. The thickness of the track and scrollbar
/// thumb will become larger when hovering, unless overridden by [thickness].
///
// TODO(Piinks): Add code sample
///
/// See also:
///
///  * [RawScrollbar], the simple base class this extends.
///  * [CupertinoScrollbar], an iOS style scrollbar.
///  * [ListView], which display a linear, scrollable list of children.
///  * [GridView], which display a 2 dimensional, scrollable array of children.
class Scrollbar extends RawScrollbar {
  /// Creates a material design scrollbar that wraps the given [child].
  ///
  /// The [child] should be a source of [ScrollNotification] notifications,
  /// typically a [Scrollable] widget.
  const Scrollbar({
    Key? key,
    required Widget child,
    ScrollController? controller,
    bool isAlwaysShown = false,
    this.showTrackOnHover = false,
    // TODO(Piinks): should we include thickness[WithTrack/OnHover], a la
    // CupertinoScrollbar thickness/thicknessWhileDragging?
    // May be better to not introduce more properties in lieu of future ScrollbarTheme
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
         pressDuration: Duration.zero,
       );

  /// Controls if the track will show on hover and remain, including during drag.
  /// 
  /// Defaults to false, cannot be null.
  final bool showTrackOnHover;

  @override
  _ScrollbarState createState() => _ScrollbarState();
}

class _ScrollbarState extends RawScrollbarState<Scrollbar> {
  late AnimationController _hoverAnimationController;
  late TextDirection _textDirection;
  bool _dragIsActive = false;
  bool _hoverIsActive = false;
  
  Color get _thumbColor {
    if (_dragIsActive)
      return const Color(0xFF616161);

    // If the track is visible, the thumb color animation is ignored.
    if (widget.showTrackOnHover && _hoverIsActive)
      return const Color(0xFF757575);

    return Color.lerp(
      const Color(0xFFE0E0E0),
      const Color(0xFF757575),
      _hoverAnimationController.value,
    )!;
  }

  Color get _trackColor => _hoverIsActive && widget.showTrackOnHover
    ? const Color(0xFF424242).withOpacity(0.04)
    : const Color(0x00000000);

  Color get _trackBorderColor => _hoverIsActive && widget.showTrackOnHover
    ? const Color(0xFFE0E0E0)
    : const Color(0x00000000);

  double get _thickness {
   if (widget.thickness != null)
     return widget.thickness!;
   return _hoverIsActive && widget.showTrackOnHover
     ? _kScrollbarHoverThickness
     : _kScrollbarThickness;
  }

  @override
  void initState() {
    super.initState();
    _hoverAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _hoverAnimationController.addListener(() {
      painter!.updateColors(
        _thumbColor,
        _trackColor,
        _trackBorderColor,
      );
      painter!.updateThickness(
        _thickness,
        widget.radius ?? _kScrollbarRadius,
      );
    });
  }

  @override
  void didChangeDependencies() {
    _textDirection = Directionality.of(context);
    painter = _buildMaterialScrollbarPainter();
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(Scrollbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    painter!
      ..thickness = _thickness
      ..radius = widget.radius ?? _kScrollbarRadius;
  }

  ScrollbarPainter _buildMaterialScrollbarPainter() {
    return ScrollbarPainter(
      color: _thumbColor,
      trackColor: _trackColor,
      trackBorderColor: _trackBorderColor,
      textDirection: _textDirection,
      thickness: widget.thickness ?? _kScrollbarThickness,
      radius: widget.radius ?? _kScrollbarRadius,
      crossAxisMargin: _kScrollbarMargin,
      minLength: _kScrollbarMinLength,
      fadeoutOpacityAnimation: fadeoutOpacityAnimation,
      padding: MediaQuery.of(context).padding,
    );
  }

  @override
  void handleLongPressStart(LongPressStartDetails details) {
    super.handleLongPressStart(details);
    _dragIsActive = true;
    painter!.updateColors(
      _thumbColor,
      _trackColor,
      _trackBorderColor,
    );
  }

  @override
  void handleLongPressEnd(LongPressEndDetails details) {
    super.handleLongPressEnd(details);
    _dragIsActive = false;
    painter!.updateColors(
      _thumbColor,
      _trackColor,
      _trackBorderColor,
    );
  }

  void maybeHovering(PointerHoverEvent event) {
    if (customPaintKey.currentContext == null) {
      return;
    }

    final CustomPaint customPaint = customPaintKey.currentContext!.widget as CustomPaint;
    final ScrollbarPainter painter = customPaint.foregroundPainter! as ScrollbarPainter;
    final RenderBox renderBox = customPaintKey.currentContext!.findRenderObject()! as RenderBox;
    final Offset localOffset = renderBox.globalToLocal(event.position);
    final bool onScrollbar = painter.hitTestInteractive(localOffset);

    // Check is the position of the pointer falls over the painted scrollbar
    if (onScrollbar) {
      // Pointer exited hovering the scrollbar
      _hoverIsActive = true;
      _hoverAnimationController.forward();
    } else {
      // Pointer entered the area of the painted scrollbar
      _hoverIsActive = false;
      _hoverAnimationController.reverse();
    }
  }

  void maybeHoverExit(PointerExitEvent event) {
    _hoverIsActive = false;
    _hoverAnimationController.reverse();
  }

  @override
  void dispose() {
    _hoverAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: handleScrollNotification,
      child: RepaintBoundary(
        child: RawGestureDetector(
          gestures: gestures,
          child: MouseRegion(
            onExit: maybeHoverExit,
            onHover: maybeHovering,
            child: CustomPaint(
              key: customPaintKey,
              foregroundPainter: painter,
              child: RepaintBoundary(child: widget.child),
            ),
          ),
        ),
      ),
    );
  }
}
